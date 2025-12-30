#!/usr/bin/env bash

set -euo pipefail

# Manage ~/.zshrc safely and idempotently according to enterprise rules.
# - Do not overwrite ~/.zshrc
# - Only modify content inside managed block
# - Install oh-my-zsh if missing
# - Align theme when absent; never overwrite user-chosen theme
# - Merge plugins by appending missing ones
# - Validate plugins under ~/.oh-my-zsh/custom/plugins and attempt non-interactive install

ZSHRC_PATH="$HOME/.zshrc"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
REPO_REF_DIR=".devopstools"
REF_ZSHRC="$REPO_REF_DIR/reference_zshrc"

MARK_START="# >>> devopstools managed >>>"
MARK_END="# <<< devopstools managed <<<"

installed_ohmyzsh="skipped"
theme_status="unchanged"
plugins_added=()
plugins_skipped=()
zshrc_updated="unchanged"

# CLI flags
DRY_RUN=0
INSTALL_PLUGINS=0
LOGFILE="$HOME/Library/Logs/devopstools/manage_zshrc.log"

ensure_repo_ref() {
  mkdir -p "$REPO_REF_DIR"
  if [ ! -f "$REF_ZSHRC" ]; then
    if [ -f "$ZSHRC_PATH" ]; then
      cp "$ZSHRC_PATH" "$REF_ZSHRC"
      printf "Saved current ~/.zshrc as reference at %s\n" "$REF_ZSHRC"
    else
      printf "No existing ~/.zshrc found to save as reference.\n"
      touch "$REF_ZSHRC"
    fi
  fi
}

backup_file() {
  # arg: filepath
  f="$1"
  if [ -f "$f" ]; then
    mkdir -p "$(dirname "$f")"
    cp -a "$f" "${f}.bak.$(date +%s)" || true
    printf "Backup created: %s.bak.%s\n" "$f" "$(date +%s)"
  fi
}

parse_theme_from() {
  # arg: file
  # Extract ZSH_THEME value (handles single or double quotes)
  sed -n -E "s/^[[:space:]]*ZSH_THEME[[:space:]]*=[[:space:]]*['\"]?([^'\"]+)['\"]?.*$/\1/p" "$1" || true
}

parse_plugins_from() {
  # arg: file
  # prints space-separated plugin names
  local file="$1"
  # Extract the plugins=( ... ) block (handles multi-line arrays)
  local block
  block=$(awk 'BEGIN{p=0}
    /^\s*plugins\s*=/ { if (index($0,"(")) { p=1; sub(/.*\(/,""); print; if(index($0,")")){exit} ; next }}
    p==1 { print; if(index($0,")")){ exit } }' "$file" 2>/dev/null || true)
  if [ -z "$block" ]; then
    return 0
  fi
  # Remove parentheses, quotes and commas; normalize whitespace to single spaces
  echo "$block" | tr -d '()' | sed -E "s/[\"']//g" | tr ',' ' ' | tr -s ' \t\n' ' ' | sed 's/^ *//; s/ *$//'
}

ensure_oh_my_zsh() {
  if [ -d "$OH_MY_ZSH_DIR" ]; then
    printf "✔ ~/.oh-my-zsh present — skipping\n"
    installed_ohmyzsh="skipped"
    return 0
  fi
  printf "→ oh-my-zsh not present; will install non-interactively\n"
  # Clone without running the install script and without prompts
  if git --version >/dev/null 2>&1; then
    if git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR" >> /dev/null 2>&1; then
      printf "✓ Installed oh-my-zsh\n"
      installed_ohmyzsh="installed"
      return 0
    else
      printf "✖ Failed to install oh-my-zsh — git clone failed\n"
      installed_ohmyzsh="failed"
      return 1
    fi
  else
    printf "✖ git not available; cannot install oh-my-zsh non-interactively\n"
    installed_ohmyzsh="failed"
    return 1
  fi
}

merge_plugins_runtime_snippet() {
  # arg: space-separated required plugins
  required_plugins=("$@")
  printf "%s\n" "$MARK_START"
  printf "# devopstools managed block — do not edit outside markers\n"
  printf "# This block ensures required plugins are present in the plugins array\n"
  printf "DEVOPSTOOLS_REQUIRED_PLUGINS=(%s)\n" "${required_plugins[*]}"
  cat <<'EOF'
if [ -z "${plugins+x}" ]; then
  plugins=()
fi
for p in "${DEVOPSTOOLS_REQUIRED_PLUGINS[@]}"; do
  found=0
  for exist in "${plugins[@]}"; do
    if [ "$exist" = "$p" ]; then found=1; break; fi
  done
  if [ $found -eq 0 ]; then
    plugins+=("$p")
  fi
done
EOF
  printf "%s\n" "$MARK_END"
}

install_missing_plugins() {
  # arg: array of plugin names
  # plugin_repo(name) -> prints owner/repo for known plugins (compatible with older bash)
  plugin_repo() {
    case "$1" in
      zsh-autosuggestions) printf "zsh-users/zsh-autosuggestions" ;;
      zsh-syntax-highlighting) printf "zsh-users/zsh-syntax-highlighting" ;;
      fast-syntax-highlighting) printf "zdharma-continuum/fast-syntax-highlighting" ;;
      zsh-autocomplete) printf "marlonrichert/zsh-autocomplete" ;;
      *) return 1 ;;
    esac
  }
  for p in "$@"; do
    plugin_dir="$OH_MY_ZSH_DIR/custom/plugins/$p"
    if [ -d "$plugin_dir" ]; then
      plugins_skipped+=("$p")
      continue
    fi
    # Attempt common clone locations
    printf "→ Installing plugin %s\n" "$p"
    cloned=1
    # Determine repository to clone
    repo=""
    if [[ "$p" == */* ]]; then
      repo="$p"
    else
      if repo=$(plugin_repo "$p" 2>/dev/null); then
        :
      else
        repo="zsh-users/$p"
      fi
    fi

    # Attempt clone non-interactively using HTTPS; if network or auth blocks it, report and continue
    if git clone --depth=1 "https://github.com/${repo}.git" "$plugin_dir" >> /dev/null 2>&1; then
      plugins_added+=("$p")
      cloned=0
    else
      printf "✖ Could not non-interactively clone https://github.com/%s.git for plugin %s\n" "$repo" "$p"
      cloned=1
    fi
    if [ $cloned -ne 0 ]; then
      printf "✖ Could not install plugin %s — manual action required\n" "$p"
      return 1
    fi
  done
  return 0
}

update_zshrc_managed_block() {
  # Use the current machine's ~/.zshrc as the source-of-truth for defaults
  # Initialize arrays to avoid unbound variable under "set -u"
  ref_plugins=()
  target_plugins=()

  # Use repository reference zshrc as the source-of-truth for defaults
  ref_plugins_raw="$(parse_plugins_from "$REF_ZSHRC" || true)"
  if [ -n "$ref_plugins_raw" ]; then
    read -ra ref_plugins <<<"$ref_plugins_raw"
  fi

  # Determine ZSH_THEME from reference (defaults) and target (~/.zshrc)
  ref_theme="$(parse_theme_from "$REF_ZSHRC" || true)"
  target_theme="$(parse_theme_from "$ZSHRC_PATH" || true)"

  # Determine target plugins from existing ~/.zshrc
  target_plugins_raw="$(parse_plugins_from "$ZSHRC_PATH" || true)"
  if [ -n "$target_plugins_raw" ]; then
    read -ra target_plugins <<<"$target_plugins_raw"
  fi

  # Identify missing plugins (handle empty arrays)
  missing_plugins=()
  if [ ${#ref_plugins[@]} -ne 0 ]; then
    for rp in "${ref_plugins[@]}"; do
      found=0
      if [ ${#target_plugins[@]} -ne 0 ]; then
        for tp in "${target_plugins[@]}"; do
          if [ "$rp" = "$tp" ]; then found=1; break; fi
        done
      fi
      if [ $found -eq 0 ]; then
        missing_plugins+=("$rp")
      fi
    done
  fi

  # Theme handling
  if [ -z "$target_theme" ] && [ -n "$ref_theme" ]; then
    theme_status="aligned"
    # We'll set theme inside managed block so new machines pick it up
    need_theme_line=1
  elif [ -n "$target_theme" ] && [ "$target_theme" != "$ref_theme" ]; then
    theme_status="unchanged"
    need_theme_line=0
  else
    need_theme_line=0
  fi

  # Build managed block content
  managed_content=""
  if [ "$need_theme_line" -eq 1 ]; then
    managed_content+="ZSH_THEME=\"$ref_theme\"\n"
  fi
  if [ ${#ref_plugins[@]} -ne 0 ]; then
    # We will inject runtime merge code
    managed_block_tmp="$(mktemp)"
    merge_plugins_runtime_snippet "${ref_plugins[@]}" > "$managed_block_tmp"
    managed_content+="$(cat "$managed_block_tmp")\n"
    rm -f "$managed_block_tmp"
  fi

  # Insert or update managed block in target zshrc. Place before sourcing oh-my-zsh if present.
  src_line_num=$(grep -n "source \$ZSH/oh-my-zsh.sh\|\. \$ZSH/oh-my-zsh.sh" -n "$ZSHRC_PATH" 2>/dev/null | head -n1 | cut -d: -f1 || true)
  if [ -n "$src_line_num" ]; then
    # Insert block before src_line_num
    awk -v start="$MARK_START" -v end="$MARK_END" -v content="$managed_content" -v lineno="$src_line_num" '
      BEGIN{ inserted=0 }
      NR==lineno{
        # remove existing managed block if present just before insertion
        print_block=1
      }
      { print }
    ' "$ZSHRC_PATH" > "${ZSHRC_PATH}.tmp" || true
  fi

  # Simple implementation: if markers exist, replace content between them; else append before source or at end
  if grep -qF "$MARK_START" "$ZSHRC_PATH" 2>/dev/null; then
    # replace existing block
    awk -v start="$MARK_START" -v end="$MARK_END" -v content="$managed_content" '
    BEGIN{inside=0}
    {
      if(index($0,start)==1){print start; print content; inside=1; next}
      if(index($0,end)==1){print end; inside=0; next}
      if(!inside) print
    }' "$ZSHRC_PATH" > "${ZSHRC_PATH}.new"
    if [ "$DRY_RUN" -eq 1 ]; then
      printf "DRY-RUN: would replace managed block in %s\n" "$ZSHRC_PATH"
      rm -f "${ZSHRC_PATH}.new" || true
    else
      backup_file "$ZSHRC_PATH"
      mv "${ZSHRC_PATH}.new" "$ZSHRC_PATH"
    fi
    zshrc_updated="updated"
  else
    if [ -n "$src_line_num" ]; then
      # insert before source line
      awk -v lineno="$src_line_num" -v start="$MARK_START" -v end="$MARK_END" -v content="$managed_content" 'NR==lineno{print start; print content; print end} {print}' "$ZSHRC_PATH" > "${ZSHRC_PATH}.new"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf "DRY-RUN: would insert managed block before line %s in %s\n" "$src_line_num" "$ZSHRC_PATH"
        rm -f "${ZSHRC_PATH}.new" || true
      else
        backup_file "$ZSHRC_PATH"
        mv "${ZSHRC_PATH}.new" "$ZSHRC_PATH"
      fi
      zshrc_updated="updated"
    else
      # append at end
      if [ "$DRY_RUN" -eq 1 ]; then
        printf "DRY-RUN: would append managed block to %s\n" "$ZSHRC_PATH"
      else
        backup_file "$ZSHRC_PATH"
        printf "\n%s\n%s\n%s\n" "$MARK_START" "$managed_content" "$MARK_END" >> "$ZSHRC_PATH"
      fi
      zshrc_updated="updated"
    fi
  fi

  if [ ${#missing_plugins[@]} -ne 0 ]; then
    if [ "$INSTALL_PLUGINS" -ne 1 ]; then
      printf "Plugins to install (deferred): %s\n" "${missing_plugins[*]}"
      printf "Run with --install-plugins to attempt installation.\n"
    else
      if ensure_oh_my_zsh >/dev/null 2>&1; then
        if install_missing_plugins "${missing_plugins[@]}"; then
          :
        else
          printf "Some plugins could not be installed automatically; see output above.\n"
        fi
      else
        printf "oh-my-zsh not available; skipping plugin installs.\n"
      fi
    fi
  fi
}

main() {
  # parse flags
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --install-plugins) INSTALL_PLUGINS=1; shift ;;
      -h|--help) printf "Usage: %s [--dry-run] [--install-plugins]\n" "$0"; exit 0 ;;
      *) shift ;;
    esac
  done

  # ensure logfile dir
  mkdir -p "$(dirname "$LOGFILE")"
  printf "[%s] manage_zshrc run: dry_run=%s install_plugins=%s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$DRY_RUN" "$INSTALL_PLUGINS" >> "$LOGFILE" || true
  ensure_repo_ref

  # If oh-my-zsh already exists on this machine, do not modify ~/.zshrc.
  # Use the current ~/.zshrc as the source-of-truth for theme and plugins defaults.
  if [ -d "$OH_MY_ZSH_DIR" ]; then
    installed_ohmyzsh="skipped"
    # capture current theme/plugins for summary
    cur_theme="$(parse_theme_from "$ZSHRC_PATH" || true)"
    cur_plugins_raw="$(parse_plugins_from "$ZSHRC_PATH" || true)"
    read -ra cur_plugins <<<"$cur_plugins_raw"
    theme_status="unchanged (current: ${cur_theme:-none})"
    plugins_skipped=("${cur_plugins[@]:-none}")
    zshrc_updated="unchanged"

    printf "\nSummary:\n"
    printf "  oh-my-zsh: %s\n" "$installed_ohmyzsh"
    printf "  Theme: %s\n" "$theme_status"
    printf "  Plugins added: %s\n" "none"
    printf "  Plugins skipped: %s\n" "${plugins_skipped[*]:-none}"
    printf "  zshrc: %s\n" "$zshrc_updated"
    return 0
  fi

  # New machine path: oh-my-zsh missing — proceed to install and create managed block
  if ensure_oh_my_zsh; then
    :
  fi

  update_zshrc_managed_block

  # Summary
  printf "\nSummary:\n"
  printf "  oh-my-zsh: %s\n" "$installed_ohmyzsh"
  printf "  Theme: %s\n" "$theme_status"
  printf "  Plugins added: %s\n" "${plugins_added[*]:-none}"
  printf "  Plugins skipped: %s\n" "${plugins_skipped[*]:-none}"
  printf "  zshrc: %s\n" "$zshrc_updated"
}

main "$@"

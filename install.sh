#!/usr/bin/env bash

set -euo pipefail

PROG_NAME="$(basename "$0")"
DRY_RUN=0
ASSUME_YES=0
PROFILES=""
SKIP_TOOLS=""
TOOLS_FILE=""

usage() {
  cat <<'EOF'
Usage: install.sh [OPTIONS] [tools-file]

OPTIONS:
  --profiles PROF1,PROF2,...       Comma-separated profile names to merge
  --skip-tools TOOL1,TOOL2,...     Comma-separated tools to skip
  --dry-run                        Do not perform installs; show what would run
  --yes                            Assume yes for permission fixes
  --non-interactive                Run without interactive prompts
  -h, --help                       Show this help

EXAMPLES:
  # Install from tools file
  install.sh tools.txt

  # Use profiles
  install.sh --profiles base,frontend --no-dry-run --yes

  # Preview with skipped tools
  install.sh --profiles backend,ai --skip-tools npm,poetry --dry-run

  # Non-interactive automation
  install.sh --profiles base,devops --yes --non-interactive

This script installs Homebrew formulae and other tools with support for:
  - Homebrew formulas: git, docker
  - Taps: tap: user/repo
  - npm: npm:package-name
  - pipx: pipx:package-name
  - Python versions: python@3.12, python@3.13
  - Tap-qualified: user/repo/formula

EOF
}

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --profiles)
      PROFILES="$2"
      shift 2
      ;;
    --skip-tools)
      SKIP_TOOLS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --yes)
      ASSUME_YES=1
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --) 
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      if [ -z "$TOOLS_FILE" ]; then
        TOOLS_FILE="$1"
      fi
      shift
      ;;
  esac
done

# Handle remaining args
if [ $# -gt 0 ] && [ -z "$TOOLS_FILE" ]; then
  TOOLS_FILE="$1"
fi

# ============ DETERMINE TOOLS FILE ============
if [ -n "$PROFILES" ]; then
  # Merge multiple profiles
  TOOLS_FILE=$(mktemp)
  IFS=',' read -ra profile_list <<<"$PROFILES"
  
  for profile in "${profile_list[@]}"; do
    profile=$(echo "$profile" | xargs) # trim whitespace
    profile_path="profiles/${profile}.txt"
    
    if [ ! -f "$profile_path" ]; then
      echo "[ERROR] Profile not found: $profile" >&2
      rm -f "$TOOLS_FILE"
      exit 1
    fi
    
    # Append profile content, skipping comments and blanks
    grep -v '^\s*#' "$profile_path" | grep -v '^\s*$' >> "$TOOLS_FILE" || true
  done
  
  # Remove duplicates while preserving order
  TOOLS_FILE_CLEAN=$(mktemp)
  awk '!seen[$0]++' "$TOOLS_FILE" > "$TOOLS_FILE_CLEAN"
  rm "$TOOLS_FILE"
  TOOLS_FILE="$TOOLS_FILE_CLEAN"
  CLEANUP_TEMP=1
elif [ -z "$TOOLS_FILE" ]; then
  echo "[ERROR] Must specify either --profiles or tools-file" >&2
  usage
  exit 1
fi

if [ ! -f "$TOOLS_FILE" ]; then
  echo "[ERROR] Tools list file not found: $TOOLS_FILE" >&2
  exit 1
fi

# Determine Homebrew prefix if available
BREW_PREFIX=""
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX=$(brew --prefix || true)
fi

# Log directory (user-owned) — avoid writing into formula Cellar
LOG_DIR="${HOME}/Library/Logs/devopstools"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install.log"

# Normalize skip_tools to lowercase for easier matching
SKIP_TOOLS_LOWER=$(echo "$SKIP_TOOLS" | tr '[:upper:]' '[:lower:]')

printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
printf "  DevOps Tools Installer\n"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

if [ -n "$PROFILES" ]; then
  printf "Profiles:    %s\n" "$PROFILES"
fi
if [ -n "$SKIP_TOOLS" ]; then
  printf "Skip Tools:  %s\n" "$SKIP_TOOLS"
fi
printf "Log File:    %s\n" "$LOG_FILE"

INSTALLED_TOOLS=()
SKIPPED_TOOLS=()
USER_SKIPPED_TOOLS=()
FAILED_TOOLS=()

# ============ HELPER FUNCTIONS ============

# Check if tool should be skipped by user
should_skip_tool() {
  local tool="$1"
  local tool_lower=$(echo "$tool" | tr '[:upper:]' '[:lower:]')
  
  if echo ",$SKIP_TOOLS_LOWER," | grep -iq ",${tool_lower},"; then
    return 0  # true, should skip
  fi
  
  # Also check partial matches for complex names
  for skip_item in $(echo "$SKIP_TOOLS" | tr ',' '\n'); do
    skip_item=$(echo "$skip_item" | xargs | tr '[:upper:]' '[:lower:]')
    if echo "$tool_lower" | grep -iq "$skip_item"; then
      return 0
    fi
  done
  
  return 1  # false, don't skip
}

msg_skip() { 
  printf "  ✔ %s already available — skipping\n" "$1" | tee -a "$LOG_FILE"
  SKIPPED_TOOLS+=("$1")
}

msg_user_skip() {
  printf "  ⊘ %s — skipped by user\n" "$1" | tee -a "$LOG_FILE"
  USER_SKIPPED_TOOLS+=("$1")
}

msg_installing() { 
  printf "  → Installing %s\n" "$1" | tee -a "$LOG_FILE"
}

msg_installed() { 
  printf "  ✓ Installed %s\n" "$1" | tee -a "$LOG_FILE"
  INSTALLED_TOOLS+=("$1")
}

msg_failed() { 
  printf "  ✖ Failed: %s — %s\n" "$1" "$2" | tee -a "$LOG_FILE"
  FAILED_TOOLS+=("$1: $2")
}

msg_tapping() { 
  printf "  ⊗ Tapping %s\n" "$1" | tee -a "$LOG_FILE"
}

msg_tap_skip() { 
  printf "  ✔ Tap %s already present\n" "$1" | tee -a "$LOG_FILE"
  SKIPPED_TOOLS+=("tap:$1")
}

# ============ PERMISSION CHECKS ============

fix_permissions_suggestion() {
  if [ -n "$BREW_PREFIX" ]; then
    cat <<MSG
[WARN] Some Homebrew directories are not writable. You can run:
  sudo chown -R "$(whoami)" "$BREW_PREFIX"
or run this script again with --yes to attempt a safe permission fix.
MSG
  else
    echo "[WARN] Homebrew not found in PATH. Install Homebrew first: https://brew.sh"
  fi
}

need_permission_fix=0
if [ -n "$BREW_PREFIX" ]; then
  required_dirs=("$HOME/Library/Logs/Homebrew" "$BREW_PREFIX" "$BREW_PREFIX/Cellar" "$BREW_PREFIX/opt")
  for d in "${required_dirs[@]}"; do
    if [ -e "$d" ] && [ ! -w "$d" ]; then
      printf "[WARN] Not writable: %s\n" "$d" | tee -a "$LOG_FILE"
      need_permission_fix=1
    fi
  done
fi

if [ $need_permission_fix -ne 0 ]; then
  if [ $ASSUME_YES -eq 1 ]; then
    if [ $DRY_RUN -eq 0 ]; then
      printf "[INFO] Attempting to fix permissions (sudo may be required)\n" | tee -a "$LOG_FILE"
      sudo chown -R "$(whoami)" "${BREW_PREFIX}" 2>&1 | tee -a "$LOG_FILE"
      sudo chmod u+w "${BREW_PREFIX}" 2>&1 | tee -a "$LOG_FILE"
    else
      printf "[DRY-RUN] Would attempt to fix permissions on %s\n" "${BREW_PREFIX}" | tee -a "$LOG_FILE"
    fi
  else
    fix_permissions_suggestion
  fi
else
  printf "[OK] Homebrew directories are writable\n" | tee -a "$LOG_FILE"
fi

if [ $DRY_RUN -eq 1 ]; then
  printf "\n[DRY-RUN MODE] No changes will be made\n\n" | tee -a "$LOG_FILE"
fi

printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" | tee -a "$LOG_FILE"

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  # Trim leading/trailing whitespace
  tool="$(echo "$raw_line" | sed -e 's/^\s*//' -e 's/\s*$//')"
  # Skip blanks and comments
  if [ -z "$tool" ] || [[ $tool == \#* ]]; then
    continue
  fi

  # ============ CHECK USER SKIP LIST ============
  if should_skip_tool "$tool"; then
    msg_user_skip "$tool"
    continue
  fi

  # ============ TAP HANDLING ============
  # Support explicit tap lines: "tap: user/repo"
  if [[ "$tool" =~ ^tap:[[:space:]]*([^/]+/[^/]+)$ ]]; then
    tap_name="${BASH_REMATCH[1]}"
    tap_short="$tap_name"

    if should_skip_tool "tap:$tap_short" || should_skip_tool "$tap_short"; then
      msg_user_skip "tap:$tap_short"
      continue
    fi

    if [ $DRY_RUN -eq 1 ]; then
      msg_installing "tap $tap_short"
      continue
    fi
    if command -v brew >/dev/null 2>&1; then
      if brew tap | grep -q "^$tap_short$"; then
        msg_tap_skip "$tap_short"
      else
        msg_tapping "$tap_short"
        if brew tap "$tap_short" >> "$LOG_FILE" 2>&1; then
          msg_installed "tap:$tap_short"
        else
          msg_failed "tap:$tap_short" "tap failed"
        fi
      fi
    else
      msg_failed "tap:$tap_short" "brew not available"
    fi
    continue
  fi

  # ============ NPM PACKAGES ============
  if [[ "$tool" =~ ^npm:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"

    if should_skip_tool "npm:$pkg" || should_skip_tool "$pkg"; then
      msg_user_skip "npm:$pkg"
      continue
    fi

    # check presence (robust check)
    npm_present=0
    if command -v npm >/dev/null 2>&1; then
      if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
        npm_present=1
      fi
    fi

    if [ $npm_present -eq 1 ]; then
      msg_skip "$pkg (npm)"
      continue
    fi

    msg_installing "$pkg (npm)"
    if [ $DRY_RUN -eq 1 ]; then
      continue
    fi

    if ! command -v npm >/dev/null 2>&1; then
      if command -v brew >/dev/null 2>&1; then
        msg_installing "node (prerequisite for npm)"
        if ! brew install node >> "$LOG_FILE" 2>&1; then
          msg_failed "node" "failed to install node for npm installs"
          continue
        fi
        msg_installed "node"
      else
        msg_failed "npm:$pkg" "npm not available and Homebrew not found"
        continue
      fi
    fi

    if npm install -g "$pkg" >> "$LOG_FILE" 2>&1; then
      msg_installed "$pkg (npm)"
    else
      msg_failed "$pkg (npm)" "npm install failed"
    fi
    continue
  fi

  # ============ PIPX PACKAGES ============
  if [[ "$tool" =~ ^pipx:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"

    if should_skip_tool "pipx:$pkg" || should_skip_tool "$pkg"; then
      msg_user_skip "pipx:$pkg"
      continue
    fi

    # check presence
    pipx_present=0
    if command -v pipx >/dev/null 2>&1; then
      if pipx list 2>/dev/null | grep -q "$pkg"; then
        pipx_present=1
      fi
    fi

    if [ $pipx_present -eq 1 ]; then
      msg_skip "$pkg (pipx)"
      continue
    fi

    msg_installing "$pkg (pipx)"
    if [ $DRY_RUN -eq 1 ]; then
      continue
    fi

    if ! command -v pipx >/dev/null 2>&1; then
      if command -v python3 >/dev/null 2>&1; then
        msg_installing "pipx (prerequisite)"
        python3 -m pip install --user pipx >> "$LOG_FILE" 2>&1 || true
        python3 -m pipx ensurepath >> "$LOG_FILE" 2>&1 || true
      else
        msg_failed "pipx:$pkg" "python3 not available for pipx bootstrap"
        continue
      fi
    fi

    if pipx install "$pkg" >> "$LOG_FILE" 2>&1; then
      msg_installed "$pkg (pipx)"
    else
      msg_failed "$pkg (pipx)" "pipx install failed"
    fi
    continue
  fi

  # ============ TAP-QUALIFIED FORMULAE ============
  # Support tap-qualified formulae like user/repo/formula
  if [[ "$tool" =~ ^([^/]+/[^/]+)/([^/]+)$ ]]; then
    tap_name="${BASH_REMATCH[1]}"
    formula_name="${BASH_REMATCH[2]}"

    if should_skip_tool "$formula_name" || should_skip_tool "$tap_name/$formula_name"; then
      msg_user_skip "$tap_name/$formula_name"
      continue
    fi

    if [ $DRY_RUN -eq 1 ]; then
      msg_installing "$tap_name/$formula_name"
      continue
    fi

    if command -v brew >/dev/null 2>&1; then
      if brew tap | grep -q "^$tap_name$"; then
        msg_tap_skip "$tap_name"
      else
        msg_tapping "$tap_name"
        if ! brew tap "$tap_name" >> "$LOG_FILE" 2>&1; then
          msg_failed "$tap_name" "tap failed"
          continue
        fi
      fi
    else
      msg_failed "$tap_name" "brew not available"
      continue
    fi

    # Now check if formula already installed
    if brew list --formula 2>/dev/null | grep -q "^${formula_name}$"; then
      msg_skip "$formula_name"
      continue
    fi

    msg_installing "$formula_name"
    if brew install "$formula_name" >> "$LOG_FILE" 2>&1; then
      msg_installed "$formula_name"
    else
      msg_failed "$formula_name" "brew install failed"
    fi
    continue
  fi

  # ============ POLICY: TERRAFORM DIRECT INSTALL ============
  if [[ "$tool" =~ ^terraform$ ]]; then
    msg_failed "terraform" "direct install prohibited — use tfswitch instead"
    continue
  fi

  # ============ SPECIAL: TFSWITCH ============
  if [[ "$tool" =~ ^tfswitch$ ]]; then
    if should_skip_tool "tfswitch"; then
      msg_user_skip "tfswitch"
      continue
    fi

    if command -v tfswitch >/dev/null 2>&1; then
      msg_skip "tfswitch"
      continue
    fi

    msg_installing "tfswitch"
    if [ $DRY_RUN -eq 1 ]; then
      continue
    fi

    if command -v brew >/dev/null 2>&1 && brew install tfswitch >> "$LOG_FILE" 2>&1; then
      msg_installed "tfswitch"
    else
      msg_failed "tfswitch" "failed to install"
    fi
    continue
  fi

  # ============ HOMEBREW FORMULAE (DEFAULT) ============
  if should_skip_tool "$tool"; then
    msg_user_skip "$tool"
    continue
  fi

  # Check if already installed
  if command -v brew >/dev/null 2>&1; then
    if brew list --formula 2>/dev/null | grep -q "^${tool}$"; then
      msg_skip "$tool"
      continue
    fi
  fi

  msg_installing "$tool"
  if [ $DRY_RUN -eq 1 ]; then
    continue
  fi

  if ! command -v brew >/dev/null 2>&1; then
    msg_failed "$tool" "brew not available"
    continue
  fi

  if brew install "$tool" >> "$LOG_FILE" 2>&1; then
    msg_installed "$tool"
  else
    msg_failed "$tool" "brew install failed"
  fi

done < "$TOOLS_FILE"

# ============ CLEANUP ============
if [ "${CLEANUP_TEMP:-0}" -eq 1 ]; then
  rm -f "$TOOLS_FILE"
fi

# ============ SUMMARY ============
printf "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" | tee -a "$LOG_FILE"
printf "  Installation Summary\n" | tee -a "$LOG_FILE"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" | tee -a "$LOG_FILE"

if [ ${#INSTALLED_TOOLS[@]} -ne 0 ]; then
  printf "✓ Installed (%d):\n" "${#INSTALLED_TOOLS[@]}" | tee -a "$LOG_FILE"
  printf "  %s\n" "${INSTALLED_TOOLS[@]}" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
fi

if [ ${#SKIPPED_TOOLS[@]} -ne 0 ]; then
  printf "✔ Already Present (%d):\n" "${#SKIPPED_TOOLS[@]}" | tee -a "$LOG_FILE"
  printf "  %s\n" "${SKIPPED_TOOLS[@]}" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
fi

if [ ${#USER_SKIPPED_TOOLS[@]} -ne 0 ]; then
  printf "⊘ Skipped by User (%d):\n" "${#USER_SKIPPED_TOOLS[@]}" | tee -a "$LOG_FILE"
  printf "  %s\n" "${USER_SKIPPED_TOOLS[@]}" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
fi

if [ ${#FAILED_TOOLS[@]} -ne 0 ]; then
  printf "✖ Failed (%d):\n" "${#FAILED_TOOLS[@]}" | tee -a "$LOG_FILE"
  printf "  %s\n" "${FAILED_TOOLS[@]}" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
fi

printf "\nDetailed log: %s\n" "$LOG_FILE" | tee -a "$LOG_FILE"
printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n" | tee -a "$LOG_FILE"

# Always exit 0 for non-interactive idempotent runs; failures are reported but do not stop automation.
exit 0
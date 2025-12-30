#!/usr/bin/env bash

set -euo pipefail

PROG_NAME="$(basename "$0")"
DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<EOF
Usage: $PROG_NAME [--dry-run] [--yes] <tools-file>

Options:
  --dry-run    Do not perform installs; show what would run
  --yes        Assume yes for permission fixes that require sudo
  -h, --help   Show this help

This script installs Homebrew formulae listed in <tools-file> (one per line).
Lines beginning with # or blank lines are ignored.
EOF
}


PROFILE=""
while [[ ${#-} -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --yes) ASSUME_YES=1; shift;;
    --profile) PROFILE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    --) shift; break;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2;;
    *) break;;
  esac
done

if [ -n "$PROFILE" ] && [ $# -ne 0 ]; then
  echo "[ERROR] Cannot specify both --profile and tools-file" >&2
  usage
  exit 2
fi

if [ -n "$PROFILE" ]; then
  TOOLS_FILE="profiles/${PROFILE}.txt"
  if [ ! -f "$TOOLS_FILE" ]; then
    echo "[ERROR] Profile not found: $PROFILE" >&2
    exit 2
  fi
else
  if [ $# -ne 1 ]; then
    usage
    exit 2
  fi
  TOOLS_FILE=$1
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

printf "\nInstalling tools from: %s\n" "$TOOLS_FILE"
printf "Log: %s\n" "$LOG_FILE"

INSTALLED_TOOLS=()
SKIPPED_TOOLS=()
FAILED_TOOLS=()

# helpers for quiet, consistent messaging
msg_skip() { printf "✔ %s already available — skipping\n" "$1" | tee -a "$LOG_FILE"; SKIPPED_TOOLS+=("$1"); }
msg_present_tfswitch() { printf "✔ tfswitch present — Terraform managed via tfswitch\n" | tee -a "$LOG_FILE"; SKIPPED_TOOLS+=("tfswitch"); }
msg_installing() { printf "→ Installing %s\n" "$1" | tee -a "$LOG_FILE"; }
msg_installed() { printf "✓ Installed %s\n" "$1" | tee -a "$LOG_FILE"; INSTALLED_TOOLS+=("$1"); }
msg_failed() { printf "✖ Failed: %s — %s\n" "$1" "$2" | tee -a "$LOG_FILE"; FAILED_TOOLS+=("$1: $2"); }
msg_tapping() { printf "→ Tapping %s\n" "$1" | tee -a "$LOG_FILE"; }
msg_tap_skip() { printf "✔ Tap %s already present — skipping\n" "$1" | tee -a "$LOG_FILE"; SKIPPED_TOOLS+=("tap:$1"); }


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
      printf "[WARN] Not writable: %s\n" "$d"
      need_permission_fix=1
    fi
  done
fi

if [ $need_permission_fix -ne 0 ]; then
  if [ $ASSUME_YES -eq 1 ]; then
    if [ $DRY_RUN -eq 0 ]; then
      printf "[INFO] Attempting to fix permissions (sudo may be required)\n"
      sudo chown -R "$(whoami)" "${BREW_PREFIX}"
      sudo chmod u+w "${BREW_PREFIX}"
    else
      printf "[DRY-RUN] Would attempt to fix permissions on %s\n" "${BREW_PREFIX}"
    fi
  else
    fix_permissions_suggestion
  fi
else
  printf "[OK] Required directories appear writable or Homebrew not present.\n"
fi

if [ $DRY_RUN -eq 1 ]; then
  printf "[DRY-RUN] No changes will be made.\n"
fi

echo "------------------------------------------" | tee -a "$LOG_FILE"

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  # Trim leading/trailing whitespace
  tool="$(echo "$raw_line" | sed -e 's/^\s*//' -e 's/\s*$//')"
  # Skip blanks and comments
  if [ -z "$tool" ] || [[ $tool == \#* ]]; then
    continue
  fi
  # Support explicit tap lines: "tap: user/repo"
  if [[ "$tool" =~ ^tap:[[:space:]]*([^/]+/[^/]+)$ ]]; then
    tap_name="${BASH_REMATCH[1]}"
    tap_short="$tap_name"
    if [ $DRY_RUN -eq 1 ]; then
      msg_installing "brew tap $tap_short"
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
      msg_failed "tap:$tap_short" "brew not available to tap"
    fi
    continue
  fi

  # npm global installs: npm:package
  if [[ "$tool" =~ ^npm:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    # check presence
    if command -v npm >/dev/null 2>&1 && npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
      msg_skip "$pkg"
      continue
    fi
    msg_installing "$pkg"
    if [ $DRY_RUN -eq 1 ]; then
      continue
    fi
    if ! command -v npm >/dev/null 2>&1; then
      if command -v brew >/dev/null 2>&1; then
        msg_installing "node"
        if ! brew install node >> "$LOG_FILE" 2>&1; then
          msg_failed "node" "failed to install node for npm installs"
          continue
        fi
        msg_installed "node"
      else
        msg_failed "npm:$pkg" "npm not available"
        continue
      fi
    fi
    if npm install -g "$pkg" >> "$LOG_FILE" 2>&1; then
      msg_installed "$pkg"
    else
      msg_failed "$pkg" "npm install failed"
    fi
    continue
  fi

  # pipx installs: pipx:package
  if [[ "$tool" =~ ^pipx:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    if command -v pipx >/dev/null 2>&1 && pipx list | grep -q "$pkg"; then
      msg_skip "$pkg"
      continue
    fi
    msg_installing "$pkg"
    if [ $DRY_RUN -eq 1 ]; then
      continue
    fi
    if ! command -v pipx >/dev/null 2>&1; then
      if command -v python3 >/dev/null 2>&1; then
        python3 -m pip install --user pipx >> "$LOG_FILE" 2>&1 || true
        python3 -m pipx ensurepath >> "$LOG_FILE" 2>&1 || true
      else
        msg_failed "pipx:$pkg" "python3 not available for pipx"
        continue
      fi
    fi
    if pipx install "$pkg" >> "$LOG_FILE" 2>&1; then
      msg_installed "$pkg"
    else
      msg_failed "$pkg" "pipx install failed"
    fi
    continue
  fi

  # Support tap-qualified formulae like user/tap/formula
  if [[ "$tool" =~ ^([^/]+/[^/]+)/([^/]+)$ ]]; then
    tap_name="${BASH_REMATCH[1]}"
    formula_name="${BASH_REMATCH[2]}"
    if [ $DRY_RUN -eq 1 ]; then
      msg_installing "$tap_name/$formula_name (dry-run)"
      continue
    fi
    if command -v brew >/dev/null 2>&1; then
      if brew tap | grep -q "^$tap_name$"; then
        msg_tap_skip "$tap_name"
      else
        msg_tapping "$tap_name"
        brew tap "$tap_name" >> "$LOG_FILE" 2>&1 || true
      fi
    else
      msg_failed "$tap_name" "brew not available"
      continue
    fi
    tool="$formula_name"
  fi

  # Enforce policy: terraform must NOT be installed directly.
  if [[ "$tool" =~ ^terraform$ ]]; then
    msg_failed "terraform" "direct install prohibited; use tfswitch"
    continue
  fi

  # Special tfswitch handling
  if [[ "$tool" =~ ^tfswitch$ ]]; then
    if command -v tfswitch >/dev/null 2>&1; then
      msg_present_tfswitch
    else
      msg_installing "tfswitch"
      if [ $DRY_RUN -eq 1 ]; then
        continue
      fi
      if command -v brew >/dev/null 2>&1 && brew install tfswitch >> "$LOG_FILE" 2>&1; then
        msg_installed "tfswitch"
      else
        msg_failed "tfswitch" "failed to install tfswitch"
      fi
    fi
    continue
  fi

  # Homebrew installs (default)
  if command -v brew >/dev/null 2>&1 && brew list --formula | grep -q "^${tool}$"; then
    msg_skip "$tool"
    continue
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

printf "\nSummary:\n" | tee -a "$LOG_FILE"
if [ ${#INSTALLED_TOOLS[@]} -ne 0 ]; then
  printf "  Installed: %s\n" "${INSTALLED_TOOLS[*]}" | tee -a "$LOG_FILE"
else
  printf "  Installed: (none)\n" | tee -a "$LOG_FILE"
fi
if [ ${#SKIPPED_TOOLS[@]} -ne 0 ]; then
  printf "  Skipped: %s\n" "${SKIPPED_TOOLS[*]}" | tee -a "$LOG_FILE"
else
  printf "  Skipped: (none)\n" | tee -a "$LOG_FILE"
fi
if [ ${#FAILED_TOOLS[@]} -ne 0 ]; then
  printf "  Failed: %s\n" "${FAILED_TOOLS[*]}" | tee -a "$LOG_FILE"
else
  printf "  Failed: (none)\n" | tee -a "$LOG_FILE"
fi

printf "More detailed log: %s\n" "$LOG_FILE" | tee -a "$LOG_FILE"

# Always exit 0 for non-interactive idempotent runs; failures are reported but do not stop automation.
exit 0
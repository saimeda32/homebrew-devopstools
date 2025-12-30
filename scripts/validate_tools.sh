#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <tools-file>" >&2
  exit 2
fi

TOOLS_FILE=$1
if [ ! -f "$TOOLS_FILE" ]; then
  echo "Tools file not found: $TOOLS_FILE" >&2
  exit 2
fi

OK=()
SKIP=()
BOOTSTRAP=()
POLICY_GAPS=()

# helpers
is_brew() { command -v brew >/dev/null 2>&1; }
is_npm() { command -v npm >/dev/null 2>&1; }
is_pipx() { command -v pipx >/dev/null 2>&1; }

# Explicit approved tool -> tap mapping (policy-approved sources)
get_tool_tap() {
  case "$1" in
    vault) echo "hashicorp/tap" ;;
    packer) echo "hashicorp/tap" ;;
    *) echo "" ;;
  esac
}

while IFS= read -r line || [ -n "$line" ]; do
  raw="$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$raw" ] && continue
  [[ $raw == \#* ]] && continue

  # Policy: direct terraform entries are forbidden
  if [[ "$raw" =~ ^terraform$ ]]; then
    echo "POLICY-GAP: direct terraform declaration detected — terraform must be managed via tfswitch" >&2
    POLICY_GAPS+=("terraform (use tfswitch)")
    continue
  fi

  # Explicit tap lines
  if [[ "$raw" =~ ^tap:[[:space:]]*([^/]+/[^/]+)$ ]]; then
    tap_name="${BASH_REMATCH[1]}"
    if is_brew && brew tap | grep -q "^$tap_name$"; then
      echo "OK: tap $tap_name present"
      OK+=("tap:$tap_name")
    else
      echo "SKIP: tap $tap_name will be added when installing associated formulae"
      SKIP+=("tap:$tap_name")
    fi
    continue
  fi

  # tap-qualified formulae: user/tap/formula
  if [[ "$raw" =~ ^([^/]+/[^/]+)/([^/]+)$ ]]; then
    tap_name="${BASH_REMATCH[1]}"
    formula_name="${BASH_REMATCH[2]}"
    if is_brew && brew tap | grep -q "^$tap_name$"; then
      if is_brew && brew info "$tap_name/$formula_name" >/dev/null 2>&1; then
        echo "OK: $raw (found in tap)"
        OK+=("$raw")
      elif is_brew && brew info "$formula_name" >/dev/null 2>&1; then
        echo "OK: $raw (found as $formula_name in core)"
        OK+=("$raw")
      else
        echo "POLICY-GAP: $raw declared but no install strategy found in tap or core" >&2
        POLICY_GAPS+=("$raw")
      fi
    else
      echo "SKIP: tap $tap_name missing; will be auto-added during install if required"
      SKIP+=("tap:$tap_name")
    fi
    continue
  fi

  # npm:package entries
  if [[ "$raw" =~ ^npm:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    if is_npm; then
      if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
        echo "OK: npm package $pkg present"
        OK+=("npm:$pkg")
      else
        echo "OK: npm package $pkg not present but installable via npm"
        OK+=("npm:$pkg")
      fi
    else
      echo "BOOTSTRAP: npm missing; node will be installed to support npm package $pkg"
      BOOTSTRAP+=("npm:$pkg")
    fi
    continue
  fi

  # pipx:package entries
  if [[ "$raw" =~ ^pipx:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    if is_pipx; then
      if pipx list | grep -q "$pkg"; then
        echo "OK: pipx package $pkg present"
        OK+=("pipx:$pkg")
      else
        echo "OK: pipx package $pkg not present but installable via pipx"
        OK+=("pipx:$pkg")
      fi
    else
      echo "BOOTSTRAP: pipx missing; pipx will be installed to support $pkg"
      BOOTSTRAP+=("pipx:$pkg")
    fi
    continue
  fi

  # tfswitch special case
  if [[ "$raw" =~ ^tfswitch$ ]]; then
    if command -v tfswitch >/dev/null 2>&1; then
      echo "OK: tfswitch present — Terraform managed via tfswitch"
      OK+=("tfswitch")
    else
      if is_brew; then
        echo "BOOTSTRAP: tfswitch missing; will be installed via Homebrew"
        BOOTSTRAP+=("tfswitch")
      else
        echo "POLICY-GAP: tfswitch required but Homebrew unavailable"
        POLICY_GAPS+=("tfswitch")
      fi
    fi
    continue
  fi

  # Default: first check if tool has an approved tap mapping
  tap="$(get_tool_tap "$raw")"
  if [ -n "$tap" ]; then
    echo "OK: $raw available via Homebrew (${tap})"
    OK+=("$raw")
    continue
  fi

  # Otherwise assume Homebrew formula
  if is_brew && brew info "$raw" >/dev/null 2>&1; then
    echo "OK: $raw available via Homebrew"
    OK+=("$raw")
  else
    if ! is_brew; then
      echo "BOOTSTRAP: Homebrew not available locally; $raw will be installed when Homebrew is available"
      BOOTSTRAP+=("$raw")
    else
      echo "POLICY-GAP: No known install strategy for $raw via Homebrew/core or tapped repos"
      POLICY_GAPS+=("$raw")
    fi
  fi
done < "$TOOLS_FILE"

# Summary
echo
echo "Validation Summary:" 
echo "  OK: ${#OK[@]} — ${OK[*]}"
echo "  SKIP: ${#SKIP[@]} — ${SKIP[*]}"
echo "  BOOTSTRAP: ${#BOOTSTRAP[@]} — ${BOOTSTRAP[*]}"
if [ ${#POLICY_GAPS[@]} -ne 0 ]; then
  echo "  POLICY-GAPS: ${#POLICY_GAPS[@]} — ${POLICY_GAPS[*]}" >&2
  echo
  echo "Validation failed: policy gaps detected (see above)." >&2
  exit 2
else
  echo "  POLICY-GAPS: 0"
  echo
  echo "Validation passed — no policy gaps detected."
  exit 0
fi
  fi

  # Support npm:package entries
  if [[ "$raw" =~ ^npm:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    if command -v npm >/dev/null 2>&1; then
      echo "[OK-NPM] npm available for $pkg"
    else
      echo "[MISSING-NPM] npm not available for $pkg (will attempt to install node)" >&2
      failed=1
    fi
    continue
  fi

  # Policy: direct terraform entries are not allowed
  if [[ "$raw" =~ ^terraform$ ]]; then
    echo "[POLICY-VIOLATION] Direct terraform install is prohibited. Use tfswitch instead." >&2
    failed=1
    continue
  fi

  # Support pipx:package entries
  if [[ "$raw" =~ ^pipx:([^[:space:]]+)$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    if command -v pipx >/dev/null 2>&1; then
      echo "[OK-PIPX] pipx available for $pkg"
    else
      echo "[MISSING-PIPX] pipx not available for $pkg (python3/pipx will be required)" >&2
      failed=1
    fi
    continue
  fi

  # Regular formula name
  if brew info "$raw" >/dev/null 2>&1; then
    echo "[OK] $raw"
  else
    echo "[MISSING] $raw" >&2
    failed=1
  fi
done < "$TOOLS_FILE"

exit $failed

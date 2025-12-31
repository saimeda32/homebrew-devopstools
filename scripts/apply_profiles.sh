#!/usr/bin/env bash

set -euo pipefail

# Helper to select one or more profiles and run the installer with the merged list.
# Usage:
#   ./scripts/apply_profiles.sh           # interactive menu
#   ./scripts/apply_profiles.sh --profiles frontend,base --dry-run
#   ./scripts/apply_profiles.sh --profiles all --yes

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Homebrew opt root for this package
BREW_OPT_ROOT="$(brew --prefix 2>/dev/null || echo /opt/homebrew)/opt/devopstools"
PROFILES_DIR="$REPO_ROOT/profiles"
INSTALL_SH="$REPO_ROOT/install.sh"

DRY_RUN=0
NON_INTERACTIVE=0
YES=0
SELECTED_PROFILES=()

print_usage(){
  cat <<EOF
Usage: devopstools [--profiles base,frontend,backend,devops|all] [--dry-run] [--yes] [--non-interactive]

Examples:
  devopstools --profiles base,devops            # merge 'base' and 'devops' profiles
  devopstools --profiles all --yes --non-interactive  # select all profiles and run without prompts

If --profiles is omitted the script runs an interactive menu.
EOF
}

if [ ! -d "$PROFILES_DIR" ]; then
  echo "No profiles directory found at $PROFILES_DIR" >&2
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profiles)
      shift; arg="$1"; shift
      IFS=',' read -ra SELECTED_PROFILES <<<"$arg"
      ;;
    --profiles=*)
      arg="${1#--profiles=}"; shift
      IFS=',' read -ra SELECTED_PROFILES <<<"$arg"
      ;;
    --no-dry-run)
      DRY_RUN=0; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --yes)
      YES=1; shift ;;
    --non-interactive)
      NON_INTERACTIVE=1; shift ;;
    -h|--help)
      print_usage; exit 0 ;;
    *) echo "Unknown arg: $1"; print_usage; exit 1 ;;
  esac
done

available_profiles=()
while IFS= read -r -d $'\0' f; do
  available_profiles+=("$(basename "$f" .txt)")
done < <(find "$PROFILES_DIR" -maxdepth 1 -type f -name '*.txt' -print0 | sort -z)

if [ ${#SELECTED_PROFILES[@]} -eq 0 ] && [ "$NON_INTERACTIVE" -eq 0 ]; then
  echo "Available profiles:"
  i=1
  for p in "${available_profiles[@]}"; do
    printf "  %2d) %s\n" "$i" "$p"
    i=$((i+1))
  done
  echo
  echo "Enter numbers separated by commas (e.g. 1,3) or 'all' to select all:" 
  read -r choice
  if [ "$choice" = "all" ]; then
    SELECTED_PROFILES=("${available_profiles[@]}")
  else
    IFS=',' read -ra nums <<<"$choice"
    for n in "${nums[@]}"; do
      n=$(echo "$n" | tr -d '[:space:]')
      if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le ${#available_profiles[@]} ]; then
        SELECTED_PROFILES+=("${available_profiles[$((n-1))]}")
      fi
    done
  fi
fi

if [ ${#SELECTED_PROFILES[@]} -eq 0 ]; then
  echo "No profiles selected. Exiting." >&2
  exit 1
fi

# handle 'all' token if passed in --profiles
if [ "${SELECTED_PROFILES[0]}" = "all" ]; then
  SELECTED_PROFILES=("${available_profiles[@]}")
fi

echo "Selected profiles: ${SELECTED_PROFILES[*]}"

# Merge profile files
merged_tmp=$(mktemp -t devopstools_profiles.XXXX)
for p in "${SELECTED_PROFILES[@]}"; do
  profile_file="$PROFILES_DIR/$p.txt"
  if [ ! -f "$profile_file" ]; then
    echo "Warning: profile $p not found at $profile_file" >&2
    continue
  fi
  # strip comments and blank lines
  grep -h -v '^[[:space:]]*#' "$profile_file" | sed '/^[[:space:]]*$/d' >> "$merged_tmp"
done
sort -u "$merged_tmp" -o "$merged_tmp"

echo
echo "Merged tool list (first 200 chars):"
sed -n '1,50p' "$merged_tmp" | sed -n '1,20p'
echo

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY-RUN: installer will be invoked with merged list but no changes will be made."
fi

if [ "$NON_INTERACTIVE" -eq 0 ] && [ "$YES" -ne 1 ]; then
  printf "Proceed to run installer with these tools? [y/N]: "
  read -r ans
  case "$ans" in
    y|Y|yes|Yes) :;;
    *) echo "Aborted."; rm -f "$merged_tmp"; exit 1;;
  esac
fi

# Prefer repo-local bin/install.sh (formula installs it into bin)
if [ -f "$REPO_ROOT/bin/install.sh" ]; then
  INSTALL_SH="$REPO_ROOT/bin/install.sh"
fi
# If not present in the repo, prefer libexec or bin under Homebrew opt
if [ ! -f "$INSTALL_SH" ]; then
  if [ -x "$BREW_OPT_ROOT/libexec/install.sh" ]; then
    INSTALL_SH="$BREW_OPT_ROOT/libexec/install.sh"
  elif [ -f "$BREW_OPT_ROOT/bin/install.sh" ]; then
    INSTALL_SH="$BREW_OPT_ROOT/bin/install.sh"
  elif [ -f "$BREW_OPT_ROOT/install.sh" ]; then
    INSTALL_SH="$BREW_OPT_ROOT/install.sh"
  fi
fi

if [ ! -x "$INSTALL_SH" ]; then
  echo "Installer not found or not executable at $INSTALL_SH" >&2
  rm -f "$merged_tmp"
  exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  "$INSTALL_SH" --dry-run "$merged_tmp"
else
  "$INSTALL_SH" "$merged_tmp"
fi

rm -f "$merged_tmp"

exit 0

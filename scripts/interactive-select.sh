#!/usr/bin/env bash

# Interactive DevOps Tools Installer
# User-friendly profile selector with tool-skipping capabilities
# Works both in source tree and when installed via Homebrew

set -euo pipefail

PROG_NAME="$(basename "$0")"
HERE="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
SKIP_TOOLS=""
SELECTED_PROFILES=""

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
  cat <<'EOF'
Interactive DevOps Tools Installer

Usage: devopstools-select [OPTIONS]

OPTIONS:
  --profiles PROFILE1,PROFILE2,...   Pre-select profiles (no interactive menu)
  --skip-tool TOOL1,TOOL2,...        Skip specific tools
  --dry-run                           Show what would be installed (no changes)
  --yes                               Assume yes to all prompts
  --no-interactive                    Run non-interactively
  -h, --help                          Show this help

EXAMPLES:
  # Interactive mode (default)
  devopstools-select

  # Pre-select profiles + skip some tools
  devopstools-select --profiles base,frontend --skip-tool yarn,npm

  # Non-interactive automation
  devopstools-select --profiles base,devops --yes --no-interactive --dry-run

AVAILABLE PROFILES:
  base              Minimal tools for all developers
  frontend          Frontend development (Node, pnpm, yarn, bun)
  backend           Backend development (Python, poetry, testing)
  devops            DevOps essentials (Terraform, K8s, Cloud CLIs)
  ai                AI/LLM development (Ollama, LangChain, Jupyter)
  fullstack         Full-stack web development
  security          Security tools & scanning
  observability     Monitoring, logging, tracing
  infra-modern      Modern infrastructure (Pulumi, GitOps)
  web3              Blockchain & Web3 development
  devx              Developer experience tools (shell enhancements)

EOF
}

# Determine where the install script is
find_install_script() {
  if [ -x "$HERE/install.sh" ]; then
    echo "$HERE/install.sh"
  elif [ -x "$HERE/../install.sh" ]; then
    echo "$HERE/../install.sh"
  else
    # Assume it's in PATH or installed via Homebrew
    command -v devopstools-install || echo "$HERE/install.sh"
  fi
}

INSTALL_SCRIPT=$(find_install_script)

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --profiles)
      SELECTED_PROFILES="$2"
      shift 2
      ;;
    --skip-tool)
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
    --no-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Default: interactive=true unless --no-interactive
INTERACTIVE=${INTERACTIVE:-1}
ASSUME_YES=${ASSUME_YES:-0}

# ============ PROFILE SELECTION ============
if [ -z "$SELECTED_PROFILES" ] && [ $INTERACTIVE -eq 1 ]; then
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  DevOps Tools Installer${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo -e "${YELLOW}Select profiles to install (space-separated):${NC}"
  echo ""
  echo "  [1] base              Minimal tools for all developers"
  echo "  [2] frontend          Frontend development"
  echo "  [3] backend           Backend development"
  echo "  [4] devops            DevOps essentials"
  echo "  [5] ai                AI/LLM development"
  echo "  [6] fullstack         Full-stack web development"
  echo "  [7] security          Security tools & scanning"
  echo "  [8] observability     Monitoring & logging"
  echo "  [9] infra-modern      Modern infrastructure"
  echo "  [10] web3             Blockchain development"
  echo "  [11] devx             Developer experience"
  echo ""
  echo -e "${YELLOW}Examples: 1 2 3 (space-separated)${NC}"
  echo -e "${YELLOW}Or just 1 for base, or press Enter to skip${NC}"
  echo -n "Your selection: "
  read -r profile_input || profile_input=""

  if [ -z "$profile_input" ]; then
    echo -e "${YELLOW}No profiles selected. Exiting.${NC}"
    exit 0
  fi

  # Convert numbers to profile names
  profiles=()
  for num in $profile_input; do
    case "$num" in
      1) profiles+=("base") ;;
      2) profiles+=("frontend") ;;
      3) profiles+=("backend") ;;
      4) profiles+=("devops") ;;
      5) profiles+=("ai") ;;
      6) profiles+=("fullstack") ;;
      7) profiles+=("security") ;;
      8) profiles+=("observability") ;;
      9) profiles+=("infra-modern") ;;
      10) profiles+=("web3") ;;
      11) profiles+=("devx") ;;
      *)
        echo -e "${RED}Invalid selection: $num${NC}"
        exit 1
        ;;
    esac
  done

  SELECTED_PROFILES=$(IFS=,; echo "${profiles[*]}")
fi

if [ -z "$SELECTED_PROFILES" ]; then
  echo -e "${RED}Error: No profiles selected${NC}"
  exit 1
fi

echo -e "${GREEN}Selected profiles: $SELECTED_PROFILES${NC}"

# ============ TOOL SKIPPING ============
if [ $INTERACTIVE -eq 1 ] && [ -z "$SKIP_TOOLS" ]; then
  echo ""
  echo -e "${YELLOW}Would you like to skip any specific tools? (optional)${NC}"
  echo "Example: yarn,npm,docker"
  echo -n "Tools to skip (or press Enter to skip none): "
  read -r skip_input || skip_input=""

  if [ -n "$skip_input" ]; then
    SKIP_TOOLS="$skip_input"
    echo -e "${GREEN}Will skip: $SKIP_TOOLS${NC}"
  fi
fi

# ============ DRY RUN CHECK ============
if [ $INTERACTIVE -eq 1 ]; then
  echo ""
  echo -e "${YELLOW}Preview mode?${NC}"
  echo "  [1] Yes, show what would be installed (--dry-run)"
  echo "  [2] No, actually install now"
  echo -n "Your choice [1/2]: "
  read -r dry_run_choice || dry_run_choice="1"

  case "$dry_run_choice" in
    1|yes|y) DRY_RUN=1 ;;
    2|no|n) DRY_RUN=0 ;;
    *) DRY_RUN=1 ;;
  esac
fi

# ============ BUILD INSTALL COMMAND ============
install_cmd=("$INSTALL_SCRIPT" --profiles "$SELECTED_PROFILES")

if [ -n "$SKIP_TOOLS" ]; then
  install_cmd+=(--skip-tools "$SKIP_TOOLS")
fi

if [ $DRY_RUN -eq 1 ]; then
  install_cmd+=(--dry-run)
  echo ""
  echo -e "${BLUE}DRY RUN MODE - No changes will be made${NC}"
fi

if [ $ASSUME_YES -eq 1 ]; then
  install_cmd+=(--yes)
fi

# ============ CONFIRMATION & EXECUTION ============
if [ $INTERACTIVE -eq 1 ]; then
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  Installation Summary${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo -e "Profiles:  ${GREEN}$SELECTED_PROFILES${NC}"
  echo -e "Skip Tools: ${GREEN}${SKIP_TOOLS:-none}${NC}"
  echo -e "Mode:      ${GREEN}$([ $DRY_RUN -eq 1 ] && echo "Preview" || echo "Actual Install")${NC}"
  echo ""
  echo -e "${YELLOW}Ready to proceed? [y/N]${NC}"
  echo -n "> "
  read -r confirm || confirm="n"

  case "$confirm" in
    y|yes|Y|YES)
      echo -e "${GREEN}Proceeding with installation...${NC}"
      ;;
    *)
      echo -e "${YELLOW}Cancelled.${NC}"
      exit 0
      ;;
  esac
fi

echo ""
exec "${install_cmd[@]}"

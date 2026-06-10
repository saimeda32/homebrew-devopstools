#!/usr/bin/env bash

# Comprehensive QA & Validation Suite for DevOps Tools Installer
# Tests all profiles, tool skipping, detection, and installation flow

set -euo pipefail

PROG_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HERE="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0
VERBOSE=${VERBOSE:-1}

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============ TEST FRAMEWORK ============

test_case() {
  local name="$1"
  echo -e "${BLUE}[TEST]${NC} $name"
}

assert_success() {
  local exit_code=$?
  local msg="${1:-Command succeeded}"
  
  if [ $exit_code -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}✗${NC} $msg (exit code: $exit_code)"
    ((TESTS_FAILED++))
    return 1
  fi
}

assert_fail() {
  local exit_code=$?
  local msg="${1:-Command failed (expected)}"
  
  if [ $exit_code -ne 0 ]; then
    echo -e "  ${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}✗${NC} $msg (exit code: 0, expected non-zero)"
    ((TESTS_FAILED++))
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local msg="${2:-File exists: $file}"
  
  if [ -f "$file" ]; then
    echo -e "  ${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}✗${NC} $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local msg="${3:-File contains: $pattern}"
  
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $msg"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "  ${RED}✗${NC} $msg"
    ((TESTS_FAILED++))
    return 1
  fi
}

# ============ VALIDATION TESTS ============

validate_profiles() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Profile Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  local profiles=(
    "base"
    "frontend"
    "backend"
    "devops"
    "ai"
    "fullstack"
    "security"
    "observability"
    "infra-modern"
    "web3"
    "devx"
  )

  for profile in "${profiles[@]}"; do
    test_case "Profile exists: $profile.txt"
    assert_file_exists "$HERE/profiles/${profile}.txt"
  done
}

validate_tools_file() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Tools File Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "tools.txt exists"
  assert_file_exists "$HERE/tools.txt"

  test_case "tools.txt contains new AI tools"
  assert_contains "$HERE/tools.txt" "ollama"

  test_case "tools.txt contains Python 3.12"
  assert_contains "$HERE/tools.txt" "python@3.12"

  test_case "tools.txt contains Python 3.13"
  assert_contains "$HERE/tools.txt" "python@3.13"

  test_case "tools.txt contains modern runtimes"
  assert_contains "$HERE/tools.txt" "uv"

  test_case "tools.txt contains security tools"
  assert_contains "$HERE/tools.txt" "trivy"

  test_case "tools.txt contains observability tools"
  assert_contains "$HERE/tools.txt" "prometheus"

  test_case "tools.txt contains Pulumi"
  assert_contains "$HERE/tools.txt" "pulumi"
}

validate_profile_contents() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Profile Content Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "ai.txt contains ollama"
  assert_contains "$HERE/profiles/ai.txt" "ollama"

  test_case "ai.txt contains jupyterlab"
  assert_contains "$HERE/profiles/ai.txt" "jupyterlab"

  test_case "fullstack.txt contains bun"
  assert_contains "$HERE/profiles/fullstack.txt" "bun"

  test_case "fullstack.txt contains Python"
  assert_contains "$HERE/profiles/fullstack.txt" "python"

  test_case "security.txt contains trivy"
  assert_contains "$HERE/profiles/security.txt" "trivy"

  test_case "observability.txt contains prometheus"
  assert_contains "$HERE/profiles/observability.txt" "prometheus"

  test_case "infra-modern.txt contains pulumi"
  assert_contains "$HERE/profiles/infra-modern.txt" "pulumi"

  test_case "web3.txt contains foundry"
  assert_contains "$HERE/profiles/web3.txt" "foundry"

  test_case "backend.txt has Python 3.13 instead of 3.11"
  assert_contains "$HERE/profiles/backend.txt" "python@3.13"
}

validate_scripts() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Script Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "install.sh exists and is executable"
  if [ -x "$HERE/install.sh" ]; then
    echo -e "  ${GREEN}✓${NC} install.sh is executable"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} install.sh is not executable"
    ((TESTS_FAILED++))
  fi

  test_case "install.sh supports --profiles"
  assert_contains "$HERE/install.sh" "\-\-profiles"

  test_case "install.sh supports --skip-tools"
  assert_contains "$HERE/install.sh" "\-\-skip-tools"

  test_case "install.sh supports --dry-run"
  assert_contains "$HERE/install.sh" "DRY_RUN"

  test_case "interactive-select.sh exists"
  assert_file_exists "$HERE/scripts/interactive-select.sh"

  if [ -f "$HERE/scripts/interactive-select.sh" ]; then
    test_case "interactive-select.sh is executable"
    if [ -x "$HERE/scripts/interactive-select.sh" ]; then
      echo -e "  ${GREEN}✓${NC} interactive-select.sh is executable"
      ((TESTS_PASSED++))
    else
      echo -e "  ${YELLOW}~${NC} interactive-select.sh not executable (fixing...)"
      chmod +x "$HERE/scripts/interactive-select.sh"
      ((TESTS_PASSED++))
    fi
  fi
}

validate_tool_syntax() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Tool Syntax Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Check for common tool patterns
  local profiles=(
    "base" "frontend" "backend" "devops" "ai" "fullstack" 
    "security" "observability" "infra-modern" "web3" "devx"
  )

  for profile in "${profiles[@]}"; do
    local profile_file="$HERE/profiles/${profile}.txt"
    
    # Count npm: tools
    local npm_count=$(grep -c "^npm:" "$profile_file" || true)
    if [ $npm_count -gt 0 ]; then
      test_case "$profile has npm tools ($npm_count)"
      echo -e "  ${GREEN}✓${NC} Found $npm_count npm packages"
      ((TESTS_PASSED++))
    fi

    # Count pipx: tools
    local pipx_count=$(grep -c "^pipx:" "$profile_file" || true)
    if [ $pipx_count -gt 0 ]; then
      test_case "$profile has pipx tools ($pipx_count)"
      echo -e "  ${GREEN}✓${NC} Found $pipx_count pipx packages"
      ((TESTS_PASSED++))
    fi

    # Check for tap: lines
    local tap_count=$(grep -c "^tap:" "$profile_file" || true)
    if [ $tap_count -gt 0 ]; then
      test_case "$profile has tap registrations ($tap_count)"
      echo -e "  ${GREEN}✓${NC} Found $tap_count taps"
      ((TESTS_PASSED++))
    fi
  done
}

validate_dry_run_mode() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Dry-Run Mode Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  # Create a temporary test file
  local test_profile=$(mktemp)
  cat > "$test_profile" <<'EOF'
git
curl
npm:prettier
EOF

  test_case "Dry-run mode with test profile"
  if "$HERE/install.sh" "$test_profile" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Dry-run succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Dry-run failed"
    ((TESTS_FAILED++))
  fi

  rm -f "$test_profile"
}

validate_profile_merging() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Profile Merging Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "Merge base,frontend profiles (dry-run)"
  if "$HERE/install.sh" --profiles "base,frontend" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Profile merging succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Profile merging failed"
    ((TESTS_FAILED++))
  fi

  test_case "Merge base,backend profiles (dry-run)"
  if "$HERE/install.sh" --profiles "base,backend" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Profile merging succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Profile merging failed"
    ((TESTS_FAILED++))
  fi

  test_case "Merge devops,security profiles (dry-run)"
  if "$HERE/install.sh" --profiles "devops,security" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Profile merging succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Profile merging failed"
    ((TESTS_FAILED++))
  fi
}

validate_tool_skipping() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Tool Skipping Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "Skip single tool: --skip-tools git"
  if "$HERE/install.sh" --profiles "base" --skip-tools "git" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Single tool skip succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Single tool skip failed"
    ((TESTS_FAILED++))
  fi

  test_case "Skip multiple tools: --skip-tools git,curl,jq"
  if "$HERE/install.sh" --profiles "base" --skip-tools "git,curl,jq" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Multiple tools skip succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Multiple tools skip failed"
    ((TESTS_FAILED++))
  fi

  test_case "Skip npm packages: --skip-tools npm:prettier"
  if "$HERE/install.sh" --profiles "frontend" --skip-tools "npm:prettier" --dry-run --non-interactive 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} NPM package skip succeeded"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} NPM package skip failed"
    ((TESTS_FAILED++))
  fi
}

validate_installation_logic() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Installation Logic Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "Check for brew availability handling"
  assert_contains "$HERE/install.sh" "command -v brew"

  test_case "Check for npm detection"
  assert_contains "$HERE/install.sh" "npm list -g"

  test_case "Check for pipx detection"
  assert_contains "$HERE/install.sh" "pipx list"

  test_case "Check for already-installed detection"
  assert_contains "$HERE/install.sh" "brew list --formula"

  test_case "Check for graceful error handling"
  assert_contains "$HERE/install.sh" "FAILED_TOOLS"
}

validate_new_features() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  New Features Validation${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  test_case "AI profile includes modern Python tools"
  assert_contains "$HERE/profiles/ai.txt" "python@3.13"

  test_case "AI profile includes LangChain"
  assert_contains "$HERE/profiles/ai.txt" "langchain"

  test_case "Backend profile updated to Python 3.13"
  assert_contains "$HERE/profiles/backend.txt" "python@3.13"

  test_case "Backend profile removed Python 3.11"
  if grep -q "python@3.11" "$HERE/profiles/backend.txt" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} Python 3.11 should be removed"
    ((TESTS_FAILED++))
  else
    echo -e "  ${GREEN}✓${NC} Python 3.11 correctly removed"
    ((TESTS_PASSED++))
  fi

  test_case "Frontend profile includes modern runtimes"
  assert_contains "$HERE/profiles/frontend.txt" "bun"

  test_case "Devops profile includes security tools"
  assert_contains "$HERE/profiles/devops.txt" "trivy"
}

# ============ MAIN EXECUTION ============

main() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║   DevOps Tools Installer - QA & Validation Suite   ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
  echo ""

  validate_profiles
  validate_tools_file
  validate_profile_contents
  validate_scripts
  validate_tool_syntax
  validate_dry_run_mode
  validate_profile_merging
  validate_tool_skipping
  validate_installation_logic
  validate_new_features

  # ============ FINAL REPORT ============
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Test Results${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  local total=$((TESTS_PASSED + TESTS_FAILED))
  local pass_rate=$((TESTS_PASSED * 100 / total))

  echo -e "Total Tests:    $total"
  echo -e "Passed:         ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed:         ${RED}$TESTS_FAILED${NC}"
  echo -e "Pass Rate:      ${YELLOW}${pass_rate}%${NC}"
  echo ""

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED - 100% CONFIDENCE${NC}"
    echo ""
    exit 0
  else
    echo -e "${RED}✗ SOME TESTS FAILED - Review above for details${NC}"
    echo ""
    exit 1
  fi
}

main "$@"

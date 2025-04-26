#!/bin/bash

TOOLS_FILE=$1
LOG_FILE="$(dirname "$TOOLS_FILE")/install.log"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

INSTALLED_TOOLS=()
SKIPPED_TOOLS=()
FAILED_TOOLS=()

if [[ ! -f "$TOOLS_FILE" ]]; then
  echo -e "${RED}❌ Tools list file not found: $TOOLS_FILE${NC}"
  exit 1
fi

echo -e "${BLUE}📦 Installing tools from: $TOOLS_FILE${NC}"
echo "------------------------------------------" | tee "$LOG_FILE"

while read -r tool; do
  [[ -z "$tool" || "$tool" =~ ^# ]] && continue  # Skip comments and blank lines

  if brew list --formula | grep -q "^${tool}$"; then
    VERSION=$(brew info --json=v2 "$tool" | grep -m1 '"installed":' -A2 | grep '"version":' | awk -F'"' '{print $4}')
    echo -e "${YELLOW}➡️  $tool is already installed (version: $VERSION), skipping...${NC}" | tee -a "$LOG_FILE"
    SKIPPED_TOOLS+=("$tool ($VERSION)")
  else
    echo -e "${BLUE}➡️  Installing $tool...${NC}" | tee -a "$LOG_FILE"
    if brew install "$tool" >> "$LOG_FILE" 2>&1; then
      INSTALLED_VERSION=$(brew info --json=v2 "$tool" | grep -m1 '"installed":' -A2 | grep '"version":' | awk -F'"' '{print $4}')
      echo -e "${GREEN}✅ Successfully installed $tool (version: $INSTALLED_VERSION)${NC}" | tee -a "$LOG_FILE"
      INSTALLED_TOOLS+=("$tool ($INSTALLED_VERSION)")
    else
      echo -e "${RED}❌ Failed to install $tool. Continuing with next...${NC}" | tee -a "$LOG_FILE"
      FAILED_TOOLS+=("$tool")
    fi
  fi
done < "$TOOLS_FILE"

echo -e "\n${BLUE}📝 Installation Summary:${NC}" | tee -a "$LOG_FILE"
echo "------------------------------------------" | tee -a "$LOG_FILE"

if [ ${#INSTALLED_TOOLS[@]} -ne 0 ]; then
  echo -e "${GREEN}✅ Installed:${NC} ${INSTALLED_TOOLS[*]}" | tee -a "$LOG_FILE"
fi
if [ ${#SKIPPED_TOOLS[@]} -ne 0 ]; then
  echo -e "${YELLOW}➡️  Skipped (already installed):${NC} ${SKIPPED_TOOLS[*]}" | tee -a "$LOG_FILE"
fi
if [ ${#FAILED_TOOLS[@]} -ne 0 ]; then
  echo -e "${RED}❌ Failed:${NC} ${FAILED_TOOLS[*]}" | tee -a "$LOG_FILE"
else
  echo -e "${GREEN}🎉 All tools installed successfully!${NC}" | tee -a "$LOG_FILE"
fi

echo -e "${BLUE}📂 Detailed log saved at: $LOG_FILE${NC}"
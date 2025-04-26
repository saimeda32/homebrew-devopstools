#!/bin/bash

TOOLS_FILE=$1

if [[ ! -f "$TOOLS_FILE" ]]; then
  echo "❌ Tools list file not found: $TOOLS_FILE"
  exit 1
fi

echo "📦 Installing tools from: $TOOLS_FILE"
echo "---------------------------------------"

while read -r tool; do
  # Skip comments and blank lines
  [[ -z "$tool" || "$tool" =~ ^# ]] && continue

  # Check if the tool is already installed
  if brew list --formula | grep -q "^${tool}$"; then
    VERSION=$(brew info --json=v2 "$tool" | grep -m1 '"installed":' -A2 | grep '"version":' | awk -F'"' '{print $4}')
    echo "✅ $tool is already installed (version: $VERSION), skipping..."
  else
    echo "➡️ Installing $tool..."
    if brew install "$tool"; then
      INSTALLED_VERSION=$(brew info --json=v2 "$tool" | grep -m1 '"installed":' -A2 | grep '"version":' | awk -F'"' '{print $4}')
      echo "✅ Successfully installed $tool (version: $INSTALLED_VERSION)"
    else
      echo "⚠️ Failed to install $tool. Continuing with the next..."
    fi
  fi
done < "$TOOLS_FILE"

echo "🎉 Installation process completed!"

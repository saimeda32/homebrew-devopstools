#!/bin/bash

set -e

echo "🔧 Starting DevOps tool installation..."

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TOOLS_FILE="${SCRIPT_DIR}/tools.txt"

if [[ ! -f "$TOOLS_FILE" ]]; then
  echo "❌ tools.txt not found!"
  exit 1
fi

while IFS= read -r tool; do
  [[ -z "$tool" || "$tool" =~ ^# ]] && continue  # Skip empty lines or comments

  if brew list --formula | grep -q "^${tool}$"; then
    echo "✅ $tool is already installed, skipping..."
  else
    echo "➡️ Installing $tool..."
    if brew install $tool; then
      echo "✅ Installed $tool successfully."
    else
      echo "⚠️ Failed to install $tool. Continuing with next..."
    fi
  fi
done < "$TOOLS_FILE"

echo "🎉 Tool installation process completed!"

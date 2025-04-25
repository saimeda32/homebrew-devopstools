#!/bin/bash
set -e

TOOLS_FILE=$1

if [[ ! -f "$TOOLS_FILE" ]]; then
  echo "❌ tools.txt not found at $TOOLS_FILE"
  exit 1
fi

echo "🔧 Starting DevOps tool installation from $TOOLS_FILE..."

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

#!/usr/bin/env bash

set -euo pipefail

# Prompt for user input
read -rp "Extension namespace: " NAMESPACE
read -rp "Extension name: " EXTENSION
read -rp "Target platform [linux-x64]: " PLATFORM
PLATFORM="${PLATFORM:-linux-x64}"

# Construct API URL
API_URL="https://open-vsx.org/api/$NAMESPACE/$EXTENSION/$PLATFORM"

echo "🔍 Fetching metadata from: $API_URL"
RESPONSE=$(curl -s -f "$API_URL")

# Extract download URL from JSON
DOWNLOAD_URL=$(echo "$RESPONSE" | grep -oP '"download"\s*:\s*"\K[^"]+')

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "❌ Failed to extract download URL"
  exit 1
fi

# Determine filename from URL
FILENAME=$(basename "$DOWNLOAD_URL")

echo "⬇️ Downloading VSIX: $FILENAME"
curl -L -o "$FILENAME" "$DOWNLOAD_URL"

echo "✅ Download complete: $FILENAME"

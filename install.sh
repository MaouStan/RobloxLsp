#!/bin/bash
# Roblox LSP Install Script
# Builds and installs the extension to VSCode

set -e

echo "========================================"
echo "  Roblox LSP Install Script"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "ERROR: package.json not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Build the extension first
echo "[1/2] Building extension..."
./build.sh
echo ""

# Find the latest .vsix file
echo "[2/2] Installing extension..."
VSIX_FILE=$(ls -t robloxlsp-*.vsix 2>/dev/null | head -n 1)

if [ -n "$VSIX_FILE" ]; then
    echo "Installing: $VSIX_FILE"
    code --install-extension "$VSIX_FILE" --force
    echo ""
    echo "========================================"
    echo "  Installation complete!"
    echo "========================================"
    echo ""
    echo "Please reload VSCode:"
    echo "  Ctrl+Shift+P -> \"Developer: Reload Window\""
else
    echo "ERROR: No .vsix file found!"
    exit 1
fi

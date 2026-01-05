#!/bin/bash
# Roblox LSP Build Script
# Builds the VSCode extension and packages it as a .vsix file

set -e

echo "========================================"
echo "  Roblox LSP Build Script"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "ERROR: package.json not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "[1/4] Copying MaouData files to server..."
if [ ! -d "MaouData" ]; then
    echo "WARNING: MaouData directory not found!"
    echo "Skipping MaouData copy..."
else
    mkdir -p server/maou-data
    cp -f MaouData/en-us.json server/maou-data/ 2>/dev/null || true
    cp -f MaouData/globalTypes.d.luau server/maou-data/ 2>/dev/null || true
    if [ -f "MaouData/luau-lsp.exe" ]; then
        mkdir -p server/bin/Windows
        cp -f MaouData/luau-lsp.exe server/bin/Windows/ 2>/dev/null || true
    fi
    echo "Copied: en-us.json, globalTypes.d.luau"
fi
echo ""

echo "[2/4] Installing client dependencies..."
npm install
echo ""

echo "[3/4] Packaging extension with vsce..."
npx vsce package
echo ""

echo "[4/4] Build complete!"
echo ""

# Find the latest .vsix file
VSIX_FILE=$(ls -t robloxlsp-*.vsix 2>/dev/null | head -n 1)

if [ -n "$VSIX_FILE" ]; then
    SIZE=$(du -h "$VSIX_FILE" | cut -f1)
    echo "========================================"
    echo "  Created: $VSIX_FILE ($SIZE)"
    echo "========================================"
    echo ""
    echo "To install:"
    echo "  code --install-extension $VSIX_FILE"
    echo ""
    echo "Or run: ./install.sh"
else
    echo "WARNING: No .vsix file found!"
fi

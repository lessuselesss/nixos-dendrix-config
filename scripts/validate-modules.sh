#!/usr/bin/env bash
# validate-modules.sh - Enforce flake-parts module structure

set -euo pipefail

MODULES_DIR="modules"
EXIT_CODE=0

echo "🔍 Validating flake-parts module structure..."

# Check if modules directory exists
if [[ ! -d "$MODULES_DIR" ]]; then
    echo "❌ Modules directory '$MODULES_DIR' not found"
    exit 1
fi

# Find all .nix files in modules directory (excluding default.nix)
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    
    # Skip default.nix and other meta files
    if [[ "$filename" == "default.nix" ]]; then
        continue
    fi
    
    echo "Checking: $file"
    
    # Check 1: Must have flake-parts function signature
    if ! grep -q "{.*inputs.*,.*\.\.\..*}.*:" "$file"; then
        echo "❌ $file: Missing flake-parts function signature '{ inputs, ... }:'"
        EXIT_CODE=1
    fi
    
    # Check 2: Must define flake.nixosModules.X
    if ! grep -q "flake\.nixosModules\." "$file"; then
        echo "❌ $file: Missing 'flake.nixosModules.X' definition"
        EXIT_CODE=1
    fi
    
    # Check 3: Must not have bare NixOS module pattern
    if grep -q "^[[:space:]]*{[[:space:]]*(config\|lib\|pkgs)" "$file"; then
        echo "❌ $file: Contains bare NixOS module pattern - should be wrapped in flake.nixosModules.X"
        EXIT_CODE=1
    fi
    
    # Success indicator for valid files
    if grep -q "flake\.nixosModules\." "$file" && grep -q "{.*inputs.*,.*\.\.\..*}.*:" "$file"; then
        echo "✅ $file: Valid flake-parts module"
    fi
    
done < <(find "$MODULES_DIR" -name "*.nix" -print0)

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "🎉 All modules follow flake-parts structure!"
else
    echo "❌ Some modules need conversion to flake-parts format"
    echo ""
    echo "Expected pattern:"
    echo "{ inputs, ... }:"
    echo "{"
    echo "  flake.nixosModules.MODULE-NAME = { config, lib, pkgs, ... }: {"
    echo "    # NixOS configuration here"
    echo "  };"
    echo "}"
fi

exit $EXIT_CODE
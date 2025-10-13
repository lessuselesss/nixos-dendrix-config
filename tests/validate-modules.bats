#!/usr/bin/env bats
# Tests for module validation script

setup() {
    # Create temporary test modules directory
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/modules"
    export ORIGINAL_PWD="$PWD"
    cd "$TEST_DIR"
}

teardown() {
    cd "$ORIGINAL_PWD"
    rm -rf "$TEST_DIR"
}

@test "valid flake-parts module passes validation" {
    cat > modules/valid-module.nix << 'EOF'
{ inputs, ... }:
{
  flake.nixosModules.test = { config, lib, pkgs, ... }: {
    programs.firefox.enable = true;
  };
}
EOF
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"✅ modules/valid-module.nix: Valid flake-parts module"* ]]
}

@test "bare NixOS module fails validation" {
    cat > modules/bare-module.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  programs.firefox.enable = true;
}
EOF
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing flake-parts function signature"* ]]
    [[ "$output" == *"Missing 'flake.nixosModules.X' definition"* ]]
}

@test "module without flake.nixosModules fails validation" {
    cat > modules/no-flake-modules.nix << 'EOF'
{ inputs, ... }:
{
  # Just regular config, no flake.nixosModules
  system.stateVersion = "25.05";
}
EOF
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing 'flake.nixosModules.X' definition"* ]]
}

@test "module with wrong function signature fails validation" {
    cat > modules/wrong-signature.nix << 'EOF'
{ pkgs, ... }:
{
  flake.nixosModules.test = { config, lib, pkgs, ... }: {
    programs.firefox.enable = true;
  };
}
EOF
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing flake-parts function signature"* ]]
}

@test "default.nix is skipped" {
    cat > modules/default.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware.nix ];
}
EOF
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 0 ]
    [[ "$output" != *"default.nix"* ]]
}

@test "empty modules directory succeeds" {
    # Remove any test files
    rm -f modules/*.nix
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"All modules follow flake-parts structure"* ]]
}

@test "mixed valid and invalid modules reports correctly" {
    cat > modules/valid.nix << 'EOF'
{ inputs, ... }:
{
  flake.nixosModules.valid = { config, lib, pkgs, ... }: {
    programs.firefox.enable = true;
  };
}
EOF
    
    cat > modules/invalid.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  programs.firefox.enable = true;
}
EOF
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"✅ modules/valid.nix: Valid flake-parts module"* ]]
    [[ "$output" == *"❌ modules/invalid.nix:"* ]]
}

@test "script fails when modules directory missing" {
    rmdir modules
    
    run "$ORIGINAL_PWD/scripts/validate-modules.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Modules directory 'modules' not found"* ]]
}
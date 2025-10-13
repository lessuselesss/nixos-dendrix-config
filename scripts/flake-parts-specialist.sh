#!/usr/bin/env bash
# flake-parts-specialist.sh - Flake-Parts Architecture Specialist
# Ensures proper flake-parts structure and module composition

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES_DIR="$PROJECT_ROOT/modules"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo "Flake-Parts Specialist - Module Structure Expert"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  validate        Validate all flake-parts module structure"
    echo "  convert FILE    Convert bare NixOS module to flake-parts"
    echo "  template NAME   Generate new flake-parts module template"
    echo "  analyze         Analyze module exports and dependencies"
    echo "  check-imports   Verify all module imports are valid"
    echo "  optimize        Suggest structural optimizations"
    echo ""
    echo "Options:"
    echo "  --fix           Automatically fix issues where possible"
    echo "  --verbose       Show detailed analysis"
    echo "  --dry-run       Show what would be done without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 convert modules/old-module.nix"
    echo "  $0 template redis-config"
    echo "  $0 analyze --verbose"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

log_suggestion() {
    echo -e "${PURPLE}💡${NC} $1"
}

# Check if a file has proper flake-parts structure
check_flake_parts_structure() {
    local file="$1"
    local verbose="${2:-false}"
    local issues=()
    
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file"
        return 1
    fi
    
    local content
    content="$(cat "$file")"
    
    # Check 1: Must have flake-parts function signature
    if ! echo "$content" | grep -q "{.*inputs.*,.*\.\.\..*}.*:"; then
        issues+=("Missing flake-parts function signature '{ inputs, ... }:'")
    fi
    
    # Check 2: Must define flake.nixosModules.X
    if ! echo "$content" | grep -q "flake\.nixosModules\."; then
        issues+=("Missing 'flake.nixosModules.X' definition")
    fi
    
    # Check 3: Must not have bare NixOS module pattern
    if echo "$content" | grep -q "^[[:space:]]*{[[:space:]]*(config\|lib\|pkgs)"; then
        issues+=("Contains bare NixOS module pattern - should be wrapped in flake.nixosModules.X")
    fi
    
    # Check 4: Proper module function signature inside flake.nixosModules
    if echo "$content" | grep -q "flake\.nixosModules\." && ! echo "$content" | grep -q "{ config, lib, pkgs, \.\.\. }"; then
        issues+=("Module function should include '{ config, lib, pkgs, ... }'")
    fi
    
    # Check 5: No unused inputs parameter (common issue)
    if echo "$content" | grep -q "{ inputs, \.\.\. }" && ! echo "$content" | grep -q "inputs\."; then
        log_warning "$(basename "$file"): 'inputs' parameter is unused - consider removing if not needed"
    fi
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        if [[ "$verbose" == "true" ]]; then
            log_success "$(basename "$file"): Valid flake-parts structure"
        fi
        return 0
    else
        log_error "$(basename "$file"): Structure issues found:"
        for issue in "${issues[@]}"; do
            echo "    • $issue"
        done
        return 1
    fi
}

# Extract module name from flake-parts export
extract_module_name() {
    local file="$1"
    local module_name
    
    module_name="$(grep -o "flake\.nixosModules\.[a-zA-Z0-9_-]*" "$file" | head -1 | cut -d. -f3)"
    echo "$module_name"
}

# Validate all modules
validate_all_modules() {
    local verbose="${1:-false}"
    local fix="${2:-false}"
    local valid_count=0
    local invalid_count=0
    
    log_info "🔍 Validating flake-parts structure across all modules..."
    
    while IFS= read -r -d '' file; do
        local filename
        filename="$(basename "$file")"
        
        # Skip default.nix and other meta files
        if [[ "$filename" == "default.nix" ]]; then
            continue
        fi
        
        if check_flake_parts_structure "$file" "$verbose"; then
            ((valid_count++))
        else
            ((invalid_count++))
            
            if [[ "$fix" == "true" ]]; then
                log_info "Attempting to auto-fix $filename..."
                if auto_fix_module "$file"; then
                    log_success "Fixed $filename"
                    ((valid_count++))
                    ((invalid_count--))
                fi
            fi
        fi
        
    done < <(find "$MODULES_DIR" -name "*.nix" -print0)
    
    echo ""
    log_info "📊 Validation Results:"
    echo "  ✅ Valid modules: $valid_count"
    echo "  ❌ Invalid modules: $invalid_count"
    
    return $invalid_count
}

# Convert bare NixOS module to flake-parts
convert_to_flake_parts() {
    local file="$1"
    local dry_run="${2:-false}"
    local module_name="$3"
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    if [[ -z "$module_name" ]]; then
        log_error "Module name is required for conversion"
        return 1
    fi
    
    local content
    content="$(cat "$file")"
    
    # Check if already flake-parts
    if echo "$content" | grep -q "flake\.nixosModules\."; then
        log_warning "$(basename "$file") already appears to be a flake-parts module"
        return 0
    fi
    
    log_info "Converting $(basename "$file") to flake-parts structure..."
    
    # Create new content with flake-parts wrapper
    local new_content
    
    # Extract header comments
    local header
    header="$(echo "$content" | sed -n '1,/^[^#]/p' | sed '$d')"
    
    # Extract the actual module content (everything after header comments)
    local module_content
    module_content="$(echo "$content" | sed '/^#/d; /^$/d')"
    
    # Remove leading { inputs, ... }: or similar if it exists
    module_content="$(echo "$module_content" | sed 's/^{[^}]*}:[[:space:]]*//g')"
    
    # Ensure module_content starts with {
    if [[ ! "$module_content" =~ ^[[:space:]]*\{ ]]; then
        module_content="{\n$module_content\n}"
    fi
    
    new_content="$header
{ inputs, ... }:

{
  flake.nixosModules.$module_name = { config, lib, pkgs, ... }: $module_content
}"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Would convert to:"
        echo "$new_content"
    else
        echo "$new_content" > "$file"
        log_success "Converted $(basename "$file") to flake-parts structure"
    fi
}

# Generate new module template
generate_template() {
    local module_name="$1"
    local description="${2:-$module_name configuration}"
    
    if [[ -z "$module_name" ]]; then
        log_error "Module name is required"
        return 1
    fi
    
    # Suggest JDD naming
    log_info "💡 Consider using JDD naming convention. Run: scripts/jdd-architect.sh suggest-name '$description'"
    
    local template="# $(echo "$module_name" | tr '[:lower:]' '[:upper:]') Configuration
# $description
{ inputs, ... }:

{
  flake.nixosModules.$module_name = { config, lib, pkgs, ... }: {
    # Configuration options
    # Add your NixOS configuration here
    
    # Example:
    # programs.example.enable = true;
    # services.example = {
    #   enable = true;
    #   port = 8080;
    # };
    
    # Home Manager configuration (if needed)
    # home-manager.users.lessuseless = { pkgs, ... }: {
    #   home.packages = with pkgs; [
    #     # packages here
    #   ];
    # };
  };
}"
    
    echo "$template"
    log_success "Template generated for '$module_name'"
    log_suggestion "Copy the above template to your new module file"
}

# Analyze module exports and dependencies
analyze_modules() {
    local verbose="${1:-false}"
    declare -A exports
    declare -A imports
    declare -A home_manager_users
    
    log_info "🔬 Analyzing module structure and dependencies..."
    
    while IFS= read -r -d '' file; do
        local filename
        filename="$(basename "$file")"
        
        if [[ "$filename" == "default.nix" ]]; then
            continue
        fi
        
        local content
        content="$(cat "$file")"
        
        # Extract module exports
        local export
        export="$(echo "$content" | grep -o "flake\.nixosModules\.[a-zA-Z0-9_-]*" | head -1)"
        if [[ -n "$export" ]]; then
            local module_name
            module_name="$(echo "$export" | cut -d. -f3)"
            exports["$filename"]="$module_name"
        fi
        
        # Check for imports of other flake modules
        if echo "$content" | grep -q "inputs\.self\.nixosModules\."; then
            local module_imports
            module_imports="$(echo "$content" | grep -o "inputs\.self\.nixosModules\.[a-zA-Z0-9_-]*" | cut -d. -f4 | tr '\n' ',')"
            imports["$filename"]="$module_imports"
        fi
        
        # Check for home-manager usage
        if echo "$content" | grep -q "home-manager\.users\."; then
            local users
            users="$(echo "$content" | grep -o "home-manager\.users\.[a-zA-Z0-9_-]*" | cut -d. -f3 | sort -u | tr '\n' ',')"
            home_manager_users["$filename"]="$users"
        fi
        
    done < <(find "$MODULES_DIR" -name "*.nix" -print0)
    
    # Report findings
    echo ""
    log_info "📦 Module Exports:"
    for file in "${!exports[@]}"; do
        printf "  %-50s → %s\n" "$file" "${exports[$file]}"
    done
    
    if [[ "${#imports[@]}" -gt 0 ]]; then
        echo ""
        log_info "🔗 Module Dependencies:"
        for file in "${!imports[@]}"; do
            printf "  %-50s → %s\n" "$file" "${imports[$file]%,}"
        done
    fi
    
    if [[ "${#home_manager_users[@]}" -gt 0 ]]; then
        echo ""
        log_info "🏠 Home Manager Users:"
        for file in "${!home_manager_users[@]}"; do
            printf "  %-50s → %s\n" "$file" "${home_manager_users[$file]%,}"
        done
    fi
    
    # Check for missing exports
    local missing_exports=0
    for file in "${!exports[@]}"; do
        if [[ -z "${exports[$file]}" ]]; then
            ((missing_exports++))
        fi
    done
    
    if [[ $missing_exports -gt 0 ]]; then
        log_warning "$missing_exports modules are missing flake.nixosModules exports"
    fi
}

# Auto-fix common issues
auto_fix_module() {
    local file="$1"
    local backup_file="${file}.backup"
    
    # Create backup
    cp "$file" "$backup_file"
    
    local content
    content="$(cat "$file")"
    
    # Try to fix missing inputs parameter
    if ! echo "$content" | grep -q "{ inputs, \.\.\. }"; then
        if echo "$content" | grep -q "^[[:space:]]*{"; then
            # Replace first { with { inputs, ... }:
            content="$(echo "$content" | sed '0,/^[[:space:]]*{/s//{ inputs, ... }:\n\n{/')"
        fi
    fi
    
    # Try to wrap bare module in flake.nixosModules
    if ! echo "$content" | grep -q "flake\.nixosModules\."; then
        local basename_no_ext
        basename_no_ext="$(basename "$file" .nix)"
        local module_name
        module_name="$(echo "$basename_no_ext" | sed 's/.*--//g' | tr '-' '_')"
        
        # Wrap the content
        content="{ inputs, ... }:

{
  flake.nixosModules.$module_name = { config, lib, pkgs, ... }: $content
}"
    fi
    
    echo "$content" > "$file"
    
    # Verify the fix worked
    if check_flake_parts_structure "$file" >/dev/null 2>&1; then
        rm "$backup_file"
        return 0
    else
        # Restore backup if fix failed
        mv "$backup_file" "$file"
        return 1
    fi
}

main() {
    local command="${1:-}"
    shift || true
    
    local verbose=false
    local fix=false
    local dry_run=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                verbose=true
                shift
                ;;
            --fix)
                fix=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        validate)
            validate_all_modules "$verbose" "$fix"
            ;;
        convert)
            if [[ $# -eq 0 ]]; then
                log_error "Please provide a file to convert"
                echo "Usage: $0 convert FILE [MODULE_NAME]"
                exit 1
            fi
            local file="$1"
            local module_name="${2:-$(basename "$file" .nix | sed 's/.*--//g' | tr '-' '_')}"
            convert_to_flake_parts "$file" "$dry_run" "$module_name"
            ;;
        template)
            if [[ $# -eq 0 ]]; then
                log_error "Please provide a module name"
                echo "Usage: $0 template MODULE_NAME [DESCRIPTION]"
                exit 1
            fi
            generate_template "$1" "$2"
            ;;
        analyze)
            analyze_modules "$verbose"
            ;;
        check-imports)
            log_info "🔍 Checking module imports (not yet implemented)"
            ;;
        optimize)
            log_info "🚀 Optimization suggestions (not yet implemented)"
            ;;
        "")
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
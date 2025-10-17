#!/usr/bin/env bash
# jdd-architect.sh - Johnny Decimal Directory Architecture Specialist
# Maintains JDD integrity and provides intelligent organizational guidance

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

# JDD Categories with descriptions
declare -A JDD_CATEGORIES=(
    ["00-09"]="Meta/System Architecture"
    ["10-19"]="System Foundation (hardware, boot, networking)"
    ["20-29"]="Desktop Environment (display, audio, input)"
    ["30-39"]="Development Tools (languages, editors, terminals)"
    ["40-49"]="AI & Automation (models, servers, integrations)"
    ["50-59"]="Applications (user apps, containers, utilities)"
    ["60-69"]="Users & Identity (accounts, home-manager)"
    ["70-79"]="Services (network services, daemons)"
    ["80-89"]="Security (secrets, authentication, encryption)"
    ["90-99"]="Future/Experimental (reserved for expansion)"
)

# Meta-System Area (00-09+) Subcategories - System Directory Mapping
# Maps to important system directories in hierarchical order
declare -A META_CATEGORIES=(
    ["00"]="/etc/nixos (source configuration)"
    ["01"]="/etc (applied system configuration)"
    ["02"]="Reserved"
    ["03"]="/nix/store (immutable package store)"
    ["04"]="/nix (nix system root)"
    ["05"]="/boot (bootloader and kernel)"
    ["06"]="/root (root user home)"
    ["07"]="/run/current-system (active system generation)"
    ["08"]="/var (variable data and state)"
    ["09"]="/tmp (temporary files)"
    ["10"]="/home (user home directories)"
)

usage() {
    echo "JDD Architect - Johnny Decimal Directory Specialist"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  validate        Validate all JDD module naming and organization"
    echo "  analyze         Analyze current JDD structure and suggest improvements"
    echo "  suggest-name    Suggest proper JDD name for a module description"
    echo "  check-conflicts Check for naming conflicts and overlaps"
    echo "  reorganize      Suggest reorganization opportunities"
    echo "  stats           Show JDD statistics and distribution"
    echo ""
    echo "Options:"
    echo "  --fix           Automatically fix issues where possible"
    echo "  --verbose       Show detailed analysis"
    echo "  --json          Output in JSON format"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 suggest-name 'PostgreSQL database configuration'"
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

# Parse JDD filename into components
parse_jdd_name() {
    local filename="$1"
    local basename
    basename="$(basename "$filename" .nix)"
    
    # Expected format: XX-XX_category__XX-subcategory__XX.XX--description
    if [[ "$basename" =~ ^([0-9]{2})-([0-9]{2})_(.+)__([0-9]{2})-(.+)__([0-9]{2})\.([0-9]{2})--(.+)$ ]]; then
        echo "valid"
        echo "area_start=${BASH_REMATCH[1]}"
        echo "area_end=${BASH_REMATCH[2]}"
        echo "category=${BASH_REMATCH[3]}"
        echo "subcat_num=${BASH_REMATCH[4]}"
        echo "subcategory=${BASH_REMATCH[5]}"
        echo "item_major=${BASH_REMATCH[6]}"
        echo "item_minor=${BASH_REMATCH[7]}"
        echo "description=${BASH_REMATCH[8]}"
    else
        echo "invalid"
        echo "filename=$basename"
    fi
}

validate_jdd_structure() {
    local verbose=${1:-false}
    local fix=${2:-false}
    local valid_count=0
    local invalid_count=0
    local issues=()
    
    log_info "🏗️ Validating JDD structure across all modules..."
    
    # Check each .nix file in modules directory
    while IFS= read -r -d '' file; do
        local filename
        filename="$(basename "$file")"
        
        # Skip default.nix and other meta files
        if [[ "$filename" == "default.nix" || "$filename" == "flake.nix" ]]; then
            continue
        fi
        
        # Parse the filename
        local parse_result
        parse_result="$(parse_jdd_name "$filename")"
        
        if [[ "$(echo "$parse_result" | head -1)" == "valid" ]]; then
            ((valid_count++))
            if [[ "$verbose" == "true" ]]; then
                log_success "Valid JDD naming: $filename"
            fi
            
            # Extract components for additional validation
            eval "$parse_result"
            
            # Validate area range
            local area_key="${area_start}-${area_end}"
            if [[ ! -v JDD_CATEGORIES[$area_key] ]]; then
                log_warning "$filename: Unknown area range $area_key"
                issues+=("Unknown area: $filename ($area_key)")
            fi
            
            # Validate subcategory numbering is within area
            if [[ $subcat_num -lt $area_start || $subcat_num -gt $area_end ]]; then
                log_error "$filename: Subcategory $subcat_num outside area range $area_key"
                issues+=("Subcategory out of range: $filename")
                ((invalid_count++))
                ((valid_count--))
            fi
            
        else
            ((invalid_count++))
            eval "$parse_result"
            log_error "Invalid JDD naming: $filename"
            issues+=("Invalid naming: $filename")
            
            # Suggest correct format
            if [[ "$verbose" == "true" ]]; then
                log_suggestion "Expected format: XX-XX_category__XX-subcategory__XX.XX--description.nix"
                log_suggestion "Example: 30-39_development__31-systems-langs__31.01--rust.nix"
            fi
        fi
        
    done < <(find "$MODULES_DIR" -name "*.nix" -print0)
    
    # Summary
    echo ""
    log_info "📊 JDD Validation Results:"
    echo "  ✅ Valid modules: $valid_count"
    echo "  ❌ Invalid modules: $invalid_count"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo ""
        log_warning "Issues found:"
        for issue in "${issues[@]}"; do
            echo "    • $issue"
        done
    fi
    
    return $invalid_count
}

analyze_jdd_distribution() {
    local verbose=${1:-false}
    declare -A area_counts
    declare -A category_counts
    
    log_info "📈 Analyzing JDD distribution and organization..."
    
    while IFS= read -r -d '' file; do
        local filename
        filename="$(basename "$file")"
        
        if [[ "$filename" == "default.nix" ]]; then
            continue
        fi
        
        local parse_result
        parse_result="$(parse_jdd_name "$filename")"
        
        if [[ "$(echo "$parse_result" | head -1)" == "valid" ]]; then
            eval "$parse_result"
            local area_key="${area_start}-${area_end}"
            ((area_counts[$area_key]++))
            ((category_counts[$category]++))
        fi
        
    done < <(find "$MODULES_DIR" -name "*.nix" -print0)
    
    echo ""
    log_info "🗂️ Distribution by Area:"
    for area in $(printf '%s\n' "${!JDD_CATEGORIES[@]}" | sort); do
        local count=${area_counts[$area]:-0}
        local description="${JDD_CATEGORIES[$area]}"
        printf "  %-8s %-40s %d modules\n" "$area" "$description" "$count"
    done
    
    if [[ "$verbose" == "true" ]]; then
        echo ""
        log_info "📂 Distribution by Category:"
        for category in $(printf '%s\n' "${!category_counts[@]}" | sort); do
            printf "  %-30s %d modules\n" "$category" "${category_counts[$category]}"
        done
    fi
    
    # Identify gaps and suggest improvements
    echo ""
    log_info "💡 Organization Suggestions:"
    for area in "${!JDD_CATEGORIES[@]}"; do
        local count=${area_counts[$area]:-0}
        if [[ $count -eq 0 ]]; then
            log_suggestion "Area $area (${JDD_CATEGORIES[$area]}) has no modules - consider if any current modules should be moved here"
        elif [[ $count -gt 8 ]]; then
            log_warning "Area $area has $count modules - consider splitting into multiple areas if growing beyond 10"
        fi
    done
}

suggest_module_name() {
    local description="$1"
    
    log_info "🤔 Analyzing description: '$description'"
    
    # Simple keyword-based suggestion logic
    local suggested_area=""
    local suggested_category=""
    local suggested_subcategory=""
    
    # Convert to lowercase for matching
    local desc_lower
    desc_lower="$(echo "$description" | tr '[:upper:]' '[:lower:]')"
    
    # Area detection logic
    # Meta-System Area (00-19) - System Directory Mapping
    if [[ "$desc_lower" =~ (/etc/nixos|nixos.config|configuration.nix) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="00-nixos"
    elif [[ "$desc_lower" =~ (/etc|system.config|etc/) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="01-etc"
    elif [[ "$desc_lower" =~ (/nix/store|store|packages) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="03-store"
    elif [[ "$desc_lower" =~ (^nix |/nix|nix.system) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="04-nix"
    elif [[ "$desc_lower" =~ (/boot|bootloader|grub|systemd-boot) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="05-boot"
    elif [[ "$desc_lower" =~ (/root|root.home) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="06-root"
    elif [[ "$desc_lower" =~ (/run/current-system|current.system|generation) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="07-current-system"
    elif [[ "$desc_lower" =~ (/var|variable.data|state) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="08-var"
    elif [[ "$desc_lower" =~ (/tmp|temporary|temp) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="09-tmp"
    elif [[ "$desc_lower" =~ (/home|user.home|home.directory) ]]; then
        suggested_area="00-19"
        suggested_category="meta"
        suggested_subcategory="10-home"
    # System Foundation Area (10-19)
    elif [[ "$desc_lower" =~ (hardware|boot|kernel|driver) ]]; then
        suggested_area="10-19"
        suggested_category="system"
    elif [[ "$desc_lower" =~ (desktop|gnome|kde|window|display|audio) ]]; then
        suggested_area="20-29"
        suggested_category="desktop"
    elif [[ "$desc_lower" =~ (development|language|compiler|editor|ide|terminal) ]]; then
        suggested_area="30-39"
        suggested_category="development"
    elif [[ "$desc_lower" =~ (ai|model|ollama|claude|mcp) ]]; then
        suggested_area="40-49"
        suggested_category="ai"
    elif [[ "$desc_lower" =~ (application|app|software|tool) ]]; then
        suggested_area="50-59"
        suggested_category="apps"
    elif [[ "$desc_lower" =~ (user|home|account) ]]; then
        suggested_area="60-69"
        suggested_category="users"
    elif [[ "$desc_lower" =~ (service|daemon|server|network) ]]; then
        suggested_area="70-79"
        suggested_category="services"
    elif [[ "$desc_lower" =~ (security|secret|auth|crypto) ]]; then
        suggested_area="80-89"
        suggested_category="security"
    fi
    
    if [[ -n "$suggested_area" ]]; then
        # Extract area numbers for subcategory suggestion
        local area_start="${suggested_area%-*}"
        local area_end="${suggested_area#*-}"
        local subcat_start=$((area_start + 1))
        
        log_success "Suggested area: $suggested_area (${JDD_CATEGORIES[$suggested_area]})"
        log_suggestion "Suggested naming pattern:"
        echo "    ${suggested_area}_${suggested_category}__${subcat_start}0-subcategory__${subcat_start}0.01--$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g').nix"
    else
        log_warning "Could not automatically categorize '$description'"
        log_suggestion "Please manually select from available areas:"
        for area in $(printf '%s\n' "${!JDD_CATEGORIES[@]}" | sort); do
            echo "    $area: ${JDD_CATEGORIES[$area]}"
        done
    fi
}

check_conflicts() {
    log_info "🔍 Checking for JDD naming conflicts and overlaps..."
    
    declare -A used_numbers
    local conflicts=0
    
    while IFS= read -r -d '' file; do
        local filename
        filename="$(basename "$file")"
        
        if [[ "$filename" == "default.nix" ]]; then
            continue
        fi
        
        local parse_result
        parse_result="$(parse_jdd_name "$filename")"
        
        if [[ "$(echo "$parse_result" | head -1)" == "valid" ]]; then
            eval "$parse_result"
            local full_number="${item_major}.${item_minor}"
            
            if [[ -v used_numbers[$full_number] ]]; then
                log_error "Conflict: Number $full_number used in both:"
                echo "    - ${used_numbers[$full_number]}"
                echo "    - $filename"
                ((conflicts++))
            else
                used_numbers[$full_number]="$filename"
            fi
        fi
        
    done < <(find "$MODULES_DIR" -name "*.nix" -print0)
    
    if [[ $conflicts -eq 0 ]]; then
        log_success "No JDD numbering conflicts found!"
    else
        log_error "Found $conflicts naming conflicts"
        return 1
    fi
}

main() {
    local command="${1:-}"
    shift || true
    
    local verbose=false
    local fix=false
    local json=false
    
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
            --json)
                json=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        validate)
            validate_jdd_structure "$verbose" "$fix"
            ;;
        analyze)
            analyze_jdd_distribution "$verbose"
            ;;
        suggest-name)
            if [[ $# -eq 0 ]]; then
                log_error "Please provide a module description"
                echo "Usage: $0 suggest-name 'Description of the module'"
                exit 1
            fi
            suggest_module_name "$*"
            ;;
        check-conflicts)
            check_conflicts
            ;;
        stats)
            analyze_jdd_distribution true
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
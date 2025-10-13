#!/usr/bin/env bash
# nix-quality-auditor.sh - Nix Quality Assurance Specialist
# Runs comprehensive Nix quality checks with intelligent analysis

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
    echo "Nix Quality Auditor - Comprehensive Quality Analysis"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS] [FILES...]"
    echo ""
    echo "Commands:"
    echo "  audit           Run comprehensive quality audit (statix + deadnix + syntax)"
    echo "  statix          Run statix anti-pattern detection"
    echo "  deadnix         Run deadnix unused code detection"  
    echo "  format          Format Nix files with alejandra"
    echo "  syntax          Check Nix syntax across all files"
    echo "  report          Generate detailed quality report"
    echo "  fix             Automatically fix issues where possible"
    echo ""
    echo "Options:"
    echo "  --verbose       Show detailed output"
    echo "  --fix           Automatically apply fixes"
    echo "  --json          Output results in JSON format"
    echo "  --severity      Filter by severity: info|warn|error"
    echo ""
    echo "Examples:"
    echo "  $0 audit                    # Full audit of all modules"
    echo "  $0 statix modules/*.nix     # Check specific files"
    echo "  $0 fix --verbose           # Auto-fix with details"
    echo "  $0 report --json           # JSON quality report"
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

# Get list of Nix files to check
get_nix_files() {
    local files=("$@")
    
    if [[ ${#files[@]} -eq 0 ]]; then
        # Find all .nix files in modules directory
        find "$MODULES_DIR" -name "*.nix" -type f | sort
    else
        # Use provided files
        for file in "${files[@]}"; do
            if [[ -f "$file" ]]; then
                echo "$file"
            else
                log_warning "File not found: $file"
            fi
        done
    fi
}

# Run statix anti-pattern detection
run_statix() {
    local files=("$@")
    local statix_files
    mapfile -t statix_files < <(get_nix_files "${files[@]}")
    
    log_info "🔍 Running statix anti-pattern detection..."
    
    local statix_cmd="statix check"
    local exit_code=0
    local results
    
    # Check if statix is available
    if ! command -v statix >/dev/null 2>&1; then
        statix_cmd="nix run nixpkgs#statix -- check"
    fi
    
    # Run statix on each file and capture results
    local total_issues=0
    local files_with_issues=0
    
    for file in "${statix_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        local file_issues=0
        log_info "Checking $(basename "$file")..."
        
        if results="$($statix_cmd "$file" 2>&1)"; then
            log_success "$(basename "$file"): No issues found"
        else
            ((files_with_issues++))
            log_warning "$(basename "$file"): Issues found"
            
            # Parse and display results intelligently
            local issue_count
            issue_count="$(echo "$results" | grep -c "^W\|^E" || true)"
            ((total_issues += issue_count))
            ((file_issues += issue_count))
            
            # Display categorized results
            echo "$results" | while IFS= read -r line; do
                if [[ "$line" =~ ^W ]]; then
                    echo -e "    ${YELLOW}Warning:${NC} $line"
                elif [[ "$line" =~ ^E ]]; then
                    echo -e "    ${RED}Error:${NC} $line"
                elif [[ -n "$line" ]]; then
                    echo "    $line"
                fi
            done
            
            exit_code=1
        fi
    done
    
    # Summary
    echo ""
    log_info "📊 Statix Results:"
    echo "  Files checked: ${#statix_files[@]}"
    echo "  Files with issues: $files_with_issues"
    echo "  Total issues: $total_issues"
    
    return $exit_code
}

# Run deadnix unused code detection
run_deadnix() {
    local files=("$@")
    local deadnix_files
    mapfile -t deadnix_files < <(get_nix_files "${files[@]}")
    
    log_info "🧹 Running deadnix unused code detection..."
    
    local deadnix_cmd="deadnix"
    local exit_code=0
    
    # Check if deadnix is available
    if ! command -v deadnix >/dev/null 2>&1; then
        deadnix_cmd="nix run nixpkgs#deadnix --"
    fi
    
    local total_unused=0
    local files_with_unused=0
    
    for file in "${deadnix_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        log_info "Checking $(basename "$file")..."
        
        local results
        if results="$($deadnix_cmd "$file" 2>&1)"; then
            if [[ -z "$results" ]]; then
                log_success "$(basename "$file"): No unused code found"
            else
                log_warning "$(basename "$file"): Unused code found"
                echo "$results" | sed 's/^/    /'
                ((files_with_unused++))
                local unused_count
                unused_count="$(echo "$results" | grep -c "Unused" || true)"
                ((total_unused += unused_count))
                exit_code=1
            fi
        else
            log_error "$(basename "$file"): deadnix failed"
            echo "$results" | sed 's/^/    /'
            exit_code=1
        fi
    done
    
    # Summary
    echo ""
    log_info "📊 Deadnix Results:"
    echo "  Files checked: ${#deadnix_files[@]}"
    echo "  Files with unused code: $files_with_unused"
    echo "  Total unused items: $total_unused"
    
    return $exit_code
}

# Check Nix syntax
check_syntax() {
    local files=("$@")
    local syntax_files
    mapfile -t syntax_files < <(get_nix_files "${files[@]}")
    
    log_info "✅ Checking Nix syntax..."
    
    local exit_code=0
    local valid_files=0
    local invalid_files=0
    
    for file in "${syntax_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        if nix-instantiate --parse "$file" >/dev/null 2>&1; then
            ((valid_files++))
        else
            log_error "$(basename "$file"): Syntax error"
            ((invalid_files++))
            exit_code=1
        fi
    done
    
    # Summary
    echo ""
    log_info "📊 Syntax Check Results:"
    echo "  Valid files: $valid_files"
    echo "  Invalid files: $invalid_files"
    
    return $exit_code
}

# Format files with alejandra
format_files() {
    local files=("$@")
    local format_files
    mapfile -t format_files < <(get_nix_files "${files[@]}")
    
    log_info "🎨 Formatting Nix files with alejandra..."
    
    local alejandra_cmd="alejandra"
    
    # Check if alejandra is available
    if ! command -v alejandra >/dev/null 2>&1; then
        alejandra_cmd="nix run nixpkgs#alejandra --"
    fi
    
    local formatted_count=0
    
    for file in "${format_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        log_info "Formatting $(basename "$file")..."
        
        if $alejandra_cmd "$file"; then
            ((formatted_count++))
        else
            log_error "Failed to format $(basename "$file")"
        fi
    done
    
    log_success "Formatted $formatted_count files"
}

# Run comprehensive audit
run_audit() {
    local files=("$@")
    local verbose="${VERBOSE:-false}"
    local fix="${FIX:-false}"
    
    log_info "🕵️ Running comprehensive Nix quality audit..."
    
    local audit_files
    mapfile -t audit_files < <(get_nix_files "${files[@]}")
    
    echo ""
    log_info "Files to audit: ${#audit_files[@]}"
    
    if [[ "$verbose" == "true" ]]; then
        for file in "${audit_files[@]}"; do
            echo "  - $(basename "$file")"
        done
    fi
    
    local exit_code=0
    
    # 1. Syntax check first
    echo ""
    log_info "🔥 Phase 1: Syntax Validation"
    if ! check_syntax "${audit_files[@]}"; then
        log_error "Syntax errors found - fix these before continuing"
        return 1
    fi
    
    # 2. Anti-pattern detection
    echo ""
    log_info "🔍 Phase 2: Anti-Pattern Detection"
    if ! run_statix "${audit_files[@]}"; then
        exit_code=1
    fi
    
    # 3. Dead code detection
    echo ""
    log_info "🧹 Phase 3: Dead Code Analysis"
    if ! run_deadnix "${audit_files[@]}"; then
        exit_code=1
    fi
    
    # 4. Format check (if not fixing)
    if [[ "$fix" != "true" ]]; then
        echo ""
        log_info "🎨 Phase 4: Format Check"
        local alejandra_cmd="alejandra --check"
        if ! command -v alejandra >/dev/null 2>&1; then
            alejandra_cmd="nix run nixpkgs#alejandra -- --check"
        fi
        
        local format_issues=0
        for file in "${audit_files[@]}"; do
            if ! $alejandra_cmd "$file" >/dev/null 2>&1; then
                log_warning "$(basename "$file"): Formatting issues"
                ((format_issues++))
                exit_code=1
            fi
        done
        
        if [[ $format_issues -eq 0 ]]; then
            log_success "All files properly formatted"
        else
            log_warning "$format_issues files need formatting"
        fi
    fi
    
    # Overall summary
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "🎉 Quality audit passed! All files meet quality standards."
    else
        log_error "❌ Quality audit found issues. See details above."
        if [[ "$fix" != "true" ]]; then
            log_suggestion "Run with --fix to automatically resolve fixable issues"
        fi
    fi
    
    return $exit_code
}

# Auto-fix issues where possible
auto_fix() {
    local files=("$@")
    local fix_files
    mapfile -t fix_files < <(get_nix_files "${files[@]}")
    
    log_info "🔧 Auto-fixing Nix quality issues..."
    
    # 1. Format files
    format_files "${fix_files[@]}"
    
    # 2. Try to fix deadnix issues by removing unused parameters
    log_info "🧹 Removing unused code with deadnix..."
    
    local deadnix_cmd="deadnix --edit"
    if ! command -v deadnix >/dev/null 2>&1; then
        deadnix_cmd="nix run nixpkgs#deadnix -- --edit"
    fi
    
    for file in "${fix_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        log_info "Fixing $(basename "$file")..."
        $deadnix_cmd "$file" || log_warning "Could not auto-fix $(basename "$file")"
    done
    
    log_success "Auto-fix completed"
    
    # Run audit again to show results
    echo ""
    log_info "🔄 Re-running audit to verify fixes..."
    run_audit "${fix_files[@]}"
}

# Generate quality report
generate_report() {
    local files=("$@")
    local json="${JSON:-false}"
    
    log_info "📊 Generating quality report..."
    
    local report_files
    mapfile -t report_files < <(get_nix_files "${files[@]}")
    
    # Collect statistics
    local total_files=${#report_files[@]}
    local syntax_errors=0
    local statix_issues=0
    local deadnix_issues=0
    local format_issues=0
    
    # Check each file
    for file in "${report_files[@]}"; do
        # Syntax
        if ! nix-instantiate --parse "$file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
        
        # Statix (simplified check)
        local statix_cmd="statix check"
        if ! command -v statix >/dev/null 2>&1; then
            statix_cmd="nix run nixpkgs#statix -- check"
        fi
        if ! $statix_cmd "$file" >/dev/null 2>&1; then
            ((statix_issues++))
        fi
        
        # Deadnix (simplified check)
        local deadnix_cmd="deadnix"
        if ! command -v deadnix >/dev/null 2>&1; then
            deadnix_cmd="nix run nixpkgs#deadnix --"
        fi
        local deadnix_result
        deadnix_result="$($deadnix_cmd "$file" 2>/dev/null || true)"
        if [[ -n "$deadnix_result" ]]; then
            ((deadnix_issues++))
        fi
        
        # Format
        local alejandra_cmd="alejandra --check"
        if ! command -v alejandra >/dev/null 2>&1; then
            alejandra_cmd="nix run nixpkgs#alejandra -- --check"
        fi
        if ! $alejandra_cmd "$file" >/dev/null 2>&1; then
            ((format_issues++))
        fi
    done
    
    local clean_files=$((total_files - syntax_errors - statix_issues - deadnix_issues - format_issues))
    local quality_score
    if [[ $total_files -gt 0 ]]; then
        quality_score=$((clean_files * 100 / total_files))
    else
        quality_score=100
    fi
    
    if [[ "$json" == "true" ]]; then
        cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_files": $total_files,
  "syntax_errors": $syntax_errors,
  "statix_issues": $statix_issues,
  "deadnix_issues": $deadnix_issues,
  "format_issues": $format_issues,
  "clean_files": $clean_files,
  "quality_score": $quality_score
}
EOF
    else
        echo ""
        log_info "📈 Quality Report Summary:"
        echo "  Total files analyzed: $total_files"
        echo "  Syntax errors: $syntax_errors"
        echo "  Anti-pattern issues: $statix_issues"
        echo "  Dead code issues: $deadnix_issues"
        echo "  Format issues: $format_issues"
        echo "  Clean files: $clean_files"
        echo ""
        echo -e "  ${CYAN}Overall Quality Score: ${quality_score}%${NC}"
        
        if [[ $quality_score -ge 90 ]]; then
            log_success "Excellent code quality! 🌟"
        elif [[ $quality_score -ge 70 ]]; then
            log_warning "Good quality, but room for improvement"
        else
            log_error "Code quality needs attention"
        fi
    fi
}

main() {
    local command="${1:-}"
    shift || true
    
    # Parse global options
    VERBOSE=false
    FIX=false
    JSON=false
    SEVERITY=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --fix)
                FIX=true
                shift
                ;;
            --json)
                JSON=true
                shift
                ;;
            --severity)
                SEVERITY="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        audit)
            run_audit "$@"
            ;;
        statix)
            run_statix "$@"
            ;;
        deadnix)
            run_deadnix "$@"
            ;;
        format)
            format_files "$@"
            ;;
        syntax)
            check_syntax "$@"
            ;;
        report)
            generate_report "$@"
            ;;
        fix)
            auto_fix "$@"
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
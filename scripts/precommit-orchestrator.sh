#!/usr/bin/env bash
# precommit-orchestrator.sh - Pre-Commit Hook Management Specialist
# Manages and orchestrates all pre-commit hooks with intelligent staging

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo "Pre-Commit Orchestrator - Hook Management Specialist"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  status          Show pre-commit hook status and configuration"
    echo "  install         Install pre-commit hooks for this repository"
    echo "  run             Run all hooks on staged files"
    echo "  run-all         Run all hooks on all files"
    echo "  run-hook        Run specific hook by ID"
    echo "  validate        Validate hook configuration"
    echo "  update          Update pre-commit dependencies"
    echo "  bypass          Show how to bypass hooks (emergency use)"
    echo "  report          Generate detailed hook execution report"
    echo ""
    echo "Options:"
    echo "  --verbose       Show detailed output"
    echo "  --fix           Automatically fix issues where possible"
    echo "  --hook-id ID    Target specific hook"
    echo "  --json          Output results in JSON format"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 run-hook --hook-id statix-check"
    echo "  $0 run --fix"
    echo "  $0 report --json"
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

# Check if pre-commit is installed and available
check_precommit_available() {
    if command -v pre-commit >/dev/null 2>&1; then
        return 0
    elif command -v nix >/dev/null 2>&1; then
        log_info "Using nix-provided pre-commit"
        return 0
    else
        log_error "pre-commit not found and nix not available"
        log_suggestion "Install with: pip install pre-commit OR use nix shell"
        return 1
    fi
}

# Get pre-commit command
get_precommit_cmd() {
    if command -v pre-commit >/dev/null 2>&1; then
        echo "pre-commit"
    else
        echo "nix run nixpkgs#pre-commit --"
    fi
}

# Show detailed status of pre-commit configuration
show_status() {
    local verbose="${1:-false}"
    
    log_info "🔍 Analyzing pre-commit configuration..."
    
    # Check if pre-commit is available
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    # Check if hooks are installed
    if [[ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]]; then
        log_success "Pre-commit hooks are installed"
    else
        log_warning "Pre-commit hooks are NOT installed"
        log_suggestion "Run: $0 install"
    fi
    
    # Check configuration file
    if [[ -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]]; then
        log_success "Configuration file found: .pre-commit-config.yaml"
        
        if [[ "$verbose" == "true" ]]; then
            echo ""
            log_info "📋 Configured Hooks:"
            
            # Parse and display hooks from config
            if command -v yq >/dev/null 2>&1; then
                yq e '.repos[].hooks[] | "  - " + .id + " (" + .name + ")"' "$PROJECT_ROOT/.pre-commit-config.yaml"
            elif command -v python3 >/dev/null 2>&1; then
                python3 -c "
import yaml
with open('$PROJECT_ROOT/.pre-commit-config.yaml') as f:
    config = yaml.safe_load(f)
for repo in config.get('repos', []):
    for hook in repo.get('hooks', []):
        print(f\"  - {hook.get('id', 'unknown')} ({hook.get('name', 'unnamed')})\")
"
            else
                # Fallback: simple grep-based parsing
                grep -A 1 "^[[:space:]]*- id:" "$PROJECT_ROOT/.pre-commit-config.yaml" | 
                grep -E "(id:|name:)" | 
                paste - - | 
                sed 's/^[[:space:]]*- id:[[:space:]]*//; s/[[:space:]]*name:[[:space:]]*/ (/; s/$/)/' |
                sed 's/^/  - /'
            fi
        fi
        
        # Check if config is valid
        echo ""
        log_info "🧪 Validating configuration..."
        if $precommit_cmd validate-config >/dev/null 2>&1; then
            log_success "Configuration is valid"
        else
            log_error "Configuration has issues"
            $precommit_cmd validate-config
            return 1
        fi
        
    else
        log_error "No .pre-commit-config.yaml found"
        log_suggestion "Create configuration file first"
        return 1
    fi
    
    # Check recent hook runs
    if [[ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]]; then
        echo ""
        log_info "🕒 Recent Hook Activity:"
        
        # Try to get info about last run
        if [[ -f "$HOME/.cache/pre-commit/pre-commit.log" ]]; then
            tail -5 "$HOME/.cache/pre-commit/pre-commit.log" 2>/dev/null | sed 's/^/  /' || echo "  No recent activity logged"
        else
            echo "  No log file found"
        fi
    fi
}

# Install pre-commit hooks
install_hooks() {
    log_info "🔧 Installing pre-commit hooks..."
    
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    if [[ ! -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]]; then
        log_error "No .pre-commit-config.yaml found"
        log_suggestion "Create configuration file first"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    
    if $precommit_cmd install; then
        log_success "Pre-commit hooks installed successfully"
        
        # Verify installation
        if [[ -f ".git/hooks/pre-commit" ]]; then
            log_success "Hook files created in .git/hooks/"
            log_info "Hooks will now run automatically on git commit"
        fi
    else
        log_error "Failed to install pre-commit hooks"
        return 1
    fi
}

# Run hooks on staged files
run_hooks() {
    local fix="${1:-false}"
    local verbose="${2:-false}"
    
    log_info "🏃 Running pre-commit hooks on staged files..."
    
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    cd "$PROJECT_ROOT"
    
    local cmd_args=""
    if [[ "$verbose" == "true" ]]; then
        cmd_args="$cmd_args --verbose"
    fi
    
    local exit_code=0
    if $precommit_cmd run $cmd_args; then
        log_success "All hooks passed!"
    else
        exit_code=$?
        log_warning "Some hooks failed"
        
        if [[ "$fix" == "true" ]]; then
            log_info "Running auto-fix where possible..."
            
            # Run specific auto-fix hooks
            log_info "🎨 Auto-formatting with alejandra..."
            find modules -name "*.nix" -exec alejandra {} \; 2>/dev/null || 
                find modules -name "*.nix" -exec nix run nixpkgs#alejandra -- {} \;
            
            log_info "🧹 Removing unused code with deadnix..."
            find modules -name "*.nix" -exec deadnix --edit {} \; 2>/dev/null ||
                find modules -name "*.nix" -exec nix run nixpkgs#deadnix -- --edit {} \;
            
            log_info "Re-running hooks after auto-fix..."
            if $precommit_cmd run $cmd_args; then
                log_success "All hooks passed after auto-fix!"
                exit_code=0
            else
                log_warning "Some issues require manual attention"
            fi
        fi
    fi
    
    return $exit_code
}

# Run hooks on all files
run_all_hooks() {
    local fix="${1:-false}"
    local verbose="${2:-false}"
    
    log_info "🏃 Running pre-commit hooks on ALL files..."
    
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    cd "$PROJECT_ROOT"
    
    local cmd_args="--all-files"
    if [[ "$verbose" == "true" ]]; then
        cmd_args="$cmd_args --verbose"
    fi
    
    local exit_code=0
    if $precommit_cmd run $cmd_args; then
        log_success "All hooks passed on all files!"
    else
        exit_code=$?
        log_warning "Some hooks failed"
        
        if [[ "$fix" == "true" ]]; then
            log_info "Running auto-fix where possible..."
            
            # Run project-wide auto-fixes
            log_info "🎨 Auto-formatting all Nix files..."
            find . -name "*.nix" -not -path "./.git/*" -exec alejandra {} \; 2>/dev/null || 
                find . -name "*.nix" -not -path "./.git/*" -exec nix run nixpkgs#alejandra -- {} \;
            
            log_info "Re-running hooks after auto-fix..."
            if $precommit_cmd run $cmd_args; then
                log_success "All hooks passed after auto-fix!"
                exit_code=0
            fi
        fi
    fi
    
    return $exit_code
}

# Run specific hook by ID
run_specific_hook() {
    local hook_id="$1"
    local verbose="${2:-false}"
    
    log_info "🎯 Running specific hook: $hook_id"
    
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    cd "$PROJECT_ROOT"
    
    local cmd_args="--hook-stage manual $hook_id"
    if [[ "$verbose" == "true" ]]; then
        cmd_args="$cmd_args --verbose"
    fi
    
    if $precommit_cmd run $cmd_args; then
        log_success "Hook '$hook_id' passed!"
    else
        log_error "Hook '$hook_id' failed"
        return 1
    fi
}

# Update pre-commit dependencies
update_hooks() {
    log_info "📦 Updating pre-commit dependencies..."
    
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    cd "$PROJECT_ROOT"
    
    if $precommit_cmd autoupdate; then
        log_success "Dependencies updated successfully"
        log_suggestion "Review changes in .pre-commit-config.yaml and test with 'run-all'"
    else
        log_error "Failed to update dependencies"
        return 1
    fi
}

# Show bypass information
show_bypass_info() {
    log_warning "⚠️ Emergency Bypass Information"
    echo ""
    echo "To bypass pre-commit hooks (emergency use only):"
    echo "  git commit --no-verify -m 'message'"
    echo "  git commit -n -m 'message'"
    echo ""
    echo "To bypass specific hooks:"
    echo "  SKIP=hook-id git commit -m 'message'"
    echo "  SKIP=hook1,hook2 git commit -m 'message'"
    echo ""
    echo "To disable hooks temporarily:"
    echo "  pre-commit uninstall"
    echo "  # Do your commits"
    echo "  pre-commit install  # Re-enable"
    echo ""
    log_error "🚨 WARNING: Only use bypass in emergencies!"
    log_suggestion "Fix issues properly instead of bypassing hooks"
}

# Generate detailed execution report
generate_report() {
    local json="${1:-false}"
    local hook_results=()
    local total_hooks=0
    local passed_hooks=0
    local failed_hooks=0
    
    log_info "📊 Generating pre-commit execution report..."
    
    if ! check_precommit_available; then
        return 1
    fi
    
    local precommit_cmd
    precommit_cmd="$(get_precommit_cmd)"
    
    cd "$PROJECT_ROOT"
    
    # Get list of configured hooks
    local hooks
    if command -v yq >/dev/null 2>&1; then
        mapfile -t hooks < <(yq e '.repos[].hooks[].id' "$PROJECT_ROOT/.pre-commit-config.yaml")
    else
        mapfile -t hooks < <(grep "^[[:space:]]*- id:" "$PROJECT_ROOT/.pre-commit-config.yaml" | sed 's/^[[:space:]]*- id:[[:space:]]*//')
    fi
    
    total_hooks=${#hooks[@]}
    
    # Test each hook individually
    for hook in "${hooks[@]}"; do
        local status="unknown"
        local output=""
        
        log_info "Testing hook: $hook"
        
        if output=$($precommit_cmd run --hook-stage manual "$hook" 2>&1); then
            status="passed"
            ((passed_hooks++))
        else
            status="failed"
            ((failed_hooks++))
        fi
        
        hook_results+=("$hook:$status")
    done
    
    # Generate report
    if [[ "$json" == "true" ]]; then
        cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_hooks": $total_hooks,
  "passed_hooks": $passed_hooks,
  "failed_hooks": $failed_hooks,
  "success_rate": $(( passed_hooks * 100 / total_hooks ))%,
  "hooks": [
EOF
        local first=true
        for result in "${hook_results[@]}"; do
            local hook_name="${result%:*}"
            local hook_status="${result#*:}"
            
            [[ "$first" == "true" ]] && first=false || echo ","
            echo -n "    {\"id\": \"$hook_name\", \"status\": \"$hook_status\"}"
        done
        echo ""
        echo "  ]"
        echo "}"
    else
        echo ""
        log_info "📈 Pre-Commit Hook Report:"
        echo "  Total hooks: $total_hooks"
        echo "  Passed: $passed_hooks"
        echo "  Failed: $failed_hooks"
        echo "  Success rate: $(( passed_hooks * 100 / total_hooks ))%"
        echo ""
        
        if [[ $failed_hooks -gt 0 ]]; then
            log_warning "Failed hooks:"
            for result in "${hook_results[@]}"; do
                local hook_name="${result%:*}"
                local hook_status="${result#*:}"
                if [[ "$hook_status" == "failed" ]]; then
                    echo "  ❌ $hook_name"
                fi
            done
        fi
        
        if [[ $passed_hooks -gt 0 ]]; then
            echo ""
            log_success "Passed hooks:"
            for result in "${hook_results[@]}"; do
                local hook_name="${result%:*}"
                local hook_status="${result#*:}"
                if [[ "$hook_status" == "passed" ]]; then
                    echo "  ✅ $hook_name"
                fi
            done
        fi
    fi
}

main() {
    local command="${1:-}"
    shift || true
    
    local verbose=false
    local fix=false
    local json=false
    local hook_id=""
    
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
            --hook-id)
                hook_id="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        status)
            show_status "$verbose"
            ;;
        install)
            install_hooks
            ;;
        run)
            run_hooks "$fix" "$verbose"
            ;;
        run-all)
            run_all_hooks "$fix" "$verbose"
            ;;
        run-hook)
            if [[ -z "$hook_id" ]]; then
                log_error "Please provide hook ID with --hook-id"
                echo "Usage: $0 run-hook --hook-id HOOK_ID"
                exit 1
            fi
            run_specific_hook "$hook_id" "$verbose"
            ;;
        validate)
            log_info "🧪 Validating pre-commit configuration..."
            local precommit_cmd
            precommit_cmd="$(get_precommit_cmd)"
            cd "$PROJECT_ROOT"
            $precommit_cmd validate-config
            ;;
        update)
            update_hooks
            ;;
        bypass)
            show_bypass_info
            ;;
        report)
            generate_report "$json"
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
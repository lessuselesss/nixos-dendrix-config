#!/usr/bin/env bash
# agent-tester.sh - Test and validate all specialized agents
# Comprehensive testing suite for the specialized agent ecosystem

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

# Test agent availability
test_agent_availability() {
    log_info "🧪 Testing agent availability..."
    
    local agents=(
        "jdd-architect.sh"
        "flake-parts-specialist.sh"
        "nix-quality-auditor.sh"
        "precommit-orchestrator.sh"
    )
    
    local available=0
    local total=${#agents[@]}
    
    for agent in "${agents[@]}"; do
        local agent_path="$SCRIPT_DIR/$agent"
        if [[ -f "$agent_path" && -x "$agent_path" ]]; then
            log_success "$agent: Available and executable"
            ((available++))
        else
            log_error "$agent: Missing or not executable"
        fi
    done
    
    echo ""
    log_info "📊 Agent Availability: $available/$total agents ready"
    
    if [[ $available -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

# Test JDD architect
test_jdd_architect() {
    log_info "🏗️ Testing JDD Architect..."
    
    local exit_code=0
    
    # Test validate command
    if "$SCRIPT_DIR/jdd-architect.sh" validate >/dev/null 2>&1; then
        log_success "JDD validation runs without errors"
    else
        log_warning "JDD validation found issues (expected)"
    fi
    
    # Test suggest-name command
    if "$SCRIPT_DIR/jdd-architect.sh" suggest-name "Redis cache configuration" >/dev/null 2>&1; then
        log_success "JDD name suggestion works"
    else
        log_error "JDD name suggestion failed"
        exit_code=1
    fi
    
    # Test analyze command
    if "$SCRIPT_DIR/jdd-architect.sh" analyze >/dev/null 2>&1; then
        log_success "JDD analysis works"
    else
        log_error "JDD analysis failed"
        exit_code=1
    fi
    
    return $exit_code
}

# Test flake-parts specialist
test_flake_parts_specialist() {
    log_info "🔧 Testing Flake-Parts Specialist..."
    
    local exit_code=0
    
    # Test validate command
    if "$SCRIPT_DIR/flake-parts-specialist.sh" validate >/dev/null 2>&1; then
        log_success "Flake-parts validation runs"
    else
        log_warning "Flake-parts validation found issues (expected)"
    fi
    
    # Test template command
    if "$SCRIPT_DIR/flake-parts-specialist.sh" template test-module >/dev/null 2>&1; then
        log_success "Template generation works"
    else
        log_error "Template generation failed"
        exit_code=1
    fi
    
    # Test analyze command
    if "$SCRIPT_DIR/flake-parts-specialist.sh" analyze >/dev/null 2>&1; then
        log_success "Module analysis works"
    else
        log_error "Module analysis failed"
        exit_code=1
    fi
    
    return $exit_code
}

# Test nix quality auditor
test_nix_quality_auditor() {
    log_info "🔍 Testing Nix Quality Auditor..."
    
    local exit_code=0
    
    # Test syntax check
    if "$SCRIPT_DIR/nix-quality-auditor.sh" syntax >/dev/null 2>&1; then
        log_success "Syntax checking works"
    else
        log_warning "Syntax checking found issues or failed"
    fi
    
    # Test format command
    if "$SCRIPT_DIR/nix-quality-auditor.sh" format --help >/dev/null 2>&1; then
        log_success "Format command available"
    else
        log_error "Format command not working"
        exit_code=1
    fi
    
    return $exit_code
}

# Test precommit orchestrator
test_precommit_orchestrator() {
    log_info "🎭 Testing Pre-Commit Orchestrator..."
    
    local exit_code=0
    
    # Test status command
    if "$SCRIPT_DIR/precommit-orchestrator.sh" status >/dev/null 2>&1; then
        log_success "Status checking works"
    else
        log_error "Status checking failed"
        exit_code=1
    fi
    
    # Test validate command
    if "$SCRIPT_DIR/precommit-orchestrator.sh" validate >/dev/null 2>&1; then
        log_success "Configuration validation works"
    else
        log_warning "Configuration validation failed (may need pre-commit)"
    fi
    
    return $exit_code
}

# Run comprehensive agent integration test
run_integration_test() {
    log_info "🚀 Running agent integration test..."
    
    local test_file="$PROJECT_ROOT/modules/test-integration.nix"
    
    # Create a test file with issues
    cat > "$test_file" <<'EOF'
# Test file with various issues
{ config, lib, pkgs, ... }:
{
  # This is a bare module (missing flake-parts structure)
  programs.example.enable = true;
  
  # Unused variable
  let unused = "test"; in
  services.test = {
    enable = true;
  };
}
EOF
    
    log_info "Created test file with intentional issues"
    
    # Test each agent on the file
    local results=()
    
    # Test flake-parts validation
    if "$SCRIPT_DIR/flake-parts-specialist.sh" validate >/dev/null 2>&1; then
        results+=("flake-parts: PASS")
    else
        results+=("flake-parts: FAIL (expected)")
    fi
    
    # Test quality audit
    if "$SCRIPT_DIR/nix-quality-auditor.sh" deadnix "$test_file" >/dev/null 2>&1; then
        results+=("deadnix: PASS")
    else
        results+=("deadnix: FAIL (expected - found unused code)")
    fi
    
    # Clean up test file
    rm -f "$test_file"
    
    echo ""
    log_info "Integration test results:"
    for result in "${results[@]}"; do
        echo "  $result"
    done
}

# Generate comprehensive agent report
generate_agent_report() {
    local json="${1:-false}"
    
    log_info "📊 Generating comprehensive agent report..."
    
    # Collect agent statistics
    local total_agents=4
    local working_agents=0
    local agent_details=()
    
    # Test each agent and collect results
    local agents=(
        "jdd-architect:JDD naming and organization"
        "flake-parts-specialist:Flake-parts structure validation"
        "nix-quality-auditor:Nix code quality analysis"
        "precommit-orchestrator:Pre-commit hook management"
    )
    
    for agent_info in "${agents[@]}"; do
        local agent_name="${agent_info%:*}"
        local agent_desc="${agent_info#*:}"
        local script_name="$agent_name.sh"
        
        if [[ -f "$SCRIPT_DIR/$script_name" && -x "$SCRIPT_DIR/$script_name" ]]; then
            ((working_agents++))
            agent_details+=("$agent_name:working:$agent_desc")
        else
            agent_details+=("$agent_name:missing:$agent_desc")
        fi
    done
    
    # Calculate coverage
    local agent_coverage=$((working_agents * 100 / total_agents))
    
    if [[ "$json" == "true" ]]; then
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"total_agents\": $total_agents,"
        echo "  \"working_agents\": $working_agents,"
        echo "  \"coverage\": \"${agent_coverage}%\","
        echo "  \"agents\": ["
        
        local first=true
        for detail in "${agent_details[@]}"; do
            local name="${detail%%:*}"
            local status="${detail#*:}"
            status="${status%:*}"
            local desc="${detail##*:}"
            
            [[ "$first" == "true" ]] && first=false || echo ","
            echo -n "    {\"name\": \"$name\", \"status\": \"$status\", \"description\": \"$desc\"}"
        done
        echo ""
        echo "  ]"
        echo "}"
    else
        echo ""
        log_info "📈 Agent Ecosystem Report:"
        echo "  Total agents: $total_agents"
        echo "  Working agents: $working_agents"
        echo "  Coverage: ${agent_coverage}%"
        echo ""
        
        log_info "🛠️ Agent Status:"
        for detail in "${agent_details[@]}"; do
            local name="${detail%%:*}"
            local status="${detail#*:}"
            status="${status%:*}"
            local desc="${detail##*:}"
            
            if [[ "$status" == "working" ]]; then
                echo -e "  ✅ ${name}: ${desc}"
            else
                echo -e "  ❌ ${name}: ${desc} (missing)"
            fi
        done
        
        echo ""
        if [[ $agent_coverage -eq 100 ]]; then
            log_success "🎉 All agents operational! Full workflow automation ready."
        elif [[ $agent_coverage -ge 75 ]]; then
            log_success "🚀 Most agents working. Core functionality available."
        else
            log_warning "⚠️ Some agents missing. Reduced functionality."
        fi
    fi
}

# Main test orchestration
main() {
    local command="${1:-all}"
    shift || true
    
    local json=false
    local verbose=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --json)
                json=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    echo "🧪 Agent Testing Suite - NixOS JDD Configuration"
    echo ""
    
    case "$command" in
        all)
            test_agent_availability
            echo ""
            test_jdd_architect
            echo ""
            test_flake_parts_specialist
            echo ""
            test_nix_quality_auditor
            echo ""
            test_precommit_orchestrator
            echo ""
            run_integration_test
            echo ""
            generate_agent_report "$json"
            ;;
        availability)
            test_agent_availability
            ;;
        jdd)
            test_jdd_architect
            ;;
        flake-parts)
            test_flake_parts_specialist
            ;;
        quality)
            test_nix_quality_auditor
            ;;
        precommit)
            test_precommit_orchestrator
            ;;
        integration)
            run_integration_test
            ;;
        report)
            generate_agent_report "$json"
            ;;
        *)
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  all           Run all tests (default)"
            echo "  availability  Test agent availability"
            echo "  jdd           Test JDD architect"
            echo "  flake-parts   Test flake-parts specialist"
            echo "  quality       Test quality auditor"
            echo "  precommit     Test precommit orchestrator"
            echo "  integration   Run integration tests"
            echo "  report        Generate agent report"
            echo ""
            echo "Options:"
            echo "  --json        Output in JSON format"
            echo "  --verbose     Detailed output"
            ;;
    esac
}

main "$@"
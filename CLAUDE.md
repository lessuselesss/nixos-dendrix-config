# NixOS JDD Configuration - AI Assistant Instructions

Project-specific guidance for AI assistants working on this NixOS Johnny Decimal Directory configuration.

## 🎯 Project Context

This is a **NixOS configuration** using:
- **Johnny Decimal Directory** organization with `__` separators
- **Flake-parts architecture** for all modules  
- **Comprehensive quality assurance** with pre-commit hooks
- **24 modular components** across 5 major categories

## 📐 Critical Architecture Rules

### Module Structure Requirements
**ALL modules MUST follow this exact pattern:**
```nix
{ inputs, ... }:
{
  flake.nixosModules.MODULE-NAME = { config, lib, pkgs, ... }: {
    # NixOS configuration content
  };
}
```

**NEVER create modules that:**
- Start with `{ config, lib, pkgs, ... }:` (bare NixOS modules)
- Don't export `flake.nixosModules.X`
- Use `@` separators (use `__` double underscore)

### Johnny Decimal Naming Convention
**Required format:** `XX-XX_category__XX-subcategory__XX.XX--description.nix`

**Examples:**
- `30-39_development__31-systems-langs__31.01--rust.nix` ✅
- `40-49_ai__42-mcp__42.01--mcp-servers.nix` ✅
- `modules/rust.nix` ❌ (no JDD structure)
- `30-39_development@31-systems-langs@31.01--rust.nix` ❌ (uses @)

## 🛠️ Development Workflow

### Before Any Changes
1. **Always run validation first**: `scripts/validate-modules.sh`
2. **Check current hook status**: `pre-commit run --all-files`
3. **Test flake structure**: `nix flake check --no-build`

### Adding New Modules
1. **Create with proper JDD naming**
2. **Use flake-parts structure** (see template above)
3. **Add to hierarchical-system.nix** as `inputs.self.nixosModules.NAME`
4. **Run validation** to ensure compliance

### Quality Standards (Enforced by Hooks)
- **statix**: Must pass all anti-pattern checks
- **deadnix**: Remove unused parameters/bindings
- **detect-secrets**: No hardcoded secrets/tokens
- **shellcheck**: All shell scripts must be clean
- **JDD naming**: Enforce naming convention

## 📁 Module Categories & Naming

### System Foundation (10-19)
- `hardware`, `boot`, `networking`, `system-packages`

### Desktop Environment (20-29) 
- `gnome`, `audio`

### Development (30-39)
- `rust`, `go`, `python`, `nodejs`, `blockchain`
- `version-control`, `editors`, `terminals`

### AI & Automation (40-49)
- `ollama`, `claude-desktop`, `mcp-servers`
- `mcp-overlay`, `mcp-packages`

### Applications (50-59)
- `applications`, `distrobox`

### Users (60-69)
- `users`, `home-manager`

### Services (70-79)
- `vpn`

### Security (80-89)
- `secrets`

## 🚫 Common Mistakes to Avoid

### ❌ Wrong Module Structure
```nix
# DON'T DO THIS - bare NixOS module
{ config, lib, pkgs, ... }:
{
  programs.firefox.enable = true;
}
```

### ✅ Correct Flake-Parts Structure  
```nix
# DO THIS - proper flake-parts module
{ inputs, ... }:
{
  flake.nixosModules.firefox = { config, lib, pkgs, ... }: {
    programs.firefox.enable = true;
  };
}
```

### ❌ Wrong File Naming
- `firefox.nix` (no JDD structure)
- `50-59_apps@51-browsers@51.01--firefox.nix` (uses @)

### ✅ Correct JDD Naming
- `50-59_apps__51-browsers__51.01--firefox.nix`

## 🔧 Tools & Commands

### Validation
```bash
# Validate all modules
scripts/validate-modules.sh

# Check specific module
nix-instantiate --parse modules/MODULE-NAME.nix

# Run quality checks  
nix run nixpkgs#statix -- check modules/
nix run nixpkgs#deadnix -- modules/
```

### Pre-Commit
```bash
# Run all hooks
pre-commit run --all-files

# Run specific hook
pre-commit run statix-check
pre-commit run validate-flake-modules
```

### Testing
```bash
# Test flake
nix flake check

# Build configuration
nix build .#nixosConfigurations.nixos-hierarchical-fp.config.system.build.toplevel
```

## 🎯 AI Assistant Guidelines

### When Adding/Modifying Modules
1. **Always validate structure** before and after changes
2. **Use proper flake-parts exports** - never bare modules
3. **Follow JDD naming strictly** - use validation to verify
4. **Remove unused parameters** (deadnix will catch these)
5. **Test flake compilation** after structural changes

### When Debugging Issues
1. **Run validation first** - many issues are structure problems
2. **Check pre-commit results** - hooks catch most problems
3. **Verify module exports** are properly named and referenced
4. **Ensure all imports use correct module names**

### Documentation Updates
- **Keep README.md current** with module additions
- **Update module counts** and statistics  
- **Document new categories** or naming patterns
- **Maintain hook documentation** in README-PRECOMMIT.md

## 📊 Success Metrics

- ✅ **All modules pass validation** (`scripts/validate-modules.sh`)
- ✅ **Zero pre-commit failures** (clean hook runs)
- ✅ **Successful flake builds** (`nix flake check`)
- ✅ **No security issues** (secret detection passes)
- ✅ **Clean Nix code** (statix + deadnix clean)

## 🚀 Performance Notes

- **Module validation**: ~2-5 seconds for full check
- **Pre-commit hooks**: ~10-15 seconds for complete run  
- **Flake evaluation**: ~5-10 seconds for structure check
- **Quality tools**: statix/deadnix ~3-8 seconds per run

This configuration prioritizes **correctness over speed** - validation overhead ensures long-term maintainability and prevents technical debt.

## 🔍 Specialized Scripts & Agents

### Validation Ecosystem
- **validate-modules.sh/ts** - Module structure validation (dual shell/TypeScript implementation)
- **jdd-architect.sh** - JDD organization and naming enforcement
- **nix-quality-auditor.sh** - Code quality and syntax analysis
- **precommit-orchestrator.sh** - Pre-commit automation and orchestration
- **agent-tester.sh** - Agent ecosystem integration testing
- **run-eval-tests.sh** - Nix evaluation testing framework

### CI Pipeline Architecture (6-Stage Quality Gate)
1. **validate-structure**: JDD + flake-parts + module compliance
2. **quality-audit**: Nix syntax + comprehensive quality analysis
3. **security-scan**: Secret detection + shell script validation
4. **flake-validation**: Flake check + test build without activation
5. **agent-ecosystem-test**: Specialized agent testing with reports
6. **claude-ci-auto-fix**: AI-powered automatic CI failure resolution

## 🤖 MCP Integration & Future Claude-Code Proxy Support

### Current MCP Server Configuration
This configuration includes **15+ MCP servers** for comprehensive AI assistance:

**Core Infrastructure:**
- **mcp-server-filesystem** - File system operations
- **mcp-server-git** - Git repository management
- **mcp-server-fetch** - HTTP/API requests
- **mcp-server-memory** - Persistent memory

**Service Integrations:**
- **github-mcp-server** - GitHub API integration
- **context7-mcp** - Documentation access (integrated)
- **notion-mcp-server** - Notion workspace integration
- **playwright-mcp** - Browser automation

### Claude-Code Proxy Readiness
When your claude-code proxy becomes available, this configuration provides:

✅ **Complete CLAUDE.md context** with architectural rules and patterns
✅ **MCP server integration** already configured and tested
✅ **Quality validation scripts** for automated checking
✅ **Documentation-driven development** patterns established
✅ **Context7 integration** for real-time documentation access

### Auto-Fix Workflow Enhancement
The `claude-ci-auto-fix.yml` workflow includes:
- **Context7 MCP integration** for up-to-date documentation
- **Documentation-driven fixing** with 5-step process
- **Flake-parts expertise** built into prompts
- **JDD naming enforcement** 
- **Quality standards validation**

## 📈 Updated Statistics

- **25 Flake-Parts Modules**: All validated and consistent
- **8 Major Categories**: Systematic 00-89 organization
- **23 Pre-commit Hooks**: Comprehensive quality assurance
- **6-Stage CI Pipeline**: Multi-layer validation architecture
- **15+ MCP Servers**: AI-first development environment
- **Zero Configuration Drift**: Automated structure enforcement

## 🔮 Claude-Code Proxy Integration

This configuration is **fully prepared** for claude-code proxy integration:

### Ready Components
- **Comprehensive documentation** in CLAUDE.md
- **MCP server ecosystem** already configured
- **Quality validation pipeline** automated
- **Context7 documentation access** integrated
- **Flake-parts expertise** encoded in CI workflows

### Expected Benefits with Proxy
- **Seamless AI assistance** using existing MCP servers
- **Context-aware suggestions** leveraging CLAUDE.md
- **Automated quality assurance** with validation scripts
- **Real-time documentation** access via Context7
- **Consistent architectural patterns** enforcement


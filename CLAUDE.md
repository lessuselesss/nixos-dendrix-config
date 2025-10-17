# NixOS JDD Configuration - AI Assistant Instructions

Project-specific guidance for AI assistants working on this NixOS Johnny Decimal Directory configuration.

## 🎯 Project Context

This is a **NixOS configuration** using:
- **Johnny Decimal Directory** organization with `__` separators
- **Flake-parts architecture** for all modules  
- **Comprehensive quality assurance** with pre-commit hooks
- **24 modular components** across 5 major categories

## 📐 Critical Architecture Rules

### Understanding the Architecture Stack

This configuration uses a **Dendrix + Flake-Parts** architecture:

```
┌─────────────────────────────────────────────────────┐
│  flake.nix (Entry Point)                           │
│  ├─ Uses flake-parts.lib.mkFlake                  │
│  └─ Delegates to import-tree ./modules            │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  import-tree (Module Discovery)                    │
│  ├─ Recursively scans ./modules/*.nix              │
│  ├─ Returns { imports = [ ... ]; }                │
│  └─ Passes to flake-parts module system           │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Flake-Parts (Module System)                       │
│  ├─ Merges all module definitions                 │
│  ├─ Combines perSystem blocks                     │
│  └─ Generates final flake outputs                 │
└─────────────────────────────────────────────────────┘
```

### What Gets Merged by import-tree + flake-parts

**✅ Automatically Merged (use these):**
```nix
{ inputs, ... }:
{
  # NixOS/Darwin/Home-Manager modules
  flake.nixosModules.my-module = { ... };       # ✅ Merged
  flake.darwinModules.my-module = { ... };      # ✅ Merged
  flake.homeModules.my-module = { ... };        # ✅ Merged

  # Overlays
  flake.overlays.my-overlay = final: prev: { ... };  # ✅ Merged

  # Per-system outputs (packages, apps, devShells)
  perSystem = { config, pkgs, system, ... }: {
    packages.my-package = ...;   # ✅ Merged per system
    apps.my-app = ...;           # ✅ Merged per system
    devShells.default = ...;     # ✅ Merged per system
  };
}
```

**❌ NOT Merged (don't use these):**
```nix
{
  # Direct system-specific exports (nested attributes not merged)
  flake.packages.x86_64-linux.foo = ...;    # ❌ Won't merge
  flake.apps.x86_64-linux.bar = ...;        # ❌ Won't merge
}
```

### Module Structure Requirements

**Standard NixOS Module (Most Common):**
```nix
{ inputs, ... }:
{
  flake.nixosModules.MODULE-NAME = { config, lib, pkgs, ... }: {
    # NixOS configuration content
    programs.firefox.enable = true;
  };
}
```

**Package/App Module (For Utilities):**
```nix
# File: modules/XX-XX_category__YY-subcat__YY.ZZ--my-tool.nix
{ inputs, ... }:
{
  # Per-system packages and apps
  perSystem = { config, pkgs, system, ... }:
  let
    myTool = pkgs.writeShellScriptBin "my-tool" ''
      echo "Hello from my tool!"
    '';
  in
  {
    packages = {
      # Module attribute name (primary) - matches module numbering
      "YY.ZZ-my-tool" = myTool;
      # Friendly alias
      my-tool = myTool;
    };

    apps = {
      # Module attribute name (primary)
      "YY.ZZ-my-tool" = {
        type = "app";
        program = "${myTool}/bin/my-tool";
      };
      # Friendly alias
      my-tool = {
        type = "app";
        program = "${myTool}/bin/my-tool";
      };
    };
  };

  # Optional: Also export as overlay for system packages
  flake.overlays."YY.ZZ-my-tool" = final: prev: {
    my-tool = inputs.self.packages.${prev.system}.my-tool or prev.hello;
  };

  # Optional: Add to NixOS system packages
  flake.nixosModules."YY.ZZ-my-tool" = { pkgs, ... }: {
    nixpkgs.overlays = [ inputs.self.overlays."YY.ZZ-my-tool" ];
    environment.systemPackages = [ pkgs.my-tool ];
  };
}
```

**Usage:**
```bash
# Using module attribute name (recommended for clarity)
nix run .#YY.ZZ-my-tool

# Using friendly alias (shorter)
nix run .#my-tool
```

**Package Naming Convention:**
All utility packages/apps should follow this pattern:
- **Primary name**: `"XX.YY-descriptive-name"` (matches module attribute number)
- **Friendly alias**: `descriptive-name` (short form)

Examples:
- Module `00.05--jdd-architect-app.nix` → package `"00.05-jdd-architect"` + alias `jdd-architect`
- Module `91.02--check-impermanence.nix` → package `"91.02-check-impermanence"` + alias `map-impermanence`

This allows discovery by module number while keeping convenient short names.

**NEVER create modules that:**
- Start with `{ config, lib, pkgs, ... }:` (bare NixOS modules)
- Don't export via `flake.*` or `perSystem`
- Use `@` separators (use `__` double underscore)
- Define `flake.packages.x86_64-linux.*` directly (use `perSystem` instead)
- Have circular references in package definitions (use `let ... in` pattern)

### Flake-File Integration (Optional Layer)

This configuration uses `flake-file` for **modular input management**:

**How it works:**
1. Define inputs in modules where they're used:
   ```nix
   { inputs, ... }:
   {
     flake.inputs.my-dep = {
       url = "github:user/repo";
       inputs.nixpkgs.follows = "nixpkgs";
     };
   }
   ```

2. Regenerate `flake.nix` when inputs change:
   ```bash
   nix run .#write-flake
   ```

**Note:** The `flake.nix` is marked as auto-generated but can be manually edited. If you edit it manually:
- Remove the "DO-NOT-EDIT" comment
- Don't run `write-flake` (it will overwrite your changes)
- Maintain the `perSystem` block for package/app exports

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

### Meta/System Architecture (00-19)
System directory mapping and core configuration (00-10):
- **00**: `/etc/nixos` - Source configuration
- **01**: `/etc` - Applied system configuration
- **02**: Reserved
- **03**: `/nix/store` - Immutable package store
- **04**: `/nix` - Nix system root
- **05**: `/boot` - Bootloader and kernel
- **06**: `/root` - Root user home
- **07**: `/run/current-system` - Active system generation
- **08**: `/var` - Variable data and state
- **09**: `/tmp` - Temporary files
- **10**: `/home` - User home directories

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

## 🧪 Module Structure Testing

This configuration includes a comprehensive testing infrastructure to validate module patterns and flake-parts integration.

### Test Module (09.01)
Location: `modules/00-19_meta__09-tests__09.01--module-structure-test.nix`

Demonstrates all correct patterns:
```nix
{ inputs, ... }:
{
  # Test 1: NixOS Module Export
  flake.nixosModules."09.01-test-nixos-module" = { config, lib, pkgs, ... }: {
    environment.systemPackages = [ ];
  };

  # Test 2: Overlay Export
  flake.overlays."09.01-test-overlay" = final: prev: {
    test-package = prev.hello;
  };

  # Test 3: perSystem Package Export
  perSystem = { config, pkgs, system, ... }: {
    packages.test-package = pkgs.writeShellScriptBin "test-module-structure" ''
      echo "✅ Module structure test PASSED"
    '';

    # Test 4: perSystem App Export
    apps.test-structure = {
      type = "app";
      program = "${config.packages.test-package}/bin/test-module-structure";
    };
  };
}
```

### Validation Script
Location: `scripts/test-module-structure.sh`

Runs 6 comprehensive tests:
1. **Export Pattern Validation**: Ensures all modules use `flake.*` or `perSystem` exports
2. **Nested Export Detection**: Catches incorrect `flake.packages.x86_64-linux.*` usage
3. **Package Evaluation**: Verifies flake packages evaluate correctly
4. **Overlay Merging**: Tests that overlays are properly merged by flake-parts
5. **NixOS Module Merging**: Tests that nixosModules are properly merged
6. **perSystem Execution**: Runs the test package to verify perSystem works end-to-end

**Usage:**
```bash
# Run all module structure tests
scripts/test-module-structure.sh

# Expected output on success:
# ✅ PASS: All modules use flake.* or perSystem exports
# ✅ PASS: No modules use incorrect nested exports
# ✅ PASS: Flake packages evaluate correctly
# ✅ PASS: Overlays are merged (N overlays found)
# ✅ PASS: NixOS modules are merged (N modules found)
# ✅ PASS: perSystem packages work correctly
```

**What it catches:**
- Bare NixOS modules without flake-parts wrapper
- Direct system-specific exports (should use perSystem)
- Broken flake-parts merging
- Package evaluation failures

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

# Test module structure patterns
scripts/test-module-structure.sh

# Run test package to verify perSystem works
nix run .#test-package
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
- ✅ **Module structure tests pass** (`scripts/test-module-structure.sh`)
- ✅ **Test package runs successfully** (`nix run .#test-package`)
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
- **test-module-structure.sh** - Module pattern testing (flake-parts + perSystem validation)
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


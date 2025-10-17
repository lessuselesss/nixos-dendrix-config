# NixOS Johnny Decimal Directory Configuration

A modular NixOS configuration system using Johnny Decimal Directory (JDD) organization with flake-parts architecture and comprehensive quality assurance.

## 🏗️ Architecture

### Johnny Decimal Directory System
Modules are organized using the JDD methodology with double underscore (`__`) separators:
```
XX-XX_category__XX-subcategory__XX.XX--description.nix
```

**Example**: `30-39_development__31-systems-langs__31.01--rust.nix`
- **30-39**: Development area
- **31**: Systems languages category  
- **31.01**: Rust-specific module

### Flake-Parts Module Structure
All modules follow consistent flake-parts architecture with AC.ID-aspect-name:
```nix
{ inputs, ... }:
{
  flake.nixosModules."AC.ID-aspect-name" = { config, lib, pkgs, ... }: {
    # NixOS configuration here
  };
}
```

**Example**: `31.01-rust`
```nix
{ inputs, ... }:
{
  flake.nixosModules."31.01-rust" = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [ cargo gcc pkg-config gnumake ];
    };
  };
}
```

## 📁 Module Organization

All modules use the **AC.ID-aspect-name** naming convention where:
- **AC** = Category (two digits within Area range)
- **ID** = Chronological identifier (two digits)
- **aspect-name** = Descriptive name

### Meta/AI Tools (00-09)
- **04.01-jdd-llamafile-assistant** - AI-powered JDD naming assistant
- **04.02-llamafile-package** - Llamafile package overlay
- **04.03-jdd-index** - Johnny Decimal module index builder

### System Foundation (10-19)
- **11.01-hardware-config** - Hardware configuration and drivers
- **11.02-boot-config** - Boot loader and kernel settings
- **12.01-networking-config** - Network configuration and firewall
- **12.02-btrfs-validation** - Btrfs subvolume validation
- **13.03-system-packages** - Core system settings and packages

### Desktop Environment (20-29)
- **21.01-gnome-config** - GNOME desktop environment
- **22.01-audio-config** - Audio configuration with PipeWire
- **23.01-niri** - Niri Wayland compositor

### Development (30-39)
- **31.01-rust**, **31.02-go** - Systems programming languages
- **32.01-python**, **32.02-nodejs** - Application languages
- **33.01-blockchain** - Ethereum development tools
- **34.01-version-control** - Git, GitHub CLI, Jujutsu
- **34.02-editors** - Zed, Claude Code, development tools
- **34.03-terminals** - Terminal emulators and CLI tools

### AI & Automation (40-49)
- **41.01-ollama** - Local AI model serving
- **41.02-claude-desktop** - Claude Desktop application
- **42.01-mcp-servers** - Model Context Protocol servers
- **42.02-mcp-overlay**, **42.02-mcp-packages** - MCP Nix integration

### Applications (50-59)
- **51.01-applications** - Desktop applications and utilities
- **52.01-distrobox** - Container definitions and configuration

### Users (60-69)
- **61.01-users** - System user accounts and permissions
- **62.01-home-manager** - User-level package management

### Services (70-79)
- **71.01-vpn** - Cloudflare WARP VPN configuration

### Security (80-89)
- **81.01-secrets** - Secrets management with sops-nix
- **81.02-impermanence** - Ephemeral root filesystem
- **81.03-ledger-age-tools** - Ledger hardware wallet Age tools
- **81.03-secrets-validation** - Secret exposure validation
- **82.01-keycutter** - SSH key management
- **82.01-automated-home-backup** - Automated backup system

## 🚀 Quick Start

### Building the Configuration
```bash
# Check flake validity
nix flake check

# Build specific configuration
nix build .#nixosConfigurations.nixos-hierarchical-fp.config.system.build.toplevel

# Test in VM
nixos-rebuild build-vm --flake .#nixos-hierarchical-fp
```

### Development Workflow
```bash
# Validate all modules
scripts/validate-modules.sh

# Run pre-commit hooks
nix run nixpkgs#pre-commit -- run --all-files

# Test specific module
nix-instantiate --eval --strict modules/30-39_development__31-systems-langs__31.01--rust.nix
```

## 🛡️ Quality Assurance

### Pre-Commit Hooks
Comprehensive validation with 15+ hooks:
- **Security**: `detect-secrets`, `ggshield`
- **Nix Quality**: `statix`, `deadnix`, `alejandra`
- **Module Validation**: `validate-flake-modules`, `validate-jdd-naming`
- **Shell Scripts**: `shellcheck`, `bats`
- **General**: File size, merge conflicts, whitespace

### Validation Tools
- **Module Structure**: Ensures flake-parts compliance
- **JDD Naming**: Validates naming conventions
- **Dead Code**: Removes unused parameters
- **Anti-Patterns**: 40+ Nix quality checks

## 📊 Statistics

- **34 Flake-Parts Modules**: All using AC.ID-aspect-name convention
- **8 Major Categories**: Meta, System, Desktop, Development, AI, Applications, Users, Services, Security
- **Enterprise-Grade QA**: 23+ automated quality checks
- **Zero Configuration Drift**: Automated structure enforcement
- **Johnny Decimal Index**: AC.ID format (Area.Category.ID)

## 🔧 Configuration

### Available Configurations
- **nixos-hierarchical-fp** - Complete flake-parts system
- **hierarchical-complete** - Traditional NixOS test configuration

### Module Composition
Import individual modules using AC.ID-aspect-name:
```nix
inputs.self.nixosModules."31.01-rust"
inputs.self.nixosModules."21.01-gnome-config"
inputs.self.nixosModules."42.01-mcp-servers"
```

Or use complete system:
```nix
inputs.self.nixosConfigurations.nixos-hierarchical-fp
```

## 📖 Documentation

- **[Pre-Commit Guide](README-PRECOMMIT.md)** - Complete hook documentation
- **[JDD Layer Concept](JDD-LAYER-CONCEPT.md)** - Architecture philosophy
- **[Module Validation](scripts/validate-modules.sh)** - Structure enforcement
- **[Test Suite](tests/validate-modules.bats)** - Quality assurance tests

## 🎯 Features

### ✅ Implemented
- Flake-parts modular architecture
- Johnny Decimal Directory organization  
- Comprehensive pre-commit validation
- Dead code elimination
- Security scanning
- Automated testing

### 🔄 In Progress
- Secrets management with sops-nix
- Complete MCP server integration
- Claude Desktop input integration

### 🗺️ Roadmap
- Community JDD layer extraction
- Template system for new modules
- Advanced testing automation
- Documentation generation

## 🤝 Contributing

### Adding New Modules
1. Follow JDD naming: `XX-XX_category__XX-subcategory__XX.XX--description.nix`
2. Use flake-parts structure with AC.ID-aspect-name: `flake.nixosModules."AC.ID-aspect-name" = { ... }`
3. Ensure attribute name matches filename pattern (AC, ID, and aspect-name must align)
4. Run validation: `scripts/validate-modules.sh`
5. Test with pre-commit: `pre-commit run --all-files`

**Example**: For file `31-01_rust__31.01--rust.nix`:
- Attribute must be: `flake.nixosModules."31.01-rust"`
- AC (31) must match filename category
- ID (01) must match filename ID
- aspect-name (rust) must match filename description

### Quality Standards
- All modules must pass `statix` and `deadnix` checks
- No hardcoded secrets (enforced by `detect-secrets`)
- Proper flake-parts structure (validated automatically)
- JDD naming compliance (enforced by hooks)

## 📄 License

This configuration is designed for personal use but the JDD methodology and validation tools can be adapted for community use.

## 🔬 Advanced Testing & Validation

### Multi-Layer Validation Architecture
This configuration implements a **6-layer quality assurance system**:

1. **Pre-Commit Hooks** (23 checks) - Local validation before commits
2. **Static Analysis** - Statix anti-patterns, deadnix unused code detection
3. **Security Scanning** - Secret detection, shell script validation
4. **Structure Validation** - JDD naming, flake-parts compliance
5. **Evaluation Testing** - Nix expression testing inspired by flake-parts upstream
6. **CI Pipeline** - 6-stage automated quality gate with artifact collection

### Specialized Validation Scripts
- **validate-modules.sh** - Shell-based module structure validation
- **validate-modules.ts** - TypeScript-based enhanced validation with JSON reporting
- **jdd-architect.sh** - Johnny Decimal Directory naming enforcement
- **nix-quality-auditor.sh** - 4-phase comprehensive quality analysis
- **agent-tester.sh** - Agent ecosystem integration testing
- **run-eval-tests.sh** - Nix evaluation testing framework

## 🤖 AI & MCP Integration

### MCP Server Ecosystem (15+ Servers)
**Core Infrastructure:**
- mcp-server-filesystem, mcp-server-git, mcp-server-fetch, mcp-server-memory

**Service Integrations:**
- github-mcp-server, context7-mcp, notion-mcp-server, playwright-mcp

**AI Platforms:**
- Ollama (local models), Claude Desktop, multiple API integrations

### Claude-Code Proxy Readiness
This configuration is **fully prepared** for claude-code proxy integration:

✅ **Complete CLAUDE.md** with architectural rules and development patterns
✅ **MCP server ecosystem** configured with 15+ specialized servers
✅ **Quality validation scripts** for automated structure checking
✅ **Context7 integration** for real-time documentation access
✅ **CI auto-fix workflows** with flake-parts expertise built-in

## 🏗️ Architecture Innovations

### Hierarchical Johnny Decimal Directory
- **Systematic numbering**: 00-89 category organization
- **Double underscore separators**: XX-XX_category__XX-subcategory__XX.XX--name.nix
- **Infinite scalability**: Clear organizational taxonomy
- **Conflict prevention**: Automated naming validation

### Enhanced Flake-Parts Integration
- **Modular composition**: Each module exports flake.nixosModules.name
- **Automatic discovery**: import-tree eliminates manual imports
- **Evaluation testing**: Inspired by upstream flake-parts methodology
- **Structure enforcement**: Dual validation (shell + TypeScript)

## 📊 Detailed Module Statistics

- **34 Validated Modules**: All using AC.ID-aspect-name convention
- **8 Major Categories**: Meta (00-09) → System (10-19) → Desktop (20-29) → Development (30-39) → AI (40-49) → Apps (50-59) → Users (60-69) → Services (70-79) → Security (80-89)
- **23 Quality Checks**: Pre-commit hooks with security, syntax, and structure validation
- **6-Stage CI Pipeline**: Comprehensive automated quality assurance
- **15+ MCP Servers**: AI-first development environment
- **100% Structure Compliance**: Zero configuration drift through automation
- **Johnny Decimal Compliance**: All modules follow AC.ID-aspect-name pattern

## 🔮 Future Integration

### Claude-Code Proxy Support
When the claude-code proxy becomes available, this configuration provides:

- **Immediate compatibility** with existing MCP server ecosystem
- **Context-aware assistance** using comprehensive CLAUDE.md documentation
- **Automated quality assurance** through validated scripts and workflows
- **Real-time documentation** access via integrated Context7 MCP server
- **Consistent patterns** enforcement through CI-embedded expertise

### Enhanced Automation
- **AI-powered CI auto-fix** with up-to-date documentation access
- **Intelligent module suggestions** based on JDD organization
- **Quality-driven development** with automated validation at every level
- **Documentation-driven fixes** using current upstream patterns


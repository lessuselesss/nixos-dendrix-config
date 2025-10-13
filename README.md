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
All modules follow consistent flake-parts architecture:
```nix
{ inputs, ... }:
{
  flake.nixosModules.MODULE-NAME = { config, lib, pkgs, ... }: {
    # NixOS configuration here
  };
}
```

## 📁 Module Organization

### System Foundation (10-19)
- **hardware** - Hardware configuration and drivers
- **boot** - Boot loader and kernel settings
- **networking** - Network configuration and firewall
- **system-packages** - Core system settings and packages

### Desktop Environment (20-29)
- **gnome** - GNOME desktop environment
- **audio** - Audio configuration with PipeWire

### Development (30-39)
- **rust**, **go**, **python**, **nodejs** - Language toolchains
- **blockchain** - Ethereum development tools
- **version-control** - Git, GitHub CLI, Jujutsu
- **editors** - Zed, Claude Code, development tools
- **terminals** - Terminal emulators and CLI tools

### AI & Automation (40-49)
- **ollama** - Local AI model serving
- **claude-desktop** - Claude Desktop application
- **mcp-servers** - Model Context Protocol servers
- **mcp-overlay**, **mcp-packages** - MCP Nix integration

### Applications (50-59)
- **applications** - Desktop applications and utilities
- **distrobox** - Container definitions and configuration

### Users (60-69)
- **users** - System user accounts and permissions
- **home-manager** - User-level package management

### Services (70-79)
- **vpn** - Cloudflare WARP VPN configuration

### Security (80-89)
- **secrets** - Secrets management with sops-nix

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

- **24 Flake-Parts Modules**: All validated and consistent
- **5 Major Categories**: System, Desktop, Development, AI, Applications
- **Enterprise-Grade QA**: 15+ automated quality checks
- **Zero Configuration Drift**: Automated structure enforcement

## 🔧 Configuration

### Available Configurations
- **nixos-hierarchical-fp** - Complete flake-parts system
- **hierarchical-complete** - Traditional NixOS test configuration

### Module Composition
Import individual modules:
```nix
inputs.self.nixosModules.rust
inputs.self.nixosModules.gnome
inputs.self.nixosModules.mcp-servers
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
2. Use flake-parts structure: `flake.nixosModules.name = { ... }`
3. Run validation: `scripts/validate-modules.sh`
4. Test with pre-commit: `pre-commit run --all-files`

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

## 📊 Updated Statistics

- **25 Validated Modules**: All following flake-parts structure
- **8 Major Categories**: System → Desktop → Development → AI → Apps → Users → Services → Security
- **23 Quality Checks**: Pre-commit hooks with security, syntax, and structure validation
- **6-Stage CI Pipeline**: Comprehensive automated quality assurance
- **15+ MCP Servers**: AI-first development environment
- **100% Structure Compliance**: Zero configuration drift through automation

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


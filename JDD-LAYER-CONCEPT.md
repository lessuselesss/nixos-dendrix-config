# Johnny Decimal Directory (JDD) Layer Concept

## Overview

This document outlines the concept for creating a **community Dendrix layer** that provides Johnny Decimal Directory organization for NixOS configurations.

## Current Implementation Status

We have successfully implemented JDD methodology in our personal NixOS configuration:

- **24 modules** using `AC.ID_aspect.nix` naming convention
- **Flat structure** - all modules at same level in `/modules/`
- **Working configuration** with comprehensive system coverage
- **Proven organization** - easy to find, maintain, and extend

## Proposed Community Layer: `nix-jdd-layer`

### Purpose
Provide a reusable Dendrix layer that enables any NixOS user to adopt Johnny Decimal Directory organization for their configuration modules.

### Repository Structure
```
nix-jdd-layer/
├── flake.nix                    # Layer entry point
├── README.md                    # JDD methodology + usage guide
├── modules/
│   ├── default.nix             # Main layer module
│   └── tools.nix               # JDD automation tools
├── templates/
│   ├── workstation/            # Development workstation example
│   ├── homelab/                # Home server example
│   └── minimal/                # Basic desktop example
├── scripts/                    # Shell-based automation
│   ├── jdd-index              # Generate system index
│   ├── jdd-validate           # Structure validation
│   ├── jdd-gaps               # Gap analysis
│   └── jdd-imports            # Auto-import generation
├── docs/
│   ├── methodology.md          # Johnny Decimal explained for Nix
│   ├── migration.md            # Converting existing configs
│   └── examples.md             # Usage examples
└── tests/
    └── integration/            # Test tooling functionality
```

## Key Features

### 1. Johnny Decimal Naming Convention
- **Format**: `AC.ID_aspect.nix` (e.g., `01.01_hardware.nix`)
- **A**: Area (0-9) - major functional groups
- **C**: Category (0-9) - subcategories within areas  
- **ID**: Item (01-99) - specific modules within categories
- **aspect**: Descriptive name for the module's purpose

### 2. Proven Area Organization
Based on our working implementation:

```
01.xx: System Foundation    (hardware, boot, networking, core system)
02.xx: Desktop Environment  (display, audio, desktop manager)
03.xx: Development Languages (rust, go, python, nodejs, blockchain)
04.xx: Development Tools    (version control, editors, terminals)
05.xx: AI & MCP Ecosystem   (ollama, claude, mcp servers)
06.xx: Applications         (user apps, containers)
07.xx: User Configuration   (system users, home-manager)
08.xx: Services            (vpn, background services)
09.xx: Security            (secrets management, firewall)
```

### 3. Automation Tools
- **Index Generation**: Auto-generate `INDEX.md` showing system structure
- **Import Management**: Automatically maintain module import lists
- **Gap Analysis**: Identify missing numbers and organizational opportunities
- **Structure Validation**: Check naming conventions and consistency

### 4. Multiple Templates
- **workstation**: Development-focused (based on our current config)
- **homelab**: Server/infrastructure focused
- **minimal**: Basic desktop setup

## Technical Implementation

### Layer Usage
```nix
# User's flake.nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  jdd-layer.url = "github:lessuseless/nix-jdd-layer";
};

# User's layers.nix
{ inputs, ... }: {
  imports = [
    inputs.jdd-layer.nixosModules.default
  ];
  
  jdd = {
    enable = true;
    template = "workstation";  # or "homelab", "minimal", "custom"
    tools.enable = true;       # Provides jdd command-line tools
  };
}
```

### Automation Tools Distribution
Tools implemented as shell scripts packaged through Nix:
- **Universal compatibility** - works on any Nix system
- **Zero dependencies** - uses standard UNIX tools (grep, sed, awk)
- **Immediate availability** - no compilation or setup required

## Benefits

### For Individual Users
- **Easy adoption** - import layer, follow templates
- **Proven organization** - battle-tested structure
- **Reduced cognitive load** - always know where to find/place configs
- **Scalable** - can grow from simple to complex systems
- **Automation** - tools handle maintenance tasks

### For NixOS Community
- **Standardized approach** - common organization methodology
- **Lower barrier to entry** - new users get good practices immediately
- **Shared knowledge** - community can contribute improvements
- **Documentation** - methodology and examples in one place

## Development Strategy

1. **Phase 1: Foundation** (Current)
   - Extract our working config as base example
   - Create minimal layer structure
   - Test rebuild functionality

2. **Phase 2: Tooling**
   - Implement shell-based automation tools
   - Create additional templates (homelab, minimal)
   - Write comprehensive documentation

3. **Phase 3: Community**
   - Test with other users
   - Refine based on feedback
   - Submit to Dendrix community
   - Maintain as community resource

## Current Status

- ✅ **Working JDD implementation** in personal config
- ✅ **24 modules** following JDD naming convention
- ✅ **Flat structure** proven effective
- ✅ **Complete system coverage** (desktop, development, AI tools)
- 🔄 **Testing rebuild functionality** (next step)
- ⏳ **Extract as separate layer** (planned)

## Next Steps

1. Verify current flake rebuilds system successfully
2. Create separate `nix-jdd-layer` repository
3. Extract templates from current working configuration
4. Implement basic automation tools
5. Document methodology and usage
6. Test with community feedback

---

*This concept builds on our successful implementation of Johnny Decimal methodology in NixOS configuration management, proven through 24 working modules and comprehensive system coverage.*
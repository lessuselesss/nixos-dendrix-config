# Pre-Commit Hooks Configuration

Comprehensive quality assurance and validation for the Johnny Decimal Directory NixOS configuration.

## 🛡️ Security & Secrets Detection

- **detect-secrets** - Scans for hardcoded secrets and credentials
- **GitGuardian (ggshield)** - Enterprise-grade secret detection
- **Baseline**: `.secrets.baseline` tracks known/approved patterns

## 🔧 Nix-Specific Quality Control

### Linting & Analysis
- **statix** - Anti-pattern detection and code improvements  
- **deadnix** - Finds unused Nix code and parameters
- **nix-syntax-check** - Validates Nix syntax correctness

### Formatting
- **alejandra** - Primary Nix formatter (consistent style)
- **nixpkgs-fmt** - Alternative formatter (manual stage)

### Module Validation
- **validate-flake-modules** - Ensures flake-parts module structure
- **validate-jdd-naming** - Validates Johnny Decimal Directory naming
- **check-nix-imports** - Verifies proper `lib` imports

## 🐚 Shell Script Quality

- **shellcheck** - Shell script linting and best practices
- **BATS** - Shell script testing framework (manual stage)
- **executable-scripts** - Ensures shell scripts have proper permissions

## 📝 General Code Quality

- **check-added-large-files** - Prevents large files (>1MB)
- **check-case-conflict** - Case-insensitive filesystem compatibility
- **check-merge-conflict** - Detects unresolved merge conflicts
- **check-symlinks** - Validates symlink integrity
- **end-of-file-fixer** - Ensures proper file endings
- **mixed-line-ending** - Standardizes line endings
- **trailing-whitespace** - Removes trailing whitespace

## 📦 TypeScript/Deno (Optional)

- **deno-check** - Type checking for Deno TypeScript files
- **deno-fmt-check** - Formatting validation

## 🚀 Usage

### Install Pre-Commit
```bash
nix run nixpkgs#pre-commit -- install
```

### Run All Hooks
```bash
nix run nixpkgs#pre-commit -- run --all-files
```

### Run Specific Hook
```bash
nix run nixpkgs#pre-commit -- run statix-check
nix run nixpkgs#pre-commit -- run validate-flake-modules
```

### Manual Stages (Advanced)
```bash
nix run nixpkgs#pre-commit -- run --hook-stage manual bats-test
nix run nixpkgs#pre-commit -- run --hook-stage manual nixpkgs-fmt-check
```

## 🔍 Hook Details

### Module Structure Validation
The `validate-flake-modules` hook ensures all modules follow the flake-parts pattern:
```nix
{ inputs, ... }:
{
  flake.nixosModules.MODULE-NAME = { config, lib, pkgs, ... }: {
    # Configuration here
  };
}
```

### Johnny Decimal Naming
The `validate-jdd-naming` hook enforces the naming convention:
```
XX-XX_category__XX-subcategory__XX.XX--description.nix
```

### Quality Metrics
- **statix**: Identifies 40+ Nix anti-patterns
- **deadnix**: Removes unused bindings (reduces noise)  
- **shellcheck**: 100+ shell script checks
- **secrets detection**: Prevents credential leaks

## 📊 Performance

Most hooks run in **<2 seconds** on typical commits. Heavy analysis tools (statix, deadnix) may take **5-10 seconds** but provide significant value.

## 🛠️ Configuration

Edit `.pre-commit-config.yaml` to:
- Disable specific hooks: Add to `skip` list
- Modify file patterns: Update `files` regex
- Change hook arguments: Modify `args` array
- Add custom hooks: Extend `local` repo hooks

## 🎯 Benefits

- **Zero false positives** from secrets in production
- **Consistent code style** across all Nix files
- **Structural integrity** of flake-parts modules
- **Best practices** enforcement for shell scripts
- **Early detection** of common issues
- **Automated quality** without manual review
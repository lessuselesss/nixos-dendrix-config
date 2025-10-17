# 81.03 Secrets Exposure Validation
# Validates that secrets are not exposed in the filesystem or git repository
{ inputs, ... }:

{
  flake.nixosModules."81.03-secrets-validation" = { config, lib, pkgs, ... }:
  let
    # Common secret patterns to detect
    secretPatterns = [
      "sk-[a-zA-Z0-9]{48}"                                      # OpenAI API keys
      "ghp_[a-zA-Z0-9]{36}"                                     # GitHub personal access tokens
      "gho_[a-zA-Z0-9]{36}"                                     # GitHub OAuth tokens
      "github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}"             # GitHub fine-grained tokens
      "AKIA[A-Z0-9]{16}"                                        # AWS access keys
      "-----BEGIN.*PRIVATE KEY-----"                            # Private keys
      "eyJ[a-zA-Z0-9_-]*\\.[a-zA-Z0-9_-]*\\.[a-zA-Z0-9_-]*"    # JWT tokens
      "xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24,32}" # Slack tokens
    ];

    # Files/patterns that shouldn't contain secrets but are high risk
    highRiskFiles = [
      "*.key"
      "*.pem"
      "*.p12"
      "*.pfx"
      ".env"
      ".env.*"
      "secrets.yaml"  # unless encrypted with sops
      "credentials.json"
      "id_rsa"
      "id_ed25519"
      "id_ecdsa"
    ];

    # Check script for secrets
    checkScript = pkgs.writeScriptBin "check-exposed-secrets" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      FOUND_ISSUES=()
      WORKDIR="${toString ./../..}"  # flake root

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "🔍 SECRETS EXPOSURE VALIDATION"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "Scanning for exposed secrets in: $WORKDIR"
      echo ""

      # Check 1: Look for secret patterns in tracked git files
      if [ -d "$WORKDIR/.git" ]; then
        echo "📋 Checking git-tracked files for secret patterns..."

        SECRET_PATTERN="${lib.concatStringsSep "|" secretPatterns}"

        TRACKED_FILES=$(cd "$WORKDIR" && ${pkgs.git}/bin/git ls-files)

        if echo "$TRACKED_FILES" | ${pkgs.gnugrep}/bin/grep -E '\.(nix|sh|yaml|yml|json|env|conf|config)$' > /tmp/check-files.txt 2>/dev/null; then
          while IFS= read -r file; do
            if [ -f "$WORKDIR/$file" ]; then
              if ${pkgs.gnugrep}/bin/grep -E -q "$SECRET_PATTERN" "$WORKDIR/$file" 2>/dev/null; then
                MATCHES=$(${pkgs.gnugrep}/bin/grep -E "$SECRET_PATTERN" "$WORKDIR/$file" | ${pkgs.coreutils}/bin/head -3 | ${pkgs.gnugrep}/bin/sed 's/^/      /')
                FOUND_ISSUES+=("Git-tracked file contains secret pattern: $file")
              fi
            fi
          done < /tmp/check-files.txt
          rm -f /tmp/check-files.txt
        fi
      fi

      # Check 2: Look for high-risk files in git
      if [ -d "$WORKDIR/.git" ]; then
        echo "📋 Checking for high-risk files in git..."

        cd "$WORKDIR"
        ${lib.concatStringsSep "\n" (map (pattern: ''
          if ${pkgs.git}/bin/git ls-files | ${pkgs.gnugrep}/bin/grep -E '${pattern}$' > /tmp/risky-files.txt 2>/dev/null; then
            while IFS= read -r file; do
              # Exception: secrets.yaml is OK if it's sops-encrypted
              if [ "$file" = "secrets.yaml" ] || [ "$file" = "secrets/secrets.yaml" ]; then
                if ${pkgs.gnugrep}/bin/grep -q "sops:" "$WORKDIR/$file" 2>/dev/null; then
                  continue  # encrypted, OK
                fi
              fi
              FOUND_ISSUES+=("High-risk file tracked in git: $file (${pattern})")
            done < /tmp/risky-files.txt
            rm -f /tmp/risky-files.txt
          fi
        '') highRiskFiles)}
      fi

      # Check 3: Look for unencrypted private keys in home directory
      echo "📋 Checking for exposed SSH keys..."

      if [ -d "$HOME/.ssh" ]; then
        for keyfile in "$HOME/.ssh"/id_*; do
          if [ -f "$keyfile" ] && [ ! -f "$keyfile.pub" ]; then
            # This is likely a private key
            if ${pkgs.file}/bin/file "$keyfile" | ${pkgs.gnugrep}/bin/grep -q "private key"; then
              # Check if it's encrypted
              if ! ${pkgs.gnugrep}/bin/grep -q "ENCRYPTED" "$keyfile" 2>/dev/null; then
                # Check permissions
                PERMS=$(${pkgs.coreutils}/bin/stat -c "%a" "$keyfile")
                if [ "$PERMS" != "600" ] && [ "$PERMS" != "400" ]; then
                  FOUND_ISSUES+=("SSH private key has insecure permissions ($PERMS): $keyfile")
                fi
              fi
            fi
          fi
        done
      fi

      # Check 4: Look for .env files with secrets outside of ignored paths
      echo "📋 Checking for .env files with potential secrets..."

      if [ -d "$WORKDIR" ]; then
        find "$WORKDIR" -name ".env" -o -name ".env.*" 2>/dev/null | while IFS= read -r envfile; do
          # Skip if in .gitignore
          if [ -f "$WORKDIR/.gitignore" ]; then
            if ${pkgs.git}/bin/git -C "$WORKDIR" check-ignore -q "$envfile" 2>/dev/null; then
              continue  # ignored, OK
            fi
          fi

          # Check if tracked in git
          if [ -d "$WORKDIR/.git" ]; then
            if ${pkgs.git}/bin/git -C "$WORKDIR" ls-files --error-unmatch "$envfile" >/dev/null 2>&1; then
              FOUND_ISSUES+=(".env file tracked in git: $envfile")
            fi
          fi
        done
      fi

      # Check 5: Verify .gitignore exists and contains secret patterns
      echo "📋 Checking .gitignore coverage..."

      if [ ! -f "$WORKDIR/.gitignore" ]; then
        FOUND_ISSUES+=("No .gitignore file found in repository root")
      else
        REQUIRED_PATTERNS=("*.key" "*.pem" ".env" "secrets/" "id_rsa" "id_ed25519")
        for pattern in "''${REQUIRED_PATTERNS[@]}"; do
          if ! ${pkgs.gnugrep}/bin/grep -q "$pattern" "$WORKDIR/.gitignore" 2>/dev/null; then
            FOUND_ISSUES+=(".gitignore missing pattern: $pattern")
          fi
        done
      fi

      # Check 6: Look for secrets in git history
      echo "📋 Checking git history for leaked secrets (last 10 commits)..."

      if [ -d "$WORKDIR/.git" ]; then
        SECRET_PATTERN="${lib.concatStringsSep "|" (lib.take 4 secretPatterns)}"  # Check most critical patterns

        if ${pkgs.git}/bin/git -C "$WORKDIR" log -10 -p 2>/dev/null | \
           ${pkgs.gnugrep}/bin/grep -E "$SECRET_PATTERN" >/dev/null 2>&1; then
          FOUND_ISSUES+=("Potential secrets found in git history (last 10 commits)")
        fi
      fi

      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      if [ ''${#FOUND_ISSUES[@]} -gt 0 ]; then
        echo "⚠️  SECURITY ISSUES FOUND: ''${#FOUND_ISSUES[@]}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        for issue in "''${FOUND_ISSUES[@]}"; do
          echo "  🔴 $issue"
        done

        echo ""
        echo "REMEDIATION STEPS:"
        echo ""
        echo "1. Remove secrets from tracked files:"
        echo "   git rm --cached <file>"
        echo "   # Add to .gitignore"
        echo ""
        echo "2. Remove from git history (if committed):"
        echo "   git filter-branch --force --index-filter \\"
        echo "     'git rm --cached --ignore-unmatch <file>' \\"
        echo "     --prune-empty --tag-name-filter cat -- --all"
        echo ""
        echo "3. Rotate any exposed credentials immediately"
        echo ""
        echo "4. Use sops-nix for secret management:"
        echo "   nix run nixpkgs#sops -- secrets.yaml"
        echo ""
        echo "5. Fix SSH key permissions:"
        echo "   chmod 600 ~/.ssh/id_*"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        exit 1
      else
        echo "✅ No exposed secrets detected"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
      fi
    '';
  in
  {
    # Add check script to system packages
    environment.systemPackages = [ checkScript ];

    # Create a systemd service that runs the check
    systemd.services.secrets-exposure-check = {
      description = "Check for exposed secrets in filesystem and git";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${checkScript}/bin/check-exposed-secrets";
        RemainAfterExit = true;
        # Don't fail boot, just warn
        SuccessExitStatus = [ 0 1 ];
        User = "lessuseless";  # Run as user to access git repo
        WorkingDirectory = "/home/lessuseless/recovered-dendrix-config";
      };
    };

    # Build-time warning
    warnings = [
      ''
        Secrets exposure validation is enabled. Run 'check-exposed-secrets' to scan for
        exposed secrets, or check 'systemctl status secrets-exposure-check' after boot.
      ''
    ];
  };
}

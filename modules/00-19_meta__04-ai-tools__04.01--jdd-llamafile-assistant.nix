# 04.01 JDD Llamafile Assistant
# AI-powered Johnny Decimal self-describing filename assistant
# Helps generate and validate JDD filenames (no directories - flat file structure with hierarchical names)
{ inputs, ... }:

{
  flake.nixosModules.jdd-llamafile = { config, lib, pkgs, ... }:
    let
      # Declaratively fetch the LLM model
      jddModel = pkgs.fetchurl {
        name = "qwen2.5-1.5b-instruct-q4_k_m.gguf";
        url = "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf";
        sha256 = "sha256-ahouttFWIr88loVyBjUbqX4a8Www16dO44lw5DTpQH4=";
        # Using Qwen 2.5 1.5B - smallest, fastest, perfect for filename generation
        # Size: ~1GB
      };
      # JDD naming grammar for constrained decoding
      jddGrammar = pkgs.writeText "jdd-grammar.json" (builtins.toJSON {
        # Regex pattern for JDD naming convention
        pattern = "^[0-9]{2}-[0-9]{2}_[a-z-]+__[0-9]{2}-[a-z-]+__[0-9]{2}\\.[0-9]{2}--[a-z0-9-]+\\.nix$";

        # Structured grammar for llguidance
        grammar = {
          root = "jdd_filename";
          rules = {
            jdd_filename = {
              type = "sequence";
              items = [
                { type = "regex"; pattern = "[0-9]{2}-[0-9]{2}"; }
                { type = "literal"; value = "_"; }
                { type = "regex"; pattern = "[a-z][a-z-]*"; }
                { type = "literal"; value = "__"; }
                { type = "regex"; pattern = "[0-9]{2}-[a-z][a-z-]*"; }
                { type = "literal"; value = "__"; }
                { type = "regex"; pattern = "[0-9]{2}\\.[0-9]{2}"; }
                { type = "literal"; value = "--"; }
                { type = "regex"; pattern = "[a-z0-9][a-z0-9-]*"; }
                { type = "literal"; value = ".nix"; }
              ];
            };
          };
        };
      });

      # Category definitions for the AI to understand (filename prefixes, not directories)
      jddCategories = pkgs.writeText "jdd-categories.txt" ''
        JDD Self-Describing Filename Convention - Flat file structure in modules/

        Filename Pattern: XX-XX_category__XX-subcategory__XX.XX--description.nix

        Category Ranges (first XX-XX in filename):
        00-19: Meta/System - System configuration, flake structure, AI tools for organization
        10-19: System Foundation - Hardware, boot, networking, core packages
        20-29: Desktop Environment - GNOME, audio, display management
        30-39: Development - Programming languages, tools, version control, editors
        40-49: AI & Automation - Ollama, Claude Desktop, MCP servers, AI tools
        50-59: Applications - User applications, browsers, productivity tools
        60-69: Users - User accounts, home-manager configurations
        70-79: Services - System services, VPN, containers, daemons
        80-89: Security - Secrets, impermanence, encryption, hardware security
      '';

      # Python script for JDD naming assistant with llguidance
      jddAssistant = pkgs.writeScriptBin "jdd-name" ''
        #!${pkgs.python3}/bin/python3
        """
        JDD Filename Assistant

        Generates and validates self-describing JDD filenames for NixOS modules.
        JDD uses a flat file structure where hierarchy is encoded in the filename itself.

        Pattern: XX-XX_category__XX-subcategory__XX.XX--description.nix
        Example: 30-39_development__31-systems-langs__31.01--rust.nix

        All files live in modules/ directory - no subdirectories!
        """
        import sys
        import json
        import subprocess
        import re
        from pathlib import Path

        # JDD category ranges for filename prefixes
        CATEGORIES = {
            "meta": "00-19",
            "system": "10-19",
            "desktop": "20-29",
            "development": "30-39",
            "ai": "40-49",
            "applications": "50-59",
            "users": "60-69",
            "services": "70-79",
            "security": "80-89",
        }

        CATEGORY_DESCRIPTIONS = """${builtins.readFile jddCategories}"""

        def load_index() -> dict:
            """Load the JDD module index"""
            import json
            try:
                with open('''/etc/jdd/index.json''') as f:
                    return json.load(f)
            except:
                return {"modules": [], "used_numbers": {}}

        def query_llamafile_server(prompt: str, use_server: bool = True) -> str:
            """Query the llamafile server (or fall back to direct execution)"""
            import socket

            # Check if server is running
            server_available = False
            if use_server:
                try:
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(1)
                    result = sock.connect_ex(('''127.0.0.1''', 8089))
                    sock.close()
                    server_available = (result == 0)
                except:
                    pass

            if server_available:
                # Use the server API (index already in context!)
                import urllib.request
                import urllib.parse

                data = json.dumps({
                    "prompt": prompt,
                    "temperature": 0.1,
                    "max_tokens": 150,
                    "stop": ["\n\n"],
                }).encode('''utf-8''')

                req = urllib.request.Request(
                    '''http://127.0.0.1:8089/completion''',
                    data=data,
                    headers={'''Content-Type''': '''application/json'''}
                )

                try:
                    with urllib.request.urlopen(req, timeout=30) as response:
                        result = json.loads(response.read().decode('''utf-8'''))
                        return result.get('''content''', '''''').strip()
                except Exception as e:
                    print(f"Server query failed: {e}", file=sys.stderr)
                    # Fall through to direct execution

            # Fallback: direct llamafile execution
            result = subprocess.run(
                [
                    "${pkgs.llamafile-jdd}/bin/llamafile-jdd",
                    "${jddModel}",
                    prompt,
                ],
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode != 0:
                return None

            return result.stdout.strip()

        def suggest_name(description: str) -> str:
            """Use llamafile to suggest a self-describing JDD filename"""

            # Load existing modules index
            index = load_index()
            existing_modules = [m["filename"] for m in index.get("modules", [])]

            # Build compact list of existing modules for the prompt
            existing_list = "\n".join(existing_modules)

            prompt = f"""EXISTING MODULES:
        {existing_list}

        User request: {description}

        Generate a filename following the JDD pattern that:
        1. Doesn't conflict with existing module numbers
        2. Uses appropriate category range
        3. Follows XX-XX_category__XX-subcategory__XX.XX--description.nix

        Respond with ONLY the filename, nothing else."""

            # Query the llamafile (server keeps index in context)
            output = query_llamafile_server(prompt)

            if not output:
                print("Error: Failed to generate suggestion", file=sys.stderr)
                return None
            # Look for JDD pattern
            match = re.search(r'\d{2}-\d{2}_[a-z-]+__\d{2}-[a-z-]+__\d{2}\.\d{2}--[a-z0-9-]+\.nix', output)

            return match.group(0) if match else output

        def validate_name(filename: str) -> tuple[bool, str]:
            """Validate if a filename follows JDD convention"""
            pattern = r'^(\d{2})-(\d{2})_([a-z][a-z-]*)__(\d{2})-([a-z][a-z-]*)__(\d{2})\.(\d{2})--([a-z0-9][a-z0-9-]*)\.nix$'
            match = re.match(pattern, filename)

            if not match:
                return False, "Filename doesn't match JDD pattern"

            range_start, range_end, category, sub_num, subcategory, major, minor, desc = match.groups()

            # Validate ranges
            if not (0 <= int(range_start) <= 99 and 0 <= int(range_end) <= 99):
                return False, f"Invalid range: {range_start}-{range_end}"

            if int(range_start) > int(range_end):
                return False, f"Range start ({range_start}) must be <= range end ({range_end})"

            # Check if subcategory number is within range
            sub_num_int = int(sub_num)
            if not (int(range_start) <= sub_num_int <= int(range_end)):
                return False, f"Subcategory number {sub_num} not in range {range_start}-{range_end}"

            return True, "Valid JDD filename"

        def main():
            if len(sys.argv) < 2:
                print("Usage: jdd-name <description>", file=sys.stderr)
                print("       jdd-name --validate <filename>", file=sys.stderr)
                sys.exit(1)

            if sys.argv[1] == "--validate":
                if len(sys.argv) < 3:
                    print("Error: --validate requires a filename", file=sys.stderr)
                    sys.exit(1)

                filename = Path(sys.argv[2]).name
                valid, message = validate_name(filename)

                if valid:
                    print(f"✅ {message}: {filename}")
                    sys.exit(0)
                else:
                    print(f"❌ {message}: {filename}")
                    sys.exit(1)
            else:
                description = " ".join(sys.argv[1:])
                suggested = suggest_name(description)

                if suggested:
                    print(f"Suggested name: {suggested}")

                    # Validate the suggestion
                    valid, message = validate_name(suggested)
                    if not valid:
                        print(f"⚠️  Warning: Suggested name may need adjustment ({message})")
                else:
                    print("Failed to generate name suggestion", file=sys.stderr)
                    sys.exit(1)

        if __name__ == "__main__":
            main()
      '';
    in
    {
      # Require llamafile overlay and JDD index
      imports = [
        inputs.self.nixosModules.llamafile-overlay
        inputs.self.nixosModules.jdd-index
      ];

      # System packages
      environment.systemPackages = [
        pkgs.llamafile
        pkgs.llamafile-jdd
        jddAssistant
      ];

      # Systemd service for llamafile daemon with JDD index in context
      # The daemon keeps the index in memory for efficient repeated queries
      systemd.services.jdd-llamafile-daemon = {
        description = "JDD Llamafile Naming Assistant Daemon";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        requires = [ "jdd-index.service" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = let
            # System prompt with JDD index pre-loaded
            systemPromptFile = pkgs.writeText "jdd-system-prompt.txt" ''
              You are a Johnny Decimal self-describing filename assistant for NixOS modules.

              IMPORTANT: All files are in a flat modules/ directory. The filename itself encodes the hierarchy.

              JDD Self-Describing Filename Convention - Flat file structure in modules/

              Filename Pattern: XX-XX_category__XX-subcategory__XX.XX--description.nix

              Category Ranges (first XX-XX in filename):
              00-19: Meta/System - System configuration, flake structure, AI tools for organization
              10-19: System Foundation - Hardware, boot, networking, core packages
              20-29: Desktop Environment - GNOME, audio, display management
              30-39: Development - Programming languages, tools, version control, editors
              40-49: AI & Automation - Ollama, Claude Desktop, MCP servers, AI tools
              50-59: Applications - User applications, browsers, productivity tools
              60-69: Users - User accounts, home-manager configurations
              70-79: Services - System services, VPN, containers, daemons
              80-89: Security - Secrets, impermanence, encryption, hardware security

              Naming convention: XX-XX_category__XX-subcategory__XX.XX--description.nix
              - Use lowercase with hyphens for multi-word names
              - Use double underscore (__) as separators
              - Numbers must match the category system
              - File extension must be .nix

              Examples:
              - 30-39_development__31-systems-langs__31.01--rust.nix
              - 40-49_ai__42-mcp__42.01--mcp-servers.nix
              - 80-89_security__81-secrets__81.03--ledger-age-tools.nix

              The index of existing modules is available at /etc/jdd/index.json and will be provided in each request.
            '';
          in ''
            ${pkgs.llamafile}/bin/llamafile \
              -m ${jddModel} \
              --server \
              --host 127.0.0.1 \
              --port 8089 \
              --ctx-size 8192 \
              --system-prompt-file ${systemPromptFile} \
              --prompt-cache 1 \
              --parallel 2 \
              -ngl 9999
          '';
          Restart = "on-failure";
          RestartSec = "10s";

          # Security hardening
          DynamicUser = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          NoNewPrivileges = true;
          ReadOnlyPaths = [ "/etc/jdd" ];
        };
      };

      # Service to rebuild index on module changes
      systemd.services.jdd-index = {
        description = "JDD Module Index Builder";
        wantedBy = [ "multi-user.target" ];
        before = [ "jdd-llamafile-daemon.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = let
            updateScript = pkgs.writeShellScript "update-jdd-index" ''
              # Index is built at build-time, just ensure it's available
              if [ -f /etc/jdd/index.json ]; then
                echo "JDD index available: $(${pkgs.jq}/bin/jq -r '.statistics.total_modules' /etc/jdd/index.json) modules"
              else
                echo "Warning: JDD index not found at /etc/jdd/index.json"
                exit 1
              fi
            '';
          in "${updateScript}";
        };
      };
    };
}

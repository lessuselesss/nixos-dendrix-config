# 62.01 Home Manager Integration
# User-level package and service management
{ inputs, ... }:

{
  flake.nixosModules."62.01-home-manager" = { config, lib, pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";

      sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
      ];

      users.lessuseless = { pkgs, inputs, config, lib, ... }: {
        # Home Manager state version
        home.stateVersion = "25.05";
        programs.home-manager.enable = true;

        # Enable zsh shell
        programs.zsh.enable = true;

        # Configure sops for secret management
        # NOTE: Secrets are managed by the existing /etc/nixos configuration
        # This is commented out for now to allow testing without sops evaluation issues
        # Uncomment when ready to migrate secrets management to this flake
        # sops = {
        #   age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        #   defaultSopsFile = ./../../secrets.yaml;
        #
        #   secrets = {
        #     github-token = {
        #       path = "${config.home.homeDirectory}/.config/secrets/github-token";
        #     };
        #     gemini-api-key = {
        #       path = "${config.home.homeDirectory}/.config/secrets/gemini-api-key";
        #     };
        #     google-api-key = {
        #       path = "${config.home.homeDirectory}/.config/secrets/google-api-key";
        #     };
        #     openrouter-api-key = {
        #       path = "${config.home.homeDirectory}/.config/secrets/openrouter-api-key";
        #     };
        #     anthropic-api-key = {
        #       path = "${config.home.homeDirectory}/.config/secrets/anthropic-api-key";
        #     };
        #   };
        # };

        # User packages
        home.packages = with pkgs; [
          # Applications
          appimage-run
          act
          bazecor
          transmission_4
          google-chrome
          obsidian
          warp-terminal
          cloudflare-warp
          telegram-desktop
          obs-studio
          beeper
          signal-desktop
          deno
          librewolf

          # Development tools
          # cargo  # Provided by rustup in 81.03-ledger-age-tools
          claude-code
          unzip
          gh
          go
          gopass
          gopass-summon-provider
          python313Packages.pip
          python313
          pipx
          playwright
          nix-direnv
          jq
          jujutsu
          uv
          gcc
          super-productivity
          spotify
          pkg-config
          gnumake
          nodejs
          maven
          ollama
          foundry
          zed-editor
          typst
          gemini-cli
          waydroid

          # Secret management tools
          sops
          age
          age-plugin-ledger

          # Ledger hardware wallet
          ledger-live-desktop
        ];

        # Session variables
        home.sessionVariables = {
          SUMMON_PROVIDER_PATH = "${pkgs.gopass-summon-provider}/bin";
          SUMMON_PROVIDER = "gopass";
          GTK_MODULES = "gail:atk-bridge";
        };

        # Zsh configuration to load API keys from secrets
        programs.zsh.initContent = ''
          # Load API keys from sops-managed secrets if they exist
          if [ -f ~/.config/secrets/gemini-api-key ]; then
            export GEMINI_API_KEY=$(cat ~/.config/secrets/gemini-api-key)
          fi
        '';

        # Distrobox configuration
        programs.distrobox = {
          enable = true;
          containers = {
            "python-project" = {
              image = "fedora:40";
              additional_packages = "python3 git";
              init_hooks = "pip3 install numpy pandas torch torchvision";
            };
            "common-debian" = {
              image = "debian:13";
              entry = true;
              additional_packages = "git";
              init_hooks = [
                "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker"
                "ln -sf /usr/bin/distrobox-host-exec /usr/local/bin/docker-compose"
              ];
            };
            "office" = {
              clone = "common-debian";
              additional_packages = "libreoffice onlyoffice";
              entry = true;
            };
          };
        };

        # MCP configuration using secrets
        # NOTE: Disabled until sops secrets are re-enabled
        # When ready, uncomment the following to generate MCP config with secret substitution
        # home.activation.generateMcpConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        #   $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.claude
        #
        #   # Create MCP config with proper secret substitution
        #   $DRY_RUN_CMD cat > ${config.home.homeDirectory}/.claude/mcp.json.template << 'EOF'
        #   {
        #     "mcpServers": {
        #       "nixos": {
        #         "command": "nix",
        #         "args": ["run", "github:utensils/mcp-nixos", "--"]
        #       },
        #       "github": {
        #         "command": "npx",
        #         "args": ["-y", "@modelcontextprotocol/server-github"],
        #         "env": {
        #           "GITHUB_PERSONAL_ACCESS_TOKEN": "__GITHUB_TOKEN__"
        #         }
        #       },
        #       "github-cli": {
        #         "command": "npx",
        #         "args": ["gh-cli-mcp"],
        #         "env": {},
        #         "cwd": ".",
        #         "timeout": 30000,
        #         "trust": false
        #       },
        #       "taskmaster-ai": {
        #         "command": "npx",
        #         "args": ["-y", "--package=task-master-ai", "task-master-ai"],
        #         "env": {
        #           "ANTHROPIC_API_KEY": "__ANTHROPIC_API_KEY__",
        #           "GOOGLE_API_KEY": "__GOOGLE_API_KEY__",
        #           "OPENROUTER_API_KEY": "__OPENROUTER_API_KEY__"
        #         }
        #       },
        #       "jj-mcp-server": {
        #         "command": "npx",
        #         "args": ["-y", "jj-mcp-server"]
        #       },
        #       "git-mob": {
        #         "command": "npx",
        #         "args": ["-y", "git-mob-mcp-server"]
        #       },
        #       "playwright": {
        #         "command": "nix",
        #         "args": [
        #           "develop",
        #           "/home/lessuseless/Projects/Flakes/claude-code/mcp/playwrite-mcp-flake",
        #           "--command", "npx", "@playwright/mcp"
        #         ]
        #       }
        #     }
        #   }
        #   EOF
        #
        #   # Substitute secrets if they exist
        #   if [ -f ${config.sops.secrets.github-token.path} ]; then
        #     GITHUB_TOKEN=$(cat ${config.sops.secrets.github-token.path})
        #     GOOGLE_API_KEY=$(cat ${config.sops.secrets.google-api-key.path})
        #     OPENROUTER_API_KEY=$(cat ${config.sops.secrets.openrouter-api-key.path})
        #     ANTHROPIC_API_KEY=$(cat ${config.sops.secrets.anthropic-api-key.path})
        #
        #     $DRY_RUN_CMD sed -e "s/__GITHUB_TOKEN__/$GITHUB_TOKEN/g" \
        #                      -e "s/__GOOGLE_API_KEY__/$GOOGLE_API_KEY/g" \
        #                      -e "s/__OPENROUTER_API_KEY__/$OPENROUTER_API_KEY/g" \
        #                      -e "s/__ANTHROPIC_API_KEY__/$ANTHROPIC_API_KEY/g" \
        #                      ${config.home.homeDirectory}/.claude/mcp.json.template \
        #                      > ${config.home.homeDirectory}/.claude/mcp.json
        #     $DRY_RUN_CMD chmod 600 ${config.home.homeDirectory}/.claude/mcp.json
        #   fi
        # '';
      };

      extraSpecialArgs = { inherit inputs; };
    };
  };
}
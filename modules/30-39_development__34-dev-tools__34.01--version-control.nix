# 34.01 Version Control Systems
# Git, Jujutsu, GitHub CLI and related tools
{ inputs, ... }:

{
  flake.nixosModules.version-control = { config, lib, pkgs, ... }: {
    home-manager.users.lessuseless = { pkgs, ... }: {
      home.packages = with pkgs; [
        # Version control
        gh        # GitHub CLI
        jujutsu   # Modern VCS

        # Development automation
        act       # Run GitHub Actions locally

        # Security tools
        gopass                   # Password manager
        gopass-summon-provider   # Summon integration
      ];

      # Git configuration
      programs.git = {
        enable = true;
        userName = "Ashley Barr";
        userEmail = "lessuseless@nixos.local";

        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = false;
          push.autoSetupRemote = true;

          # Color output
          color.ui = true;

          # Better diffs
          diff.algorithm = "histogram";

          # SSH signing (if you use SSH keys for commits)
          # gpg.format = "ssh";
          # user.signingkey = "~/.ssh/id_ed25519.pub";
          # commit.gpgsign = true;
        };

        aliases = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };
      };

      # GitHub CLI configuration
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          editor = "vim";
        };
      };

      # Jujutsu configuration
      programs.jujutsu = {
        enable = true;
        settings = {
          user = {
            name = "Ashley Barr";
            email = "lessuseless@nixos.local";
          };
        };
      };
    };
  };
}
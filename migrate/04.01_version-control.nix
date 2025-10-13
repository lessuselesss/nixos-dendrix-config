# 04.01 Version Control Systems
# Git, Jujutsu, GitHub CLI and related tools
{ inputs, ... }:

{
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
  };
}
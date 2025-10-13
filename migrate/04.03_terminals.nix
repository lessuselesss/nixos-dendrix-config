# 04.03 Terminal and Shell Tools
# Terminal emulators and command-line utilities
{ inputs, ... }:

{
  home-manager.users.lessuseless = { pkgs, ... }: {
    home.packages = with pkgs; [
      # Terminal applications
      warp-terminal  # Modern terminal emulator
      
      # Command-line utilities
      jq       # JSON processor
      maven    # Java build tool
    ];
  };
}
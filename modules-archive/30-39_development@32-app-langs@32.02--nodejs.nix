# 32.02 Node.js and Deno Runtime
# JavaScript/TypeScript development environments
{ inputs, ... }:

{
  home-manager.users.lessuseless = { pkgs, ... }: {
    home.packages = with pkgs; [
      # JavaScript runtimes
      nodejs
      deno
      
      # Development tools
      nix-direnv  # Nix environment integration
    ];
  };
}
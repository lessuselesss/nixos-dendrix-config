# 62.01 Home Manager Integration
# User-level package and service management
{ inputs, ... }:

{
  flake.nixosModules.home-manager = { config, lib, pkgs, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bkp";
      
      users.lessuseless = { pkgs, inputs, ... }: {
        # Home Manager state version
        home.stateVersion = "25.05";
        programs.home-manager.enable = true;
        
        # Enable zsh shell
        programs.zsh.enable = true;
        
        # User packages will be defined in separate Johnny Decimal modules
        home.packages = with pkgs; [
          # Basic packages - more will be imported from other modules
          appimage-run
        ];
        
        # TODO: Extract MCP server configuration to separate module (05.03_mcp-servers.nix)
        # TODO: Extract distrobox configuration to separate module (06.02_distrobox.nix)
        # TODO: Extract development packages to separate modules (03.xx, 04.xx)
      };
      
      extraSpecialArgs = { inherit inputs; };
    };
  };
}
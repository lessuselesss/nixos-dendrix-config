# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "A dendritic setup.";
  inputs = {
    allfollow = {
      url = "github:spikespaz/allfollow";
    };
    dendrix = {
      url = "github:vic/dendrix";
    };
    devshell = {
      url = "github:numtide/devshell";
    };
    flake-file = {
      url = "github:vic/flake-file";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    mcp-servers = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    # Nix PR #8892 - Adds flake-schema support for flake output validation
    # See: https://github.com/NixOS/nix/pull/8892
    nix-pr-8892 = {
      url = "github:NixOS/nix?ref=pull/8892/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:oxalica/rust-overlay";
    };
    systems = {
      url = "github:nix-systems/default";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };

    # Secrets Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence for ephemeral root
    impermanence = {
      url = "github:nix-community/impermanence";
    };

    # MCP servers
    super-productive-mcp = {
      url = "github:lessuselesss/super-productive-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hints = {
      url = "github:lessuselesss/hints";
      flake = false;
    };

    # SSH key management
    keycutter = {
      url = "github:lessuselesss/keycutter-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (
    {
      systems = [ "x86_64-linux" ];
    } // (inputs.import-tree ./modules)
  );
}

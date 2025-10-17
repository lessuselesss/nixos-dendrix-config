# 00.04 Module Packages Registry
# Central registry that exports packages using their module attribute names
# Usage: nix run .#<module-attribute-name>
{ inputs, ... }:

let
  pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };

  # Import each module's package definitions
  checkImpermanence = import ./90-99_utilities__91-diagnostics__91.02--check-impermanence-package.nix { inherit inputs; };

  # Extract the package from the overlay
  makePackageFromOverlay = overlayName:
    let
      overlay = inputs.self.overlays.${overlayName} or (final: prev: {});
      pkgs' = pkgs.extend overlay;
    in pkgs'.map-impermanence or null;
in
{
  # Export packages with module attribute names
  flake.packages.x86_64-linux = {
    # Module 91.02 - Check Impermanence
    "91.02-check-impermanence" = makePackageFromOverlay "91.02-check-impermanence";

    # Aliases for convenience
    check-impermanence = makePackageFromOverlay "91.02-check-impermanence";
    map-impermanence = makePackageFromOverlay "91.02-check-impermanence";

    # Default package
    default = makePackageFromOverlay "91.02-check-impermanence";
  };

  # Also export as apps for `nix run` compatibility
  flake.apps.x86_64-linux = builtins.mapAttrs (name: pkg: {
    type = "app";
    program = "${pkg}/bin/map-impermanence";
  }) (inputs.self.packages.x86_64-linux or {});
}

{
  description = "Prebuilt macOS .app bundles (Claude, DockDoor, Cryptomator) packaged for Nix, auto-updated via CI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    let
      mkPackages =
        pkgs:
        import ./packages.nix {
          inherit (pkgs)
            lib
            stdenvNoCC
            undmg
            unzip
            fetchurl
            ;
          system = pkgs.stdenv.hostPlatform.system;
        };

      systemOutputs = flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" ] (
        system: {
          packages = mkPackages nixpkgs.legacyPackages.${system};
        }
      );
    in
    systemOutputs
    // {
      # Exposes the apps as pkgs.darwinApps.* so consumers can apply one overlay
      # and keep referencing pkgs.darwinApps.<name> unchanged.
      overlays.default = final: _prev: {
        darwinApps = mkPackages final;
      };
    };
}

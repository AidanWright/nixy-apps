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

      # XRayBuilder ships no macOS binary, so unlike the .app bundles it is built
      # from source here and cached, sparing consumers the .NET toolchain.
      mkXrayBuilder = pkgs: pkgs.callPackage ./xray-builder/package.nix { };

      systemOutputs = flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages = mkPackages pkgs // {
            xray-builder = mkXrayBuilder pkgs;
          };
        }
      );
    in
    systemOutputs
    // {
      # Exposes the apps as pkgs.darwinApps.* so consumers can apply one overlay
      # and keep referencing pkgs.darwinApps.<name> unchanged. XRayBuilder is a
      # CLI rather than a bundle, so it lands at the top level as pkgs.xray-builder.
      overlays.default = final: _prev: {
        darwinApps = mkPackages final;
        xray-builder = mkXrayBuilder final;
      };
    };
}

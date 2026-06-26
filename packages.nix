# Builds every app declared in apps.json for a single system. Each app's
# version and per-platform source (url + hash) is read from the JSON data file,
# so the .nix code never carries hardcoded versions; the update script edits
# apps.json instead.
{
  lib,
  stdenvNoCC,
  undmg,
  unzip,
  fetchurl,
  system,
}:
let
  mkMacosApp = import ./lib/mk-macos-app.nix { inherit stdenvNoCC undmg unzip; };
  apps = lib.importJSON ./apps.json;

  buildApp =
    pname: app:
    let
      platform =
        app.platforms.${system}
          or (throw "nixy-apps: ${pname} has no source for ${system}");
    in
    mkMacosApp {
      inherit pname;
      inherit (app) version appBundle archive;
      src = fetchurl { inherit (platform) url hash; };
    };
in
lib.mapAttrs buildApp apps

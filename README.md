# nixy-apps

Prebuilt macOS `.app` bundles packaged for Nix, with versions tracked
automatically. 

Currently, the following apps are supported:

| App | Source |
| --- | --- |
| `claude-desktop` | `downloads.claude.ai` release manifest |
| `dockdoor` | [ejbills/DockDoor](https://github.com/ejbills/DockDoor) releases |
| `cryptomator` | [cryptomator/cryptomator](https://github.com/cryptomator/cryptomator) releases |
| `stremio` | [stremio.com/downloads](https://www.stremio.com/downloads) (native macOS build, version scraped from the page) |

Updates are automatic and hit this repo within 1 hour of upstream release.

Built for `aarch64-darwin` and `x86_64-darwin`.

### Other tools

The following macOS tools ship no upstream macOS binary, so this flake builds them
from source and caches them the same way. They live at the top level (e.g.
`pkgs.xray-builder`) rather than under `darwinApps.*`:

| Tool | Source |
| --- | --- |
| `xray-builder` | [Ephemerality/xray-builder.gui](https://github.com/Ephemerality/xray-builder.gui) — build X-Ray files for sideloaded Kindle books |

Unlike the bundles, these are pinned to a release rather than auto-updated. Bump
one by editing its `version`/`src` in `<tool>/package.nix` and regenerating
`<tool>/deps.json` (`nix build .#<tool>.fetch-deps && ./result <tool>/deps.json`).

## Usage

Add the flake as an input and apply the overlay. Every app is then available as
`pkgs.darwinApps.<name>`:

```nix

  ### flake.nix
  inputs.nixy-apps.url = "github:aidanwright/nixy-apps";

  ### outputs or config.nix
  nixpkgs.overlays = [ inputs.nixy-apps.overlays.default ];
  
  # packages are available via the overlay darwinApps
  environment.systemPackages = [ pkgs.darwinApps.dockdoor ];
  home.packages = [ pkgs.darwinApps.claude-desktop pkgs.darwinApps.cryptomator ];

  # "other tools" are top-level rather than under darwinApps
  environment.systemPackages = [ pkgs.xray-builder ];
```

Or run/build directly:

```bash
nix build github:aidanwright/nixy-apps#cryptomator
```

### Versioning

Each app set is published as a dated, immutable release (CalVer, e.g.
`v2026.06.26`) whenever an app version changes. Every release lists the exact
version of each app — see [Releases](https://github.com/aidanwright/nixy-apps/releases).

Pick how you want to receive updates:

```nix
# Track the newest released set; `nix flake update nixy-apps` pulls the latest.
inputs.nixy-apps.url = "github:aidanwright/nixy-apps/latest";

# Or pin an exact set and bump deliberately (rollback by choosing an older tag).
inputs.nixy-apps.url = "github:aidanwright/nixy-apps/v2026.06.26";
```

The `latest` tag only advances on real app-version releases, not on docs or CI
commits.

### Binary cache

If you are using aarch64-darwin[^1] (M series chips), prebuilt bundles are available via Cachix.

```bash
cachix use aidanwright
```

Or trust it declaratively in your Nix config:

```nix
nix.settings = {
  substituters = [ "https://aidanwright.cachix.org" ];
  trusted-public-keys = [ "aidanwright.cachix.org-1:0SQiDDByZEpl3h36s1ItafKKMAcOoAlN3X9tApoDRog=" ];
};
```

## How updates work

- `.github/workflows/update.yml` runs hourly. For each app it runs
  `scripts/update-app.sh <app> --check`; when a newer release exists it bumps
  `apps.json`, recomputes hashes, verifies the build, and opens an
  auto-merging PR.
- `.github/workflows/build.yml` builds all apps on Apple Silicon and ~Intel~[^1] then
  pushes the results to Cachix on `main`.

Update one manually:

```bash
scripts/update-app.sh dockdoor          # update to latest
scripts/update-app.sh dockdoor --check  # exit 1 if an update is available
```

[^1]: Due to low runner availability for x86_64-darwin, only aarch64-darwin binaries are cached.  
This flake can still be used by x86_64-darwin users, but local builds will be required.  
This shouldn't be too troublesome as the packages are quite small and compile fast.  
Support may be added at a later date.  

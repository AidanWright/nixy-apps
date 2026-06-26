# nixy-apps

Prebuilt macOS `.app` bundles packaged for Nix, with versions tracked
automatically. Replaces hand-maintained Homebrew casks (and hardcoded Nix
derivations) for:

| App | Source | Platforms |
| --- | --- | --- |
| `claude-desktop` | `downloads.claude.ai` release manifest | universal |
| `dockdoor` | [ejbills/DockDoor](https://github.com/ejbills/DockDoor) releases | universal |
| `cryptomator` | [cryptomator/cryptomator](https://github.com/cryptomator/cryptomator) releases | per-arch |

Built for `aarch64-darwin` and `x86_64-darwin`.

## Use it

Add the flake as an input and apply the overlay. Every app is then available as
`pkgs.darwinApps.<name>`:

```nix
{
  inputs.nixy-apps.url = "github:aidanwright/nixy-apps";

  # in your nixpkgs / nix-darwin config:
  nixpkgs.overlays = [ inputs.nixy-apps.overlays.default ];
  # environment.systemPackages = [ pkgs.darwinApps.dockdoor ];
  # home.packages = [ pkgs.darwinApps.claude-desktop pkgs.darwinApps.cryptomator ];
}
```

Or run/build directly:

```bash
nix build github:aidanwright/nixy-apps#cryptomator
```

### Binary cache

CI pushes prebuilt bundles to Cachix so you never rebuild locally:

```bash
cachix use nixy-apps
```

Or trust it declaratively in your Nix config:

```nix
nix.settings = {
  substituters = [ "https://nixy-apps.cachix.org" ];
  trusted-public-keys = [ "nixy-apps.cachix.org-1:REPLACE_WITH_PUBLIC_KEY" ];
};
```

## How updates work

`apps.json` is the single source of truth: per app it holds the `version`, the
per-platform download `url` + SRI `hash`, and a `source` block describing where
to look for new releases. No version is ever hardcoded in `.nix` files.

- `.github/workflows/update.yml` runs hourly. For each app it runs
  `scripts/update-app.sh <app> --check`; when a newer release exists it bumps
  `apps.json`, recomputes hashes, verifies the build, and opens an
  auto-merging PR.
- `.github/workflows/build.yml` builds all apps on Apple Silicon and Intel and
  pushes the results to Cachix on `main`.

Update one manually:

```bash
scripts/update-app.sh dockdoor          # update to latest
scripts/update-app.sh dockdoor --check  # exit 1 if an update is available
```

## One-time repository setup

1. Create the `nixy-apps` Cachix cache and add a repo secret
   `CACHIX_AUTH_TOKEN`. Put the cache's public key in this README and in
   consumers' `trusted-public-keys`.
2. Enable **Allow auto-merge** in repo settings and add a branch-protection rule
   on `main` requiring the `build` checks, so update PRs merge only on a green
   build.

## Adding an app

Add an entry to `apps.json` with a `source` of type `github` (with either a
fixed `asset` or an `assetTemplate` + `archMap`) or `claude-releases`, seed the
`version`/`url`/`hash`, then `nix build .#<name>` to confirm. The packaging in
`packages.nix` and `lib/mk-macos-app.nix` is data-driven and needs no changes.

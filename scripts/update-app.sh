#!/usr/bin/env bash
# Updates a single app in apps.json to its latest upstream release: resolves the
# new version and per-platform download URLs from the app's `source`, recomputes
# SRI hashes, writes apps.json, and verifies the package still builds.
#
# Usage:
#   scripts/update-app.sh <app>           # update <app> to latest
#   scripts/update-app.sh <app> --check   # exit 0 if up to date, 1 if an update exists
set -euo pipefail

readonly APPS_JSON="apps.json"

log() { echo "[update-app] $*" >&2; }
die() { echo "[update-app] error: $*" >&2; exit 2; }

# Holds the upstream release payload (GitHub release JSON or Claude RELEASES.json)
# so it is fetched once and reused across platforms.
RELEASE_DATA="$(mktemp)"
trap 'rm -f "$RELEASE_DATA" "$APPS_JSON.tmp"' EXIT

q() { jq -r --arg a "$APP" "$@" "$APPS_JSON"; }

fetch_release() {
  case "$SOURCE_TYPE" in
    claude-releases)
      local channel
      channel="$(q '.[$a].source.channel')"
      curl -sf --max-time 30 \
        "https://downloads.claude.ai/releases/$channel/RELEASES.json" > "$RELEASE_DATA"
      ;;
    github)
      local repo
      repo="$(q '.[$a].source.repo')"
      gh api "repos/$repo/releases/latest" > "$RELEASE_DATA"
      ;;
    *) die "unknown source type: $SOURCE_TYPE" ;;
  esac
}

latest_version() {
  case "$SOURCE_TYPE" in
    claude-releases) jq -r '.currentRelease' "$RELEASE_DATA" ;;
    github) jq -r '.tag_name' "$RELEASE_DATA" | sed 's/^v//' ;;
  esac
}

# Echoes the download URL for the requested platform at $VERSION.
url_for_platform() {
  local platform="$1"
  case "$SOURCE_TYPE" in
    claude-releases)
      jq -r --arg v "$VERSION" \
        '.releases[] | select(.version==$v) | .updateTo.url' "$RELEASE_DATA" | head -1
      ;;
    github)
      local asset template arch name
      asset="$(q '.[$a].source.asset // empty')"
      if [ -n "$asset" ]; then
        name="$asset"
      else
        template="$(q '.[$a].source.assetTemplate')"
        arch="$(jq -r --arg a "$APP" --arg p "$platform" '.[$a].source.archMap[$p]' "$APPS_JSON")"
        name="${template//\{version\}/$VERSION}"
        name="${name//\{arch\}/$arch}"
      fi
      jq -r --arg n "$name" \
        '.assets[] | select(.name==$n) | .browser_download_url' "$RELEASE_DATA"
      ;;
  esac
}

write_json() { jq "$@" "$APPS_JSON" > "$APPS_JSON.tmp" && mv "$APPS_JSON.tmp" "$APPS_JSON"; }

main() {
  [ -f "$APPS_JSON" ] || die "run from the repository root ($APPS_JSON not found)"
  APP="${1:?usage: update-app.sh <app> [--check]}"
  local mode="${2:-update}"

  q '.[$a]' >/dev/null 2>&1 && [ "$(q '.[$a] // empty')" != "" ] || die "unknown app: $APP"

  SOURCE_TYPE="$(q '.[$a].source.type')"
  local current
  current="$(q '.[$a].version')"

  fetch_release
  VERSION="$(latest_version)"
  [ -n "$VERSION" ] || die "could not resolve latest version for $APP"

  log "$APP: current=$current latest=$VERSION"

  if [ "$current" = "$VERSION" ]; then
    log "$APP: up to date"
    exit 0
  fi

  if [ "$mode" = "--check" ]; then
    log "$APP: update available ($current -> $VERSION)"
    exit 1
  fi

  write_json --arg a "$APP" --arg v "$VERSION" '.[$a].version=$v'

  local platforms platform url hash
  platforms="$(q '.[$a].platforms | keys[]')"
  for platform in $platforms; do
    url="$(url_for_platform "$platform")"
    [ -n "$url" ] || die "no asset URL for $APP on $platform (version $VERSION)"
    log "$APP/$platform: prefetching $url"
    hash="$(nix store prefetch-file --json --hash-type sha256 "$url" | jq -r '.hash')"
    write_json --arg a "$APP" --arg p "$platform" --arg url "$url" --arg hash "$hash" \
      '.[$a].platforms[$p].url=$url | .[$a].platforms[$p].hash=$hash'
    log "$APP/$platform: $hash"
  done

  log "$APP: verifying build"
  nix build ".#$APP" --no-link --print-build-logs

  log "$APP: updated $current -> $VERSION"
}

main "$@"

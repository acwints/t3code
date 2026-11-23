#!/usr/bin/env bash
# Keeps this fork on the latest upstream stable release.
#
#   fork/sync-upstream.sh          merge the newest upstream vX.Y.Z tag, build, push
#   fork/sync-upstream.sh build    rebuild the current branch without merging
#   fork/sync-upstream.sh install  wait for T3 Code to quit, swap in the build, relaunch
#
# Exit 2 means the merge stopped on conflicts: resolve, commit, then run `build`.
set -euo pipefail

BRANCH="${FORK_BRANCH:-project-background}"
APP_NAME="AW Code"
APP="/Applications/$APP_NAME.app"
# The upstream install this fork replaced; retired on first install.
LEGACY_APP="/Applications/T3 Code (Beta).app"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/release-fork"
BUILT="$OUT/mac-arm64/$APP_NAME.app"
BACKUPS="$HOME/.t3/app-backups"
HEAVY_BUILD=/Users/andrewwinter/.local/bin/heavy-build

cd "$ROOT"
# shellcheck disable=SC1091
[ -f "$HOME/.config/vite-plus/env" ] && . "$HOME/.config/vite-plus/env"

latest_release() {
  git tag -l 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1
}

current_release() {
  git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' --exclude '*-*' HEAD
}

merge_latest() {
  git fetch upstream --tags --quiet
  git switch --quiet "$BRANCH"
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree has uncommitted changes; commit or stash them first." >&2
    exit 1
  fi
  local tag
  tag="$(latest_release)"
  if git merge-base --is-ancestor "$tag" HEAD; then
    echo "Already contains $tag."
    return 1
  fi
  echo "Merging $tag into $BRANCH..."
  if ! git merge --no-edit -m "Merge upstream $tag" "$tag"; then
    echo "Conflicts merging $tag. Resolve them, commit, then run: fork/sync-upstream.sh build" >&2
    exit 2
  fi
}

build() {
  local version
  version="$(current_release)"
  version="${version#v}"
  vp i
  vp run i18n:check
  local reuse=0
  if ! command -v cargo >/dev/null; then
    # Without Rust, reuse the installed app's resource monitor; it rarely changes upstream.
    local dir="native/resource-monitor/target/aarch64-apple-darwin/release"
    mkdir -p "$dir"
    local installed="$APP"
    [ -d "$installed" ] || installed="$LEGACY_APP"
    cp "$installed/Contents/Resources/resource-monitor/t3-resource-monitor" "$dir/"
    reuse=1
  fi
  rm -rf "$OUT"
  # No GITHUB_REPOSITORY / T3CODE_DESKTOP_UPDATE_REPOSITORY means no update feed is baked in,
  # so the built app never auto-updates itself back to upstream.
  env -u GITHUB_REPOSITORY -u T3CODE_DESKTOP_UPDATE_REPOSITORY \
    T3CODE_DESKTOP_REUSE_RESOURCE_MONITOR="$reuse" \
    "$HEAVY_BUILD" node scripts/build-desktop-artifact.ts \
    --platform mac --target dir --arch arm64 --build-version "$version" --output-dir "$OUT"
  if [ -f "$BUILT/Contents/Resources/app-update.yml" ]; then
    echo "Build unexpectedly contains an update feed; not installing it." >&2
    exit 1
  fi
  git push --quiet origin "$BRANCH"
  echo "Built $version at $BUILT. Run: fork/sync-upstream.sh install"
}

# pgrep patterns are regexes, and the parentheses in the legacy app name would not match literally.
# No grep -q: exiting early sends ps SIGPIPE, and pipefail would then report "not running".
app_running() {
  ps -axo comm= | grep -Fx -e "$APP/Contents/MacOS/$APP_NAME" -e "$LEGACY_APP/Contents/MacOS/T3 Code (Beta)" >/dev/null
}

install() {
  [ -d "$BUILT" ] || { echo "No build at $BUILT; run build first." >&2; exit 1; }
  if app_running; then
    echo "Waiting for $APP_NAME to quit..."
    while app_running; do sleep 2; done
  fi
  mkdir -p "$BACKUPS"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  if [ -d "$APP" ]; then
    # Keep one rollback: drop older AW Code backups before saving the current one.
    find "$BACKUPS" -maxdepth 1 -name "$APP_NAME *.app" -exec rm -rf {} +
    mv "$APP" "$BACKUPS/$APP_NAME $stamp.app"
  fi
  [ -d "$LEGACY_APP" ] && mv "$LEGACY_APP" "$BACKUPS/T3 Code (Beta) $stamp.app"
  ditto "$BUILT" "$APP"
  open "$APP"
  echo "Installed. Previous app saved in $BACKUPS."
}

case "${1:-sync}" in
  sync) merge_latest && build ;;
  build) build ;;
  install) install ;;
  *) echo "usage: $0 [sync|build|install]" >&2; exit 64 ;;
esac

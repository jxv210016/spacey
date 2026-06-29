#!/usr/bin/env bash
#
# make-dmg.sh
# ---------------------------------------------------------------------------
# Build a distributable disk image (.dmg) from an already-built Spacey.app.
#
# The DMG is the asset Spacey's in-app updater looks for: UpdateChecker.swift
# polls the GitHub "latest release" API and downloads the first asset whose
# name ends in .dmg/.zip/.pkg. So every release must ship a downloadable image,
# and this script produces it with the conventional name `Spacey-<version>.dmg`.
#
# This script only *packages* an app — it does NOT build, sign, or notarize.
# In CI (.github/workflows/release.yml) the app is built, codesigned with a
# Developer ID identity, notarized, and stapled BEFORE this runs; the resulting
# DMG is then itself signed/notarized/stapled by the workflow. Run standalone it
# still produces a perfectly good (un-notarized) image for local testing.
#
# USAGE
#   scripts/make-dmg.sh [/path/to/Spacey.app]
#
#   The app path may be given as the first argument or via the APP_PATH env var.
#   The output directory defaults to ./dist but can be overridden with OUT_DIR.
#
# ENVIRONMENT
#   APP_PATH   Path to the built Spacey.app (alternative to the positional arg).
#   OUT_DIR    Directory to write the .dmg into (default: <repo>/dist).
#   VOL_NAME   Volume name shown when the DMG is mounted (default: "Spacey").
#
# OUTPUT
#   $OUT_DIR/Spacey-<version>.dmg  (version read from the app's Info.plist)
#   The resolved path is also echoed on the final line and, when running under
#   GitHub Actions, exported as the `dmg` step output via $GITHUB_OUTPUT.
# ---------------------------------------------------------------------------

set -euo pipefail

# --- Resolve repo root (this script lives in <repo>/scripts) -----------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="Spacey"

# --- 1. Resolve the input app bundle -----------------------------------------
# Precedence: positional argument, then APP_PATH env var.
APP_PATH="${1:-${APP_PATH:-}}"
if [[ -z "$APP_PATH" ]]; then
  echo "ERROR: no app path given. Pass it as the first argument or set APP_PATH." >&2
  echo "       usage: scripts/make-dmg.sh /path/to/${APP_NAME}.app" >&2
  exit 1
fi

# Normalise to an absolute path so later `cd`/symlink operations are unambiguous.
APP_PATH="$(cd "$(dirname "$APP_PATH")" && pwd)/$(basename "$APP_PATH")"
if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: app bundle not found at: $APP_PATH" >&2
  exit 1
fi

# --- 2. Read the marketing version from the app's Info.plist -----------------
# Prefer `defaults read` (fast, ships with macOS); fall back to plutil if the
# key isn't found, then to a placeholder so the script never produces an
# unnamed image.
INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "ERROR: $APP_PATH has no Contents/Info.plist — is this a real app bundle?" >&2
  exit 1
fi

VERSION="$(defaults read "$INFO_PLIST" CFBundleShortVersionString 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
  # plutil works on the raw file and is robust to odd plist encodings.
  VERSION="$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST" 2>/dev/null || true)"
fi
if [[ -z "$VERSION" ]]; then
  echo "WARNING: could not read CFBundleShortVersionString; using 'unknown'." >&2
  VERSION="unknown"
fi
echo "==> Packaging ${APP_NAME} version ${VERSION}"

# --- 3. Prepare the output directory and DMG name ----------------------------
OUT_DIR="${OUT_DIR:-$REPO_ROOT/dist}"
VOL_NAME="${VOL_NAME:-$APP_NAME}"
mkdir -p "$OUT_DIR"
DMG_PATH="$OUT_DIR/${APP_NAME}-${VERSION}.dmg"

# Remove any stale image with the same name so hdiutil doesn't refuse to write.
rm -f "$DMG_PATH"

# --- 4. Build a clean staging directory --------------------------------------
# The DMG should contain exactly two things: the app and a symlink to
# /Applications so users can drag-install. We stage into a temp dir (cleaned up
# on exit) rather than imaging the app in place, to avoid bundling stray files.
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/spacey-dmg.XXXXXX")"
cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

echo "==> Staging bundle in $STAGING_DIR"
# -R: recursive copy, preserving the bundle structure and symlinks within it.
cp -R "$APP_PATH" "$STAGING_DIR/${APP_NAME}.app"
# The classic "drag me to Applications" affordance.
ln -s /Applications "$STAGING_DIR/Applications"

# --- 5. Create the compressed disk image -------------------------------------
# UDZO  = zlib-compressed read-only image (the standard for distribution).
# -srcfolder images the whole staging dir; -volname sets the mounted name.
echo "==> Creating disk image at $DMG_PATH"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG_PATH"

echo "==> Done."
echo "$DMG_PATH"

# When running inside GitHub Actions, expose the path to later steps.
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dmg=$DMG_PATH"
    echo "version=$VERSION"
  } >> "$GITHUB_OUTPUT"
fi

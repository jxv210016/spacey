#!/usr/bin/env bash
#
# install-and-refresh-icon.sh
# ---------------------------------------------------------------------------
# Installs Spacey.app into /Applications from a stable, sealed ad-hoc build and
# forces macOS to forget any stale, icon-less copy of the app icon.
#
# WHY THIS SCRIPT EXISTS
# ----------------------
# Spacey is a menu-bar-only (LSUIElement) app that requests Accessibility
# permission, so it appears in System Settings > Privacy & Security >
# Accessibility. The app bundle itself is correct: AppIcon.icns is embedded and
# the Info.plist carries both CFBundleIconFile and CFBundleIconName = "AppIcon"
# (verified at build time). Despite that, the icon can render blank/generic in
# the Accessibility list. Two things cause this:
#
#   1. CACHING. macOS caches the icon for a TCC entry via IconServices the first
#      time the app is registered. If Spacey was added to the Accessibility list
#      *before* the icon existed, the icon-less version is cached and never
#      refreshed on its own.
#
#   2. NO STABLE IDENTITY. Building with CODE_SIGNING_ALLOWED=NO produces a
#      "linker-signed" ad-hoc binary with `Sealed Resources=none` and
#      `Info.plist=not bound` (see `codesign -dv --verbose=4`). Combined with the
#      volatile DerivedData path (…/DerivedData/Spacey-<random>/…), LaunchServices
#      and IconServices have no durable key to hang the icon on, so the cache is
#      never invalidated across rebuilds.
#
# THE FIX: install one stable copy to /Applications, give it a *sealed* ad-hoc
# signature so the bundle (and its icon) are properly bound, flush the icon
# caches, and re-register with LaunchServices. The user then removes + re-adds
# Spacey in the Accessibility list so TCC re-reads the icon from the fresh copy.
#
# This script intentionally avoids `sudo rm -rf` on system paths. It only:
#   - copies into /Applications (sudo only if that dir isn't user-writable),
#   - clears the *user* IconServices cache under ~/Library/Caches,
#   - restarts user-level agents (iconservicesagent, Dock).
# ---------------------------------------------------------------------------

set -euo pipefail

# --- Locate the repo root (this script lives in <repo>/scripts) --------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="Spacey"
DEST="/Applications/${APP_NAME}.app"

echo "==> Spacey icon installer/refresher"
echo "    repo: $REPO_ROOT"

# --- 1. Build (unless a fresh build is reused via SKIP_BUILD=1) --------------
if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> Regenerating Xcode project (xcodegen)…"
  if command -v xcodegen >/dev/null 2>&1; then
    ( cd "$REPO_ROOT" && xcodegen generate )
  else
    echo "    WARNING: xcodegen not found; using existing Spacey.xcodeproj."
  fi

  # Release (not Debug): Debug builds embed a separate Spacey.debug.dylib that
  # breaks under an ad-hoc deep re-sign (mismatched identities → dyld refuses to
  # load). Release has no debug dylib, so the installed copy launches cleanly.
  echo "==> Building Spacey (Release, no code signing)…"
  ( cd "$REPO_ROOT" && xcodebuild \
      -project "${APP_NAME}.xcodeproj" \
      -scheme "$APP_NAME" \
      -configuration Release \
      -destination 'platform=macOS' \
      CODE_SIGNING_ALLOWED=NO \
      build )
else
  echo "==> SKIP_BUILD=1 set; reusing the latest existing build."
fi

# --- 2. Find the freshest built app in DerivedData ---------------------------
echo "==> Locating built app in DerivedData…"
BUILT_APP="$(/bin/ls -dt "$HOME"/Library/Developer/Xcode/DerivedData/Spacey-*/Build/Products/Release/${APP_NAME}.app 2>/dev/null | head -1 || true)"
if [[ -z "$BUILT_APP" || ! -d "$BUILT_APP" ]]; then
  echo "    ERROR: could not find a built ${APP_NAME}.app. Run a build first." >&2
  exit 1
fi
echo "    found: $BUILT_APP"

# Sanity-check the icon is actually inside the bundle before we install it.
if [[ ! -f "$BUILT_APP/Contents/Resources/AppIcon.icns" ]]; then
  echo "    ERROR: $BUILT_APP has no Contents/Resources/AppIcon.icns." >&2
  exit 1
fi
echo "==> Verifying embedded icns is valid…"
sips -g pixelWidth -g pixelHeight "$BUILT_APP/Contents/Resources/AppIcon.icns" >/dev/null
echo "    icns OK"

# --- 3. Copy into /Applications (stable, non-volatile location) --------------
# A helper so we only escalate to sudo when /Applications isn't user-writable.
run_priv() {
  if [[ -w /Applications ]]; then "$@"; else sudo "$@"; fi
}

echo "==> Installing to $DEST …"
if [[ -d "$DEST" ]]; then
  echo "    removing previous copy"
  run_priv /bin/rm -rf "$DEST"
fi
run_priv /bin/cp -R "$BUILT_APP" "$DEST"

# --- 4. Give the installed copy a sealed ad-hoc signature --------------------
# The DerivedData build is "linker-signed" (Sealed Resources=none). Re-signing
# with `codesign -f -s -` seals the bundle resources and binds the Info.plist,
# giving IconServices a stable thing to read the icon from.
echo "==> Re-signing /Applications copy with a sealed ad-hoc signature…"
ENTITLEMENTS="$REPO_ROOT/Sources/${APP_NAME}/${APP_NAME}.entitlements"
if [[ -f "$ENTITLEMENTS" ]]; then
  run_priv /usr/bin/codesign --force --deep --sign - \
    --entitlements "$ENTITLEMENTS" \
    --options runtime "$DEST" || \
  run_priv /usr/bin/codesign --force --deep --sign - "$DEST"
else
  run_priv /usr/bin/codesign --force --deep --sign - "$DEST"
fi
echo "==> Verifying signature…"
codesign -dv --verbose=4 "$DEST" 2>&1 | grep -E 'Signature|Sealed Resources' || true

# --- 5. Flush icon caches & re-register with LaunchServices ------------------
echo "==> Flushing user IconServices cache…"
# Only the *user* cache — never touch system caches with rm -rf.
/bin/rm -rf "$HOME/Library/Caches/com.apple.iconservices.store" 2>/dev/null || true
find "$HOME/Library/Caches" -maxdepth 1 -name 'com.apple.iconservices*' -exec /bin/rm -rf {} + 2>/dev/null || true

echo "==> Re-registering app with LaunchServices…"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
"$LSREGISTER" -f "$DEST" 2>/dev/null || true

echo "==> Restarting icon services + Dock (this briefly flashes the menu bar/Dock)…"
killall iconservicesagent 2>/dev/null || true
killall iconservicesd     2>/dev/null || true
killall Dock              2>/dev/null || true

# Touch the bundle so mtime changes and caches re-read it.
touch "$DEST"

echo
echo "==============================================================="
echo " DONE. Spacey is installed at: $DEST"
echo "==============================================================="
echo
echo " NEXT STEPS (you must do these by hand — they can't be scripted):"
echo
echo " 1. Quit any running Spacey (menu bar icon > Quit, or):"
echo "        killall Spacey 2>/dev/null || true"
echo
echo " 2. Open System Settings > Privacy & Security > Accessibility."
echo
echo " 3. Find 'Spacey' in the list. Select it and click the '-' (minus)"
echo "    button to REMOVE it. (If a sheet asks, confirm.)"
echo
echo " 4. Launch the freshly installed copy:"
echo "        open \"$DEST\""
echo
echo " 5. When Spacey asks for Accessibility, click 'Open System Settings'"
echo "    and enable the toggle — OR click '+' in the Accessibility list and"
echo "    pick $DEST."
echo
echo " The entry should now show the Spacey icon (read from the fresh,"
echo " sealed /Applications copy instead of the stale cache)."
echo

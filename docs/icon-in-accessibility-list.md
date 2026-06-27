# Fixing the blank Spacey icon in the Accessibility list

## Symptom

The Spacey icon shows correctly on `Spacey.app` in Finder, but appears **blank /
generic** next to "Spacey" in **System Settings ▸ Privacy & Security ▸
Accessibility**.

## Root cause

The app bundle is **correct** — this is a caching / app-identity problem, not a
missing-icon problem:

- `Contents/Resources/AppIcon.icns` is present and valid (`iconutil`/`sips` OK).
- The built `Info.plist` carries **both** `CFBundleIconFile = AppIcon` **and**
  `CFBundleIconName = AppIcon` (injected by the asset-catalog compiler; now also
  declared explicitly in `Sources/Spacey/Info.plist`).

Two things keep the Accessibility list showing a stale icon:

1. **IconServices/TCC cached the icon-less version.** macOS caches the icon for a
   TCC entry the first time the app is registered. Spacey was added to the
   Accessibility list *before* the icon existed, so the blank icon was cached and
   is never refreshed automatically.

2. **No stable code identity / volatile path.** Building with
   `CODE_SIGNING_ALLOWED=NO` yields a *linker-signed* ad-hoc binary —
   `codesign -dv --verbose=4` reports `Sealed Resources=none` and
   `Info.plist=not bound`. Run from `…/DerivedData/Spacey-<random>/…`, there is
   no durable key for LaunchServices/IconServices to invalidate, so the cached
   icon sticks across rebuilds.

## The fix

Install one stable, **sealed** copy to `/Applications`, flush the icon caches,
re-register with LaunchServices, then **remove + re-add** Spacey in the
Accessibility list so TCC re-reads the icon from the fresh copy.

Run:

```sh
./scripts/install-and-refresh-icon.sh
```

(Use `SKIP_BUILD=1 ./scripts/install-and-refresh-icon.sh` to reuse the latest
DerivedData build instead of rebuilding.)

The script:
- builds (or reuses) `Spacey.app` and copies it to `/Applications`,
- re-signs it with a **sealed** ad-hoc signature (`codesign --force --deep --sign -`)
  so the bundle/Info.plist are bound,
- clears the **user** IconServices cache (`~/Library/Caches/com.apple.iconservices*`
  only — never system paths with `sudo rm -rf`),
- re-registers via `lsregister` and restarts `iconservicesagent` / `Dock`.

## Should I remove and re-add it in Accessibility? — YES

Yes. Resetting caches alone is usually not enough because the TCC pane holds its
own cached icon for the existing entry. After running the script:

1. Quit Spacey:  `killall Spacey 2>/dev/null || true`
2. **System Settings ▸ Privacy & Security ▸ Accessibility.**
3. Select **Spacey** → click **–** (minus) to remove it.
4. Launch the fresh copy:  `open /Applications/Spacey.app`
5. When prompted, enable Spacey under Accessibility (or click **+** and pick
   `/Applications/Spacey.app`).

The entry then shows the Spacey icon.

> Always launch the `/Applications` copy from now on — not the DerivedData build —
> so the icon and permission stay stable across rebuilds.

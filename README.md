<div align="center">

# Spacey

**Name your macOS Spaces and jump between them with hotkeys.**

A free, open-source, no-SIP alternative to SpaceJump / Spaces Renamer for Apple Silicon.

</div>

---

> [!NOTE]
> Spacey is in early development (Phase 0). The current build proves the core
> read path: it lives in your menu bar and shows your current Space and layout
> live. Naming, hotkeys, and the quick-switcher are on the way — see the
> [build plan](docs/PLAN.md).

## Why

macOS Spaces (virtual desktops) are anonymous and positional. You can't name them,
and the only way to jump to one is a fragile, off-by-default keyboard shortcut that
macOS silently renumbers when it reshuffles your desktops. Spacey fixes that:

- 🏷️ **Name your Spaces** (label + icon + color), tied to a stable identity that
  survives reboots and macOS auto-reordering.
- 🧭 **Menu-bar indicator** that always shows which Space you're on.
- ⌨️ **Reliable name-based hotkeys** and a **quick-switcher palette** to jump to any
  Space — shortcuts that don't break when macOS renumbers desktops.

### What Spacey deliberately does *not* do

Spacey **never asks you to disable SIP**. That's the whole design philosophy. The
trade-off: custom names appear in Spacey's own menu bar and switcher — **not inside
Apple's Mission Control overlay** (that requires injecting code into `Dock.app` with
SIP partially disabled, which is fragile and breaks on macOS point releases). See
[`docs/PLAN.md`](docs/PLAN.md) for the full technical reasoning.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (also builds universal)

## Build from source

```bash
brew install xcodegen          # one-time: project generator
git clone https://github.com/<you>/spacey.git
cd spacey
xcodegen generate              # creates Spacey.xcodeproj from project.yml
open Spacey.xcodeproj          # then build & run in Xcode (⌘R)
```

Or from the command line:

```bash
xcodegen generate
xcodebuild -project Spacey.xcodeproj -scheme Spacey -destination 'platform=macOS' build
```

The `.xcodeproj` is generated and **not** committed — edit [`project.yml`](project.yml)
and regenerate.

## Roadmap

| Phase | Status | What |
|------:|:------:|------|
| 0 | ✅ in progress | Scaffold, CI, live menu-bar Space indicator (read path) |
| 1 | ⏳ | Robust change observation (plist watch), multi-display polish |
| 2 | ⏳ | Naming: labels, icons, colors, persistence |
| 3 | ⏳ | Hotkeys + quick-switcher palette + jump-to-previous |
| 4 | ⏳ | Move-window-to-Space, launch at login, settings polish |
| 5 | ⏳ | Signing, notarization, Sparkle auto-update, Homebrew Cask |

Full detail: [`docs/PLAN.md`](docs/PLAN.md).

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md). By participating you
agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## How it works (briefly)

Spacey reads your Spaces through the private SkyLight (`SLSCopyManagedDisplaySpaces`)
API — the same read-only, no-SIP approach used by WhichSpace and AltTab. All private
symbols are resolved at runtime via `dlsym` and isolated in a single file
([`SkyLightBridge.swift`](Sources/Spacey/SpacesEngine/SkyLightBridge.swift)) so the
app degrades gracefully if Apple renames them. Custom names are stored in Spacey's
own preferences, keyed by each Space's stable UUID.

## License

[MIT](LICENSE) © Spacey contributors

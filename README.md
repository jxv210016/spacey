<div align="center">

# Spacey

**Name your macOS desktops, switch between them by name, and see those names right inside Mission Control.**

A free, open-source, **no‑SIP** alternative to SpaceJump / Spaces Renamer for Apple Silicon.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS 14+](https://img.shields.io/badge/macOS-14%2B-black.svg)](#requirements)
[![Dependencies: none](https://img.shields.io/badge/dependencies-zero-brightgreen.svg)](#zero-dependencies)

</div>

---

## What it is

Spacey is a lightweight macOS menu‑bar utility that gives your virtual desktops
(**Spaces**) real identities.

macOS Spaces are **anonymous and positional**: you can't name them, and the only
built‑in way to reach one is a fragile, off‑by‑default keyboard shortcut that macOS
silently renumbers whenever it reshuffles your desktops. If "Space 3" is your email
desktop today, it might be Space 2 tomorrow.

Spacey fixes that. Give each Space a name, an icon, and a color — and those names
follow you everywhere: in the menu bar, and **inside Apple's own Mission Control
overlay**, all without ever disabling System Integrity Protection (SIP).

## Screenshots

> Screenshots and GIFs live in [`docs/screenshots/`](docs/screenshots/). See that
> folder's [README](docs/screenshots/README.md) for what to capture and where to
> drop files. The links below will render once the images are added.

| Menu‑bar list & naming | Names in Mission Control | Settings |
|---|---|---|
| ![Spacey menu‑bar dropdown with named Spaces](docs/screenshots/menu-bar.png) | ![Custom names shown inside Mission Control](docs/screenshots/mission-control.png) | ![Spacey settings window](docs/screenshots/settings.png) |

## Features

### Naming
- Give each Space a **label, an optional SF Symbol icon, and a color**.
- Names are keyed to each Space's **stable UUID**, so they **survive reboots and
  macOS auto‑reordering** of desktops.
- Edit inline from the menu‑bar dropdown — no separate editor to open.

### Menu‑bar indicator
- A persistent menu‑bar item that always shows your **current Space**'s name/icon.
- **Multi‑display aware** — the dropdown groups Spaces per display and marks the
  active one.
- The dropdown lists every Space; **click any row to switch to it**.

### Names in Mission Control  ·  *the headline feature*
- Your custom names are drawn **on top of the real Mission Control Spaces Bar**,
  using a no‑SIP Accessibility overlay.
- Works whether the Spaces Bar is **collapsed** (the thin strip at the top) or
  **expanded** (hover to reveal full thumbnails) — labels track the live positions.
- On by default; toggle it any time from the menu or the Mission Control settings
  pane. Requires the Accessibility permission (see [Permissions](#permissions)).

### Switching & hotkeys
- **Click‑to‑switch** from the menu: Spacey steps to the target Space by driving the
  built‑in Control + ← / → Mission Control shortcuts through System Events — the
  reliable, no‑SIP path.
- **Global hotkeys** and a **Quick Switcher** command palette (type‑to‑filter by
  name, numeric jump, ↑/↓ + Return) let you jump to a Space by name from anywhere.

### Quality of life
- **Add Desktop** straight from the menu (drives Mission Control's own “+”, no SIP).
- **Launch at login** via `SMAppService` (no helper app, no external dependency).
- **First‑run onboarding** that walks you through the one permission Spacey needs.
- **In‑app update check** against GitHub Releases — it tells you when a new version
  is out and links you to the download. There's no silent auto‑installer.
- A modern **Settings** window with sidebar panes: General, Appearance, Mission
  Control, Permissions, Updates, and About (plus a Shortcuts pane for hotkeys).

## Why Spacey

| | Spacey | SpaceJump | Spaces Renamer | yabai |
|---|:---:|:---:|:---:|:---:|
| Price | **Free** | Paid | Free | Free |
| Open source | **Yes** | No | No | Yes |
| Names in Mission Control | **Yes** | Yes | Yes | n/a |
| Requires disabling SIP | **No** | No | **Yes** | **Yes** (for most features) |
| Works on Apple Silicon | **Yes** | Yes | Often broken | Yes |

Spacey's wedge: **free + open + polished + no‑SIP**. It never disables SIP and never
injects code into `Dock.app`; it reads your Spaces through the same read‑only,
long‑stable private APIs that tools like AltTab and WhichSpace use, and it paints
names with an Accessibility overlay rather than modifying the system.

<a name="zero-dependencies"></a>
### Zero dependencies
Spacey has **no third‑party Swift packages** — no Sparkle, no helper libraries.
Everything (the update check, launch‑at‑login, hotkeys, the overlay) is built on
the macOS SDK alone. That keeps the app small, auditable, and easy to build.

## Requirements

- **macOS 14 (Sonoma) or later**
- **Apple Silicon** (also builds as a universal binary)

## Install

### Download (recommended, when available)
Grab the latest notarized build from the
[**Releases page**](https://github.com/jxv210016/spacey/releases), move `Spacey.app`
to `/Applications`, and launch it. Spacey checks for newer releases on its own and
points you to the download when one appears.

> Releases are still being prepared. Until a signed build is posted, build from
> source below.

### Build from source
See the next section.

## Build from source

**Prerequisites**

- **Xcode 16+** (Xcode command‑line tools installed)
- The build/lint toolchain via [Homebrew](https://brew.sh):
  ```bash
  brew install xcodegen swiftlint swiftformat
  ```

Spacey uses **[XcodeGen](https://github.com/yonaskolb/XcodeGen)**: the
`Spacey.xcodeproj` is **generated** from [`project.yml`](project.yml) and is **not**
committed. Generate it first, then build.

**Build and run in Xcode**

```bash
git clone https://github.com/jxv210016/spacey.git
cd spacey
xcodegen generate            # creates Spacey.xcodeproj from project.yml
open Spacey.xcodeproj         # then build & run (⌘R)
```

**Build from the command line**

```bash
xcodegen generate
xcodebuild -scheme Spacey -configuration Release build
```

**Install a built copy locally**

A helper script builds a Release copy, installs it to `/Applications`, gives it a
sealed ad‑hoc signature, and refreshes the icon caches (this last part works around
a macOS quirk where the app icon can render blank in the Privacy lists — see
[`docs/icon-in-accessibility-list.md`](docs/icon-in-accessibility-list.md)):

```bash
bash scripts/install-and-refresh-icon.sh
```

The script prints the manual follow‑up steps for granting Accessibility to the
freshly installed copy.

## Permissions

Spacey requests a single macOS permission:

- **Accessibility** — needed to (a) read the Mission Control Spaces Bar so it can
  draw your custom names over it, (b) drive the built‑in Control + ← / → shortcuts
  to switch Spaces, and (c) press Mission Control's “Add Desktop” button.

What Spacey does **not** do:

- It **never disables SIP** and **never injects into `Dock.app`**.
- It reads only the Spaces layout — **no window titles, no screen contents, no
  keystrokes**. It does **not** request Screen Recording or Input Monitoring.
- Switching also relies on the macOS **Apple Events** entitlement to control System
  Events; macOS will prompt you to allow that the first time.

The first‑run onboarding flow guides you through granting Accessibility, and Spacey
re‑arms itself automatically once permission is granted — no relaunch needed.

> **Why no Mac App Store?** A Spaces manager fundamentally needs Accessibility and
> Apple Events, which the App Sandbox forbids. Spacey is therefore non‑sandboxed and
> distributed directly — fully compatible with Developer ID notarization, just not
> with the Mac App Store. This is a deliberate design choice.

## Honest limitations

Spacey deliberately stays on the durable, no‑SIP side of macOS. That means a few
things it intentionally does **not** do:

- **Switching needs the built‑in shortcuts.** Space switching drives the standard
  Mission Control **Control + ←/→** shortcuts via System Events. Those are enabled
  by default; if you've turned them off (or **Secure Keyboard Entry** is active in,
  e.g., Terminal), switching won't work until they're restored.
- **Absolute "jump to Space N" is approximate.** Spacey reaches a target by stepping
  relatively from the current Space, which is reliable within a display. There is no
  SIP‑based "teleport to any arbitrary Space" primitive.
- **Moving a window across Spaces is not in this version.** That's a yabai‑style
  feature that's hard to do well without SIP.
- **Permissions can go stale after macOS updates.** macOS sometimes drops TCC grants
  across OS upgrades; you may need to re‑grant Accessibility. Spacey detects this and
  prompts you.

See [`docs/PLAN.md`](docs/PLAN.md) for the full technical reasoning behind the
no‑SIP design and the SIP boundary it stays on.

## Contributing

Contributions are very welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the
XcodeGen workflow, build/test/lint commands, and the project's design boundaries.
By participating you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE) © Spacey contributors

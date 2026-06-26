# Contributing to Spacey

Thanks for your interest! Spacey is a SwiftUI menu-bar app for naming and switching
macOS Spaces. This guide gets you set up.

## Prerequisites

- macOS 14+ and Xcode 16+ (Xcode 26 recommended)
- Developer tools:
  ```bash
  brew install xcodegen swiftlint swiftformat
  ```

## Getting started

```bash
git clone https://github.com/<you>/spacey.git
cd spacey
xcodegen generate
open Spacey.xcodeproj
```

The `.xcodeproj` is **generated** from [`project.yml`](project.yml) and is not
committed. If you change targets, files, or build settings, edit `project.yml` and
re-run `xcodegen generate` — don't hand-edit the `.xcodeproj`.

## Before you open a PR

Run the same checks CI runs:

```bash
swiftformat .            # auto-format
swiftlint                # lint
xcodebuild -project Spacey.xcodeproj -scheme Spacey -destination 'platform=macOS' build test
```

## Architecture notes

- **All private SkyLight/CGS API usage lives in `Sources/Spacey/SpacesEngine/SkyLightBridge.swift`.**
  Keep it that way — resolve symbols via `dlsym`, weak-typed, and feature-gate every
  call so a renamed symbol degrades gracefully instead of crashing.
- Parsing logic (`SpacesReader.parse`) is a pure function so it can be unit-tested
  without the private API. Add fixtures to `Tests/SpaceyTests` when you change it.
- No SIP-requiring features. If a feature needs `Dock.app` injection or SIP disabled,
  it's out of scope — see [`docs/PLAN.md`](docs/PLAN.md).

## Commit & PR conventions

- Keep PRs focused; one logical change per PR.
- Write a clear description of *what* and *why*.
- Reference any related issue (`Fixes #123`).
- Make sure CI is green.

## Reporting bugs / requesting features

Use the issue templates. For Spaces/SkyLight bugs, please include your exact macOS
version (`sw_vers`) — these private APIs vary across builds.

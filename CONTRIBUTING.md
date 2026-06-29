# Contributing to Spacey

Thanks for your interest! Spacey is a SwiftUI menu‑bar app for naming and switching
macOS Spaces, with a no‑SIP overlay that shows your names inside Mission Control.
This guide gets you set up and explains the boundaries the project keeps.

## Prerequisites

- **macOS 14+** and **Xcode 16+**
- The toolchain via [Homebrew](https://brew.sh):
  ```bash
  brew install xcodegen swiftlint swiftformat
  ```

## Getting set up

Spacey is built with **[XcodeGen](https://github.com/yonaskolb/XcodeGen)**. The
`Spacey.xcodeproj` is **generated** from [`project.yml`](project.yml) and is **not**
committed to the repo. This keeps merge conflicts out of the project file and makes
the build configuration reviewable as plain YAML.

```bash
git clone https://github.com/jxv210016/spacey.git
cd spacey
xcodegen generate      # generates Spacey.xcodeproj from project.yml
open Spacey.xcodeproj
```

**If you change targets, files, build settings, or schemes, edit `project.yml` and
re‑run `xcodegen generate`.** Do not hand‑edit the `.xcodeproj` — your changes would
be lost on the next regeneration and can't be reviewed.

## Build, run, and test

Generate the project first (`xcodegen generate`), then:

```bash
# Build
xcodebuild -scheme Spacey -configuration Release build

# Run the test suite
xcodebuild test -scheme Spacey -destination 'platform=macOS'
```

You can also build and run interactively in Xcode with ⌘R, and run tests with ⌘U.

To install a local copy to `/Applications` (and work around the blank‑icon quirk in
the Privacy lists), use the helper script:

```bash
bash scripts/install-and-refresh-icon.sh
```

## Lint and format

The project is kept at **zero lint warnings**. Run both before opening a PR — they
are separate gates that CI also runs:

```bash
swiftformat .      # auto-formats to .swiftformat
swiftlint          # lints against .swiftlint.yml (keep it clean)
```

Configuration lives in [`.swiftformat`](.swiftformat) and
[`.swiftlint.yml`](.swiftlint.yml). If a rule genuinely needs to change, change it in
the config (with rationale in your PR) rather than scattering inline disables.

## Project design boundaries

Two rules are non‑negotiable. PRs that cross them will be declined regardless of
quality:

### 1. Zero third‑party dependencies
Spacey ships with **no SwiftPM packages** — the update check, launch‑at‑login,
hotkeys, and the Mission Control overlay are all built on the macOS SDK alone. This
keeps the app small, auditable, and trivially buildable. **PRs that add a SwiftPM
(or any external) dependency will be declined.** If you think a dependency is truly
unavoidable, open an issue to discuss it first.

### 2. No SIP, no Dock injection
Spacey never disables System Integrity Protection and never injects code into
`Dock.app`. Names appear via a read‑only Accessibility overlay; switching drives the
built‑in Mission Control keyboard shortcuts. **Any feature that would require
disabling SIP or injecting a scripting addition into Dock is out of scope** — see
the SIP boundary discussion in [`docs/PLAN.md`](docs/PLAN.md).

## Code organization notes

- **All private SkyLight/CGS API usage lives in
  [`Sources/Spacey/SpacesEngine/SkyLightBridge.swift`](Sources/Spacey/SpacesEngine/SkyLightBridge.swift).**
  Keep it that way — symbols are resolved at runtime via `dlsym` and feature‑gated so
  a renamed symbol degrades gracefully instead of crashing the app.
- Parsing logic (e.g. `SpacesReader`) is written as **pure functions** so it can be
  unit‑tested without the private API. Add fixtures under `Tests/SpaceyTests/` when
  you touch parsing or mapping code.

## Commit & PR conventions

- Keep PRs **focused** — one logical change per PR.
- Write a clear description of **what** changed and **why**.
- Reference related issues (e.g. `Fixes #123`).
- Make sure the build, tests, SwiftLint, and SwiftFormat are all green.

## Reporting bugs / requesting features

Please use the issue templates. For Spaces / SkyLight / Mission Control bugs,
**include your exact macOS version** (`sw_vers`) — these private APIs and the Mission
Control accessibility tree vary across builds, and that detail is often the key to a
fix.

By contributing, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

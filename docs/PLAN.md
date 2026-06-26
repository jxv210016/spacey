# Spacey — Build Plan

> Open-source macOS menu-bar utility for **naming virtual desktops (Spaces)** and
> **switching between them with hotkeys**, on Apple Silicon. A free, no-SIP
> alternative to SpaceJump / Spaces Renamer.

**License:** MIT · **Target:** macOS 14 (Sonoma)+ · **Arch:** Apple Silicon (universal binary) · **Distribution:** notarized direct download + Homebrew Cask

---

## 1. Vision & positioning

macOS Spaces are anonymous and positional. You can only reach them via fragile,
off-by-default, position-based shortcuts that macOS silently renumbers. There is
no native way to *name* a Space. Spacey fixes this:

- **Name your Spaces** (label + icon + color), keyed to a stable identity so the
  name survives reboots and macOS auto-reordering.
- **A persistent menu-bar indicator** showing the current Space's name.
- **Reliable, name-based global hotkeys** + a **quick-switcher palette** to jump
  to any Space — shortcuts that don't break when macOS reshuffles desktop numbers.

**The defining constraint (chosen): no SIP disabling.** Names appear in *Spacey's
own UI* (menu bar + switcher overlay), **not** inside Apple's Mission Control
overlay. Putting labels into real Mission Control requires injecting code into
`Dock.app`, which on Apple Silicon needs partial SIP disable — fragile, breaks on
macOS point releases, and deters users. We deliberately stay on the durable side
of that line. (See §3.)

**Competitors:** SpaceJump ($9.99, closed), Spaces Renamer (SIP-required, broken
on Apple Silicon), Spaceman / DesktopRenamer (free, less polished), yabai (SIP).
Our wedge: **free + open + polished + no-SIP + reliable name-based hotkeys.**

---

## 2. The critical technical finding: the SIP boundary

Everything hinges on one split, confirmed against yabai, AltTab, and WhichSpace
source plus Apple's own docs:

| Capability | Mechanism | SIP? | Durability |
|---|---|---|---|
| **Enumerate Spaces** (per display, count, IDs, UUIDs) | `SLSCopyManagedDisplaySpaces` / `CGSCopyManagedDisplaySpaces` | No | **Stable** Mojave→Sequoia |
| **Detect current Space** | `SLSManagedDisplayGetCurrentSpace` / `CGSGetActiveSpace` | No | **Stable** |
| **Watch for Space changes** | plist `.delete` watch + `NSWorkspace.activeSpaceDidChangeNotification` | No | **Stable** |
| **Switch Space (relative / first N)** | drive built-in Mission Control shortcuts via AppleScript / System Events | No | Reliable (needs Accessibility + Automation) |
| **Switch to *arbitrary* Space, in-Mission-Control labels, move window cross-space** | inject scripting addition into `Dock.app` | **Yes (partial disable)** | **Fragile** — breaks on point releases (12.3, 14.4, 15.4…) |

**Design rule: build the entire app on the no-SIP (top) rows.** Every feature
below is achievable without SIP. The one feature we *cannot* fully match —
arbitrary jump-to-any-Space — we approximate (see §5, Switching).

### Private API specifics

- Framework: `/System/Library/PrivateFrameworks/SkyLight.framework`. Symbols
  renamed `CGS*` → `SLS*`; both coexist via shims. **`dlsym`/weak-link** them
  (don't hard-link) so we can feature-gate and survive symbol drift.
- Connection handle: `SLSMainConnectionID()` / `_CGSDefaultConnection()`.
- `SLSCopyManagedDisplaySpaces(cid)` → `CFArray` of per-display dicts:
  `"Display Identifier"` (UUID or `"Main"`), `"Spaces"` (ordered array; length =
  count), `"Current Space"`. Each Space dict has `"uuid"` (stable, our naming
  key), `"id64"` / `"ManagedSpaceID"` (the 64-bit handle), `"type"`.
- **Naming key = the Space `"uuid"` string** (survives reboots). Store names in
  *our own* `UserDefaults`/`Defaults`, never in `com.apple.spaces.plist` (the OS
  ignores foreign keys and rewrites that file atomically).
- **Space → user-visible number** = positional index within the ordered
  `"Spaces"` array (the `ManagedSpaceID` values are opaque, non-sequential).
- **Change detection:** macOS rewrites `~/Library/Preferences/com.apple.spaces.plist`
  atomically, so watch a `DispatchSource` file-system source for the `.delete`
  event and re-arm on the new inode; supplement with `activeSpaceDidChangeNotification`
  (a bare "something changed" ping — no payload, misses some fullscreen transitions).
- **Runtime-probe `SLSSpaceGetType` values per OS build** — fullscreen/tiled enum
  values drift; detect fullscreen by presence of a `"TileLayoutManager"` sub-dict
  (the WhichSpace approach) rather than trusting the numeric type.

### Notarization & permissions (confirmed)

- Private CGS/SkyLight APIs **do not block notarization** — notarization is an
  automated malware scan, *not* App Review. Proof: AltTab ships signed+notarized
  using exactly these symbols. (They *do* make us Mac-App-Store-ineligible and
  rule out sandboxing — both fine for a direct-download utility.)
- Permissions required: **Accessibility** (to drive System Events for switching;
  probe via `AXIsProcessTrusted()` + a live `CGEventTap` attempt), **Automation/
  Apple Events** (to control System Events). **Not** required: Screen Recording
  (only needed for window *titles*, which we don't read), Input Monitoring (we use
  Carbon hotkeys, which need no permission).
- Need the **paid Apple Developer Program ($99/yr)** for a Developer ID cert —
  there is no free path to a Gatekeeper-clean download (macOS 15 removed the
  Control-click bypass).

---

## 3. Architecture

```
Spacey.app (LSUIElement, .accessory, non-sandboxed)
│
├─ SpacesEngine                  ← the only module touching private APIs
│   ├─ SkyLightBridge (dlsym wrappers, weak-linked)   // SLSCopy…, current space
│   ├─ SpaceModel { uuid, managedID, displayUUID, index, type }
│   ├─ SpaceObserver (plist .delete watch + activeSpaceDidChange) → publishes snapshots
│   └─ SpaceSwitcher (AppleScript/System Events: next/prev + Ctrl+N for first N)
│
├─ NamingStore                   ← Defaults-backed: uuid → { name, icon, color }
│
├─ Hotkeys                       ← KeyboardShortcuts: per-Space jump, switcher toggle,
│                                   jump-to-previous, move-window-to-space
│
├─ UI (SwiftUI)
│   ├─ MenuBarExtra(.window)     ← indicator + dropdown list of named spaces
│   ├─ QuickSwitcher (NSPanel)   ← command-palette overlay: type-to-filter, 1–9 jump
│   ├─ Settings scene            ← naming editor, hotkey recorders, launch-at-login
│   └─ Onboarding/Permissions    ← guide user through Accessibility + MC shortcuts
│
└─ Infra: LaunchAtLogin-Modern · Sparkle (auto-update) · Defaults
```

**Key isolation principle:** all private-API calls live behind `SpacesEngine`'s
`SkyLightBridge`, each call feature-gated and runtime-probed, so when a macOS
release renames a symbol only one file changes and the app degrades gracefully
instead of crashing.

---

## 4. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| UI | **SwiftUI** `MenuBarExtra(.window)` + AppKit bridges | `MenuBarExtraAccess` for status-item access; `NSPanel` for the switcher overlay |
| Project | **Xcode project** (`.xcodeproj`), SwiftPM deps | a pure SwiftPM package can't build a `.app`; optionally generate via XcodeGen |
| Min OS | **macOS 14** | MenuBarExtra floors at 13; 14 dodges known Settings-window bugs, negligible reach cost |
| Hotkeys | **`KeyboardShortcuts`** (sindresorhus, MIT) | only lib with a native SwiftUI recorder; Carbon-based → no permission needed |
| Launch at login | **`LaunchAtLogin-Modern`** (MIT) | wraps `SMAppService`, macOS 13+ |
| Prefs | **`Defaults`** (sindresorhus, MIT) | type-safe, Codable, observable; `@AppStorage` can't hold dicts/arrays |
| Settings window | SwiftUI `Settings` scene (+ `SettingsAccess` to open from a menu-bar-only app) | |
| Private APIs | `CGSInternal`/SkyLight headers, **dlsym'd** | bridging header for the C symbols |
| Auto-update | **Sparkle 2.x** (MIT), EdDSA-signed appcast on GitHub Pages | strip XPC services (non-sandboxed) |
| Signing | Developer ID + **`notarytool`** (App Store Connect API key) | `altool` is dead since Nov 2023 |
| CI | GitHub Actions `runs-on: macos-15` | build/test + SwiftLint + SwiftFormat `--lint` |
| Lint/format | **SwiftLint** + **SwiftFormat** | both MIT, separate gates |

---

## 5. v1 feature set (feature-rich)

**Naming**
- Name each Space with a label, optional SF Symbol icon, and color.
- Names keyed to Space `uuid` → survive reboot and auto-reorder.
- Inline rename from the menu-bar dropdown and from Settings.

**Indicator**
- Persistent menu-bar item showing the current Space's name/icon/number.
- Multi-display aware (shows the active display's current Space).
- Dropdown lists all Spaces with names; click to switch.

**Switching & hotkeys**
- Global hotkey to open the **Quick Switcher** palette (default e.g. ⌥Space):
  type-to-filter by name, 1–9 numeric jump, ↑/↓ + Return.
- Per-Space assignable global hotkeys (jump directly to "Code", "Email", …).
- **Jump-to-previous-Space** hotkey.
- Switching impl: AppleScript/System Events driving the built-in Mission Control
  shortcuts (relative next/prev always; absolute jump for the first N via
  Ctrl+number). Onboarding walks the user through enabling those shortcuts.
- **Move-active-window-to-Space**: best-effort via accessibility window ops +
  switch (documented limitations vs SIP-based tools).

**System integration**
- Launch at login toggle (`SMAppService`).
- Onboarding flow: request Accessibility + Automation, verify Mission Control
  shortcuts are enabled, explain why.
- Sparkle auto-update.

**Known honest limitations (document in README):**
- No labels inside Apple's Mission Control (no-SIP design choice).
- Absolute "jump to any Space N" is reliable only for the first N Spaces that have
  a Ctrl+number shortcut; beyond that, relative navigation or the switcher palette
  (which chains relative moves) is used.
- Move-window-cross-space is best-effort, not yabai-grade.

---

## 6. Milestones

**Phase 0 — Scaffold (½ day)**
Xcode project, MIT LICENSE, SwiftPM deps, `LSUIElement`, empty `MenuBarExtra`,
SwiftLint/SwiftFormat configs, GitHub Actions build CI, repo hygiene (§7).

**Phase 1 — Read & indicate (the durable core)**
`SkyLightBridge` (dlsym wrappers) → enumerate Spaces + current Space. `SpaceObserver`
(plist `.delete` watch + activeSpaceDidChange). Menu-bar indicator + dropdown list
showing positional numbers. *Milestone: it tracks your current Space live.*

**Phase 2 — Naming**
`NamingStore` (Defaults, keyed by uuid). Rename UI in dropdown + Settings. Icons/
colors. *Milestone: named Spaces persist across reboot/reorder.*

**Phase 3 — Switching & hotkeys**
`SpaceSwitcher` via System Events. `KeyboardShortcuts` integration: switcher
toggle, per-Space jump, jump-to-previous. Quick Switcher `NSPanel` overlay.
Onboarding/permissions flow. *Milestone: hotkey-driven switching works.*

**Phase 4 — Polish & extras**
Move-window-to-Space, multi-display refinements, launch-at-login, Settings polish,
empty/error states, accessibility, localization scaffolding.

**Phase 5 — Release engineering**
Developer ID signing + notarization in CI, Sparkle appcast on GitHub Pages, DMG
packaging, GitHub Release, README with screenshots/GIF, then Homebrew Cask once
the star/fork threshold is met.

---

## 7. Open-source repo hygiene

```
spacey/
├─ Spacey.xcodeproj
├─ Sources/Spacey/…           (App, SpacesEngine, UI, Hotkeys, …)
├─ Tests/SpaceyTests/
├─ docs/                       (PLAN.md, appcast.xml on Pages, screenshots)
├─ .github/
│   ├─ workflows/ci.yml, release.yml
│   ├─ ISSUE_TEMPLATE/{bug_report,feature_request,config}.yml
│   └─ PULL_REQUEST_TEMPLATE.md
├─ .swiftlint.yml  .swiftformat
├─ README.md  LICENSE (MIT)  CONTRIBUTING.md  CODE_OF_CONDUCT.md
└─ .github/FUNDING.yml         (GitHub Sponsors / Ko-fi, optional)
```

- **CI:** `runs-on: macos-15`, `xcodebuild build/test`, SwiftLint, `swiftformat --lint`.
- **Release CI:** gated on tag push only (protects signing secrets from fork PRs);
  decode Developer ID `.p12` from encrypted secret → `notarytool submit --wait` →
  `stapler staple` → attach DMG to Release → `generate_appcast` → commit appcast.
- **Secrets safety:** GitHub doesn't expose repo secrets to fork PR workflows;
  still gate signing to tags/protected branch, or sign on a trusted maintainer
  machine.

---

## 8. Top risks & mitigations

1. **Private symbol drift across macOS releases** → isolate in `SkyLightBridge`,
   `dlsym` + weak-link, feature-gate each call, runtime-probe enum values, degrade
   gracefully. (Read path has been stable for years; this is low but nonzero.)
2. **Switching reliability** (System Events needs MC shortcuts enabled, Secure
   Keyboard Entry can block it) → robust onboarding that verifies setup; clear
   error states; fall back to the switcher palette.
3. **Permissions friction** (Accessibility/Automation) → first-run guided flow,
   re-check on activation (TCC caches go stale after OS updates).
4. **Notarization needs $99/yr account** → unavoidable; document the unsigned
   "Open Anyway" path for users who build from source.
5. **Apple ships native naming someday** → unlikely near-term; our switcher/hotkey
   value persists regardless.

---

## 9. Open questions to validate early

- Exact `SLSSpaceGetType` numeric values + which SkyLight symbols are no-op'd on
  the current macOS build (probe on-device in Phase 1).
- How smooth move-window-cross-space can be without SIP (spike in Phase 4).
- Whether SpaceJump's undisclosed no-SIP in-Mission-Control naming is replicable
  (deferred research; explicitly out of v1 scope).

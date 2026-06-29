# Releasing Spacey

This is the maintainer guide for cutting a signed, notarized Spacey release. It
covers the one-time setup (Apple credentials + GitHub secrets) and the
per-release steps.

Spacey is distributed as a **notarized direct download** — there is no Mac App
Store build (the app is non-sandboxed by design). Releases are produced entirely
by the tag-gated GitHub Actions workflow at
[`.github/workflows/release.yml`](../.github/workflows/release.yml), which builds,
codesigns with a Developer ID identity, notarizes, staples, packages a DMG (via
[`scripts/make-dmg.sh`](../scripts/make-dmg.sh)), and publishes a GitHub Release
with the DMG attached.

The in-app updater ([`Sources/Spacey/Settings/UpdateChecker.swift`](../Sources/Spacey/Settings/UpdateChecker.swift))
polls the GitHub **latest release** API and offers the first `.dmg`/`.zip`/`.pkg`
asset for download — so the DMG attached by the workflow is what existing users
are upgraded to.

---

## 1. Prerequisites (one time)

You need a **paid Apple Developer Program** membership ($99/yr). There is no free
path to a Gatekeeper-clean download — macOS 15 removed the Control-click bypass,
so unsigned/un-notarized builds show a hard "damaged / cannot be opened" wall.

You will create two Apple credentials:

### a. Developer ID Application certificate

This is the code-signing identity. Create it from
**Apple Developer → Certificates, IDs & Profiles → Certificates → +**, choose
**Developer ID Application**, and follow the CSR flow (or let Xcode manage it via
**Settings → Accounts → Manage Certificates → + → Developer ID Application**).

Then export it **with its private key** as a `.p12`:

1. Open **Keychain Access → login → My Certificates**.
2. Find **Developer ID Application: Your Name (TEAMID)** and expand it so the
   private key is included.
3. Right-click → **Export…** → format **Personal Information Exchange (.p12)**.
4. Set a password — this becomes the `DEVELOPER_ID_P12_PASSWORD` secret.

### b. App Store Connect API key (for notarization)

`notarytool` authenticates with an App Store Connect API key (the old `altool`
password flow is dead). Create one at
**App Store Connect → Users and Access → Integrations → App Store Connect API**:

1. Generate a key with the **Developer** role (sufficient for notarization).
2. Download the `.p8` file — **you can only download it once**.
3. Note the **Key ID** and the **Issuer ID** shown on that page.

These map to `AC_API_KEY_BASE64` (the `.p8`), `AC_API_KEY_ID`, and
`AC_API_ISSUER_ID`.

---

## 2. Configure GitHub secrets (one time)

Add each of the following under **repo → Settings → Secrets and variables →
Actions → New repository secret**. The values are never printed by the workflow
and the temporary signing keychain is deleted at the end of every run.

| Secret | What it is | How to produce the value |
| --- | --- | --- |
| `DEVELOPER_ID_P12_BASE64` | Developer ID Application cert + private key | `base64 -i DeveloperID.p12 \| pbcopy` |
| `DEVELOPER_ID_P12_PASSWORD` | password you set when exporting the `.p12` | the password itself |
| `KEYCHAIN_PASSWORD` | throwaway password for the temporary CI keychain | any random string, e.g. `openssl rand -base64 24` |
| `AC_API_KEY_ID` | App Store Connect API **Key ID** | copy from the API key page |
| `AC_API_ISSUER_ID` | App Store Connect API **Issuer ID** | copy from the API key page |
| `AC_API_KEY_BASE64` | the App Store Connect `.p8` key | `base64 -i AuthKey_XXXX.p8 \| pbcopy` |

Notes:

- On macOS, `base64 -i FILE` encodes a file; piping to `pbcopy` copies it to the
  clipboard so you can paste it straight into the secret field. (On Linux use
  `base64 -w0 FILE`.)
- Store the original `.p12` and `.p8` files somewhere safe offline. They are
  gitignored (`*.p12`, `*.cer`, etc.) and must **never** be committed.
- Rotating a credential = re-encode and update the corresponding secret. No code
  change is needed.

---

## 3. Cut a release

The workflow is triggered **only by pushing a tag matching `v*`** — never by a
branch push or a pull request. This is the security boundary: forked-PR
workflows cannot read these secrets, and PRs cannot create tags on the base
repo, so only a maintainer pushing a tag can sign a build.

1. **Bump the version** in [`project.yml`](../project.yml). Edit
   `settings.base.MARKETING_VERSION` (this becomes `CFBundleShortVersionString`,
   which the DMG name and the in-app updater compare against). Bump
   `CURRENT_PROJECT_VERSION` too if you track build numbers. Commit to `main`:

   ```sh
   git commit -am "release: 0.2.0"
   git push origin main
   ```

2. **Tag and push the tag.** The tag must be `v` + the marketing version:

   ```sh
   git tag v0.2.0
   git push origin v0.2.0
   ```

3. The **Release** workflow runs automatically. It will:
   - generate the Xcode project (`xcodegen generate`) and build Release;
   - import the Developer ID cert into a temporary keychain;
   - codesign the app (Developer ID, hardened runtime, the existing
     [`Spacey.entitlements`](../Sources/Spacey/Spacey.entitlements));
   - notarize with `notarytool submit --wait` and staple;
   - build `Spacey-<version>.dmg` via `scripts/make-dmg.sh`;
   - codesign, notarize, and staple the DMG too;
   - create the GitHub Release for the tag and upload the DMG as an asset;
   - delete the temporary keychain and decoded key material.

4. **Verify** on the Releases page: the new release exists, marked "Latest", with
   `Spacey-<version>.dmg` attached.

If the workflow fails, no release is published (it is not created until the final
step) — fix the issue, delete the tag if needed (`git push --delete origin
v0.2.0` and `git tag -d v0.2.0`), and re-tag.

---

## 4. How notarization works (brief)

Notarization is Apple's **automated malware scan** — not App Review. Spacey's use
of private SkyLight/CGS symbols does **not** block it (AltTab ships notarized
using the same APIs). The flow the workflow performs:

1. **Codesign** the app with a Developer ID identity, the hardened runtime
   (`--options runtime`), a secure timestamp, and the app's entitlements.
2. **Submit** an archive of the app to Apple via `notarytool` and wait for the
   scan to pass.
3. **Staple** the resulting ticket into the bundle (and into the DMG) so
   Gatekeeper can verify it offline, with no network round-trip on first launch.

A notarized + stapled DMG opens cleanly on any Mac with no warnings.

---

## 5. What users see after a release

Existing users: the in-app **Updates** pane (and the launch-time auto-check, on
by default) polls the GitHub latest-release API, compares the tag to the running
build, and — when newer — surfaces a download link to the DMG asset. There is no
auto-install; Spacey hands the user the link, in keeping with its zero-dependency
philosophy (no Sparkle).

New users: download the DMG from the Releases page, drag Spacey to Applications.

---

## 6. Unsigned "build from source" fallback

Users who don't want the notarized build (or are on a fork) can build from
source. Such a build is **not** notarized, so macOS will refuse to open it
normally. The documented bypass:

- Build locally (see the README / [`scripts/install-and-refresh-icon.sh`](../scripts/install-and-refresh-icon.sh),
  which installs a locally re-signed copy), **or**
- For a downloaded-but-unsigned build: **System Settings → Privacy & Security**,
  scroll to the "… was blocked" message, and click **Open Anyway** (then confirm
  on the next launch). On older macOS the equivalent is Control-click → Open.

This path is for source builders only; the official, recommended distribution is
the notarized DMG produced by the release workflow.

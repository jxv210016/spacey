# Releasing Spacey

Maintainer guide for cutting a release. Spacey ships as an **unsigned `.zip`** — no
paid Apple Developer account, no code-signing, no notarization, **no GitHub secrets**.
Cutting a release is just pushing a tag.

## Cut a release

1. Bump the version in [`project.yml`](../project.yml) (`MARKETING_VERSION`), commit,
   and push to `main`.
2. Tag and push:
   ```bash
   git tag v0.1.0          # match MARKETING_VERSION
   git push origin v0.1.0
   ```
3. The tag-gated [`release.yml`](../.github/workflows/release.yml) workflow runs on a
   macOS runner: it generates the project, builds Release (unsigned), zips the app to
   a fixed-name `Spacey.zip`, and creates a GitHub Release for the tag with that zip
   attached + auto-generated notes.

That's it — no secrets to configure.

## How users install

Because the build is unsigned, Gatekeeper quarantines a downloaded copy until the
quarantine attribute is cleared:

```bash
curl -L -o Spacey.zip https://github.com/jxv210016/spacey/releases/latest/download/Spacey.zip
unzip -o Spacey.zip -d /Applications
xattr -dr com.apple.quarantine /Applications/Spacey.app
open /Applications/Spacey.app
```

The fixed `Spacey.zip` asset name keeps the `releases/latest/download/Spacey.zip` URL
stable across versions. The in-app **UpdateChecker** polls the GitHub "latest release"
API, compares the tag to the running build, and links users to this asset when a newer
version exists (it never auto-installs).

## If you later want a signed, Gatekeeper-clean build

Signing + notarization (so users skip the `xattr` step) needs the paid Apple Developer
Program: a *Developer ID Application* certificate and an App Store Connect API key,
wired into the release workflow as secrets. That's intentionally out of scope here —
the zip flow above keeps releases free and secret-free.

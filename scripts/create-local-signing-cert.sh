#!/usr/bin/env bash
#
# create-local-signing-cert.sh
# ---------------------------------------------------------------------------
# Creates a *self-signed* code-signing certificate named "Spacey Local Signing"
# in your login keychain, then install-and-refresh-icon.sh will sign the
# installed app with it automatically.
#
# WHY: signing with a real, stable identity is what lets macOS/TCC keep the
# Accessibility grant across reinstalls (an ad-hoc signature changes every build,
# so the permission is dropped each time). An Apple-issued cert (Apple
# Development / Developer ID) would do this too, but it embeds your real name in
# the signature, which is public in the app bundle. A self-signed cert gives the
# same stability with a generic name and no personal information.
#
# TRADE-OFF: a self-signed cert is fine for THIS Mac, but it is "not trusted" by
# other machines, so the app is NOT distributable this way (Gatekeeper will block
# downloaders). For distribution, use a Developer ID Application cert + notarize.
#
# Safe to re-run: it removes any prior "Spacey Local Signing" identity first so
# you don't accumulate duplicates (which would make codesign's identity
# ambiguous).
# ---------------------------------------------------------------------------

set -euo pipefail

CN="Spacey Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
P12_PASS="spacey"   # transient; only used to move the key into the keychain

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT   # never leave the private key on disk

echo "==> Removing any existing '$CN' identity (avoid duplicates)…"
# Delete by certificate common name; ignore if none exists.
security delete-identity -c "$CN" "$KEYCHAIN" 2>/dev/null || true
security delete-certificate -c "$CN" "$KEYCHAIN" 2>/dev/null || true

echo "==> Generating self-signed code-signing certificate…"
openssl req -x509 -newkey rsa:2048 -keyout "$WORK/key.pem" -out "$WORK/cert.pem" \
  -days 3650 -nodes \
  -subj "/CN=${CN}" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" \
  -addext "basicConstraints=critical,CA:false" >/dev/null 2>&1

# `-legacy` so the PKCS#12 uses algorithms Apple's Security framework can import.
openssl pkcs12 -export -legacy -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
  -out "$WORK/cert.p12" -passout "pass:${P12_PASS}" -name "$CN" >/dev/null 2>&1

echo "==> Importing into the login keychain (pre-authorizing codesign)…"
security import "$WORK/cert.p12" -k "$KEYCHAIN" -P "$P12_PASS" -T /usr/bin/codesign

echo
echo "Done. Self-signed identity installed:"
# Listed WITHOUT -v because a self-signed cert is "not trusted" and -v hides it.
security find-identity -p codesigning | grep "$CN" || true
echo
echo "Now run:  bash scripts/install-and-refresh-icon.sh"
echo "It will sign the installed app as '$CN' (no personal name, stable identity)."
echo "You'll re-grant Accessibility once more (the identity changed); after that"
echo "future reinstalls keep the grant."

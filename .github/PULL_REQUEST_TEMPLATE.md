<!-- Thanks for contributing to Spacey! -->

## Summary

<!-- What does this PR change, and why? -->

## Linked issue

<!-- e.g. Fixes #123 -->

## Testing done

<!-- How did you verify this change? Manual steps, new/updated tests, etc. -->

## Checklist

- [ ] Builds: `xcodebuild build -scheme Spacey -configuration Release -destination 'platform=macOS'`
- [ ] `swiftlint --strict` is clean (zero warnings)
- [ ] `swiftformat --lint .` is clean
- [ ] Tests pass: `xcodebuild test -scheme Spacey -destination 'platform=macOS'`
- [ ] No new external (SwiftPM) dependencies
- [ ] Follows the no-SIP design (no SIP disable, no Dock/system-process injection)
- [ ] Updated docs/tests where relevant

# Personal TestFlight builds (this fork)

This fork carries the mobile dictation work (language selection, Apple
`DictationTranscriber` fallback, NVIDIA Parakeet on-device) and can be signed
with your own Apple Developer team, so you can install it from TestFlight
whether or not the upstream PRs land.

Upstream's bundle ID (`com.hardbeat920.monocode-mobile`) and EAS project belong
to the upstream maintainer, so a personal build uses your own bundle ID.
`app.config.js` swaps the identifiers from environment variables; with none
set the config is exactly `app.json`'s.

| Variable | Example | Used for |
| --- | --- | --- |
| `MONOCODE_BUNDLE_ID` | `com.you.monocode` | bundle identifier |
| `MONOCODE_APPLE_TEAM_ID` | `ABCDE12345` | signing team |
| `MONOCODE_BUILD_NUMBER` | `202611210930` | `CFBundleVersion`, must grow with each upload |
| `MONOCODE_EAS_OWNER`, `MONOCODE_EAS_PROJECT_ID` | | only for EAS builds/updates |

Without your own EAS project, over-the-air updates are disabled in personal
builds (upstream's update server can't serve another app).

## One-time setup

1. In [App Store Connect](https://appstoreconnect.apple.com/apps) choose
   **+ → New App**, platform iOS, and register your bundle ID (for example
   `com.you.monocode`). Xcode registers the identifier and the push
   capability automatically when it signs the first build.
2. Pick a build route below.

## Build on this Mac (Xcode signed in to your account)

Needs Xcode (27.1+ recommended), Node 24, CocoaPods, and Rust (`brew install
cocoapods rustup && rustup default stable`).

```bash
cd mobile
MONOCODE_BUNDLE_ID=com.you.monocode \
MONOCODE_APPLE_TEAM_ID=ABCDE12345 \
scripts/testflight.sh
```

With an Xcode older than 27.1 (no iOS 27.1 SDK) the script builds without
fold-to-type on iPhone Duo (`UIHingeInteraction`), which is the only part
that needs 27.1; everything else, dictation included, is unaffected.

The script builds the Rust transport, runs `expo prebuild`, archives a Release
build signed by the team (automatic signing via the Apple account in Xcode →
Settings → Accounts), and uploads it to TestFlight. `SKIP_UPLOAD=1` only exports
the `.ipa` to `mobile/build/testflight/export/`. To sign with an App Store
Connect API key instead of the Xcode account, also set `ASC_KEY_PATH`,
`ASC_KEY_ID` and `ASC_ISSUER_ID`.

## Build on GitHub Actions

The **Mobile TestFlight (personal)** workflow (`.github/workflows/mobile-testflight.yml`)
runs the same script on a macOS runner. In the fork's **Settings → Secrets and
variables → Actions**:

- Variables: `MONOCODE_BUNDLE_ID`, `MONOCODE_APPLE_TEAM_ID`
- Secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (the `.p8` file's
  contents) for an App Store Connect API key with the **Admin** role, so Xcode
  can create the distribution certificate and profile in the cloud.

Then **Actions → Mobile TestFlight (personal) → Run workflow**. Build numbers
are `3` followed by the run number.

## Build with EAS

```bash
cd mobile
npx eas-cli@latest login
MONOCODE_BUNDLE_ID=com.you.monocode MONOCODE_EAS_OWNER=your-expo-name \
  npx eas-cli@latest init   # prints the new project ID
MONOCODE_BUNDLE_ID=com.you.monocode MONOCODE_EAS_OWNER=your-expo-name \
MONOCODE_EAS_PROJECT_ID=<id> \
  npx eas-cli@latest build --platform ios --profile production --auto-submit
```

EAS asks for your Apple ID once and manages the certificates.

## Keeping up with upstream

```bash
git fetch origin            # origin = hardbeat920/monocode
git checkout personal
git merge origin/main
```

#!/usr/bin/env bash
# Builds MonoCode signed with your own Apple Developer team and uploads it to
# TestFlight, on this Mac with Xcode. See PERSONAL_BUILDS.md.
#
# Required:
#   MONOCODE_BUNDLE_ID       e.g. com.you.monocode (an App Store Connect app with it must exist)
#   MONOCODE_APPLE_TEAM_ID   your 10-character team ID
# Optional:
#   MONOCODE_BUILD_NUMBER    defaults to the current date and time (YYYYMMDDHHMM)
#   ASC_KEY_PATH, ASC_KEY_ID, ASC_ISSUER_ID
#                            an App Store Connect API key; without one the Apple
#                            account signed in to Xcode is used
#   SKIP_UPLOAD=1            stop after exporting the .ipa
set -euo pipefail

: "${MONOCODE_BUNDLE_ID:?Set MONOCODE_BUNDLE_ID, e.g. com.you.monocode}"
: "${MONOCODE_APPLE_TEAM_ID:?Set MONOCODE_APPLE_TEAM_ID to your Apple Developer team ID}"
export MONOCODE_BUNDLE_ID MONOCODE_APPLE_TEAM_ID
export MONOCODE_BUILD_NUMBER="${MONOCODE_BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"

mobile="$(cd "$(dirname "$0")/.." && pwd)"
cd "$mobile"
out="$mobile/build/testflight"
rm -rf "$out"
mkdir -p "$out"

auth=()
if [[ -n "${ASC_KEY_PATH:-}" ]]; then
  : "${ASC_KEY_ID:?Set ASC_KEY_ID with ASC_KEY_PATH}"
  : "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID with ASC_KEY_PATH}"
  auth=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

echo "› Building $MONOCODE_BUNDLE_ID ($MONOCODE_BUILD_NUMBER) for team $MONOCODE_APPLE_TEAM_ID"
[[ -d node_modules ]] || npm ci
node scripts/build-native-link.mjs ios --device-only
# Fold-to-type needs the iOS 27.1 SDK; on an older Xcode it is left out
# (read by modules/monocode-link/ios/MonocodeLink.podspec at pod install).
sdk="$(xcrun --sdk iphoneos --show-sdk-version)"
if [[ "$(printf '%s\n27.1\n' "$sdk" | sort -V | head -1)" != 27.1 ]]; then
  echo "› iOS SDK $sdk is older than 27.1: building without fold-to-type"
  export MONOCODE_NO_HINGE=1
fi
CI=1 npx expo prebuild --platform ios --clean
[[ -d ios/MonoCode.xcworkspace ]] || { echo "✗ pod install failed (see above)"; exit 1; }

xcodebuild \
  -workspace ios/MonoCode.xcworkspace \
  -scheme MonoCode \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath "$out/MonoCode.xcarchive" \
  -allowProvisioningUpdates ${auth[@]+"${auth[@]}"} \
  DEVELOPMENT_TEAM="$MONOCODE_APPLE_TEAM_ID" \
  archive

destination=upload
[[ "${SKIP_UPLOAD:-}" == 1 ]] && destination=export
cat > "$out/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>$destination</string>
  <key>teamID</key><string>$MONOCODE_APPLE_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>uploadSymbols</key><true/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$out/MonoCode.xcarchive" \
  -exportOptionsPlist "$out/ExportOptions.plist" \
  -exportPath "$out/export" \
  -allowProvisioningUpdates ${auth[@]+"${auth[@]}"}

if [[ "$destination" == upload ]]; then
  echo "✓ Uploaded build $MONOCODE_BUILD_NUMBER. It appears in TestFlight once App Store Connect has processed it."
else
  echo "✓ Exported $out/export/MonoCode.ipa"
fi

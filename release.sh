#!/bin/bash
# Baut die Mac-Version der Verlosung, unterschreibt sie mit der Developer ID,
# lässt sie von Apple beglaubigen und legt build/Verlosung.zip für GitHub an.
set -euo pipefail
cd "$(dirname "$0")"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
PROFILE="MacCleaner-Notar"   # gleiches Apple-Konto wie bei MacCleaner
rm -rf build/dd build/Verlosung.app build/Verlosung.zip
xcodebuild -project Verlosung.xcodeproj -scheme Verlosung -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath build/dd \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Developer ID Application" DEVELOPMENT_TEAM=83WCHDLBXB PROVISIONING_PROFILE_SPECIFIER= \
  ENABLE_HARDENED_RUNTIME=YES CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO OTHER_CODE_SIGN_FLAGS=--timestamp -quiet build
cp -R build/dd/Build/Products/Release/Verlosung.app build/
codesign -dv build/Verlosung.app 2>&1 | grep -E "Authority=Developer ID|TeamIdentifier"
if [[ "${1:-}" != "--no-notary" ]]; then
  echo "Wird bei Apple beglaubigt …"
  ditto -c -k --keepParent build/Verlosung.app build/notar.zip
  xcrun notarytool submit build/notar.zip --keychain-profile "$PROFILE" --wait | tee build/notar.log
  rm -f build/notar.zip
  grep -q "status: Accepted" build/notar.log || { echo "Beglaubigung fehlgeschlagen – siehe build/notar.log"; exit 1; }
  xcrun stapler staple build/Verlosung.app
  spctl -a -vv -t exec build/Verlosung.app
fi
ditto -c -k --sequesterRsrc --keepParent build/Verlosung.app build/Verlosung.zip
if [[ "${1:-}" != "--no-notary" ]]; then
  NOTARY_PROFILE="$PROFILE" ./make_dmg.sh build/Verlosung.app build/Verlosung.dmg dmg-background.png
fi
echo "Fertig: build/Verlosung.zip und build/Verlosung.dmg"

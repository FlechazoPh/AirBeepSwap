#!/bin/bash
# AirBeepSwap — maintained by Poner7.
# https://github.com/poner7/AirBeepSwap
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUTPUT_DIR="$ROOT/build/unsigned"
ARCHIVE_PATH="$OUTPUT_DIR/airbeepswap.xcarchive"
VERSION=$(sed -n 's/.*MARKETING_VERSION = \([^;]*\);/\1/p' airbeepswap.xcodeproj/project.pbxproj | head -n 1)
test -n "$VERSION"

bash scripts/test-system-compatibility.sh
bash scripts/test-local-tunnel.sh
bash scripts/verify-airlift.sh
xcodebuild archive \
  -project airbeepswap.xcodeproj \
  -scheme airbeepswap \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$ROOT/build/DerivedData" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

APP_PATH="$ARCHIVE_PATH/Products/Applications/airbeepswap.app"
bash scripts/verify-airlift.sh "$APP_PATH" "$VERSION"
python3 scripts/verify-local-tunnel.py "$APP_PATH"
mkdir -p "$OUTPUT_DIR/Payload"
rm -rf "$OUTPUT_DIR/Payload/airbeepswap.app"
cp -R "$APP_PATH" "$OUTPUT_DIR/Payload/"
IPA_PATH="$OUTPUT_DIR/airbeepswap-v$VERSION-unsigned.ipa"
rm -f "$IPA_PATH"
(
  cd "$OUTPUT_DIR"
  zip -qry "$IPA_PATH" Payload
)
echo "Unsigned IPA: $IPA_PATH"

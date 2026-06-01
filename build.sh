#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-MultiClips}"
SCHEME_NAME="${2:-MultiClips}"
PROJECT_FILE="${3:-MultiClips.xcodeproj}"
BUILD_ROOT="${4:-build}"
SIGN_MODE="${5:-unsigned}"

DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
RELEASE_APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/$APP_NAME.app"
DMG_STAGING_PATH="$BUILD_ROOT/dmg-staging"
DMG_OUTPUT_PATH="$BUILD_ROOT/$APP_NAME-local.dmg"

if [[ ! -f "$PROJECT_FILE/project.pbxproj" ]]; then
  echo "Project file '$PROJECT_FILE' was not found."
  echo "Usage: ./scripts/build_dmg.sh [AppName] [SchemeName] [ProjectFile] [BuildRoot] [unsigned|signed]"
  exit 1
fi

if [[ "$SIGN_MODE" != "unsigned" && "$SIGN_MODE" != "signed" ]]; then
  echo "Invalid sign mode '$SIGN_MODE'. Use 'unsigned' or 'signed'."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required but not found."
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "hdiutil is required but not found."
  exit 1
fi

echo "Building Release app using scheme '$SCHEME_NAME'..."
if [[ "$SIGN_MODE" == "unsigned" ]]; then
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    clean build
else
  xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    clean build
fi

if [[ ! -d "$RELEASE_APP_PATH" ]]; then
  echo "Expected app bundle not found at: $RELEASE_APP_PATH"
  exit 1
fi

echo "Preparing DMG staging folder..."
rm -rf "$DMG_STAGING_PATH"
mkdir -p "$DMG_STAGING_PATH"
cp -R "$RELEASE_APP_PATH" "$DMG_STAGING_PATH/"
ln -s /Applications "$DMG_STAGING_PATH/Applications"

echo "Creating DMG at: $DMG_OUTPUT_PATH"
rm -f "$DMG_OUTPUT_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_PATH" \
  -ov \
  -format UDZO \
  "$DMG_OUTPUT_PATH"

echo "DMG build complete."
echo "Output: $DMG_OUTPUT_PATH"

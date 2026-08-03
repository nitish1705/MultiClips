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

PBXPROJ_PATH="$PROJECT_FILE/project.pbxproj"

if [[ ! -f "$PBXPROJ_PATH" ]]; then
  echo "Project file '$PROJECT_FILE' was not found."
  echo "Usage: ./build.sh [AppName] [SchemeName] [ProjectFile] [BuildRoot] [unsigned|signed]"
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

if ! command -v codesign >/dev/null 2>&1; then
  echo "codesign is required but not found."
  exit 1
fi

# --- Step 1: Auto-Increment Build Counter in project.pbxproj ---
OLD_BUILD=$(grep -m 1 "CURRENT_PROJECT_VERSION" "$PBXPROJ_PATH" | tr -cd '0-9' || echo "1")
if [[ -z "$OLD_BUILD" ]]; then
  OLD_BUILD=1
fi
NEW_BUILD=$((OLD_BUILD + 1))

MARKETING_VER=$(grep -m 1 "MARKETING_VERSION" "$PBXPROJ_PATH" | cut -d'=' -f2 | tr -d ' ;"' || echo "2.0.0")

echo "=========================================="
echo "Bumping Build Number: Build $OLD_BUILD -> Build $NEW_BUILD"
echo "Marketing Version: v$MARKETING_VER"
echo "=========================================="

sed -i '' "s/CURRENT_PROJECT_VERSION = $OLD_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PBXPROJ_PATH"

# --- Step 2: Build Release Binary ---
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

# --- Step 3: Ad-Hoc Sign the App Bundle ---
# CODE_SIGNING_ALLOWED=NO leaves only a linker-signed signature that seals the
# binary but no bundle resources. Gatekeeper reads that as an invalid signature
# and reports "MultiClips is damaged" once the download picks up quarantine.
# Signing properly writes Contents/_CodeSignature and downgrades that to the
# ordinary "unidentified developer" prompt users can approve.
if [[ "$SIGN_MODE" == "unsigned" ]]; then
  echo "Ad-hoc signing app bundle..."
  codesign --force --deep --sign - "$RELEASE_APP_PATH"
fi

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$RELEASE_APP_PATH"

# --- Step 4: Package DMG ---
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

# --- Step 5: Package Release Zip for In-App Auto-Updater ---
ZIP_NAMED_PATH="$BUILD_ROOT/${APP_NAME}-v${MARKETING_VER}-b${NEW_BUILD}.app.zip"
ZIP_GENERIC_PATH="$BUILD_ROOT/${APP_NAME}.app.zip"

echo "Creating Release Zip for Auto-Updater..."
rm -f "$ZIP_NAMED_PATH" "$ZIP_GENERIC_PATH"
ditto -c -k --sequesterRsrc --keepParent "$RELEASE_APP_PATH" "$ZIP_GENERIC_PATH"
cp "$ZIP_GENERIC_PATH" "$ZIP_NAMED_PATH"

echo "=========================================="
echo "🎉 Build Complete! (Build #$NEW_BUILD)"
echo "DMG Output:   $DMG_OUTPUT_PATH"
echo "ZIP Output:   $ZIP_GENERIC_PATH"
echo "Named Zip:    $ZIP_NAMED_PATH"
echo "=========================================="

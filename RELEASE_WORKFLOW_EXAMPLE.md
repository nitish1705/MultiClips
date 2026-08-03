# 🚀 MultiClips Release Workflow - Step-by-Step Examples

## 📦 Scenario 1: Hotfix Release (Same Version, Bug Fix)

You've fixed a bug and want to push a quick update without bumping the version.

### Current State
- App Version: `v2.0 (Build 2)`
- Bug fixed: Clipboard history not refreshing

### Steps

```bash
# 1. Build the release (auto-increments build: 2 → 3)
cd "/Users/nitishm/Desktop/FILES/Apps (Xcode)/MultiClips/MultiClips"
./build.sh

# Output:
# ==========================================
# Bumping Build Number: Build 2 -> Build 3
# Marketing Version: v2.0
# ==========================================
# 🎉 Build Complete! (Build #3)
# ZIP Output: build/MultiClips.app.zip
# Named Zip: build/MultiClips-v2.0-b3.app.zip

# 2. Commit the build number increment
git add MultiClips.xcodeproj/project.pbxproj
git commit -m "Release v2.0 Build 3 - Fix clipboard refresh bug"
git push origin main

# 3. Create GitHub Release
gh release create v2.0-b3 \
  --title "MultiClips v2.0 Build 3" \
  --notes "**Bug Fixes**
- Fixed clipboard history not refreshing after wake from sleep
- Improved memory management for large image clips

Build: 3" \
  build/MultiClips.app.zip \
  build/MultiClips-local.dmg
```

### Result
- GitHub tag: `v2.0-b3`
- Users on `v2.0 Build 2` will see: "Update available: v2.0 (Build 3)"
- Users on `v2.0 Build 3` will see: "Up to date"

---

## 🎨 Scenario 2: Feature Release (Version Bump)

You've added new features and want to release as v2.1.

### Current State
- App Version: `v2.0 (Build 3)`
- New features: Dark mode improvements, keyboard shortcuts

### Steps

```bash
# 1. Update the marketing version in Xcode project
# Edit MultiClips.xcodeproj/project.pbxproj
# Find: MARKETING_VERSION = 2.0;
# Replace with: MARKETING_VERSION = 2.1;

# Or use sed:
sed -i '' 's/MARKETING_VERSION = 2.0;/MARKETING_VERSION = 2.1;/g' \
  MultiClips.xcodeproj/project.pbxproj

# 2. Build the release (Build counter continues: 3 → 4)
./build.sh

# Output:
# Bumping Build Number: Build 3 -> Build 4
# Marketing Version: v2.1
# ZIP Output: build/MultiClips-v2.1-b4.app.zip

# 3. Commit changes
git add .
git commit -m "Release v2.1.0 Build 4 - Dark mode improvements & keyboard shortcuts"
git push origin main

# 4. Create GitHub Release
gh release create v2.1.0 \
  --title "MultiClips v2.1.0" \
  --notes "## ✨ What's New

### 🌙 Dark Mode Improvements
- Enhanced contrast for better readability
- Smoother transitions between light/dark modes

### ⌨️ Keyboard Shortcuts
- \`⌘ + K\` - Quick search
- \`⌘ + ⇧ + C\` - Clear history
- \`⌘ + P\` - Pin/unpin clip

### 🐛 Bug Fixes
- Fixed clipboard refresh issue
- Improved performance with large image clips

Build: 4" \
  build/MultiClips.app.zip \
  build/MultiClips-local.dmg
```

### Alternative: Simple Tag (Build defaults to 1)

If you want the release to show as "Build 1" instead of "Build 4":

```bash
# Create release WITHOUT build suffix
gh release create v2.1.0 \
  --title "MultiClips v2.1.0" \
  --notes "Release notes here..." \
  build/MultiClips.app.zip
```

Users will see: `v2.1.0 (Build 1)`

---

## 🔥 Scenario 3: Multiple Patches on Same Version

You release several hotfixes in quick succession.

### Timeline

```bash
# Monday: Initial v2.0 release
# Build 1 → v2.0-b1

# Tuesday: Hotfix #1
./build.sh  # Creates Build 2
git commit -m "v2.0 Build 2 - Fix memory leak"
gh release create v2.0-b2 ... 

# Wednesday: Hotfix #2
./build.sh  # Creates Build 3
git commit -m "v2.0 Build 3 - Fix crash on startup"
gh release create v2.0-b3 ...

# Thursday: Hotfix #3
./build.sh  # Creates Build 4
git commit -m "v2.0 Build 4 - Fix image preview"
gh release create v2.0-b4 ...
```

### Update Detection

| User's Version | Latest Release | Update Shown? |
|----------------|----------------|---------------|
| v2.0 Build 1 | v2.0 Build 4 | ✅ YES |
| v2.0 Build 2 | v2.0 Build 4 | ✅ YES |
| v2.0 Build 3 | v2.0 Build 4 | ✅ YES |
| v2.0 Build 4 | v2.0 Build 4 | ❌ NO (up to date) |

---

## 🎯 Scenario 4: Using Release Body for Build Number

You prefer simple tags like `v2.1.0` but still want build tracking.

### Steps

```bash
# 1. Build release
./build.sh  # Creates Build 5

# 2. Create release with build in description
gh release create v2.1.0 \
  --title "MultiClips v2.1.0" \
  --notes "## Release Notes

New features and improvements.

**Build Number: 5**

## Changes
- Feature A
- Feature B" \
  build/MultiClips.app.zip
```

The updater will parse "Build Number: 5" from the release body!

### Supported Body Formats

All of these work:
```
Build: 5
Build Number: 5
Build Num: 5
build: 5
BUILD NUMBER: 5
```

---

## 🧪 Testing Before Release

Always test the update detection logic before publishing:

```bash
# Run the test suite
swift test_update_logic.swift

# Expected output:
# ✅ Total Tests: 13
# ✅ Passed: 13
# ❌ Failed: 0

# Build and test locally
./build.sh
open build/MultiClips.app  # Test the built app
```

---

## 📋 Pre-Release Checklist

Before creating a GitHub release:

- [ ] Run `./build.sh` successfully
- [ ] Verify build number incremented correctly
- [ ] Test the built app: `open build/MultiClips.app`
- [ ] Commit and push the build number change
- [ ] Choose appropriate tag format:
  - Patch: `v2.0-b3` or `v2.0+3`
  - Feature: `v2.1.0` or `v2.1.0-b1`
  - Major: `v3.0.0`
- [ ] Include "Build: X" in release notes if using simple tag
- [ ] Upload `MultiClips.app.zip` (required for auto-updater)
- [ ] Upload `MultiClips-local.dmg` (optional, for manual installs)

---

## 🎉 What Happens When Users Update

1. **User launches MultiClips** → Auto-check runs in background
2. **Update detected** → Banner appears: "MultiClips v2.1 (Build 4) is available"
3. **User clicks "Update & Relaunch"**:
   - Downloads `MultiClips.app.zip` to `/tmp/`
   - Extracts app bundle
   - Spawns relaunch script
   - Replaces `/Applications/MultiClips.app`
   - Launches updated app
4. **User sees** → "MultiClips is up to date (v2.1 Build 4)"

---

## 🔧 Troubleshooting

### Users Not Seeing Update

Check these:

1. **GitHub Release Assets**: Must include `MultiClips.app.zip`
2. **Tag Format**: Should be `v2.0-b3` or `v2.0.0` (not `2.0` or `MultiClips-v2.0`)
3. **Build Number**: If tag is `v2.0`, add "Build: 3" to release body
4. **Version Comparison**: Remote version must be > local version OR same version with higher build

### Build Number Not Incrementing

```bash
# Check current build
grep "CURRENT_PROJECT_VERSION" MultiClips.xcodeproj/project.pbxproj

# Should show: CURRENT_PROJECT_VERSION = X;

# If stuck, manually fix:
sed -i '' 's/CURRENT_PROJECT_VERSION = 2;/CURRENT_PROJECT_VERSION = 3;/g' \
  MultiClips.xcodeproj/project.pbxproj
```

### Test Update Detection

```bash
# Simulate different scenarios with the test script
# Edit test_update_logic.swift and change:
let currentLocal = AppVersionInfo(
    versionComponents: [2, 0, 0],
    buildNumber: 2,  // <-- Change this
    rawVersionString: "2.0"
)

swift test_update_logic.swift
```

---

## 📚 Additional Resources

- [UPDATER_GUIDE.md](UPDATER_GUIDE.md) - Complete technical documentation
- [UPDATE_SYSTEM_SUMMARY.md](UPDATE_SYSTEM_SUMMARY.md) - Implementation details
- [test_update_logic.swift](test_update_logic.swift) - Automated test suite

---

**Next Release**: Just run `./build.sh` and follow the checklist! 🚀

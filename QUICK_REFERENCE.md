# 🚀 MultiClips Release - Quick Reference Card

## ⚡ TL;DR

```bash
# Build release
./build.sh

# Commit
git add . && git commit -m "Release v2.0 Build 3" && git push

# Upload to GitHub
gh release create v2.0-b3 --title "v2.0 Build 3" --notes "Bug fixes" \
  build/MultiClips.app.zip build/MultiClips-local.dmg

# DONE! Users auto-update.
```

---

## 📝 Cheat Sheet

### Current Version
- Marketing: `2.0`
- Build: `2`
- Display: `v2.0 (Build 2)`

### Next Build
```bash
./build.sh  # Creates v2.0 Build 3
```

### Tag Formats (All Work)
```
v2.0-b3       ✅ Recommended
v2.0+3        ✅ Alternative
v2.0.0-b3     ✅ Full semver
v2.0          ✅ Defaults to Build 1
```

### Required Files
```
✅ MultiClips.app.zip  (REQUIRED - auto-updater)
✅ MultiClips-local.dmg (optional - new users)
```

---

## 🎯 When to Bump Version vs Build

### Bump Build Number (Patches/Hotfixes)
```bash
# Just run build.sh - it auto-increments
./build.sh
# v2.0 Build 2 → v2.0 Build 3
```

### Bump Version (Features/Breaking Changes)
```bash
# 1. Update MARKETING_VERSION in project.pbxproj
sed -i '' 's/MARKETING_VERSION = 2.0;/MARKETING_VERSION = 2.1;/g' \
  MultiClips.xcodeproj/project.pbxproj

# 2. Build
./build.sh
# v2.0 Build 3 → v2.1 Build 4
```

---

## ✅ Pre-Release Checklist

- [ ] Run `./build.sh` successfully
- [ ] Test: `open build/MultiClips.app`
- [ ] Verify build incremented
- [ ] Commit: `git add . && git commit && git push`
- [ ] Create GitHub release with tag
- [ ] Upload `MultiClips.app.zip` ⚠️ **REQUIRED**
- [ ] Upload `MultiClips-local.dmg` (optional)
- [ ] Verify release shows on GitHub
- [ ] Test update on another machine (optional)

---

## 🧪 Testing

```bash
# Run test suite
swift test_update_logic.swift

# Check current GitHub release
curl -s https://api.github.com/repos/nitish1705/MultiClips/releases/latest \
  | jq '{tag_name, assets: [.assets[].name]}'

# Verify build number in project
grep CURRENT_PROJECT_VERSION MultiClips.xcodeproj/project.pbxproj | head -1
```

---

## 🔍 Update Detection Logic

```
User has: v2.0 Build 2

Remote v2.1.0 Build 1  →  ✅ UPDATE (version higher)
Remote v2.0.0 Build 3  →  ✅ UPDATE (build higher)
Remote v2.0.0 Build 2  →  ❌ NO UPDATE (same)
Remote v2.0.0 Build 1  →  ❌ NO UPDATE (older build)
Remote v1.9.0 Build 99 →  ❌ NO UPDATE (older version)
```

---

## 🐛 Troubleshooting

### Users not seeing update?
1. Check GitHub release has `MultiClips.app.zip`
2. Verify tag format: `v2.0-b3` not `2.0` or `MultiClips-2.0`
3. Check app logs in Console.app

### Build number not incrementing?
```bash
# Check current build
grep CURRENT_PROJECT_VERSION MultiClips.xcodeproj/project.pbxproj | head -1

# Manually fix if needed
sed -i '' 's/CURRENT_PROJECT_VERSION = 2;/CURRENT_PROJECT_VERSION = 3;/g' \
  MultiClips.xcodeproj/project.pbxproj
```

### App won't replace itself?
- Gatekeeper issue: Code sign your app
- Or tell users: `xattr -dr com.apple.quarantine /Applications/MultiClips.app`

---

## 📚 Full Documentation

- [UPDATER_GUIDE.md](UPDATER_GUIDE.md) - Complete technical docs
- [UPDATE_SYSTEM_SUMMARY.md](UPDATE_SYSTEM_SUMMARY.md) - Implementation details
- [HOW_AUTO_UPDATE_WORKS.md](HOW_AUTO_UPDATE_WORKS.md) - End-to-end explanation
- [RELEASE_WORKFLOW_EXAMPLE.md](RELEASE_WORKFLOW_EXAMPLE.md) - Step-by-step examples

---

## 💡 Key Points

1. ✅ Users **NEVER** manually reinstall
2. ✅ App auto-checks GitHub on launch
3. ✅ One-click update from inside the app
4. ✅ `MultiClips.app.zip` is **REQUIRED**
5. ✅ Build number auto-increments
6. ✅ Both version AND build are compared

---

## 🎉 Next Release

```bash
# Ready to release v2.0 Build 3?

./build.sh
git add . && git commit -m "Release v2.0 Build 3" && git push
gh release create v2.0-b3 \
  --title "MultiClips v2.0 Build 3" \
  --notes "- Fixed clipboard refresh bug\n- Improved performance" \
  build/MultiClips.app.zip \
  build/MultiClips-local.dmg

# Your users (v2.0 Build 2) will now see:
# "🔔 Update Available! v2.0 (Build 3)"
```

That's it! 🚀

# 📜 MultiClips Version History

## v2.3 Build 12 (Latest) - August 4, 2026

### ⚙️ Settings & Auto-Update Polish
- **Streamlined Sidebar Settings**: Removed unused General Settings row and eliminated duplicate Theme selector dropdown
- **Hourly GitHub Auto-Update Checks**: Background timer now automatically checks GitHub API for new releases every 1 hour
- **Non-Disruptive Floating Toast Overlay**: Rebuilt update banner into a sleek glassmorphic floating toast overlay with auto-dismiss after 3.5 seconds

---

## v2.2 Build 10 - August 3, 2026

### 🎨 Menu Bar Redesign
- **Hover-revealed actions**: Star and the actions button now stay hidden until a row is hovered, so the resting list is just content. A starred clip keeps its star visible at rest
- **New header**: Material bar with the clipboard glyph in a theme-tinted chip
- **Compact footer**: Two stacked icon buttons, Open and Quit, replacing three full-width rows
- **Clear History removed from the menu bar**: bulk delete now lives only in the main window sidebar, where it is gated behind a confirmation alert instead of being one unguarded click away

### 📄 Version History & Credits Redesign
- **Release cards**: Each version is now a card, with the newest carrying a Latest badge and a tinted fill
- **Two-column highlights** on wider windows, collapsing to one below 700pt
- **Readable release notes**: Bullet text is no longer drawn in the theme colour, which had made the page a wall of tinted body copy
- **Credits rebuilt**: Monogram avatar, real profile handles as subtitles, and a new "About this app" panel showing version, system requirement, storage and licence
- **Removed duplicate Quick Links**: They repeated the rows above them and always rendered system blue regardless of the selected theme

### 🐛 Bug Fixes
- **Fixed theme tint showing desktop colours through the window**: Four views faded their theme gradient to a fully transparent colour with nothing opaque underneath, so the panes were genuinely see-through. On a green-yellow wallpaper the purple theme read green. Each now fades on-hue over a solid window background

---

## v2.0 Build 6 - August 3, 2026

### 🔧 Build System Improvements
- **Ad-Hoc Code Signing**: Added proper ad-hoc signing to prevent "damaged app" errors on macOS
- **Signature Verification**: Build script now verifies app signature after signing
- **Better DMG Compatibility**: Improved DMG creation process for better compatibility across macOS versions

### 🐛 Bug Fixes
- Fixed "MultiClips is damaged" error when opening downloaded DMG
- Resolved Gatekeeper issues with unsigned builds
- Improved app bundle integrity for distribution

### 📦 Release Assets
- `MultiClips-local.dmg` - DMG installer with ad-hoc signed app (recommended for first install)
- `MultiClips.app.zip` - Direct app bundle (recommended for auto-updater and manual installs)

---

## v2.0 Build 4 - August 3, 2026

### 🔄 Auto-Updater Enhancements
- **Fixed Version Parsing**: Corrected regex pattern for parsing build numbers from GitHub tags
- **Dual-Version System**: Proper comparison of both marketing version and build numbers
- **Build Number Tracking**: Added `AppVersionInfo` struct for type-safe version handling
- **Body Parsing**: Extract build numbers from both release tags and release body

### 📚 Documentation
- Added comprehensive auto-updater documentation (5 new guides)
- Created automated test suite (13/13 tests passing)
- Added developer workflow examples
- Quick reference cheat sheet for releases

### 🎨 UI Improvements
- Display build numbers in update notifications
- Show current version as "v2.0 (Build X)" format
- Better update available messages

### 🐛 Bug Fixes
- Fixed false positive update notifications
- Corrected version comparison logic
- Resolved edge cases in version string parsing

---

## v2.0 Build 2 - August 1, 2026

### 🚀 Initial Auto-Updater Release
- Built-in automatic update system
- One-click update and relaunch
- Background update checks on launch
- Manual "Check for Updates" option
- In-app changelog preview

### ✨ Features
- Pin clips to keep them at the top
- Keyboard shortcuts for quick access
- Duplicate detection prevents clutter
- Advanced search across all clips
- Category filtering with instant search

### 🎨 UI Enhancements
- Filter buttons in All Clips view
- Improved theme gradients
- Enhanced animations and transitions
- Better dark mode support

### ⚡ Performance
- Optimized image grid rendering with caching
- Reduced memory usage for large clipboard sessions
- Faster duplicate detection

---

## v2.0.0 - March 1, 2026

### 🎉 Initial Release
- Native macOS clipboard manager built with SwiftUI
- Smart categorization (Texts, Images, Media, Documents, Files, Links)
- Live search and filtering
- Rich image support with thumbnails
- Clip notes and starring
- Menu bar integration
- Local-only storage with SwiftData
- Dark mode support

---

## Version Numbering

MultiClips uses a **dual-versioning system**:

- **Marketing Version** (e.g., `2.0`) - Major feature releases
- **Build Number** (e.g., `Build 6`) - Incremental builds and patches

### Format
- **Full Version**: `v2.1 (Build 9)`
- **GitHub Tag**: `v2.1-b9` or `v2.1+9`
- **Release Title**: `MultiClips v2.1 Build 9`

### Update Detection
An update is triggered when:
1. Remote marketing version > Local marketing version, **OR**
2. Same marketing version AND remote build > local build

This ensures users always get the latest fixes and features!

---

**Latest Release**: [v2.1-b9](https://github.com/nitish1705/MultiClips/releases/latest)

**Documentation**: [Auto-Updater Guide](UPDATER_GUIDE.md) | [How It Works](HOW_AUTO_UPDATE_WORKS.md)

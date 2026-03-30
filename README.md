# MultiClips

MultiClips is a lightweight native macOS clipboard manager that keeps your recent copy history available at any time.

It is built with SwiftUI and SwiftData for macOS 14+.

---

## Why This App Exists

macOS only keeps the latest clipboard entry. MultiClips runs in the menu bar and keeps a local history of what you copy, including text, links, images, and files.

---

## Features

### Multi-Clipboard Storage
Stores every clipboard entry — texts, images, files, documents, links, and media — organized by type.

### Search & Live Filtering 🔍
Instantly find past clips using the built-in search bar with live filtering across all your clipboard content.

### Clip Notes & Starring ⭐
Add tiny custom notes to individual clips to remember context, and star your most important clips for quick access via the three-dot action menu.

### Menu Bar App
Lives in your macOS menu bar. Runs in the background even when the main window is closed. Click the clipboard icon to quickly copy any previous item.

### Smart Classification
Automatically categorizes clips into **Texts**, **Images**, **Media**, **Documents**, **Files**, and **Links**.

### Custom Themes 🎨
Personalize your clipboard experience with multiple theme customization and color options.

### Duplicate Detection
Copies the same text twice? MultiClips recognizes it and bumps the existing entry to the top instead of creating a duplicate.

### Image Support
Full support for screenshots (⌘⇧4), copied images from apps, and image files (JPG, PNG, HEIC, etc.) copied from Finder — with thumbnail previews.

### Privacy First
All clipboard data stays **on your device**, stored locally using SwiftData. No cloud uploads. No analytics. No tracking.

### Launch at Login
Optional toggle to start MultiClips automatically when you log in to your Mac.

### Native macOS Design
Built with SwiftUI. Feels right at home on macOS with proper dark mode support, material backgrounds, and system fonts.

---

## Screenshots

| Main Window | Menu Bar |
|---|---|
| ![Main Window](Screenshots/main-window.png) | ![Menu Bar](Screenshots/menu-bar.png) |

---

## Installation

### Option 1: Download Release

1. Go to the [Releases](../../releases) page
2. Download **MultiClips.dmg**
3. Open the DMG and drag **MultiClips** into your **Applications** folder
4. Eject the DMG

### Option 2: Build from Source

```bash
git clone [https://github.com/nitish1705/MultiClips.git](https://github.com/nitish1705/MultiClips.git)
cd MultiClips
open MultiClips.xcodeproj

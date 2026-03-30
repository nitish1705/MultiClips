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

### Menu Bar App
Lives in your macOS menu bar. Runs in the background even when the main window is closed. Click the clipboard icon to quickly copy any previous item.

### Smart Classification
Automatically categorizes clips into **Texts**, **Images**, **Media**, **Documents**, **Files**, and **Links**.

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
git clone https://github.com/nitish1705/MultiClips.git
cd MultiClips
open MultiClips.xcodeproj
```

Build and run with **⌘R** in Xcode.

**Requirements:**
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

### Local DMG Build

To package a local DMG from the command line:

```bash
./scripts/build_dmg.sh
```

Default output:

```bash
build/MultiClips-local.dmg
```

Optional parameters:

```bash
./scripts/build_dmg.sh MultiClips MultiClips MultiClips.xcodeproj build unsigned
```

Parameters are:
- App name
- Xcode scheme name
- Xcode project file
- Build output root folder
- Sign mode (`unsigned` by default, or `signed`)

## First Launch (Important)

Since this app is not yet notarized by Apple, macOS may block it on first launch.

1. Open **MultiClips** from the **Applications** folder.
2. macOS will show a message saying the app cannot be opened. Click **Done**.
3. Open **System Settings**.
4. Go to **Privacy & Security**.
5. Scroll down and find the message that **MultiClips was blocked from use**.
6. Click **Open Anyway**.
7. Confirm by clicking **Open** in the dialog.

After this, **MultiClips** will launch normally.

---

## How It Works

```
You copy something
       │
       ▼
AppDelegate detects pasteboard change (polls every 0.5s)
       │
       ▼
Classifies content → Text / Image / File / Link / Document / Media
       │
       ▼
Checks for duplicates
       │
       ├── Duplicate found → bumps existing clip to top
       └── New content → saves to SwiftData
       │
       ▼
Appears instantly in main window + menu bar
```

---

## Architecture

| File | Purpose |
|---|---|
| `MultiClipsApp.swift` | App entry point — WindowGroup + MenuBarExtra |
| `AppDelegate.swift` | Pasteboard monitoring, window management, app lifecycle |
| `ContentView.swift` | Main window UI and menu bar dropdown components |
| `Item.swift` | SwiftData model — stores clip type, text, file URL, raw data |
| `LoginItemManager.swift` | Launch at Login via ServiceManagement |

---

## Tech Stack

- **SwiftUI** — UI framework
- **SwiftData** — Persistence
- **AppKit** — NSPasteboard monitoring, window management
- **UniformTypeIdentifiers** — File type classification
- **ServiceManagement** — Login item registration

---

## Performance and Testing

MultiClips is designed for lightweight background usage. Clipboard polling runs every 0.5 seconds and writes only when the pasteboard change count updates.

Current testing approach:
- Manual testing for text, link, image, and file copy flows
- Duplicate detection verification across repeated copy actions
- Menu bar copy-back checks to avoid self-ingestion loops

Observed behavior from local development runs:
- Stable background operation with no continuous CPU spikes during idle usage
- Memory usage scales with number and size of stored clips (especially image-heavy histories)

Planned additions:
- Documented RAM snapshots at different history sizes
- Repeatable stress test notes for large clipboard sessions

### Automated Performance Test Script

An automated sampler is available at `scripts/performance_test.sh`.

It captures:
- RSS memory (MB)
- Virtual memory size (MB)
- CPU usage (%)

Run it while MultiClips is open:

```bash
./scripts/performance_test.sh
```

Optional arguments:

```bash
./scripts/performance_test.sh MultiClips 120 1 performance-results
```

Arguments are:
- App name
- Duration in seconds
- Sampling interval in seconds
- Output directory

Outputs:
- CSV timeline with per-sample data
- Summary file with min/max/avg metrics

If Python 3 and matplotlib are available, a chart image is generated automatically:
- PNG chart beside the CSV (for example `perf-<timestamp>.png`)

Install visualization dependency:

```bash
python3 -m pip install matplotlib
```

Manual visualization command:

```bash
python3 scripts/visualize_performance.py performance-results/perf-20260319-204401.csv
```

---

## Version History

A dedicated release history is available in the app under Version History.
Repository-side release notes are tracked in `RELEASE_NOTES.md`.

---

## Roadmap

- [ ] Search through clipboard history
- [ ] Pin favorite clipboard entries
- [ ] Keyboard shortcut to open menu bar (global hotkey)
- [ ] Auto-clear options (delete clips older than X days)
- [ ] iCloud Sync across devices
- [ ] Drag and drop from clip cards
- [ ] Customizable grid layout

---

## Known Limitations

- App is not notarized (macOS Gatekeeper prompt on first launch)
- Image files must be accessible on disk to display thumbnails
- Clipboard monitoring requires the app to be running (menu bar or main window)

---

## Contributing

Contributions, suggestions, and bug reports are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Version

**Current:** v1.0.0

Follows [Semantic Versioning](https://semver.org/):
- **Patch** (1.0.x) → Bug fixes
- **Minor** (1.x.0) → New features
- **Major** (x.0.0) → Breaking changes

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Author

Built by [@nitish1705](https://github.com/nitish1705)

---

> **MultiClips** — Copy once, access anytime. 📋

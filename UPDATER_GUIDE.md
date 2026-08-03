# 🔄 MultiClips Auto-Updater & Versioning Guide

> Comprehensive documentation for the built-in **Custom Native In-App Auto-Updater** and **Build Counter System** in MultiClips.

---

## 📌 Architecture Overview

MultiClips features a zero-dependency, native Swift auto-update engine ([`UpdateManager.swift`](file:///Users/nitishm/Desktop/FILES/Apps%20\(Xcode\)/MultiClips/MultiClips/MultiClips/UpdateManager.swift)) that allows users to receive instant updates directly inside the application with a single click.

```mermaid
graph TD
    A[App Startup / Manual Check] --> B[UpdateManager.checkForUpdates]
    B -->|GET /releases/latest| C{GitHub Release API}
    C -->|Parse Tag & Body| D[Extract Remote Version & Build Number]
    D --> E{Compare (Version, Build)}
    E -->|Remote > Local| F[Display In-App Update Card with Changelog]
    E -->|Remote <= Local| G[Show 'Up to Date' Status]
    F -->|User Clicks Update & Relaunch| H[Download MultiClips.app.zip to /tmp]
    H --> I[Extract App Bundle via ditto]
    I --> J[Launch Relaunch Shell Script]
    J --> K[Terminate Current App Instance]
    K --> L[Script Replaces /Applications/MultiClips.app]
    L --> M[Script Clears Quarantine & Opens Updated App]
```

---

## 🔢 Dual-Versioning System (Marketing Version + Build Counter)

To eliminate false-positive update prompts and accurately track patch builds, MultiClips enforces **Dual-Versioning**:

1. **Marketing Version (`CFBundleShortVersionString`)**:
   * Standard semantic version string (e.g., `2.0.0`, `2.1.0`).
   * Stored in Xcode as `MARKETING_VERSION`.

2. **Build Number (`CFBundleVersion`)**:
   * Monotonically increasing build counter (e.g., `1`, `2`, `3`, ...).
   * Stored in Xcode as `CURRENT_PROJECT_VERSION` in [`MultiClips.xcodeproj/project.pbxproj`](file:///Users/nitishm/Desktop/FILES/Apps%20\(Xcode\)/MultiClips/MultiClips/MultiClips.xcodeproj/project.pbxproj).

### 🎯 Comparison Logic

An update prompt is triggered **ONLY** when:
* `Remote Marketing Version > Local Marketing Version` (e.g., `2.1.0` vs `2.0.0`), **OR**
* `Remote Marketing Version == Local Marketing Version` **AND** `Remote Build Number > Local Build Number` (e.g., Build `2` vs Build `1`).

If the local version and build counter match or exceed GitHub's latest release, the app cleanly reports **Up to Date** without any update prompts.

---

## 🏷️ GitHub Tag & Release Format

The updater recognizes build numbers in any of the following standard GitHub release formats:

| Format | GitHub Release Tag | Release Description / Body | Extracted Version | Extracted Build |
| :--- | :--- | :--- | :--- | :--- |
| **Recommended Suffix** | `v2.0.0-b2` or `v2.0.0+2` | Any text | `2.0.0` | `2` |
| **Body Metadata** | `v2.0.0` | `Build: 2` or `build_number: 2` | `2.0.0` | `2` |
| **Standard Tag** | `v2.0.0` | No build specified | `2.0.0` | `1` (Default) |

---

## 🛠️ Maintainer Workflow: Publishing a Release

### **Step 1: Run the Build Script**
Execute the automated build script in the terminal:

```bash
./build.sh
```

`build.sh` automatically:
1. Reads `CURRENT_PROJECT_VERSION` from `project.pbxproj`.
2. Increments the build counter by `+1` (e.g. `1` → `2`).
3. Compiles the Release application binary.
4. Generates both release assets inside `build/`:
   * 📦 `build/MultiClips-vX.Y.Z-bN.app.zip` / `build/MultiClips.app.zip` *(Required for Auto-Updater)*
   * 💿 `build/MultiClips-local.dmg` *(For manual DMG installers)*

### **Step 2: Commit & Push Changes**
```bash
git add .
git commit -m "Release v2.1.0 Build 2"
git push origin main
```

### **Step 3: Publish on GitHub**
1. Go to your GitHub repository ([`nitish1705/MultiClips`](https://github.com/nitish1705/MultiClips)) → **Releases** → **Draft a new release**.
2. Set the release tag (e.g. `v2.1.0` or `v2.0.0-b2`).
3. Drag & drop `MultiClips.app.zip` (and `MultiClips-local.dmg`) into the Release Assets section.
4. Click **Publish release**.

---

## 🔒 Security & Self-Replacement Process

When a user clicks **Update & Relaunch**:
1. **Stream Download**: Downloads `MultiClips.app.zip` to macOS temporary storage (`/tmp/`).
2. **Bundle Unpacking**: Uses `/usr/bin/ditto` to extract the `.app` bundle.
3. **Background Relauncher**: Spawns a background shell script:
   ```bash
   sleep 1
   rm -rf "/Applications/MultiClips.app"
   cp -R "/tmp/.../MultiClips.app" "/Applications/MultiClips.app"
   xattr -dr com.apple.quarantine "/Applications/MultiClips.app" 2>/dev/null || true
   open "/Applications/MultiClips.app"
   ```
4. **Clean Exit**: The running application calls `NSApp.terminate(nil)`.
5. **In-Place Update**: The background script overwrites the bundle, clears Gatekeeper quarantine attributes, and launches the new MultiClips instance seamlessly.

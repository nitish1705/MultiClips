# MultiClips 📋

> **Copy once, access anytime.** A lightweight, native macOS clipboard manager that never lets you lose what you copied.

MultiClips is a powerful utility that lives in your Mac's menu bar, keeping a persistent, local history of your clipboard. Built entirely with modern macOS technologies (SwiftUI and SwiftData), it is designed to be fast, private, and deeply integrated into the macOS ecosystem.

---

## 💡 Why This App Exists

By default, macOS only remembers the absolute last item you copied. If you copy a link, and then accidentally copy a piece of text right after, that original link is gone forever. 

MultiClips solves this by running silently in the background. It catches everything you copy—text, URLs, images, screenshots, and even files—and stores them in an easily searchable, beautifully designed history that you can access with a single click.

---

## ✨ Core Features

* **Infinite Multi-Clipboard Storage:** Safely stores your entire copy history. Whether it is a snippet of code, a meme from the web, or a PDF document, MultiClips remembers it.
* **Search & Live Filtering 🔍:** Stop endlessly scrolling. Instantly find past clips using the built-in search bar. The list filters in real-time as you type, scanning through the content of all your saved clips.
* **Clip Notes & Starring ⭐:** Not all clips are created equal. Add custom, tiny text notes to individual clips to give yourself context for later. Star your most frequently used clips to keep them highly accessible via the three-dot action menu.
* **Smart Classification:** MultiClips automatically analyzes what you copy and categorizes it into smart folders: **Texts**, **Images**, **Media**, **Documents**, **Files**, and **Links**. 
* **Intelligent Duplicate Detection:** If you copy the same text or link twice, MultiClips won't clutter your history with duplicates. It recognizes the exact match and simply bumps the existing entry to the very top of your list.
* **Rich Image Support:** Fully supports macOS screenshots (`⌘ + ⇧ + 4`), images copied directly from web browsers, and raw image files (JPG, PNG, HEIC) copied from Finder. All images display with beautiful, native thumbnail previews.
* **Custom Themes 🎨:** Personalize your clipboard experience. MultiClips includes multiple theme customizations and accent color options to match your exact desktop setup.
* **Uncompromising Privacy:** Your data is yours. All clipboard data stays **strictly on your device** and is stored locally using Apple's secure SwiftData framework. There are no cloud servers, no analytics, and no tracking of any kind.
* **Native macOS Feel:** Built from the ground up with SwiftUI. MultiClips features proper dark mode support, system fonts, and native material backgrounds that make it feel like an official Apple app.

---

## 📸 Screenshots

| Main Window | Menu Bar |
|---|---|
| ![Main Window](Screenshots/main-window.png) | ![Menu Bar](Screenshots/menu-bar.png) |

---

## 🚀 Installation

### Option 1: Download the Release (Recommended)

1. Navigate to the [Releases](../../releases) page.
2. Download the latest **MultiClips_v2.0.dmg** file.
3. Open the downloaded `.dmg` file.
4. Drag the **MultiClips** application icon into the **Applications** folder shortcut.
5. Eject the DMG file from your desktop.

---

### ⚠️ Important: First Launch & macOS Gatekeeper

Because MultiClips is a free, open-source application, it is not distributed through the Mac App Store. It also hasn't been "notarized" through Apple's paid Developer Program. 

Because of this, macOS uses a security feature called **Gatekeeper** that automatically blocks apps from unidentified developers to protect your system. When you try to open MultiClips for the first time, macOS will show a warning saying the app cannot be opened. 

**This is entirely normal for open-source apps. Here is how to safely allow MultiClips to run:**

1. Open **MultiClips** from your Applications folder.
2. When the macOS warning dialog appears, click **Done** (or **Cancel**).
3. Open your Mac's **System Settings**.
4. Navigate to **Privacy & Security** in the left sidebar.
5. Scroll down to the **Security** section.
6. You will see a message stating that *"MultiClips was blocked from use because it is not from an identified developer."*
7. Click the **Open Anyway** button next to that message.
8. macOS will ask for your Mac password or Touch ID to confirm.
9. Click **Open** on the final confirmation dialog.

*MultiClips will now open normally, and macOS will remember this approval for all future launches!*

---

### Option 2: Build from Source

If you prefer to compile the app yourself, you can easily build it using Xcode.

```bash
git clone [https://github.com/nitish1705/MultiClips.git](https://github.com/nitish1705/MultiClips.git)
cd MultiClips
open MultiClips.xcodeproj

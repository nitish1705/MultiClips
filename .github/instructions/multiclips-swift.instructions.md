---
applyTo: "**/*.swift"
description: "Hard rules for Swift changes in this workspace: preserve MultiClips architecture, clipboard flow, and model compatibility."
---

# MultiClips Swift Instructions

## Scope and Stack (Hard Rules)
- This project is a macOS app (macOS 14+) built with SwiftUI, SwiftData, AppKit, UniformTypeIdentifiers, and ServiceManagement.
- Keep implementation native and lightweight. Do not introduce cross-platform frameworks or web wrappers.
- Use SwiftUI-first UI changes. Use AppKit only where needed for pasteboard, lifecycle, or window behavior.

## Architecture Rules
- Preserve separation of concerns:
  - `MultiClipsApp.swift`: app entry and scene wiring.
  - `AppDelegate.swift`: pasteboard monitoring, extraction, deduplication, and window behavior.
  - `ContentView.swift`: main navigation and all clip UI, including the menu bar dropdown. This is the only UI file of consequence — expect to work here.
  - `Item.swift`: SwiftData model and `ClipType` definitions.
  - `LoginItemManager.swift`: launch-at-login behavior.
  - `ModelContainerProvider.swift`: shared container construction.
  - `UpdateManager.swift`: GitHub release checks, version parsing/comparison, download and install. Singleton via `UpdateManager.shared`, `@MainActor`.
  - `UpdateNotificationView.swift`: update banner and the Check for Updates button.
- Keep shared behavior deterministic across menu bar and main window by using the shared model container pattern.

## Clipboard Pipeline Safety
- Treat clipboard handling as a pipeline and keep all steps aligned:
  - extract content type
  - classify content
  - deduplicate existing clips
  - create or update `Item`
  - render and copy back to pasteboard
- If adding or changing a clip type, update all related switch paths in extraction, deduplication, card/detail rendering, and copy-to-pasteboard logic.
- Keep duplicate handling behavior intact: duplicates must bump recency rather than create duplicate rows.

## Data Model and Compatibility
- Do not rename persisted `ClipType` cases (`Texts`, `Images`, `Medias`, `Documents`, `Files`, `Links`, `Unknown`) without an explicit migration plan.
- Keep `Item` as the central SwiftData model for clipboard entries.
- Preserve `rawData` as external storage for large payloads unless a deliberate schema migration is requested.
- Block schema changes to `ClipType` or `Item` unless the change includes a clear migration plan and compatibility notes.

## Concurrency and App Behavior
- Keep pasteboard polling/model mutations on the main actor where currently required.
- Preserve `skipNextPasteboardChange` notification flow so copy actions in the app do not re-ingest themselves.
- Preserve menu bar behavior and the accessory activation policy unless the task explicitly asks to change app lifecycle/UX.

## Theming and Backgrounds (Hard Rules)
- Themes come from `ThemeOption` in `ContentView.swift`, persisted as `@AppStorage("selectedTheme")`. Every themed view resolves `activeTheme` the same way — copy that pattern, do not invent a second source of truth.
- **Never fade a background gradient to `Color.clear`.** `.clear` is transparent black: the window becomes see-through and the user's desktop wallpaper tints the pane. This shipped as a bug where the purple theme read green on a green wallpaper. Fade to `activeTheme.color.opacity(0)` instead, and put an opaque floor underneath:
  ```swift
  .background(LinearGradient(colors: [activeTheme.color.opacity(0.10),
                                      activeTheme.color.opacity(0)], ...))
  .background(Color(nsColor: .windowBackgroundColor))
  ```
- The accent marks structure — badges, icons, active states, rules. Body copy stays `.primary`/`.secondary`. Tinting whole paragraphs of text in the theme colour is a regression, not a feature.
- SwiftUI `Link` keeps its own system-blue tint and ignores an ambient `.tint(activeTheme.color)`. Use a `Button` that opens the URL when the control must follow the theme.

## SwiftUI Gotchas Already Paid For
- **Hover-revealed controls**: put `.opacity(...)` on each button individually, never on the enclosing stack. A shared container cannot keep one child visible (e.g. a starred clip's star) while hiding its siblings. Always pair opacity with `.allowsHitTesting(...)` — an `opacity(0)` button still swallows clicks.
- **Tinting an icon+label pair**: apply `.foregroundStyle(...)` to the containing stack. Applying it to the `Image` alone leaves the `Text` at the default colour.
- **macOS toolbar placement**: `ToolbarItemGroup(placement: .secondaryAction)` renders in the *centre* of a macOS toolbar, which reads as a control floating loose. Use `.primaryAction` for trailing-edge controls.
- **`ForEach` identity**: models carrying `let id = UUID()` must live in stored properties. Moving such an array to a computed property regenerates every id on each render and breaks identity and animation.
- The menu bar list height is `min(CGFloat(clips.count) * 52 + 20, 280)`. That `52` is a hardcoded mirror of the row height — change one and you must change the other.
- Destructive bulk actions belong in the main window behind a confirmation alert (see `showDeleteAllAlert`), not one unguarded click away in the menu bar.

## Versioning and Releases
- `build.sh` increments `CURRENT_PROJECT_VERSION` in the project file *before* building, then writes it back. So the committed value is the last build produced; running the script yields that number plus one. A failed build still leaves the bump behind.
- **Never hardcode a version or build number in UI code.** Read `UpdateManager.shared.currentVersion` and `.currentBuildNumber`, which come from `CFBundleShortVersionString` / `CFBundleVersion`. Hardcoded values go stale on the very next `build.sh` run.
- Release tags are `v<marketing>-b<build>` (e.g. `v2.1-b9`), titled `MultiClips v2.1 Build 9`. `UpdateManager.parseReleaseVersion` expects that shape; comparison is marketing version first, then build number as tiebreak.
- A release touches three places and all must agree: `MARKETING_VERSION` in the project file, the `releases` array in `VersionHistoryView`, and `VERSION_HISTORY.md`.

## Testing
- There is no XCTest target. `Tests/VersionLogicTests.swift` is a standalone script: `swift Tests/VersionLogicTests.swift`.
- It contains **copies** of `parseReleaseVersion`, `normalizeVersion` and `isUpdateNewer`. Changing those functions in `UpdateManager.swift` means updating the copies too, or the tests quietly stop testing the real code. Adding a proper test target and deleting the copies is a welcome improvement.
- Pure logic (parsing, comparison, classification) should get a case here before it is called fixed.

## Design Previews
- `design-preview/` holds standalone HTML/CSS/JS mockups of the menu bar and About pages, used to agree on a design before writing Swift. Not app code; nothing there ships in the bundle.
- When changing those surfaces, check the implementation against the relevant mockup rather than reinventing the layout.

## Style and Structure
- Match existing style and naming in the file being edited.
- Use explicit `// MARK:` sections for major blocks in larger files.
- Keep functions focused and avoid broad refactors unless requested.
- Add concise comments only for non-obvious logic (especially around pasteboard edge cases).

## Change Validation Checklist
Before finalizing Swift changes, verify:
- The project builds: `xcodebuild -project MultiClips.xcodeproj -scheme MultiClips -configuration Debug -destination 'platform=macOS' build`. Requires full Xcode; Command Line Tools alone cannot build this (the SwiftData macro plugin is missing).
- `swift Tests/VersionLogicTests.swift` passes if anything under `UpdateManager` was touched.
- New/updated clipboard behavior appears in both main window and menu bar flows.
- No obvious regressions in deduplication or copy-back behavior.
- Model changes are backward-safe or explicitly migrated.
- Launch-at-login behavior remains functional when touched.
- Themed views were checked against a **saturated, non-grey desktop wallpaper** in both light and dark mode. Transparency bugs are invisible on a neutral background.
- Version and build numbers shown in the UI were read from the bundle, not typed in.
- A build succeeding is not a visual check. State plainly what was and was not verified by running the app.

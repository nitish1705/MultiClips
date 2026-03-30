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
  - `ContentView.swift`: main navigation and clip UI.
  - `Item.swift`: SwiftData model and `ClipType` definitions.
  - `LoginItemManager.swift`: launch-at-login behavior.
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

## Style and Structure
- Match existing style and naming in the file being edited.
- Use explicit `// MARK:` sections for major blocks in larger files.
- Keep functions focused and avoid broad refactors unless requested.
- Add concise comments only for non-obvious logic (especially around pasteboard edge cases).

## Change Validation Checklist
Before finalizing Swift changes, verify:
- New/updated clipboard behavior appears in both main window and menu bar flows.
- No obvious regressions in deduplication or copy-back behavior.
- Model changes are backward-safe or explicitly migrated.
- Launch-at-login behavior remains functional when touched.

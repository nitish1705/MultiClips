# Sidebar Theme Color Fix (Final) — `ContentView.swift`

## Problem

Even with `.tint(activeTheme.color)` on the `List`, the selected `NavigationLink` row still shows the **system blue highlight**. This is because on macOS, `NavigationSplitView` sidebar selections are controlled by the system and override `.tint()` and `listRowBackground` on the selected row.

---

## Root Cause

`NavigationLink` inside a `NavigationSplitView` sidebar uses **macOS's native selection rendering**, which paints the selected row with the system accent color (blue) regardless of `listRowBackground` or `.tint()`.

There are two ways to fix this:

---

## Solution A — Override with `.listRowBackground` + Disable Native Selection (Recommended)

Use `selection` binding on the `List` combined with `tag()` per row, and suppress the native selection highlight using `.listRowBackground` on every row.

### Step 1 — Give the List a selection binding

```swift
// In ContentView, already have:
@State private var selectedSidebarItem: String = "clips:All Clips"

// Change the List to use selection binding:
List(selection: $selectedSidebarItem) {
    // ... sections unchanged
}
.tint(activeTheme.color)
```

### Step 2 — Add `.tag()` to every NavigationLink

Each `NavigationLink` needs a `.tag()` matching the key so the List knows which item is selected:

```swift
// In nav() helper:
NavigationLink {
    ClipGridView(title: title, clips: data)
        .onAppear { selectedSidebarItem = key }
} label: {
    Label(title, systemImage: icon)
        .badge(data.count)
        .foregroundStyle(sidebarRowForeground(for: key))
}
.tag(key)                                              // ← ADD THIS
.listRowBackground(sidebarRowBackground(for: key))

// Same for every hardcoded NavigationLink — e.g.:
NavigationLink { ... } label: { ... }
    .tag("history:recent")                             // ← ADD per row
    .listRowBackground(sidebarRowBackground(for: "history:recent"))
```

### Step 3 — Suppress the native blue selection overlay

Add this modifier to the `List` to disable the system selection highlight so `listRowBackground` is the only background:

```swift
List(selection: $selectedSidebarItem) {
    // ...
}
.tint(activeTheme.color)
.listRowSeparator(.hidden)  // optional cosmetic
// Disable the native selection highlight:
.environment(\.defaultMinListRowHeight, 0)
```

> **Note:** On macOS 14+ (Sonoma), you can also use:
>
> ```swift
> .scrollContentBackground(.hidden)
> ```
>
> on the List to help prevent the system from injecting its own selection color.

---

## Solution B — Replace NavigationLink with Button + Manual Navigation (Most Reliable)

Since macOS always wins the selection highlight battle on `NavigationLink`, the most reliable fix is to **not use NavigationLink selection at all** and instead navigate manually using a `@State` destination variable.

### Replace `nav()` helper:

```swift
// Replace the NavigationLink-based nav() with a Button that sets selectedSidebarItem
// and drives the detail view from a separate @State var

@State private var detailView: AnyView = AnyView(ClipGridView(title: "All Clips", clips: []))

// In the sidebar List, replace NavigationLink with:
@ViewBuilder
private func nav(_ title: String, _ icon: String, _ data: [Item]) -> some View {
    let key = "clips:\(title)"
    Button {
        selectedSidebarItem = key
    } label: {
        Label(title, systemImage: icon)
            .badge(data.count)
            .foregroundStyle(sidebarRowForeground(for: key))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(.vertical, 3)
    .listRowBackground(sidebarRowBackground(for: key))
}
```

Then drive the detail pane from `selectedSidebarItem` in the `detail:` closure:

```swift
NavigationSplitView {
    List { ... }
} detail: {
    // Switch on selectedSidebarItem to show the right view
    switch selectedSidebarItem {
    case "clips:All Clips":     ClipGridView(title: "All Clips", clips: clips)
    case "clips:Starred":       ClipGridView(title: "Starred", clips: clips.filter { $0.isStarred })
    case "clips:Texts":         ClipGridView(title: "Texts", clips: clips.filter { $0.type == .Texts })
    case "clips:Images":        ClipGridView(title: "Images", clips: clips.filter { $0.type == .Images })
    case "clips:Media":         ClipGridView(title: "Media", clips: clips.filter { $0.type == .Medias })
    case "clips:Documents":     ClipGridView(title: "Documents", clips: clips.filter { $0.type == .Documents })
    case "clips:Files":         ClipGridView(title: "Files", clips: clips.filter { $0.type == .Files })
    case "clips:Links":         ClipGridView(title: "Links", clips: clips.filter { $0.type == .Links })
    case "history:recent":      HistoryView(clips: clips)
    case "settings:general":    Text("General Settings")
    case "about:credits":       CreditsView()
    case "about:versions":      VersionHistoryView()
    default:                    ClipGridView(title: "All Clips", clips: clips)
    }
}
```

This approach gives **100% control** over row styling — no system selection highlight can override a plain `Button` with custom `listRowBackground`.

---

## Recommended Approach

**Use Solution B.** It is the most reliable on all macOS versions. The system selection highlight on `NavigationLink` in a sidebar is a known macOS SwiftUI limitation that cannot be fully suppressed via `.tint()` alone.

---

## Why `.tint()` Alone Didn't Work

| Modifier                               | What it controls                        | Does it fix sidebar selection?                                   |
| -------------------------------------- | --------------------------------------- | ---------------------------------------------------------------- |
| `.tint(color)` on List                 | Accent color for toggles, badges, links | ❌ Does NOT override NavigationLink selection highlight on macOS |
| `.listRowBackground(color)`            | Row background when NOT selected        | ❌ Overridden by system when row IS selected via NavigationLink  |
| `Button` + `.listRowBackground(color)` | Full control, no system selection       | ✅ Always works                                                  |

---

## Summary

The blue selected row highlight is **not a tint/foreground issue** — it is the macOS system selection highlight that overrides custom backgrounds on `NavigationLink` rows. The fix is to replace `NavigationLink` rows with `Button` rows (Solution B) and drive navigation manually via `selectedSidebarItem`.

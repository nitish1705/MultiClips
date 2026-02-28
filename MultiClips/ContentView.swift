import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - Notification name (used by AppDelegate + copy buttons)
extension Notification.Name {
    static let skipNextPasteboardChange = Notification.Name("skipNextPasteboardChange")
}

// MARK: - Main Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.copiedDate, order: .reverse) var clips: [Item]

    @State private var showDeleteAllAlert = false

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var showWelcome = false

    var body: some View {
        ZStack {
            NavigationSplitView {
                List {
                    Section("Clips") {
                        nav("All Clips", "tray.2", clips)
                        nav("Texts", "doc.text", clips.filter { $0.type == .Texts })
                        nav("Images", "photo", clips.filter { $0.type == .Images })
                        nav("Media", "play.rectangle", clips.filter { $0.type == .Medias })
                        nav("Documents", "doc", clips.filter { $0.type == .Documents })
                        nav("Files", "folder", clips.filter { $0.type == .Files })
                        nav("Links", "link", clips.filter { $0.type == .Links })
                    }

                    Section("Home") {
                        NavigationLink { Text("Favorites View") } label: {
                            Label("Favorites", systemImage: "star")
                        }
                    }

                    Section("History") {
                        NavigationLink { HistoryView(clips: clips) } label: {
                            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                        }
                    }

                    Section("Settings") {
                        NavigationLink { Text("General Settings") } label: {
                            Label("General Settings", systemImage: "gearshape")
                        }

                        Toggle(isOn: .constant(true)) {
                            Label("iCloud Sync", systemImage: "icloud")
                        }

                        Toggle(isOn: Binding(
                            get: { LoginItemManager.isEnabled },
                            set: { newValue in
                                if newValue { LoginItemManager.enable() }
                                else { LoginItemManager.disable() }
                            }
                        )) {
                            Label("Launch at Login", systemImage: "arrow.clockwise")
                        }

                        Button(role: .destructive) { showDeleteAllAlert = true } label: {
                            Label("Clear History", systemImage: "trash").foregroundColor(.red)
                        }
                        .alert("Clear All History?", isPresented: $showDeleteAllAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Delete All", role: .destructive) { deleteAllClips() }
                        } message: {
                            Text("This will permanently delete all \(clips.count) clip\(clips.count == 1 ? "" : "s").")
                        }
                    }
                }
                .navigationTitle("MultiClips")
            } detail: {
                Text("Select a category from the sidebar").foregroundStyle(.secondary)
            }

            if showWelcome {
                WelcomeView(isPresented: $showWelcome)
                    .transition(.opacity)
                    .zIndex(1)
                    .onDisappear { hasSeenWelcome = true }
            }
        }
        .onAppear {
            if !hasSeenWelcome { showWelcome = true }
        }
    }

    @ViewBuilder
    private func nav(_ title: String, _ icon: String, _ data: [Item]) -> some View {
        NavigationLink { ClipGridView(title: title, clips: data) } label: {
            Label(title, systemImage: icon).badge(data.count)
        }
    }

    private func deleteAllClips() {
        clips.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

// MARK: - Grid View

struct ClipGridView: View {
    let title: String
    let clips: [Item]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedClip: Item?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            if clips.isEmpty {
                ContentUnavailableView("No \(title)", systemImage: "clipboard", description: Text("Items you copy will appear here."))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(clips) { clip in
                            ClipCard(clip: clip).onTapGesture { selectedClip = clip }
                        }
                    }.padding()
                }
            }

            if let clip = selectedClip {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { selectedClip = nil }
                ClipDetailSheet(clip: clip, onDelete: {
                    modelContext.delete(clip)
                    try? modelContext.save()
                    selectedClip = nil
                }, onDismiss: { selectedClip = nil })
                .frame(width: 500, height: 420)
                .background(.ultraThickMaterial)
                .cornerRadius(16)
            }
        }
        .navigationTitle(title)
    }
}

// MARK: - Detail Sheet

struct ClipDetailSheet: View {
    let clip: Item
    var onDelete: () -> Void
    var onDismiss: () -> Void
    @State private var showCopiedAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash").foregroundColor(.red) }
                    .buttonStyle(.bordered)
                Spacer()
                Button {
                    copyToPasteboard()
                    showCopiedAlert = true
                } label: { Label("Copy", systemImage: "doc.on.doc") }
                    .buttonStyle(.borderedProminent)
                Button(action: onDismiss) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
            }
            .padding()
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(clip.copiedDate.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(.secondary)
                    Divider()
                    switch clip.type {
                    case .Texts, .Links:
                        Text(clip.textCopied ?? "No text content").textSelection(.enabled)
                    case .Images:
                        if let img = imageForClip(clip) {
                            Image(nsImage: img).resizable().scaledToFit().cornerRadius(8)
                        } else {
                            Text("Unable to display image").foregroundStyle(.secondary)
                        }
                    case .Files, .Documents, .Medias:
                        Text(clip.files?.path ?? "No file path available").textSelection(.enabled)
                    case .Unknown:
                        Text("Unknown clipboard content").foregroundStyle(.secondary)
                    }
                }.padding()
            }
        }
        .alert("Copied!", isPresented: $showCopiedAlert) { Button("OK", role: .cancel) {} }
        .onExitCommand(perform: onDismiss)
    }

    private func copyToPasteboard() {
        NotificationCenter.default.post(name: .skipNextPasteboardChange, object: nil)
        let pb = NSPasteboard.general
        pb.clearContents()

        switch clip.type {
        case .Texts, .Links:
            if let t = clip.textCopied { pb.setString(t, forType: .string) }

        case .Images:
            var wrote = false
            if let img = imageForClip(clip) {
                pb.writeObjects([img])
                wrote = true
                if let tiff = img.tiffRepresentation { pb.setData(tiff, forType: .tiff) }
            }
            if let file = clip.files {
                pb.writeObjects([file as NSURL])
                wrote = true
            }
            if !wrote { print("No image data to copy") }

        case .Files, .Documents, .Medias:
            if let u = clip.files { pb.writeObjects([u as NSURL]) }

        case .Unknown:
            if let d = clip.rawData { pb.setData(d, forType: .string) }
        }
    }
}

// MARK: - Clip Card

struct ClipCard: View {
    let clip: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: clip.type)).foregroundStyle(.secondary)
                Spacer()
                Text(clip.copiedDate, style: .time).font(.caption2).foregroundStyle(.tertiary)
            }

            Group {
                switch clip.type {
                case .Texts, .Links:
                    Text(clip.textCopied ?? "Empty").lineLimit(4).font(.callout)
                case .Images:
                    if let img = imageForClip(clip) {
                        Image(nsImage: img).resizable().scaledToFill().frame(height: 60).clipped().cornerRadius(6)
                    } else {
                        Text("Image unavailable").foregroundStyle(.secondary)
                    }
                case .Files, .Documents, .Medias:
                    Text(clip.files?.lastPathComponent ?? clip.type.rawValue).lineLimit(2).font(.callout)
                case .Unknown:
                    Text("Unknown Clip").font(.callout)
                }
            }

            Spacer(minLength: 0)
            HStack {
                Text(clip.copiedDate, style: .date).font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(clip.type.rawValue).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(.quaternary).cornerRadius(4)
            }
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(.background)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private func iconName(for type: ClipType) -> String {
        switch type {
        case .Texts: return "doc.text"
        case .Images: return "photo"
        case .Medias: return "play.rectangle"
        case .Documents: return "doc"
        case .Files: return "folder"
        case .Links: return "link"
        case .Unknown: return "questionmark.square"
        }
    }
}

// MARK: - Shared Image Helper

func imageForClip(_ clip: Item) -> NSImage? {
    if let data = clip.rawData, let img = NSImage(data: data) { return img }
    if let data = clip.rawData, let rep = NSBitmapImageRep(data: data) {
        let img = NSImage(size: rep.size); img.addRepresentation(rep); return img
    }
    if let url = clip.files, let img = NSImage(contentsOf: url) { return img }
    return nil
}

// MARK: - History View

struct HistoryView: View {
    let clips: [Item]
    var body: some View {
        List(clips) { clip in
            HStack {
                Text(clip.displayTitle).lineLimit(1)
                Spacer()
                Text(clip.copiedDate.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("History")
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Binding var isPresented: Bool
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack {
                Text("Welcome to MultiClips").font(.title.bold()).foregroundStyle(.orange)
                Button("Continue") { isPresented = false }
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(.orange))
                    .foregroundStyle(.black)
            }
            .frame(width: 420, height: 300)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.copiedDate, order: .reverse) var clips: [Item]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "clipboard.fill").foregroundStyle(.orange)
                Text("MultiClips").font(.headline)
                Spacer()
                Text("\(clips.count) clips").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if clips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard").font(.largeTitle).foregroundStyle(.secondary)
                    Text("No clips yet").foregroundStyle(.secondary)
                    Text("Copy something to get started").font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(clips.prefix(10)) { clip in
                            MenuBarClipRow(clip: clip) { copyClipToPasteboard(clip) }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 320)
            }

            Divider()

            VStack(spacing: 2) {
                Button {
                    if let d = NSApplication.shared.delegate as? AppDelegate { d.showMainWindow() }
                } label: {
                    HStack { Image(systemName: "macwindow"); Text("Open MultiClips"); Spacer() }
                        .padding(.horizontal, 12).padding(.vertical, 6).contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    clips.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                } label: {
                    HStack { Image(systemName: "trash"); Text("Clear History"); Spacer() }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12).padding(.vertical, 6).contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack { Image(systemName: "power"); Text("Quit MultiClips"); Spacer() }
                        .padding(.horizontal, 12).padding(.vertical, 6).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 300)
    }

    private func copyClipToPasteboard(_ clip: Item) {
        NotificationCenter.default.post(name: .skipNextPasteboardChange, object: nil)
        let pb = NSPasteboard.general
        pb.clearContents()

        switch clip.type {
        case .Texts, .Links:
            if let t = clip.textCopied { pb.setString(t, forType: .string) }
        case .Images:
            if let img = imageForClip(clip) {
                pb.writeObjects([img])
                if let tiff = img.tiffRepresentation { pb.setData(tiff, forType: .tiff) }
            }
            if let file = clip.files { pb.writeObjects([file as NSURL]) }
        case .Files, .Documents, .Medias:
            if let u = clip.files { pb.writeObjects([u as NSURL]) }
        case .Unknown:
            if let d = clip.rawData { pb.setData(d, forType: .string) }
        }

        clip.copiedDate = Date()
        try? modelContext.save()
    }
}

// MARK: - Menu Bar Clip Row

struct MenuBarClipRow: View {
    let clip: Item
    let onCopy: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 10) {
                Image(systemName: iconName(for: clip.type))
                    .font(.system(size: 14)).foregroundStyle(.orange).frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(clipPreview).font(.callout).lineLimit(1).truncationMode(.tail)
                    Text(clip.copiedDate.formatted(date: .omitted, time: .shortened)).font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                if isHovered { Image(systemName: "doc.on.doc").font(.caption).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            .cornerRadius(6).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var clipPreview: String {
        switch clip.type {
        case .Texts, .Links: return clip.textCopied ?? "Empty"
        case .Images: return clip.files != nil ? "🖼 \(clip.files!.lastPathComponent)" : "🖼 Screenshot"
        case .Files, .Documents, .Medias: return clip.files?.lastPathComponent ?? clip.type.rawValue
        case .Unknown: return "Unknown Clip"
        }
    }

    private func iconName(for type: ClipType) -> String {
        switch type {
        case .Texts: return "doc.text"
        case .Images: return "photo"
        case .Medias: return "play.rectangle"
        case .Documents: return "doc"
        case .Files: return "folder"
        case .Links: return "link"
        case .Unknown: return "questionmark.square"
        }
    }
}

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers
internal import Combine

extension Notification.Name {
    static let skipNextPasteboardChange = Notification.Name("skipNextPasteboardChange")
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.copiedDate, order: .reverse) var clips: [Item]

    @State private var showDeleteAllAlert = false
    @State private var lastChangeCount: Int = NSPasteboard.general.changeCount
    @State private var skipNextPasteboardChange = false

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
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            checkPasteboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .skipNextPasteboardChange)) { _ in
            skipNextPasteboardChange = true
        }
        .onAppear {
            lastChangeCount = NSPasteboard.general.changeCount
            if !hasSeenWelcome { showWelcome = true }
        }
    }

    @ViewBuilder
    private func nav(_ title: String, _ icon: String, _ data: [Item]) -> some View {
        NavigationLink { ClipGridView(title: title, clips: data) } label: {
            Label(title, systemImage: icon).badge(data.count)
        }
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        let cc = pb.changeCount
        guard cc != lastChangeCount else { return }
        lastChangeCount = cc

        if skipNextPasteboardChange {
            skipNextPasteboardChange = false
            return
        }

        let content = extractPasteboardContent(pb)
        guard !(content.type == .Unknown && content.rawData == nil && content.text == nil && content.fileURL == nil && content.imageData == nil) else { return }

        if let existing = findExistingClip(for: content) {
            existing.copiedDate = Date()
            if existing.type == .Images, existing.rawData == nil, let d = content.imageData {
                existing.rawData = d
            }
        } else {
            modelContext.insert(createItem(from: content))
        }

        try? modelContext.save()
    }

    private struct PasteboardContent {
        var type: ClipType
        var text: String?
        var fileURL: URL?
        var imageData: Data?
        var rawData: Data?
    }

    private func extractPasteboardContent(_ pb: NSPasteboard) -> PasteboardContent {
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let url = urls.first, url.isFileURL {
            let t = classifyFileURL(url)
            if t == .Images {
                let imgData = readImageBytesFromFileURL(url)
                return PasteboardContent(type: .Images, text: nil, fileURL: url, imageData: imgData, rawData: nil)
            }
            return PasteboardContent(type: t, text: nil, fileURL: url, imageData: nil, rawData: nil)
        }

        if let img = getImageDataFromPasteboard(pb) {
            return PasteboardContent(type: .Images, text: nil, fileURL: nil, imageData: img, rawData: nil)
        }

        if let s = pb.string(forType: .string), !s.isEmpty {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let u = URL(string: trimmed), let scheme = u.scheme?.lowercased(), (scheme == "http" || scheme == "https"), u.host != nil {
                return PasteboardContent(type: .Links, text: trimmed, fileURL: nil, imageData: nil, rawData: nil)
            }
            return PasteboardContent(type: .Texts, text: s, fileURL: nil, imageData: nil, rawData: nil)
        }

        return PasteboardContent(type: .Unknown, text: nil, fileURL: nil, imageData: nil, rawData: pb.data(forType: pb.types?.first ?? .string))
    }

    private func readImageBytesFromFileURL(_ url: URL) -> Data? {
        if let d = try? Data(contentsOf: url), !d.isEmpty { return d }
        guard let img = NSImage(contentsOf: url) else { return nil }
        return nsImageToPNG(img)
    }

    private func getImageDataFromPasteboard(_ pb: NSPasteboard) -> Data? {
        if let png = pb.data(forType: .png) { return png }
        if let tiff = pb.data(forType: .tiff) { return tiff }
        if let imgs = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let img = imgs.first,
           let tiff = img.tiffRepresentation {
            return tiff
        }
        return nil
    }

    private func nsImageToPNG(_ image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        return png
    }

    private func findExistingClip(for c: PasteboardContent) -> Item? {
        for clip in clips where clip.type == c.type {
            switch c.type {
            case .Texts, .Links:
                if c.text == clip.textCopied { return clip }
            case .Images:
                if let u = c.fileURL, let ex = clip.files, u.standardizedFileURL == ex.standardizedFileURL { return clip }
                if let d = c.imageData, let exd = clip.rawData, d.count == exd.count, d == exd { return clip }
            case .Files, .Documents, .Medias:
                if let u = c.fileURL, let ex = clip.files, u.standardizedFileURL == ex.standardizedFileURL { return clip }
            case .Unknown:
                if let d = c.rawData, let exd = clip.rawData, d == exd { return clip }
            }
        }
        return nil
    }

    private func createItem(from c: PasteboardContent) -> Item {
        Item(type: c.type, textCopied: c.text, files: c.fileURL, rawData: c.imageData ?? c.rawData)
    }

    private func classifyFileURL(_ url: URL) -> ClipType {
        guard let t = UTType(filenameExtension: url.pathExtension) else { return .Files }
        if t.conforms(to: .image) { return .Images }
        if t.conforms(to: .audiovisualContent) { return .Medias }
        if t.conforms(to: .pdf) || t.conforms(to: .spreadsheet) || t.conforms(to: .presentation) || t.conforms(to: .text) { return .Documents }
        return .Files
    }

    private func deleteAllClips() {
        clips.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

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

func imageForClip(_ clip: Item) -> NSImage? {
    if let data = clip.rawData, let img = NSImage(data: data) { return img }
    if let data = clip.rawData, let rep = NSBitmapImageRep(data: data) {
        let img = NSImage(size: rep.size); img.addRepresentation(rep); return img
    }
    if let url = clip.files, let img = NSImage(contentsOf: url) { return img }
    return nil
}

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

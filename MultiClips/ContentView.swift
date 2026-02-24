import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers
internal import Combine

// MARK: - Main Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.copiedDate, order: .reverse) var clips: [Item]
    
    @State private var showDeleteAllAlert = false
    @State private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var showWelcome = false

    var body: some View {
        ZStack{
            if showWelcome {
                WelcomeView(isPresented: $showWelcome)
                    .transition(.opacity)
                    .zIndex(1)
                    .onDisappear {
                        hasSeenWelcome = true
                    }
            }
            NavigationSplitView {
                List {
                    Section("Clips") {
                        NavigationLink {
                            ClipGridView(title: "All Clips", clips: clips)
                        } label: {
                            Label("All Clips", systemImage: "tray.2")
                                .badge(clips.count)
                        }

                        NavigationLink {
                            ClipGridView(title: "Texts", clips: clips.filter { $0.type == .Texts })
                        } label: {
                            Label("Texts", systemImage: "doc.text")
                                .badge(clips.filter { $0.type == .Texts }.count)
                        }

                        NavigationLink {
                            ClipGridView(title: "Images", clips: clips.filter { $0.type == .Images })
                        } label: {
                            Label("Images", systemImage: "photo")
                                .badge(clips.filter { $0.type == .Images }.count)
                        }

                        NavigationLink {
                            ClipGridView(title: "Media", clips: clips.filter { $0.type == .Medias })
                        } label: {
                            Label("Media", systemImage: "play.rectangle")
                                .badge(clips.filter { $0.type == .Medias }.count)
                        }

                        NavigationLink {
                            ClipGridView(title: "Documents", clips: clips.filter { $0.type == .Documents })
                        } label: {
                            Label("Documents", systemImage: "doc")
                                .badge(clips.filter { $0.type == .Documents }.count)
                        }

                        NavigationLink {
                            ClipGridView(title: "Files", clips: clips.filter { $0.type == .Files })
                        } label: {
                            Label("Files", systemImage: "folder")
                                .badge(clips.filter { $0.type == .Files }.count)
                        }

                        NavigationLink {
                            ClipGridView(title: "Links", clips: clips.filter { $0.type == .Links })
                        } label: {
                            Label("Links", systemImage: "link")
                                .badge(clips.filter { $0.type == .Links }.count)
                        }
                    }

                    Section("Home") {
                        NavigationLink {
                            Text("Favorites View")
                        } label: {
                            Label("Favorites", systemImage: "star")
                        }
                    }

                    Section("History") {
                        NavigationLink {
                            HistoryView(clips: clips)
                        } label: {
                            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                        }
                    }

                    Section("Settings") {
                        NavigationLink {
                            Text("General Settings")
                        } label: {
                            Label("General Settings", systemImage: "gearshape")
                        }
                        Toggle(isOn: .constant(true)) {
                            Label("iCloud Sync", systemImage: "icloud")
                        }
                        Button(role: .destructive) {
                            showDeleteAllAlert = true
                        } label: {
                            Label("Clear History", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .alert(
                            "Clear All History?",
                            isPresented: $showDeleteAllAlert
                        ) {
                            Button("Cancel", role: .cancel) {}
                            Button("Delete All", role: .destructive) {
                                deleteAllClips()
                            }
                        } message: {
                            Text("This will permanently delete all \(clips.count) clip\(clips.count == 1 ? "" : "s") from your history. This action cannot be undone.")
                        }
                    }
                }
                .navigationTitle("MultiClips")
            } detail: {
                Text("Select a category from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
        .onReceive(
            Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
        ) { _ in
            checkPasteboard()
        }
        .onAppear {
            lastChangeCount = NSPasteboard.general.changeCount
            showWelcome = true
        }
        
    }

    // MARK: - Pasteboard Monitoring (with deduplication)

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Extract what's on the pasteboard
        let extracted = extractPasteboardContent(pasteboard)

        // Check if an identical clip already exists
        if let existing = findExistingClip(for: extracted) {
            // Just bump it to the top by updating its date
            existing.copiedDate = Date()
        } else {
            // Brand new content — insert it
            let newClip = createItem(from: extracted)
            modelContext.insert(newClip)
        }

        try? modelContext.save()
    }

    // MARK: - Content Extraction (separate from Item creation)

    private struct PasteboardContent {
        var type: ClipType
        var text: String?
        var fileURL: URL?
        var imageData: Data?
        var rawData: Data?
    }

    private func extractPasteboardContent(_ pasteboard: NSPasteboard) -> PasteboardContent {
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = urls.first {
            let clipType = classifyFileURL(firstURL)
            return PasteboardContent(type: clipType, fileURL: firstURL)
        }

        
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            return PasteboardContent(type: .Images, imageData: imageData)
        }

        
        if let string = pasteboard.string(forType: .string) {
            if let url = URL(string: string), url.scheme != nil, url.host != nil {
                return PasteboardContent(type: .Links, text: string)
            }
            return PasteboardContent(type: .Texts, text: string)
        }

        
        let rawData = pasteboard.data(forType: pasteboard.types?.first ?? .string)
        return PasteboardContent(type: .Unknown, rawData: rawData)
    }

    // MARK: - Deduplication: Find Existing Clip

    private func findExistingClip(for content: PasteboardContent) -> Item? {
        for clip in clips {
            
            guard clip.type == content.type else { continue }

            switch content.type {
            case .Texts, .Links:
                
                if let newText = content.text,
                   let existingText = clip.textCopied,
                   newText == existingText {
                    return clip
                }

            case .Images:
                
                if let newData = content.imageData,
                   let existingData = clip.rawData,
                   newData == existingData {
                    return clip
                }

            case .Files, .Documents, .Medias:
                
                if let newURL = content.fileURL,
                   let existingURL = clip.files,
                   newURL == existingURL {
                    return clip
                }

            case .Unknown:
                
                if let newData = content.rawData,
                   let existingData = clip.rawData,
                   newData == existingData {
                    return clip
                }
            }
        }
        return nil
    }

    private func createItem(from content: PasteboardContent) -> Item {
        return Item(
            type: content.type,
            textCopied: content.text,
            files: content.fileURL,
            rawData: content.imageData ?? content.rawData
        )
    }

    // MARK: - Helpers

    private func classifyFileURL(_ url: URL) -> ClipType {
        guard let utType = UTType(filenameExtension: url.pathExtension) else { return .Files }
        if utType.conforms(to: .image)              { return .Images }
        if utType.conforms(to: .audiovisualContent)  { return .Medias }
        if utType.conforms(to: .pdf)
            || utType.conforms(to: .spreadsheet)
            || utType.conforms(to: .presentation)
            || utType.conforms(to: .text)            { return .Documents }
        if utType.conforms(to: .url)                 { return .Links }
        return .Files
    }

    private func deleteAllClips() {
        for clip in clips {
            modelContext.delete(clip)
        }
        try? modelContext.save()
    }
}


// MARK: - 3×N Grid View for a Clip Category
struct ClipGridView: View {
    let title: String
    let clips: [Item]

    @Environment(\.modelContext) private var modelContext

    @State private var selectedClip: Item?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            // ── Main Grid Content ──
            Group {
                if clips.isEmpty {
                    ContentUnavailableView(
                        "No \(title)",
                        systemImage: "clipboard",
                        description: Text("Items you copy will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(clips) { clip in
                                ClipCard(clip: clip)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedClip = clip
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }

            // ── Overlay: Transparent backdrop + Detail Card ──
            if let clip = selectedClip {
                // Full-screen transparent tap target to dismiss
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedClip = nil
                        }
                    }

                // The floating detail card
                ClipDetailSheet(clip: clip, onDelete: {
                    modelContext.delete(clip)
                    try? modelContext.save()
                    withAnimation {
                        selectedClip = nil
                    }
                }, onDismiss: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedClip = nil
                    }
                })
                .frame(width: 500, height: 400)
                .background(.ultraThickMaterial)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .navigationTitle(title)
    }
}


// MARK: - Detail Sheet (dismiss on outside tap or close button)

struct ClipDetailSheet: View {
    let clip: Item
    var onDelete: () -> Void
    var onDismiss: () -> Void

    @State private var showCopiedAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Toolbar: Delete, Copy & Close ──
            HStack {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    copyToPasteboard()
                    showCopiedAlert = true
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label(clip.type.rawValue, systemImage: iconName(for: clip.type))
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(clip.copiedDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    Divider()

                    switch clip.type {
                    case .Texts, .Links:
                        Text(clip.textCopied ?? "No text content")
                            .textSelection(.enabled)
                            .font(.body)

                    case .Images:
                        if let data = clip.rawData, let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                        } else {
                            Text("Unable to display image")
                        }

                    case .Files, .Documents, .Medias:
                        if let url = clip.files {
                            Text(url.absoluteString)
                                .textSelection(.enabled)
                        } else {
                            Text("No file path available")
                        }

                    case .Unknown:
                        Text("Unknown clipboard content")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The clip has been copied to your clipboard.")
        }
        .onExitCommand {
            onDismiss()
        }
    }

    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch clip.type {
        case .Texts, .Links:
            if let text = clip.textCopied {
                pasteboard.setString(text, forType: .string)
            }
        case .Images:
            if let data = clip.rawData {
                pasteboard.setData(data, forType: .png)
            }
        case .Files, .Documents, .Medias:
            if let url = clip.files {
                pasteboard.writeObjects([url as NSURL])
            }
        case .Unknown:
            if let data = clip.rawData {
                pasteboard.setData(data, forType: .string)
            }
        }
    }

    private func iconName(for type: ClipType) -> String {
        switch type {
        case .Texts:     return "doc.text"
        case .Images:    return "photo"
        case .Medias:    return "play.rectangle"
        case .Documents: return "doc"
        case .Files:     return "folder"
        case .Links:     return "link"
        case .Unknown:   return "questionmark.square"
        }
    }
}


// MARK: - Individual Card in the Grid

struct ClipCard: View {
    let clip: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: clip.type))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(clip.copiedDate, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Group {
                switch clip.type {
                case .Texts, .Links:
                    Text(clip.textCopied ?? "Empty")
                        .lineLimit(4)
                        .font(.callout)

                case .Images:
                    if let data = clip.rawData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 60)
                            .clipped()
                            .cornerRadius(6)
                    } else {
                        Text("Image")
                            .font(.callout)
                    }

                case .Files, .Documents, .Medias:
                    Text(clip.files?.lastPathComponent ?? clip.type.rawValue)
                        .lineLimit(2)
                        .font(.callout)

                case .Unknown:
                    Text("Unknown Clip")
                        .font(.callout)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            Text(clip.copiedDate, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func iconName(for type: ClipType) -> String {
        switch type {
        case .Texts:     return "doc.text"
        case .Images:    return "photo"
        case .Medias:    return "play.rectangle"
        case .Documents: return "doc"
        case .Files:     return "folder"
        case .Links:     return "link"
        case .Unknown:   return "questionmark.square"
        }
    }
}



// MARK: - History View (chronological list)

struct HistoryView: View {
    let clips: [Item]

    var body: some View {
        Group {
            if clips.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("Your clipboard history will appear here.")
                )
            } else {
                List(clips) { clip in
                    HStack {
                        Image(systemName: iconName(for: clip.type))
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text(clip.displayTitle)
                                .lineLimit(1)
                            Text(clip.copiedDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Text(clip.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .navigationTitle("History")
    }

    private func iconName(for type: ClipType) -> String {
        switch type {
        case .Texts:     return "doc.text"
        case .Images:    return "photo"
        case .Medias:    return "play.rectangle"
        case .Documents: return "doc"
        case .Files:     return "folder"
        case .Links:     return "link"
        case .Unknown:   return "questionmark.square"
        }
    }
}

struct WelcomeView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                Image(systemName: "clipboard")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.orange)
                    .frame(width: 90, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                Spacer().frame(height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.orange)

                    Text("MultiClips")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

                Spacer().frame(height: 12)

                Text("Your smart clipboard manager. Copy once, access anytime. All your texts, images, files, and links — organized and always at your fingertips.")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 36)

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.orange)

                    Text("Your clipboard data stays on your device and is stored locally using SwiftData. iCloud Sync is optional and can be toggled in Settings. We never collect or share your clipboard content.")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)

                    Button {
                    } label: {
                        Text("See how your data is managed...")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.orange)
                        )
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 30)
            }
            .frame(width: 480, height: 580)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(nsColor: .init(white: 0.12, alpha: 1.0)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
        }
    }
}

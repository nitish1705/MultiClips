import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - Notification name (used by AppDelegate + copy buttons)
extension Notification.Name {
    static let skipNextPasteboardChange = Notification.Name("skipNextPasteboardChange")
    static let openMainWindowRequest = Notification.Name("openMainWindowRequest")
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case orange
    case blue
    case green
    case pink
    case purple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orange: return "Sunset Orange"
        case .blue: return "Ocean Blue"
        case .green: return "Forest Green"
        case .pink: return "Rose Pink"
        case .purple: return "Royal Purple"
        }
    }

    var color: Color {
        switch self {
        case .orange: return .orange
        case .blue: return .blue
        case .green: return .green
        case .pink: return .pink
        case .purple: return .purple
        }
    }
}

struct AppRelease: Identifiable {
    let id = UUID()
    let version: String
    /// Build label shown as a separate chip, e.g. "Build 7". `var` so the memberwise
    /// initialiser still takes it while defaulting to nil for older releases.
    var build: String? = nil
    let date: String
    let highlights: [String]
}

// MARK: - Main Content View
    
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.copiedDate, order: .reverse) var clips: [Item]

    @State private var showDeleteAllAlert = false

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var showWelcome = false

    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = true
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue
    @State private var selectedSidebarItem: String = "clips:All Clips"
        
    @State private var launchAtLogin: Bool = LoginItemManager.isEnabled

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    var body: some View {
        ZStack {
            NavigationSplitView {
                List {
                    Section("Clips") {
                        nav("All Clips", "tray.2", clips)
                        nav("Starred", "star.fill", clips.filter { $0.isStarred })
                        nav("Texts", "doc.text", clips.filter { $0.type == .Texts })
                        nav("Images", "photo", clips.filter { $0.type == .Images })
                        nav("Media", "play.rectangle", clips.filter { $0.type == .Medias })
                        nav("Documents", "doc", clips.filter { $0.type == .Documents })
                        nav("Files", "folder", clips.filter { $0.type == .Files })
                        nav("Links", "link", clips.filter { $0.type == .Links })
                    }

                    Section("History") {
                        Button {
                            selectedSidebarItem = "history:recent"
                        } label: {
                            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(sidebarRowForeground(for: "history:recent"))
                                .tint(sidebarRowForeground(for: "history:recent"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(sidebarRowBackground(for: "history:recent"))
                    }

                    Section("Settings") {
                        Button {
                            selectedSidebarItem = "settings:general"
                        } label: {
                            Label("General Settings", systemImage: "gearshape")
                                .foregroundStyle(sidebarRowForeground(for: "settings:general"))
                                .tint(sidebarRowForeground(for: "settings:general"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(sidebarRowBackground(for: "settings:general"))

                        Picker("Theme", selection: $selectedThemeRaw) {
                            ForEach(ThemeOption.allCases) { theme in
                                Text(theme.title).tag(theme.rawValue)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(sidebarRowBackground(for: "settings:general"))

                        // Every settings row is laid out the same way: icon + text leading,
                        // control trailing. A plain Toggle puts its checkbox first, which
                        // pushed the icon and text out of the column the rest of the sidebar
                        // shares -- hence the leading Label and a labelsHidden control.
                        Picker(selection: $selectedThemeRaw) {
                            ForEach(ThemeOption.allCases) { theme in
                                Text(theme.title).tag(theme.rawValue)
                            }
                        } label: {
                            Label("Theme", systemImage: "paintpalette")
                        }

                        HStack {
                            Label("iCloud Sync", systemImage: "icloud")
                            Spacer(minLength: 8)
                            Toggle("", isOn: $isICloudSyncEnabled)
                                .toggleStyle(.checkbox)
                                .labelsHidden()
                        }

                        HStack {
                            Label("Launch at Login", systemImage: "arrow.clockwise")
                            Spacer(minLength: 8)
                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(.checkbox)
                                .labelsHidden()
                        }
                        .onChange(of: launchAtLogin) { oldValue, newValue in
                            if newValue {
                                LoginItemManager.enable()
                            } else {
                                LoginItemManager.disable()
                            }
                            DispatchQueue.main.async {
                                launchAtLogin = LoginItemManager.isEnabled
                            }
                        }

                        // Outlined button matching Check for Updates -- destructive actions
                        // should look like actions, not like another navigation row.
                        Button(role: .destructive) { showDeleteAllAlert = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Clear History")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                        .listRowBackground(Color.clear)
                        .alert("Clear All History?", isPresented: $showDeleteAllAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Delete All", role: .destructive) { deleteAllClips() }
                        } message: {
                            Text("This will permanently delete all \(clips.count) clip\(clips.count == 1 ? "" : "s").")
                        }
                    }

                    Section("About") {
                        Button {
                            selectedSidebarItem = "about:credits"
                        } label: {
                            Label("Developer / Credits", systemImage: "person.crop.circle")
                                .foregroundStyle(sidebarRowForeground(for: "about:credits"))
                                .tint(sidebarRowForeground(for: "about:credits"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(sidebarRowBackground(for: "about:credits"))

                        Button {
                            selectedSidebarItem = "about:versions"
                        } label: {
                            Label("Version History", systemImage: "clock.badge.checkmark")
                                .foregroundStyle(sidebarRowForeground(for: "about:versions"))
                                .tint(sidebarRowForeground(for: "about:versions"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(sidebarRowBackground(for: "about:versions"))

                        CheckForUpdatesButton(activeTheme: activeTheme)
                            .foregroundStyle(sidebarRowForeground(for: "about:updates"))
                            .tint(sidebarRowForeground(for: "about:updates"))
                            .listRowBackground(sidebarRowBackground(for: "about:updates"))
                    }
                }
                .navigationTitle("MultiClips")
                .tint(activeTheme.color)
            } detail: {
                VStack(spacing: 0) {
                    UpdateBannerView(activeTheme: activeTheme)
                    selectedDetailView
                }
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
        let key = "clips:\(title)"
        Button {
            selectedSidebarItem = key
        } label: {
            Label(title, systemImage: icon)
                .badge(data.count)
                .foregroundStyle(sidebarRowForeground(for: key))
                .tint(sidebarRowForeground(for: key))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(sidebarRowBackground(for: key))
    }

    @ViewBuilder
    private var selectedDetailView: some View {
        switch selectedSidebarItem {
        case "clips:All Clips":
            ClipGridView(title: "All Clips", clips: clips)
        case "clips:Starred":
            ClipGridView(title: "Starred", clips: clips.filter { $0.isStarred })
        case "clips:Texts":
            ClipGridView(title: "Texts", clips: clips.filter { $0.type == .Texts })
        case "clips:Images":
            ClipGridView(title: "Images", clips: clips.filter { $0.type == .Images })
        case "clips:Media":
            ClipGridView(title: "Media", clips: clips.filter { $0.type == .Medias })
        case "clips:Documents":
            ClipGridView(title: "Documents", clips: clips.filter { $0.type == .Documents })
        case "clips:Files":
            ClipGridView(title: "Files", clips: clips.filter { $0.type == .Files })
        case "clips:Links":
            ClipGridView(title: "Links", clips: clips.filter { $0.type == .Links })
        case "history:recent":
            HistoryView(clips: clips)
        case "settings:general":
            Text("General Settings")
        case "about:credits":
            CreditsView()
        case "about:versions":
            VersionHistoryView()
        default:
            ClipGridView(title: "All Clips", clips: clips)
        }
        
    }

    private func sidebarRowBackground(for key: String) -> Color {
        selectedSidebarItem == key ? activeTheme.color.opacity(0.16) : .clear
    }

    private func sidebarRowForeground(for key: String) -> Color {
        selectedSidebarItem == key ? activeTheme.color : .primary
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
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue
    @State private var selectedClip: Item?
    @State private var searchText: String = ""
    @State private var showDuplicates = false
    @State private var duplicateGroups: [[Item]] = []
    @State private var selectedDateRange: (Date, Date)? = nil
    @State private var selectedTypes: Set<ClipType> = Set(ClipType.allCases)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    private var filteredClips: [Item] {
        var result = clips

        // Filter by date range
        if let (startDate, endDate) = selectedDateRange {
            result = result.filter { $0.copiedDate >= startDate && $0.copiedDate <= endDate }
        }

        // Filter by type
        result = result.filter { selectedTypes.contains($0.type) }

        // Search filter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { clip in
                clipMatchesSearch(clip, query: query)
            }
        }

        // Sort: pinned first, then by date
        return result.sorted { a, b in
            if a.isPinned != b.isPinned {
                return a.isPinned
            }
            return a.copiedDate > b.copiedDate
        }
    }

    var body: some View {
        ZStack {
            if filteredClips.isEmpty {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView("No \(title)", systemImage: "clipboard", description: Text("Items you copy will appear here."))
                } else {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different search term."))
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredClips, id: \.id) { clip in
                            ClipCard(clip: clip)
                                .onTapGesture { selectedClip = clip }
                        }
                    }
                    .padding()
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

            if showDuplicates && !duplicateGroups.isEmpty {
                Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { showDuplicates = false }
                DuplicatesDetectionSheet(groups: duplicateGroups, onDismiss: { showDuplicates = false }, modelContext: modelContext)
                    .frame(width: 550, height: 500)
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [activeTheme.color.opacity(0.10), activeTheme.color.opacity(0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(title)
        .searchable(text: $searchText, prompt: "Search clips")
        .toolbar {
            // .secondaryAction lands in the centre of a macOS toolbar, leaving the filter
            // control floating between the title and the search field. .primaryAction puts
            // it on the trailing edge, grouped with search where it belongs.
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Section("Type Filter") {
                        ForEach(ClipType.allCases, id: \.self) { type in
                            Toggle(isOn: Binding(
                                get: { selectedTypes.contains(type) },
                                set: { if $0 { selectedTypes.insert(type) } else { selectedTypes.remove(type) } }
                            )) {
                                Label(type.rawValue, systemImage: iconForType(type))
                            }
                        }
                    }
                    Divider()
                    Button(action: detectDuplicates) {
                        Label("Find Duplicates", systemImage: "doc.on.doc")
                    }
                } label: {
                    Label("Filters", systemImage: "slider.horizontal.3")
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func clipMatchesSearch(_ clip: Item, query: String) -> Bool {
        let q = query.lowercased()
        let note = clip.note?.lowercased() ?? ""
        let text = clip.textCopied?.lowercased() ?? ""
        let fileName = clip.files?.lastPathComponent.lowercased() ?? ""
        let filePath = clip.files?.path.lowercased() ?? ""
        let type = clip.type.rawValue.lowercased()

        return note.contains(q)
            || text.contains(q)
            || fileName.contains(q)
            || filePath.contains(q)
            || type.contains(q)
    }

    private func detectDuplicates() {
        var groups: [[Item]] = []
        var processed = Set<UUID>()

        for clip in clips {
            guard !processed.contains(clip.id) else { continue }
            var duplicates = [clip]
            processed.insert(clip.id)

            for other in clips {
                guard !processed.contains(other.id) else { continue }
                if areDuplicates(clip, other) {
                    duplicates.append(other)
                    processed.insert(other.id)
                }
            }

            if duplicates.count > 1 {
                groups.append(duplicates)
            }
        }

        duplicateGroups = groups
        showDuplicates = !groups.isEmpty
    }

    private func areDuplicates(_ a: Item, _ b: Item) -> Bool {
        guard a.type == b.type else { return false }

        switch a.type {
        case .Texts, .Links:
            return a.textCopied?.lowercased() == b.textCopied?.lowercased()
        case .Images:
            if let u1 = a.files?.standardizedFileURL, let u2 = b.files?.standardizedFileURL {
                return u1 == u2
            }
            return a.rawData == b.rawData
        case .Files, .Documents, .Medias:
            return a.files?.standardizedFileURL == b.files?.standardizedFileURL
        case .Unknown:
            return a.rawData == b.rawData
        }
    }

    private func iconForType(_ type: ClipType) -> String {
        clipIconName(for: Item(type: type))
    }
}
// MARK: - Detail Sheet

struct ClipDetailSheet: View {
    let clip: Item
    var onDelete: () -> Void
    var onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue
    @State private var showCopiedAlert = false
    @State private var noteText: String
    private let noteLimit = 60

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    init(clip: Item, onDelete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.clip = clip
        self.onDelete = onDelete
        self.onDismiss = onDismiss
        _noteText = State(initialValue: clip.note ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash").foregroundColor(.red) }
                    .buttonStyle(.bordered)
                Button(action: togglePin) {
                    Label(clip.isPinned ? "Pinned" : "Pin", systemImage: clip.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(clip.isPinned ? activeTheme.color : .primary)
                }
                .buttonStyle(.bordered)
                Button(action: toggleStar) {
                    Label(clip.isStarred ? "Starred" : "Star", systemImage: clip.isStarred ? "star.fill" : "star")
                        .foregroundStyle(clip.isStarred ? activeTheme.color : .primary)
                }
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tiny Note").font(.caption).foregroundStyle(.secondary)
                        TextField("Add a short note", text: noteBinding)
                            .textFieldStyle(.roundedBorder)
                        Text("\(noteText.count)/\(noteLimit)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
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
        // The sheet had no tint, so .borderedProminent controls in it (Copy) fell back to the
        // system accent instead of the selected theme. Applied at the root so every tinted
        // control in the sheet follows, not just the one that was noticed.
        .tint(activeTheme.color)
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { noteText },
            set: { newValue in
                let trimmed = String(newValue.prefix(noteLimit))
                noteText = trimmed

                let normalized = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
                let savedNote = normalized.isEmpty ? nil : normalized
                if clip.note != savedNote {
                    clip.note = savedNote
                    try? modelContext.save()
                }
            }
        )
    }

    private func togglePin() {
        clip.isPinned.toggle()
        try? modelContext.save()
    }

    private func toggleStar() {
        clip.isStarred.toggle()
        try? modelContext.save()
    }

    private func keepOnlyThisClip() {
        let descriptor = FetchDescriptor<Item>()
        let allClips = (try? modelContext.fetch(descriptor)) ?? []

        for other in allClips where other.id != clip.id {
            if isDuplicate(other, of: clip) {
                modelContext.delete(other)
            }
        }

        clip.isStarred = true
        try? modelContext.save()
    }

    private func isDuplicate(_ other: Item, of current: Item) -> Bool {
        guard other.type == current.type else { return false }

        switch current.type {
        case .Texts, .Links:
            return other.textCopied == current.textCopied
        case .Images:
            if let u1 = other.files?.standardizedFileURL, let u2 = current.files?.standardizedFileURL, u1 == u2 {
                return true
            }
            return other.rawData == current.rawData
        case .Files, .Documents, .Medias:
            return other.files?.standardizedFileURL == current.files?.standardizedFileURL
        case .Unknown:
            return other.rawData == current.rawData
        }
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

// MARK: - Duplicates Detection Sheet

struct DuplicatesDetectionSheet: View {
    let groups: [[Item]]
    var onDismiss: () -> Void
    let modelContext: ModelContext
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Found \(groups.count) Duplicate Group\(groups.count == 1 ? "" : "s")")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group \(index + 1) - \(group.count) duplicates")
                                .font(.subheadline.bold())
                                .foregroundStyle(activeTheme.color)

                            ForEach(group) { clip in
                                HStack {
                                    Image(systemName: "doc.on.doc").foregroundStyle(.secondary)
                                    Text(clip.displayTitle).lineLimit(1)
                                    Spacer()
                                    Button(role: .destructive) {
                                        modelContext.delete(clip)
                                        try? modelContext.save()
                                    } label: {
                                        Image(systemName: "trash").font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(8)
                                .background(.background)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Clip Card

struct ClipCard: View {
    let clip: Item
    @State private var cachedImage: NSImage? = nil // Local state for the async image
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue
    @Environment(\.modelContext) private var modelContext

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName(for: clip)).foregroundStyle(.secondary)
                if clip.isPinned {
                    Image(systemName: "pin.fill").foregroundStyle(activeTheme.color)
                }
                if clip.isStarred {
                    Image(systemName: "star.fill").foregroundStyle(activeTheme.color)
                }
                Spacer()
                Text(relativeTime(for: clip.copiedDate)).font(.caption2).foregroundStyle(.tertiary)
            }

            // Every clip type gets the same content block, sized to four lines of text.
            // Images are clipped into it rather than dictating the card's dimensions --
            // .frame(height:) alone left width unconstrained, so a wide image stretched
            // its whole grid column and made the cards uneven.
            Group {
                switch clip.type {
                case .Texts, .Links:
                    Text(clip.textCopied ?? "Empty").lineLimit(4).font(.callout)
                case .Images:
                    if let img = cachedImage {
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
            .frame(maxWidth: .infinity, minHeight: 72, maxHeight: 72, alignment: .topLeading)
            .clipped()

            if let note = clip.note, !note.isEmpty {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let note = clip.note, !note.isEmpty {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
            HStack {
                Text(clip.copiedDate, style: .date).font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(clip.type.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        // Fixed, not minimum: cards with and without a note must match, and the trailing
        // Spacer(minLength: 0) absorbs the difference so the footer stays pinned.
        .frame(maxWidth: .infinity, minHeight: 172, maxHeight: 172)
        .background(.background)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        .background(
            LinearGradient(
                colors: [activeTheme.color.opacity(0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .task(id: clip.id) {
            if clip.type == .Images && cachedImage == nil {
                cachedImage = imageForClip(clip)
            }
        }
    }

    private func iconName(for clip: Item) -> String {
        clipIconName(for: clip)
    }

    private func relativeTime(for date: Date) -> String {
        relativeClipTime(from: date)
    }
}
// MARK: - Shared Image Helper

func imageForClip(_ clip: Item) -> NSImage? {
    if let data = clip.rawData, let img = NSImage(data: data) { return img }
    if let url = clip.files, let img = NSImage(contentsOf: url) { return img }
    if let data = clip.rawData, let rep = NSBitmapImageRep(data: data) {
        let img = NSImage(size: rep.size); img.addRepresentation(rep); return img
    }
    return nil
}

// MARK: - History View

struct HistoryView: View {
    let clips: [Item]
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    var body: some View {
        List(clips) { clip in
            HStack {
                Text(clip.displayTitle).lineLimit(1)
                Spacer()
                Text(relativeClipTime(from: clip.copiedDate)).font(.caption).foregroundStyle(activeTheme.color.opacity(0.9))
            }
            .listRowBackground(Color.clear);
        }
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [activeTheme.color.opacity(0.10), activeTheme.color.opacity(0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("History")
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    @Binding var isPresented: Bool
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack {
                Text("Welcome to MultiClips").font(.title.bold()).foregroundStyle(activeTheme.color)
                Button("Continue") { isPresented = false }
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(activeTheme.color))
                    .foregroundStyle(.white)
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
    
    @Environment(\.openWindow) private var openWindow
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue
    @State private var selectedClipForActionsID: UUID?

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "clipboard.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(activeTheme.color)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(activeTheme.color.opacity(0.20))
                        )
                    Text("MultiClips").font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
                }

                Divider()

                if clips.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clipboard").font(.largeTitle).foregroundStyle(.secondary)
                        Text("No clips yet").foregroundStyle(.secondary)
                        Text("Copy something to get started").font(.caption).foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 100)
                } else {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(clips.prefix(30)) { clip in
                                MenuBarClipRow(
                                    clip: clip,
                                    onCopy: { copyClipToPasteboard(clip) },
                                    onOpenActions: { selectedClipForActionsID = clip.id },
                                    onToggleStar: { toggleStar(clip) },
                                    themeColor: activeTheme.color
                                )
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    .frame(height: min(CGFloat(clips.count) * 52 + 20, 280))
                }

                Divider()

                // Clear History intentionally lives only in the main window sidebar, where it is
                // gated behind a confirm alert. One-click bulk delete does not belong in a menu bar.
                HStack(spacing: 4) {
                    footerButton(icon: "arrow.up.forward.app", label: "Open") {
                        NotificationCenter.default.post(name: .openMainWindowRequest, object: nil)
                        openWindow(id: "main-window")
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }

                    footerButton(icon: "power", label: "Quit", tint: .red) {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.top, 4)
                .padding(.bottom, 5)
                .background(.regularMaterial)
            }
            .frame(width: 300)

            if let id = selectedClipForActionsID,
               let clip = clips.first(where: { $0.id == id }) {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture { selectedClipForActionsID = nil }

                MenuBarClipActionsSheet(
                    clip: clip,
                    onToggleStar: { toggleStar(clip) },
                    onSaveNote: { note in saveNote(note, for: clip) },
                    themeColor: activeTheme.color,
                    onClose: { selectedClipForActionsID = nil }
                )
                .background(.regularMaterial)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            }
        }
        .tint(activeTheme.color)
    }

    @ViewBuilder
    private func footerButton(
        icon: String,
        label: String,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.caption2)
            }
            // tint on the VStack so glyph *and* label colour together
            .foregroundStyle(tint ?? .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private func toggleStar(_ clip: Item) {
        clip.isStarred.toggle()
        try? modelContext.save()
    }

    private func saveNote(_ note: String, for clip: Item) {
        let normalized = note.trimmingCharacters(in: .whitespacesAndNewlines)
        clip.note = normalized.isEmpty ? nil : String(normalized.prefix(60))
        try? modelContext.save()
    }
}

// MARK: - Menu Bar Clip Row

struct MenuBarClipRow: View {
    let clip: Item
    let onCopy: () -> Void
    let onOpenActions: () -> Void
    let onToggleStar: () -> Void
    let themeColor: Color
    @State private var isHovered = false

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: 10) {
                Image(systemName: iconName(for: clip))
                    .font(.system(size: 14)).foregroundStyle(.secondary).frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(clipPreview).font(.callout).lineLimit(1).truncationMode(.tail)
                    if let note = clip.note, !note.isEmpty {
                        Text(note).font(.caption2).lineLimit(1).foregroundStyle(.secondary)
                    } else {
                        Text(relativeClipTime(from: clip.copiedDate)).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                // Actions stay out of the way until the row is hovered. Opacity goes on each
                // button separately, never the HStack, so a starred clip keeps its star at rest.
                HStack(spacing: 4) {
                    Button(action: onToggleStar) {
                        Image(systemName: clip.isStarred ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundStyle(clip.isStarred ? themeColor : themeColor.opacity(0.28))
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered || clip.isStarred ? 1 : 0)
                    .allowsHitTesting(isHovered || clip.isStarred)

                    Button(action: onOpenActions) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(isHovered)
                }
                .animation(.easeOut(duration: 0.18), value: isHovered)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isHovered ? themeColor.opacity(0.16) : Color.clear)
            .cornerRadius(6).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Copy") {
                onCopy()
            }

            Button("Open Actions") {
                onOpenActions()
            }
        }
        .simultaneousGesture(
            TapGesture().modifiers(.control).onEnded {
                onOpenActions()
            }
        )
    }

    private var clipPreview: String {
        switch clip.type {
        case .Texts, .Links: return clip.textCopied ?? "Empty"
        case .Images: return clip.files != nil ? "🖼 \(clip.files!.lastPathComponent)" : "Screenshot"
        case .Files, .Documents, .Medias: return clip.files?.lastPathComponent ?? clip.type.rawValue
        case .Unknown: return "Unknown Clip"
        }
    }

    private func iconName(for clip: Item) -> String {
        clipIconName(for: clip)
    }
}

struct MenuBarClipActionsSheet: View {
    let clip: Item
    let onToggleStar: () -> Void
    let onSaveNote: (String) -> Void
    let themeColor: Color
    let onClose: () -> Void
    @State private var noteText: String

    init(clip: Item, onToggleStar: @escaping () -> Void, onSaveNote: @escaping (String) -> Void, themeColor: Color, onClose: @escaping () -> Void) {
        self.clip = clip
        self.onToggleStar = onToggleStar
        self.onSaveNote = onSaveNote
        self.themeColor = themeColor
        self.onClose = onClose
        _noteText = State(initialValue: clip.note ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                Text("Clip Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            Button(action: onToggleStar) {
                HStack(spacing: 10) {
                    Image(systemName: clip.isStarred ? "star.fill" : "star")
                        .foregroundStyle(clip.isStarred ? themeColor : .secondary)
                        .font(.system(size: 14))
                    Text(clip.isStarred ? "Unstar" : "Star")
                        .font(.callout)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                TextField("Add a short note…", text: $noteText)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout)
                    .padding(.horizontal, 14)
                    .onSubmit {
                        onSaveNote(noteText)
                        onClose()
                    }

                HStack(spacing: 8) {
                    Spacer()
                    Button("Cancel") { onClose() }
                        .font(.callout)
                        .buttonStyle(.bordered)
                    Button("Save") {
                        onSaveNote(noteText)
                        onClose()
                    }
                    .font(.callout)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .padding(.top, 4)
            }
        }
        .frame(width: 260)
        .fixedSize()
    }
}

// MARK: - Credits View

struct CreditsView: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    private let developerName = "Nitish"
    private let githubURL = "https://github.com/nitish1705"
    private let linkedInURL = "https://www.linkedin.com/in/nitish--m"

    /// Read from the bundle rather than hardcoded, so it cannot drift from the build.
    private var versionLabel: String {
        "v\(UpdateManager.shared.currentVersion) (Build \(UpdateManager.shared.currentBuildNumber))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock

                VStack(spacing: 9) {
                    socialLinkRow(
                        title: "GitHub Profile",
                        subtitle: "github.com/nitish1705",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        destination: githubURL
                    )

                    socialLinkRow(
                        title: "LinkedIn Profile",
                        subtitle: "linkedin.com/in/nitish--m",
                        systemImage: "person.2.fill",
                        destination: linkedInURL
                    )

                    updatesRow
                }

                aboutBlock
                    .padding(.top, 26)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [activeTheme.color.opacity(0.10), activeTheme.color.opacity(0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Credits")
        .tint(activeTheme.color)
    }

    private var heroBlock: some View {
        VStack(spacing: 0) {
            Text(String(developerName.prefix(1)))
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(activeTheme.color)
                .frame(width: 78, height: 78)
                .background(Circle().fill(activeTheme.color.opacity(0.16)))
                .overlay(Circle().stroke(activeTheme.color.opacity(0.30), lineWidth: 1))
                .overlay(Circle().stroke(activeTheme.color.opacity(0.07), lineWidth: 7).scaleEffect(1.18))
                .padding(.bottom, 15)

            Text(developerName)
                .font(.system(size: 22, weight: .bold))
                .padding(.bottom, 4)

            Text("Developer & maintainer, MultiClips")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text("Built with SwiftUI and SwiftData for macOS")
                .font(.system(size: 11.5))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
    }

    private var aboutBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT THIS APP")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.tertiary)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 1), GridItem(.flexible(), spacing: 1)],
                spacing: 1
            ) {
                factCell("Version", versionLabel)
                factCell("Requires", "macOS 14.6 or later")
                factCell("Storage", "SwiftData, on-device")
                factCell("Licence", "MIT")
            }
            .background(Color.primary.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func factCell(_ key: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(key).font(.system(size: 10.5)).foregroundStyle(.tertiary)
            Text(value).font(.system(size: 12.5, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func socialLinkRow(title: String, subtitle: String, systemImage: String, destination: String) -> some View {
        Link(destination: URL(string: destination)!) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(activeTheme.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var updatesRow: some View {
        Button {
            updateManager.checkForUpdates(isManualCheck: true)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(activeTheme.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(updateManager.isChecking ? "Checking for Updates..." : "Check for Updates")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(updateManager.updateAvailable ? "New version available!" : "You are on the latest build (\(versionLabel))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if updateManager.isChecking {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.09), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(updateManager.isChecking || updateManager.isDownloading)
    }
}

// MARK: - Version History View

struct VersionHistoryView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw = ThemeOption.orange.rawValue

    private var activeTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .orange
    }

    /// Highlights are hand-maintained; the newest entry's build number is read from the
    /// bundle so it cannot drift. `build.sh` bumps CURRENT_PROJECT_VERSION on every run,
    /// which is exactly how a hardcoded label goes stale.
    /// Stays a stored property: a computed one would regenerate each AppRelease's `id`
    /// on every render and break ForEach identity.
    private let releases: [AppRelease] = [
        AppRelease(
            version: "v2.2",
            build: "Build \(UpdateManager.shared.currentBuildNumber)",
            date: "3 Aug 2026",
            highlights: [
                "Redesigned UI: modern menu bar dropdown, release cards for Version History, and redesigned Credits view",
                "Fixed window background transparency across dark/light themes",
                "Fixed update banner notifications and network sandbox permissions"
            ]
        ),
        AppRelease(
            version: "v2.1",
            build: "Build 9",
            date: "3 Aug 2026",
            highlights: [
                "Redesigned menu bar with actions that appear on hover",
                "Version History rebuilt as release cards",
                "Credits page redesigned with app details",
                "Fixed theme tint letting the desktop show through windows"
            ]
        ),
        AppRelease(
            version: "v2.0",
            build: "Build 7",
            date: "3 Aug 2026",
            highlights: [
                "Ad-hoc code signing to prevent 'damaged app' errors",
                "Fixed DMG installation issues on macOS",
                "Auto-updater with one-click updates",
                "Build number tracking for accurate update detection"
            ]
        ),
        AppRelease(
            version: "v1.2.1",
            date: "26 Mar 2026",
            highlights: [
                "Per-clip actions from menu icon bar rows",
                "Three-dots action dialog with Star and Add Text (Note)",
                "Main app navbar quick note input removed",
                "Clip row click now opens actions dialog in icon bar"
            ]
        ),
        AppRelease(
            version: "v1.2.0",
            date: "26 Mar 2026",
            highlights: [
                "Clip search with live filtering across clip content",
                "Tiny note support per clip",
                "Quick add text option in the top bar",
                "App now opens with All Clips by default"
            ]
        ),
        AppRelease(
            version: "v1.1.0",
            date: "19 Mar 2026",
            highlights: [
                "Theme customization with multiple color options",
                "Credits page and release tracking screen",
                "Improved contextual icons and relative-time labels",
                "Menu bar open-window behavior improvements"
            ]
        ),
        AppRelease(
            version: "v1.0.0",
            date: "Initial Release",
            highlights: [
                "Clipboard history for text, files, and images",
                "Menu bar quick-copy access",
                "Local persistence with SwiftData"
            ]
        )
    ]

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width >= 700

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(Array(releases.enumerated()), id: \.element.id) { index, release in
                        releaseCard(release, isLatest: index == 0, isWide: isWide)
                    }
                }
                .padding(22)
            }
        }
        .background(
            LinearGradient(
                colors: [activeTheme.color.opacity(0.10), activeTheme.color.opacity(0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Version History")
        .tint(activeTheme.color)
    }

    @ViewBuilder
    private func releaseCard(_ release: AppRelease, isLatest: Bool, isWide: Bool) -> some View {
        let columns = isWide
            ? [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)]
            : [GridItem(.flexible(), alignment: .topLeading)]

        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(release.version)
                    .font(.system(size: 21, weight: .bold))
                    .tracking(-0.4)

                if let build = release.build {
                    Text(build)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                }

                if isLatest {
                    Text("LATEST")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(activeTheme.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(activeTheme.color.opacity(0.18)))
                }

                Spacer(minLength: 8)

                Text(release.date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(release.highlights, id: \.self) { point in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(activeTheme.color)
                            .padding(.top, 1)
                        // body copy stays .primary — the accent marks structure, not every word
                        Text(point)
                            .font(.system(size: 12.5))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 17)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isLatest ? activeTheme.color.opacity(0.07) : Color.primary.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isLatest ? activeTheme.color.opacity(0.28) : Color.primary.opacity(0.09),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [activeTheme.color, activeTheme.color.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .opacity(isLatest ? 1 : 0.35)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Shared Helpers

func relativeClipTime(from date: Date, now: Date = Date()) -> String {
    let seconds = Int(now.timeIntervalSince(date))
    if seconds < 0 { return "just now" }
    if seconds < 60 { return "\(seconds) sec ago" }

    let minutes = seconds / 60
    if minutes <= 30 {
        return "\(minutes) min ago"
    }

    return date.formatted(date: .omitted, time: .shortened)
}

func clipIconName(for clip: Item) -> String {
    switch clip.type {
    case .Texts:
        return "textformat"
    case .Images:
        return "photo"
    case .Links:
        return "link"
    case .Documents:
        return "doc.text"
    case .Medias:
        return "play.rectangle"
    case .Files:
        if let url = clip.files {
            return iconForFileURL(url)
        }
        return "doc"
    case .Unknown:
        return "questionmark.square"
    }
}

func iconForFileURL(_ url: URL) -> String {
    guard let type = UTType(filenameExtension: url.pathExtension) else {
        return "doc"
    }

    if type.conforms(to: .pdf) { return "doc.richtext" }
    if type.conforms(to: .spreadsheet) { return "tablecells" }
    if type.conforms(to: .presentation) { return "display" }
    if type.conforms(to: .archive) { return "archivebox" }
    if type.conforms(to: .audio) { return "music.note" }
    if type.conforms(to: .movie) { return "film" }
    if type.conforms(to: .image) { return "photo" }
    if type.conforms(to: .text) { return "doc.text" }

    return "doc"
}

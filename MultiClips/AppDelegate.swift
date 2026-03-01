import AppKit
import SwiftData
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {

    var modelContainer: ModelContainer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var skipNextPasteboardChange = false
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        lastChangeCount = NSPasteboard.general.changeCount

        // Listen for skip notifications from copy buttons
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSkipNotification),
            name: .skipNextPasteboardChange,
            object: nil
        )

        // Start the pasteboard monitoring timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    @objc private func handleSkipNotification() {
        skipNextPasteboardChange = true
    }

    // MARK: - Pasteboard Monitoring

    @MainActor
    private func checkPasteboard() {
        guard let container = modelContainer else { return }

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

        let context = container.mainContext

        // Fetch existing clips for dedup
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.copiedDate, order: .reverse)])
        let existingClips = (try? context.fetch(descriptor)) ?? []

        if let existing = findExistingClip(in: existingClips, for: content) {
            existing.copiedDate = Date()
            if existing.type == .Images, existing.rawData == nil, let d = content.imageData {
                existing.rawData = d
            }
        } else {
            context.insert(createItem(from: content))
        }

        try? context.save()
    }

    // MARK: - Content Extraction

    struct PasteboardContent {
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
            if let u = URL(string: trimmed), let scheme = u.scheme?.lowercased(),
               (scheme == "http" || scheme == "https"), u.host != nil {
                return PasteboardContent(type: .Links, text: trimmed, fileURL: nil, imageData: nil, rawData: nil)
            }
            return PasteboardContent(type: .Texts, text: s, fileURL: nil, imageData: nil, rawData: nil)
        }

        return PasteboardContent(type: .Unknown, text: nil, fileURL: nil, imageData: nil,
                                 rawData: pb.data(forType: pb.types?.first ?? .string))
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
           let img = imgs.first, let tiff = img.tiffRepresentation {
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

    // MARK: - Deduplication

    private func findExistingClip(in clips: [Item], for c: PasteboardContent) -> Item? {
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

    // MARK: - Window Management

    func showMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        for window in NSApplication.shared.windows {
            if window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        for window in NSApplication.shared.windows where window.className.contains("SwiftUI") {
            window.makeKeyAndOrderFront(nil)
            return
        }

        if let mainMenu = NSApplication.shared.mainMenu,
           let fileMenu = mainMenu.item(at: 1)?.submenu {
            for item in fileMenu.items {
                if item.keyEquivalent == "n" && item.keyEquivalentModifierMask.contains(.command) {
                    NSApplication.shared.sendAction(item.action!, to: item.target, from: nil)
                    return
                }
            }
        }
    }
}

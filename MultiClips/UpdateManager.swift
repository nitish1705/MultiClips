import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - GitHub Release Data Models

struct GitHubRelease: Codable, Identifiable {
    var id: Int
    let tagName: String
    let name: String?
    let body: String?
    let htmlUrl: String
    let publishedAt: String?
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

struct GitHubAsset: Codable, Identifiable {
    var id: Int
    let name: String
    let browserDownloadUrl: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

// MARK: - Version & Build Info Helper

struct AppVersionInfo: Equatable {
    let versionComponents: [Int]
    let buildNumber: Int
    let rawVersionString: String

    var displayString: String {
        "v\(rawVersionString) (Build \(buildNumber))"
    }
}

// MARK: - Update Manager

private let kLastUpdateCheckKey = "lastUpdateCheckAt"

@MainActor
final class UpdateManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = UpdateManager()

    private let repoOwner = "nitish1705"
    private let repoName = "MultiClips"

    @Published var isChecking: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var latestRelease: GitHubRelease? = nil
    @Published var latestVersionInfo: AppVersionInfo? = nil
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading: Bool = false
    @Published var isInstalling: Bool = false
    @Published var errorMessage: String? = nil
    @Published var upToDateMessageShown: Bool = false

    /// When the last check *completed* — success or failure. Persisted so relaunching twice in
    /// quick succession does not re-hit the API. Published so the sidebar can show "Checked N ago".
    /// Seeded inline rather than in an init, which NSObject + @MainActor makes awkward.
    @Published private(set) var lastUpdateCheckAt: Date? = {
        let stored = UserDefaults.standard.double(forKey: kLastUpdateCheckKey)
        return stored > 0 ? Date(timeIntervalSince1970: stored) : nil
    }()

    /// Separate from `updateAvailable`, which is a fact about the world and must survive a
    /// dismissal. This is view state: it hides the banner until the window is opened again.
    @Published var bannerDismissed: Bool = false

    private let checkInterval: TimeInterval = 5 * 60

    private var downloadTask: URLSessionDownloadTask?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
    }

    var currentBuildNumber: Int {
        let buildStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return Int(buildStr.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1
    }

    var currentVersionInfo: AppVersionInfo {
        AppVersionInfo(
            versionComponents: normalizeVersion(currentVersion),
            buildNumber: currentBuildNumber,
            rawVersionString: currentVersion
        )
    }

    // MARK: - Check for Updates

    /// Pure, so the 5-minute rule can be tested without a clock or UserDefaults.
    /// See `Tests/VersionLogicTests.swift`.
    static func isCheckStale(lastCheck: Date?, now: Date, interval: TimeInterval) -> Bool {
        guard let lastCheck else { return true }
        let elapsed = now.timeIntervalSince(lastCheck)
        // A negative elapsed means the stored date is in the future — clock skew, or the user
        // moved their clock back. Treat that as fresh rather than checking on every open.
        guard elapsed >= 0 else { return false }
        return elapsed >= interval
    }

    /// Entry point for automatic checks. Called whenever the main window opens.
    /// Always un-dismisses the banner, so an available update reappears even when the check
    /// itself is skipped for being too recent.
    func checkForUpdatesIfStale() {
        bannerDismissed = false
        guard Self.isCheckStale(lastCheck: lastUpdateCheckAt, now: Date(), interval: checkInterval)
        else { return }
        checkForUpdates(isManualCheck: false)
    }

    /// Recorded on every completed attempt, including failures — otherwise a dropped network
    /// would re-fire a request on every single window open.
    private func recordCheckCompleted() {
        let now = Date()
        lastUpdateCheckAt = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: kLastUpdateCheckKey)
    }

    func checkForUpdates(isManualCheck: Bool = false) {
        guard !isChecking && !isDownloading else { return }

        isChecking = true
        errorMessage = nil
        if isManualCheck {
            upToDateMessageShown = false
        }

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            errorMessage = "Invalid release API URL."
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("MultiClips-App/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "UpdateManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response."])
                }

                if httpResponse.statusCode == 404 {
                    self.isChecking = false
                    self.recordCheckCompleted()
                    // 404 means the repo has no published releases at all, which is not the
                    // same as being current — say so rather than implying you are up to date.
                    if isManualCheck {
                        self.errorMessage = "No published releases found for this repository."
                    }
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "UpdateManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "GitHub API returned status \(httpResponse.statusCode)."])
                }

                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let remoteInfo = self.parseReleaseVersion(tag: release.tagName, body: release.body)

                self.latestRelease = release
                self.latestVersionInfo = remoteInfo

                let isNewer = self.isUpdateNewer(remote: remoteInfo, local: self.currentVersionInfo)

                self.isChecking = false
                self.recordCheckCompleted()
                if isNewer {
                    self.updateAvailable = true
                    self.bannerDismissed = false
                    self.upToDateMessageShown = false
                } else {
                    self.updateAvailable = false
                    if isManualCheck {
                        self.upToDateMessageShown = true
                    }
                }
            } catch {
                self.isChecking = false
                self.recordCheckCompleted()
                if isManualCheck {
                    self.errorMessage = "Failed to check for updates: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Download & Install

    func downloadAndInstallUpdate() {
        guard let release = latestRelease else { return }

        guard let zipAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".zip") }) ?? release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) else {
            if let webURL = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(webURL)
            }
            return
        }

        guard let downloadURL = URL(string: zipAsset.browserDownloadUrl) else {
            errorMessage = "Invalid asset download URL."
            return
        }

        isDownloading = true
        downloadProgress = 0.0
        errorMessage = nil

        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)

        downloadTask = session.downloadTask(with: downloadURL)
        downloadTask?.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0.0
    }

    // MARK: - URLSessionDownloadDelegate

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.downloadProgress = progress
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let destinationURL = tempDir.appendingPathComponent("UpdatePackage.zip")
            try FileManager.default.moveItem(at: location, to: destinationURL)

            Task { @MainActor in
                self.isDownloading = false
                self.isInstalling = true
                self.installUpdate(packageURL: destinationURL, in: tempDir)
            }
        } catch {
            Task { @MainActor in
                self.isDownloading = false
                self.errorMessage = "Failed to process update package: \(error.localizedDescription)"
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            Task { @MainActor in
                self.isDownloading = false
                self.errorMessage = "Download error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Installation Execution

    private func installUpdate(packageURL: URL, in tempDir: URL) {
        let extractedAppDir = tempDir.appendingPathComponent("Extracted")

        do {
            try FileManager.default.createDirectory(at: extractedAppDir, withIntermediateDirectories: true)

            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzipProcess.arguments = ["-x", "-k", packageURL.path, extractedAppDir.path]
            try unzipProcess.run()
            unzipProcess.waitUntilExit()

            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: extractedAppDir, includingPropertiesForKeys: nil)
            guard let appBundleURL = contents.first(where: { $0.pathExtension == "app" }) else {
                errorMessage = "Could not find valid MultiClips.app inside update archive."
                isInstalling = false
                return
            }

            let currentBundlePath = Bundle.main.bundlePath
            let scriptPath = tempDir.appendingPathComponent("relaunch.sh").path

            let scriptContent = """
            #!/bin/bash
            sleep 1
            rm -rf "\(currentBundlePath)"
            cp -R "\(appBundleURL.path)" "\(currentBundlePath)"
            xattr -dr com.apple.quarantine "\(currentBundlePath)" 2>/dev/null || true
            open "\(currentBundlePath)"
            """

            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)

            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", scriptPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()

            let relaunchProcess = Process()
            relaunchProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
            relaunchProcess.arguments = [scriptPath]
            try relaunchProcess.run()

            NSApp.terminate(nil)

        } catch {
            errorMessage = "Installation failed: \(error.localizedDescription)"
            isInstalling = false
        }
    }

    // MARK: - Version & Build Parsing Logic

    func parseReleaseVersion(tag: String, body: String?) -> AppVersionInfo {
        let cleanTag = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

        var versionStr = cleanTag
        var buildNum = 1
        var buildFound = false

        let pattern = #"(?i)^([0-9\.]+)[-_\+](?:b|build)?\s*([0-9]+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: cleanTag, range: NSRange(cleanTag.startIndex..., in: cleanTag)) {

            if let vRange = Range(match.range(at: 1), in: cleanTag) {
                versionStr = String(cleanTag[vRange])
            }
            if let bRange = Range(match.range(at: 2), in: cleanTag), let bVal = Int(cleanTag[bRange]) {
                buildNum = bVal
                buildFound = true
            }
        }

        if !buildFound, let bodyText = body {
            // "Build 7", "Build Number: 7", "build: 7" and "Build num 7" must all parse.
            // The word/colon separator is optional; \b stops this matching inside "rebuild".
            let bodyPattern = #"(?i)\bbuild\s*(?:number|num)?\s*:?\s*([0-9]+)"#
            if let bodyRegex = try? NSRegularExpression(pattern: bodyPattern),
               let match = bodyRegex.firstMatch(in: bodyText, range: NSRange(bodyText.startIndex..., in: bodyText)),
               let bRange = Range(match.range(at: 1), in: bodyText),
               let bVal = Int(bodyText[bRange]) {
                buildNum = bVal
            }
        }

        return AppVersionInfo(
            versionComponents: normalizeVersion(versionStr),
            buildNumber: buildNum,
            rawVersionString: versionStr
        )
    }

    func normalizeVersion(_ versionString: String) -> [Int] {
        var cleaned = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        let components = cleaned.split(separator: ".").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        var result = components
        while result.count < 3 {
            result.append(0)
        }
        return result
    }

    func isUpdateNewer(remote: AppVersionInfo, local: AppVersionInfo) -> Bool {
        let maxCount = max(remote.versionComponents.count, local.versionComponents.count)
        for i in 0..<maxCount {
            let rVal = i < remote.versionComponents.count ? remote.versionComponents[i] : 0
            let lVal = i < local.versionComponents.count ? local.versionComponents[i] : 0

            if rVal > lVal {
                return true
            } else if rVal < lVal {
                return false
            }
        }

        return remote.buildNumber > local.buildNumber
    }
}

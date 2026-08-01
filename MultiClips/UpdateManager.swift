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

    var cleanVersion: String {
        tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
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

// MARK: - Update Manager

@MainActor
final class UpdateManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = UpdateManager()

    private let repoOwner = "nitish1705"
    private let repoName = "MultiClips"

    @Published var isChecking: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var latestRelease: GitHubRelease? = nil
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading: Bool = false
    @Published var isInstalling: Bool = false
    @Published var errorMessage: String? = nil
    @Published var upToDateMessageShown: Bool = false

    private var downloadTask: URLSessionDownloadTask?
    private var downloadObservation: NSKeyValueObservation?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Check for Updates

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
                    // No releases published yet on GitHub
                    self.isChecking = false
                    if isManualCheck {
                        self.upToDateMessageShown = true
                    }
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "UpdateManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "GitHub API returned status \(httpResponse.statusCode)."])
                }

                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                self.latestRelease = release

                let isNewer = self.compareVersions(latest: release.cleanVersion, current: self.currentVersion) == .orderedDescending

                self.isChecking = false
                if isNewer {
                    self.updateAvailable = true
                    self.upToDateMessageShown = false
                } else if isManualCheck {
                    self.updateAvailable = false
                    self.upToDateMessageShown = true
                }
            } catch {
                self.isChecking = false
                if isManualCheck {
                    self.errorMessage = "Failed to check for updates: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Download & Install

    func downloadAndInstallUpdate() {
        guard let release = latestRelease else { return }

        // Find zip asset first, or dmg asset
        guard let zipAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".zip") }) ?? release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) else {
            // If no binary asset found in release, open release web page in browser
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
        // Move downloaded file to a stable temp directory
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

            // Extract zip via ditto
            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzipProcess.arguments = ["-x", "-k", packageURL.path, extractedAppDir.path]
            try unzipProcess.run()
            unzipProcess.waitUntilExit()

            // Find .app inside extracted folder
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: extractedAppDir, includingPropertiesForKeys: nil)
            guard let appBundleURL = contents.first(where: { $0.pathExtension == "app" }) else {
                errorMessage = "Could not find valid MultiClips.app inside update archive."
                isInstalling = false
                return
            }

            let currentBundlePath = Bundle.main.bundlePath
            let scriptPath = tempDir.appendingPathComponent("relaunch.sh").path

            // Relaunch helper script
            let scriptContent = """
            #!/bin/bash
            sleep 1
            rm -rf "\(currentBundlePath)"
            cp -R "\(appBundleURL.path)" "\(currentBundlePath)"
            xattr -dr com.apple.quarantine "\(currentBundlePath)" 2>/dev/null || true
            open "\(currentBundlePath)"
            """

            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)

            // Make script executable
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", scriptPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()

            // Launch script in background
            let relaunchProcess = Process()
            relaunchProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
            relaunchProcess.arguments = [scriptPath]
            try relaunchProcess.run()

            // Exit current app instance
            NSApp.terminate(nil)

        } catch {
            errorMessage = "Installation failed: \(error.localizedDescription)"
            isInstalling = false
        }
    }

    // MARK: - Version Helper

    func compareVersions(latest: String, current: String) -> ComparisonResult {
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(latestComponents.count, currentComponents.count)

        for i in 0..<maxLength {
            let lVal = i < latestComponents.count ? latestComponents[i] : 0
            let cVal = i < currentComponents.count ? currentComponents[i] : 0

            if lVal > cVal {
                return .orderedDescending
            } else if lVal < cVal {
                return .orderedAscending
            }
        }

        return .orderedSame
    }
}

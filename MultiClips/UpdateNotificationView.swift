import SwiftUI

struct UpdateBannerView: View {
    @ObservedObject var updateManager = UpdateManager.shared
    let activeTheme: ThemeOption

    /// GitHub release bodies are block markdown, but SwiftUI's `Text` only understands the
    /// inline subset — headings and list markers would render as literal "###" and "-".
    /// Flatten those to plain text first, then let AttributedString handle **bold**, `code`
    /// and links. Falls back to the raw string if the markdown fails to parse.
    private func renderedReleaseNotes(_ raw: String) -> AttributedString {
        let flattened = raw
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                var s = String(line)
                s = s.replacingOccurrences(of: #"^\s*#{1,6}\s+"#, with: "", options: .regularExpression)
                s = s.replacingOccurrences(of: #"^(\s*)[-*+]\s+"#, with: "$1• ", options: .regularExpression)
                return s
            }
            .joined(separator: "\n")

        return (try? AttributedString(
            markdown: flattened,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(flattened)
    }

    /// Small mono chip, matching the build chip on the Version History release cards.
    @ViewBuilder
    private func versionChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 5).fill(.quaternary))
    }

    var body: some View {
        // The transitions below only play if an animated container owns the conditional.
        // Without this Group the banner popped in and out instantly.
        Group {
            bannerContent
        }
        // Low damping gives the slight overshoot that reads as a toast dropping in.
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: updateManager.updateAvailable)
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: updateManager.bannerDismissed)
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: updateManager.upToDateMessageShown)
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: updateManager.errorMessage)
        .animation(.easeInOut(duration: 0.2), value: updateManager.isDownloading)
        .animation(.easeInOut(duration: 0.2), value: updateManager.isInstalling)
    }

    @ViewBuilder
    private var bannerContent: some View {
        if updateManager.updateAvailable, !updateManager.bannerDismissed,
           let release = updateManager.latestRelease {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(activeTheme.color)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(activeTheme.color.opacity(0.20))
                        )

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Update available")
                            .font(.system(size: 14, weight: .semibold))

                        HStack(spacing: 6) {
                            versionChip(updateManager.latestVersionInfo?.displayString ?? release.tagName)
                            Image(systemName: "arrow.left")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                            versionChip(updateManager.currentVersionInfo.displayString)
                        }
                    }

                    Spacer()

                    Button {
                        updateManager.bannerDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(5)
                            .background(Circle().fill(.quaternary))
                    }
                    .buttonStyle(.plain)
                }

                if let bodyText = release.body, !bodyText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RELEASE HIGHLIGHTS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.tertiary)

                        ScrollView {
                            Text(renderedReleaseNotes(bodyText))
                                .font(.system(size: 12))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(maxHeight: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.quaternary)
                        )
                    }
                }

                if updateManager.isDownloading {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Downloading update...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(updateManager.downloadProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(activeTheme.color)
                        }
                        ProgressView(value: updateManager.downloadProgress)
                            .tint(activeTheme.color)
                            // Without this the bar jumps between URLSession's progress
                            // callbacks instead of sliding.
                            .animation(.linear(duration: 0.18), value: updateManager.downloadProgress)
                    }
                } else if updateManager.isInstalling {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Installing update & relaunching MultiClips...")
                            .font(.callout)
                            .foregroundStyle(activeTheme.color)
                    }
                } else {
                    HStack(spacing: 8) {
                        Button {
                            updateManager.downloadAndInstallUpdate()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Update & Relaunch")
                            }
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(activeTheme.color)

                        Button("Later") {
                            updateManager.bannerDismissed = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.small)
                }

                if let error = updateManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(14)
            // Same treatment as the "Latest" release card: tinted fill, 1pt accent stroke,
            // 2pt gradient top edge. Replaces a hardcoded black/white fill, which was the last
            // place in the app still branching on colorScheme.
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(activeTheme.color.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(activeTheme.color.opacity(0.28), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [activeTheme.color, activeTheme.color.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) { Divider() }
            // Same entrance as the toasts, but no auto-close: an available update is an
            // action item, not a transient message.
            .transition(.asymmetric(
                insertion: .move(edge: .top)
                    .combined(with: .opacity)
                    .combined(with: .scale(scale: 0.96, anchor: .top)),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        } else if updateManager.upToDateMessageShown {
            // Green stays: this is semantic success, not theming.
            statusStrip(
                icon: "checkmark.seal.fill",
                tint: .green,
                text: "MultiClips is up to date — \(updateManager.currentVersionInfo.displayString)"
            ) {
                updateManager.upToDateMessageShown = false
            }
        } else if let error = updateManager.errorMessage {
            statusStrip(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                text: error
            ) {
                updateManager.errorMessage = nil
            }
        }
    }

    /// Shared shell for the up-to-date and error strips. Both behave as toasts: they close
    /// themselves after a few seconds, show how long is left, and hold while hovered.
    @ViewBuilder
    private func statusStrip(
        icon: String,
        tint: Color,
        text: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        ToastStrip(icon: icon, tint: tint, text: text, onDismiss: onDismiss)
    }
}

// MARK: - Toast

/// A self-closing notification modelled on react-toastify: springy slide-in from the top,
/// a progress bar counting the time down, hover to hold it open, and a slide-out to the
/// trailing edge. Auto-close is what makes these transient messages toasts rather than
/// banners — an available update is an action item, so it deliberately does not use this.
private struct ToastStrip: View {
    let icon: String
    let tint: Color
    let text: String
    let onDismiss: () -> Void

    private let lifetime: TimeInterval = 5
    private let tick: TimeInterval = 0.05

    @State private var remaining: TimeInterval = 5
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 12.5))
                .textSelection(.enabled)
            Spacer(minLength: 8)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(5)
                    .background(Circle().fill(.quaternary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onHover { isHovered = $0 }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
        .transition(.asymmetric(
            insertion: .move(edge: .top)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.94, anchor: .top)),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        // Keyed on the message so a new toast restarts the clock instead of inheriting
        // whatever was left of the previous one.
        .task(id: text) {
            remaining = lifetime
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
                if Task.isCancelled { return }
                if !isHovered { remaining -= tick }
            }
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { onDismiss() }
    }
}

struct CheckForUpdatesButton: View {
    @ObservedObject var updateManager = UpdateManager.shared
    let activeTheme: ThemeOption

    var body: some View {
        VStack(spacing: 5) {
            Button {
                // Manual checks ignore the 5-minute gate on purpose.
                updateManager.checkForUpdates(isManualCheck: true)
            } label: {
                HStack(spacing: 6) {
                    if updateManager.isChecking {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(updateManager.isChecking ? "Checking…" : "Check for Updates")
                }
                .frame(maxWidth: .infinity)
            }
            // Explicit style: without one this inherits its container, which is why it looked
            // like a sidebar row when it lived inside the List.
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(activeTheme.color)
            .disabled(updateManager.isChecking || updateManager.isDownloading)

            if let last = updateManager.lastUpdateCheckAt {
                Text("Checked \(relativeClipTime(from: last))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

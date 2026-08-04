import SwiftUI

struct UpdateBannerView: View {
    @ObservedObject var updateManager = UpdateManager.shared
    @Environment(\.colorScheme) var colorScheme
    let activeTheme: ThemeOption

    var body: some View {
        Group {
            if updateManager.updateAvailable, let release = updateManager.latestRelease {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(activeTheme.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("New Version Available!")
                                .font(.headline)
                                .fontWeight(.bold)

                            if let remoteInfo = updateManager.latestVersionInfo {
                                Text("MultiClips \(remoteInfo.displayString) is available. Installed: \(updateManager.currentVersionInfo.displayString)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("MultiClips \(release.tagName) is available. Installed: \(updateManager.currentVersionInfo.displayString)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            withAnimation {
                                updateManager.updateAvailable = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    if let bodyText = release.body, !bodyText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Release Highlights:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ScrollView {
                                Text(bodyText)
                                    .font(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                            .frame(maxHeight: 100)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(6)
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
                        HStack(spacing: 12) {
                            Button {
                                updateManager.downloadAndInstallUpdate()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Update & Relaunch")
                                }
                                .fontWeight(.bold)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(activeTheme.color)

                            Button("Later") {
                                withAnimation {
                                    updateManager.updateAvailable = false
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let error = updateManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(activeTheme.color.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                .frame(maxWidth: 520)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))

            } else if updateManager.upToDateMessageShown {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.title3)

                    Text("MultiClips is up to date — \(updateManager.currentVersionInfo.displayString)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer(minLength: 8)

                    Button {
                        withAnimation {
                            updateManager.upToDateMessageShown = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
                .frame(maxWidth: 460)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation {
                            updateManager.upToDateMessageShown = false
                        }
                    }
                }

            } else if let error = updateManager.errorMessage {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)

                    Text(error)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer(minLength: 8)

                    Button {
                        withAnimation {
                            updateManager.errorMessage = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
                .frame(maxWidth: 460)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            updateManager.errorMessage = nil
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: updateManager.updateAvailable)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: updateManager.upToDateMessageShown)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: updateManager.errorMessage != nil)
    }
}

struct CheckForUpdatesButton: View {
    @ObservedObject var updateManager = UpdateManager.shared
    let activeTheme: ThemeOption

    var body: some View {
        Button {
            withAnimation {
                updateManager.checkForUpdates(isManualCheck: true)
            }
        } label: {
            Label(
                title: {
                    Text(updateManager.isChecking ? "Checking..." : "Check for Updates")
                },
                icon: {
                    if updateManager.isChecking {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(updateManager.isChecking || updateManager.isDownloading)
    }
}

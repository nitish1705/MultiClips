import SwiftUI
import SwiftData

@main
struct MultiClipsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(id: "main-window") {
            ContentView()
        }
        .modelContainer(ModelContainerProvider.shared)

        MenuBarExtra("MultiClips", systemImage: "clipboard.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
        .modelContainer(ModelContainerProvider.shared)
    }
}

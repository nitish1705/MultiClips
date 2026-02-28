import SwiftUI
import SwiftData

@main
struct MultiClipsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    // Give AppDelegate access to the shared container
                    appDelegate.modelContainer = sharedModelContainer
                }
        }

        MenuBarExtra("MultiClips", systemImage: "clipboard.fill") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    appDelegate.modelContainer = sharedModelContainer
                }
        }
        .menuBarExtraStyle(.window)
    }
}

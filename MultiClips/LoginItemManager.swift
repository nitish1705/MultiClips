import ServiceManagement
import Foundation

class LoginItemManager {

    /// Returns whether the app is set to launch at login
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Enable launch at login
    static func enable() {
        do {
            try SMAppService.mainApp.register()
            print("✅ Login item registered")
        } catch {
            print("❌ Failed to register login item: \(error)")
        }
    }

    /// Disable launch at login
    static func disable() {
        do {
            try SMAppService.mainApp.unregister()
            print("✅ Login item unregistered")
        } catch {
            print("❌ Failed to unregister login item: \(error)")
        }
    }

    /// Toggle on/off
    static func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}

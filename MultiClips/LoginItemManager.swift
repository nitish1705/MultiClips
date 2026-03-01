import ServiceManagement
import Foundation

class LoginItemManager {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    static func enable() {
        do {
            try SMAppService.mainApp.register()
            print("Login item registered")
        } catch {
            print("Failed to register login item: \(error)")
        }
    }

    static func disable() {
        do {
            try SMAppService.mainApp.unregister()
            print("Login item unregistered")
        } catch {
            print("Failed to unregister login item: \(error)")
        }
    }
    static func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}

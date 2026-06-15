import Foundation
import ServiceManagement

/// 登录自启（macOS 13+ SMAppService）。
enum LoginItem {
    static func set(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
        } catch {
            NSLog("SuperRight login item error: \(error)")
        }
    }
}

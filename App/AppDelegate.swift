import Foundation
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 首次启动写默认配置。
        ConfigStore.writeDefaultIfNeeded()
    }

    /// 接收 superright:// 命令。
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard let cmd = ActionURL.decode(url) else { continue }
            CommandHandler.handle(cmd)
        }
    }
}

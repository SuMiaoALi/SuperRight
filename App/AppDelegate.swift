import Foundation
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 首次启动写默认配置。
        ConfigStore.writeDefaultIfNeeded()
        // 播种内置模板到 App Group（供扩展读取）。
        TemplateStore.seedBuiltins(from: .main)
        let config = ConfigStore.load()
        L10n.apply(config.settings.language)
        // 菜单栏图标（重启 / 配置 / 设置 / 退出 入口）；可在设置里关闭。
        if config.settings.menuBarIcon {
            statusBar = StatusBarController()
        }
        // 应用登录自启设置。
        LoginItem.set(config.settings.launchAtLogin)
    }

    /// 接收 superright:// 命令。
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard let cmd = ActionURL.decode(url) else { continue }
            CommandHandler.handle(cmd)
        }
    }
}

import AppKit

/// 菜单栏（状态栏）图标 —— 提供重启 / 打开配置 / 退出。
/// 因为主程序是无 Dock 图标的后台代理，这是用户唯一的可见入口。
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let expiryItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        if let button = statusItem.button {
            let img = NSImage(systemSymbolName: "cursorarrow.click.2",
                              accessibilityDescription: "SuperRight")
            img?.isTemplate = true
            button.image = img
            button.toolTip = "SuperRight"
        }

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        let title = NSMenuItem(title: "SuperRight \(appVersion)", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        expiryItem.isEnabled = false
        menu.addItem(expiryItem)
        menu.addItem(.separator())

        menu.addItem(item("设置…", #selector(openSettings), key: ","))
        menu.addItem(item("打开配置文件", #selector(openConfig)))
        menu.addItem(item("在 Finder 中显示配置", #selector(revealConfig)))
        menu.addItem(.separator())
        menu.addItem(item("重启 SuperRight", #selector(restart)))
        menu.addItem(.separator())
        menu.addItem(item("退出 SuperRight", #selector(quit), key: "q"))

        statusItem.menu = menu
    }

    // 打开菜单时刷新签名剩余天数。
    func menuWillOpen(_ menu: NSMenu) {
        if let days = ProfileExpiry.daysRemaining() {
            if days < 0 {
                expiryItem.title = "⚠️ 签名已过期，请续签"
            } else {
                expiryItem.title = "签名剩 \(days) 天" + (days <= 2 ? "（建议续签）" : "")
            }
        } else {
            expiryItem.title = "签名状态未知"
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String).map { "v\($0)" } ?? ""
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        i.isEnabled = true
        return i
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func openConfig() {
        ConfigStore.writeDefaultIfNeeded()
        if let url = ConfigStore.configURL { NSWorkspace.shared.open(url) }
    }

    @objc private func revealConfig() {
        ConfigStore.writeDefaultIfNeeded()
        if let url = ConfigStore.configURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc private func restart() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"\(path)\""]
        try? task.run()
        NSApp.terminate(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

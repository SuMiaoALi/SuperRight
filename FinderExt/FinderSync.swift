import Foundation
import AppKit
import FinderSync

/// FinderSync 主体：注册监控目录、构建右键菜单、把动作派发出去。
/// 沙盒进程——轻动作（复制）就地完成，重动作打包 superright:// 交给主程序。
class FinderSync: FIFinderSync {

    override init() {
        super.init()
        let config = ConfigStore.load()
        let scope = PathUtils.expand(config.scope)
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: scope)]
    }

    // 每次构建菜单时重新读配置，使配置文件改动即时生效（无需重启 Finder）。
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let config = ConfigStore.load()
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        let targetDir = controller.targetedURL()
        let builder = MenuBuilder(config: config,
                                  target: self,
                                  openAction: #selector(runOpen(_:)),
                                  copyAction: #selector(runCopy(_:)))
        return builder.menu(for: menuKind, selected: selected, targetDir: targetDir)
    }

    // MARK: - 菜单动作

    /// 打开 superright:// URL，交给主程序执行。
    @objc func runOpen(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    /// 就地把文本写入剪贴板（复制路径/名称）。
    @objc func runCopy(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}

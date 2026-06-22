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
        // 预热图标缓存（主线程 async，避免与菜单构建并发读写缓存；不在点击路径上）。
        DispatchQueue.main.async {
            MenuBuilder.warmIconCache(config)
        }
    }

    // tag → 动作 的查表（representedObject 在 FinderSync 菜单里会丢，必须用 tag 标识）。
    private var actions: [Int: MenuAction] = [:]

    // 每次构建菜单时重新读配置，使配置文件改动即时生效（无需重启 Finder）。
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        actions.removeAll()
        let config = ConfigStore.load()
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        let targetDir = controller.targetedURL()
        let builder = MenuBuilder(
            config: config,
            target: self,
            action: #selector(runAction(_:)),
            register: { [weak self] act in
                guard let self = self else { return 0 }
                let tag = self.actions.count + 1   // 从 1 开始，全树唯一
                self.actions[tag] = act
                return tag
            })
        return builder.menu(for: menuKind, selected: selected, targetDir: targetDir)
    }

    // MARK: - 菜单动作（统一入口，按 tag 查表）

    @objc func runAction(_ sender: NSMenuItem) {
        guard let act = actions[sender.tag] else { return }
        switch act {
        case .open(let url):
            NSWorkspace.shared.open(url)
        case .copy(let text):
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(text, forType: .string)
        }
    }
}

/// 菜单项点击后要做的事。
enum MenuAction {
    case open(URL)      // 打开 superright:// 交给主程序
    case copy(String)   // 就地写剪贴板
}

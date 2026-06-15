import Foundation
import AppKit
import FinderSync

/// 按右键场景 + 配置生成 NSMenu。
/// FinderSync 会丢弃菜单项的 representedObject，故用 tag 标识：每个菜单项注册一个动作拿到
/// 唯一 tag，点击时扩展按 tag 查表。所有项共用同一个 action selector。
final class MenuBuilder {
    let config: Config
    let target: AnyObject
    let action: Selector
    let register: (MenuAction) -> Int   // 注册动作，返回该项的 tag

    init(config: Config, target: AnyObject, action: Selector, register: @escaping (MenuAction) -> Int) {
        self.config = config
        self.target = target
        self.action = action
        self.register = register
    }

    func menu(for kind: FIMenuKind, selected: [URL], targetDir: URL?) -> NSMenu {
        let menu = NSMenu(title: "SuperRight")
        switch kind {
        case .contextualMenuForContainer, .contextualMenuForSidebar:
            buildContainerMenu(menu, dir: targetDir)
        case .contextualMenuForItems:
            buildItemsMenu(menu, selected: selected)
        default:
            break
        }
        return menu
    }

    // MARK: - 空白处（当前文件夹）

    private func buildContainerMenu(_ menu: NSMenu, dir: URL?) {
        guard let dir = dir else { return }
        let dirPath = dir.path

        // 新建文件 ▸
        let newFile = submenu("新建文件")
        for t in config.newFileTypes {
            let url = ActionURL.encode(.init(action: .newFile, dir: dirPath, ext: t.ext))
            newFile.addItem(openItem("\(t.name)  (.\(t.ext))", url: url))
        }
        newFile.addItem(.separator())
        let customURL = ActionURL.encode(.init(action: .newFile, dir: dirPath, custom: true))
        newFile.addItem(openItem("自定义名称…", url: customURL))
        menu.addItem(parent("新建文件", submenu: newFile))

        // 在此打开 ▸（用 App 打开当前目录）
        let openHere = submenu("在此打开")
        for app in config.openApps {
            let url = ActionURL.encode(.init(action: .openDirWith, dir: dirPath,
                                             appBundleId: app.bundleId, appPath: app.path))
            openHere.addItem(openItem(app.name, url: url))
        }
        menu.addItem(parent("在此打开", submenu: openHere))

        // 跳转到 ▸（常用目录）
        let jump = submenu("跳转到")
        for d in config.favoriteDirs {
            let url = ActionURL.encode(.init(action: .revealDir, dir: d.path))
            jump.addItem(openItem(d.name, url: url))
        }
        menu.addItem(parent("跳转到", submenu: jump))

        menu.addItem(.separator())
        menu.addItem(copyItem("复制当前路径", text: dirPath))
    }

    // MARK: - 选中文件

    private func buildItemsMenu(_ menu: NSMenu, selected: [URL]) {
        guard !selected.isEmpty else { return }
        let paths = selected.map { $0.path }
        let names = selected.map { $0.lastPathComponent }

        menu.addItem(copyItem("复制路径", text: PathUtils.joinForClipboard(paths)))
        menu.addItem(copyItem("复制名称", text: PathUtils.joinForClipboard(names)))
        menu.addItem(.separator())

        // 移动到 ▸
        let moveTo = submenu("移动到")
        for t in config.sendTargets {
            let url = ActionURL.encode(.init(action: .moveTo, paths: paths, dest: t.path))
            moveTo.addItem(openItem(t.name, url: url))
        }
        menu.addItem(parent("移动到", submenu: moveTo))

        // 复制到 ▸
        let copyTo = submenu("复制到")
        for t in config.sendTargets {
            let url = ActionURL.encode(.init(action: .copyTo, paths: paths, dest: t.path))
            copyTo.addItem(openItem(t.name, url: url))
        }
        menu.addItem(parent("复制到", submenu: copyTo))

        // 用 App 打开 ▸
        let openWith = submenu("用 App 打开")
        for app in config.openApps {
            let url = ActionURL.encode(.init(action: .openWith, paths: paths,
                                             appBundleId: app.bundleId, appPath: app.path))
            openWith.addItem(openItem(app.name, url: url))
        }
        menu.addItem(parent("用 App 打开", submenu: openWith))
    }

    // MARK: - 构造辅助

    private func submenu(_ title: String) -> NSMenu { NSMenu(title: title) }

    private func parent(_ title: String, submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func openItem(_ title: String, url: URL) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = target
        item.tag = register(.open(url))
        return item
    }

    private func copyItem(_ title: String, text: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = target
        item.tag = register(.copy(text))
        return item
    }
}

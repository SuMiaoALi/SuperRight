import Foundation
import AppKit
import FinderSync
import UniformTypeIdentifiers

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
        L10n.apply(config.settings.language)
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
        if config.features.newFile {
            let newFile = submenu("新建文件")
            for t in config.newFileTypes {
                let url = ActionURL.encode(.init(action: .newFile, dir: dirPath, ext: t.ext))
                newFile.addItem(openItem("\(t.name)  (.\(t.ext))", url: url, image: Self.fileIcon(ext: t.ext)))
            }
            let templates = TemplateStore.list()
            if !templates.isEmpty {
                newFile.addItem(.separator())
                for t in templates {
                    let url = ActionURL.encode(.init(action: .newFromTemplate, dir: dirPath, templatePath: t.path))
                    newFile.addItem(openItem("\(t.name)  (.\(t.ext))", url: url, image: Self.fileIcon(ext: t.ext)))
                }
            }
            newFile.addItem(.separator())
            let customURL = ActionURL.encode(.init(action: .newFile, dir: dirPath, custom: true))
            newFile.addItem(openItem("自定义名称…", url: customURL, symbol: "pencil"))
            menu.addItem(parent("新建文件", submenu: newFile, symbol: "doc.badge.plus"))
        }

        // 在此打开 ▸（用 App 打开当前目录）
        if config.features.openWith {
            let openHere = submenu("在此打开")
            for app in config.openApps {
                let url = ActionURL.encode(.init(action: .openDirWith, dir: dirPath,
                                                 appBundleId: app.bundleId, appPath: app.path))
                openHere.addItem(openItem(app.name, url: url, image: Self.appIcon(bundleId: app.bundleId, path: app.path)))
            }
            menu.addItem(parent("在此打开", submenu: openHere, symbol: "arrow.up.forward.app"))
        }

        // 跳转到 ▸（常用目录）
        if config.features.favorites {
            let jump = submenu("跳转到")
            for d in config.favoriteDirs {
                let url = ActionURL.encode(.init(action: .revealDir, dir: d.path))
                jump.addItem(openItem(d.name, url: url, image: Self.folderIcon()))
            }
            menu.addItem(parent("跳转到", submenu: jump, symbol: "folder"))
        }

        menu.addItem(.separator())
        menu.addItem(copyItem("复制当前路径", text: dirPath, symbol: "doc.on.clipboard"))

        if config.features.toolbox {
            menu.addItem(openItem("粘贴到此", url: ActionURL.encode(.init(action: .pasteHere, dir: dirPath)), symbol: "doc.on.clipboard.fill"))
            menu.addItem(openItem("显示/隐藏 隐藏文件", url: ActionURL.encode(.init(action: .toggleHidden)), symbol: "eye"))
        }
    }

    // MARK: - 选中文件

    private func buildItemsMenu(_ menu: NSMenu, selected: [URL]) {
        guard !selected.isEmpty else { return }
        let paths = selected.map { $0.path }
        let names = selected.map { $0.lastPathComponent }

        menu.addItem(copyItem("复制路径", text: PathUtils.joinForClipboard(paths), symbol: "doc.on.clipboard"))
        menu.addItem(copyItem("复制名称", text: PathUtils.joinForClipboard(names), symbol: "textformat"))
        menu.addItem(.separator())

        // 移动到 / 复制到 ▸
        if config.features.transfer {
            let moveTo = submenu("移动到")
            for t in config.sendTargets {
                let url = ActionURL.encode(.init(action: .moveTo, paths: paths, dest: t.path))
                moveTo.addItem(openItem(t.name, url: url, image: Self.folderIcon()))
            }
            menu.addItem(parent("移动到", submenu: moveTo, symbol: "arrow.right.doc.on.clipboard"))

            let copyTo = submenu("复制到")
            for t in config.sendTargets {
                let url = ActionURL.encode(.init(action: .copyTo, paths: paths, dest: t.path))
                copyTo.addItem(openItem(t.name, url: url, image: Self.folderIcon()))
            }
            menu.addItem(parent("复制到", submenu: copyTo, symbol: "doc.on.doc"))
        }

        // 用 App 打开 ▸
        if config.features.openWith {
            let openWith = submenu("用 App 打开")
            for app in config.openApps {
                let url = ActionURL.encode(.init(action: .openWith, paths: paths,
                                                 appBundleId: app.bundleId, appPath: app.path))
                openWith.addItem(openItem(app.name, url: url, image: Self.appIcon(bundleId: app.bundleId, path: app.path)))
            }
            menu.addItem(parent("用 App 打开", submenu: openWith, symbol: "app.dashed"))
        }

        // 文件夹图标 ▸
        if config.features.icon {
            let icon = submenu("文件夹图标")
            let colors = submenu("换颜色")
            for c in config.folderColors {
                let url = ActionURL.encode(.init(action: .setFolderColor, paths: paths, hex: c.hex))
                colors.addItem(openItem(c.name, url: url, image: Self.colorDot(hex: c.hex)))
            }
            icon.addItem(parent("换颜色", submenu: colors, symbol: "paintpalette"))
            icon.addItem(openItem("设置自定义图标…", url: ActionURL.encode(.init(action: .setCustomIcon, paths: paths)), symbol: "photo"))
            icon.addItem(openItem("拷贝图标", url: ActionURL.encode(.init(action: .copyIcon, paths: paths)), symbol: "doc.on.doc"))
            icon.addItem(openItem("粘贴图标", url: ActionURL.encode(.init(action: .pasteIcon, paths: paths)), symbol: "doc.on.clipboard"))
            icon.addItem(openItem("清除自定义图标", url: ActionURL.encode(.init(action: .clearIcon, paths: paths)), symbol: "arrow.uturn.backward"))
            menu.addItem(parent("文件夹图标", submenu: icon, symbol: "folder.badge.gearshape"))
        }

        // 工具箱 ▸
        if config.features.toolbox {
            let tb = submenu("工具箱")
            tb.addItem(openItem("剪切", url: ActionURL.encode(.init(action: .markCut, paths: paths)), symbol: "scissors"))
            tb.addItem(openItem("拷贝", url: ActionURL.encode(.init(action: .markCopy, paths: paths)), symbol: "doc.on.doc"))
            tb.addItem(.separator())
            tb.addItem(openItem("压缩为 ZIP", url: ActionURL.encode(.init(action: .zip, paths: paths)), symbol: "archivebox"))
            tb.addItem(openItem("解压", url: ActionURL.encode(.init(action: .unzip, paths: paths)), symbol: "archivebox"))
            let conv = submenu("转换图片为")
            for f in ImageFormat.allCases {
                conv.addItem(openItem(f.displayName, url: ActionURL.encode(.init(action: .convertImage, paths: paths, fmt: f.rawValue)), symbol: "photo"))
            }
            tb.addItem(parent("转换图片为", submenu: conv, symbol: "photo.on.rectangle.angled"))
            tb.addItem(openItem("生成二维码", url: ActionURL.encode(.init(action: .qrcode, paths: paths)), symbol: "qrcode"))
            tb.addItem(.separator())
            tb.addItem(openItem("文件信息", url: ActionURL.encode(.init(action: .fileInfo, paths: paths)), symbol: "info.circle"))
            tb.addItem(openItem("创建替身", url: ActionURL.encode(.init(action: .makeAlias, paths: paths)), symbol: "arrowshape.turn.up.left"))
            tb.addItem(openItem("创建符号链接", url: ActionURL.encode(.init(action: .makeSymlink, paths: paths)), symbol: "link"))
            tb.addItem(openItem("批量重命名…", url: ActionURL.encode(.init(action: .batchRename, paths: paths)), symbol: "character.cursor.ibeam"))
            tb.addItem(.separator())
            tb.addItem(openItem("显示/隐藏 隐藏文件", url: ActionURL.encode(.init(action: .toggleHidden)), symbol: "eye"))
            tb.addItem(openItem("永久删除…", url: ActionURL.encode(.init(action: .deletePermanently, paths: paths)), symbol: "trash"))
            menu.addItem(parent("工具箱", submenu: tb, symbol: "wrench.and.screwdriver"))
        }
    }

    // MARK: - 构造辅助

    // 标题统一套 L()：菜单固定项被翻译，动态项（App名/类型名/格式名）查不到表自动保持原样。
    private func submenu(_ title: String) -> NSMenu { NSMenu(title: L(title)) }

    private func parent(_ title: String, submenu: NSMenu, symbol: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: L(title), action: nil, keyEquivalent: "")
        item.submenu = submenu
        item.image = symbol.flatMap(Self.sf)
        return item
    }

    private func openItem(_ title: String, url: URL, symbol: String? = nil, image: NSImage? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: L(title), action: action, keyEquivalent: "")
        item.target = target
        item.tag = register(.open(url))
        item.image = image ?? symbol.flatMap(Self.sf)
        return item
    }

    private func copyItem(_ title: String, text: String, symbol: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: L(title), action: action, keyEquivalent: "")
        item.target = target
        item.tag = register(.copy(text))
        item.image = symbol.flatMap(Self.sf)
        return item
    }

    // MARK: - 图标
    //
    // 全部按 key 缓存：扩展进程常驻，首次右键后命中缓存，消除每次 ~1s 的同步图标计算延迟。

    private static let iconSize = NSSize(width: 16, height: 16)
    private static var sfCache: [String: NSImage] = [:]
    private static var fileIconCache: [String: NSImage] = [:]
    private static var appIconCache: [String: NSImage] = [:]
    private static var folderIconCached: NSImage?

    /// SF Symbol 小图标。
    /// 关键：把矢量 symbol 栅格化成 2x 位图再标 template —— 矢量 symbol 跨进程传给 Finder 时
    /// template 标志会丢，导致深色菜单里发灰；位图+template 能稳定保住，系统按文字色渲染、高亮反白。
    static func sf(_ name: String) -> NSImage? {
        if let c = sfCache[name] { return c }
        let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg) else { return nil }
        let scale = 2
        let px = Int(iconSize.width) * scale
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        rep.size = iconSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let r = NSRect(origin: .zero, size: iconSize)
        // 居中绘制 symbol 的自然尺寸
        let s = symbol.size
        let drawRect = NSRect(x: (iconSize.width - s.width) / 2,
                              y: (iconSize.height - s.height) / 2,
                              width: s.width, height: s.height)
        symbol.draw(in: drawRect.intersection(r).isEmpty ? r : drawRect)
        NSGraphicsContext.restoreGraphicsState()
        let out = NSImage(size: iconSize)
        out.addRepresentation(rep)
        out.isTemplate = true
        sfCache[name] = out
        return out
    }

    /// 某扩展名对应的系统文档图标（显示 Word/Excel 等真实图标）。
    static func fileIcon(ext: String) -> NSImage {
        if let c = fileIconCache[ext] { return c }
        let type = UTType(filenameExtension: ext) ?? .data
        let img = NSWorkspace.shared.icon(for: type)
        img.size = iconSize
        fileIconCache[ext] = img
        return img
    }

    /// App 图标（bundleId 优先，其次 path）；取不到回退 SF。
    static func appIcon(bundleId: String?, path: String?) -> NSImage? {
        let key = bundleId ?? path ?? ""
        if let c = appIconCache[key] { return c }
        var url: URL?
        if let b = bundleId { url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: b) }
        if url == nil, let p = path { url = URL(fileURLWithPath: PathUtils.expand(p)) }
        guard let u = url else { return sf("app") }
        let img = NSWorkspace.shared.icon(forFile: u.path)
        img.size = iconSize
        appIconCache[key] = img
        return img
    }

    static func folderIcon() -> NSImage {
        if let c = folderIconCached { return c }
        let img = NSWorkspace.shared.icon(for: .folder)
        img.size = iconSize
        folderIconCached = img
        return img
    }

    /// 预热常用图标缓存（扩展加载时后台调用），让首次右键也快。
    static func warmIconCache(_ config: Config) {
        _ = folderIcon()
        for s in ["doc.badge.plus", "arrow.up.forward.app", "folder", "doc.on.clipboard",
                  "doc.on.clipboard.fill", "eye", "textformat", "arrow.right.doc.on.clipboard",
                  "doc.on.doc", "app.dashed", "folder.badge.gearshape", "paintpalette", "photo",
                  "arrow.uturn.backward", "wrench.and.screwdriver", "scissors", "archivebox",
                  "photo.on.rectangle.angled", "qrcode", "info.circle", "arrowshape.turn.up.left",
                  "link", "character.cursor.ibeam", "trash", "pencil"] { _ = sf(s) }
        for t in config.newFileTypes { _ = fileIcon(ext: t.ext) }
        for t in TemplateStore.list() { _ = fileIcon(ext: t.ext) }
        for a in config.openApps { _ = appIcon(bundleId: a.bundleId, path: a.path) }
    }

    /// 实心色点（文件夹换色用）。
    static func colorDot(hex: String) -> NSImage? {
        guard let rgb = ColorHex.rgb(hex) else { return nil }
        let img = NSImage(size: iconSize)
        img.lockFocus()
        NSColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 12, height: 12)).fill()
        img.unlockFocus()
        return img
    }
}

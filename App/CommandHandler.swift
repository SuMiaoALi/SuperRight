import Foundation
import AppKit
import UniformTypeIdentifiers

struct SimpleError: LocalizedError {
    let msg: String
    init(_ m: String) { msg = m }
    var errorDescription: String? { msg }
}

/// 把 superright:// 命令派发到具体操作，并负责所有 UI（输入框 / 错误弹窗）。
enum CommandHandler {

    static func handle(_ cmd: ActionURL.Command) {
        switch cmd.action {
        case .newFile:
            handleNewFile(cmd)
        case .newFromTemplate:
            handleNewFromTemplate(cmd)
        case .moveTo, .copyTo:
            handleTransfer(cmd, move: cmd.action == .moveTo)
        case .openWith:
            handleOpenWith(paths: cmd.paths, cmd: cmd)
        case .openDirWith:
            if let dir = cmd.dir { handleOpenWith(paths: [dir], cmd: cmd) }
        case .revealDir:
            if let dir = cmd.dir { AppLauncher.revealDir(dir) }
        case .setFolderColor:
            runCatching { try IconOps.setColor(cmd.paths, hex: cmd.hex ?? "") }
        case .setCustomIcon:
            handleSetCustomIcon(cmd.paths)
        case .clearIcon:
            runCatching { try IconOps.clearIcon(cmd.paths) }
        case .copyIcon:
            if let first = cmd.paths.first { IconOps.copyIcon(first) }
        case .pasteIcon:
            runCatching { try IconOps.pasteIcon(cmd.paths) }
        // 工具箱
        case .toggleHidden:
            Toolbox.toggleHiddenFiles()
        case .qrcode:
            handleQRCode(cmd.paths)
        case .zip:
            runCatching { let u = try Toolbox.zip(cmd.paths); AppLauncher.revealFiles([u.path]) }
        case .unzip:
            runCatching { try Toolbox.unzip(cmd.paths) }
        case .convertImage:
            runCatching { try Toolbox.convertImage(cmd.paths, to: ImageFormat(rawValue: cmd.fmt ?? "") ?? .png) }
        case .fileInfo:
            if let first = cmd.paths.first { showInfo(Toolbox.info(for: first)) }
        case .makeAlias:
            runCatching { try Toolbox.makeAlias(cmd.paths) }
        case .makeSymlink:
            runCatching { try Toolbox.makeSymlink(cmd.paths) }
        case .batchRename:
            handleBatchRename(cmd.paths)
        // 剪切 / 拷贝 / 粘贴
        case .markCut:
            TransferClipboard.mark(cmd.paths, cut: true)
        case .markCopy:
            TransferClipboard.mark(cmd.paths, cut: false)
        case .pasteHere:
            if let dir = cmd.dir {
                runCatching { let r = try TransferClipboard.pasteHere(dir); AppLauncher.revealFiles(r.map { $0.path }) }
            }
        case .deletePermanently:
            handleDeletePermanently(cmd.paths)
        }
    }

    private static func handleQRCode(_ paths: [String]) {
        guard let first = paths.first else { return }
        runCatching { let u = try Toolbox.makeQRCode(for: first); AppLauncher.revealFiles([u.path]) }
    }

    private static func handleDeletePermanently(_ paths: [String]) {
        guard !paths.isEmpty else { return }
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "永久删除 \(paths.count) 项？"
        alert.informativeText = "这些文件将被直接删除，不进废纸篓，无法恢复。"
        alert.addButton(withTitle: "永久删除")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        runCatching { try Toolbox.deletePermanently(paths) }
    }

    private static func handleSetCustomIcon(_ paths: [String]) {
        guard !paths.isEmpty, let imagePath = promptForImage() else { return }
        runCatching { try IconOps.setCustomIcon(paths, imagePath: imagePath) }
    }

    private static func handleNewFromTemplate(_ cmd: ActionURL.Command) {
        guard let dir = cmd.dir, let tmpl = cmd.templatePath else { return }
        do {
            let url = try FileOps.newFromTemplate(tmpl, inDir: dir)
            AppLauncher.revealFiles([url.path])
        } catch {
            showError(error)
        }
    }

    // MARK: - 新建文件

    private static func handleNewFile(_ cmd: ActionURL.Command) {
        guard let dir = cmd.dir else { return }
        let ext = cmd.ext ?? ""
        var base = "未命名"
        if cmd.custom {
            guard let input = promptForName(defaultName: ext.isEmpty ? "未命名.txt" : "未命名.\(ext)") else {
                return  // 用户取消
            }
            // 自定义输入可能自带扩展名：拆出 base 与 ext。
            let nsInput = input as NSString
            let inExt = nsInput.pathExtension
            if !inExt.isEmpty {
                base = nsInput.deletingPathExtension
                createFile(dir: dir, base: base, ext: inExt)
                return
            }
            base = input
        }
        createFile(dir: dir, base: base, ext: ext)
    }

    private static func createFile(dir: String, base: String, ext: String) {
        do {
            let url = try FileOps.createEmptyFile(inDir: dir, base: base, ext: ext)
            AppLauncher.revealFiles([url.path])
        } catch {
            showError(error)
        }
    }

    // MARK: - 移动/复制

    private static func handleTransfer(_ cmd: ActionURL.Command, move: Bool) {
        guard let dest = cmd.dest, !cmd.paths.isEmpty else { return }
        let destExpanded = PathUtils.expand(dest)
        do {
            let results = try FileOps.transfer(cmd.paths, toDir: destExpanded, move: move)
            AppLauncher.revealFiles(results.map { $0.path })
        } catch {
            showError(error)
        }
    }

    // MARK: - 用 App 打开

    private static func handleOpenWith(paths: [String], cmd: ActionURL.Command) {
        AppLauncher.open(paths, bundleId: cmd.appBundleId, appPath: cmd.appPath) { error in
            if let error = error {
                DispatchQueue.main.async { showError(error) }
            }
        }
    }

    // MARK: - UI 辅助

    /// 弹出名字输入框；取消返回 nil。
    private static func promptForName(defaultName: String) -> String? {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "新建文件"
        alert.informativeText = "输入文件名（可带扩展名）"
        alert.addButton(withTitle: "创建")
        alert.addButton(withTitle: "取消")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = defaultName
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        let resp = alert.runModal()
        guard resp == .alertFirstButtonReturn else { return nil }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    /// 展示文件信息，附"复制"。
    private static func showInfo(_ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "文件信息"
        alert.informativeText = text
        alert.addButton(withTitle: "复制")
        alert.addButton(withTitle: "关闭")
        if alert.runModal() == .alertFirstButtonReturn {
            let pb = NSPasteboard.general; pb.clearContents(); pb.setString(text, forType: .string)
        }
    }

    /// 弹出批量重命名规则表单。
    private static func handleBatchRename(_ paths: [String]) {
        guard !paths.isEmpty else { return }
        NSApp.activate(ignoringOtherApps: true)

        func field(_ placeholder: String) -> NSTextField {
            let tf = NSTextField(); tf.placeholderString = placeholder
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.widthAnchor.constraint(equalToConstant: 240).isActive = true
            return tf
        }
        let prefix = field("前缀")
        let suffix = field("后缀")
        let find = field("查找")
        let replace = field("替换为")
        let index = field("起始序号（留空=不加，可写 001 补零）")

        func row(_ label: String, _ tf: NSTextField) -> NSStackView {
            let l = NSTextField(labelWithString: label)
            l.translatesAutoresizingMaskIntoConstraints = false
            l.widthAnchor.constraint(equalToConstant: 72).isActive = true
            let s = NSStackView(views: [l, tf]); s.orientation = .horizontal; s.spacing = 8
            return s
        }
        let stack = NSStackView(views: [
            row("前缀", prefix), row("后缀", suffix),
            row("查找", find), row("替换为", replace), row("序号", index)
        ])
        stack.orientation = .vertical; stack.spacing = 8
        stack.frame = NSRect(x: 0, y: 0, width: 330, height: 170)

        let alert = NSAlert()
        alert.messageText = "批量重命名 \(paths.count) 项"
        alert.accessoryView = stack
        alert.addButton(withTitle: "重命名")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        var rule = RenameRule(find: find.stringValue, replace: replace.stringValue,
                              prefix: prefix.stringValue, suffix: suffix.stringValue)
        let idx = index.stringValue.trimmingCharacters(in: .whitespaces)
        if let n = Int(idx) {
            rule.useIndex = true
            rule.startIndex = n
            rule.padding = idx.hasPrefix("0") ? idx.count : 0
        }
        runCatching { try Toolbox.batchRename(paths, rule: rule) }
    }

    /// 执行可能抛错的操作，失败弹窗。
    static func runCatching(_ op: () throws -> Void) {
        do { try op() } catch { showError(error) }
    }

    /// 弹出选图片面板。
    private static func promptForImage() -> String? {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "选择图标图片"
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .icns, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }

    private static func showError(_ error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "操作失败"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
}

import Foundation
import AppKit

/// 把 superright:// 命令派发到具体操作，并负责所有 UI（输入框 / 错误弹窗）。
enum CommandHandler {

    static func handle(_ cmd: ActionURL.Command) {
        switch cmd.action {
        case .newFile:
            handleNewFile(cmd)
        case .moveTo, .copyTo:
            handleTransfer(cmd, move: cmd.action == .moveTo)
        case .openWith:
            handleOpenWith(paths: cmd.paths, cmd: cmd)
        case .openDirWith:
            if let dir = cmd.dir { handleOpenWith(paths: [dir], cmd: cmd) }
        case .revealDir:
            if let dir = cmd.dir { AppLauncher.revealDir(dir) }
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

import Foundation

struct Template: Equatable {
    var name: String   // 菜单显示名（文件名去扩展名）
    var path: String   // 模板文件绝对路径
    var ext: String    // 扩展名
}

/// 模板库。统一放在 App Group 容器的 Templates 子目录——这样**沙盒扩展也能读**
/// （它无法访问 ~/Library 任意路径）。主程序首启把内置 Office 模板播种进去。
enum TemplateStore {
    /// 内置模板的资源文件名（打包在主程序 bundle 里）。
    static let builtinFileNames = [
        "Word 文档.docx",
        "Excel 表格.xlsx",
        "PPT 演示.pptx",
        "RTF 富文本.rtf"
    ]

    static var dirURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ConfigStore.appGroupID)?
            .appendingPathComponent("Templates", isDirectory: true)
    }

    /// 列出全部模板（内置已播种 + 用户后加），按名排序。扩展与主程序都用。
    static func list() -> [Template] {
        guard let dir = dirURL,
              let items = try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil) else { return [] }
        return items
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .map { Template(name: $0.deletingPathExtension().lastPathComponent,
                            path: $0.path,
                            ext: $0.pathExtension) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// 主程序首启：把内置模板拷进 App Group Templates（已存在则跳过）。
    static func seedBuiltins(from bundle: Bundle) {
        guard let dir = dirURL else { return }
        let fm = FileManager.default
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in builtinFileNames {
            let base = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension
            guard let src = bundle.url(forResource: base, withExtension: ext) else { continue }
            let dst = dir.appendingPathComponent(name)
            if !fm.fileExists(atPath: dst.path) {
                try? fm.copyItem(at: src, to: dst)
            }
        }
    }
}

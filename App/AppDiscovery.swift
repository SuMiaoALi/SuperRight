import Foundation
import AppKit

/// 扫描机器上已安装的"常用打开方式"App（编辑器/IDE/终端/浏览器等），自动填充 openApps。
enum AppDiscovery {
    /// 候选清单（名称, bundleId）。只把实际装了的加进来。
    private static let candidates: [(String, String)] = [
        // 终端
        ("终端", "com.apple.Terminal"),
        ("iTerm", "com.googlecode.iterm2"),
        ("Warp", "dev.warp.Warp-Stable"),
        ("Alacritty", "io.alacritty"),
        ("kitty", "net.kovidgoyal.kitty"),
        ("Ghostty", "com.mitchellh.ghostty"),
        // 编辑器 / IDE
        ("VS Code", "com.microsoft.VSCode"),
        ("Cursor", "com.todesktop.230313mzl4w4u92"),
        ("Antigravity", "com.google.antigravity-ide"),
        ("Windsurf", "com.exafunction.windsurf"),
        ("Zed", "dev.zed.Zed"),
        ("Sublime Text", "com.sublimetext.4"),
        ("Nova", "com.panic.Nova"),
        ("BBEdit", "com.barebones.bbedit"),
        ("Typora", "abnerworks.Typora"),
        ("Obsidian", "md.obsidian"),
        ("MacVim", "org.vim.MacVim"),
        ("Xcode", "com.apple.dt.Xcode"),
        ("PyCharm", "com.jetbrains.pycharm"),
        ("IntelliJ IDEA", "com.jetbrains.intellij"),
        ("WebStorm", "com.jetbrains.WebStorm"),
        ("GoLand", "com.jetbrains.goland"),
        // 浏览器
        ("Safari", "com.apple.Safari"),
        ("Chrome", "com.google.Chrome"),
        ("Firefox", "org.mozilla.firefox"),
        ("Edge", "com.microsoft.edgemac"),
        ("Arc", "company.thebrowser.Browser"),
        // 其它
        ("预览", "com.apple.Preview"),
        ("文本编辑", "com.apple.TextEdit"),
    ]

    /// 返回已安装候选对应的 OpenApp。
    static func installed() -> [OpenApp] {
        candidates.compactMap { name, bid in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) != nil
                ? OpenApp(name: name, bundleId: bid, path: nil) : nil
        }
    }

    /// 把扫描结果并入现有列表（按 bundleId 去重），返回合并后的列表与新增数量。
    static func merge(into existing: [OpenApp]) -> (apps: [OpenApp], added: Int) {
        let have = Set(existing.compactMap { $0.bundleId })
        let fresh = installed().filter { !have.contains($0.bundleId ?? "") }
        return (existing + fresh, fresh.count)
    }
}

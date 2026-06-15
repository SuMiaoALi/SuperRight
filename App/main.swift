import AppKit

// 后台代理型 App：无 Dock 图标，常驻接收 superright:// 命令并托管 Finder 扩展。
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

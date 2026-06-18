import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 选择器辅助

enum Picker2 {
    static func chooseFolder() -> String? {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false; p.allowsMultipleSelection = false
        return p.runModal() == .OK ? p.url?.path : nil
    }
    static func chooseApp() -> OpenApp? {
        let p = NSOpenPanel()
        p.canChooseFiles = true; p.allowedContentTypes = [.application]
        p.directoryURL = URL(fileURLWithPath: "/Applications")
        guard p.runModal() == .OK, let url = p.url else { return nil }
        return OpenApp(name: url.deletingPathExtension().lastPathComponent,
                       bundleId: Bundle(url: url)?.bundleIdentifier,
                       path: url.path)
    }
}

// MARK: - 顶层

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        TabView {
            GeneralTab(store: store).tabItem { Label(L("通用"), systemImage: "gear") }
            ListsTab(store: store).tabItem { Label(L("列表"), systemImage: "list.bullet") }
            FeaturesTab(store: store).tabItem { Label(L("菜单功能"), systemImage: "switch.2") }
            AboutTab().tabItem { Label(L("关于"), systemImage: "info.circle") }
        }
        .frame(width: 560, height: 470)
    }
}

// MARK: - 通用

struct GeneralTab: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Form {
            Section(L("启动与显示")) {
                Toggle(L("显示菜单栏图标"), isOn: $store.config.settings.menuBarIcon)
                Toggle(L("登录时自动启动"), isOn: $store.config.settings.launchAtLogin)
                Picker(L("语言"), selection: $store.config.settings.language) {
                    Text(L("跟随系统")).tag("system")
                    Text("中文").tag("zh")
                    Text("English").tag("en")
                }
                HStack {
                    Text(L("使用范围"))
                    TextField("/", text: $store.config.scope)
                }
            }
            Section(L("权限与位置")) {
                Button(L("打开「完全磁盘访问权限」设置")) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                }
                Button(L("打开「登录项与扩展」设置")) {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
                }
                Button(L("打开模板文件夹")) {
                    if let dir = TemplateStore.dirURL {
                        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                        NSWorkspace.shared.open(dir)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 菜单功能开关

struct FeaturesTab: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Form {
            Section(L("右键菜单显示哪些分组")) {
                Toggle(L("新建文件"), isOn: $store.config.features.newFile)
                Toggle(L("移动到 / 复制到"), isOn: $store.config.features.transfer)
                Toggle(L("跳转到常用目录"), isOn: $store.config.features.favorites)
                Toggle(L("用 App 打开 / 在此打开"), isOn: $store.config.features.openWith)
                Toggle(L("文件夹图标"), isOn: $store.config.features.icon)
                Toggle(L("工具箱"), isOn: $store.config.features.toolbox)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 列表管理

struct ListsTab: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                newFileSection
                pathSection(title: L("常用目录"), keyPath: \.favoriteDirs)
                pathSection(title: L("发送/移动复制目标"), keyPath: \.sendTargets)
                appSection
            }
            .padding()
        }
    }

    private var newFileSection: some View {
        ListBox(title: L("新建文件类型")) {
            ForEach(store.config.newFileTypes.indices, id: \.self) { i in
                HStack {
                    TextField(L("名称"), text: $store.config.newFileTypes[i].name)
                    TextField(L("扩展名"), text: $store.config.newFileTypes[i].ext).frame(width: 90)
                    DeleteButton { store.config.newFileTypes.remove(at: i) }
                }
            }
        } onAdd: {
            store.config.newFileTypes.append(NewFileType(name: L("新类型"), ext: "txt"))
        }
    }

    private func pathSection(title: String, keyPath: WritableKeyPath<Config, [NamedPath]>) -> some View {
        ListBox(title: title) {
            ForEach(store.config[keyPath: keyPath].indices, id: \.self) { i in
                HStack {
                    TextField(L("名称"), text: Binding(
                        get: { store.config[keyPath: keyPath][i].name },
                        set: { store.config[keyPath: keyPath][i].name = $0 }))
                    .frame(width: 110)
                    TextField(L("路径"), text: Binding(
                        get: { store.config[keyPath: keyPath][i].path },
                        set: { store.config[keyPath: keyPath][i].path = $0 }))
                    Button(L("选择…")) {
                        if let p = Picker2.chooseFolder() { store.config[keyPath: keyPath][i].path = p }
                    }
                    DeleteButton { store.config[keyPath: keyPath].remove(at: i) }
                }
            }
        } onAdd: {
            store.config[keyPath: keyPath].append(NamedPath(name: L("新目录"), path: "~/"))
        }
    }

    private var appSection: some View {
        ListBox(title: L("打开方式 App")) {
            ForEach(store.config.openApps.indices, id: \.self) { i in
                HStack {
                    TextField(L("名称"), text: $store.config.openApps[i].name).frame(width: 110)
                    TextField("bundleId", text: Binding(
                        get: { store.config.openApps[i].bundleId ?? "" },
                        set: { store.config.openApps[i].bundleId = $0.isEmpty ? nil : $0 }))
                    Button(L("选择 App…")) {
                        if let app = Picker2.chooseApp() { store.config.openApps[i] = app }
                    }
                    DeleteButton { store.config.openApps.remove(at: i) }
                }
            }
        } onAdd: {
            store.config.openApps.append(OpenApp(name: L("新 App"), bundleId: nil, path: nil))
        }
    }
}

// MARK: - 复用组件

struct ListBox<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    let onAdd: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button(action: onAdd) { Image(systemName: "plus.circle") }.buttonStyle(.borderless)
            }
            content
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DeleteButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) { Image(systemName: "minus.circle").foregroundColor(.red) }
            .buttonStyle(.borderless)
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "cursorarrow.click.2").font(.system(size: 48))
            Text("SuperRight").font(.title.bold())
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                .foregroundColor(.secondary)
            Text(L("开源的 macOS 右键增强工具")).foregroundColor(.secondary)
            Link("github.com/SuMiaoALi/SuperRight",
                 destination: URL(string: "https://github.com/SuMiaoALi/SuperRight")!)
            Text(L("配置文件改动即时生效，无需重启 Finder。"))
                .font(.footnote).foregroundColor(.secondary).padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

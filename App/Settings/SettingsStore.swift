import Foundation
import Combine

/// 设置界面的数据源：加载配置、编辑、自动原子写回（扩展会即时重读）。
final class SettingsStore: ObservableObject {
    @Published var config: Config {
        didSet { persist() }
    }
    private var lastLaunchAtLogin: Bool

    init() {
        let c = ConfigStore.load()
        config = c
        lastLaunchAtLogin = c.settings.launchAtLogin
    }

    private func persist() {
        ConfigStore.save(config)
        if config.settings.launchAtLogin != lastLaunchAtLogin {
            LoginItem.set(config.settings.launchAtLogin)
            lastLaunchAtLogin = config.settings.launchAtLogin
        }
    }
}

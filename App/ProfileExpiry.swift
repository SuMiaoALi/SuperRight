import Foundation

/// 读取本 App 内嵌 provisioning profile 的到期日（免费个人 team 仅 7 天）。
enum ProfileExpiry {
    static func expirationDate() -> Date? {
        let url = Bundle.main.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile")
        guard let data = try? Data(contentsOf: url),
              let plist = extractPlist(data),
              let date = plist["ExpirationDate"] as? Date else { return nil }
        return date
    }

    /// 剩余天数（向下取整）；读不到返回 nil。
    static func daysRemaining() -> Int? {
        guard let date = expirationDate() else { return nil }
        return Int(floor(date.timeIntervalSinceNow / 86400))
    }

    /// 从 CMS 数据里抠出内嵌的 XML plist 并解析。
    private static func extractPlist(_ data: Data) -> [String: Any]? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8)) else { return nil }
        let sub = data[start.lowerBound..<end.upperBound]
        return (try? PropertyListSerialization.propertyList(from: sub, options: [], format: nil)) as? [String: Any]
    }
}

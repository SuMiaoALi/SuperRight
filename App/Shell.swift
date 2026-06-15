import Foundation

enum Shell {
    /// 同步运行命令，返回 (退出码, stdout+stderr 文本)。
    @discardableResult
    static func run(_ launchPath: String, _ args: [String], cwd: String? = nil) -> (code: Int32, out: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = args
        if let cwd = cwd { task.currentDirectoryURL = URL(fileURLWithPath: cwd) }
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch { return (-1, error.localizedDescription) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return (task.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}

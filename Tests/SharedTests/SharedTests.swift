import XCTest

final class FileNameTests: XCTestCase {
    func testNoConflict() {
        XCTAssertEqual(FileName.unique(base: "未命名", ext: "txt", existing: []), "未命名.txt")
    }
    func testOneConflict() {
        XCTAssertEqual(FileName.unique(base: "a", ext: "txt", existing: ["a.txt"]), "a 2.txt")
    }
    func testMultipleConflicts() {
        XCTAssertEqual(FileName.unique(base: "a", ext: "txt", existing: ["a.txt", "a 2.txt", "a 3.txt"]), "a 4.txt")
    }
    func testNoExtension() {
        XCTAssertEqual(FileName.unique(base: "folder", ext: "", existing: ["folder"]), "folder 2")
    }
}

final class PathUtilsTests: XCTestCase {
    func testExpandTildeRoot() {
        XCTAssertEqual(PathUtils.expandTilde("~", home: "/Users/foo"), "/Users/foo")
    }
    func testExpandTildePath() {
        XCTAssertEqual(PathUtils.expandTilde("~/Downloads", home: "/Users/foo"), "/Users/foo/Downloads")
    }
    func testNoTilde() {
        XCTAssertEqual(PathUtils.expandTilde("/abs/path", home: "/Users/foo"), "/abs/path")
    }
    func testJoinForClipboard() {
        XCTAssertEqual(PathUtils.joinForClipboard(["/a", "/b"]), "/a\n/b")
    }
    func testLastComponent() {
        XCTAssertEqual(PathUtils.lastComponent("/a/b/c.txt"), "c.txt")
    }
}

final class ConfigTests: XCTestCase {
    func testDefaultRoundTrip() {
        let data = Config.default.encoded()
        let decoded = Config.decode(from: data)
        XCTAssertEqual(decoded, Config.default)
    }
    func testDecodeGarbage() {
        XCTAssertNil(Config.decode(from: Data("not json".utf8)))
    }
    func testDecodeMinimal() {
        let json = """
        {"scope":"/","newFileTypes":[],"favoriteDirs":[],"sendTargets":[],"openApps":[{"name":"终端","bundleId":"com.apple.Terminal"}]}
        """
        let cfg = Config.decode(from: Data(json.utf8))
        XCTAssertEqual(cfg?.openApps.first?.bundleId, "com.apple.Terminal")
        XCTAssertNil(cfg?.openApps.first?.path)
    }
}

final class ActionURLTests: XCTestCase {
    func testNewFileRoundTrip() {
        let cmd = ActionURL.Command(action: .newFile, dir: "/tmp/中文 目录", ext: "md")
        let url = ActionURL.encode(cmd)
        XCTAssertEqual(url.scheme, "superright")
        XCTAssertEqual(ActionURL.decode(url), cmd)
    }
    func testNewFileCustom() {
        let cmd = ActionURL.Command(action: .newFile, dir: "/tmp", custom: true)
        XCTAssertEqual(ActionURL.decode(ActionURL.encode(cmd)), cmd)
    }
    func testMoveToMultiplePaths() {
        let cmd = ActionURL.Command(action: .moveTo, paths: ["/a/x.txt", "/a/y z.txt"], dest: "~/Downloads")
        XCTAssertEqual(ActionURL.decode(ActionURL.encode(cmd)), cmd)
    }
    func testOpenWithBundle() {
        let cmd = ActionURL.Command(action: .openWith, paths: ["/a/x"], appBundleId: "com.apple.Terminal")
        XCTAssertEqual(ActionURL.decode(ActionURL.encode(cmd)), cmd)
    }
    func testRevealDir() {
        let cmd = ActionURL.Command(action: .revealDir, dir: "~/Documents")
        XCTAssertEqual(ActionURL.decode(ActionURL.encode(cmd)), cmd)
    }
    func testDecodeWrongSchemeReturnsNil() {
        XCTAssertNil(ActionURL.decode(URL(string: "http://newFile?dir=/tmp")!))
    }
}

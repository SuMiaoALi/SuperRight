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
    func testNewActionsRoundTrip() {
        let cmds = [
            ActionURL.Command(action: .newFromTemplate, dir: "/tmp", templatePath: "/t/模板.docx"),
            ActionURL.Command(action: .setFolderColor, paths: ["/a/f"], hex: "#FF5A52"),
            ActionURL.Command(action: .convertImage, paths: ["/a/x.png"], fmt: "jpg"),
            ActionURL.Command(action: .zip, paths: ["/a/x", "/a/y"]),
            ActionURL.Command(action: .toggleHidden),
            ActionURL.Command(action: .batchRename, paths: ["/a/1.txt"]),
            ActionURL.Command(action: .deletePermanently, paths: ["/a/x"]),
            ActionURL.Command(action: .pasteHere, dir: "/a")
        ]
        for c in cmds {
            XCTAssertEqual(ActionURL.decode(ActionURL.encode(c)), c, "\(c.action)")
        }
    }
}

final class ConfigBackCompatTests: XCTestCase {
    func testOldJsonGetsNewDefaults() {
        // 旧版配置（无 templatesDir/folderColors/features/settings）应回退默认。
        let old = """
        {"scope":"/","newFileTypes":[],"favoriteDirs":[],"sendTargets":[],"openApps":[]}
        """
        let cfg = Config.decode(from: Data(old.utf8))
        XCTAssertNotNil(cfg)
        XCTAssertEqual(cfg?.templatesDir, Config.default.templatesDir)
        XCTAssertEqual(cfg?.features, FeatureToggles())
        XCTAssertEqual(cfg?.settings.menuBarIcon, true)
        XCTAssertFalse(cfg?.folderColors.isEmpty ?? true)
    }
    func testPartialFeatures() {
        let json = """
        {"features":{"toolbox":false}}
        """
        let cfg = Config.decode(from: Data(json.utf8))
        XCTAssertEqual(cfg?.features.toolbox, false)
        XCTAssertEqual(cfg?.features.newFile, true) // 缺省项仍 true
    }
    func testFullRoundTrip() {
        let data = Config.default.encoded()
        XCTAssertEqual(Config.decode(from: data), Config.default)
    }
}

final class BatchRenameTests: XCTestCase {
    func testFindReplaceKeepsExt() {
        let r = RenameRule(find: "IMG", replace: "照片")
        XCTAssertEqual(BatchRename.apply("IMG_001.jpg", rule: r, position: 0), "照片_001.jpg")
    }
    func testPrefixSuffix() {
        let r = RenameRule(prefix: "a_", suffix: "_b")
        XCTAssertEqual(BatchRename.apply("x.txt", rule: r, position: 0), "a_x_b.txt")
    }
    func testIndexWithPadding() {
        let r = RenameRule(prefix: "p", useIndex: true, startIndex: 1, padding: 3)
        let out = BatchRename.applyAll(["a.txt", "b.txt"], rule: r)
        XCTAssertEqual(out, ["pa001.txt", "pb002.txt"])
    }
    func testNoExtension() {
        let r = RenameRule(prefix: "x_")
        XCTAssertEqual(BatchRename.apply("folder", rule: r, position: 0), "x_folder")
    }
}

final class ColorHexTests: XCTestCase {
    func testValid() {
        let rgb = ColorHex.rgb("#FF8040")
        XCTAssertEqual(rgb?.r ?? 0, 1.0, accuracy: 0.001)
        XCTAssertEqual(rgb?.g ?? 0, 128.0/255.0, accuracy: 0.001)
        XCTAssertEqual(rgb?.b ?? 0, 64.0/255.0, accuracy: 0.001)
    }
    func testNoHash() { XCTAssertNotNil(ColorHex.rgb("00FF00")) }
    func testInvalid() {
        XCTAssertNil(ColorHex.rgb("#GGG"))
        XCTAssertNil(ColorHex.rgb("#FFF"))
    }
}

final class ByteFormatTests: XCTestCase {
    func testBytes() { XCTAssertEqual(ByteFormat.human(512), "512 B") }
    func testKB() { XCTAssertEqual(ByteFormat.human(2048), "2.00 KB") }
    func testMB() { XCTAssertEqual(ByteFormat.human(5 * 1024 * 1024), "5.00 MB") }
}

final class L10nTests: XCTestCase {
    func testOverrideEnglish() {
        L10n.override = "en"
        XCTAssertEqual(L("新建文件"), "New File")
        XCTAssertEqual(L("工具箱"), "Toolbox")
    }
    func testOverrideChinese() {
        L10n.override = "zh"
        XCTAssertEqual(L("新建文件"), "新建文件")
    }
    func testMissingKeyFallsBackToChinese() {
        L10n.override = "en"
        XCTAssertEqual(L("某个没翻译的词"), "某个没翻译的词")
        L10n.override = nil
    }
    func testApply() {
        L10n.apply("en"); XCTAssertTrue(L10n.isEnglish)
        L10n.apply("zh"); XCTAssertFalse(L10n.isEnglish)
        L10n.apply("system"); XCTAssertNil(L10n.override)
    }
}

final class ConfigLanguageTests: XCTestCase {
    func testLanguageDefaultsToSystem() {
        let cfg = Config.decode(from: Data("{}".utf8))
        XCTAssertEqual(cfg?.settings.language, "system")
    }
    func testLanguageRoundTrip() {
        var c = Config.default; c.settings.language = "en"
        XCTAssertEqual(Config.decode(from: c.encoded())?.settings.language, "en")
    }
}

final class ImageFormatTests: XCTestCase {
    func testUTIs() {
        XCTAssertEqual(ImageFormat.jpg.uti, "public.jpeg")
        XCTAssertEqual(ImageFormat.heic.uti, "public.heic")
        XCTAssertEqual(ImageFormat.allCases.count, 6)
    }
}

# SuperRight

English ｜ [中文](README.zh-CN.md)

A self-built macOS Finder context-menu enhancer — a free, open-source alternative to paid tools like "超级右键 / iRightMouse". Built on Apple's official **FinderSync** extension, so items appear at the top level of the right-click menu, all driven by a single `config.json`.

> Personal use / build-it-yourself. Runs with a free Apple ID (the provisioning profile lasts 7 days; auto-renew is included — see [Limitations](#limitations)).

## Features

Right-click on **empty space in a folder**:

- **New File** ▸ plain-text types (txt/md/rtf/json/sh…), built-in Office templates (Word/Excel/PPT), anything in your **templates folder**, or a custom name (auto-numbered on conflict)
- **Open Here** ▸ open the current folder in Terminal / Warp / an editor
- **Go To** ▸ jump to favorite directories in Finder
- **Copy Current Path**, **Paste Here**, **Toggle Hidden Files**

Right-click on **selected files**:

- **Copy Path** / **Copy Name**
- **Move To** ▸ / **Copy To** ▸ favorite destinations (non-destructive, auto-numbered on conflict)
- **Open With** ▸ (terminal-class apps automatically open the file's containing folder)
- **Folder Icon** ▸ recolor / custom icon / copy-paste / reset
- **Toolbox** ▸ cut & paste, zip / unzip, image-format conversion, QR code, file info (MD5/SHA256), make alias / symlink, batch rename, permanent delete

**Settings window** (menu-bar icon → Settings…): edit every list graphically, toggle menu groups, set the templates folder, permission shortcuts, launch-at-login — no JSON editing required. Config changes apply instantly.

## Architecture

```
SuperRight.app  (main app, non-sandboxed, lives in the menu bar)
 ├─ FinderExt.appex  (FinderSync extension, sandboxed) — builds the menu + captures clicks
 └─ App Group container — config.json, read by both
```

- The extension is sandboxed: **light actions run in place** (copy path → pasteboard), while **heavy actions are encoded into a `superright://` URL** and handed to the non-sandboxed main app, which performs the real file ops / app launches.
- Menu items are dispatched by `tag` (FinderSync drops `representedObject` across the process boundary — a key gotcha).
- Pure logic (config parsing, URL coding, conflict-free naming, path handling) lives in a shared module with unit tests.

See [`docs/`](docs/finder-context-menu/) for design, research and decisions.

## Requirements

- macOS 14+
- Full **Xcode** (Command Line Tools alone can't package a FinderSync extension)
- [XcodeGen](https://github.com/yonyz/XcodeGen): `brew install xcodegen`

## Build & Install

1. **One-time GUI step** (FinderSync needs a signed extension): run `xcodegen generate`, open `SuperRight.xcodeproj`, sign in with a free Apple ID under Xcode → Settings → Accounts, and pick your *(Personal Team)* for both the `SuperRight` and `FinderExt` targets in Signing & Capabilities. This creates your first provisioning profile.
2. **Run the setup script** — it auto-detects your Team ID, builds, installs, and enables the extension:
   ```bash
   bash scripts/setup.sh
   ```
   (Under the hood: `scripts/build-install.sh` generates the project → builds → installs to `/Applications` → launches → enables the Finder extension → restarts Finder. You can re-run it anytime to rebuild.)
3. **Grant permissions** (first run): enable **SuperRight** under System Settings → Login Items & Extensions → Finder Extensions, and add **SuperRight.app** to Full Disk Access (otherwise protected folders keep prompting).

## Auto-renew (the 7-day expiry)

A free personal team's profile expires after 7 days. One command installs a LaunchAgent that rebuilds & re-signs at login and every 5 days:

```bash
bash scripts/install-autorenew.sh            # install
bash scripts/install-autorenew.sh uninstall  # remove
```

The menu-bar icon shows "signature: N days left". A paid Apple Developer account ($99/yr) removes the expiry entirely and lets you notarize a `.dmg` for distribution.

## Configuration

`~/Library/Group Containers/group.com.cola.SuperRight/config.json` (or menu-bar icon → Open Config File). Saved changes apply instantly. Paths support `~`; apps can be referenced by `bundleId` or `path`; a missing/corrupt file falls back to built-in defaults so the menu never goes empty.

```json
{
  "scope": "/",
  "newFileTypes": [{ "name": "Markdown", "ext": "md" }],
  "favoriteDirs":  [{ "name": "Downloads", "path": "~/Downloads" }],
  "sendTargets":   [{ "name": "Projects", "path": "~/projects" }],
  "openApps": [
    { "name": "Terminal", "bundleId": "com.apple.Terminal" }
  ]
}
```

## Limitations

- **Free personal-team profiles last only 7 days** — mitigated by the auto-renew LaunchAgent above; a paid account removes it.
- **The binary can't be distributed as-is**: a personal-team signature is only valid on the machine that built it. Others must build it themselves. Shipping a `.dmg` requires a paid account + notarization.
- Protected folders require Full Disk Access — the common cost of a non-sandboxed helper.

> UI is bilingual (English / 中文), following the system language. Override it under Settings → Language.

## License

[Apache-2.0](LICENSE)

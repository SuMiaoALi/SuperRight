# 付费号 + 公证分发方案（备查）

> 目的：让**任何人下载 .dmg 拖进应用程序即用**，无需 Xcode、无需自己签名、永不 7 天到期。
> 这是把 SuperRight 从"开发者自建"变成"人人可用"的唯一途径，是一道**花钱的门**，不是写代码能跨过的。

## 为什么免费号做不到
- 免费个人 team 的签名只在**本机**有效，profile 7 天到期；拷给别人的二进制在对方机器上**无法启动**。
- 沙盒扩展 + App Group 要求正式签名；分发还要过 Gatekeeper / 公证。

## 需要什么
1. **Apple Developer Program 会员**：$99/年（个人或公司均可）。
2. 一个 **Developer ID Application** 证书（加入后在 Xcode 自动管理里勾选即可生成）。
3. 用于公证的 **App-specific password** 或 **App Store Connect API Key**。

## 步骤（拿到付费号后）
1. **改签名为 Developer ID + 关掉个人 team 那套**
   - `project.yml` 里 `CODE_SIGN_IDENTITY = "Developer ID Application"`，`DEVELOPMENT_TEAM` 换成付费 team id。
   - App Group / 扩展 capability 不变。
2. **Release 构建 + 启用 Hardened Runtime**（已开 `ENABLE_HARDENED_RUNTIME=YES`）。
   ```bash
   xcodebuild -scheme SuperRight -configuration Release archive -archivePath build/SuperRight.xcarchive
   xcodebuild -exportArchive -archivePath build/SuperRight.xcarchive \
     -exportOptionsPlist export.plist -exportPath build/export   # method: developer-id
   ```
3. **打包 .dmg**：`hdiutil create` 或 create-dmg，把 SuperRight.app 拖进去。
4. **公证**：
   ```bash
   xcrun notarytool submit build/SuperRight.dmg \
     --apple-id <id> --team-id <team> --password <app-specific-pw> --wait
   xcrun stapler staple build/SuperRight.dmg
   ```
5. **发 GitHub Release**：`gh release create vX.Y build/SuperRight.dmg -t ... -n ...`

## 自动化
- 上面可写成 `scripts/release.sh`，凭据走环境变量。
- 进一步可用 GitHub Actions（macOS runner + 证书/密钥放 Secrets）做 tag 触发自动公证发布。

## 用户侧体验（公证后）
- 下载 .dmg → 拖入「应用程序」→ 启动 → 系统设置启用 Finder 扩展 + 授完全磁盘访问 → 用。
- 不再有 7 天到期；不需要 Xcode / Apple ID / 构建。
- （Finder 扩展启用 + 完全磁盘访问这两个系统授权仍需用户手点——这是 macOS 对所有同类工具的统一要求，超级右键也一样。）

## 结论
- **要不要做 = 要不要花 $99/年 + 愿不愿做实名开发者账号。** 纯工程上我们已就绪（Hardened Runtime 已开、架构不变）。
- 决定投入后，我可以把 release.sh + GitHub Actions 一并补上，约半天工作量。

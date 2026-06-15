#!/bin/bash
# 冒烟测试：通过 superright:// 触发所有"可脚本化"的 app 侧动作并核对结果。
# 不覆盖需要弹窗交互的动作（批量重命名/永久删除/文件信息/自定义图标/换色——见末尾人工清单）。
set -u
D=/tmp/sr-smoke
rm -rf "$D" 2>/dev/null; mkdir -p "$D" "$D/dest"
PASS=0; FAIL=0
fire() { open "superright://$1"; sleep 1.2; }
check() { # $1=描述 $2=路径glob
  if compgen -G "$2" >/dev/null; then echo "✅ $1"; PASS=$((PASS+1)); else echo "❌ $1  ($2)"; FAIL=$((FAIL+1)); fi
}

echo "== 新建文件 =="
fire "newFile?dir=$D&ext=md";                check "新建 md"            "$D/未命名.md"
echo "== 从模板新建（Word） =="
TMPL="$HOME/Library/Group Containers/group.com.cola.SuperRight/Templates/Word 文档.docx"
fire "newFromTemplate?dir=$D&tmpl=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$TMPL")"
check "从模板新建 docx" "$D/Word 文档.docx"

echo "== 复制 / 移动 =="
printf x > "$D/src.txt"
fire "copyTo?p=$D/src.txt&dest=$D/dest";      check "复制到"  "$D/dest/src.txt"
printf x > "$D/mv.txt"
fire "moveTo?p=$D/mv.txt&dest=$D/dest";        check "移动到"  "$D/dest/mv.txt"

echo "== 剪贴板 拷贝→粘贴 =="
printf x > "$D/clip.txt"; mkdir -p "$D/pasteinto"
fire "markCopy?p=$D/clip.txt"
fire "pasteHere?dir=$D/pasteinto";             check "粘贴到此" "$D/pasteinto/clip.txt"

echo "== 压缩 / 解压 =="
fire "zip?p=$D/src.txt";                       check "压缩 zip" "$D/src.zip"
[ -f "$D/src.zip" ] && fire "unzip?p=$D/src.zip" && check "解压" "$D/src/*"

echo "== 二维码 =="
fire "qrcode?p=$D/src.txt";                    check "二维码 png" "$D/src.txt.qr.png"

echo "== 图片格式转换 png→jpg =="
ICNS="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns"
sips -s format png "$ICNS" --out "$D/pic.png" >/dev/null 2>&1
if [ -f "$D/pic.png" ]; then
  fire "convertImage?p=$D/pic.png&fmt=jpg";     check "转 jpg" "$D/pic.jpg"
else echo "⚠️ 跳过图片转换（测试图生成失败）"; fi

echo "== 替身 / 符号链接 =="
fire "makeAlias?p=$D/src.txt";                 check "替身"      "$D/src.txt 替身"
fire "makeSymlink?p=$D/src.txt";               check "符号链接"  "$D/src.txt 链接"

echo "== 文件夹换色（仅触发，图标效果需肉眼）=="
mkdir -p "$D/colorme"
fire "setFolderColor?p=$D/colorme&hex=%23FF5A52"; echo "  （已触发，去 $D 看 colorme 颜色）"

echo ""
echo "================  结果：$PASS 通过 / $FAIL 失败  ================"
echo "需人工验收（弹窗类）：批量重命名、永久删除、文件信息、自定义图标、显示隐藏文件、Finder 右键各菜单项"

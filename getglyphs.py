import sys
import os
import requests
import time
import pathlib

base = sys.argv[1]
codepoint_file = sys.argv[2]
extended_file = sys.argv[3] if len(sys.argv) > 3 else None

# 1. コードポイントリストの読み込み
with open(codepoint_file, "r", encoding="utf-8") as fp:
    codepoints = [line.strip() for line in fp if line.strip()]

# 2. SpaceGlyphs.txt からチェック除外対象リストの読み込み
space_glyphs = set()
space_file = "SpaceGlyphs.txt"
if os.path.exists(space_file):
    with open(space_file, "r", encoding="utf-8") as fp:
        for line in fp:
            line = line.strip()
            if line and not line.startswith("#"):
                # 先頭のコードポイント文字列を取得
                space_glyphs.add(line.split()[0])

# 3. ExtendedGlyphs.txt からのグリフ名マッピング作成 (codepoint -> glyph_name)
extended_map = {}
if extended_file and os.path.exists(extended_file):
    with open(extended_file, "r", encoding="utf-8") as fp:
        for line in fp:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split(";")
            if len(parts) >= 2:
                cp = parts[0].strip()
                glyph_name = parts[1].strip()
                if cp and glyph_name:
                    extended_map[cp] = glyph_name

# 4. ディレクトリの事前作成
dirs = set()
for i in codepoints:
    c = i.split("-")[0]
    d1 = c[:-3]
    d2 = c[:-2]
    dirs.add(os.path.join(base, d1, d2))

for d in dirs:
    os.makedirs(d, exist_ok=True)

# 5. 既存SVGの取得
temp = pathlib.Path(base)
svg_set = {str(p) for p in temp.glob("**/*.svg")}

# 6. グリフSVGの取得処理
for i in codepoints:
    c = i.split("-")[0]
    d1 = c[:-3]
    d2 = c[:-2]
    target_path = os.path.join(base, d1, d2, f"{i}.svg")
    
    print("\r", i, sep="", end="        ")
    
    if target_path not in svg_set:
        # 2列目に指定されたグリフ名があればそれを使用、無ければデフォルト(i)を使用
        glyph_name = extended_map.get(i, i)
        url = f"https://glyphwiki.org/glyph/{glyph_name}.svg"
        
        # SpaceGlyphs.txt に含まれるコードポイントかの判定
        is_space = i in space_glyphs
        
        count = 20
        data = b""
        while count > 0:
            try:
                res = requests.get(url, timeout=10)
                data = res.content
                # SpaceGlyphs 対象ならサイズ判定をスキップ、通常グリフなら len(data) > 193 を適用
                if data[0:4] == b'<svg' and (is_space or len(data) > 193):
                    break
            except Exception:
                pass
            
            print("\nfailed to get ... retry:", i, end='')
            time.sleep(1)
            count -= 1

        if data[0:4] == b'<svg' and (is_space or len(data) > 193):
            with open(target_path, mode='wb') as f:
                f.write(data)
        else:
            print("\nfailed to get:", i)

print("\r", end="")

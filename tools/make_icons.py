#!/usr/bin/env python3
"""앱 아이콘(확정본 '세 겹' DO/IT 라일락, W 11-23) → Android 런처 아이콘 세트. 5번방 #167
 입력: resources/icon_fg-1024.png (투명 바탕, 글자 묶음이 적응형 안전 구역 66/108 안에 들어가게 놓임)
 출력(<res> 아래): mipmap-*/ic_launcher_foreground.png · ic_launcher.png · ic_launcher_round.png,
                  mipmap-anydpi-v26/ic_launcher(.xml·_round.xml), values/cd_launcher_bg.xml
 iOS는 resources/AppIcon-1024.png 를 그대로 씀(ios.yml).  사용: python3 tools/make_icons.py android/app/src/main/res
"""
import os, sys
from PIL import Image, ImageDraw
BG = (0xA4, 0x8B, 0xF7, 255)
HERE = os.path.dirname(os.path.abspath(__file__))
DENS = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

def main(res):
    fg = Image.open(os.path.join(HERE, '..', 'resources', 'icon_fg-1024.png')).convert('RGBA')
    full = Image.new('RGBA', fg.size, BG); full.alpha_composite(fg)
    c = round(fg.size[0] * 18 / 108)                       # 런처가 보여 주는 창 = 가운데 72/108
    vis = full.crop((c, c, fg.size[0] - c, fg.size[1] - c))
    for d, k in DENS.items():
        out = os.path.join(res, 'mipmap-' + d); os.makedirs(out, exist_ok=True)
        fg.resize((round(108 * k),) * 2, Image.LANCZOS).save(os.path.join(out, 'ic_launcher_foreground.png'))
        n = round(48 * k); sq = vis.resize((n, n), Image.LANCZOS)
        S = 4; m = Image.new('L', (n * S, n * S), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, n * S - 1, n * S - 1), radius=round(n * S * .18), fill=255)
        a = sq.copy(); a.putalpha(m.resize((n, n), Image.LANCZOS)); a.save(os.path.join(out, 'ic_launcher.png'))
        m = Image.new('L', (n * S, n * S), 0); ImageDraw.Draw(m).ellipse((0, 0, n * S - 1, n * S - 1), fill=255)
        a = sq.copy(); a.putalpha(m.resize((n, n), Image.LANCZOS)); a.save(os.path.join(out, 'ic_launcher_round.png'))
    any26 = os.path.join(res, 'mipmap-anydpi-v26'); os.makedirs(any26, exist_ok=True)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@color/cd_launcher_bg"/>\n    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
    for nm in ('ic_launcher.xml', 'ic_launcher_round.xml'): open(os.path.join(any26, nm), 'w').write(xml)
    os.makedirs(os.path.join(res, 'values'), exist_ok=True)
    open(os.path.join(res, 'values', 'cd_launcher_bg.xml'), 'w').write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="cd_launcher_bg">#A48BF7</color>\n</resources>\n')
    # 틀에 딸려 온 벡터 앞 판이 남아 있으면 PNG와 이름이 겹쳐 빌드가 깨짐 → 지움
    for p in ('drawable-v24/ic_launcher_foreground.xml', 'drawable/ic_launcher_foreground.xml'):
        f = os.path.join(res, p)
        if os.path.exists(f): os.remove(f)
    print('icons ok →', res)

if __name__ == '__main__':
    main(sys.argv[1])

"""스플래시 만들기(5번방 #112 1차, W 승인 앱 첫 화면 1안): 보라 바탕 #7A5AF0 + 가운데 두잇이·글자(resources/splash_mark.png).
쓰기: python3 tools/make_splash.py 너비 높이 출력경로  — 그림 높이 = 짧은 쪽 기준 휴대폰 화면 높이의 약 18%"""
import sys
from PIL import Image
BG=(0x7A,0x5A,0xF0)
def make(w,h,out,mark='resources/splash_mark.png'):
    m=Image.open(mark).convert('RGBA')
    # 세로 화면(가로를 꽉 채워 잘림) 기준: 보이는 높이 ≈ h(세로형) / 정사각은 가운데 세로 띠가 보임 → 높이의 18%
    mh=int(min(w*844/390,h)*0.18); mw=int(m.width*mh/m.height)
    m=m.resize((mw,mh),Image.LANCZOS)
    c=Image.new('RGBA',(w,h),BG+(255,)); c.alpha_composite(m,((w-mw)//2,(h-mh)//2))
    c.convert('RGB').save(out)
if __name__=='__main__':
    make(int(sys.argv[1]),int(sys.argv[2]),sys.argv[3])

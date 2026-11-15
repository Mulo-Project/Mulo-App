"""앱 아이콘 원본(assets/icon/*.png)에서 Android 아이콘 리소스를 만든다.

실행: python3 tool/gen_android_icon.py   (Pillow 필요)
- app_icon.png       : 색이 있는 원본 (배경 투명, 1024x1024)
- app_icon_mono.png  : 단색 마크 (테마 아이콘 monochrome 용)
만드는 것: mipmap-*/ic_launcher.png (옛 기기), ic_launcher_foreground.png,
ic_launcher_monochrome.png. 배경색 · adaptive xml은 res/ 안에 직접 둔다.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

color = Image.open(ROOT / "assets/icon/app_icon.png").convert("RGBA")
mono = Image.open(ROOT / "assets/icon/app_icon_mono.png").convert("RGBA")


def place(src: Image.Image, canvas_dp: float, content_dp: float, density: float) -> Image.Image:
    """src의 내용(투명이 아닌 부분)을 content_dp 크기로 줄여 canvas 가운데에 놓는다."""
    box = src.getchannel("A").getbbox()
    art = src.crop(box)
    scale = content_dp * density / max(art.size)
    art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
    size = round(canvas_dp * density)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(art, ((size - art.width) // 2, (size - art.height) // 2))
    return out


for name, density in DENSITIES.items():
    d = RES / f"mipmap-{name}"
    d.mkdir(parents=True, exist_ok=True)
    # adaptive: 108dp 캔버스, 안전 영역(지름 66dp) 안에 원이 들어오게 둔다
    place(color, 108, 62, density).save(d / "ic_launcher_foreground.png", optimize=True)
    place(mono, 108, 50, density).save(d / "ic_launcher_monochrome.png", optimize=True)
    # 옛 기기(8.0 미만): 48dp 한 장
    place(color, 48, 46, density).save(d / "ic_launcher.png", optimize=True)
print("done")

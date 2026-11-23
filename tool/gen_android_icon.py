"""앱 아이콘 원본(assets/icon/*.png)에서 Android 아이콘 리소스를 만든다.

실행: python3 tool/gen_android_icon.py   (Pillow 필요)
- app_icon.png       : 색이 있는 원본 (배경 투명, 1024x1024)
- app_icon_mono.png  : 단색 마크 (테마 아이콘 monochrome 용)
- app_icon_background.png : adaptive 배경 (사각형을 가득 채우는 색 번짐, 1080x1080 = 108dp)
만드는 것: mipmap-*/ic_launcher.png (옛 기기), ic_launcher_foreground.png,
ic_launcher_background.png, ic_launcher_monochrome.png. adaptive xml은 res/ 안에 직접 둔다.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}

color = Image.open(ROOT / "assets/icon/app_icon.png").convert("RGBA")
mono = Image.open(ROOT / "assets/icon/app_icon_mono.png").convert("RGBA")
background = Image.open(ROOT / "assets/icon/app_icon_background.png").convert("RGBA")


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
    size = round(108 * density)
    bg = background.resize((size, size), Image.LANCZOS)
    bg.convert("RGB").save(d / "ic_launcher_background.png", optimize=True)
    # 옛 기기(8.0 미만): 배경 + 앞면을 합쳐 가운데 72dp만 둥근 사각형으로 자른다
    full = bg.copy()
    full.alpha_composite(place(color, 108, 62, density))
    m = round(18 * density)
    visible = full.crop((m, m, size - m, size - m))
    out_px = round(48 * density)
    visible = visible.resize((out_px, out_px), Image.LANCZOS)
    mask = Image.new("L", (out_px, out_px), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, out_px - 1, out_px - 1), radius=round(out_px * 0.2), fill=255)
    visible.putalpha(mask)
    visible.save(d / "ic_launcher.png", optimize=True)
print("done")

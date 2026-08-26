import os
import math
import subprocess
import tempfile
from pathlib import Path
from PIL import Image

ROOT_DIR = Path(__file__).resolve().parent.parent
APP_DIR = ROOT_DIR / "app"

ASSETS_ICONS_DIR = APP_DIR / "assets" / "icons"
WEB_ICONS_DIR = APP_DIR / "web" / "icons"
WEB_DIR = APP_DIR / "web"
ANDROID_RES_DIR = APP_DIR / "android" / "app" / "src" / "main" / "res"
IOS_ICONS_DIR = APP_DIR / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

for d in [ASSETS_ICONS_DIR, WEB_ICONS_DIR, WEB_DIR, ANDROID_RES_DIR, IOS_ICONS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

SIZE = 512
STRIPES = 7
STRIPE_W = SIZE / STRIPES
CX = SIZE / 2
CY = SIZE / 2

# Gear geometry
TEETH = 12
R_TIP = 170
R_ROOT = 110
BORE_HALF = 46
BORE_CORNER = 16
P = (math.pi * 2) / TEETH
ALPHA = P * 0.3
BETA = P * 0.07

GEAR_FILL = "#00731f"
KEYLINE_FILL = "#004613"
KEYLINE_WIDTH = 10
GEAR_OPACITY = 1

def pt(r, a):
    return f"{(CX + r * math.cos(a)):.3f} {(CY + r * math.sin(a)):.3f}"

cog_pts = []
for i in range(TEETH):
    c = i * P - math.pi / 2
    corners = [
        (R_ROOT, c - ALPHA),
        (R_TIP, c - BETA),
        (R_TIP, c + BETA),
        (R_ROOT, c + ALPHA),
    ]
    for k, (r, a) in enumerate(corners):
        prefix = "M" if (i == 0 and k == 0) else "L"
        cog_pts.append(f"{prefix}{pt(r, a)}")

cog = " ".join(cog_pts) + " Z"

bx0 = CX - BORE_HALF
bx1 = CX + BORE_HALF
by0 = CY - BORE_HALF
by1 = CY + BORE_HALF
rc = BORE_CORNER
bore = f"M {bx0 + rc} {by0} L {bx1 - rc} {by0} A {rc} {rc} 0 0 1 {bx1} {by0 + rc} L {bx1} {by1 - rc} A {rc} {rc} 0 0 1 {bx1 - rc} {by1} L {bx0 + rc} {by1} A {rc} {rc} 0 0 1 {bx0} {by1 - rc} L {bx0} {by0 + rc} A {rc} {rc} 0 0 1 {bx0 + rc} {by0} Z"

stripes = ""
for i in range(STRIPES):
    x = f"{(i * STRIPE_W):.3f}"
    w = f"{STRIPE_W:.3f}"
    fill = "#999999" if (i % 2 == 0) else "#ffffff"
    stripes += f'  <rect x="{x}" y="0" width="{w}" height="{SIZE}" fill="{fill}"/>\n'

svg = f'''<svg width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="gear-shadow" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="0" dy="5" stdDeviation="6" flood-color="#000000" flood-opacity="0.4"/>
    </filter>
  </defs>
{stripes}  <path d="{cog} {bore}" fill="{KEYLINE_FILL}" stroke="{KEYLINE_FILL}" stroke-width="{2 * KEYLINE_WIDTH}" stroke-linejoin="round" fill-rule="evenodd" filter="url(#gear-shadow)"/>
  <path d="{cog} {bore}" fill="{GEAR_FILL}" fill-rule="evenodd" fill-opacity="{GEAR_OPACITY}"/>
</svg>
'''

# 1. Write SVGs
for svg_path in [
    ASSETS_ICONS_DIR / "roboref.svg",
    WEB_DIR / "roboref.svg",
    WEB_ICONS_DIR / "roboref.svg",
]:
    svg_path.write_text(svg, encoding="utf-8")
print("Wrote roboref.svg to assets and web")

# 2. Render high-res base PNG using Chrome headless
chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(chrome_path):
    chrome_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

html_page = f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: 1024px; height: 1024px; overflow: hidden; background: transparent; }}
  svg {{ width: 1024px; height: 1024px; display: block; }}
</style>
</head>
<body>
{svg}
</body>
</html>'''

with tempfile.TemporaryDirectory() as tmpdir:
    tmp_html = Path(tmpdir) / "icon.html"
    tmp_png = Path(tmpdir) / "icon1024.png"
    tmp_html.write_text(html_page, encoding="utf-8")

    cmd = [
        chrome_path,
        "--headless=new",
        "--disable-gpu",
        "--force-device-scale-factor=1",
        "--window-size=1024,1024",
        "--default-background-color=00000000",
        f"--screenshot={str(tmp_png)}",
        tmp_html.as_uri(),
    ]
    subprocess.run(cmd, check=True)

    base_img = Image.open(tmp_png).convert("RGBA")
    # Ensure 1024x1024
    if base_img.size != (1024, 1024):
        base_img = base_img.resize((1024, 1024), Image.Resampling.LANCZOS)

    # 3. Flutter Assets
    asset_sizes = [48, 72, 96, 144, 168, 192, 256, 512, 1024]
    for sz in asset_sizes:
        resized = base_img.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(ASSETS_ICONS_DIR / f"roboref-{sz}x{sz}.png", format="PNG")
    print("Wrote Flutter asset PNGs")

    # 4. Web PWA Icons
    base_img.resize((192, 192), Image.Resampling.LANCZOS).save(WEB_ICONS_DIR / "Icon-192.png", format="PNG")
    base_img.resize((512, 512), Image.Resampling.LANCZOS).save(WEB_ICONS_DIR / "Icon-512.png", format="PNG")
    base_img.resize((192, 192), Image.Resampling.LANCZOS).save(WEB_ICONS_DIR / "Icon-maskable-192.png", format="PNG")
    base_img.resize((512, 512), Image.Resampling.LANCZOS).save(WEB_ICONS_DIR / "Icon-maskable-512.png", format="PNG")
    base_img.resize((64, 64), Image.Resampling.LANCZOS).save(WEB_DIR / "favicon.png", format="PNG")
    print("Wrote Web PWA icons & favicon.png")

    # 5. Favicon .ico
    ico_imgs = [base_img.resize((s, s), Image.Resampling.LANCZOS) for s in [16, 32, 48]]
    ico_imgs[0].save(
        ASSETS_ICONS_DIR / "favicon.ico",
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48)],
        append_images=ico_imgs[1:]
    )
    ico_imgs[0].save(
        WEB_DIR / "favicon.ico",
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48)],
        append_images=ico_imgs[1:]
    )
    print("Wrote favicon.ico")

    # 6. Android Mipmaps
    android_mipmaps = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]
    for folder, sz in android_mipmaps:
        out_dir = ANDROID_RES_DIR / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        base_img.resize((sz, sz), Image.Resampling.LANCZOS).save(out_dir / "ic_launcher.png", format="PNG")
    print("Wrote Android mipmap icons")

    # 7. iOS AppIcon set
    ios_icons = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for name, sz in ios_icons:
        base_img.resize((sz, sz), Image.Resampling.LANCZOS).save(IOS_ICONS_DIR / name, format="PNG")
    print("Wrote iOS AppIcon set")

print("All RoboRef brand icons updated to #00731f successfully!")

import os
import math
import subprocess
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw

ROOT_DIR = Path(__file__).resolve().parent.parent
APP_DIR = ROOT_DIR / "app"

ASSETS_ICONS_DIR = APP_DIR / "assets" / "icons"
WEB_ICONS_DIR = APP_DIR / "web" / "icons"
WEB_DIR = APP_DIR / "web"
ANDROID_RES_DIR = APP_DIR / "android" / "app" / "src" / "main" / "res"
IOS_ICONS_DIR = APP_DIR / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

for d in [ASSETS_ICONS_DIR, WEB_ICONS_DIR, WEB_DIR, ANDROID_RES_DIR, IOS_ICONS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# -----------------------------------------------------------------------------
# Canonical 512x512 Icon Definition
# -----------------------------------------------------------------------------
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

def pt(cx, cy, r, a):
    return f"{(cx + r * math.cos(a)):.3f} {(cy + r * math.sin(a)):.3f}"

def build_cog(cx, cy, r_root, r_tip):
    cog_pts = []
    for i in range(TEETH):
        c = i * P - math.pi / 2
        corners = [
            (r_root, c - ALPHA),
            (r_tip, c - BETA),
            (r_tip, c + BETA),
            (r_root, c + ALPHA),
        ]
        for k, (r, a) in enumerate(corners):
            prefix = "M" if (i == 0 and k == 0) else "L"
            cog_pts.append(f"{prefix}{pt(cx, cy, r, a)}")
    return " ".join(cog_pts) + " Z"

def build_bore(cx, cy, bore_half, rc):
    bx0 = cx - bore_half
    bx1 = cx + bore_half
    by0 = cy - bore_half
    by1 = cy + bore_half
    return (
        f"M {bx0 + rc:.3f} {by0:.3f} "
        f"L {bx1 - rc:.3f} {by0:.3f} "
        f"A {rc:.3f} {rc:.3f} 0 0 1 {bx1:.3f} {by0 + rc:.3f} "
        f"L {bx1:.3f} {by1 - rc:.3f} "
        f"A {rc:.3f} {rc:.3f} 0 0 1 {bx1 - rc:.3f} {by1:.3f} "
        f"L {bx0 + rc:.3f} {by1:.3f} "
        f"A {rc:.3f} {rc:.3f} 0 0 1 {bx0:.3f} {by1 - rc:.3f} "
        f"L {bx0:.3f} {by0 + rc:.3f} "
        f"A {rc:.3f} {rc:.3f} 0 0 1 {bx0 + rc:.3f} {by0:.3f} Z"
    )

cog = build_cog(CX, CY, R_ROOT, R_TIP)
bore = build_bore(CX, CY, BORE_HALF, BORE_CORNER)

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

# Browser path for headless rendering
chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(chrome_path):
    chrome_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

def render_svg_to_png(svg_str, width, height):
    """Render an SVG string to a PIL RGBA Image using headless Chrome/Edge."""
    html_page = f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: {width}px; height: {height}px; overflow: hidden; background: transparent; }}
  svg {{ width: {width}px; height: {height}px; display: block; }}
</style>
</head>
<body>
{svg_str}
</body>
</html>'''
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_html = Path(tmpdir) / "render.html"
        tmp_png = Path(tmpdir) / "render.png"
        tmp_html.write_text(html_page, encoding="utf-8")
        cmd = [
            chrome_path,
            "--headless=new",
            "--disable-gpu",
            "--force-device-scale-factor=1",
            f"--window-size={width},{height}",
            "--default-background-color=00000000",
            f"--screenshot={str(tmp_png)}",
            tmp_html.as_uri(),
        ]
        subprocess.run(cmd, check=True)
        img = Image.open(tmp_png).convert("RGBA")
        if img.size != (width, height):
            img = img.resize((width, height), Image.Resampling.LANCZOS)
        return img

# 2. Render high-res base PNG
base_img = render_svg_to_png(svg, 1024, 1024)

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

# 6. Android Legacy Mipmaps
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

    # Round legacy icon (circle mask)
    round_img = Image.new("RGBA", (sz, sz), (0, 0, 0, 0))
    mask = Image.new("L", (sz, sz), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, sz - 1, sz - 1), fill=255)
    round_img.paste(base_img.resize((sz, sz), Image.Resampling.LANCZOS), (0, 0), mask=mask)
    round_img.save(out_dir / "ic_launcher_round.png", format="PNG")
print("Wrote Android legacy mipmap icons (standard + round)")

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

# -----------------------------------------------------------------------------
# 8. Android Adaptive Icons (API 26+)
# -----------------------------------------------------------------------------
# Specifications:
# Canvas: 108dp x 108dp
# Safe zone: centered circle of diameter 66dp
# Proportions: Outer gear diameter = 54dp (radius 27dp), comfortably within 66dp
ADAPTIVE_CANVAS = 108
ADAPTIVE_CX = 54.0
ADAPTIVE_CY = 54.0
GEAR_DIAMETER = 54.0
# In 512px canvas, gear diameter with keyline was 360 (170 + 10 radius)
ADAPTIVE_SCALE = GEAR_DIAMETER / 360.0

A_R_TIP = 170.0 * ADAPTIVE_SCALE
A_R_ROOT = 110.0 * ADAPTIVE_SCALE
A_BORE_HALF = 46.0 * ADAPTIVE_SCALE
A_BORE_CORNER = 16.0 * ADAPTIVE_SCALE
A_KEYLINE_WIDTH = 10.0 * ADAPTIVE_SCALE
A_SHADOW_DY = 5.0 * ADAPTIVE_SCALE
A_SHADOW_STD = 6.0 * ADAPTIVE_SCALE

adaptive_cog = build_cog(ADAPTIVE_CX, ADAPTIVE_CY, A_R_ROOT, A_R_TIP)
adaptive_bore = build_bore(ADAPTIVE_CX, ADAPTIVE_CY, A_BORE_HALF, A_BORE_CORNER)

# Background stripes across 108dp canvas (symmetrical around center CX=54)
# Stripe width scaled proportionally to gear: 73.142857 * 0.15 = 10.971429 dp
A_STRIPE_W = (SIZE / STRIPES) * ADAPTIVE_SCALE

adaptive_stripes = []
max_stripe_idx = int(math.ceil((ADAPTIVE_CANVAS / 2.0) / A_STRIPE_W)) + 1
for i in range(-max_stripe_idx, max_stripe_idx + 1):
    x0 = ADAPTIVE_CX + (i - 0.5) * A_STRIPE_W
    x1 = ADAPTIVE_CX + (i + 0.5) * A_STRIPE_W
    left = max(0.0, x0)
    right = min(float(ADAPTIVE_CANVAS), x1)
    if right > left:
        fill = "#ffffff" if (i % 2 == 0) else "#999999"
        adaptive_stripes.append((left, right - left, fill))

# 8A. Generate Background Vector Drawable (res/drawable/ic_launcher_background.xml)
DRAWABLE_DIR = ANDROID_RES_DIR / "drawable"
DRAWABLE_DIR.mkdir(parents=True, exist_ok=True)

white_rect_paths = []
for left, width, fill in adaptive_stripes:
    if fill == "#ffffff":
        white_rect_paths.append(f"M{left:.3f},0h{width:.3f}v108h-{width:.3f}z")
white_path_data = " ".join(white_rect_paths)

bg_vector_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#999999"
        android:pathData="M0,0h108v108h-108z" />
    <path
        android:fillColor="#ffffff"
        android:pathData="{white_path_data}" />
</vector>
'''
(DRAWABLE_DIR / "ic_launcher_background.xml").write_text(bg_vector_xml, encoding="utf-8")
print("Wrote res/drawable/ic_launcher_background.xml")

# 8B. Generate Foreground Vector Drawable Fallback (res/drawable/ic_launcher_foreground.xml)
fg_vector_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="{KEYLINE_FILL}"
        android:strokeColor="{KEYLINE_FILL}"
        android:strokeWidth="{2 * A_KEYLINE_WIDTH:.3f}"
        android:strokeLineJoin="round"
        android:fillType="evenOdd"
        android:pathData="{adaptive_cog} {adaptive_bore}" />
    <path
        android:fillColor="{GEAR_FILL}"
        android:fillType="evenOdd"
        android:pathData="{adaptive_cog} {adaptive_bore}" />
</vector>
'''
(DRAWABLE_DIR / "ic_launcher_foreground.xml").write_text(fg_vector_xml, encoding="utf-8")
print("Wrote res/drawable/ic_launcher_foreground.xml")

# 8C. Generate Monochrome Vector Drawable (res/drawable/ic_launcher_monochrome.xml) for Android 13+ Themed Icons
monochrome_vector_xml = f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#ffffff"
        android:fillType="evenOdd"
        android:pathData="{adaptive_cog} {adaptive_bore}" />
</vector>
'''
(DRAWABLE_DIR / "ic_launcher_monochrome.xml").write_text(monochrome_vector_xml, encoding="utf-8")
print("Wrote res/drawable/ic_launcher_monochrome.xml")

# 8D. Generate Adaptive Icon XMLs (res/mipmap-anydpi-v26/)
MIPMAP_ANYDPI_DIR = ANDROID_RES_DIR / "mipmap-anydpi-v26"
MIPMAP_ANYDPI_DIR.mkdir(parents=True, exist_ok=True)

adaptive_icon_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
'''
(MIPMAP_ANYDPI_DIR / "ic_launcher.xml").write_text(adaptive_icon_xml, encoding="utf-8")
(MIPMAP_ANYDPI_DIR / "ic_launcher_round.xml").write_text(adaptive_icon_xml, encoding="utf-8")
print("Wrote res/mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml")

# 8E. Render Raster Foreground Mipmap PNGs (with authentic drop shadow)
# High-res SVG for foreground layer with scaled drop shadow
adaptive_fg_svg = f'''<svg width="{ADAPTIVE_CANVAS}" height="{ADAPTIVE_CANVAS}" viewBox="0 0 {ADAPTIVE_CANVAS} {ADAPTIVE_CANVAS}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="gear-shadow" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="0" dy="{A_SHADOW_DY:.3f}" stdDeviation="{A_SHADOW_STD:.3f}" flood-color="#000000" flood-opacity="0.4"/>
    </filter>
  </defs>
  <path d="{adaptive_cog} {adaptive_bore}" fill="{KEYLINE_FILL}" stroke="{KEYLINE_FILL}" stroke-width="{2 * A_KEYLINE_WIDTH:.3f}" stroke-linejoin="round" fill-rule="evenodd" filter="url(#gear-shadow)"/>
  <path d="{adaptive_cog} {adaptive_bore}" fill="{GEAR_FILL}" fill-rule="evenodd"/>
</svg>
'''

# Densities for 108dp adaptive foreground:
# mdpi (1x) = 108, hdpi (1.5x) = 162, xhdpi (2x) = 216, xxhdpi (3x) = 324, xxxhdpi (4x) = 432
adaptive_densities = [
    ("mipmap-mdpi", 108),
    ("mipmap-hdpi", 162),
    ("mipmap-xhdpi", 216),
    ("mipmap-xxhdpi", 324),
    ("mipmap-xxxhdpi", 432),
]

# Render xxxhdpi base at 432x432
adaptive_base_fg = render_svg_to_png(adaptive_fg_svg, 432, 432)

for folder, sz in adaptive_densities:
    target_dir = ANDROID_RES_DIR / folder
    target_dir.mkdir(parents=True, exist_ok=True)
    resized_fg = adaptive_base_fg.resize((sz, sz), Image.Resampling.LANCZOS)
    resized_fg.save(target_dir / "ic_launcher_foreground.png", format="PNG")
print("Wrote Android adaptive ic_launcher_foreground.png across all densities")

print("\nAll RoboRef brand and adaptive icons generated successfully!")

import os
import base64
import subprocess
import tempfile
from pathlib import Path
from PIL import Image

ROOT_DIR = Path(__file__).resolve().parent.parent
APP_DIR = ROOT_DIR / "app"
STORE_DIR = APP_DIR / "assets" / "store"
STORE_DIR.mkdir(parents=True, exist_ok=True)

ICON_PATH = APP_DIR / "assets" / "icons" / "roboref-512x512.png"
if not ICON_PATH.exists():
    raise FileNotFoundError(f"Icon not found at {ICON_PATH}")

ICON_B64 = base64.b64encode(ICON_PATH.read_bytes()).decode("ascii")
ICON_DATA_URI = f"data:image/png;base64,{ICON_B64}"

CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(CHROME_PATH):
    CHROME_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

def get_template_horizontal():
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800;900&display=swap');

  * {{
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    -webkit-font-smoothing: antialiased;
  }}

  body {{
    width: 2048px;
    height: 1000px;
    overflow: hidden;
    background: #121513;
    font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    color: #ffffff;
    display: flex;
    align-items: center;
    justify-content: center;
  }}

  .container {{
    display: flex;
    align-items: center;
    gap: 84px;
    padding: 0 160px;
    max-width: 1850px;
  }}

  .app-icon {{
    width: 340px;
    height: 340px;
    border-radius: 68px;
    overflow: hidden;
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.6), 0 4px 16px rgba(0, 0, 0, 0.4);
    border: 3px solid rgba(255, 255, 255, 0.12);
    flex-shrink: 0;
  }}

  .app-icon img {{
    width: 100%;
    height: 100%;
    display: block;
  }}

  .text-block {{
    display: flex;
    flex-direction: column;
    justify-content: center;
  }}

  .app-title {{
    font-size: 136px;
    font-weight: 900;
    letter-spacing: -3.5px;
    line-height: 0.95;
    color: #ffffff;
  }}

  .app-subtitle {{
    font-size: 44px;
    font-weight: 700;
    color: #66e07a;
    letter-spacing: 0.5px;
    margin-top: 14px;
  }}

  .app-tagline {{
    font-size: 30px;
    font-weight: 400;
    color: #94a3b8;
    margin-top: 16px;
    line-height: 1.45;
    max-width: 820px;
  }}
</style>
</head>
<body>
  <div class="container">
    <div class="app-icon">
      <img src="{ICON_DATA_URI}" alt="RoboRef Logo">
    </div>
    <div class="text-block">
      <h1 class="app-title">RoboRef</h1>
      <div class="app-subtitle">Head Referee Assistant</div>
      <div class="app-tagline">Match Anomaly Log for VEX Robotics Tournaments</div>
    </div>
  </div>
</body>
</html>"""

def render_html_to_images(html_str, base_name):
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_html = Path(tmpdir) / "render.html"
        tmp_png = Path(tmpdir) / "render2048.png"
        tmp_html.write_text(html_str, encoding="utf-8")

        cmd = [
            CHROME_PATH,
            "--headless=new",
            "--disable-gpu",
            "--force-device-scale-factor=1",
            "--window-size=2048,1000",
            f"--screenshot={str(tmp_png)}",
            tmp_html.as_uri(),
        ]
        subprocess.run(cmd, check=True)

        img = Image.open(tmp_png)
        resized = img.resize((1024, 500), Image.Resampling.LANCZOS)
        # Google Play requires strictly NO alpha channel (24-bit RGB or JPEG)
        rgb_img = resized.convert("RGB")
        
        png_out = STORE_DIR / f"{base_name}.png"
        jpg_out = STORE_DIR / f"{base_name}.jpg"
        
        rgb_img.save(png_out, format="PNG", optimize=True)
        rgb_img.save(jpg_out, format="JPEG", quality=95, optimize=True)
        
        print(f"Generated {png_out.name} ({os.path.getsize(png_out)} bytes)")
        print(f"Generated {jpg_out.name} ({os.path.getsize(jpg_out)} bytes)")
        return rgb_img

if __name__ == "__main__":
    print("Rendering Primary Horizontal Featured Graphic...")
    render_html_to_images(get_template_horizontal(), "gplay_feature_graphic")

    print("Done! Google Play Featured Graphics generated successfully in app/assets/store/!")

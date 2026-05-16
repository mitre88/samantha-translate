from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "SamanthaTranslate" / "Assets.xcassets" / "AppIcon.appiconset"
ASSET_DIR = ROOT / "Assets"
AUDIT_DIR = ROOT / "AppStore" / "IconAudit"

def make_icon(size=1024):
    img = Image.new("RGB", (size, size), (7, 10, 14))
    draw = ImageDraw.Draw(img)
    for radius, alpha in [(430, 44), (330, 78), (238, 118)]:
        layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        ld.ellipse((size/2-radius, size/2-radius, size/2+radius, size/2+radius), fill=(94, 226, 255, alpha))
        img_rgba = img.convert("RGBA")
        img_rgba.alpha_composite(layer.filter(ImageFilter.GaussianBlur(28)))
        img = img_rgba.convert("RGB")
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((118, 118, 906, 906), radius=206, fill=(13, 17, 22), outline=(34, 42, 50), width=8)
    draw.ellipse((188, 188, 836, 836), fill=(248, 252, 253), outline=(192, 244, 255), width=10)
    draw.ellipse((292, 292, 732, 732), outline=(221, 227, 232), width=8)
    heights = [166, 292, 392, 292, 166]
    start_x = 356
    for index, height in enumerate(heights):
        x = start_x + index * 78
        y1 = size / 2 - height / 2
        y2 = size / 2 + height / 2
        draw.rounded_rectangle((x, y1, x + 34, y2), radius=18, fill=(13, 17, 22))
    return img

def make_small_size_preview(icon):
    canvas = Image.new("RGB", (720, 360), (246, 248, 250))
    dark_panel = Image.new("RGB", (360, 360), (7, 10, 14))
    canvas.paste(dark_panel, (360, 0))
    draw = ImageDraw.Draw(canvas)
    small = icon.resize((60, 60), Image.Resampling.LANCZOS)
    large = icon.resize((160, 160), Image.Resampling.LANCZOS)
    canvas.paste(large, (100, 72))
    canvas.paste(small, (150, 258))
    canvas.paste(large, (460, 72))
    canvas.paste(small, (510, 258))
    draw.text((72, 22), "Light App Store context", fill=(13, 17, 22))
    draw.text((432, 22), "Dark App Store context", fill=(246, 250, 251))
    return canvas

def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    icon = make_icon()
    icon.save(ICON_DIR / "AppIcon-1024.png")
    icon.save(ASSET_DIR / "samantha-translate-icon.png")
    make_small_size_preview(icon).save(AUDIT_DIR / "icon-60px-preview.png")
    (ICON_DIR / "Contents.json").write_text('''{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''')

if __name__ == "__main__":
    main()

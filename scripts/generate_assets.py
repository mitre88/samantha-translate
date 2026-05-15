from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "SamanthaTranslate" / "Assets.xcassets" / "AppIcon.appiconset"
ASSET_DIR = ROOT / "Assets"

def make_icon(size=1024):
    img = Image.new("RGB", (size, size), (17, 20, 23))
    draw = ImageDraw.Draw(img)
    for radius, alpha in [(410, 40), (330, 70), (245, 110)]:
        layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        ld.ellipse((size/2-radius, size/2-radius, size/2+radius, size/2+radius), fill=(80, 220, 245, alpha))
        img_rgba = img.convert("RGBA")
        img_rgba.alpha_composite(layer.filter(ImageFilter.GaussianBlur(24)))
        img = img_rgba.convert("RGB")
    draw = ImageDraw.Draw(img)
    draw.ellipse((172, 172, 852, 852), fill=(246, 250, 251), outline=(210, 245, 255), width=8)
    draw.ellipse((312, 312, 712, 712), fill=(20, 25, 30), outline=(120, 235, 255), width=12)
    for x in [430, 486, 542, 598]:
        draw.rounded_rectangle((x, 384, x + 28, 640), radius=18, fill=(238, 252, 255))
    return img

def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    icon = make_icon()
    icon.save(ICON_DIR / "AppIcon-1024.png")
    icon.save(ASSET_DIR / "samantha-translate-icon.png")
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


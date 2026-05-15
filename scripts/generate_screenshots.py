from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "AppStore" / "Screenshots" / "generated"
SIZE = (1320, 2868)

SCREENS = [
    ("01-core-promise.png", "Hear any language", "Samantha speaks the translation in yours."),
    ("02-live-listening.png", "Real-time listening", "Auto-detect speech and translate instantly."),
    ("03-spoken-output.png", "Spoken translations", "Designed for voice-first conversations."),
    ("04-language-selector.png", "Five interface languages", "English, Spanish, French, Chinese, and Japanese."),
    ("05-private-by-design.png", "No saved audio", "Audio is processed live and not stored by us."),
]

def font(size, bold=False):
    names = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for name in names:
        try:
            return ImageFont.truetype(name, size=size)
        except Exception:
            pass
    return ImageFont.load_default()

def make_screen(title, subtitle):
    img = Image.new("RGB", SIZE, (247, 248, 249))
    draw = ImageDraw.Draw(img)
    cx = SIZE[0] // 2
    draw.ellipse((cx - 260, 420, cx + 260, 940), fill=(18, 23, 29), outline=(145, 236, 255), width=9)
    draw.ellipse((cx - 185, 495, cx + 185, 865), fill=(248, 252, 253))
    for x in [cx - 82, cx - 28, cx + 28, cx + 82]:
        draw.rounded_rectangle((x - 14, 590, x + 14, 770), radius=14, fill=(18, 23, 29))
    draw.text((84, 1160), title, fill=(14, 18, 22), font=font(96, True))
    draw.text((84, 1390), subtitle, fill=(76, 84, 92), font=font(44))
    draw.rounded_rectangle((84, 1830, SIZE[0] - 84, 2120), radius=42, fill=(255, 255, 255), outline=(225, 232, 236), width=2)
    draw.text((132, 1895), "Samantha Translate", fill=(14, 18, 22), font=font(48, True))
    draw.text((132, 1975), "Real-time voice translation", fill=(76, 84, 92), font=font(36))
    draw.rounded_rectangle((84, 2350, SIZE[0] - 84, 2490), radius=40, fill=(16, 20, 24))
    draw.text((280, 2392), "Start 3-day free trial", fill=(255, 255, 255), font=font(42, True))
    return img

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lines = ["# Screenshot Manifest", "", "Device class: iPhone 6.9 portrait", "Pixel size: 1320x2868", ""]
    for filename, title, subtitle in SCREENS:
        make_screen(title, subtitle).save(OUT / filename)
        lines.append(f"- `{filename}` - {title} - 1320x2868")
    (OUT / "screenshot-manifest.md").write_text("\n".join(lines) + "\n")

if __name__ == "__main__":
    main()

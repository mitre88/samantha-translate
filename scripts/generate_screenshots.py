from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "AppStore" / "Screenshots" / "generated"
SIZE = (1320, 2868)

SCREENS = [
    {
        "file": "01-live-orb.png",
        "title": "Listen once. Understand now.",
        "subtitle": "Samantha hears speech and speaks the translation in your language.",
        "scene": "orb",
        "accent": (132, 229, 255),
    },
    {
        "file": "02-conversation.png",
        "title": "Built for live conversations",
        "subtitle": "Auto-detects the speaker and returns natural translated speech.",
        "scene": "conversation",
        "accent": (175, 244, 213),
    },
    {
        "file": "03-trial-paywall.png",
        "title": "Try Pro for 3 days",
        "subtitle": "Then $4.99/week through Apple. Cancel anytime in Apple settings.",
        "scene": "paywall",
        "accent": (255, 214, 122),
    },
    {
        "file": "04-language-control.png",
        "title": "Your output language stays clear",
        "subtitle": "Choose the language Samantha speaks back to you.",
        "scene": "languages",
        "accent": (178, 169, 255),
    },
    {
        "file": "05-private-mode.png",
        "title": "Private by design",
        "subtitle": "No saved audio, no transcript history, no chat memory.",
        "scene": "privacy",
        "accent": (255, 173, 188),
    },
    {
        "file": "06-interview-mode.png",
        "title": "Useful when the room moves fast",
        "subtitle": "For interviews, travel, calls, and quick language switches.",
        "scene": "interview",
        "accent": (120, 224, 190),
    },
]


def font(size, bold=False):
    names = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for name in names:
        try:
            return ImageFont.truetype(name, size=size)
        except Exception:
            pass
    return ImageFont.load_default()


def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def text(draw, xy, value, size, fill, bold=False, max_width=None, line_gap=12):
    selected = font(size, bold)
    if not max_width:
        draw.text(xy, value, fill=fill, font=selected)
        return draw.textbbox(xy, value, font=selected)[3]

    words = value.split()
    lines = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if draw.textlength(candidate, font=selected) <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    y = xy[1]
    for line in lines:
        draw.text((xy[0], y), line, fill=fill, font=selected)
        y += size + line_gap
    return y


def header(draw, title, subtitle, accent):
    rounded(draw, (72, 92, 1248, 2780), 52, (248, 250, 251))
    draw.ellipse((-190, -280, 760, 670), fill=tuple(min(255, int(c * 0.42 + 150)) for c in accent))
    draw.ellipse((760, 2100, 1570, 2910), fill=tuple(min(255, int(c * 0.35 + 165)) for c in accent))
    text(draw, (132, 250), title, 78, (12, 17, 22), True, max_width=1056, line_gap=18)
    text(draw, (132, 470), subtitle, 38, (87, 94, 101), False, max_width=980, line_gap=10)


def draw_orb(draw, cx, cy, radius, accent, active=True):
    for offset, alpha in [(90, 32), (48, 45), (0, 255)]:
        fill = tuple(min(255, int(c + (255 - c) * 0.55)) for c in accent) if offset else (255, 255, 255)
        draw.ellipse((cx - radius - offset, cy - radius - offset, cx + radius + offset, cy + radius + offset), fill=fill)
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(255, 255, 255), outline=(214, 225, 230), width=3)
    bar_color = (15, 20, 26)
    heights = [150, 260, 370, 250, 150] if active else [110, 150, 190, 150, 110]
    x0 = cx - 150
    for index, height in enumerate(heights):
        x = x0 + index * 75
        rounded(draw, (x, cy - height // 2, x + 30, cy + height // 2), 15, bar_color)


def phone_frame(draw, x, y, w, h):
    rounded(draw, (x, y, x + w, y + h), 60, (16, 21, 27))
    rounded(draw, (x + 22, y + 24, x + w - 22, y + h - 24), 42, (252, 253, 253))
    draw.rounded_rectangle((x + w // 2 - 80, y + 42, x + w // 2 + 80, y + 60), radius=9, fill=(33, 39, 47))


def scene_orb(draw, accent):
    draw_orb(draw, 660, 1220, 280, accent)
    rounded(draw, (180, 1680, 1140, 1960), 38, (255, 255, 255), (220, 229, 234), 2)
    text(draw, (240, 1740), "English detected", 34, (89, 97, 105))
    text(draw, (240, 1810), "Speaking Spanish", 54, (14, 19, 24), True)
    rounded(draw, (380, 2220, 940, 2370), 44, (15, 20, 26))
    text(draw, (476, 2264), "Start listening", 42, (255, 255, 255), True)


def scene_conversation(draw, accent):
    phone_frame(draw, 210, 790, 900, 1440)
    text(draw, (300, 900), "Live Translation", 44, (16, 22, 28), True)
    bubbles = [
        ((300, 1040, 930, 1210), "Can you explain your last project?", (238, 244, 247)),
        ((390, 1280, 1020, 1490), "Puedes explicar tu ultimo proyecto?", (222, 250, 238)),
        ((300, 1580, 890, 1750), "Claro, I led the mobile release.", (238, 244, 247)),
        ((390, 1820, 1020, 2030), "Sure. I led the mobile release.", (222, 250, 238)),
    ]
    for box, value, fill in bubbles:
        rounded(draw, box, 34, fill)
        text(draw, (box[0] + 34, box[1] + 40), value, 34, (16, 22, 28), max_width=box[2] - box[0] - 68)
    draw_orb(draw, 660, 2320, 140, accent, active=False)


def scene_paywall(draw, accent):
    rounded(draw, (160, 790, 1160, 2200), 44, (255, 255, 255), (220, 229, 234), 2)
    draw_orb(draw, 660, 1040, 130, accent, active=False)
    text(draw, (250, 1250), "Samantha Translate Pro", 52, (14, 19, 24), True, max_width=820)
    rows = [
        ("3-day free trial", "Then $4.99/week"),
        ("Native Apple checkout", "Purchase, restore, and cancel with Apple"),
        ("No API keys", "The app handles access for you"),
    ]
    y = 1430
    for title, subtitle in rows:
        draw.ellipse((250, y + 8, 304, y + 62), fill=(17, 23, 29))
        text(draw, (334, y), title, 38, (16, 22, 28), True)
        text(draw, (334, y + 52), subtitle, 28, (94, 101, 108))
        y += 165
    rounded(draw, (250, 1960, 1070, 2100), 38, (15, 20, 26))
    text(draw, (392, 1998), "Start free trial", 42, (255, 255, 255), True)


def scene_languages(draw, accent):
    languages = [("English", "EN"), ("Espanol", "ES"), ("Francais", "FR"), ("Chinese", "ZH"), ("Japanese", "JA")]
    y = 790
    for index, (name, code) in enumerate(languages):
        box = (170, y, 1150, y + 210)
        fill = (255, 255, 255) if index != 1 else (232, 229, 255)
        rounded(draw, box, 34, fill, (222, 229, 234), 2)
        rounded(draw, (220, y + 48, 330, y + 158), 34, (16, 22, 28) if index == 1 else (236, 240, 242))
        text(draw, (248, y + 80), code, 30, (255, 255, 255) if index == 1 else (37, 44, 51), True)
        text(draw, (380, y + 52), name, 44, (14, 19, 24), True)
        text(draw, (380, y + 112), "Spoken output language", 28, (92, 99, 106))
        y += 250


def scene_privacy(draw, accent):
    draw_orb(draw, 660, 930, 170, accent, active=False)
    items = [
        ("No audio library", "Voice is processed for translation, not saved by us."),
        ("No transcript history", "The app does not build a conversation archive."),
        ("Subscription only", "Apple handles trial, renewal, and cancellation."),
    ]
    y = 1300
    for title, subtitle in items:
        rounded(draw, (170, y, 1150, y + 240), 34, (255, 255, 255), (222, 229, 234), 2)
        rounded(draw, (230, y + 62, 334, y + 166), 30, (16, 22, 28))
        draw.line((258, y + 114, 306, y + 114), fill=(255, 255, 255), width=10)
        text(draw, (380, y + 58), title, 40, (15, 20, 26), True)
        text(draw, (380, y + 118), subtitle, 28, (92, 99, 106), max_width=670)
        y += 295


def scene_interview(draw, accent):
    rounded(draw, (150, 790, 1170, 1250), 42, (255, 255, 255), (220, 229, 234), 2)
    text(draw, (220, 880), "Question heard", 30, (92, 99, 106))
    text(draw, (220, 945), "Tell us about a time you solved a hard technical problem.", 42, (15, 20, 26), True, max_width=870)
    rounded(draw, (150, 1370, 1170, 1850), 42, (227, 249, 239), (198, 237, 218), 2)
    text(draw, (220, 1460), "Spanish meaning", 30, (67, 114, 91))
    text(draw, (220, 1525), "Cuentanos de una vez que resolviste un problema tecnico dificil.", 42, (15, 20, 26), True, max_width=870)
    rounded(draw, (150, 1970, 1170, 2220), 42, (255, 255, 255), (220, 229, 234), 2)
    text(draw, (220, 2045), "Speak back in English", 34, (15, 20, 26), True)
    text(draw, (220, 2110), "Natural output for fast interview practice.", 30, (92, 99, 106))


SCENE_DRAWERS = {
    "orb": scene_orb,
    "conversation": scene_conversation,
    "paywall": scene_paywall,
    "languages": scene_languages,
    "privacy": scene_privacy,
    "interview": scene_interview,
}


def make_screen(spec):
    img = Image.new("RGB", SIZE, (7, 10, 13))
    draw = ImageDraw.Draw(img)
    header(draw, spec["title"], spec["subtitle"], spec["accent"])
    SCENE_DRAWERS[spec["scene"]](draw, spec["accent"])
    text(draw, (132, 2620), "Samantha Translate", 34, (91, 98, 105), True)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Screenshot Manifest",
        "",
        "Device class: iPhone 6.9 portrait",
        "Pixel size: 1320x2868",
        "Generated from distinct product states, not repeated templates.",
        "",
    ]
    for spec in SCREENS:
        make_screen(spec).save(OUT / spec["file"])
        lines.append(f"- `{spec['file']}` - {spec['title']} - 1320x2868")
    (OUT / "screenshot-manifest.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()

"""Draws the mod icon in the usual ModHub script-mod style: dark textured
background, white line-art tractor pressed onto the ground, title below.
Run: python tools/icon.py  (writes docs/icon.png and the mod's .dds)"""
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 512
ROOT = Path(__file__).resolve().parent.parent
WHITE, GREEN = (245, 245, 240, 255), (126, 186, 64, 255)

img = Image.new("RGBA", (S, S), (38, 38, 38, 255))
noise = Image.new("L", (S, S))
random.seed(7)
noise.putdata([random.randint(0, 40) for _ in range(S * S)])
img = Image.composite(Image.new("RGBA", (S, S), (52, 52, 52, 255)), img, noise.filter(ImageFilter.GaussianBlur(1)))
d = ImageDraw.Draw(img)

W = 14  # line width
ground = 330

# ground line with a small dip: the ditch the tractor stays planted in
d.line([(40, ground), (472, ground)], fill=WHITE, width=W)

# wheels sit on the ground line
def wheel(cx, r):
    d.ellipse([cx - r, ground - 2 * r, cx + r, ground], outline=WHITE, width=W)
    d.ellipse([cx - r * 0.35, ground - r - r * 0.35, cx + r * 0.35, ground - r + r * 0.35], fill=WHITE)

wheel(330, 82)
wheel(150, 52)

# body and cab as line art
d.line([(110, 232), (110, 196), (240, 196)], fill=WHITE, width=W, joint="curve")
d.line([(240, 196), (240, 92), (372, 92), (390, 170)], fill=WHITE, width=W, joint="curve")
d.line([(200, 196), (200, 128)], fill=WHITE, width=W)  # exhaust
d.line([(256, 110), (356, 110), (370, 168), (256, 168), (256, 110)], fill=WHITE, width=8, joint="curve")

# green chevrons: "weight down"
for y in (30, 62):
    d.line([(388, y), (428, y + 26), (468, y)], fill=GREEN, width=12, joint="curve")

font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 54)
for text, y in (("GROUNDED", 362), ("TRACTORS", 426)):
    w = d.textlength(text, font=font)
    d.text(((S - w) / 2, y), text, font=font, fill=WHITE if text == "GROUNDED" else GREEN)

img.save(ROOT / "docs" / "icon.png")
img.convert("RGB").save(ROOT / "FS25_GroundedTractors" / "icon_GroundedTractors.dds", pixel_format="DXT1")
print("ok")

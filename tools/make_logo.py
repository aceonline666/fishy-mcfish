"""Renders the game logo, the boot splash and the app icons from the title font and the painted
sprites.

Writes assets/ui/logo.png (title with a nautilus), assets/ui/splash.png (portrait boot
splash: sea, logo, the wader on the beach), assets/ui/icon.png and the Android adaptive icon
layers assets/ui/icon_foreground.png and assets/ui/icon_background.png.

Needs Pillow and NumPy. Usage (from the project folder):
  python tools/make_logo.py
"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = "art_source/fonts/LuckiestGuy-Regular.ttf"
OUT = "assets/ui/"
NAVY = (16, 35, 63, 255)
SKY = (120, 220, 235)
DEEP = (10, 70, 140)


def title(width: int) -> Image.Image:
    """"FISHY / McFISH" in yellow-to-orange letters with a navy outline and a drop shadow."""
    height = int(width * 0.55)
    size = int(width * 0.2)
    font = ImageFont.truetype(FONT, size)
    small = ImageFont.truetype(FONT, int(size * 0.62))
    # The font only has capitals: the c of "Mc" is a smaller capital on the baseline.
    lines = [([("FISHY", font)], 0.0), ([("M", font), ("C", small), ("FISH", font)], 0.47)]
    stroke = max(4, size // 9)
    text_mask = Image.new("L", (width, height))
    outline_mask = Image.new("L", (width, height))
    for parts, y in lines:
        widths = [font_part.getbbox(text)[2] for text, font_part in parts]
        x = (width - sum(widths)) // 2
        baseline = int(height * (0.06 + y)) + stroke + font.getbbox("M")[3]
        for (text, font_part), part_width in zip(parts, widths):
            top = baseline - font_part.getbbox(text)[3]
            for mask, extra in ((text_mask, 0), (outline_mask, stroke)):
                ImageDraw.Draw(mask).text((x, top), text, font=font_part, fill=255, stroke_width=extra, stroke_fill=255)
            x += part_width
    out = Image.new("RGBA", (width, height))
    shadow = Image.new("RGBA", (width, height), (0, 20, 40, 150))
    out.paste(shadow, (stroke // 2, stroke), outline_mask)
    out.paste(Image.new("RGBA", (width, height), NAVY), (0, 0), outline_mask)
    gradient = np.zeros((height, width, 4), np.uint8)
    for row in range(height):
        t = (row % (height // 2)) / (height / 2)
        gradient[row] = (255, int(225 - 95 * t), int(70 - 50 * t), 255)
    out.paste(Image.fromarray(gradient), (0, 0), text_mask)
    # A light shine on the upper half of each letter.
    shine = Image.new("L", (width, height))
    draw = ImageDraw.Draw(shine)
    for _, y in lines:
        top = int(height * (0.06 + y)) + stroke + font.getbbox("M")[1]
        draw.rectangle([0, top, width, top + size * 0.28], fill=90)
    shine = Image.composite(shine, Image.new("L", (width, height)), text_mask)
    out.paste(Image.new("RGBA", (width, height), (255, 255, 255, 255)), (0, 0), shine)
    return out


def painted_fish(species: str, length: int) -> Image.Image:
    """A painted fish from its body and tail sprites, facing right."""
    body = Image.open(f"assets/sprites/fish_painted/{species}_body.png")
    tail = Image.open(f"assets/sprites/fish_painted/{species}_tail.png")
    unit = body.width / 240.0
    canvas = Image.new("RGBA", (body.width + tail.width, max(body.height, tail.height)))
    root_x = int(62 * unit)
    canvas.alpha_composite(tail, (0, (canvas.height - tail.height) // 2))
    canvas.alpha_composite(body, (root_x - int(20 * unit), (canvas.height - body.height) // 2))
    box = canvas.getbbox()
    canvas = canvas.crop(box)
    scale = length / canvas.width
    return canvas.resize((length, int(canvas.height * scale)), Image.LANCZOS)


def bubbles(image: Image.Image, area: tuple, count: int, seed: int) -> None:
    rng = random.Random(seed)
    draw = ImageDraw.Draw(image)
    for _ in range(count):
        r = rng.randint(6, 22)
        x = rng.randint(area[0], area[2])
        y = rng.randint(area[1], area[3])
        draw.ellipse([x - r, y - r, x + r, y + r], outline=(255, 255, 255, 200), width=max(2, r // 5))
        draw.ellipse([x - r * 0.45, y - r * 0.55, x - r * 0.1, y - r * 0.2], fill=(255, 255, 255, 190))


def logo() -> Image.Image:
    width = 1024
    words = title(width)
    out = Image.new("RGBA", (width, words.height + 140))
    fish = painted_fish("chambered_nautilus", 280).rotate(-10, expand=True, resample=Image.BICUBIC)
    bubbles(out, (40, 20, 300, 160), 6, 3)
    out.alpha_composite(words, (0, 120))
    out.alpha_composite(fish, (width - fish.width - 20, 0))
    return out.crop(out.getbbox())


def sea_gradient(width: int, height: int) -> Image.Image:
    rows = np.linspace(0.0, 1.0, height)[:, None]
    sky = np.array(SKY, float)
    deep = np.array(DEEP, float)
    colors = sky + (deep - sky) * rows ** 0.8
    image = np.repeat(colors[:, None, :], width, axis=1).astype(np.uint8)
    return Image.fromarray(image).convert("RGBA")


def splash() -> Image.Image:
    width, height = 1080, 1920
    out = sea_gradient(width, height)
    # Sun rays from the top.
    rays = Image.new("L", (width, height))
    draw = ImageDraw.Draw(rays)
    for i in range(7):
        x = 120 + i * 150
        draw.polygon([(x, 0), (x + 70, 0), (x + 260, height * 0.75), (x + 130, height * 0.75)], fill=40)
    out.paste(Image.new("RGBA", (width, height), (255, 255, 255, 255)), (0, 0), rays.filter(ImageFilter.GaussianBlur(30)))
    bubbles(out, (60, 900, 1020, 1500), 22, 7)
    for species, x, y, length, flip in (("yellowfin_tuna", 90, 1150, 280, False), ("opah", 730, 1040, 230, True),
                                        ("red_sea_bream", 230, 1390, 200, False), ("moon_jellyfish", 760, 1330, 170, False)):
        fish = painted_fish(species, length)
        if flip:
            fish = fish.transpose(Image.FLIP_LEFT_RIGHT)
        out.alpha_composite(fish, (x, y))
    # Sand at the bottom with the wader.
    sand = Image.new("L", (width, height))
    draw = ImageDraw.Draw(sand)
    draw.ellipse([-300, 1600, width + 300, 2400], fill=255)
    out.paste(Image.new("RGBA", (width, height), (240, 214, 150, 255)), (0, 0), sand)
    wader = Image.open("assets/sprites/props/wader_front.png")
    wader = wader.resize((int(wader.width * 2.6), int(wader.height * 2.6)), Image.LANCZOS)
    out.alpha_composite(wader, ((width - wader.width) // 2, 1640 - wader.height + 60))
    mark = logo()
    mark = mark.resize((960, int(mark.height * 960 / mark.width)), Image.LANCZOS)
    out.alpha_composite(mark, ((width - mark.width) // 2, 260))
    return out


def icon_background(size: int) -> Image.Image:
    out = sea_gradient(size, size)
    bubbles(out, (int(size * 0.1), int(size * 0.55), int(size * 0.9), int(size * 0.9)), 5, 11)
    return out


def icon_foreground(size: int, fish_share: float) -> Image.Image:
    out = Image.new("RGBA", (size, size))
    fish = painted_fish("chambered_nautilus", int(size * fish_share)).rotate(-8, expand=True, resample=Image.BICUBIC)
    out.alpha_composite(fish, ((size - fish.width) // 2, (size - fish.height) // 2))
    return out


def rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, image.width - 1, image.height - 1], radius, fill=255)
    out = Image.new("RGBA", image.size)
    out.paste(image, (0, 0), mask)
    return out


def main() -> None:
    logo().save(OUT + "logo.png")
    splash().save(OUT + "splash.png")
    icon = icon_background(512)
    icon.alpha_composite(icon_foreground(512, 0.82))
    rounded(icon, 110).save(OUT + "icon.png")
    # Adaptive icons: the launcher masks the layers; keep the fish in the middle two thirds.
    icon_background(432).save(OUT + "icon_background.png")
    icon_foreground(432, 0.6).save(OUT + "icon_foreground.png")
    print("written logo, splash and icons")


if __name__ == "__main__":
    main()

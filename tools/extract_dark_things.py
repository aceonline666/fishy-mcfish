"""Cuts the things in the dark out of art_source/props/dark_things_sheet.png (transparent
background; prompt in art_source/props/secrets_sprite_prompt.md): the deep sea horror from the
top two thirds and the four pairs of glowing eyes from the bottom third, each trimmed to its
visible pixels and scaled down.

Writes assets/sprites/props/deep_horror.png and eyes_1.png ... eyes_4.png.

Needs Pillow and NumPy. Usage (from the project folder):
  python tools/extract_dark_things.py
"""
from PIL import Image

SHEET = "art_source/props/dark_things_sheet.png"
OUT = "assets/sprites/props/"
HORROR_SCALE = 0.6
EYES_SCALE = 0.5
# Fainter pixels than this count as empty when trimming.
VISIBLE = 8


def trimmed(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A").point(lambda a: 255 if a >= VISIBLE else 0)
    return image.crop(alpha.getbbox())


def scaled(image: Image.Image, factor: float) -> Image.Image:
    return image.resize((round(image.width * factor), round(image.height * factor)), Image.LANCZOS)


def main() -> None:
    sheet = Image.open(SHEET).convert("RGBA")
    split = sheet.height * 2 // 3
    scaled(trimmed(sheet.crop((0, 0, sheet.width, split))), HORROR_SCALE).save(OUT + "deep_horror.png")
    quarter = sheet.width // 4
    for i in range(4):
        cell = sheet.crop((i * quarter, split, (i + 1) * quarter, sheet.height))
        scaled(trimmed(cell), EYES_SCALE).save(OUT + f"eyes_{i + 1}.png")
    print("written deep_horror.png and eyes_1..4.png")


if __name__ == "__main__":
    main()

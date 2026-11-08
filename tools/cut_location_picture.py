"""Cuts a generated location picture to a world map card picture: crops it to the 4:5 portrait
of the other pictures (centred) and scales it to their size.

Writes assets/sprites/props/location_<id>.png. Prompts: art_source/props/location_pictures_prompt.md.

Needs Pillow. Usage (from the project folder):
  python tools/cut_location_picture.py art_source/props/location_antarctica.png antarctica
"""
import sys

from PIL import Image

# The cards' pictures: 4 wide to 5 high, this many pixels high (as the ones from the gear sheet).
ASPECT = 0.8
HEIGHT = 315


def main() -> None:
    source = Image.open(sys.argv[1]).convert("RGB")
    width = min(source.width, round(source.height * ASPECT))
    height = round(width / ASPECT)
    left = (source.width - width) // 2
    top = (source.height - height) // 2
    picture = source.crop((left, top, left + width, top + height))
    picture = picture.resize((round(HEIGHT * ASPECT), HEIGHT), Image.LANCZOS)
    out = f"assets/sprites/props/location_{sys.argv[2]}.png"
    picture.save(out)
    print("written", out, picture.size)


if __name__ == "__main__":
    main()

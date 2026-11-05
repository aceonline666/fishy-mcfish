"""Draws the perspective guide for generating the gear shop's displays (the props behind the pads,
art_source/store/fixture_sprite_prompts.md).

A display stands on one cell against the room's west or north wall, or free in the room. In the style of the tank guides: the
footprint (grey), the wall behind it (green, a marker only) and the largest box the display
may fill (dashed). Same geometry as the level 1 tank: one
cell at E px per cell edge (E across, E/2 down), the footprint's bottom corner at BOTTOM.

Needs Pillow. Usage:
  python tools/make_fixture_guide.py art_source/store
writes art_source/store/fixture_perspective_guide.svg and .png (west wall, on the footprint's
upper-left edge), fixture_perspective_guide_north.svg and .png (north wall, upper-right edge) and
fixture_perspective_guide_free.svg and .png (no wall, at most FREE_HEIGHT tall).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = (1024, 1024)
E = 240
BOTTOM = (512, 880)
HEIGHT = 360
FREE_HEIGHT = 240
WALL = 430


def at(i: float, j: float, h: float = 0.0) -> tuple:
    """Cell coordinates from the back corner: i east (down-right), j south (down-left), h up."""
    back = (BOTTOM[0], BOTTOM[1] - E)
    return (back[0] + (i - j) * E, back[1] + (i + j) * E / 2 - h)


def shapes(wall: str) -> list:
    """(kind, points, fill, opacity, stroke, width) from back to front."""
    HEIGHT = FREE_HEIGHT if wall == "free" else globals()["HEIGHT"]
    out = []
    if wall != "free":
        end = at(0, 1) if wall == "west" else at(1, 0)
        out.append(("polygon", [at(0, 0), end, (end[0], end[1] - WALL), at(0, 0, WALL)], "#3cb371", 0.25, "#1e7a45", 3))
    return out + [
        ("polygon", [at(0, 0), at(1, 0), at(1, 1), at(0, 1)], "#d9d9d9", 1.0, "#555", 3),
        ("dashed", [at(0, 0, HEIGHT), at(1, 0, HEIGHT), at(1, 1, HEIGHT), at(0, 1, HEIGHT), at(0, 0, HEIGHT)], None, 1.0, "#999", 2),
        ("dashed", [at(1, 0), at(1, 0, HEIGHT)], None, 1.0, "#999", 2),
        ("dashed", [at(1, 1), at(1, 1, HEIGHT)], None, 1.0, "#999", 2),
        ("dashed", [at(0, 1), at(0, 1, HEIGHT)], None, 1.0, "#999", 2),
    ]


def svg(items: list, wall: str) -> str:
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE[0]}" height="{SIZE[1]}" viewBox="0 0 {SIZE[0]} {SIZE[1]}">',
             f"<!-- Gear shop display, 1 x 1 cell at {E} px per cell edge, bottom corner {BOTTOM}, at most "
             f"{FREE_HEIGHT if wall == "free" else HEIGHT} px tall, wall behind: {wall}. See art_source/store/fixture_sprite_prompts.md. -->",
             f'<rect width="{SIZE[0]}" height="{SIZE[1]}" fill="#ffffff"/>']
    for kind, points, fill, opacity, stroke, width in items:
        pts = " ".join(f"{x:g},{y:g}" for x, y in points)
        if kind == "polygon":
            lines.append(f'<polygon points="{pts}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{width}"/>')
        else:
            lines.append(f'<polyline points="{pts}" fill="none" stroke="{stroke}" stroke-width="{width}" stroke-dasharray="10,8"/>')
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def png(items: list) -> Image.Image:
    image = Image.new("RGBA", SIZE, "#ffffff")
    for kind, points, fill, opacity, stroke, width in items:
        layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        if kind == "polygon":
            rgb = tuple(int(fill[k:k + 2], 16) for k in (1, 3, 5))
            draw.polygon(points, fill=rgb + (int(255 * opacity),))
            draw.line(points + [points[0]], fill=stroke, width=width, joint="curve")
        else:
            for a, b in zip(points, points[1:]):
                _dashed(draw, a, b, stroke, width)
        image = Image.alpha_composite(image, layer)
    return image.convert("RGB")


def _dashed(draw: ImageDraw.ImageDraw, a: tuple, b: tuple, color: str, width: int, dash: float = 10, gap: float = 8) -> None:
    length = ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5
    t = 0.0
    while t < length:
        u, v = t / length, min(t + dash, length) / length
        draw.line([(a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u), (a[0] + (b[0] - a[0]) * v, a[1] + (b[1] - a[1]) * v)], fill=color, width=width)
        t += dash + gap


def main() -> None:
    out = Path(sys.argv[1])
    for wall, name in [("west", "fixture_perspective_guide"), ("north", "fixture_perspective_guide_north"),
                       ("free", "fixture_perspective_guide_free")]:
        items = shapes(wall)
        stem = out / name
        stem.with_suffix(".svg").write_text(svg(items, wall), encoding="utf-8")
        png(items).save(stem.with_suffix(".png"))


if __name__ == "__main__":
    main()

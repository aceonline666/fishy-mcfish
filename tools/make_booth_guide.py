"""Draws the perspective guide for generating the booth row (art_source/buildings/
booth_row_sprite_prompt.md).

The booths stand in a line up the beach (FishingScene.BOOTH_COLUMN), one cell each, their counters
along the cells' east edges, facing east to the buyers. The guide shows a run of three cells so the
painting has its joins drawn; the middle segment (blue) is cut out between its posts' centres and
repeated. Grey: the cells; brown: each booth's footprint (DEPTH of a cell, at the east edge);
green: the counter front, facing the buyers; dashed: the highest the awning may reach; black: the
four shared front posts; orange: the awning's front edge, above the head of a cashier as tall as
the wader standing behind the counter (no figures are drawn: the generator would paint them in).

Needs Pillow. Usage:
  python tools/make_booth_guide.py art_source/buildings
writes art_source/buildings/booth_row_perspective_guide.svg and .png.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = (1536, 1024)
E = 300
# Ground cell (0, 0) north-west corner on screen; cells run south (down-left).
ORIGIN = (986, 410)
CELLS = 3
DEPTH = 0.45
COUNTER = 190
TOP = 480
AWNING = 420
PERSON = 381


def at(i: float, j: float, h: float = 0.0) -> tuple:
    """i cells east (down-right), j cells south (down-left), h px up."""
    return (ORIGIN[0] + (i - j) * E, ORIGIN[1] + (i + j) * E / 2 - h)


def shapes() -> list:
    back = 1.0 - DEPTH
    out = []
    for j in range(CELLS):
        out.append(("polygon", [at(0, j), at(1, j), at(1, j + 1), at(0, j + 1)], "#d9d9d9", 1.0, "#555", 2))
    for j in range(CELLS):
        out.append(("polygon", [at(back, j), at(1, j), at(1, j + 1), at(back, j + 1)], "#a0522d", 0.35, "#6b3519", 3))
    out.append(("dashed", [at(back, 0, TOP), at(1, 0, TOP), at(1, CELLS, TOP), at(back, CELLS, TOP), at(back, 0, TOP)], None, 1.0, "#999", 2))
    for j in range(CELLS):
        fill, stroke, opacity = ("#4a90d9", "#1f5fa8", 0.35) if j == 1 else ("#3cb371", "#1e7a45", 0.3)
        out.append(("polygon", [at(1, j), at(1, j + 1), at(1, j + 1, COUNTER), at(1, j, COUNTER)], fill, opacity, stroke, 3))
    # The awning's front edge, high enough for a cashier as tall as the wader (PERSON, 1.27 cell
    # edges) behind the counter. No figures in the guide: the generator paints them in.
    out.append(("line", [at(1, 0, AWNING), at(1, CELLS, AWNING)], None, 1.0, "#e67e22", 6))
    for j in range(CELLS + 1):
        out.append(("line", [at(1, j), at(1, j, TOP - 40)], None, 1.0, "#000", 5))
        out.append(("dashed", [at(back, j), at(back, j, TOP - 40)], None, 1.0, "#555", 3))
    return out


def svg(items: list) -> str:
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE[0]}" height="{SIZE[1]}" viewBox="0 0 {SIZE[0]} {SIZE[1]}">',
             f"<!-- Booth row: {CELLS} cells along ground y at {E} px per cell edge, booth {DEPTH} cell deep at the east "
             f"edge, counter {COUNTER} px, top {TOP} px; middle segment blue. See art_source/buildings/booth_row_sprite_prompt.md. -->",
             f'<rect width="{SIZE[0]}" height="{SIZE[1]}" fill="#ffffff"/>']
    for kind, points, fill, opacity, stroke, width in items:
        pts = " ".join(f"{x:g},{y:g}" for x, y in points)
        if kind == "polygon":
            lines.append(f'<polygon points="{pts}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{width}"/>')
        elif kind == "dashed":
            lines.append(f'<polyline points="{pts}" fill="none" stroke="{stroke}" stroke-width="{width}" stroke-dasharray="10,8"/>')
        else:
            lines.append(f'<polyline points="{pts}" fill="none" stroke="{stroke}" stroke-width="{width}"/>')
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
        elif kind == "dashed":
            for a, b in zip(points, points[1:]):
                _dashed(draw, a, b, stroke, width)
        else:
            draw.line(points, fill=stroke, width=width)
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
    items = shapes()
    stem = out / "booth_row_perspective_guide"
    stem.with_suffix(".svg").write_text(svg(items), encoding="utf-8")
    png(items).save(stem.with_suffix(".png"))


if __name__ == "__main__":
    main()

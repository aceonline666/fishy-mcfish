"""Draws the perspective guides for generating the tank sprites (art_source/tank_sprite_prompt.md).

One guide per level, in the style of the booth and gear shop guides: the footprint with its cells
(grey), the base (brown), the glass box's front-left face (green) and front-right face (blue), the
three front corner posts (black, solid) and the back post and back rim (dashed). The geometry is
the prompt's table: footprint W x D cells at e px per cell edge (e across, e/2 down), the bottom
corner, the base and glass heights.

Needs Pillow. Usage:
  python tools/make_tank_guides.py art_source [level ...]
writes art_source/tank_<level>_perspective_guide.svg and .png (all levels without a level given).
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

# Level: (W, D, e, canvas, bottom corner, base height, glass height), as in the prompt's table.
LEVELS = {
    1: (1, 1, 240, (1024, 1024), (512, 880), 80, 160),
    2: (2, 1, 240, (1024, 1024), (632, 900), 80, 200),
    3: (2, 2, 240, (1536, 1024), (768, 940), 70, 240),
    4: (2, 3, 200, (1536, 1024), (668, 960), 60, 215),
    5: (3, 3, 200, (1536, 1024), (768, 980), 50, 235),
    6: (3, 4, 180, (1536, 1024), (678, 980), 45, 225),
    7: (3, 5, 160, (1536, 1024), (608, 980), 40, 215),
}


def main() -> None:
    out = Path(sys.argv[1])
    for level in [int(a) for a in sys.argv[2:]] or LEVELS:
        shapes = _shapes(*LEVELS[level])
        size = LEVELS[level][3]
        stem = out / f"tank_{level}_perspective_guide"
        stem.with_suffix(".svg").write_text(_svg(level, size, shapes), encoding="utf-8")
        _png(size, shapes).save(stem.with_suffix(".png"))


def _shapes(w: int, d: int, e: int, size: tuple, bottom: tuple, base: int, glass: int) -> list:
    """(kind, points, fill, opacity, stroke, width) from back to front."""
    def at(i: float, j: float, h: float = 0.0) -> tuple:
        # Cell coordinates from the back corner: i cells east (down-right), j cells south (down-left).
        back = (bottom[0] + (d - w) * e, bottom[1] - (w + d) * e / 2)
        return (back[0] + (i - j) * e, back[1] + (i + j) * e / 2 - h)

    left, front, right, back = at(0, d), at(w, d), at(w, 0), at(0, 0)
    top = base + glass
    shapes = [("polygon", [left, front, right, back], "#d9d9d9", 1.0, "#555", 3)]
    shapes += [("line", [at(i, 0), at(i, d)], None, 1.0, "#888", 2) for i in range(1, w)]
    shapes += [("line", [at(0, j), at(w, j)], None, 1.0, "#888", 2) for j in range(1, d)]
    shapes += [
        ("dashed", [at(0, 0, base), at(0, 0, top)], None, 1.0, "#999", 2),
        ("dashed", [at(0, d, top), at(0, 0, top), at(w, 0, top)], None, 1.0, "#999", 2),
        ("dashed", [at(0, d, base), at(0, 0, base), at(w, 0, base)], None, 1.0, "#999", 2),
        ("polygon", [left, front, at(w, d, base), at(0, d, base)], "#a0522d", 0.35, "#6b3519", 4),
        ("polygon", [front, right, at(w, 0, base), at(w, d, base)], "#a0522d", 0.25, "#6b3519", 4),
        ("polygon", [at(0, d, base), at(w, d, base), at(w, d, top), at(0, d, top)], "#3cb371", 0.35, "#1e7a45", 4),
        ("polygon", [at(w, d, base), at(w, 0, base), at(w, 0, top), at(w, d, top)], "#4a90d9", 0.3, "#1f5fa8", 4),
    ]
    shapes += [("line", [at(i, j, base), at(i, j, top)], None, 1.0, "#222", 5) for i, j in [(0, d), (w, d), (w, 0)]]
    return shapes


def _svg(level: int, size: tuple, shapes: list) -> str:
    w, d, e, _, bottom, base, glass = LEVELS[level]
    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size[0]}" height="{size[1]}" viewBox="0 0 {size[0]} {size[1]}">',
        f"<!-- Tank level {level}, footprint {w} x {d} cells at {e} px per cell edge; bottom corner {bottom},",
        f"base {base} px, glass {glass} px (tools/make_tank_guides.py). -->",
        f'<rect width="{size[0]}" height="{size[1]}" fill="#ffffff"/>',
    ]
    for kind, points, fill, opacity, stroke, width in shapes:
        coords = " ".join(f"{x:g},{y:g}" for x, y in points)
        if kind == "polygon":
            lines.append(f'<polygon points="{coords}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{width}"/>')
        else:
            dash = ' stroke-dasharray="10,8"' if kind == "dashed" else ""
            lines.append(f'<polyline points="{coords}" fill="none" stroke="{stroke}" stroke-width="{width}"{dash}/>')
    return "\n".join(lines + ["</svg>", ""])


def _png(size: tuple, shapes: list) -> Image.Image:
    image = Image.new("RGBA", size, "#ffffff")
    for kind, points, fill, opacity, stroke, width in shapes:
        layer = Image.new("RGBA", size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        if kind == "polygon":
            draw.polygon(points, fill=fill + "%02x" % round(opacity * 255))
            draw.line(points + points[:1], fill=stroke, width=width, joint="curve")
        elif kind == "line":
            draw.line(points, fill=stroke, width=width)
        else:
            for a, b in zip(points, points[1:]):
                _dashes(draw, a, b, stroke, width)
        image.alpha_composite(layer)
    return image.convert("RGB")


def _dashes(draw: ImageDraw.ImageDraw, a: tuple, b: tuple, color: str, width: int) -> None:
    length = ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5
    t = 0.0
    while t < length:
        u, v = t / length, min(t + 10.0, length) / length
        draw.line([(a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u),
                   (a[0] + (b[0] - a[0]) * v, a[1] + (b[1] - a[1]) * v)], fill=color, width=width)
        t += 18.0


if __name__ == "__main__":
    main()

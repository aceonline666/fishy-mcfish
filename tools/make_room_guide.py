"""Draws the perspective guide for generating the gear shop room sprite
(art_source/store/room_sprite_prompt.md).

In the style of the tank and gear shop guides: the floor with its cells (grey), the west wall
(green) and the north wall (blue), the wall segments behind the shelves and the desk (orange,
keep plain), the wall segment for the sea chart (purple) and the doormat (brown). The geometry is
the prompt's table: the room is UpgradeStore.ROOM_SIZE (7 x 7 cells) at E px per cell edge
(E across, E/2 down), its back (north-west) corner at BACK, walls WALL px tall.

Needs Pillow. Usage:
  python tools/make_room_guide.py art_source/store
writes art_source/store/room_perspective_guide.svg and .png.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = (1536, 1024)
CELLS = 7
E = 100
BACK = (768, 250)
WALL = 180
SLAB = 16
# Wall segments behind fixtures (UpgradeStore.FIXTURES): west wall by row from the back
# (row -4 -> 3, row -2 -> 5), north wall by column (shelf 1, desk 3).
WEST_FIXTURES = [3, 5]
NORTH_FIXTURES = [1, 3]
CHART_COLUMN = 5
DOOR_COLUMN = 3


def at(i: float, j: float, h: float = 0.0) -> tuple:
    """Cell coordinates from the back corner: i cells east (down-right), j cells south (down-left)."""
    return (BACK[0] + (i - j) * E, BACK[1] + (i + j) * E / 2 - h)


def shapes() -> list:
    """(kind, points, fill, opacity, stroke, width) from back to front."""
    n = CELLS
    back, right, front, left = at(0, 0), at(n, 0), at(n, n), at(0, n)
    out = [("polygon", [left, at(0, n, -SLAB), at(n, n, -SLAB), at(n, 0, -SLAB), right, front], "#a0522d", 0.35, "#6b3519", 3)]
    out.append(("polygon", [back, right, front, left], "#d9d9d9", 1.0, "#555", 3))
    out += [("line", [at(i, 0), at(i, n)], None, 1.0, "#888", 2) for i in range(1, n)]
    out += [("line", [at(0, j), at(n, j)], None, 1.0, "#888", 2) for j in range(1, n)]
    out.append(("polygon", [at(DOOR_COLUMN + 0.15, n - 0.6), at(DOOR_COLUMN + 0.85, n - 0.6),
                            at(DOOR_COLUMN + 0.85, n), at(DOOR_COLUMN + 0.15, n)], "#8b5a2b", 0.6, "#5a3a1a", 3))
    out.append(("polygon", [left, back, at(0, 0, WALL), at(0, n, WALL)], "#3cb371", 0.35, "#1e7a45", 4))
    out.append(("polygon", [back, right, at(n, 0, WALL), at(0, 0, WALL)], "#4a90d9", 0.3, "#1f5fa8", 4))
    for j in WEST_FIXTURES:
        out.append(("polygon", [at(0, j), at(0, j + 1), at(0, j + 1, WALL), at(0, j, WALL)], "#ff8c00", 0.45, "#c05f00", 3))
    for i in NORTH_FIXTURES:
        out.append(("polygon", [at(i, 0), at(i + 1, 0), at(i + 1, 0, WALL), at(i, 0, WALL)], "#ff8c00", 0.45, "#c05f00", 3))
    c = CHART_COLUMN
    out.append(("polygon", [at(c + 0.1, 0, 50), at(c + 0.9, 0, 50), at(c + 0.9, 0, 150), at(c + 0.1, 0, 150)], "#8a2be2", 0.4, "#5a1a99", 3))
    out.append(("line", [at(0, 0), at(0, 0, WALL)], None, 1.0, "#000", 4))
    return out


def svg(items: list) -> str:
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE[0]}" height="{SIZE[1]}" viewBox="0 0 {SIZE[0]} {SIZE[1]}">',
             f"<!-- Gear shop room, {CELLS} x {CELLS} cells at {E} px per cell edge ({E} across, {E // 2} down); "
             f"back corner {BACK}, walls {WALL} px. See art_source/store/room_sprite_prompt.md. -->",
             f'<rect width="{SIZE[0]}" height="{SIZE[1]}" fill="#ffffff"/>']
    for kind, points, fill, opacity, stroke, width in items:
        pts = " ".join(f"{x:g},{y:g}" for x, y in points)
        if kind == "polygon":
            lines.append(f'<polygon points="{pts}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}" stroke-width="{width}"/>')
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
        else:
            draw.line(points, fill=stroke, width=width)
        image = Image.alpha_composite(image, layer)
    return image.convert("RGB")


def main() -> None:
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    items = shapes()
    stem = out / "room_perspective_guide"
    stem.with_suffix(".svg").write_text(svg(items), encoding="utf-8")
    png(items).save(stem.with_suffix(".png"))


if __name__ == "__main__":
    main()

"""Cuts the painted sales belt (art_source/buildings/sales_belt.png, see sales_belt_sprite_prompt.md)
into three pieces, so SalesBelt can draw it at any length: the tank end (the crank), a section that
repeats and the booth end (the bell).

The painting is not quite 2:1: both its run and its ends slope about 0.39 instead of 0.5, as if
squashed upright. Narrowing it to SQUASH of its width fixes both. Positions below are in the
narrowed painting.

The run is measured by `s`, screen pixels across (x) along the belt's centre line from TANK_END
(the middle of the belt's top at the crank end), and `b`, screen pixels across over its width
(-HALF_WIDTH at the back edge, +HALF_WIDTH at the front). A cut goes across the belt at one `s`,
then straight up from its back edge and straight down from its front edge, so the legs and the bell
post stay whole. The section runs from SECTION_FROM to SECTION_TO, each cut just before a pair of
legs; the booth end starts at END_FROM, the same distance before another pair, so it joins the
section like the section joins itself. Each piece reaches OVERLAP pixels past its tank-side cut.

So the belt can run, its top is taken out of the pieces (SURFACE_FROM to SURFACE_TO along the run,
SURFACE_HALF_WIDTH across) and saved apart as `<prefix>_surface.png`: straightened, one pixel per
painted pixel along (x) and across (y), one section long (two cleats), so it repeats. SalesBelt
draws it scrolling under the pieces.

Prints each piece's top-left corner in the narrowed painting, for SalesBelt's constants, and saves
a preview of a belt with PREVIEW_SECTIONS sections next to the pieces.

Needs Pillow and NumPy. Usage:
  python tools/cut_belt.py art_source/buildings/sales_belt.png assets/sprites/props/sales_belt
"""
import sys

import numpy as np
from PIL import Image

SQUASH = 0.78
TANK_END = np.array([110.0, 768.0])
HALF_WIDTH = 65.0
SECTION_FROM = 390.0
SECTION_TO = 535.0
END_FROM = 645.0
# The belt's top between the end rollers, and the stretch of it saved as the repeating surface.
SURFACE_FROM = 6.0
SURFACE_TO = 928.0
SURFACE_HALF_WIDTH = 64
# Alpha below this is the painting's faint glow, not the belt.
CLEAR_BELOW = 100
OVERLAP = 3.0
PREVIEW_SECTIONS = 4


def main(source: str, prefix: str) -> None:
    painting = Image.open(source).convert("RGBA")
    width, height = painting.size
    painting = painting.resize((round(width * SQUASH), height), Image.LANCZOS)
    image = np.array(painting)
    image[image[..., 3] < CLEAR_BELOW, 3] = 0
    image[image[..., 3] == 0, :3] = 0
    height, width = image.shape[:2]
    ys, xs = np.mgrid[0:height, 0:width]
    # Screen = TANK_END + s * (1, -1/2) + b * (1, 1/2).
    px, py = xs - TANK_END[0], ys - TANK_END[1]
    s, b = (px - 2.0 * py) / 2.0, (px + 2.0 * py) / 2.0

    surface = _straighten(image, SECTION_FROM, SECTION_TO - SECTION_FROM)
    Image.fromarray(surface).save("%s_surface.png" % prefix)
    on_top = (s > SURFACE_FROM) & (s < SURFACE_TO) & (np.abs(b) <= SURFACE_HALF_WIDTH)
    image[on_top] = 0

    def tank_side(cut: float) -> np.ndarray:
        back_x = TANK_END[0] + cut - HALF_WIDTH
        front_x = TANK_END[0] + cut + HALF_WIDTH
        return np.where(b < -HALF_WIDTH, xs < back_x, np.where(b > HALF_WIDTH, xs < front_x, s < cut))

    pieces = {
        "tank": tank_side(SECTION_FROM + OVERLAP),
        "section": tank_side(SECTION_TO + OVERLAP) & ~tank_side(SECTION_FROM),
        "booth": ~tank_side(END_FROM),
    }
    corners = {}
    cut_images = {}
    for name, mask in pieces.items():
        piece = image.copy()
        piece[..., 3] = np.where(mask, piece[..., 3], 0)
        rows, cols = np.nonzero(piece[..., 3])
        left, top = int(cols.min()), int(rows.min())
        cut_images[name] = Image.fromarray(piece[top:rows.max() + 1, left:cols.max() + 1])
        cut_images[name].save("%s_%s.png" % (prefix, name))
        corners[name] = (left, top)
        print(name, (left, top))

    # A preview drawn as SalesBelt draws it: the booth end first, then the sections from the far
    # end down, then the tank end on top.
    step = np.array([1.0, -0.5])
    section = SECTION_TO - SECTION_FROM
    length = SECTION_FROM + PREVIEW_SECTIONS * section + (width - END_FROM)
    preview = Image.new("RGBA", (int(length + 200), int(height + length * 0.5)), (240, 230, 200, 255))
    origin = np.array([0.0, length * 0.5])
    booth_shift = SECTION_FROM + PREVIEW_SECTIONS * section - END_FROM

    def paste(name: str, shift: float) -> None:
        at = origin + np.array(corners[name]) + step * shift
        preview.alpha_composite(cut_images[name], (int(round(at[0])), int(round(at[1]))))

    paste("booth", booth_shift)
    for i in range(PREVIEW_SECTIONS - 1, -1, -1):
        paste("section", i * section)
    paste("tank", 0.0)
    preview.save("%s_preview.png" % prefix)


def _straighten(image: np.ndarray, start: float, length: float) -> np.ndarray:
    """The belt's top from `start`, `length` long, as a rectangle: x along the run, y across."""
    us, vs = np.meshgrid(np.arange(int(length)), np.arange(-SURFACE_HALF_WIDTH, SURFACE_HALF_WIDTH + 1))
    xs = TANK_END[0] + (start + us) + vs
    ys = TANK_END[1] - (start + us) * 0.5 + vs * 0.5
    x0, y0 = np.floor(xs).astype(int), np.floor(ys).astype(int)
    fx, fy = (xs - x0)[..., None], (ys - y0)[..., None]
    pixels = image.astype(float)
    top = pixels[y0, x0] * (1 - fx) + pixels[y0, x0 + 1] * fx
    bottom = pixels[y0 + 1, x0] * (1 - fx) + pixels[y0 + 1, x0 + 1] * fx
    out = (top * (1 - fy) + bottom * fy).round().astype(np.uint8)
    out[..., 3] = 255
    return out


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

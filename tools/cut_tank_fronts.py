"""Cuts the front of each tank sprite into a layer of its own: the parts of the frame that stand
in front of the water, drawn again over the water and the fish (TankNode).

The sprites are painted as one picture (tools/import_tank_art.py), the frame and the glass and the
sand behind it all opaque, so the front can't be told apart by alpha or colour. It is cut along
the painting's own outlines: the dark lines split the sprite into regions, and the front is every
region lying (almost) wholly within REACH pixels of where the tank's geometry puts the frame (the
three front corner posts, the bottom and top rails along the two front faces, the posts standing
in those faces), together with the outlines around them. A glass pane reaches far beyond that, a
pebble is too small. The glass corners are TankNode.GLASS (sprite pixels): keep the two in step.

With --debug the sprites are written with the cut tinted magenta instead, to check it.

Needs Pillow, NumPy and SciPy. Usage:
  python tools/cut_tank_fronts.py assets/sprites/props [--debug <dir>]
writes assets/sprites/props/tank_<level>_front.png for every level.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

# How far the outlines may lie from where the geometry puts the frame (sprite pixels).
REACH = 8
# Darker than this (luminance) is an outline.
OUTLINE = 75
# A region counts as frame when this share of it lies near the frame and it is at least
# LONGEST pixels long; holes in the frame smaller than HOLE pixels are filled.
INSIDE = 0.9
LONGEST = 14
HOLE = 160
# How far into dark pixels the frame reaches from its lighter parts (outlines, shaded sides).
DARK_REACH = 10

# Level: glass corners west, south, east and the glass height (TankNode.GLASS), then the frame:
# half the width of a corner post and how far its cap reaches above the glass; how high the bottom
# rail reaches above the glass floor and how far the top rail reaches above and below the rim;
# and the posts in the faces as (face, share along it, half width), face "W" running from the west
# corner to the south one and "E" from the south corner to the east one. A painting that is not
# quite a box gets its four rails measured instead: (from, to, half thickness) along their middles.
LEVELS = {
    1: ((30, 344), (231, 445), (415, 353), 245, 16, 24, 14, (14, 12), []),
    2: ((25, 252), (400, 440), (515, 382), 205, 14, 21, 12, (12, 10), []),
    3: ((30, 356), (234, 458), (422, 364), 245, 20, 30, 16, (16, 14), []),
    4: ((20, 313), (201, 415), (522, 253), 148, 12, 14, 12, (10, 10), []),
    5: ((20, 288), (310, 433), (595, 290), 140, 15, 6, 12, (10, 10), []),
    6: ((14, 321), (245, 437), (594, 262), 143, 10, 6, 12, (10, 10), []),
    7: ((22, 402), (200, 495), (662, 263), 124, 16, 30, 12, (14, 3), [("E", 0.33, 7), ("E", 0.69, 7)]),
}
RAILS = {
    4: [((20, 167), (201, 271), 12), ((201, 266), (522, 93), 12),
        ((20, 313), (201, 411), 10), ((201, 419), (522, 253), 10)],
    7: [((22, 282), (200, 371), 6), ((200, 369), (662, 125), 6),
        ((22, 402), (200, 491), 7), ((200, 500), (662, 263), 7)],
}


def main() -> None:
    folder = Path(sys.argv[1])
    debug = Path(sys.argv[sys.argv.index("--debug") + 1]) if "--debug" in sys.argv else None
    for level, spec in LEVELS.items():
        sprite = Image.open(folder / f"tank_{level}.png").convert("RGBA")
        mask = _cut(np.array(sprite), *_near_frame(sprite.size, *spec, RAILS.get(level)))
        if debug is None:
            front = np.array(sprite)
            front[..., 3] = (front[..., 3].astype(float) * mask).astype(np.uint8)
            Image.fromarray(front, "RGBA").save(folder / f"tank_{level}_front.png")
        else:
            shown = np.array(sprite).astype(float)
            tint = mask[..., None] * 0.55
            shown[..., :3] = shown[..., :3] * (1 - tint) + np.array([255, 0, 255]) * tint
            Image.fromarray(shown.astype(np.uint8), "RGBA").save(debug / f"front_{level}.png")


def _cut(rgba: np.ndarray, near: np.ndarray, posts: list) -> np.ndarray:
    """1 where the sprite is front frame, 0 elsewhere, soft at the edges. `posts` are the posts'
    middles (x, top, bottom) and how far their zones reach to either side."""
    luminance = rgba[..., :3].astype(float) @ np.array([0.3, 0.59, 0.11])
    outline = (luminance < OUTLINE) | (rgba[..., 3] < 128)
    regions, count = ndimage.label(~outline)
    frame = np.zeros(near.shape, bool)
    for index, box in enumerate(ndimage.find_objects(regions), 1):
        region = regions[box] == index
        size = max(box[0].stop - box[0].start, box[1].stop - box[1].start)
        if size >= LONGEST and near[box][region].mean() >= INSIDE:
            frame[box] |= region
    # A post painted in one piece with a rail running away behind it: the region crossing the
    # post's middle, as far as the post's zone reaches.
    columns = np.arange(near.shape[1])[None, :]
    for x, top, bottom, half in posts:
        ids, counts = np.unique(regions[top:bottom, x], return_counts=True)
        zone = near & (abs(columns - x) <= half)
        for index in ids[(counts >= LONGEST) & (ids > 0)]:
            frame |= (regions == index) & zone
    # The outlines around the frame and its dark, shaded sides, as far as they reach from it, and
    # its own small holes (bolts, highlights).
    dark = outline & near & (rgba[..., 3] > 0)
    frame |= ndimage.binary_dilation(frame, iterations=DARK_REACH, mask=dark)
    holes = ndimage.binary_fill_holes(frame) & ~frame
    hole_regions, _ = ndimage.label(holes)
    sizes = np.bincount(hole_regions.ravel())
    frame |= (sizes[hole_regions] < HOLE) & holes
    return ndimage.gaussian_filter(frame.astype(float), 0.6)


def _near_frame(size, west, south, east, height, post, cap, bottom, top, face_posts, rails) -> tuple:
    """True within REACH of where the geometry puts the frame, and the posts for _cut."""
    posts = [(x, y - height, y, post + REACH) for x, y in (west, south, east)]
    image = Image.new("L", size, 0)
    draw = ImageDraw.Draw(image)
    post += REACH
    bottom += REACH
    top = (top[0] + REACH, top[1] + REACH)
    cap += REACH

    def shape(points):
        draw.polygon(points, fill=255)

    def up(point, by):
        return point[0], point[1] - by

    if rails:
        for a, b, half in rails:
            shape([up(a, -half - REACH), up(b, -half - REACH), up(b, half + REACH), up(a, half + REACH)])
    for a, b in ((west, south), (south, east)) if not rails else ():
        # Bottom rail, from below the floor up; top rail around the rim.
        shape([up(a, -bottom), up(b, -bottom), up(b, bottom), up(a, bottom)])
        shape([up(a, height - top[1]), up(b, height - top[1]), up(b, height + top[0]), up(a, height + top[0])])
    for x, y in (west, south, east):
        # The shaft up to the rim, the cap above it rounded like the knob on top.
        shape([(x - post, y + post * 1.5), (x + post, y + post * 1.5), (x + post, y - height), (x - post, y - height)])
        draw.ellipse([x - post, y - height - cap, x + post, y - height + cap * 0.6], fill=255)
    for face, share, half in face_posts:
        half += REACH
        a, b = (west, south) if face == "W" else (south, east)
        x, y = a[0] + (b[0] - a[0]) * share, a[1] + (b[1] - a[1]) * share
        posts.append((round(x), round(y - height), round(y), half))
        shape([(x - half, y + half), (x + half, y + half), (x + half, y - height), (x - half, y - height)])
    return np.array(image) > 0, posts


if __name__ == "__main__":
    main()

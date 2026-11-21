"""Cuts a species image (art_source/fish/views/<id>.png) into its side-view sprites.

The image shows the creature from the side, head left, in the style of the cod in
art_source/fish/species_style_side.png (prompts: tools/make_species_view_prompts.py). It becomes
assets/sprites/fish_painted/<id>_body.png and <id>_tail.png (FishArt's side layout, cut by
tools/extract_painted.py's _write: the tail fin split off for species that beat it, see
FishArt.MOTIONS). Older images also show two views from above above the side view; those are
ignored (the lowest big drawing is the side view).

Usage:
    python tools/extract_species_views.py <id> [<id> ...] [--scale=0.5]

Real transparency is cut by its alpha (a faint glow is dropped), an opaque light background (white
or a painted checkerboard) by removing the light pixels connected to the border. After cutting,
import in Godot and turn mipmaps on for new sprites (see the README).
"""
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_painted import _write  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
VIEWS = ROOT / "art_source" / "fish" / "views"
OUT = ROOT / "assets" / "sprites" / "fish_painted"
FISH_ART = ROOT / "src" / "scenes" / "fishing" / "fish_art.gd"
# Alpha a pixel needs to count as part of a creature; below KEEP_ALPHA lies the glow.
SOLID_ALPHA = 200
KEEP_ALPHA = 40


def tail_beaters_excluded() -> set[str]:
    """Species that do not beat a tail fin (FishArt.MOTIONS): their side view is not split."""
    text = FISH_ART.read_text(encoding="utf-8")
    block = text[text.index("const MOTIONS"):text.index("const WAVES")]
    return set(re.findall(r'"([a-z0-9_]+)": Motion\.', block))


CHECKER = 8


def checker_like(value: np.ndarray, light: np.ndarray, labels: np.ndarray, background: set) -> np.ndarray:
    """Pixels of a painted checkerboard: one of its two greys, with the other grey CHECKER (+-1)
    px away to the left, right, top or bottom. The two greys are read off the border background."""
    outside = light & np.isin(labels, list(background))
    if not outside.any():
        return np.zeros(value.shape, bool)
    shades = value[outside]
    low, high = np.percentile(shades, 25), np.percentile(shades, 75)
    if high - low < 25:
        return np.zeros(value.shape, bool)  # a plain white background
    dark = light & (np.abs(value - low) < 14)
    bright = light & (np.abs(value - high) < 14)
    near_bright = np.zeros(value.shape, bool)
    near_dark = np.zeros(value.shape, bool)
    for shift in (CHECKER - 1, CHECKER, CHECKER + 1):
        for axis in (0, 1):
            for sign in (1, -1):
                near_bright |= np.roll(bright, sign * shift, axis=axis)
                near_dark |= np.roll(dark, sign * shift, axis=axis)
    return (dark & near_bright) | (bright & near_dark)


def alpha_of(image: np.ndarray) -> np.ndarray:
    alpha = image[:, :, 3].astype(np.int32)
    if (alpha < 250).mean() > 0.2:
        return alpha
    rgb = image[:, :, :3].astype(np.int32)
    # White, or the light and mid grey squares of a painted checkerboard.
    light = (rgb.min(axis=2) > 120) & (rgb.max(axis=2) - rgb.min(axis=2) < 20)
    labels, count = ndimage.label(light)
    background = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))) - {0}
    # Checkerboard caught between fins or arms: an enclosed patch mostly made of checker squares,
    # each grey square next to one of the other grey CHECKER px away (an eye's white is one
    # shade only; a silvery belly or a pale fin has the shades but not the pattern).
    value = rgb.min(axis=2)
    like = checker_like(value, light, labels, background)
    sizes = ndimage.sum(light, labels, range(1, count + 1))
    matched = ndimage.sum(like, labels, range(1, count + 1))
    checkered = np.zeros(light.shape, bool)
    for label in range(1, count + 1):
        if label not in background and matched[label - 1] > max(6, 0.5 * sizes[label - 1]):
            checkered |= labels == label
    # The whole gap up to the outlines around it: a see-through web may tint part of it. The
    # flood stays out of light patches kept as part of the creature (a silvery belly or a pale
    # fin touching the gap would be eaten whole).
    kept_light = light & ~checkered & ~np.isin(labels, list(background))
    checkered = ndimage.binary_dilation(checkered, iterations=0, mask=(value > 90) & ~kept_light)
    return np.where(np.isin(labels, list(background)) | checkered, 0, 255)


def cut(species_id: str, scale: float, no_split: set[str]) -> None:
    image = np.array(Image.open(VIEWS / f"{species_id}.png").convert("RGBA"))
    alpha = alpha_of(image)
    solid = ndimage.binary_fill_holes(alpha >= SOLID_ALPHA)
    labels, count = ndimage.label(ndimage.binary_dilation(solid, iterations=3))
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    if count == 0:
        print(f"{species_id}: no drawing found")
        return
    # The drawings: the side view alone, or (older three-view images) the side view below two
    # views from above, which are not used. Loose bits (a detached fin ray) are left out.
    drawings = [int(i) + 1 for i in np.argsort(sizes)[::-1][:3] if sizes[i] >= 0.25 * sizes.max()]
    side = max(drawings, key=lambda label: ndimage.center_of_mass(solid, labels, label)[0])
    out = image.copy()
    out[:, :, 3] = np.where((labels == side) & (alpha >= KEEP_ALPHA), alpha, 0).astype(np.uint8)
    ys, xs = np.nonzero(out[:, :, 3])
    sprite = Image.fromarray(out[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    sprite = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.LANCZOS)
    # The side view heads left; FishArt's side sprites face right.
    side_view = np.array(sprite)[:, ::-1]
    _write(species_id, side_view, species_id not in no_split, OUT)


def main() -> None:
    scale = 0.5
    ids = []
    for arg in sys.argv[1:]:
        if arg.startswith("--scale="):
            scale = float(arg.split("=", 1)[1])
        else:
            ids.append(arg)
    no_split = tail_beaters_excluded()
    for species_id in ids:
        cut(species_id, scale, no_split)


main()

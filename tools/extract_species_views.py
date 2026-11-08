"""Cuts a species image (art_source/fish/views/<id>.png) into its three sprites.

The image shows one creature three times, in the layout of the cod in
art_source/fish/species_style_test.png (prompts: tools/make_species_view_prompts.py):
- top left, seen from above heading lower left  -> assets/sprites/fish_painted/<id>_top.png
- top right, seen from above heading upper left -> <id>_top_up.png
- bottom, the side view, head left              -> <id>_body.png and <id>_tail.png (FishArt's
  side layout, cut by tools/extract_painted.py's _write: the tail fin split off for species that
  beat it, see FishArt.MOTIONS)

Usage:
    python tools/extract_species_views.py <id> [<id> ...] [--scale=0.5]

The three biggest drawings are taken; the lowest is the side view, of the other two the left one
heads lower left. Real transparency is cut by its alpha (a faint glow is dropped), an opaque light
background (white or a painted checkerboard) by removing the light pixels connected to the border.
After cutting, import in Godot and turn mipmaps on for new sprites (see the README).
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


def alpha_of(image: np.ndarray) -> np.ndarray:
    alpha = image[:, :, 3].astype(np.int32)
    if (alpha < 250).mean() > 0.2:
        return alpha
    rgb = image[:, :, :3].astype(np.int32)
    light = (rgb.min(axis=2) > 185) & (rgb.max(axis=2) - rgb.min(axis=2) < 25)
    labels, _ = ndimage.label(light)
    border = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    return np.where(np.isin(labels, border[border > 0]), 0, 255)


def cut(species_id: str, scale: float, no_split: set[str]) -> None:
    image = np.array(Image.open(VIEWS / f"{species_id}.png").convert("RGBA"))
    alpha = alpha_of(image)
    solid = ndimage.binary_fill_holes(alpha >= SOLID_ALPHA)
    labels, count = ndimage.label(ndimage.binary_dilation(solid, iterations=3))
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    biggest = [int(i) + 1 for i in np.argsort(sizes)[::-1][:3]]
    if len(biggest) < 3:
        print(f"{species_id}: only {len(biggest)} drawings found")
        return
    centres = {label: ndimage.center_of_mass(solid, labels, label) for label in biggest}
    side = max(biggest, key=lambda label: centres[label][0])
    top = sorted((label for label in biggest if label != side), key=lambda label: centres[label][1])
    sprites = {}
    for label in biggest:
        out = image.copy()
        out[:, :, 3] = np.where((labels == label) & (alpha >= KEEP_ALPHA), alpha, 0).astype(np.uint8)
        ys, xs = np.nonzero(out[:, :, 3])
        sprite = Image.fromarray(out[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
        sprite = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.LANCZOS)
        sprites[label] = sprite
    for label, suffix in ((top[0], ""), (top[1], "_up")):
        sprites[label].save(OUT / f"{species_id}_top{suffix}.png")
        print(f"{species_id}_top{suffix}: {sprites[label].width} x {sprites[label].height}")
    # The side view heads left; FishArt's side sprites face right.
    side_view = np.array(sprites[side])[:, ::-1]
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

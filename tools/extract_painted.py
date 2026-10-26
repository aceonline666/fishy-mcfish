"""Cuts species sprites out of painted sprite sheets into body/tail PNGs in FishArt's layout.

Body canvas: 240 units wide, tail root at x=20, snout at x=220, centred on the body axis.
Tail canvas: 70 units wide at the body's pixel scale, tail root at x=62.
SHEETS maps each sheet file to its species: a point on the sprite, the way the head points
("left" sprites are mirrored to face right) and whether the tail fin is cut off to beat. Sheets
without transparency (a painted checkerboard behind the sprites) are cut out like the props.

Needs Pillow, NumPy and SciPy. Usage, per sheet:
  python tools/extract_painted.py art_source/painted_sprite_sheet.png assets/sprites/fish_painted
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).parent))
from extract_props import _foreground  # noqa: E402

# species id: (sprite centre x, y on the sheet, facing, split tail)
PAINTED_SHEET = {
    "european_sprat": (246, 115, "left", True),
    "atlantic_herring": (381, 112, "left", True),
    "lesser_sand_eel": (515, 113, "left", True),
    "atlantic_mackerel": (669, 112, "left", True),
    "european_plaice": (835, 112, "left", True),
    "lumpsucker": (978, 112, "left", True),
    "atlantic_cod": (1112, 114, "left", True),
    "conger_eel": (1281, 109, "left", True),
    "ocellaris_clownfish": (1449, 111, "left", True),
    "blue_green_chromis": (95, 277, "left", True),
    "blue_tang": (221, 273, "left", True),
    "mandarinfish": (363, 273, "left", True),
    "red_lionfish": (508, 271, "left", True),
    "blacktip_reef_shark": (668, 273, "left", True),
    "humphead_wrasse": (835, 275, "left", True),
    "lions_mane_jellyfish": (972, 266, "right", False),
    "atlantic_bluefin_tuna": (1126, 277, "left", True),
    "ocean_sunfish": (1285, 268, "left", False),
    "basking_shark": (1446, 272, "left", True),
    "roundnose_grenadier": (92, 434, "left", False),
    "rabbit_fish": (240, 431, "left", False),
    "curled_octopus": (369, 431, "right", False),
    "greenland_shark": (519, 430, "left", True),
    "humpback_anglerfish": (677, 432, "right", True),
    "south_african_sardine": (532, 595, "left", True),
    "green_sea_turtle": (387, 761, "right", False),
    "sperm_whale": (1172, 746, "left", True),
    "blue_whale": (111, 883, "left", True),
    "giant_squid": (1250, 901, "right", False),
}

SHEETS = {
    "painted_sprite_sheet.png": PAINTED_SHEET,
    "species_sheet_1.png": {
        "atlantic_wolffish": (310, 150, "left", True),
        "atlantic_footballfish": (840, 160, "right", True),
        "moon_jellyfish": (205, 400, "right", False),
        "yellowfin_tuna": (690, 415, "left", True),
        "reef_manta_ray": (1200, 420, "left", False),
        "skinnycheek_lanternfish": (255, 670, "left", True),
        "chambered_nautilus": (655, 680, "left", False),
        "bluntnose_sixgill_shark": (1180, 670, "left", True),
        "pacific_blackdragon": (390, 880, "left", False),
        "west_indian_ocean_coelacanth": (1070, 880, "left", True),
    },
    "species_sheet_2.png": {
        "australian_salmon": (205, 150, "left", True),
        "southern_blue_ringed_octopus": (555, 160, "right", False),
        "weedy_seadragon": (900, 160, "left", False),
        "blue_groper": (1310, 160, "left", True),
        "smooth_stingray": (215, 410, "left", False),
        "port_jackson_shark": (540, 420, "left", True),
        "old_wife": (910, 400, "left", True),
        "loggerhead_turtle": (1320, 420, "left", False),
        "leafy_seadragon": (180, 660, "left", False),
        "blubber_jellyfish": (495, 650, "right", False),
        "great_white_shark": (850, 660, "left", True),
        "humpback_whale": (1300, 660, "left", True),
        "orange_roughy": (200, 885, "left", True),
        "pink_ling": (610, 885, "left", False),
        "blobfish": (975, 880, "left", False),
        "common_fangtooth": (1340, 880, "left", True),
    },
    "species_sheet_3.png": {
        "red_sea_bream": (180, 140, "left", True),
        "japanese_horse_mackerel": (525, 150, "left", True),
        "tiger_puffer": (850, 130, "left", True),
        "japanese_amberjack": (1255, 145, "left", True),
        "japanese_flying_squid": (160, 410, "right", False),
        "opah": (520, 390, "left", True),
        "nomuras_jellyfish": (875, 400, "right", False),
        "japanese_spider_crab": (1290, 400, "right", False),
        "giant_pacific_octopus": (170, 670, "right", False),
        "giant_isopod": (510, 660, "left", False),
        "frilled_shark": (885, 690, "left", False),
        "goblin_shark": (1300, 660, "left", True),
        "mariana_snailfish": (255, 910, "left", True),
        "giant_oarfish": (970, 895, "left", False),
    },
    "species_sheet_4.png": {
        "hottentot_seabream": (195, 150, "left", True),
        "common_octopus": (595, 150, "right", False),
        "knysna_seahorse": (900, 140, "left", False),
        "galjoen": (1295, 155, "left", True),
        "copper_shark": (210, 385, "left", True),
        "ragged_tooth_shark": (595, 395, "left", True),
        "giant_guitarfish": (990, 400, "left", True),
        "portuguese_man_o_war": (1385, 410, "right", False),
        "shortfin_mako": (200, 620, "left", True),
        "leatherback_turtle": (580, 640, "left", False),
        "southern_right_whale": (965, 640, "left", True),
        "cape_hake": (1350, 625, "left", True),
        "kingklip": (200, 870, "left", True),
        "sloanes_viperfish": (565, 880, "left", False),
        "pelican_eel": (930, 880, "left", False),
        "colossal_squid": (1320, 850, "right", False),
    },
}

# Sheet rows below which a sprite's region is its label, not the creature.
BOTTOM_LIMIT = {"green_sea_turtle": 800}

ALPHA_FLOOR = 40
MAX_TAIL_SHARE = 0.3


def main() -> None:
    image = Image.open(sys.argv[1])
    sheet = np.array(image.convert("RGBA"))
    if "A" not in image.mode:
        sheet[..., 3] = _foreground(sheet[..., :3])
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    mask = sheet[..., 3] > 60
    labels, _ = ndimage.label(ndimage.binary_dilation(mask, iterations=3))
    for species, (cx, cy, facing, split) in SHEETS[Path(sys.argv[1]).name].items():
        label = _label_near(labels, cx, cy)
        sl = ndimage.find_objects((labels == label).astype(int))[0]
        crop = sheet[sl].copy()
        keep = labels[sl] == label
        # The turtle's name label sits so close that it merges with the sprite.
        if species in BOTTOM_LIMIT:
            keep[BOTTOM_LIMIT[species] - sl[0].start:] = False
        alpha = crop[..., 3].astype(float)
        alpha[~keep] = 0
        alpha = np.clip((alpha - ALPHA_FLOOR) / (255 - ALPHA_FLOOR), 0, 1) * 255
        crop[..., 3] = alpha.astype(np.uint8)
        crop = _trim(crop)
        if facing == "left":
            crop = crop[:, ::-1]
        _write(species, crop, split, out)


def _label_near(labels: np.ndarray, x: int, y: int) -> int:
    """The biggest labelled region within a few pixels of the point."""
    window = labels[y - 12:y + 12, x - 12:x + 12]
    values, counts = np.unique(window[window > 0], return_counts=True)
    return int(values[np.argmax(counts)])


def _trim(img: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(img[..., 3] > 0)
    return img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def _write(species: str, img: np.ndarray, split: bool, out: Path) -> None:
    h, w = img.shape[:2]
    opaque = img[..., 3] > 128
    if split:
        # The tail root is the narrowest column in the back part of the body.
        heights = np.array([np.count_nonzero(opaque[:, x]) for x in range(w)])
        lo, hi = int(w * 0.08), int(w * MAX_TAIL_SHARE * 1.2)
        root = lo + int(np.argmin(heights[lo:hi] + np.linspace(0, 2, hi - lo)))
        root = min(root, int(w * MAX_TAIL_SHARE))
        rows = np.nonzero(opaque[:, root])[0]
        axis = int(rows.mean()) if len(rows) else h // 2
    else:
        root = 0
        axis = h // 2
    body = img[:, root:]
    tail = img[:, :root + 2] if root > 0 else np.zeros((h, 1, 4), np.uint8)
    body_px = body.shape[1]
    unit = body_px / 200.0
    # Centre both parts on the body axis.
    half = max(axis, h - axis)
    body = _pad_vertical(body, axis, half)
    tail = _pad_vertical(tail, axis, half)
    pad = int(round(20 * unit))
    body_canvas = np.zeros((body.shape[0], body_px + 2 * pad, 4), np.uint8)
    body_canvas[:, pad:pad + body_px] = body
    tail_width = int(round(70 * unit))
    tail_canvas = np.zeros((tail.shape[0], tail_width, 4), np.uint8)
    root_x = int(round(62 * unit))
    # The tail part reaches 2 px into the body so no seam shows; its column `root` sits at root_x.
    start = root_x - root
    if start < 0:
        tail = tail[:, -start:]
        start = 0
    end = min(start + tail.shape[1], tail_width)
    tail_canvas[:, start:end] = tail[:, :end - start]
    Image.fromarray(body_canvas).save(out / f"{species}_body.png")
    Image.fromarray(tail_canvas).save(out / f"{species}_tail.png")
    print(f"{species}: {w}x{h}, tail {root}px")


def _pad_vertical(img: np.ndarray, axis: int, half: int) -> np.ndarray:
    top = half - axis
    bottom = 2 * half - img.shape[0] - top
    return np.pad(img, ((top, max(bottom, 0)), (0, 0), (0, 0)))


if __name__ == "__main__":
    main()

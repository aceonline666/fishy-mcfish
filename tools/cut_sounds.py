"""Cuts the recorded sounds (seabird calls, shore and open sea ambience) out of their sources.

The sources lie in art_source/audio/ (where they come from and their licences: see the README's
credits). Each clip is a stretch of a source: mixed to mono (the ambience stays stereo), the
background hiss below the call faded in and out, levelled to the same peak and written as Ogg
Vorbis to assets/audio/. The ambience loops are cut so that their end blends into their start.

Needs NumPy and soundfile (pip install soundfile). Usage:
    python tools/cut_sounds.py
Then import in Godot (godot --headless --import).
"""
from pathlib import Path

import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "art_source" / "audio"
OUT = ROOT / "assets" / "audio"
RATE = 44100
# Peak level of every call, and of the ambience (which plays quieter still, see Sfx).
PEAK_DB = -3.0
FADE_S = 0.04

# Calls: output name -> (source, start s, end s). Seabirds.CALLS picks them by name.
CALLS = {
    "herring_gull_1": ("herring_gull_passing_744592.mp3", 3.95, 10.95),
    "herring_gull_2": ("herring_gull_538015.mp3", 0.0, 1.6),
    "herring_gull_3": ("herring_gull_538015.mp3", 2.55, 3.8),
    "herring_gull_4": ("herring_gull_538015.mp3", 12.25, 18.55),
    "black_headed_gull_1": ("black_headed_gull_848876.mp3", 2.5, 4.35),
    "black_headed_gull_2": ("black_headed_gull_848876.mp3", 11.95, 14.15),
    "black_headed_gull_3": ("black_headed_gull_848876.mp3", 14.75, 15.6),
    "gannet_1": ("northern_gannet_colony_bl.ogg", 0.2, 3.5),
    "gannet_2": ("northern_gannet_colony_bl.ogg", 16.9, 19.1),
    "pterosaur_1": ("pterosaur_733530.mp3", 10.95, 12.5),
    "pterosaur_2": ("pterosaur_733530.mp3", 14.2, 16.3),
    "pterosaur_3": ("pterosaur_733530.mp3", 30.5, 32.8),
}
# Ambience loops: output name -> (source, start s, length s).
LOOPS = {
    "shore": ("small_caribbean_waves_796618.mp3", 60.0, 40.0),
    "open_sea": ("ocean_waves_wind_457213.mp3", 10.0, 40.0),
}
LOOP_BLEND_S = 3.0


def read(name: str, start: float, end: float, mono: bool) -> np.ndarray:
    data, rate = sf.read(SOURCES / name, always_2d=True)
    if rate != RATE:
        # Linear resampling is enough for these noisy field recordings.
        times = np.arange(int(len(data) * RATE / rate)) / RATE
        data = np.stack([np.interp(times, np.arange(len(data)) / rate, data[:, c]) for c in range(data.shape[1])], axis=1)
    if data.shape[1] == 1:
        data = np.repeat(data, 2, axis=1)
    clip = data[int(start * RATE):int(end * RATE)]
    return clip.mean(axis=1, keepdims=True) if mono else clip[:, :2]


def level(clip: np.ndarray) -> np.ndarray:
    return clip * (10.0 ** (PEAK_DB / 20.0) / max(np.abs(clip).max(), 1e-6))


def write(name: str, clip: np.ndarray) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # In small blocks: libsndfile's Vorbis encoder overflows the stack on long writes.
    with sf.SoundFile(OUT / f"{name}.ogg", "w", RATE, clip.shape[1], format="OGG", subtype="VORBIS") as file:
        for start in range(0, len(clip), 4096):
            file.write(clip[start:start + 4096].astype(np.float32))
    print(f"{name}: {len(clip) / RATE:.1f} s")


def main() -> None:
    for name, (source, start, end) in CALLS.items():
        clip = read(source, start, end, True)
        fade = int(FADE_S * RATE)
        ramp = np.linspace(0.0, 1.0, fade)[:, None]
        clip[:fade] *= ramp
        clip[-fade:] *= ramp[::-1]
        write(name, level(clip))
    for name, (source, start, length) in LOOPS.items():
        blend = int(LOOP_BLEND_S * RATE)
        clip = read(source, start, start + length + LOOP_BLEND_S, False)
        body, tail = clip[:-blend].copy(), clip[-blend:]
        # The stretch after the loop's end fades out over its start, which fades in: no seam.
        ramp = np.sin(np.linspace(0.0, np.pi / 2.0, blend))[:, None]
        body[:blend] = body[:blend] * ramp + tail * ramp[::-1]
        write(name, level(body))


if __name__ == "__main__":
    main()

"""Original, reproducible weapon effects. Standard library only; no external samples."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "Resource" / "Audio"


def generate(name, duration, seed):
    rng = random.Random(seed)
    samples = []
    phase = 0.0
    noise = 0.0
    for i in range(int(RATE * duration)):
        t = i / RATE
        part = t / duration
        if i % 9 == 0:
            noise = rng.uniform(-1, 1)
        if name == "shotgun":
            freq, mix = 180 * (1 - part) + 40, 0.7
            envelope = (1 - part) ** 2
        elif name in ("flame", "phoenix"):
            freq, mix = (135 if name == "flame" else 205) + math.sin(t * 90) * 25, 0.85
            envelope = min(1, t * 180) * (1 - part)
        elif name == "needle":
            freq, mix = 1600 * (1 - part) ** 2 + 200, 0.15
            envelope = (1 - part) ** 1.4
        else:
            pulse = t % 0.055
            freq, mix = 900 * max(0, 1 - pulse / 0.04) + 110, 0.25
            envelope = max(0, 1 - pulse / 0.04) * (1 - part * 0.35)
        phase += freq / RATE
        tone = 1.0 if phase % 1 < 0.25 else -1.0
        value = (tone * (1 - mix) + noise * mix) * envelope * min(1, t / .003) * min(1, (duration - t) / .006)
        samples.append(struct.pack("<h", int(max(-1, min(1, value)) * 16000)))
    with wave.open(str(ROOT / (name + ".wav")), "wb") as audio:
        audio.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        audio.writeframes(b"".join(samples))


if __name__ == "__main__":
    for index, (name, duration) in enumerate([("shotgun", .19), ("flame", .095), ("needle", .22), ("tempest", .165), ("phoenix", .09)]):
        generate(name, duration, 140 + index)
    print("Generated five original weapon effects.")

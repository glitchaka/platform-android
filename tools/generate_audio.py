"""Original four-voice chiptune compositions and effects; no downloaded samples.
Run with Python 3 and ffmpeg on PATH. Sources intentionally remain reproducible.
"""
from pathlib import Path
from array import array
import math
import random
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resource" / "Audio"
WORK = ROOT / ".audio-build"
RATE = 22050
OUT.mkdir(parents=True, exist_ok=True)
WORK.mkdir(exist_ok=True)


def note(buffer, start, duration, midi, volume, voice="pulse", duty=.25):
    if midi < 0:
        return
    begin = int(start * RATE)
    size = min(int(duration * RATE), len(buffer) - begin)
    frequency = 440 * 2 ** ((midi - 69) / 12)
    for i in range(size):
        phase = i * frequency / RATE % 1
        value = 1 if phase < duty else -1
        if voice == "triangle":
            value = 1 - 4 * abs(phase - .5)
        envelope = min(1, i / 90, (size - i) / 180)
        buffer[begin + i] += value * envelope * volume


def drum(buffer, start, kind, rng):
    length = .09 if kind == "kick" else .065 if kind == "snare" else .028
    begin = int(start * RATE)
    size = min(int(length * RATE), len(buffer) - begin)
    for i in range(size):
        t = i / RATE
        env = (1 - i / size) ** 2
        value = math.sin(2 * math.pi * (90 * t - 280 * t * t)) if kind == "kick" else rng.choice((-1, 1))
        buffer[begin + i] += value * env * (.15 if kind == "kick" else .055 if kind == "snare" else .024)


def write_wav(path, samples):
    # Small smoothing plus quantization retains the chip character without harsh peaks.
    output = array("h")
    previous = 0.
    peak = max(max(samples), -min(samples), .01)
    gain = min(.82 / peak, 1.3)
    for sample in samples:
        previous = previous * .25 + sample * .75
        output.append(int(max(-1, min(1, previous * gain)) * 32760))
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(output.tobytes())


# Tempo, tonic, distinct melody, harmony progression, pulse duty.
SONGS = {
    "title": (96, 57, [0,7,12,10,7,3,5,7,0,3,7,15,14,10,7,5], [0,-5,-2,-7], .25),
    "tutorial": (112, 60, [0,2,4,7,4,2,0,-99,4,5,7,12,11,7,4,2], [0,5,7,0], .5),
    "town": (100, 62, [4,7,9,7,4,2,0,2,5,9,12,9,7,4,2,0], [0,5,2,7], .25),
    "cross": (118, 57, [0,3,7,10,7,5,3,2,0,7,12,10,8,7,3,5], [0,-2,-5,-7], .25),
    "nest": (138, 55, [0,0,7,3,0,10,7,3,1,1,8,5,3,1,7,0], [0,1,-2,0], .125),
    "fungus": (88, 62, [0,7,10,14,10,7,5,-99,3,8,12,15,12,8,7,5], [0,3,-2,5], .25),
    "bone": (108, 52, [0,1,7,6,3,1,0,-99,7,8,12,11,7,6,3,1], [0,-1,-5,-2], .125),
    "city": (104, 59, [0,7,14,12,10,7,5,3,2,5,10,9,7,3,2,-99], [0,-5,3,-2], .5),
    "palace": (92, 65, [0,4,7,12,11,9,7,4,5,9,12,16,14,12,7,4], [0,5,-3,7], .25),
    "deep": (80, 50, [0,-99,7,3,2,-99,0,10,7,-99,5,3,1,0,7,-99], [0,-2,1,-5], .125),
    "boss": (148, 54, [0,7,0,12,11,7,3,1,0,7,8,7,3,0,1,3], [0,1,-2,-1], .125),
}


def music(name, config):
    bpm, root, melody, chords, duty = config
    beat = 60 / bpm
    length = beat * 64  # sixteen bars, a complete A-A'-B-A arrangement
    samples = array("f", [0]) * int(length * RATE)
    rng = random.Random(name)
    major = name in ("town", "tutorial", "palace")
    for bar in range(16):
        chord = chords[bar % 4]
        for step in range(8):
            start = (bar * 4 + step * .5) * beat
            index = (bar % 2) * 8 + step
            tune = melody[index]
            if tune > -50:
                octave = 12 if 8 <= bar < 12 else 0
                variation = -2 if bar in (7, 15) and step == 7 else 0
                note(samples, start, beat * .39, root + 12 + tune + octave + variation, .085, duty=duty)
            note(samples, start, beat * .45, root - 12 + chord + (7 if step % 2 else 0), .15, "triangle")
            if bar >= 4:
                harmony = (0, 4 if major else 3, 7, 12)[step % 4]
                note(samples, start + beat * .25, beat * .18, root + chord + harmony, .034, duty=.5)
            drum(samples, start, "kick" if step in (0, 4) else "snare" if step in (2, 6) else "hat", rng)
    temporary = WORK / (name + ".wav")
    write_wav(temporary, samples)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(temporary), "-c:a", "libvorbis", "-q:a", "4", str(OUT / (name + ".ogg"))], check=True)
    print(f"Music {name}: {length:.1f}s", flush=True)


EFFECTS = {
    "jump": [60, 67, 72], "double_jump": [72, 79, 84], "land": [36, 31],
    "dash": [84, 76, 67, 55], "shoot": [89, 71, 48], "hit": [43, 39, 32],
    "hurt": [53, 48, 44, 39], "death": [60, 55, 51, 48, 43, 36],
    "coin": [84, 91], "crate": [48, 35, 31], "chest": [60, 64, 67, 72],
    "switch": [55, 67], "heal": [64, 67, 72, 76], "buy": [67, 72, 79],
    "door": [55, 60, 67], "error": [47, 46], "menu": [76],
    "accept": [72, 79], "achievement": [72, 76, 79, 84, 91],
    "boss_down": [48, 55, 60, 67, 72, 79, 84], "key": [79, 84, 91, 96],
    "shield": [96, 84, 72],
}

if __name__ == "__main__":
    for name, config in SONGS.items():
        music(name, config)
    for name, notes in EFFECTS.items():
        step = .025 if name in ("shoot", "land", "menu") else .055 if name in ("coin", "jump", "hit") else .09
        samples = array("f", [0]) * int((len(notes) * step + .025) * RATE)
        for index, midi in enumerate(notes):
            note(samples, index * step, step, midi, .27, "triangle" if name in ("heal", "land") else "pulse")
        write_wav(OUT / (name + ".wav"), samples)
    print(f"Generated {len(SONGS)} music loops and {len(EFFECTS)} effects.", flush=True)

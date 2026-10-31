#!/usr/bin/env python3
"""Generador procedural de música y efectos para SERAPHALL (provisional).
Uso: python3 tools/gen_audio.py  -> assets/audio/*.ogg y *.wav"""
import os, subprocess, math
import numpy as np
from scipy.signal import lfilter, butter

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(11)

def t_arr(d):
    return np.arange(int(d * SR)) / SR

def note(n):  # n: semitonos desde A4
    return 440.0 * 2 ** (n / 12)

NOTES = {"C": -9, "C#": -8, "Db": -8, "D": -7, "D#": -6, "Eb": -6, "E": -5, "F": -4, "F#": -3, "Gb": -3, "G": -2, "G#": -1, "Ab": -1, "A": 0, "A#": 1, "Bb": 1, "B": 2}
def nf(name, octave):
    return note(NOTES[name] + 12 * (octave - 4))

def lp(x, fc, order=2):
    b, a = butter(order, min(0.99, fc / (SR / 2)), "low")
    return lfilter(b, a, x)

def hp(x, fc, order=2):
    b, a = butter(order, min(0.99, fc / (SR / 2)), "high")
    return lfilter(b, a, x)

def bp(x, lo, hi):
    b, a = butter(2, [lo / (SR / 2), min(0.99, hi / (SR / 2))], "band")
    return lfilter(b, a, x)

def env(n, a, d, s, r, sus_len):
    A = int(a * SR); D = int(d * SR); R = int(r * SR); S = max(0, n - A - D - R)
    e = np.concatenate([np.linspace(0, 1, A, endpoint=False), np.linspace(1, s, D, endpoint=False), np.full(S, s), np.linspace(s, 0, R)])
    return np.pad(e, (0, max(0, n - len(e))))[:n]

def saw(f, t, detune=0.0):
    ph = (f * (1 + detune)) * t
    return 2 * (ph - np.floor(ph + 0.5))

def reverb(x, mix=0.3, size=1.0):
    out = np.zeros_like(x)
    for dly, g in ((1557, 0.84), (1617, 0.83), (1491, 0.85), (1422, 0.86), (1277, 0.87), (1356, 0.86)):
        d = int(dly * size * SR / 44100)
        b = np.zeros(d + 1); b[0] = 1
        a = np.zeros(d + 1); a[0] = 1; a[d] = -g
        out += lfilter(b, a, x)
    out /= 6
    for dly in (225, 556, 441, 341):
        d = int(dly * SR / 44100); g = 0.5
        b = np.zeros(d + 1); b[0] = -g; b[d] = 1
        a = np.zeros(d + 1); a[0] = 1; a[d] = -g
        out = lfilter(b, a, out)
    return x * (1 - mix) + out * mix

# ---------------------------------------------------------------- instrumentos
def choir(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t + rng.uniform(0, 6))
    y = np.zeros(n)
    for v in range(4):  # voces desafinadas
        dt = rng.uniform(-0.006, 0.006)
        for h in range(1, 12):
            fh = f * h * (1 + dt)
            if fh > SR / 2.2: break
            # formante "aah": picos ~ 700 y 1200 Hz
            w = math.exp(-((fh - 750) / 380) ** 2) + 0.7 * math.exp(-((fh - 1200) / 300) ** 2) + 0.35 / h
            y += w * np.sin(2 * np.pi * fh * vib * t + rng.uniform(0, 6))
    y *= env(n, 0.6, 0.3, 0.85, 0.8, n) * vel / 12
    return y

def strings(f, dur, vel=1.0, att=0.02, rel=0.08, bright=2500):
    t = t_arr(dur); n = len(t)
    y = saw(f, t) + saw(f, t, 0.004) + 0.5 * saw(f * 2, t, -0.003)
    y = lp(y, bright)
    return y * env(n, att, 0.05, 0.7, rel, n) * vel * 0.25

def pad(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    y = sum(saw(f, t, d) for d in (-0.007, 0, 0.006)) + 0.6 * saw(f / 2, t)
    y = lp(y, 900)
    return y * env(n, 1.2, 0.5, 0.8, 1.5, n) * vel * 0.12

def bell(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    m = np.sin(2 * np.pi * f * 3.5 * t) * 2.5 * np.exp(-t * 3)
    y = np.sin(2 * np.pi * f * t + m) * np.exp(-t * 2.2)
    return y * vel * 0.35

def brass(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    e = env(n, 0.04, 0.1, 0.8, 0.12, n)
    y = saw(f, t) + saw(f, t, 0.003)
    y = lp(y * (0.4 + 0.6 * e), 600 + 2200 * vel)
    return y * e * vel * 0.3

def timpani(f, dur=1.2, vel=1.0):
    t = t_arr(dur)
    fr = f * (1 + 0.5 * np.exp(-t * 30))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 3.5)
    y += lp(rng.standard_normal(len(t)), 400) * np.exp(-t * 25) * 0.6
    return y * vel * 0.9

def taiko(vel=1.0):
    t = t_arr(0.6)
    fr = 70 * (1 + 1.5 * np.exp(-t * 40))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 7)
    y += lp(rng.standard_normal(len(t)), 900) * np.exp(-t * 30) * 0.8
    return np.tanh(y * 1.6) * vel * 0.8

def snare(vel=1.0):
    t = t_arr(0.25)
    y = bp(rng.standard_normal(len(t)), 800, 6000) * np.exp(-t * 18) + 0.4 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25)
    return y * vel * 0.5

def cymbal(vel=1.0):
    t = t_arr(2.0)
    return hp(rng.standard_normal(len(t)), 5000) * np.exp(-t * 1.6) * vel * 0.18

class Track:
    def __init__(self, dur):
        self.buf = np.zeros(int(dur * SR) + SR * 4)
        self.dur = dur
    def add(self, sig, at, gain=1.0):
        i = int(at * SR)
        j = min(len(self.buf), i + len(sig))
        self.buf[i:j] += sig[: j - i] * gain
    def render(self, rev=0.3, size=1.0):
        y = reverb(self.buf, rev, size)
        L = int(self.dur * SR)
        # cola de reverb sumada al principio para un loop sin cortes
        tail = y[L:]
        y = y[:L].copy()
        m = min(len(tail), L)
        y[:m] += tail[:m]
        y = y / (np.max(np.abs(y)) + 1e-9) * 0.85
        return y

def save(name, y, ogg=True):
    y16 = (np.clip(y, -1, 1) * 32767).astype(np.int16)
    wav = os.path.join(OUT, name + ".wav")
    import wave
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y16.tobytes())
    if ogg:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", os.path.join(OUT, name + ".ogg")], check=True)
        os.remove(wav)

CH = {  # acordes (raíz, notas)
    "Dm": [("D", 3), ("A", 3), ("D", 4), ("F", 4)],
    "Bb": [("Bb", 2), ("F", 3), ("Bb", 3), ("D", 4)],
    "F": [("F", 2), ("C", 3), ("F", 3), ("A", 3)],
    "C": [("C", 3), ("G", 3), ("C", 4), ("E", 4)],
    "Gm": [("G", 2), ("D", 3), ("G", 3), ("Bb", 3)],
    "A": [("A", 2), ("E", 3), ("A", 3), ("C#", 4)],
    "Eb": [("Eb", 3), ("Bb", 3), ("Eb", 4), ("G", 4)],
}

# ---------------------------------------------------------------- tema principal (menú)
def theme():
    bpm = 66; beat = 60 / bpm; bar = beat * 4
    prog = ["Dm", "Bb", "F", "C", "Dm", "Gm", "Bb", "A"]
    T = Track(bar * len(prog))
    for i, c in enumerate(prog):
        t0 = i * bar
        for nm, o in CH[c]:
            T.add(choir(nf(nm, o + 1), bar + 0.6, 0.9), t0)
            T.add(pad(nf(nm, o), bar + 1.0, 0.8), t0)
        T.add(timpani(nf(CH[c][0][0], 2), 2.0, 0.7), t0)
        if i % 2 == 1:
            T.add(timpani(nf(CH[c][0][0], 2), 1.2, 0.4), t0 + beat * 3.5)
    mel = [("D", 5, 0, 2), ("F", 5, 2, 1), ("E", 5, 3, 1), ("D", 5, 4, 3), ("A", 4, 7, 1), ("Bb", 4, 8, 2), ("C", 5, 10, 1), ("D", 5, 11, 1),
           ("F", 5, 12, 2), ("E", 5, 14, 2), ("D", 5, 16, 2), ("F", 5, 18, 1), ("G", 5, 19, 1), ("A", 5, 20, 4), ("G", 5, 24, 2), ("F", 5, 26, 1),
           ("E", 5, 27, 1), ("D", 5, 28, 2), ("C#", 5, 30, 2)]
    for nm, o, b, l in mel:
        T.add(bell(nf(nm, o), 3.0, 0.8), b * beat)
        T.add(strings(nf(nm, o), l * beat, 0.5, att=0.15, rel=0.4, bright=1800), b * beat)
    return T.render(0.45, 1.3)

# ---------------------------------------------------------------- exploración (Vestíbulo de Ceniza)
def explore():
    bpm = 72; beat = 60 / bpm; bar = beat * 4
    prog = ["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "A", "A", "Dm", "Dm", "Eb", "Eb", "Bb", "C", "A", "A"]
    T = Track(bar * len(prog))
    for i, c in enumerate(prog):
        t0 = i * bar
        if i % 2 == 0:
            for nm, o in CH[c][:3]:
                T.add(pad(nf(nm, o), bar * 2 + 1.5, 0.9), t0)
        # ostinato grave suave
        r = CH[c][0]
        for k in range(4):
            T.add(strings(nf(r[0], r[1]), beat * 0.9, 0.35, att=0.05, rel=0.3, bright=700), t0 + k * beat)
        # campanas dispersas
        if i % 2 == 1:
            nm, o = CH[c][3]
            T.add(bell(nf(nm, o + 1), 4.0, 0.45), t0 + beat * (1 + (i % 3)))
        if i % 4 == 3:
            T.add(choir(nf(CH[c][2][0], 4), bar, 0.5), t0)
    return T.render(0.5, 1.5)

# ---------------------------------------------------------------- jefe (Seravel) fase 1 y 2
def boss(phase=1):
    bpm = 148 if phase == 1 else 156; beat = 60 / bpm; bar = beat * 4
    prog = ["Dm", "Dm", "Bb", "C", "Dm", "Dm", "Gm", "A"] * (1 if phase == 1 else 1)
    if phase == 2:
        prog = ["Dm", "Eb", "Dm", "Eb", "Bb", "C", "Gm", "A"]
    T = Track(bar * len(prog) * 2)
    for rep in range(2):
        for i, c in enumerate(prog):
            t0 = (rep * len(prog) + i) * bar
            root = CH[c][0]
            # ostinato de cuerdas en semicorcheas
            seq = [0, 0, 12, 0, 7, 0, 12, 3] if phase == 1 else [0, 12, 0, 7, 0, 12, 3, 12]
            for k in range(16):
                f = nf(root[0], root[1] + 1) * 2 ** (seq[k % 8] / 12)
                T.add(strings(f, beat / 4 * 0.9, 0.55 if k % 4 == 0 else 0.4, bright=3000), t0 + k * beat / 4)
            # coro
            for nm, o in CH[c]:
                T.add(choir(nf(nm, o + 1), bar + 0.3, 1.0 if phase == 2 else 0.8), t0)
            # percusión
            pat = [1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1] if phase == 2 else [1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0]
            for k, v in enumerate(pat):
                if v: T.add(taiko(0.9 if k % 4 == 0 else 0.6), t0 + k * beat / 4)
            for k in (1, 3):
                T.add(snare(0.7), t0 + k * beat)
            T.add(timpani(nf(root[0], 2), 1.0, 0.9), t0)
            if i % 4 == 0:
                T.add(cymbal(0.9), t0)
            # metales
            if i % 2 == 1 or phase == 2:
                for nm, o in CH[c][1:3]:
                    T.add(brass(nf(nm, o + 1), beat * 1.5, 0.9), t0 + beat * 2)
                    T.add(brass(nf(nm, o + 1), beat * 0.5, 0.7), t0 + beat * 3.5)
    return T.render(0.25, 1.0)

def piano(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    y = np.zeros(n)
    for h, amp in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.06)):
        fh = f * h * (1 + 0.0004 * h * h)
        y += amp * np.sin(2 * np.pi * fh * t) * np.exp(-t * (1.6 + h * 0.9))
    y *= np.minimum(1.0, t / 0.004)
    return lp(y, 4200) * vel * 0.45

def musicbox(f, dur, vel=1.0):
    t = t_arr(dur)
    y = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 6) + 0.2 * np.sin(2 * np.pi * f * 2.0 * t)
    return y * np.exp(-t * 2.6) * vel * 0.3

def soft_pad(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    y = sum(np.sin(2 * np.pi * f * k * t + rng.uniform(0, 6)) / k for k in (1, 2, 3)) + 0.5 * np.sin(2 * np.pi * f * 1.003 * t)
    return lp(y, 1200) * env(n, 2.0, 0.5, 0.8, 2.0, n) * vel * 0.1

def peace():
    """Santuario / lugares de paz: caja de música y cuerdas suaves (Re mayor / Si menor)."""
    bpm = 64; beat = 60 / bpm; bar = beat * 3   # compás de 3/4
    prog = [("D", [("D", 3), ("A", 3), ("F#", 4)]), ("Bm", [("B", 2), ("F#", 3), ("D", 4)]), ("G", [("G", 2), ("D", 3), ("B", 3)]), ("A", [("A", 2), ("E", 3), ("C#", 4)]),
            ("D", [("D", 3), ("A", 3), ("F#", 4)]), ("F#m", [("F#", 2), ("C#", 3), ("A", 3)]), ("G", [("G", 2), ("D", 3), ("B", 3)]), ("A", [("A", 2), ("E", 3), ("A", 3)])]
    T = Track(bar * len(prog) * 2)
    mel = [("F#", 5), ("A", 5), ("D", 6), ("C#", 6), ("B", 5), ("A", 5), ("G", 5), ("F#", 5), ("E", 5), ("F#", 5), ("A", 5), ("E", 5),
           ("F#", 5), ("D", 5), ("E", 5), ("C#", 5), ("D", 5), ("F#", 5), ("A", 5), ("B", 5), ("A", 5), ("G", 5), ("E", 5), ("C#", 5)]
    for rep in range(2):
        for i, (name, notes) in enumerate(prog):
            t0 = (rep * len(prog) + i) * bar
            for nm, o in notes:
                T.add(soft_pad(nf(nm, o), bar + 1.5, 0.9), t0)
            # arpegio de piano suave
            arp = [notes[0], notes[1], notes[2], notes[1], notes[2], notes[1]]
            for k, (nm, o) in enumerate(arp):
                T.add(piano(nf(nm, o + (1 if k >= 2 else 0)), 2.5, 0.5 if k else 0.7), t0 + k * beat / 2)
            # melodía de caja de música (3 notas por compás)
            for k in range(3):
                nm, o = mel[(i * 3 + k) % len(mel)]
                if rep == 1 or k != 1:
                    T.add(musicbox(nf(nm, o), 2.5, 0.75), t0 + k * beat)
    return T.render(0.55, 1.6)

def memory():
    """Contemplación: piano lento y melancólico (Si menor)."""
    bpm = 52; beat = 60 / bpm; bar = beat * 4
    prog = [[("B", 2), ("F#", 3), ("D", 4)], [("G", 2), ("D", 3), ("B", 3)], [("D", 3), ("A", 3), ("F#", 4)], [("A", 2), ("E", 3), ("C#", 4)],
            [("E", 2), ("B", 2), ("G", 3)], [("G", 2), ("D", 3), ("B", 3)], [("F#", 2), ("C#", 3), ("A#", 3)], [("B", 2), ("F#", 3), ("B", 3)]]
    mel = [("F#", 5), ("D", 5), ("B", 4), ("C#", 5), ("D", 5), ("E", 5), ("F#", 5), ("A", 5), ("G", 5), ("F#", 5), ("E", 5), ("D", 5),
           ("E", 5), ("D", 5), ("C#", 5), ("B", 4)]
    T = Track(bar * len(prog))
    for i, notes in enumerate(prog):
        t0 = i * bar
        for k, (nm, o) in enumerate(notes):
            T.add(piano(nf(nm, o), 4.0, 0.6), t0 + k * 0.03)
        T.add(piano(nf(notes[1][0], notes[1][1] + 1), 3.0, 0.4), t0 + beat * 2)
        for k in range(2):
            nm, o = mel[(i * 2 + k) % len(mel)]
            T.add(piano(nf(nm, o), 3.5, 0.75), t0 + k * beat * 2 + beat * 0.5)
        for nm, o in notes:
            T.add(soft_pad(nf(nm, o + 1), bar + 1.0, 0.6), t0)
    return T.render(0.6, 1.8)

def victory():
    T = Track(7.0)
    for i, (nm, o) in enumerate([("D", 4), ("F", 4), ("A", 4), ("D", 5)]):
        T.add(bell(nf(nm, o), 4, 0.8), i * 0.18)
    for nm, o in [("D", 3), ("F#", 3), ("A", 3), ("D", 4)]:
        T.add(choir(nf(nm, o + 1), 5.5, 1.0), 0.6)
        T.add(brass(nf(nm, o), 2.0, 0.7), 0.6)
    T.add(timpani(nf("D", 2), 2.0, 1.0), 0.6)
    T.add(cymbal(0.8), 0.6)
    return T.render(0.45, 1.4)

import sys
FORCE = "--force" in sys.argv
print("Componiendo música...")
for _name, _fn in (("music_theme", theme), ("music_explore", explore), ("music_boss1", lambda: boss(1)),
                   ("music_boss2", lambda: boss(2)), ("music_victory", victory), ("music_peace", peace), ("music_memory", memory)):
    if FORCE or not os.path.exists(os.path.join(OUT, _name + ".ogg")):
        save(_name, _fn())

# ---------------------------------------------------------------- efectos de sonido
def norm(y, g=0.9):
    return y / (np.max(np.abs(y)) + 1e-9) * g

def whoosh(dur=0.22, lo=500, hi=4000, g=0.7):
    t = t_arr(dur); n = len(t)
    noise = rng.standard_normal(n)
    e = np.sin(np.pi * np.linspace(0, 1, n)) ** 1.5
    y = bp(noise, lo, hi) * e
    return norm(y, g)

def hit(heavy=False):
    t = t_arr(0.3)
    fr = (120 if heavy else 180) * (1 + 2 * np.exp(-t * 50))
    body = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * (12 if heavy else 18))
    click = bp(rng.standard_normal(len(t)), 1500, 8000) * np.exp(-t * 60)
    return norm(np.tanh((body + click * 0.8) * 2.5), 0.95)

def parry():
    t = t_arr(0.9)
    y = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) for f, d in ((1320, 4), (1980, 5), (2770, 7), (3960, 9)))
    y += bp(rng.standard_normal(len(t)), 3000, 9000) * np.exp(-t * 40)
    return norm(reverb(y, 0.3), 0.9)

def lance():
    t = t_arr(0.45)
    f = 600 + 1800 * t / 0.45
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 4) + 0.5 * np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR) * np.exp(-t * 6)
    y += whoosh(0.45, 2000, 8000, 0.4)
    return norm(reverb(y, 0.25), 0.8)

def boom(dur=1.0, f0=60):
    t = t_arr(dur)
    fr = f0 * (1 + 2 * np.exp(-t * 20))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t * 4)
    y += lp(rng.standard_normal(len(t)), 1200) * np.exp(-t * 6)
    return norm(np.tanh(y * 2), 0.95)

def chime(notes, step=0.07):
    T = Track(1.6)
    for i, n in enumerate(notes):
        T.add(bell(note(n), 1.2, 0.7), i * step)
    return T.render(0.3)[: int(1.6 * SR)]

def hurt():
    t = t_arr(0.35)
    f = 300 * (1 - 0.5 * t / 0.35)
    y = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * np.exp(-t * 8)
    h = hit(); h = np.pad(h, (0, max(0, len(t) - len(h))))[: len(t)]
    return norm(lp(y, 1500) + h * 0.5, 0.8)

def die():
    t = t_arr(0.8)
    y = lp(rng.standard_normal(len(t)), 600) * np.exp(-t * 4)
    f = 200 * (1 - 0.7 * t / 0.8)
    y += np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5) * 0.6
    return norm(y, 0.8)

def roar():
    t = t_arr(1.6)
    f = 90 + 30 * np.sin(2 * np.pi * 3 * t)
    y = saw(1, t) * 0
    ph = np.cumsum(f) / SR
    y = 2 * (ph - np.floor(ph + 0.5))
    y = bp(y + 0.5 * rng.standard_normal(len(t)), 150, 1800)
    y *= env(len(t), 0.15, 0.2, 0.8, 0.8, len(t))
    return norm(np.tanh(reverb(y, 0.4) * 3), 0.95)

def blip(f=880, d=0.08):
    t = t_arr(d)
    return norm(np.sin(2 * np.pi * f * t) * np.exp(-t * 30), 0.5)

def step():
    t = t_arr(0.08)
    return norm(lp(rng.standard_normal(len(t)), 500) * np.exp(-t * 60), 0.35)

def gate_sfx():
    t = t_arr(2.0)
    y = lp(rng.standard_normal(len(t)), 200) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * t)) * env(len(t), 0.2, 0.2, 0.8, 0.6, len(t))
    return norm(y + boom(2.0, 45) * 0.5, 0.8)

def charge():
    t = t_arr(0.18)
    return norm(np.sin(2 * np.pi * (500 + 1500 * t / 0.18) * t) * np.exp(-t * 10), 0.4)

SFX = {
    "swing": whoosh(0.18, 800, 5000, 0.6), "swing_heavy": whoosh(0.32, 300, 2500, 0.8), "dash": whoosh(0.25, 1500, 9000, 0.5),
    "hit": hit(False), "hit_heavy": hit(True), "parry": parry(), "lance": lance(), "nova": boom(1.0, 70), "slam": boom(1.2, 50),
    "heal": chime([3, 7, 10, 15]), "levelup": chime([0, 4, 7, 12, 16, 19], 0.09), "pickup": blip(1320, 0.1), "ui_move": blip(660, 0.05),
    "ui_ok": chime([7, 12], 0.05), "hurt": hurt(), "die": die(), "roar": roar(), "step": step(), "gate": gate_sfx(), "charge": charge(),
    "enemy_shot": whoosh(0.2, 400, 2500, 0.4), "quest": chime([0, 7, 12, 19], 0.12),
}
for k, v in SFX.items():
    save("sfx_" + k, v, ogg=False)
print("Audio generado en", os.path.abspath(OUT))

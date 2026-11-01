#!/usr/bin/env python3
"""SERAPHALL - banda sonora y sonidos procedurales (v0.5).
Inspirado en la técnica de leitmotivs de Undertale: unas pocas melodías que reaparecen transformadas
(más lentas, al revés, en mayor, en otro instrumento) en todas las pistas.

Leitmotivs:
  PLUMA     - el Desplumado / la esperanza (re menor; en re mayor en la paz y la victoria)
  VOZ       - el Arquitecto (tritonos; aparece escondido en el bajo y en la Sombra)
  SERAVEL   - la Guardiana de las Puertas
  CORO      - el lamento cromático del Coro Hueco
  CADENA    - el riff del Carcelero
Uso: python3 tools/gen_music.py   (escribe assets/audio/music_*.ogg y sfx_*.wav)"""
import os, subprocess, wave
import numpy as np
from scipy.signal import lfilter, butter, fftconvolve

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
RNG = np.random.default_rng(7)

def mf(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)

def T(d):
    return np.arange(int(d * SR)) / SR

def lp(x, fc, o=2):
    b, a = butter(o, min(fc, SR / 2 - 100) / (SR / 2), "low"); return lfilter(b, a, x)

def hp(x, fc, o=2):
    b, a = butter(o, fc / (SR / 2), "high"); return lfilter(b, a, x)

def bp(x, lo, hi, o=2):
    b, a = butter(o, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], "band"); return lfilter(b, a, x)

def adsr(n, a, d, s, r):
    e = np.ones(n) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    na = min(na, n); e[:na] = np.linspace(0, 1, na) if na else e[:na]
    if nd and na < n:
        k = min(nd, n - na); e[na:na + k] = np.linspace(1, s, k)
    if nr:
        k = min(nr, n); e[n - k:] *= np.linspace(1, 0, k)
    return e

def osc_saw(f, t, ph=0.0):
    return 2.0 * ((f * t + ph) % 1.0) - 1.0

def norm(x, g=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * g

# ------------------------------------------------------------------ instrumentos
def mbox(f, d, v=1.0):
    t = T(max(d, 1.6)); e = np.exp(-t * 2.4)
    y = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t * 5) + 0.18 * np.sin(2 * np.pi * f * 5.04 * t) * np.exp(-t * 8)
    return y * e * v * 0.5

def bell(f, d, v=1.0):
    t = T(max(d, 2.5)); idx = 3.0 * np.exp(-t * 3)
    y = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * 3.5 * t))
    y += 0.4 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 2.2)
    return y * np.exp(-t * 1.3) * v * 0.35

def chip(f, d, v=1.0, duty=0.25):
    t = T(d); vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) * 4, 0, 1)
    ph = np.cumsum(f * vib / SR) % 1.0
    y = np.where(ph < duty, 1.0, -1.0)
    return lp(y, 5000) * adsr(len(t), 0.005, 0.08, 0.6, 0.05) * v * 0.22

def harp(f, d, v=1.0):
    n = int(max(d, 1.8) * SR); N = max(2, int(SR / f))
    x = np.zeros(n); x[:N] = RNG.uniform(-1, 1, N)
    a = np.zeros(N + 2); a[0] = 1; a[N] = -0.4985; a[N + 1] = -0.4985
    y = lfilter([1.0], a, x)
    return lp(y, 4500) * v * 0.5

def choir(f, d, v=1.0, vowel="a"):
    t = T(d + 0.4); vib = 1 + 0.005 * np.sin(2 * np.pi * 5.2 * t + RNG.uniform(0, 6))
    y = np.zeros(len(t))
    for det in (-0.006, 0.0, 0.007):
        y += osc_saw(f * (1 + det), np.cumsum(vib) / SR, RNG.uniform())
    F = {"a": (800, 1150, 2900), "o": (450, 800, 2830), "u": (325, 700, 2530)}[vowel]
    z = bp(y, F[0] * 0.8, F[0] * 1.2) * 1.0 + bp(y, F[1] * 0.85, F[1] * 1.15) * 0.6 + bp(y, F[2] * 0.9, F[2] * 1.1) * 0.25
    return z * adsr(len(t), 0.35, 0.2, 0.85, 0.45) * v * 0.9

def organ(f, d, v=1.0):
    t = T(d + 0.1); y = np.zeros(len(t))
    for h, w in ((0.5, 0.5), (1, 1.0), (2, 0.6), (3, 0.35), (4, 0.3), (6, 0.15), (8, 0.12)):
        y += w * np.sin(2 * np.pi * f * h * t)
    y *= 1 + 0.12 * np.sin(2 * np.pi * 6.0 * t)
    return y * adsr(len(t), 0.02, 0.1, 0.9, 0.12) * v * 0.16

def strings(f, d, v=1.0, att=0.25, bright=2200):
    t = T(d + 0.3); y = np.zeros(len(t))
    for det in (-0.004, 0.003, 0.009):
        y += osc_saw(f * (1 + det), t, RNG.uniform())
    return lp(y, bright, 2) * adsr(len(t), att, 0.2, 0.8, 0.3) * v * 0.18

def brass(f, d, v=1.0):
    t = T(d + 0.1); y = osc_saw(f, t) + 0.5 * osc_saw(f * 1.003, t)
    fe = np.exp(-t * 6)
    out = lp(y, 3200) * fe + lp(y, 700) * (1 - fe)
    return out * adsr(len(t), 0.03, 0.15, 0.7, 0.08) * v * 0.25

def bass(f, d, v=1.0, dist=0.0):
    t = T(d); y = 2 * np.abs(2 * ((f * t) % 1) - 1) - 1 + 0.6 * np.sin(2 * np.pi * f * 0.5 * t)
    if dist:
        y = np.tanh(y * (1 + dist * 6))
    return lp(y, 1200) * adsr(len(t), 0.005, 0.1, 0.8, 0.04) * v * 0.4

def drone(f, d, v=1.0):
    t = T(d); y = np.zeros(len(t))
    for det in (-0.01, -0.003, 0.004, 0.011):
        y += osc_saw(f * (1 + det), t, RNG.uniform())
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.07 * t)
    out = lp(y, 260) * (1 - lfo) + lp(y, 650) * lfo
    return out * adsr(len(t), 2.0, 0.5, 1.0, 2.0) * v * 0.18

def kick(v=1.0):
    t = T(0.35); f = 45 + 110 * np.exp(-t * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9) * v

def taiko(v=1.0):
    t = T(0.8); f = 55 + 60 * np.exp(-t * 18)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 5) + lp(RNG.normal(0, 1, len(t)), 600) * np.exp(-t * 25) * 0.6
    return y * v * 0.9

def snare(v=1.0):
    t = T(0.25); y = hp(RNG.normal(0, 1, len(t)), 1200) * np.exp(-t * 18) + 0.5 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25)
    return y * v * 0.45

def hat(v=1.0, open_=False):
    t = T(0.3 if open_ else 0.06); y = hp(RNG.normal(0, 1, len(t)), 7000) * np.exp(-t * (12 if open_ else 70))
    return y * v * 0.25

def chain(v=1.0):
    t = T(0.45); y = np.zeros(len(t))
    for r in (1.0, 1.47, 2.31, 3.17):
        y += np.sin(2 * np.pi * 820 * r * t + 2 * np.sin(2 * np.pi * 1300 * t))
    y = y * np.exp(-t * 9) + hp(RNG.normal(0, 1, len(t)), 3000) * np.exp(-t * 30) * 0.7
    return y * v * 0.18

def timpani(f, v=1.0):
    t = T(1.4); y = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.5 * t)
    return (y * np.exp(-t * 3) + lp(RNG.normal(0, 1, len(t)), 300) * np.exp(-t * 20) * 0.5) * v * 0.5

def wind(d, v=1.0):
    t = T(d); y = RNG.normal(0, 1, len(t))
    y = bp(y, 300, 1400) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t) * np.sin(2 * np.pi * 0.037 * t))
    return y * v * 0.25

def heartbeat(v=1.0):
    t = T(0.6)
    one = lambda dl: np.concatenate([np.zeros(int(dl * SR)), np.sin(2 * np.pi * np.cumsum(50 + 30 * np.exp(-t * 25)) / SR) * np.exp(-t * 14)])
    a = one(0.0); b = one(0.17) * 0.7
    n = max(len(a), len(b)); y = np.zeros(n); y[:len(a)] += a; y[:len(b)] += b
    return lp(y, 300) * v

# ------------------------------------------------------------------ efectos de mezcla
def reverb(x, mix=0.3, t60=2.2):
    n = int(t60 * SR); t = np.arange(n) / SR
    ir = RNG.normal(0, 1, n) * np.exp(-6.9 * t / t60)
    ir = lp(ir, 5000); ir[:int(0.012 * SR)] = 0; ir /= np.sqrt(np.sum(ir ** 2))
    wet = fftconvolve(x, ir)[:len(x)]
    return x * (1 - mix) + wet * mix * 0.9

def tape(x, depth=0.0025, rate=0.6):
    n = len(x); t = np.arange(n) / SR
    pos = np.arange(n) + depth * SR * np.sin(2 * np.pi * rate * t) / (2 * np.pi * rate)
    return np.interp(np.clip(pos, 0, n - 1), np.arange(n), x)

def crush(x, bits=6, keep=3):
    q = 2 ** bits; y = np.round(x * q) / q
    y = np.repeat(y[::keep], keep)[:len(x)]
    return y

def crackle(d, v=1.0):
    n = int(d * SR); y = np.zeros(n)
    idx = RNG.integers(0, n, int(d * 18)); y[idx] = RNG.uniform(-1, 1, len(idx))
    return lp(y, 3500) * v * 0.4 + lp(RNG.normal(0, 1, n), 800) * 0.01

# ------------------------------------------------------------------ secuenciador
class Song:
    def __init__(self, bpm, beats, tail=3.0):
        self.spb = 60.0 / bpm; self.beats = beats
        self.len = int(beats * self.spb * SR)
        self.buf = np.zeros(self.len + int(tail * SR))
    def add(self, w, beat, g=1.0):
        i = int(beat * self.spb * SR)
        if i >= len(self.buf):
            return
        seg = w[:len(self.buf) - i]; self.buf[i:i + len(seg)] += seg * g
    def seq(self, inst, notes, start=0.0, g=1.0, oct_=0, legato=1.0, **kw):
        b = start
        for m, d in notes:
            if m is not None:
                self.add(inst(mf(m + 12 * oct_), d * self.spb * legato, **kw), b, g)
            b += d
        return b
    def chord(self, inst, ms, beat, dur, g=1.0, **kw):
        for m in ms:
            self.add(inst(mf(m), dur * self.spb, **kw), beat, g / max(1, len(ms)) * 1.6)
    def loop(self):
        """Envuelve la cola (reverb/notas largas) al principio para un bucle sin costuras."""
        y = self.buf[:self.len].copy(); tail = self.buf[self.len:]
        y[:len(tail)] += tail
        return y
    def oneshot(self):
        return self.buf

def save_music(name, y, loop=True):
    y = np.tanh(norm(y, 0.95) * 1.15) * 0.9
    if not loop:
        y[-int(0.5 * SR):] *= np.linspace(1, 0, int(0.5 * SR))
    y16 = (np.clip(y, -1, 1) * 32767).astype(np.int16)
    wav = os.path.join(OUT, "music_%s.wav" % name)
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y16.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", wav[:-4] + ".ogg"], check=True)
    os.remove(wav)
    print("  music_%s.ogg  %.1fs" % (name, len(y) / SR))

def save_sfx(name, y, g=0.9):
    y16 = (np.clip(norm(y, g), -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, "sfx_%s.wav" % name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y16.tobytes())

# ------------------------------------------------------------------ leitmotivs (MIDI, pulsos)
D4, E4, F4, G4, A4, Bb4, C5, D5, E5, F5, G5, A5 = 62, 64, 65, 67, 69, 70, 72, 74, 76, 77, 79, 81
PLUMA = [(D5, 1), (A5, 1), (G5, 0.5), (F5, 0.5), (E5, 1), (F5, 0.5), (E5, 0.5), (D5, 2), (C5, 1), (D5, 0.5), (E5, 0.5), (F5, 1), (E5, 1), (C5, 1), (D5, 3)]   # 16 pulsos
PLUMA_MAJ = [(m + (1 if m % 12 in (5, 0) else 0), d) for m, d in PLUMA]    # F->F#, C->C#: re mayor
VOZ = [(D4 - 12, 2), (56 - 12, 2), (G4 - 12, 1), (61 - 12, 3)]
SERAVEL = [(A4, 1.5), (C5, 0.5), (E5, 1), (D5, 1), (C5, 0.5), (71, 0.5), (A4, 2), (F4, 1), (G4, 1), (A4, 1), (E5, 1), (D5, 4)]  # 16
CORO = [(E5, 1), (69 + 6, 1), (D5 + 1, 1), (D5, 1), (73, 1), (C5, 1), (71, 2)]   # lamento cromático descendente (8)
CADENA = [(38, 0.5), (38, 0.5), (41, 0.5), (38, 0.5), (44, 1), (43, 0.5), (41, 0.5)]  # 4 pulsos
Dm, Bb, F, C, Gm, A, Eb = [50, 57, 62, 65], [46, 53, 58, 62], [41, 48, 53, 57], [48, 55, 60, 64], [43, 50, 55, 58], [45, 52, 57, 61], [51, 58, 63, 67]
D, G, Bm, Fsm = [50, 57, 62, 66], [43, 50, 55, 59], [47, 54, 59, 62], [42, 49, 54, 57]

def reversed_notes(ns):
    return list(reversed(ns))

# ------------------------------------------------------------------ pistas
def theme():
    s = Song(72, 64)
    s.add(drone(mf(38), 64 * s.spb), 0, 1.0)
    s.add(wind(64 * s.spb, 0.5), 0)
    prog = [Dm, Bb, F, C, Dm, Bb, Gm, A]
    for i, ch in enumerate(prog * 2):
        s.chord(strings, ch, i * 4, 4, 0.9, att=0.6, bright=1600)
        s.add(timpani(mf(ch[0]), 0.5), i * 4)
    s.seq(bell, PLUMA, 16, 0.55)
    s.seq(choir, PLUMA, 32, 0.6, oct_=-1)
    s.seq(mbox, PLUMA, 48, 0.4, oct_=1)
    s.seq(bass, VOZ, 48, 0.45)
    return reverb(s.loop(), 0.35, 3.2)

def explore():
    """Vestíbulo de Ceniza: ruinas espeluznantes. Dron, campanas lejanas con fragmentos de PLUMA y silencios."""
    s = Song(66, 64)
    s.add(drone(mf(38), 64 * s.spb), 0, 1.1)
    s.add(drone(mf(45), 64 * s.spb), 0, 0.5)
    s.add(wind(64 * s.spb, 0.5), 0)
    frag = PLUMA[:4]
    for b in (4, 20, 36, 52):
        s.seq(bell, frag, b, 0.35, oct_=-1)
    s.seq(mbox, [(D5, 2), (None, 2), (Bb4 + 12, 2), (A5, 6)], 12, 0.25)
    s.seq(mbox, [(F5, 2), (E5, 2), (C5, 2), (D5, 6)], 44, 0.25)
    for i in range(16):
        s.add(kick(0.25), i * 4)
        if i % 2:
            s.add(chain(0.12), i * 4 + 2.5)
    for i, ch in enumerate([Dm, Bb, Gm, A] * 4):
        s.chord(choir, ch[1:], i * 4, 4, 0.35, vowel="u")
    s.seq(bass, VOZ, 56, 0.35)
    return reverb(s.loop(), 0.45, 3.5)

def peace():
    """Mirador y Sala del Nimbo: arpa (cuerdas pulsadas) y PLUMA en re mayor. Cálida y nostálgica."""
    s = Song(76, 64)
    prog = [D, Bm, G, A, D, Fsm, G, A]
    for i, ch in enumerate(prog * 2):
        for k in range(8):
            m = ch[(k * 2) % 4] + (12 if k >= 4 else 0)
            s.add(harp(mf(m), 0.5 * s.spb), i * 4 + k * 0.5, 0.5)
        s.chord(strings, ch, i * 4, 4, 0.35, att=0.8, bright=1400)
    s.seq(mbox, PLUMA_MAJ, 16, 0.45)
    s.seq(choir, PLUMA_MAJ, 48, 0.35, oct_=-1, vowel="o")
    s.add(wind(64 * s.spb, 0.15), 0)
    return reverb(s.loop(), 0.35, 2.8)

def memory():
    """Recuerdo: caja de música sola, cinta que se tuerce y crepitar de vinilo."""
    s = Song(60, 40)
    s.seq(mbox, PLUMA_MAJ, 0, 0.8)
    s.seq(mbox, [(m - 12, d) for m, d in PLUMA[:8]], 0, 0.25)
    s.seq(mbox, PLUMA, 18, 0.7)
    s.seq(mbox, [(D5 + 12, 4)], 36, 0.3)
    y = s.loop() + crackle(len(s.loop()) / SR, 0.5)
    return reverb(tape(y, 0.004, 0.45), 0.4, 3.0)

def boss_carcelero():
    """El Carcelero: industrial, cadenas, taikos y bajo distorsionado con el riff CADENA."""
    s = Song(138, 96)
    for bar in range(24):
        b = bar * 4
        s.seq(bass, CADENA, b, 0.9, dist=0.6)
        s.add(taiko(1.0), b); s.add(taiko(0.7), b + 1.5); s.add(taiko(0.9), b + 2)
        s.add(snare(0.8), b + 1); s.add(snare(0.9), b + 3)
        for k in range(8):
            s.add(chain(0.5 if k % 2 == 0 else 0.25), b + k * 0.5 + 0.25)
        if bar % 4 == 3:
            s.add(chain(1.0), b + 3.5); s.add(chain(1.0), b + 3.75)
    for i, ch in enumerate([Dm, Bb, Gm, A] * 6):
        s.chord(brass, [ch[1], ch[2]], i * 4, 0.5, 0.8)
        s.chord(brass, [ch[1], ch[2]], i * 4 + 2.5, 0.5, 0.6)
    s.seq(brass, [(m - 12, d) for m, d in PLUMA], 32, 0.45)
    s.seq(organ, [(m - 12, d) for m, d in VOZ] * 2, 64, 0.5)
    return reverb(s.loop(), 0.2, 1.6)

def boss_choir():
    """El Coro Hueco: órgano, coro de vocales y el lamento CORO; 6/8 inquietante."""
    s = Song(116, 96)
    for i in range(32):
        b = i * 3
        s.add(kick(0.6), b); s.add(hat(0.5), b + 1); s.add(hat(0.5), b + 2)
        if i % 2:
            s.add(snare(0.5), b + 1.5)
    for i, ch in enumerate([Dm, [49, 56, 61, 65], Gm, A] * 8):
        s.chord(organ, ch, i * 3, 3, 0.9)
    for b in (0, 24, 48, 72):
        s.seq(choir, CORO, b, 0.75, vowel="a")
        s.seq(choir, [(m - 5, d) for m, d in CORO], b, 0.45, vowel="o")
    s.seq(chip, PLUMA, 40, 0.5, duty=0.125)
    s.seq(bell, VOZ, 64, 0.6, oct_=2)
    for i in range(48):
        s.add(harp(mf([62, 65, 69, 74][i % 4] + (12 if (i // 12) % 2 else 0)), 0.4), 48 + i * 0.5, 0.25)
    return reverb(s.loop(), 0.3, 2.6)

def boss_seravel(p3=False):
    """Seravel: coro épico, ostinato de cuerdas, taikos; SERAVEL contra PLUMA. Fase final más rápida y en tritono."""
    bpm = 168 if p3 else 150
    s = Song(bpm, 128)
    prog = [Dm, Bb, C, A] if not p3 else [Dm, [56, 62, 65, 68], Bb, A]
    for bar in range(32):
        b = bar * 4; ch = prog[bar % 4]
        for k in range(8):
            s.add(strings(mf(ch[(k % 2) + 1] + 12), 0.45 * s.spb, att=0.01, bright=3000), b + k * 0.5, 0.55)
        s.add(taiko(1.0), b); s.add(taiko(0.8), b + 2); s.add(kick(0.7), b + 3.5)
        s.add(snare(0.7), b + 1); s.add(snare(0.8), b + 3)
        if p3:
            for k in range(8):
                s.add(hat(0.6), b + k * 0.5 + 0.25)
        s.add(bass(mf(ch[0] - 12), 4 * s.spb, dist=0.3 if p3 else 0.1), b, 0.8)
        s.chord(choir, ch[1:], b, 4, 0.7, vowel="a")
    s.seq(choir, SERAVEL, 16, 0.85, oct_=0, vowel="a")
    s.seq(brass, SERAVEL, 48, 0.55)
    s.seq(bell, PLUMA, 80, 0.45)
    s.seq(choir, PLUMA, 96, 0.7, vowel="o")
    s.seq(brass, [(m - 12, d) for m, d in SERAVEL], 112, 0.6)
    if p3:
        s.seq(organ, VOZ * 4, 64, 0.6)
    return reverb(s.loop(), 0.22, 2.0)

def trial():
    """Pruebas de las antesalas: tensión creciente. Ostinato de cuerdas en Re menor, taikos a contratiempo,
    el riff CADENA en pizzicato grave y la PLUMA en metales cuando la prueba se pone seria."""
    s = Song(132, 64)
    for bar in range(16):
        b = bar * 4
        s.add(taiko(0.9), b); s.add(taiko(0.6), b + 1.5); s.add(taiko(0.8), b + 2.5)
        s.add(snare(0.45), b + 3)
        for k in range(8):
            s.add(hat(0.25 if k % 2 else 0.4), b + k * 0.5)
        if bar >= 8 and bar % 2 == 1:
            s.add(chain(0.6), b + 3.5)
    for i, ch in enumerate([Dm, Dm, Bb, A] * 4):
        for k in range(8):
            s.add(strings(mf(ch[1 + (k % 3)] + 12), 0.45 * Song(132, 1).spb, 0.35, att=0.01, bright=2600), i * 4 + k * 0.5)
        s.add(bass(mf(ch[0] - 12), 3.5 * Song(132, 1).spb, 0.7, dist=0.3), i * 4)
    s.seq(brass, [(m - 12, d) for m, d in PLUMA], 32, 0.5)
    s.seq(bass, CADENA * 4, 16, 0.45, dist=0.5)
    return reverb(s.loop(), 0.22, 1.8)

def chapel():
    """Capilla Olvidada (v0.8): órgano muy suave y coro que tararea en re menor; la PLUMA en campanas
    lejanas, lenta y rota, como una nana que alguien intenta recordar."""
    s = Song(54, 48)
    prog = [Dm, Bb, Gm, A, Dm, F, Gm, A, Dm, Bb, Eb, A]
    for i, ch in enumerate(prog):
        s.chord(organ, ch, i * 4, 4, 0.32)
        s.chord(choir, [m + 12 for m in ch[1:]], i * 4, 4, 0.22, vowel="o")
        s.add(bass(mf(ch[0] - 12), 3.8 * s.spb, 0.4), i * 4)
    s.seq(bell, [(m, d * 2) for m, d in PLUMA[:7]], 8, 0.32)
    s.seq(mbox, [(m + 12, d * 2) for m, d in PLUMA[:6]], 30, 0.25)
    s.add(wind(48 * s.spb, 0.12), 0)
    return reverb(tape(s.loop(), 0.002, 0.3), 0.5, 3.6)

def shadow():
    """La Sombra: PLUMA al revés, desafinada y triturada, con latido."""
    s = Song(84, 32)
    s.seq(chip, reversed_notes(PLUMA), 0, 0.5, oct_=-1, duty=0.5)
    s.seq(mbox, [(m + 1, d) for m, d in reversed_notes(PLUMA)], 16, 0.45)
    for i in range(32):
        s.add(heartbeat(0.9), i * 1.0)
    s.add(drone(mf(37), 32 * s.spb), 0, 0.9)
    y = crush(s.loop(), 5, 2) * 0.6 + s.loop() * 0.4
    return reverb(tape(y, 0.006, 0.3), 0.35, 2.5)

def victory():
    s = Song(100, 14, tail=3.0)
    s.chord(brass, D, 0, 1, 1.0); s.chord(brass, G, 1, 1, 1.0); s.chord(brass, A, 2, 1, 1.0)
    s.seq(bell, PLUMA_MAJ[:8], 3, 0.8)
    s.chord(choir, [62, 66, 69, 74], 10, 4, 1.0, vowel="a")
    s.add(timpani(mf(38), 1.0), 3); s.add(timpani(mf(38), 1.0), 10)
    return reverb(s.oneshot(), 0.35, 2.6)

def gameover():
    s = Song(60, 8, tail=3.0)
    s.seq(mbox, [(D5 + 12, 1), (A5, 1), (F5, 1), (D5, 1), (Bb4 - 12 + 12, 2), (A4 - 12, 4)], 0, 0.8)
    s.add(drone(mf(37), 8), 0, 0.7)
    return reverb(tape(s.oneshot(), 0.008, 0.25), 0.5, 3.5)

# ------------------------------------------------------------------ efectos y voces de diálogo
def voice(kind):
    if kind == "brenna":   y = chip(196, 0.06, 1.0, 0.5)
    elif kind == "carto":  t = T(0.07); y = np.sin(2 * np.pi * (330 + 40 * np.sin(2 * np.pi * 30 * t)) * t) * np.exp(-t * 20)
    elif kind == "ozias":  t = T(0.06); y = lp(osc_saw(150, t), 2500) * np.exp(-t * 25)
    elif kind == "ilse":   t = T(0.09); y = np.sin(2 * np.pi * 523 * t) * np.sin(np.pi * t / 0.09)
    elif kind == "nyx":    y = chip(784, 0.05, 1.0, 0.125)
    elif kind == "velaria": y = bell(659, 0.25, 1.0)[:int(0.25 * SR)]
    elif kind == "voz":
        t = T(0.12); y = np.tanh(6 * np.sin(2 * np.pi * 70 * t)) * 0.6 + hp(RNG.normal(0, 1, len(t)), 2000) * 0.25
        y = crush(y * np.exp(-t * 10), 4, 3)
    elif kind == "seravel": y = sum(choir(mf(m), 0.12)[:int(0.16 * SR)] for m in (69, 72, 76))
    elif kind == "carcelero": t = T(0.1); y = np.tanh(4 * osc_saw(65, t)) * np.exp(-t * 15)
    elif kind == "coro":   y = sum(choir(mf(m), 0.1, vowel="o")[:int(0.14 * SR)] for m in (64, 67, 70))
    else:                  y = chip(440, 0.045, 1.0, 0.25)
    return y

def sfx_all():
    for k in ("brenna", "carto", "ozias", "ilse", "nyx", "velaria", "voz", "seravel", "carcelero", "coro", "default"):
        save_sfx("voice_" + k, voice(k), 0.7)
    save_sfx("heartbeat", heartbeat(1.0), 0.95)
    # interfaz: tonos suaves y redondos (sin ataques bruscos)
    def soft_tone(fs, d=0.12, g=0.45):
        t = T(d); y = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * (18 + i * 6)) for i, f in enumerate(fs))
        y *= np.clip(t / 0.006, 0, 1)
        return lp(y, 2600) * g
    save_sfx("ui_move", soft_tone([880, 1320], 0.08), 0.35)
    save_sfx("ui_ok", np.concatenate([soft_tone([660, 990], 0.07), soft_tone([990, 1485], 0.14)]), 0.4)
    save_sfx("pickup", np.concatenate([soft_tone([784], 0.06), soft_tone([1046], 0.06), soft_tone([1568], 0.18)]), 0.45)
    save_sfx("quest", np.concatenate([soft_tone([523, 659], 0.12), soft_tone([659, 784], 0.12), soft_tone([784, 1046], 0.35)]), 0.5)
    t = T(0.6)   # pluma arrancada: desgarro de tela + campanilla
    tear = bp(RNG.normal(0, 1, len(t)), 1500, 6000) * np.exp(-t * 7) * (1 + 0.5 * np.sin(2 * np.pi * 60 * t))
    save_sfx("feather_tear", tear + np.pad(mbox(mf(86), 0.5), (int(0.05 * SR), 0))[:len(t)] * 0.6)
    t2 = T(1.6)  # la Sombra se alza: soplido inverso + golpe grave
    sw = (bp(RNG.normal(0, 1, len(t2)), 200, 2500) * np.linspace(0, 1, len(t2)) ** 3)
    save_sfx("shadow_rise", sw + np.pad(taiko(1.2), (int(1.3 * SR), 0))[:len(t2)] + drone(mf(37), 1.6)[:len(t2)] * 2)
    save_sfx("glitch", crush(RNG.normal(0, 1, int(0.18 * SR)) * np.sin(np.linspace(0, 40, int(0.18 * SR))), 3, 6), 0.6)
    t3 = T(0.35)
    save_sfx("shatter", sum(np.sin(2 * np.pi * f * t3) * np.exp(-t3 * (14 + i * 4)) for i, f in enumerate((2100, 2900, 3700, 4900))) + hp(RNG.normal(0, 1, len(t3)), 4000) * np.exp(-t3 * 30))
    save_sfx("spark", np.pad(mbox(mf(93), 0.3), (0, 0))[:int(0.4 * SR)], 0.5)
    for i, m in enumerate((84, 79, 74)):   # campanas del Atrio: 0 aguda, 1 media, 2 grave
        save_sfx("bell_%d" % i, reverb(np.pad(bell(mf(m), 2.4, 1.0), (0, int(0.6 * SR))), 0.35, 2.4), 0.7)
    t4 = T(1.2)  # evento del mundo: trueno lejano
    save_sfx("event", lp(RNG.normal(0, 1, len(t4)), 400) * np.exp(-t4 * 2.5) * (1 + np.sin(2 * np.pi * 7 * t4)))

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    print("Componiendo la banda sonora de SERAPHALL...")
    save_music("theme", theme())
    save_music("explore", explore())
    save_music("peace", peace())
    save_music("memory", memory())
    save_music("boss_carcelero", boss_carcelero())
    save_music("boss_choir", boss_choir())
    save_music("boss_seravel", boss_seravel(False))
    save_music("boss_seravel3", boss_seravel(True))
    save_music("boss1", boss_carcelero())
    save_music("boss2", boss_seravel(True))
    save_music("shadow", shadow())
    save_music("victory", victory(), loop=False)
    save_music("gameover", gameover(), loop=False)
    sfx_all()
    print("Listo.")

#!/usr/bin/env python3
"""Efectos de logro (estilo consola): campanitas brillantes y una fanfarria para los épicos.
Uso: python3 tools/gen_sfx_ach.py -> assets/audio/sfx_achieve*.wav"""
import os, wave
import numpy as np
from scipy.signal import lfilter, butter

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(5)

def t_arr(d):
    return np.arange(int(d * SR)) / SR

def note(n):
    return 440.0 * 2 ** (n / 12)

def lp(x, fc):
    b, a = butter(2, min(0.99, fc / (SR / 2)), "low")
    return lfilter(b, a, x)

def hp(x, fc):
    b, a = butter(2, min(0.99, fc / (SR / 2)), "high")
    return lfilter(b, a, x)

def reverb(x, mix=0.35, size=1.0):
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

def bell(f, dur, vel=1.0, bright=3.5):
    t = t_arr(dur)
    m = np.sin(2 * np.pi * f * bright * t) * 2.0 * np.exp(-t * 4)
    return np.sin(2 * np.pi * f * t + m) * np.exp(-t * 3.0) * vel

def glass(f, dur, vel=1.0):
    t = t_arr(dur)
    y = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.01 * t) + 0.2 * np.sin(2 * np.pi * f * 3.99 * t)
    return y * np.exp(-t * 5.0) * (1 - np.exp(-t * 400)) * vel

def saw(f, t):
    ph = f * t
    return 2 * (ph - np.floor(ph + 0.5))

def brass(f, dur, vel=1.0):
    t = t_arr(dur); n = len(t)
    a = np.minimum(1, t / 0.05); r = np.minimum(1, (dur - t) / 0.15)
    e = np.clip(a * r, 0, 1)
    y = saw(f, t) + saw(f * 1.004, t) + 0.5 * saw(f * 0.5, t)
    return lp(y * (0.3 + 0.7 * e), 900 + 2400 * vel) * e * vel * 0.3

def mix_at(buf, y, at):
    i = int(at * SR)
    end = min(len(buf), i + len(y))
    buf[i:end] += y[: end - i]

def norm(y, g=0.9):
    return y / (np.max(np.abs(y)) + 1e-9) * g

def save(name, y):
    y16 = (np.clip(y, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(y16.tobytes())

def shimmer(dur, vel=0.12):
    t = t_arr(dur)
    y = hp(rng.standard_normal(len(t)), 6000) * np.exp(-t * 3.5) * (1 - np.exp(-t * 30))
    return y * vel

def achieve():
    ## arpegio ascendente de cristal (Re mayor) + destello agudo, como un "¡ding!" de consola
    buf = np.zeros(int(2.2 * SR))
    for i, n in enumerate([5, 9, 12, 17]):
        mix_at(buf, glass(note(n + 12), 1.0, 0.55 + 0.1 * i), 0.07 * i)
    mix_at(buf, bell(note(29), 1.6, 0.5), 0.3)
    mix_at(buf, bell(note(24), 1.6, 0.35, 2.0), 0.3)
    mix_at(buf, shimmer(1.4), 0.25)
    return norm(reverb(buf, 0.35), 0.75)

def achieve_epic():
    ## fanfarria breve de metales + campanas y coro de cristal
    buf = np.zeros(int(3.4 * SR))
    for n, at, d in [(-7, 0.0, 0.16), (-7, 0.17, 0.12), (-2, 0.3, 0.2), (5, 0.5, 1.4)]:
        for iv in (0, 4, 7):
            mix_at(buf, brass(note(n + iv), d, 0.9), at)
    for i, n in enumerate([17, 21, 24, 29, 33]):
        mix_at(buf, glass(note(n), 1.3, 0.45), 0.5 + 0.06 * i)
    mix_at(buf, bell(note(5), 2.6, 0.6, 2.0), 0.5)
    mix_at(buf, bell(note(17), 2.4, 0.5), 0.5)
    mix_at(buf, shimmer(2.2, 0.16), 0.45)
    t = t_arr(0.6)
    boom = np.sin(2 * np.pi * (55 + 30 * np.exp(-t * 8)) * t) * np.exp(-t * 6) * 0.8
    mix_at(buf, boom, 0.5)
    return norm(reverb(buf, 0.4, 1.2), 0.8)

def progress():
    buf = np.zeros(int(0.9 * SR))
    mix_at(buf, glass(note(17), 0.6, 0.5), 0.0)
    mix_at(buf, glass(note(24), 0.6, 0.5), 0.06)
    return norm(reverb(buf, 0.3), 0.45)

if __name__ == "__main__":
    save("sfx_achieve", achieve())
    save("sfx_achieve_epic", achieve_epic())
    save("sfx_achieve_tick", progress())
    print("ok")

#!/usr/bin/env python3
"""SERAPHALL — música de los Estratos II, III y IV y de sus Arcontes.
Reutiliza los instrumentos y leitmotivs de gen_music.py (PLUMA, VOZ...).
Uso: python3 tools/gen_music_strata.py -> assets/audio/music_{forest,foundry,throne,boss_orrun,boss_vulkaris,boss_azrahel}.ogg"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import gen_music as M
from gen_music import Song, mf, drone, wind, bell, mbox, harp, choir, organ, strings, brass, bass, kick, taiko, snare, hat, chain, timpani, reverb, tape, PLUMA, PLUMA_MAJ, VOZ, save_music

# acordes
Em, C, G, D, Am, B = [52, 59, 64, 67], [48, 55, 60, 64], [43, 50, 55, 59], [50, 57, 62, 66], [45, 52, 57, 60], [47, 54, 59, 63]
Cm, Ab, Eb, Bb, Fm, Gm = [48, 55, 60, 63], [44, 51, 56, 60], [51, 58, 63, 67], [46, 53, 58, 62], [41, 48, 53, 56], [43, 50, 55, 58]
Bbm, Gb, Db, Ab2, Fm2 = [46, 53, 58, 61], [42, 49, 54, 58], [49, 56, 61, 65], [44, 51, 56, 60], [41, 48, 53, 56]


def shift(notes, k):
    return [(None if m is None else m + k, d) for m, d in notes]


def forest():
    """Bosque de Plumas Muertas: arpa en mi menor, viento entre ramas, pájaros (campanitas) y un coro lejano."""
    s = Song(70, 64)
    s.add(drone(mf(40), 64 * s.spb), 0, 0.8)
    s.add(wind(64 * s.spb, 0.55), 0)
    prog = [Em, C, G, D, Em, Am, C, B]
    for i, ch in enumerate(prog * 2):
        for k in range(8):
            m = ch[(k * 3) % 4] + (12 if k % 4 == 3 else 0)
            s.add(harp(mf(m), 0.5 * s.spb), i * 4 + k * 0.5, 0.42)
        s.chord(strings, ch, i * 4, 4, 0.22, att=1.0, bright=1200)
    s.seq(mbox, shift(PLUMA, -2), 16, 0.3, oct_=1)
    s.seq(choir, shift(PLUMA[:8], -2), 40, 0.35, oct_=-1, vowel="u")
    for b in (6, 13.5, 27, 38.5, 51, 60):
        s.add(bell(mf(88 + int(b) % 5), 0.25), b, 0.18)
        s.add(bell(mf(91 + int(b) % 3), 0.2), b + 0.25, 0.14)
    return reverb(s.loop(), 0.42, 3.4)


def foundry():
    """Fundición de Halos: yunques que marcan el compás, metales graves y un órgano que hierve en do menor."""
    s = Song(84, 64)
    s.add(drone(mf(36), 64 * s.spb), 0, 1.0)
    for i in range(32):
        s.add(chain(0.3), i * 2)
        s.add(kick(0.55), i * 2)
        if i % 2:
            s.add(taiko(0.5), i * 2 + 1)
        s.add(bell(mf(84 + (i % 3)), 0.12), i * 2 + 1.5, 0.12)
    for i, ch in enumerate([Cm, Ab, Eb, Bb, Cm, Fm, Ab, Gm] * 2):
        s.chord(organ, ch, i * 4, 4, 0.26)
        s.add(bass(mf(ch[0] - 12), 3.8 * s.spb, 0.6), i * 4, 0.7)
    s.seq(brass, shift(PLUMA[:8], -2), 16, 0.45, oct_=-1)
    s.seq(brass, shift(VOZ, 10), 48, 0.5)
    return reverb(s.loop(), 0.32, 2.6)


def throne():
    """El Trono Vacío: corte solemne en si bemol menor; coro, órgano y campanas reales, con la VOZ escondida."""
    s = Song(62, 64)
    s.add(drone(mf(34), 64 * s.spb), 0, 1.0)
    for i, ch in enumerate([Bbm, Gb, Db, Ab2, Bbm, Fm2, Gb, Ab2] * 2):
        s.chord(choir, ch[1:], i * 4, 4, 0.38, vowel="a")
        s.chord(organ, ch, i * 4, 4, 0.18)
        s.add(timpani(mf(ch[0]), 0.4), i * 4)
    s.seq(bell, shift(PLUMA, -4), 8, 0.4)
    s.seq(mbox, shift(PLUMA_MAJ, -4), 40, 0.25, oct_=1)
    s.seq(bass, shift(VOZ, 8), 24, 0.5)
    s.seq(bass, shift(VOZ, 8), 56, 0.5)
    s.add(wind(64 * s.spb, 0.2), 0)
    return reverb(s.loop(), 0.5, 3.8)


def boss_orrun():
    """Orrun: galope de timbales, cuerdas furiosas en mi menor y la PLUMA en metales cuando embiste."""
    s = Song(148, 64)
    for i in range(64):
        s.add(kick(0.8 if i % 2 == 0 else 0.4), i)
        s.add(taiko(0.55), i + 0.5) if i % 4 == 3 else None
        s.add(hat(0.25), i + 0.5)
    for i, ch in enumerate([Em, C, D, B] * 4):
        s.chord(strings, ch, i * 4, 4, 0.55, att=0.05, bright=3200)
        s.add(bass(mf(ch[0] - 12), 3.9 * s.spb, 0.8), i * 4, 0.9)
    s.seq(brass, shift(PLUMA, -2), 16, 0.6)
    s.seq(brass, shift(PLUMA, -2), 48, 0.6, oct_=1)
    s.seq(choir, shift(PLUMA[:8], -2), 32, 0.5, oct_=-1)
    return reverb(s.loop(), 0.22, 2.0)


def boss_vulkaris():
    """Vulkaris: martillo y yunque en cada tiempo fuerte, metales graves y el órgano en do menor al rojo."""
    s = Song(126, 64)
    for i in range(64):
        s.add(kick(0.85), i) if i % 2 == 0 else s.add(snare(0.5), i)
        s.add(chain(0.35), i + 0.5)
        if i % 4 == 0:
            s.add(bell(mf(72), 0.2), i, 0.35)
    for i, ch in enumerate([Cm, Ab, Bb, Gm] * 4):
        s.chord(organ, ch, i * 4, 4, 0.35)
        s.chord(brass, ch[1:], i * 4, 2, 0.4)
        s.add(bass(mf(ch[0] - 12), 3.8 * s.spb, 1.0), i * 4, 0.9)
    s.seq(brass, shift(VOZ, 12), 16, 0.6)
    s.seq(choir, shift(PLUMA, -2), 32, 0.45, oct_=-1, vowel="a")
    return reverb(s.loop(), 0.25, 2.2)


def boss_azrahel():
    """Azrahel: el último combate. Coro completo, órgano, timbales y la PLUMA y la VOZ enfrentadas."""
    s = Song(136, 64)
    for i in range(64):
        s.add(kick(0.9 if i % 2 == 0 else 0.5), i)
        if i % 2:
            s.add(snare(0.45), i)
        s.add(hat(0.2), i + 0.5)
        if i % 8 == 0:
            s.add(timpani(mf(46), 0.9), i)
    for i, ch in enumerate([Bbm, Gb, Ab2, Fm2, Bbm, Gb, Db, Ab2] * 2):
        s.chord(choir, ch[1:], i * 4, 4, 0.5, vowel="a")
        s.chord(organ, ch, i * 4, 4, 0.28)
        s.add(bass(mf(ch[0] - 12), 3.9 * s.spb, 1.0), i * 4, 0.9)
    s.seq(brass, shift(PLUMA, -4), 8, 0.55)
    s.seq(brass, shift(VOZ, 20), 28, 0.6)
    s.seq(strings, shift(PLUMA, -4), 40, 0.5, oct_=1)
    s.seq(bell, shift(PLUMA_MAJ, -4), 56, 0.35, oct_=1)
    return reverb(s.loop(), 0.3, 2.6)


if __name__ == "__main__":
    os.makedirs(M.OUT, exist_ok=True)
    for name, fn in [("forest", forest), ("foundry", foundry), ("throne", throne), ("boss_orrun", boss_orrun),
            ("boss_vulkaris", boss_vulkaris), ("boss_azrahel", boss_azrahel)]:
        save_music(name, fn())
    print("ok")

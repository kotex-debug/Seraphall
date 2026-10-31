#!/usr/bin/env python3
"""SERAPHALL v0.6 - arte detallado: PNJ y enemigos a escala del protagonista (32 px), objetos con detalle,
baldosas con relieve e iconos nuevos. Se ejecuta DESPUÉS de gen_art.py (sobrescribe esos archivos).
Uso: python3 tools/gen_art.py && python3 tools/gen_art2.py"""
import math, os, random, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import gen_looks as GL

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
INK = (18, 14, 24, 255)
R = random.Random(11)

def C(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def sh(c, f):
    return (max(0, min(255, int(c[0] * f))), max(0, min(255, int(c[1] * f))), max(0, min(255, int(c[2] * f))), c[3] if len(c) > 3 else 255)

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def outline(img, col=INK, skip=None):
    a = np.array(img); alpha = a[:, :, 3] > 0
    if skip is not None:
        alpha &= ~skip
    pad = np.pad(alpha, 1)
    n = pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:]
    edge = n & ~(a[:, :, 3] > 0)
    a[edge] = col
    return Image.fromarray(a)

def strip(frames):
    w, h = frames[0].size; s = canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.paste(f, (i * w, 0), f)
    return s

def sheet(rows):
    w, h = rows[0][0].size; m = max(len(r) for r in rows); s = canvas(w * m, h * len(rows))
    for j, r in enumerate(rows):
        for i, f in enumerate(r):
            s.paste(f, (i * w, j * h), f)
    return s

def colorize(idx, pal, lost=()):
    """Convierte una hoja indexada de gen_looks en color (como hace look.gd en el juego)."""
    src = np.array(idx.convert("RGBA")); out = np.zeros_like(src)
    part = np.round(src[:, :, 0] / 12.0).astype(int); f = src[:, :, 1] / 128.0
    m = (src[:, :, 3] > 0) & (src[:, :, 2] == 1)
    for p, col in pal.items():
        sel = m & (part == p)
        if p in lost or col is None:
            continue
        for ch in range(3):
            out[:, :, ch][sel] = np.clip(col[ch] * f[sel], 0, 255)
        out[:, :, 3][sel] = 255
    other = (src[:, :, 3] > 0) & (src[:, :, 2] != 1)
    out[other] = src[other]
    return Image.fromarray(out.astype(np.uint8))

def look_pal(skin, hair, eye, armor, legs, accent, cloak, wing, halo):
    pal = {1: skin, 2: hair, 3: eye, 4: armor, 5: legs, 6: accent, 7: cloak, 8: wing, 9: halo, 20: sh(skin, 0.55), 21: (245, 245, 255, 255), 22: sh(skin, 0.9)}
    for i in range(10, 20):
        pal[i] = wing
    return pal

# ================================================================== PNJ (32x32, 4 fotogramas)
def npc(body, hair, pal, extra, wings=False, halo=False, lost=()):
    frames = []
    for i in range(4):
        pose = {"bob": [0, 0, 1, 1][i], "flap": [0, 1, 1, 0][i], "cloak": [0, 1, 1, 0][i], "wings": wings, "halo": halo}
        img = colorize(GL.hero(body, hair, pose), pal, lost)
        d = ImageDraw.Draw(img)
        extra(d, img, i, pose["bob"])
        frames.append(outline(img))
    return strip(frames)

def ex_brenna(d, img, i, b):
    # martillo de forja (golpea el yunque imaginario) + hollín
    up = [0, -2, -3, -1][i]
    hx, hy = 21, 23 + b
    d.line([(hx, hy), (hx + 2, hy + 4 + up)], fill=C("6a4a2a"), width=1)
    d.rectangle([hx, hy + 4 + up, hx + 5, hy + 6 + up], fill=C("5a5a66")); d.line([(hx, hy + 4 + up), (hx + 5, hy + 4 + up)], fill=C("9a9aa8"))
    d.point((15, 9 + b), fill=C("3a2a2a")); d.point((19, 11 + b), fill=C("3a2a2a"))
    d.rectangle([13, 17 + b, 18, 22 + b], fill=C("8a5a30")); d.line([(13, 17 + b), (18, 17 + b)], fill=C("a87a40"))  # delantal
    if i == 2:
        d.point((hx + 6, hy + 2), fill=C("ffb040")); d.point((hx + 7, hy), fill=C("ffd080"))

def ex_carto(d, img, i, b):
    d.rectangle([16, 9 + b, 21, 9 + b], fill=C("e8e0d0"))                      # venda
    d.point((15, 10 + b), fill=C("c8c0b0"))
    d.polygon([(17, 12 + b), (21, 12 + b), (20, 16 + b), (18, 16 + b)], fill=C("d8d8e0"))  # barba
    d.rectangle([9, 18 + b, 13, 20 + b], fill=C("d8c8a0")); d.line([(9, 18 + b), (9, 20 + b)], fill=C("a89870"))  # mapas
    d.point((11 + (i % 2), 19 + b), fill=C("6a5a40"))

def ex_ozias(d, img, i, b):
    hood = C("1e5a6a")
    d.polygon([(12, 4 + b), (18, 2 + b), (22, 6 + b), (22, 10 + b), (20, 9 + b), (16, 7 + b), (14, 12 + b), (11, 14 + b)], fill=hood)
    d.line([(14, 4 + b), (19, 3 + b)], fill=sh(hood, 1.4))
    d.point((18, 10 + b), fill=C("60f0ff")); d.point((19, 10 + b), fill=C("c0ffff"))  # ojos que brillan
    for k in range(3):
        d.point((14 + k * 2, 18 + b + (k + i) % 2), fill=C("40e0ff"))               # runas
    d.line([(22, 21 + b), (25, 18 + b)], fill=C("a0a8b0")); d.point((25, 17 + b), fill=C("80ffff"))  # cincel

def ex_ilse(d, img, i, b):
    veil = C("1e1e48"); white = C("eeeaf2")
    d.polygon([(12, 4 + b), (19, 3 + b), (21, 6 + b), (14, 6 + b), (13, 20 + b), (10, 22 + b)], fill=veil)
    d.line([(14, 5 + b), (20, 5 + b)], fill=white); d.line([(14, 6 + b), (14, 13 + b)], fill=white)
    d.line([(15, 13 + b), (20, 13 + b)], fill=white)
    d.point((16, 19 + b), fill=C("80c0ff")); d.point((16, 20 + b), fill=C("c0e8ff"))   # lágrima colgante
    if i % 2:
        d.point((19, 11 + b), fill=C("a0d8ff"))                                          # una lágrima cae

def ex_nyx(d, img, i, b):
    d.polygon([(18, 8 + b), (25, 11 + b), (18, 12 + b)], fill=C("e8dcc8"))           # pico de la máscara
    d.line([(18, 12 + b), (24, 11 + b)], fill=C("a89880"))
    d.point((18, 9 + b), fill=C("ffd040"))                                             # ojo dorado
    d.polygon([(12, 4 + b), (19, 3 + b), (21, 6 + b), (13, 8 + b)], fill=C("120c18"))  # capucha de plumas
    lx, ly = 23, 21 + b + (1 if i in (1, 2) else 0)
    d.line([(21, 20 + b), (lx, ly - 2)], fill=C("5a4a30"))
    d.rectangle([lx - 1, ly - 1, lx + 1, ly + 2], fill=C("ffd060")); d.point((lx, ly), fill=C("fff8c0"))  # farol

def ex_velaria(d, img, i, b):
    hood = C("8a1828")
    d.polygon([(12, 5 + b), (17, 2 + b), (21, 5 + b), (22, 9 + b), (19, 7 + b), (14, 8 + b), (13, 14 + b), (11, 16 + b)], fill=hood)
    d.line([(13, 6 + b), (20, 4 + b)], fill=C("e0b040"))
    sw = [0, 2, 3, 1][i]
    cx, cy = 23 + sw, 25 + b
    d.line([(21, 19 + b), (cx, cy - 3)], fill=C("c8a040"))
    d.ellipse([cx - 2, cy - 3, cx + 2, cy + 1], fill=C("a07a30")); d.point((cx, cy - 1), fill=C("ff6040"))  # incensario
    for k in range(2):
        d.point((cx + k - sw // 2, cy - 5 - k * 2 - i % 2), fill=(200, 190, 210, 160))

NPCS = {
    "brenna": ("f", 2, look_pal(C("d8a882"), C("c0522a"), C("ffa040"), C("6a4a38"), C("3a2c28"), C("ffa040"), C("4a3a30"), C("8a8070"), C("ffffff")), ex_brenna, False, False),
    "carto": ("m", 2, look_pal(C("b8b0a8"), C("d8d8d8"), C("d8d8f0"), C("38405a"), C("282a38"), C("90a0ff"), C("2a3050"), C("707a90"), C("ffffff")), ex_carto, True, False),
    "ozias": ("m", 0, look_pal(C("8a7060"), C("1e5a6a"), C("60f0ff"), C("2a3a44"), C("1a242c"), C("40e0ff"), C("1e3a48"), C("506070"), C("ffffff")), ex_ozias, False, False),
    "ilse": ("f", 2, look_pal(C("f0d8c8"), C("1e1e48"), C("6a8ad8"), C("2a2a5a"), C("1a1a38"), C("c8d0e0"), C("1a1a40"), C("d8d8f0"), C("d8e0ff")), ex_ilse, False, True),
    "nyx": ("f", 0, look_pal(C("c8a888"), C("120c18"), C("ffd040"), C("1a141e"), C("0e0a12"), C("d8a040"), C("0e0a12"), C("1a1420"), C("ffffff")), ex_nyx, True, False),
    "velaria": ("f", 0, look_pal(C("e8c8b0"), C("8a1828"), C("ff6070"), C("8a1828"), C("3a0a14"), C("e0b040"), C("5a0a18"), C("ffffff"), C("ff4a5a")), ex_velaria, False, True),
}
for name, (body, hair, pal, ex, wings, halo) in NPCS.items():
    lost = (14, 19, 13, 18, 12, 17) if name == "carto" else ()
    npc(body, hair, pal, ex, wings, halo, lost).save(f"{OUT}/npc_{name}.png")

# ================================================================== enemigos
def husk_rows():
    """Hueco: ángel vaciado. Gris ceniza, alas desplumadas, ojos rojos, grietas y una espada oxidada."""
    pal = look_pal(C("8a8490"), C("4a4450"), C("ff3040"), C("5a5464"), C("3a3440"), C("6a3a3a"), C("3a2a30"), C("6a6470"), C("000000"))
    lost = (14, 19, 13, 18, 12, 17, 11)
    def frame(pose, extra_i):
        pose = dict(pose); pose["halo"] = False
        img = colorize(GL.hero("m", 1, pose), pal, lost)
        d = ImageDraw.Draw(img); b = pose.get("bob", 0)
        d.point((18, 9 + b), fill=C("ff2030")); d.point((19, 9 + b), fill=C("ff8080"))
        d.line([(15, 6 + b), (14, 10 + b)], fill=C("2a2430")); d.point((17, 18 + b), fill=C("2a2430"))  # grietas
        d.line([(12, 22), (11, 26 + extra_i % 2)], fill=C("4a3a3a"))                                      # jirones
        if pose.get("arm", 0) == 0:
            d.line([(22, 22 + b), (25, 27 + b)], fill=C("8a6a50")); d.point((25, 28 + b), fill=C("6a4a3a"))  # espada rota
        return outline(img)
    idle = [frame({"bob": [0, 0, 1, 1][i], "flap": [0, 1, 1, 0][i]}, i) for i in range(4)]
    cyc = [(-2, 2), (-1, 1), (1, -1), (2, -2)]
    walk = [frame({"l": cyc[i][0], "r": cyc[i][1], "bob": i % 2, "swing": [1, 0, -1, 0][i]}, i) for i in range(4)]
    atk = [frame({"arm": a, "l": l, "r": -l}, k) for k, (a, l) in enumerate(((1, -1), (2, 2), (2, 1)))]
    dead = frame({"bob": 1}, 0).rotate(90, expand=False, resample=Image.NEAREST)
    return [idle, walk, atk, [dead, dead]]
sheet(husk_rows()).save(f"{OUT}/enemy_hueco.png")

def acolyte_rows():
    """Acólito: túnica larga morada, mitra alta, bastón con vela."""
    pal = look_pal(C("c8b0a0"), C("2a1a3a"), C("d080ff"), C("4a2a6a"), C("2a1a3a"), C("d8b050"), C("3a1a5a"), C("6a5a7a"), C("000000"))
    def frame(pose, k):
        pose = dict(pose); pose["halo"] = False; pose["wings"] = False
        img = colorize(GL.hero("m", 0, pose), pal)
        d = ImageDraw.Draw(img); b = pose.get("bob", 0)
        d.polygon([(11, 20 + b), (21, 20 + b), (23, 30), (9, 30)], fill=C("4a2a6a"))                      # túnica larga
        d.line([(16, 21 + b), (16, 29)], fill=C("d8b050")); d.line([(10, 29), (22, 29)], fill=C("d8b050"))
        for x in range(11, 22, 3):
            d.line([(x, 23 + b), (x - 1, 29)], fill=C("3a1a5a"))
        d.polygon([(13, 5 + b), (16, -1 + b + 2), (20, 5 + b)], fill=C("e8d8a0")); d.line([(16, 2 + b), (16, 5 + b)], fill=C("c83040"))  # mitra
        d.rectangle([13, 5 + b, 20, 6 + b], fill=C("c8b080"))
        sx = 23 if pose.get("arm", 0) == 0 else 21
        d.line([(sx, 12 + b), (sx, 29)], fill=C("6a4a2a"))                                                 # bastón
        d.rectangle([sx - 1, 9 + b, sx + 1, 11 + b], fill=C("f0e8d0"))
        fl = (k % 2)
        d.point((sx, 8 + b - fl), fill=C("ffd060")); d.point((sx, 7 + b - fl), fill=C("fff0b0"))
        if pose.get("arm", 0) == 2:
            for q in range(3):
                d.point((sx + 2 + q, 8 + b - q), fill=C("d080ff"))
        return outline(img)
    idle = [frame({"bob": [0, 0, 1, 1][i]}, i) for i in range(4)]
    atk = [frame({"arm": a}, k) for k, a in enumerate((1, 2, 2))]
    dead = frame({"bob": 1}, 0).rotate(90, expand=False, resample=Image.NEAREST)
    return [idle, atk, [dead, dead]]
sheet(acolyte_rows()).save(f"{OUT}/enemy_acolito.png")

def beast(pose):
    """Bestia de ceniza: sabueso con espinazo de plumas quemadas y brasas en los ojos (38x28)."""
    W, H = 38, 28
    img = canvas(W, H); d = ImageDraw.Draw(img)
    fur, fur_d, fur_l, ember = C("4a3a3a"), C("2e2226"), C("6a5654"), C("ff6a20")
    bob = pose.get("bob", 0); lg = pose.get("legs", 0); lunge = pose.get("lunge", 0)
    bx = 8 + lunge; by = 12 + bob
    # cola
    d.line([(bx - 2, by + 2), (bx - 6, by - 2 + bob), (bx - 7, by - 5)], fill=fur_d, width=2)
    d.point((bx - 7, by - 6), fill=ember)
    # patas traseras y delanteras (alternadas al correr)
    for k, (px, ph) in enumerate(((bx + 2, lg), (bx + 5, -lg), (bx + 16, -lg), (bx + 19, lg))):
        d.line([(px, by + 6), (px + ph // 2, by + 11), (px + ph, by + 14)], fill=fur_d if k % 2 else fur, width=2)
        d.point((px + ph + 1, by + 14), fill=C("1a1416"))
    # cuerpo
    d.ellipse([bx - 2, by - 2, bx + 20, by + 9], fill=fur)
    d.ellipse([bx, by + 3, bx + 18, by + 9], fill=fur_d)
    d.line([(bx + 1, by - 1), (bx + 16, by - 2)], fill=fur_l)
    for k in range(6):                                                                   # espinazo de plumas quemadas
        x = bx + 2 + k * 3
        d.polygon([(x, by - 1), (x + 2, by - 6 - (k % 2) - bob), (x + 3, by - 1)], fill=C("2a1e22"))
        d.point((x + 2, by - 5 - (k % 2) - bob), fill=ember if k % 2 else C("ffb060"))
    # cabeza
    hx, hy = bx + 18 + lunge // 2, by - 4
    d.ellipse([hx, hy, hx + 10, hy + 8], fill=fur)
    d.polygon([(hx + 7, hy + 3), (hx + 14, hy + 4), (hx + 13, hy + 7), (hx + 7, hy + 7)], fill=fur_l)   # hocico
    d.polygon([(hx + 1, hy + 1), (hx + 2, hy - 4), (hx + 5, hy + 1)], fill=fur_d)                      # oreja
    d.point((hx + 7, hy + 2), fill=ember); d.point((hx + 8, hy + 2), fill=C("fff0a0"))
    if pose.get("bite"):
        d.line([(hx + 9, hy + 7), (hx + 14, hy + 9)], fill=C("1a0e10"), width=2)
        d.point((hx + 11, hy + 8), fill=C("f0e0d0")); d.point((hx + 13, hy + 8), fill=C("f0e0d0"))
    # brasas que se desprenden
    if pose.get("spark", 0):
        d.point((bx + 6, by - 9), fill=ember)
    return outline(img)
rows = [[beast({"bob": [0, 0, 1, 1][i], "spark": i % 2}) for i in range(4)],
        [beast({"legs": [-2, 0, 2, 0][i], "bob": i % 2}) for i in range(4)],
        [beast({"lunge": 0, "bob": 1}), beast({"lunge": 4, "bite": True})],
        [beast({"bob": 2}).transpose(Image.FLIP_TOP_BOTTOM)] * 2]
sheet(rows).save(f"{OUT}/enemy_bestia.png")

# ================================================================== objetos con detalle
def chest(open_=False):
    img = canvas(20, 18); d = ImageDraw.Draw(img)
    wood, wood_d, gold = C("6a3e22"), C("452616"), C("e0b040")
    d.rectangle([2, 8, 17, 16], fill=wood); d.rectangle([2, 14, 17, 16], fill=wood_d)
    for x in (6, 10, 14):
        d.line([(x, 9), (x, 15)], fill=wood_d)
    d.rectangle([2, 8, 17, 8], fill=gold); d.rectangle([1, 16, 18, 16], fill=gold)
    d.line([(2, 8), (2, 16)], fill=gold); d.line([(17, 8), (17, 16)], fill=gold)
    if open_:
        d.polygon([(2, 8), (17, 8), (16, 2), (3, 2)], fill=wood_d); d.line([(3, 2), (16, 2)], fill=gold)
        d.rectangle([4, 7, 15, 8], fill=C("1a0e0a"))
        d.point((8, 6), fill=C("ffe080")); d.point((11, 5), fill=C("fff0c0"))
    else:
        d.polygon([(2, 8), (17, 8), (16, 4), (14, 2), (5, 2), (3, 4)], fill=wood)
        d.line([(5, 2), (14, 2)], fill=gold); d.line([(3, 5), (16, 5)], fill=C("8a5a30"))
        d.rectangle([8, 7, 11, 11], fill=gold); d.point((9, 9), fill=C("c83040")); d.point((10, 8), fill=C("ff8080"))
    return outline(img)
strip([chest(False), chest(True)]).save(f"{OUT}/chest.png")

def candles(i):
    img = canvas(12, 16); d = ImageDraw.Draw(img)
    wax, wax_d = C("ece2c8"), C("c8b898")
    for k, (x, h) in enumerate(((2, 9), (5, 12), (8, 7))):
        y0 = 15 - h
        d.rectangle([x, y0, x + 2, 15], fill=wax); d.line([(x + 2, y0), (x + 2, 15)], fill=wax_d)
        d.point((x, y0 + 2 + (k + i) % 3), fill=C("fff8e8"))                      # gota de cera
        fl = (i + k) % 4
        d.point((x + 1, y0 - 1), fill=C("ffb040")); d.point((x + 1, y0 - 2 - (fl % 2)), fill=C("fff0a0"))
        if fl == 2:
            d.point((x + 1 + (1 if k % 2 else -1), y0 - 3), fill=C("ff8030"))
    d.rectangle([1, 15, 11, 15], fill=wax_d)
    return outline(img)
strip([candles(i) for i in range(4)]).save(f"{OUT}/candle.png")

def statue():
    img = canvas(24, 36); d = ImageDraw.Draw(img)
    st, st_d, st_l = C("8a8494"), C("5a5464"), C("b0aabc")
    d.rectangle([4, 30, 19, 35], fill=st_d); d.line([(4, 30), (19, 30)], fill=st_l)            # pedestal
    d.polygon([(2, 12), (8, 8), (10, 22), (4, 26)], fill=st); d.polygon([(21, 12), (15, 8), (13, 22), (19, 26)], fill=st_d)  # alas
    for k in range(4):
        d.line([(3 + k, 14 + k * 3), (7, 12 + k * 3)], fill=st_d); d.line([(20 - k, 14 + k * 3), (16, 12 + k * 3)], fill=sh(st_d, 0.8))
    d.polygon([(8, 14), (15, 14), (16, 30), (7, 30)], fill=st)                                  # túnica
    for x in (9, 11, 13):
        d.line([(x, 16), (x - 1, 29)], fill=st_d)
    d.ellipse([8, 5, 15, 13], fill=st); d.line([(9, 7), (12, 6)], fill=st_l)                   # cabeza inclinada
    d.rectangle([10, 15, 13, 18], fill=st_l)                                                    # manos rezando
    d.arc([7, 1, 16, 5], 180, 360, fill=C("c8b060"))                                            # aureola dorada gastada
    d.line([(12, 9), (13, 12)], fill=C("4a3a4a"))                                               # grieta / lágrima
    d.point((5, 33), fill=C("4a6a4a")); d.point((17, 32), fill=C("4a6a4a"))                     # musgo
    return outline(img)
statue().save(f"{OUT}/statue.png")

def pillar(broken=False):
    img = canvas(18, 40); d = ImageDraw.Draw(img)
    st, st_d, st_l = C("6e6878"), C("4a4454"), C("9a94a6")
    top = 14 if broken else 4
    d.rectangle([4, top, 13, 35], fill=st)
    for x in (6, 9, 12):
        d.line([(x, top + 1), (x, 34)], fill=st_d)                                              # estrías
    d.line([(4, top), (4, 35)], fill=st_l)
    d.rectangle([2, 35, 15, 39], fill=st_d); d.line([(2, 35), (15, 35)], fill=st_l)            # basa
    if broken:
        d.polygon([(4, top), (7, top - 3), (10, top + 1), (13, top - 2), (13, top + 2), (4, top + 2)], fill=st)
        d.point((15, 37), fill=st); d.point((1, 38), fill=st_d)
    else:
        d.rectangle([2, 1, 15, 4], fill=st_l); d.rectangle([3, 4, 14, 5], fill=st_d)          # capitel
        d.point((3, 2), fill=C("c8b060")); d.point((14, 2), fill=C("c8b060"))
    d.line([(8, 20), (10, 24), (9, 27)], fill=C("2e2836"))                                     # grieta
    d.point((5, 30), fill=C("4a6a4a")); d.point((12, 28), fill=C("4a6a4a"))
    return outline(img)
strip([pillar(False), pillar(True)]).save(f"{OUT}/pillar.png")

def rubble(seed):
    rr = random.Random(seed); img = canvas(16, 10); d = ImageDraw.Draw(img)
    for k in range(4 + seed):
        x, y, s = rr.randint(1, 12), rr.randint(3, 8), rr.randint(2, 4)
        c = C("6a6474") if k % 2 else C("54505e")
        d.polygon([(x, y + s // 2), (x + s // 2, y - s // 2), (x + s, y), (x + s - 1, y + s // 2)], fill=c)
        d.point((x + 1, y - s // 2 + 1), fill=C("8a8494"))
    d.point((rr.randint(2, 13), 8), fill=C("4a6a4a"))
    return outline(img)
strip([rubble(i) for i in range(3)]).save(f"{OUT}/rubble.png")

def bones(i):
    img = canvas(16, 10); d = ImageDraw.Draw(img); bone, bone_d = C("e0d8c8"), C("a89c88")
    if i == 0:                                                                                  # calavera
        d.ellipse([4, 1, 11, 8], fill=bone); d.rectangle([5, 7, 10, 9], fill=bone_d)
        d.point((6, 4), fill=INK); d.point((9, 4), fill=INK); d.point((7, 6), fill=bone_d)
    elif i == 1:                                                                                # costillas
        for k in range(4):
            d.arc([2 + k * 3, 2, 6 + k * 3, 9], 180, 360, fill=bone)
        d.line([(2, 6), (14, 6)], fill=bone_d)
    else:                                                                                       # ala de hueso
        d.line([(2, 8), (13, 2)], fill=bone)
        for k in range(4):
            d.line([(4 + k * 3, 7 - k), (6 + k * 3, 9 - k)], fill=bone_d)
    return outline(img)
strip([bones(i) for i in range(3)]).save(f"{OUT}/bones.png")

# ================================================================== baldosas con relieve
T = 16
def noise_tile(base, seed, amp=5):
    rr = random.Random(seed); a = np.zeros((T, T, 4), dtype=np.int32)
    for y in range(T):
        for x in range(T):
            n = rr.randint(-amp, amp)
            a[y, x, :3] = np.array(base[:3]) + n; a[y, x, 3] = 255
    return a

def slab(a, x0, y0, x1, y1, light=16, dark=-18):
    a[y0, x0:x1 + 1, :3] += light; a[y0:y1 + 1, x0, :3] += light // 2
    a[y1, x0:x1 + 1, :3] += dark; a[y0:y1 + 1, x1, :3] += dark // 2

def floor(seed, tint=(1, 1, 1), layout=0, deco=None):
    rr = random.Random(seed * 7 + layout)
    base = (np.array([56, 50, 62]) * np.array(tint)).astype(int)
    a = noise_tile(base, seed)
    rects = [[(0, 0, 15, 15)], [(0, 0, 7, 7), (8, 0, 15, 7), (0, 8, 15, 15)], [(0, 0, 9, 15), (10, 0, 15, 15)], [(0, 0, 15, 5), (0, 6, 7, 15), (8, 6, 15, 15)]][layout % 4]
    for (x0, y0, x1, y1) in rects:
        slab(a, x0, y0, x1, y1)
        a[y1, x0:x1 + 1, :3] = (base * 0.6).astype(int); a[y0:y1 + 1, x1, :3] = (base * 0.62).astype(int)  # juntas
    if seed % 3 == 0:                                                                           # grieta
        x, y = rr.randint(3, 11), rr.randint(2, 6)
        for k in range(rr.randint(4, 8)):
            a[y, x, :3] = (base * 0.5).astype(int)
            if k % 2:
                a[y, min(15, x + 1), :3] = (base * 0.75).astype(int)
            x = max(1, min(14, x + rr.choice([-1, 0, 1]))); y = min(14, y + 1)
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(img)
    if deco == "ash":
        for k in range(6):
            d.point((rr.randint(1, 14), rr.randint(1, 14)), fill=C("8a7a70") if k % 3 else C("a89888"))
        if seed % 2:
            d.point((rr.randint(2, 13), rr.randint(2, 13)), fill=C("ff7030"));
    elif deco == "moss":
        for k in range(5):
            x, y = rr.randint(1, 14), rr.randint(1, 14)
            d.point((x, y), fill=C("4a6a48")); d.point((x + 1, y), fill=C("5a7a52"))
        if seed % 2:
            d.point((rr.randint(2, 13), rr.randint(2, 13)), fill=C("e0d8f0"))                 # florecilla
    elif deco == "water":
        for k in range(3):
            y = rr.randint(3, 12); x = rr.randint(1, 9)
            d.line([(x, y), (x + rr.randint(2, 5), y)], fill=C("6a7aa8"))
    elif deco == "dirt":
        for k in range(5):
            d.point((rr.randint(1, 14), rr.randint(1, 14)), fill=C("7a6040"))
        d.line([(rr.randint(1, 8), rr.randint(2, 13)), (rr.randint(8, 14), rr.randint(2, 13))], fill=C("a08a50"))  # paja
    if seed % 5 == 1:                                                                           # runa tenue grabada
        cx, cy = rr.randint(4, 11), rr.randint(4, 11)
        for p in ((0, -2), (0, -1), (0, 0), (-1, 1), (1, 1), (0, 2)):
            d.point((cx + p[0], cy + p[1]), fill=tuple(int(v * 0.72) for v in base[:3]) + (255,))
    return img

def wall_face(seed):
    rr = random.Random(seed); img = canvas(T, T); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=C("3e3848"))
    for row, y in enumerate((0, 4, 8, 12)):
        off = 0 if row % 2 == 0 else 4
        for x in range(-off, 16, 8):
            c = sh(C("4e465a"), 1 + rr.uniform(-0.1, 0.08))
            d.rectangle([x, y, x + 7, y + 3], fill=c)
            d.line([(x, y), (x + 6, y)], fill=sh(c, 1.22)); d.line([(x + 7, y), (x + 7, y + 3)], fill=sh(c, 0.7))
            d.line([(x, y + 3), (x + 7, y + 3)], fill=C("2a2434"))
    if seed % 3 == 0:
        d.line([(rr.randint(3, 12), 2), (rr.randint(3, 12), 9)], fill=C("2a2434"))            # grieta
    if seed % 2 == 1:
        for x in range(rr.randint(1, 5), 16, 5):
            d.point((x, 15), fill=C("4a6a48")); d.point((x, 14), fill=C("5a7a52"))           # musgo al pie
    d.rectangle([0, 0, 15, 0], fill=C("6a6278"))
    return img

def wall_top():
    rr = random.Random(5); a = np.zeros((T, T, 4), dtype=np.int32)
    for y in range(T):
        for x in range(T):
            v = 28 + rr.randint(-3, 3) + (4 if (x // 4 + y // 4) % 2 else 0)
            a[y, x] = (v, v - 3, v + 7, 255)
    a[T - 1, :, :3] = (52, 46, 60)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

def carpet():
    img = canvas(T, T); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=C("6a1828"))
    d.line([(0, 1), (15, 1)], fill=C("c8a050")); d.line([(0, 14), (15, 14)], fill=C("c8a050"))
    d.line([(0, 2), (15, 2)], fill=C("4a1020")); d.line([(0, 13), (15, 13)], fill=C("4a1020"))
    for x in range(0, 16, 8):                                                                  # motivo de plumas
        d.polygon([(x + 4, 4), (x + 6, 8), (x + 4, 11), (x + 2, 8)], fill=C("8a2a3a")); d.point((x + 4, 7), fill=C("c8a050"))
    return img

def grate():
    img = floor(4); d = ImageDraw.Draw(img)
    d.rectangle([2, 2, 13, 13], fill=C("120c16")); d.rectangle([2, 2, 13, 2], fill=C("2a2232"))
    for x in range(3, 13, 3):
        d.line([(x, 2), (x, 13)], fill=C("6a6472")); d.point((x, 3), fill=C("8a8494"))
    d.point((7, 10), fill=C("ff6020"))                                                         # brasa al fondo
    return img

def void():
    a = np.zeros((T, T, 4), dtype=np.uint8)
    for y in range(T):
        v = int(10 + 6 * math.sin(y * 0.6)); a[y, :, :] = (v, max(0, v - 4), v + 8, 255)
    return Image.fromarray(a)

def cliff(part, seed=0):
    rr = random.Random(seed * 13 + part); a = np.zeros((T, T, 4), dtype=np.int32)
    teeth = [rr.randint(3, 13) for _ in range(T)]
    for x in range(1, T):
        teeth[x] = (teeth[x] + teeth[x - 1]) // 2
    for y in range(T):
        for x in range(T):
            gy = y + part * T
            if part == 1 and y > teeth[x]:
                continue
            strata = (gy // 3 + (x // 5)) % 3
            v = 80 - gy * 1.7 + (10 if strata == 0 else (-7 if strata == 2 else 0)) + rr.randint(-3, 3)
            a[y, x] = (int(v * 0.92), int(v * 0.78), int(v * 1.12), 255)
    if part == 0:
        a[0, :, :3] = (156, 138, 166); a[1, :, :3] = (100, 88, 112)
        for x in range(0, T, 6):                                                               # raíces que cuelgan
            for y in range(2, 2 + rr.randint(4, 10)):
                a[y, (x + seed + y // 3) % T, :3] = (58, 44, 40)
    else:
        for x in range(T):
            ty = teeth[x]
            if 0 <= ty < T:
                a[ty, x, :3] = (30, 22, 36)
        a[rr.randint(2, 6), rr.randint(2, 13), :3] = (140, 110, 200)                            # cristal incrustado
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

tiles = [floor(0, layout=0), floor(1, layout=1), floor(2, layout=2), floor(3, layout=3), floor(20, (1.08, 1.0, 0.95), 1, "ash"), floor(21, (1.08, 1.0, 0.95), 2, "ash"),
         wall_top(), wall_face(0), wall_face(1), wall_face(3), carpet(), grate(), void(),
         floor(6, (0.88, 0.94, 1.18), 1, "water"), floor(7, (0.88, 0.94, 1.18), 3, "water"), floor(9, (1.12, 1.0, 0.85), 2, "dirt"),
         cliff(0, 1), cliff(1, 1), canvas(T, T), floor(12, (0.95, 1.1, 0.95), 0, "moss")]
strip(tiles).save(f"{OUT}/tiles.png")

# ================================================================== iconos nuevos (16x16)
def icon_eco():
    """Eco: moneda de alma con una pluma grabada y un brillo."""
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 14, 14], fill=C("2a7ab0")); d.ellipse([2, 2, 13, 13], fill=C("5ac8f0")); d.ellipse([4, 4, 11, 11], fill=C("3aa0d8"))
    d.arc([2, 2, 13, 13], 200, 290, fill=C("c8f4ff"))
    d.line([(6, 11), (9, 5)], fill=C("e8fbff")); d.point((9, 4), fill=C("ffffff")); d.point((7, 8), fill=C("bfefff")); d.point((8, 9), fill=C("bfefff"))
    d.point((11, 3), fill=C("ffffff")); d.point((12, 4), fill=C("ffffff"))
    return outline(img)

def icon_feather():
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    d.polygon([(3, 14), (11, 2), (14, 1), (13, 5), (6, 13)], fill=C("e8e4f0"))
    d.polygon([(4, 13), (11, 4), (12, 5), (6, 12)], fill=C("c8c0d8"))
    d.line([(2, 15), (13, 2)], fill=C("8a7aa0"))
    for k in range(4):
        d.point((6 + k * 2, 11 - k * 2), fill=C("ffffff"))
    d.point((14, 1), fill=C("ffe27a"))
    return outline(img)

def icon_vial(liq, liq_l, glow):
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    d.rectangle([6, 1, 9, 3], fill=C("8a5a30")); d.line([(6, 1), (9, 1)], fill=C("b08048"))   # corcho
    d.rectangle([6, 4, 9, 5], fill=C("c8d8e8"))                                                  # cuello
    d.ellipse([2, 5, 13, 15], fill=C("d8e8f8"))                                                  # vidrio
    d.ellipse([3, 7, 12, 14], fill=liq); d.rectangle([4, 7, 11, 9], fill=C("d8e8f8"))            # líquido
    d.line([(4, 10), (11, 10)], fill=liq_l)
    d.point((5, 7), fill=C("ffffff")); d.point((4, 8), fill=C("ffffff"))                       # reflejo
    d.point((10, 12), fill=glow); d.point((7, 13), fill=liq_l)
    return outline(img)

icon_eco().save(f"{OUT}/icon_eco.png")
icon_feather().save(f"{OUT}/icon_feather.png")
icon_vial(C("d82840"), C("ff7080"), C("ffc0c8")).save(f"{OUT}/icon_flask.png")
icon_vial(C("2a90e0"), C("70d0ff"), C("e0f8ff")).save(f"{OUT}/icon_vial_luz.png")
icon_vial(C("e0a020"), C("ffd860"), C("fff4c0")).save(f"{OUT}/icon_vial_aliento.png")
print("Arte v0.6 generado")

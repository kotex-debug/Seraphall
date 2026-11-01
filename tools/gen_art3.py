#!/usr/bin/env python3
"""SERAPHALL v0.7 - arte de las antesalas: el Custodio del Umbral (48x48), Tobías el preso,
campanas del Atrio, estela de inscripciones, puertas de celda y barrotes.
Uso: python3 tools/gen_art.py && python3 tools/gen_art2.py && python3 tools/gen_art3.py"""
import os, sys, math
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import gen_art2 as A2
import gen_looks as GL

OUT = A2.OUT
C, sh, canvas, outline, strip, sheet = A2.C, A2.sh, A2.canvas, A2.outline, A2.strip, A2.sheet

# ================================================================== El Custodio del Umbral (48x48)
MARBLE = C("d8d0c4"); MARBLE_M = C("a89e92"); MARBLE_D = C("6a6068"); GOLD = C("e8b848"); GOLD_L = C("fff0a0"); GOLD_D = C("9a6a20")
GLOW = C("ffe890")

def custodio(pose="idle", k=0):
    """Estatua-guardiana con yelmo cerrado, alas de piedra, tabardo y alabarda dorada."""
    img = canvas(48, 48); d = ImageDraw.Draw(img)
    bob = [0, 0, 1, 1][k % 4] if pose in ("idle", "walk") else 0
    cx = 22
    # alas de piedra plegadas detrás
    for side, base in ((-1, MARBLE_M), (1, MARBLE_D)):
        x0 = cx + side * 5
        pts = [(x0, 14 + bob), (x0 + side * 12, 4 + bob), (x0 + side * 17, 10 + bob), (x0 + side * 15, 26 + bob), (x0 + side * 9, 33 + bob), (x0 + side * 3, 28 + bob)]
        d.polygon(pts, fill=base)
        for i in range(4):
            fy = 10 + i * 5 + bob
            d.line([(x0 + side * (13 - i), fy), (x0 + side * (6 - i // 2), fy + 6)], fill=sh(base, 0.78))
        d.line([(x0 + side * 12, 4 + bob), (x0 + side * 17, 10 + bob)], fill=sh(base, 1.25))
    # piernas (grebas)
    stride = {"walk": [(-2, 2), (-1, 1), (2, -2), (1, -1)][k % 4]}.get(pose, (0, 0))
    for side, off in ((-1, stride[0]), (1, stride[1])):
        lx = cx + side * 3 + off
        d.rectangle([lx - 2, 34, lx + 2, 44], fill=MARBLE_M if side < 0 else MARBLE_D)
        d.line([(lx - 2, 34), (lx - 2, 44)], fill=MARBLE)
        d.rectangle([lx - 3, 44, lx + 3, 46], fill=MARBLE_D)
        d.point((lx, 38), fill=GOLD)
    # tabardo
    d.polygon([(cx - 7, 27 + bob), (cx + 7, 27 + bob), (cx + 9, 40), (cx - 9, 40)], fill=C("8a2a30"))
    d.line([(cx, 28 + bob), (cx, 39)], fill=GOLD)
    d.line([(cx - 9, 40), (cx + 9, 40)], fill=GOLD)
    for x in range(cx - 7, cx + 8, 3):
        d.line([(x, 30 + bob), (x - 1, 39)], fill=C("6a1a22"))
    # torso acorazado
    d.polygon([(cx - 8, 15 + bob), (cx + 8, 15 + bob), (cx + 7, 28 + bob), (cx - 7, 28 + bob)], fill=MARBLE)
    d.polygon([(cx + 2, 15 + bob), (cx + 8, 15 + bob), (cx + 7, 28 + bob), (cx + 2, 28 + bob)], fill=MARBLE_M)
    d.line([(cx - 4, 18 + bob), (cx + 4, 18 + bob)], fill=GOLD)
    d.polygon([(cx, 19 + bob), (cx + 2, 22 + bob), (cx, 25 + bob), (cx - 2, 22 + bob)], fill=GOLD)   # emblema
    d.point((cx, 22 + bob), fill=GOLD_L)
    for vx, vy in ((cx - 6, 20), (cx - 5, 24), (cx + 5, 17)):                                         # vetas doradas
        d.line([(vx, vy + bob), (vx + 2, vy + 2 + bob)], fill=GOLD_D)
    # hombreras
    for side in (-1, 1):
        px = cx + side * 9
        d.ellipse([px - 4, 13 + bob, px + 4, 19 + bob], fill=MARBLE if side < 0 else MARBLE_M)
        d.line([(px - 3, 14 + bob), (px + 3, 14 + bob)], fill=GOLD)
    # yelmo cerrado con cresta
    d.rectangle([cx - 5, 4 + bob, cx + 5, 14 + bob], fill=MARBLE)
    d.rectangle([cx + 2, 4 + bob, cx + 5, 14 + bob], fill=MARBLE_M)
    d.polygon([(cx - 5, 4 + bob), (cx, 1 + bob), (cx + 5, 4 + bob)], fill=MARBLE)
    d.line([(cx - 4, 9 + bob), (cx + 5, 9 + bob)], fill=C("2a2026"))                                  # visera
    glow = GLOW if pose != "attack" else C("ffffff")
    d.line([(cx - 3, 9 + bob), (cx + 4, 9 + bob)], fill=glow)
    d.line([(cx, 11 + bob), (cx, 13 + bob)], fill=C("2a2026"))
    d.line([(cx - 5, 14 + bob), (cx + 5, 14 + bob)], fill=GOLD)
    for i in range(6):                                                                                  # penacho
        d.line([(cx - 1 + i // 2, 1 + bob - i // 2), (cx - 6 - i, -1 + bob + i)], fill=C("c83040") if i % 2 else C("ff5060"))
    # alabarda
    if pose == "attack" and k == 0:        # en alto
        d.line([(cx + 10, 16), (cx + 22, 1)], fill=C("6a4a2a"), width=2)
        d.polygon([(cx + 20, 0), (cx + 27, -2), (cx + 25, 6), (cx + 22, 3)], fill=GOLD)
        d.line([(cx + 20, 0), (cx + 27, -2)], fill=GOLD_L)
        d.ellipse([cx + 8, 15, cx + 12, 19], fill=MARBLE)
    elif pose == "attack":                 # tajo horizontal
        d.line([(cx + 6, 22), (cx + 25, 24)], fill=C("6a4a2a"), width=2)
        d.polygon([(cx + 23, 18), (cx + 30, 22), (cx + 30, 28), (cx + 24, 27)], fill=GOLD)
        d.line([(cx + 30, 22), (cx + 30, 28)], fill=GOLD_L)
        if k == 1:
            for i in range(5):
                d.point((cx + 31 + i % 2, 19 + i * 2), fill=GOLD_L)
    else:
        hx = cx + 12
        d.line([(hx, 6 + bob), (hx, 46)], fill=C("6a4a2a"), width=2)
        d.line([(hx, 6 + bob), (hx, 46)], fill=C("8a6a3a"))
        d.polygon([(hx - 1, 1 + bob), (hx + 5, 3 + bob), (hx + 4, 10 + bob), (hx - 1, 8 + bob)], fill=GOLD)   # hoja
        d.line([(hx + 5, 3 + bob), (hx + 4, 10 + bob)], fill=GOLD_L)
        d.polygon([(hx - 1, 4 + bob), (hx - 4, 6 + bob), (hx - 1, 8 + bob)], fill=GOLD_D)                    # pico
        d.point((hx, 0 + bob), fill=GOLD_L)
        d.ellipse([hx - 2, 18 + bob, hx + 2, 22 + bob], fill=MARBLE)                                          # mano
    return outline(img)

def custodio_rows():
    idle = [custodio("idle", i) for i in range(4)]
    walk = [custodio("walk", i) for i in range(4)]
    atk = [custodio("attack", 0), custodio("attack", 1), custodio("attack", 2)]
    dead = custodio("idle", 1).rotate(90, expand=False, resample=Image.NEAREST)
    # al morir se agrieta
    dd = ImageDraw.Draw(dead)
    for x, y in ((14, 20), (24, 26), (30, 22)):
        dd.line([(x, y), (x + 3, y + 4)], fill=C("2a2026"))
    return [idle, walk, atk, [dead, dead]]

sheet(custodio_rows()).save(f"{OUT}/enemy_custodio.png")

# ================================================================== Tobías, el último preso
def ex_preso(d, img, i, b):
    # barba larga, harapos, grilletes con cadena y mirada hundida
    d.polygon([(17, 12 + b), (22, 12 + b), (21, 19 + b), (18, 18 + b)], fill=C("b8b0a8"))
    d.line([(18, 13 + b), (20, 17 + b)], fill=C("8a8278"))
    d.point((18, 10 + b), fill=C("1a1418")); d.point((19, 10 + b), fill=C("fff0d0"))
    for k in range(3):
        d.line([(12 + k * 3, 22 + b), (11 + k * 3, 27)], fill=C("3a3032"))                  # jirones
    d.rectangle([20, 22 + b, 23, 23 + b], fill=C("5a5a62")); d.point((21, 22 + b), fill=C("9a9aa8"))  # grillete
    for k in range(4):
        d.point((22 + k, 25 + b + (k + i) % 2), fill=C("7a7a86"))                            # cadena
    if i in (1, 2):
        d.point((15, 4 + b), fill=(200, 200, 220, 150))                                      # aliento

PAL_PRESO = A2.look_pal(C("b89880"), C("6a6260"), C("c8c0b0"), C("4a4248"), C("2a2428"), C("6a5a50"), C("3a3236"), C("5a5258"), C("ffffff"))
A2.npc("m", 1, PAL_PRESO, ex_preso, False, False, tuple(range(10, 20))).save(f"{OUT}/npc_preso.png")

# ================================================================== campanas del Atrio (24x32): 3 campanas + soporte
def bell(n):
    img = canvas(24, 32); d = ImageDraw.Draw(img)
    w = [5, 7, 9][n]; h = [7, 9, 11][n]
    top = 6
    body = [C("c8a050"), C("b08840"), C("9a7030")][n]
    d.rectangle([11, 2, 12, top], fill=C("4a4048"))                     # argolla
    d.polygon([(12 - w // 2, top), (12 + w // 2, top), (12 + w, top + h), (12 - w, top + h)], fill=body)
    d.line([(12 - w, top + h), (12 + w, top + h)], fill=sh(body, 1.35))
    d.line([(12 - w // 2 + 1, top + 1), (12 - w + 1, top + h - 1)], fill=sh(body, 1.4))
    d.line([(12 + w // 2, top + 1), (12 + w, top + h - 1)], fill=sh(body, 0.65))
    d.line([(12 - w + 2, top + h // 2 + 1), (12 + w - 2, top + h // 2 + 1)], fill=sh(body, 0.75))
    for k in range(n + 1):                                                    # runas grabadas (una por tono)
        d.point((10 + k * 2, top + h // 2 - 1), fill=C("e0d0ff"))
    d.rectangle([11, top + h, 12, top + h + 2], fill=C("3a3038"))           # badajo
    return outline(img)

def bell_frame():
    img = canvas(24, 32); d = ImageDraw.Draw(img)
    wood = C("5a4030")
    d.rectangle([2, 2, 4, 31], fill=wood); d.rectangle([19, 2, 21, 31], fill=sh(wood, 0.75))
    d.rectangle([1, 1, 22, 3], fill=sh(wood, 1.2)); d.line([(1, 1), (22, 1)], fill=sh(wood, 1.5))
    d.line([(3, 3), (3, 30)], fill=sh(wood, 1.3))
    d.rectangle([0, 29, 6, 31], fill=C("4a4048")); d.rectangle([17, 29, 23, 31], fill=C("3a3038"))
    d.point((11, 3), fill=C("8a8a96")); d.point((12, 3), fill=C("8a8a96"))
    return outline(img)

strip([bell(0), bell(1), bell(2), bell_frame()]).save(f"{OUT}/bells.png")

# ================================================================== estela de inscripciones (16x26, 2 fotogramas)
def stele(lit):
    img = canvas(16, 26); d = ImageDraw.Draw(img)
    st = C("6a6274")
    d.polygon([(3, 4), (8, 1), (13, 4), (13, 23), (3, 23)], fill=st)
    d.polygon([(9, 2), (13, 4), (13, 23), (9, 23)], fill=sh(st, 0.75))
    d.line([(3, 4), (8, 1)], fill=sh(st, 1.35)); d.line([(4, 5), (4, 22)], fill=sh(st, 1.2))
    d.rectangle([1, 22, 15, 25], fill=sh(st, 0.6)); d.line([(1, 22), (15, 22)], fill=sh(st, 1.1))
    rune = C("a8e8ff") if lit else C("5aa0c8")
    for y in range(6, 20, 3):
        x0 = 5 + (y % 2)
        d.line([(x0, y), (x0 + 4 - (y % 3), y)], fill=rune)
        d.point((x0 + 1, y + 1), fill=sh(rune, 0.8))
    d.line([(10, 8), (11, 14)], fill=C("3a3442"))                           # grieta
    return outline(img)

strip([stele(False), stele(True)]).save(f"{OUT}/stele.png")

# ================================================================== puerta de celda (24x30, cerrada / abierta)
def celldoor(open_):
    img = canvas(24, 30); d = ImageDraw.Draw(img)
    stone = C("4a4250")
    d.rectangle([0, 0, 23, 29], fill=stone)
    d.pieslice([2, 2, 21, 20], 180, 360, fill=C("120c14"))
    d.rectangle([2, 11, 21, 29], fill=C("120c14"))
    d.arc([1, 1, 22, 21], 180, 360, fill=sh(stone, 1.4))
    for y in range(4, 29, 6):
        d.line([(0, y), (1, y)], fill=sh(stone, 0.7)); d.line([(22, y), (23, y)], fill=sh(stone, 0.7))
    if open_:
        for x in range(4, 21, 4):                                            # barrotes levantados
            d.line([(x, 3), (x, 9)], fill=C("6a646e"))
        d.line([(3, 9), (20, 9)], fill=C("5a5460"))
        for k in range(5):
            d.point((6 + k * 3, 22 + k % 2), fill=C("ff6a30"))               # ojos en la oscuridad
            d.point((7 + k * 3, 22 + k % 2), fill=C("ff6a30"))
    else:
        for x in range(4, 21, 4):
            d.line([(x, 4 if x in (8, 16) else 6), (x, 29)], fill=C("6a646e"))
            d.point((x, 29), fill=C("8a8490"))
        for y in (12, 22):
            d.line([(3, y), (20, y)], fill=C("5a5460"))
        d.rectangle([17, 15, 19, 18], fill=C("8a6a3a")); d.point((18, 16), fill=C("2a2026"))   # cerradura
    return outline(img)

strip([celldoor(False), celldoor(True)]).save(f"{OUT}/celldoor.png")

# ================================================================== barrotes de la celda de Tobías (26x30)
def cellbars():
    img = canvas(26, 30); d = ImageDraw.Draw(img)
    for x in range(2, 25, 4):
        d.line([(x, 1), (x, 29)], fill=C("5a5460"))
        d.line([(x + 1, 1), (x + 1, 29)], fill=C("8a8490"))
    for y in (2, 15, 28):
        d.line([(1, y), (25, y)], fill=C("4a4450"))
    d.point((22, 16), fill=C("ff8a40"))
    return outline(img)

cellbars().save(f"{OUT}/cellbars.png")
print("Arte de las antesalas generado en", OUT)

# ================================================================== v0.8: baldosas propias de las salas nuevas
# Se añaden al final de tiles.png (índices 20 en adelante):
#   20-21 piedra de celda · 22-23 mosaico de vitral (Atrio) · 24-25 mármol con oro (Antesala)
#   26 alfombra blanca y oro · 27 sumidero de celda · 28-29 muro de celda · 30-31 muro de mármol · 32-33 muro con vitral
import random
import numpy as np
T = 16

def celda_floor(seed, deco=True):
    rr = random.Random(seed)
    img = A2.floor(seed, (0.82, 0.8, 0.86), seed % 4)
    d = ImageDraw.Draw(img)
    # adoquines irregulares
    for k in range(3):
        x, y = rr.randint(1, 12), rr.randint(1, 12)
        d.rectangle([x, y, x + rr.randint(2, 3), y + rr.randint(1, 2)], fill=(44, 40, 48, 255))
        d.point((x, y), fill=(70, 64, 74, 255))
    if deco:
        for k in range(4):                                      # paja
            x, y = rr.randint(1, 13), rr.randint(1, 13)
            d.line([(x, y), (x + rr.randint(1, 3), y + rr.choice([-1, 0, 1]))], fill=C("8a7448"))
        if seed % 2:
            d.ellipse([rr.randint(2, 8), rr.randint(2, 8), rr.randint(9, 13), rr.randint(9, 13)], outline=(40, 30, 34, 255))  # mancha de humedad
    return img

def mosaic(seed):
    rr = random.Random(seed)
    img = canvas(T, T); d = ImageDraw.Draw(img)
    cols = [C("3a2a6a"), C("4a3a8a"), C("2a4a8a"), C("6a3a8a"), C("2a2a5a")]
    d.rectangle([0, 0, 15, 15], fill=C("2a1e48"))
    for y in range(0, 16, 8):
        for x in range(0, 16, 8):
            c = cols[rr.randint(0, len(cols) - 1)]
            d.polygon([(x + 4, y), (x + 8, y + 4), (x + 4, y + 8), (x, y + 4)], fill=c)
            d.point((x + 3, y + 2), fill=sh(c, 1.5))
    for i in range(0, 17, 8):                                   # plomo dorado del vitral
        d.line([(i, 0), (i + 16, 16)], fill=C("8a6a3a")); d.line([(i, 16), (i + 16, 0)], fill=C("8a6a3a"))
        d.line([(i - 16, 0), (i, 16)], fill=C("8a6a3a")); d.line([(i - 16, 16), (i, 0)], fill=C("8a6a3a"))
    if seed % 3 == 0:
        d.point((rr.randint(2, 13), rr.randint(2, 13)), fill=C("e0d0ff"))
    return img

def marble(seed):
    rr = random.Random(seed)
    a = A2.noise_tile((196, 188, 178), seed, 4)
    for (x0, y0, x1, y1) in [(0, 0, 15, 15)] if seed % 2 == 0 else [(0, 0, 7, 15), (8, 0, 15, 15)]:
        A2.slab(a, x0, y0, x1, y1, 14, -26)
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)); d = ImageDraw.Draw(img)
    x, y = rr.randint(0, 6), 0                                   # veta
    for k in range(16):
        d.point((x, y), fill=(150, 140, 150, 255))
        x = max(0, min(15, x + rr.choice([0, 1, 1]))); y += 1
    d.line([(0, 15), (15, 15)], fill=C("c89a40")); d.line([(15, 0), (15, 15)], fill=C("c89a40"))   # incrustación de oro
    if seed % 3 == 0:
        d.polygon([(7, 5), (10, 8), (7, 11), (4, 8)], outline=C("d8aa48"))
        d.point((7, 8), fill=C("fff0a0"))
    return img

def gold_carpet():
    img = canvas(T, T); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=C("e8e0d0"))
    d.line([(0, 1), (15, 1)], fill=C("d8aa48")); d.line([(0, 14), (15, 14)], fill=C("d8aa48"))
    d.line([(0, 2), (15, 2)], fill=C("b8b0a0")); d.line([(0, 13), (15, 13)], fill=C("b8b0a0"))
    for x in range(0, 16, 8):
        d.polygon([(x + 4, 4), (x + 6, 8), (x + 4, 11), (x + 2, 8)], fill=C("f4ecd8")); d.point((x + 4, 7), fill=C("d8aa48"))
    return img

def celda_drain():
    img = celda_floor(31, False); d = ImageDraw.Draw(img)
    d.ellipse([3, 4, 12, 11], fill=C("100a10")); d.ellipse([3, 4, 12, 11], outline=C("5a5462"))
    for x in (5, 7, 9):
        d.line([(x, 5), (x, 10)], fill=C("6a646e"))
    d.point((8, 9), fill=C("ff6020"))
    return img

def celda_wall(seed):
    img = A2.wall_face(seed + 40); d = ImageDraw.Draw(img)
    px = img.load()
    for y in range(T):
        for x in range(T):
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * 0.85), int(g * 0.8), int(b * 0.82), a)
    d.ellipse([5, 5, 10, 10], outline=C("8a8494"))               # argolla de hierro
    d.line([(7, 4), (8, 4)], fill=C("5a5462"))
    if seed % 2:
        d.line([(3, 11), (3, 15)], fill=C("4a1a1a")); d.point((3, 15), fill=C("6a2a2a"))   # rastro de óxido
    return img

def marble_wall(seed):
    rr = random.Random(seed)
    img = canvas(T, T); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=C("b8b0a4"))
    for row, y in enumerate((0, 5, 10)):
        off = 0 if row % 2 == 0 else 5
        for x in range(-off, 16, 10):
            c = sh(C("cfc7ba"), 1 + rr.uniform(-0.06, 0.05))
            d.rectangle([x, y, x + 9, y + 4], fill=c)
            d.line([(x, y), (x + 8, y)], fill=sh(c, 1.15)); d.line([(x, y + 4), (x + 9, y + 4)], fill=C("8a8278"))
    d.line([(0, 0), (15, 0)], fill=C("d8aa48"))
    if seed % 2 == 0:
        d.rectangle([6, 6, 9, 13], fill=C("8a6a3a")); d.rectangle([7, 7, 8, 12], fill=C("ffd060"))   # hornacina con vela
    return img

def glass_wall(seed):
    img = A2.wall_face(seed + 60); d = ImageDraw.Draw(img)
    d.rectangle([3, 2, 12, 14], fill=C("1a1230"))
    d.pieslice([3, -2, 12, 7], 180, 360, fill=C("1a1230"))
    cols = [C("6a4aff"), C("ff5a8a"), C("4ac0ff"), C("ffd060")]
    for i, (x, y) in enumerate(((5, 4), (8, 4), (5, 8), (8, 8), (6, 11))):
        d.rectangle([x, y, x + 2, y + 2], fill=cols[(i + seed) % 4])
    d.line([(7, 1), (7, 14)], fill=C("8a6a3a")); d.line([(4, 7), (11, 7)], fill=C("8a6a3a"))
    return img

base = Image.open(f"{OUT}/tiles.png").convert("RGBA")
extra = [celda_floor(1), celda_floor(2), mosaic(1), mosaic(2), marble(1), marble(2), gold_carpet(), celda_drain(),
         celda_wall(0), celda_wall(1), marble_wall(0), marble_wall(1), glass_wall(0), glass_wall(1)]
out = canvas(base.width + T * len(extra), T)
out.paste(base, (0, 0))
for i, t in enumerate(extra):
    out.paste(t, (base.width + i * T, 0), t)
out.save(f"{OUT}/tiles.png")
print("tiles.png ampliado a", out.width // T, "baldosas")

# ================================================================== v0.8: icono del amuleto nuevo y página del himno
def icon_bell():
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    d.line([(8, 1), (8, 3)], fill=C("8a8494"))
    d.polygon([(6, 3), (10, 3), (13, 11), (3, 11)], fill=C("d8b050"))
    d.line([(6, 4), (4, 10)], fill=C("fff0a0")); d.line([(10, 4), (12, 10)], fill=C("8a6a20"))
    d.line([(3, 11), (13, 11)], fill=C("fff0a0"))
    d.rectangle([7, 12, 9, 13], fill=C("6a5a7a"))
    d.point((5, 7), fill=C("e0d0ff")); d.point((11, 7), fill=C("e0d0ff"))
    d.arc([0, 0, 15, 15], 200, 250, fill=C("c8b8ff")); d.arc([0, 0, 15, 15], 290, 340, fill=C("c8b8ff"))
    return outline(img)

def icon_page():
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    d.polygon([(3, 2), (12, 1), (13, 14), (4, 15)], fill=C("e8dcc0"))
    d.line([(3, 2), (4, 15)], fill=C("b8a888"))
    for y in (4, 6, 8, 10):
        d.line([(5, y), (11, y - 1)], fill=C("6a4a8a"))
    d.point((10, 12), fill=C("c83040")); d.point((11, 12), fill=C("c83040"))
    return outline(img)

def cracked_wall():
    """Muro agrietado (48x24) que tapa el pasadizo de la capilla, y su versión derrumbada."""
    frames = []
    for broken in (False, True):
        img = canvas(48, 24); d = ImageDraw.Draw(img)
        if not broken:
            for row, y in enumerate((0, 6, 12, 18)):
                off = 0 if row % 2 == 0 else 6
                for x in range(-off, 48, 12):
                    d.rectangle([x, y, x + 11, y + 5], fill=C("4e465a"))
                    d.line([(x, y), (x + 10, y)], fill=C("6a6278")); d.line([(x, y + 5), (x + 11, y + 5)], fill=C("2a2434"))
            for pts in (((20, 2), (24, 8), (22, 13), (27, 19), (25, 23)), ((30, 5), (33, 11), (31, 16))):
                d.line(pts, fill=C("140c18"), width=1)
            d.point((24, 10), fill=C("ffd060")); d.point((23, 15), fill=C("ffd060"))   # luz al otro lado
        else:
            for k in range(7):
                x = 4 + k * 6; y = 14 + (k % 3) * 3
                d.polygon([(x, y), (x + 5, y - 2), (x + 7, y + 4), (x + 1, y + 6)], fill=C("4e465a"))
                d.line([(x, y), (x + 5, y - 2)], fill=C("6a6278"))
        frames.append(outline(img))
    return strip(frames)

icon_bell().save(f"{OUT}/icon_amulet_bell.png")
icon_page().save(f"{OUT}/icon_page.png")
cracked_wall().save(f"{OUT}/cracked_wall.png")
print("Iconos v0.8 generados")

# ================================================================== v0.8: Guardia de las Celdas (32x32)
def guard_rows():
    """Guardia: carcelero menor con casco de rejilla, cota oxidada y un escudo-puerta de celda."""
    pal = A2.look_pal(C("8a7a72"), C("3a3236"), C("ff7a30"), C("5a5258"), C("3a3438"), C("9a6a3a"), C("4a2a24"), C("5a5258"), C("000000"))
    lost = tuple(range(10, 20))
    def frame(pose, k):
        pose = dict(pose); pose["halo"] = False; pose["wings"] = False
        img = A2.colorize(GL.hero("m", 0, pose), pal, lost)
        d = ImageDraw.Draw(img); b = pose.get("bob", 0)
        d.rectangle([13, 3 + b, 21, 11 + b], fill=C("4a4450"))                         # yelmo de rejilla
        for x in (15, 17, 19):
            d.line([(x, 6 + b), (x, 11 + b)], fill=C("2a2430"))
        d.point((17, 8 + b), fill=C("ff7a30")); d.point((19, 8 + b), fill=C("ff7a30"))
        d.line([(13, 3 + b), (21, 3 + b)], fill=C("7a7480"))
        sx = 22 if pose.get("arm", 0) != 2 else 24                                        # escudo: puerta de celda
        d.rectangle([sx - 3, 14 + b, sx + 3, 26 + b], fill=C("3a3440"))
        for x in range(sx - 2, sx + 3, 2):
            d.line([(x, 15 + b), (x, 25 + b)], fill=C("8a8494"))
        d.line([(sx - 3, 19 + b), (sx + 3, 19 + b)], fill=C("6a646e"))
        d.point((sx, 20 + b), fill=C("c89a40"))
        return outline(img)
    idle = [frame({"bob": [0, 0, 1, 1][i]}, i) for i in range(4)]
    cyc = [(-2, 2), (-1, 1), (1, -1), (2, -2)]
    walk = [frame({"l": cyc[i][0], "r": cyc[i][1], "bob": i % 2}, i) for i in range(4)]
    atk = [frame({"arm": a, "l": l, "r": -l}, k) for k, (a, l) in enumerate(((1, -1), (2, 2), (2, 1)))]
    dead = frame({"bob": 1}, 0).rotate(90, expand=False, resample=Image.NEAREST)
    return [idle, walk, atk, [dead, dead]]

sheet(guard_rows()).save(f"{OUT}/enemy_guardia.png")
print("Guardia generado")

# ================================================================== v0.8: Sael, la Peregrina (PNJ de la Escalinata)
def ex_peregrina(d, img, i, b):
    hood = C("6a5a48")
    d.polygon([(12, 4 + b), (18, 2 + b), (22, 6 + b), (22, 10 + b), (19, 8 + b), (15, 7 + b), (14, 14 + b), (11, 16 + b)], fill=hood)
    d.line([(13, 5 + b), (19, 3 + b)], fill=sh(hood, 1.35))
    sx = 23
    d.line([(sx, 8 + b), (sx, 30)], fill=C("7a5a3a"))                                  # bastón
    ly = 9 + b + (1 if i in (1, 2) else 0)
    d.rectangle([sx - 1, ly - 1, sx + 1, ly + 2], fill=C("ffd88a")); d.point((sx, ly), fill=C("fffbe0"))   # farolillo
    for k in range(3):                                                                    # cinta de peregrina
        d.point((13 + k, 19 + b + k % 2), fill=C("c83040"))

PAL_PEREGRINA = A2.look_pal(C("e0c0a0"), C("c8b8a0"), C("8ac0a0"), C("8a7a60"), C("4a3e32"), C("d8aa48"), C("5a4a3a"), C("d8d0c0"), C("ffffff"))
A2.npc("f", 2, PAL_PEREGRINA, ex_peregrina, True, False, (14, 19, 13)).save(f"{OUT}/npc_peregrina.png")
print("Peregrina generada")


# v0.8: las velas y los cálices nuevos sustituyen a los de gen_art/gen_art2
import gen_props
gen_props.main()

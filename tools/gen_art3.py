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

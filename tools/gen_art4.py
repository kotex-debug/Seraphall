#!/usr/bin/env python3
"""SERAPHALL v0.8 - la Plañidera: espíritu velado que llora lágrimas que caen desde lo alto.
Hoja 32x32: fila 0 reposo (4), fila 1 flotar (4), fila 2 ataque (3), fila 3 muerte (2).
Uso: python3 tools/gen_art4.py"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
W = H = 32
INK = (16, 10, 24, 255)


def C(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


VEIL = C("2c2e52"); VEIL_L = C("4c5288"); VEIL_D = C("1a1a34")
SKIN = C("d8d0e4"); EYE = C("9ff8ff"); TEAR = C("7ad8ff"); GLOW = C("c8f4ff")
HALO = C("8a8698")


def outline(img):
    px = img.load(); out = img.copy(); po = out.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                        po[x, y] = INK
                        break
    return out


def frame(bob=0, flutter=0, arms="clasp", glow=0.0, tears=1):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    b = bob
    # velo: capucha y manto acampanado con bajo deshilachado
    d.polygon([(13, 5 + b), (19, 5 + b), (22, 10 + b), (23, 18 + b), (25, 26 + b), (7, 26 + b), (9, 18 + b), (10, 10 + b)], fill=VEIL)
    hem = []
    for i in range(9):
        x = 7 + i * 2.25
        y = 26 + b + ((i + flutter) % 2) * 2
        hem.append((x, y))
    d.polygon([(7, 25 + b)] + hem + [(25, 25 + b)], fill=VEIL)
    d.line([(11, 11 + b), (9, 25 + b)], fill=VEIL_D)
    d.line([(21, 11 + b), (23, 25 + b)], fill=VEIL_L)
    d.line([(16, 15 + b), (16, 26 + b)], fill=VEIL_D)
    d.line([(14, 6 + b), (18, 6 + b)], fill=VEIL_L)
    # rostro oculto: hueco oscuro con ojos que brillan y lágrimas
    d.ellipse([13, 8 + b, 19, 14 + b], fill=C("0a0812"))
    d.point((14, 11 + b), fill=EYE); d.point((17, 11 + b), fill=EYE)
    for k in range(tears):
        d.line([(14, 12 + b), (14, 14 + b + k)], fill=TEAR)
        d.line([(17, 12 + b), (17, 13 + b + k)], fill=TEAR)
    # aureola rota
    d.arc([11, 1 + b, 21, 5 + b], 200, 330, fill=HALO)
    d.arc([11, 1 + b, 21, 5 + b], 350, 380, fill=HALO)
    # manos y vial de lágrimas
    vial_col = tuple(int(TEAR[i] + (GLOW[i] - TEAR[i]) * glow) for i in range(3)) + (255,)
    if arms == "clasp":
        d.rectangle([14, 17 + b, 18, 19 + b], fill=SKIN)
        d.rectangle([15, 15 + b, 17, 17 + b], fill=vial_col)
        d.point((16, 14 + b), fill=GLOW)
    elif arms == "raise":
        d.line([(12, 15 + b), (11, 8 + b)], fill=SKIN, width=2)
        d.line([(20, 15 + b), (21, 8 + b)], fill=SKIN, width=2)
        d.ellipse([14, 2 + b, 18, 6 + b], fill=vial_col)
        d.point((16, 3 + b), fill=(255, 255, 255, 255))
    else:  # spread
        d.line([(11, 16 + b), (5, 13 + b)], fill=SKIN, width=2)
        d.line([(21, 16 + b), (27, 13 + b)], fill=SKIN, width=2)
        for x in (4, 28):
            d.ellipse([x - 1, 10 + b, x + 1, 13 + b], fill=TEAR)
    return outline(img)


def dead(k):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    d.polygon([(5, 29), (9, 24 - k), (16, 22 - k), (23, 24 - k), (27, 29)], fill=VEIL)
    d.line([(9, 26), (23, 26)], fill=VEIL_L)
    d.ellipse([14, 25, 18, 28], fill=TEAR)
    return outline(img)


def sheet():
    rows = [
        [frame(b, i % 2) for i, b in enumerate((0, 0, -1, -1))],
        [frame(b, (i + 1) % 2, tears=2) for i, b in enumerate((0, -1, -1, 0))],
        [frame(0, 0, "raise", 0.5), frame(-1, 1, "raise", 1.0, tears=2), frame(0, 0, "spread", 1.0, tears=3)],
        [dead(0), dead(1)],
    ]
    s = Image.new("RGBA", (W * 4, H * 4))
    for j, r in enumerate(rows):
        for i, f in enumerate(r):
            s.paste(f, (i * W, j * H), f)
    return s


if __name__ == "__main__":
    sheet().save(os.path.join(OUT, "enemy_planidera.png"))
    print("Plañidera generada")

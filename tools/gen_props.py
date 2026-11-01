#!/usr/bin/env python3
"""SERAPHALL v0.8 - velas y cálices (braseros) con más detalle.
candle.png: 4 fotogramas de 12x16 (tres velas con cera chorreada, platillo de latón y llama de 3 tonos).
brazier.png: 4 fotogramas de 16x24 (cáliz de bronce dorado con nudo en el tallo y fuego vivo).
Uso: python3 tools/gen_props.py"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
INK = (20, 12, 22, 255)


def C(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def outline(img, skip_alpha_below=200):
    w, h = img.size
    px = img.load()
    out = img.copy()
    po = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] >= skip_alpha_below:
                        po[x, y] = INK
                        break
    return out


WAX = C("f2e6c8"); WAX_L = C("fffaf0"); WAX_D = C("c8b48e"); WAX_DD = C("9a8468")
BRASS = C("c89a40"); BRASS_L = C("f0d070"); BRASS_D = C("7a5a28")
F_WHITE = C("fffbe0"); F_YEL = C("ffd040"); F_ORA = C("ff8a2a"); F_RED = C("e0402a")


def flame(d, x, y, k, big=False):
    """Llama de 3 tonos que cambia de forma con el fotograma k."""
    lean = [0, 1, 0, -1][k]
    h = (4 if big else 3) + [0, 1, 0, 1][k]
    d.line([(x + lean, y - h), (x, y)], fill=F_ORA)
    d.line([(x + lean, y - h + 1), (x, y - 1)], fill=F_YEL)
    d.point((x, y - 1), fill=F_WHITE)
    if big:
        d.point((x - 1, y - 1), fill=F_ORA)
        d.point((x + 1, y - 1), fill=F_ORA)
        d.point((x + lean, y - h - 1), fill=F_RED)


def candle_frame(k):
    img = Image.new("RGBA", (12, 16)); d = ImageDraw.Draw(img)
    # platillo de latón
    d.rectangle([0, 14, 11, 15], fill=BRASS_D)
    d.line([(1, 14), (10, 14)], fill=BRASS)
    d.point((2, 14), fill=BRASS_L); d.point((3, 14), fill=BRASS_L)
    # tres velas (alta, media, baja) con luz desde la izquierda
    for (x0, top, w) in ((1, 5, 3), (5, 3, 3), (9, 8, 2)):
        d.rectangle([x0, top, x0 + w - 1, 13], fill=WAX)
        d.line([(x0, top), (x0, 13)], fill=WAX_L)
        d.line([(x0 + w - 1, top + 1), (x0 + w - 1, 13)], fill=WAX_D)
        d.point((x0 + 1, top), fill=WAX_L)
        # gotas de cera
        d.point((x0 + w - 1, top + 2 + (x0 % 3)), fill=WAX_DD)
        d.point((x0, top + 3), fill=WAX_L)
        # mecha
        d.point((x0 + w // 2, top - 1), fill=C("3a2a20"))
    # charco de cera en el platillo
    d.line([(4, 13), (8, 13)], fill=WAX_D)
    img = outline(img)
    d = ImageDraw.Draw(img)
    for (x0, top, w), big in (((1, 5, 3), False), ((5, 3, 3), True), ((9, 8, 2), False)):
        flame(d, x0 + w // 2, top - 1, (k + x0) % 4, big)
    return img


def brazier_frame(k):
    img = Image.new("RGBA", (16, 24)); d = ImageDraw.Draw(img)
    # base escalonada
    d.rectangle([3, 21, 12, 23], fill=BRASS_D)
    d.line([(4, 21), (11, 21)], fill=BRASS)
    d.point((4, 21), fill=BRASS_L)
    # tallo con nudo
    d.rectangle([6, 15, 9, 20], fill=BRASS)
    d.line([(6, 15), (6, 20)], fill=BRASS_L)
    d.line([(9, 15), (9, 20)], fill=BRASS_D)
    d.ellipse([4, 16, 11, 19], fill=BRASS)
    d.line([(5, 17), (6, 17)], fill=BRASS_L)
    d.point((10, 18), fill=BRASS_D)
    d.point((7, 17), fill=C("e0303a"))                       # gema roja en el nudo
    # copa
    d.polygon([(0, 8), (15, 8), (13, 13), (10, 15), (5, 15), (2, 13)], fill=BRASS)
    d.line([(1, 9), (4, 14)], fill=BRASS_L)
    d.line([(14, 9), (11, 14)], fill=BRASS_D)
    for x in (4, 7, 10, 13):                                  # grabado
        d.point((x, 11), fill=BRASS_D)
    # borde con brasas
    d.rectangle([0, 7, 15, 8], fill=BRASS_L)
    d.line([(2, 7), (13, 7)], fill=C("7a2010"))
    for x in (3, 6, 9, 12):
        d.point((x, 7), fill=[F_RED, F_ORA, F_YEL, F_ORA][(x + k) % 4])
    img = outline(img)
    d = ImageDraw.Draw(img)
    # fuego: tres lenguas que se alternan
    shapes = [
        [(3, 7), (5, 2), (7, 5), (8, 0), (10, 5), (12, 3), (13, 7)],
        [(3, 7), (4, 3), (7, 4), (8, 1), (11, 4), (12, 2), (13, 7)],
        [(3, 7), (5, 3), (6, 5), (9, 0), (10, 4), (12, 4), (13, 7)],
        [(3, 7), (4, 2), (7, 5), (7, 1), (10, 3), (11, 2), (13, 7)],
    ]
    pts = shapes[k]
    d.polygon(pts, fill=F_RED)
    inner = [(x + (8 - x) * 0.3, y + (7 - y) * 0.35) for x, y in pts]
    d.polygon(inner, fill=F_ORA)
    core = [(x + (8 - x) * 0.6, y + (7 - y) * 0.65) for x, y in pts]
    d.polygon(core, fill=F_YEL)
    d.point((8, 6), fill=F_WHITE); d.point((7, 6), fill=F_WHITE)
    return img


STONE = C("8a8496"); STONE_L = C("b4aec0"); STONE_D = C("5a5468"); VELVET = C("8a2030"); VELVET_L = C("c04050")
WOOD = C("7a4a2a"); WOOD_L = C("a86a3a"); WOOD_D = C("4a2a1a"); IRON = C("4a4652"); IRON_L = C("8a8694"); GOLD = C("e8b848")


def bench():
    """Banco de oración de piedra tallada con cojín de terciopelo (donde se contempla)."""
    img = Image.new("RGBA", (28, 14)); d = ImageDraw.Draw(img)
    for x0 in (2, 22):                                           # patas talladas
        d.rectangle([x0, 7, x0 + 3, 13], fill=STONE_D)
        d.line([(x0, 7), (x0, 13)], fill=STONE)
        d.point((x0 + 1, 10), fill=STONE_L)
    d.rectangle([0, 4, 27, 7], fill=STONE)                       # tablero
    d.line([(1, 4), (26, 4)], fill=STONE_L)
    d.line([(0, 7), (27, 7)], fill=STONE_D)
    for x in (6, 13, 20):                                        # relieve
        d.point((x, 6), fill=STONE_D)
    d.rectangle([5, 1, 22, 4], fill=VELVET)                      # cojín
    d.line([(6, 1), (21, 1)], fill=VELVET_L)
    d.point((5, 4), fill=GOLD); d.point((22, 4), fill=GOLD)       # borlas
    d.point((13, 2), fill=C("e06070"))
    return outline(img)


def chest_frame(open_):
    """Cofre de madera con herrajes de hierro, esquinas doradas y cerradura que brilla."""
    img = Image.new("RGBA", (20, 18)); d = ImageDraw.Draw(img)
    d.rectangle([1, 8, 18, 17], fill=WOOD)
    for y in (10, 13, 16):
        d.line([(2, y), (17, y)], fill=WOOD_D)
    d.line([(1, 8), (1, 17)], fill=WOOD_L)
    if not open_:
        d.rectangle([1, 3, 18, 8], fill=WOOD)
        d.chord([1, 0, 18, 8], 180, 360, fill=WOOD_L)
        d.line([(2, 2), (17, 2)], fill=C("c88a50"))
        d.rectangle([1, 7, 18, 8], fill=IRON)
    else:
        d.polygon([(1, 8), (3, 0), (16, 0), (18, 8)], fill=WOOD_D)
        d.polygon([(3, 7), (5, 2), (14, 2), (16, 7)], fill=C("2a160c"))
        d.rectangle([4, 6, 15, 8], fill=C("ffd060"))                 # brillo del tesoro
        d.point((7, 5), fill=C("fff8d0")); d.point((12, 5), fill=C("fff8d0"))
    for x in (4, 15):                                                # flejes
        d.line([(x, 3 if not open_ else 8), (x, 17)], fill=IRON)
        d.line([(x + 1, 3 if not open_ else 8), (x + 1, 17)], fill=IRON_L)
    for cx, cy in ((1, 8), (18, 8), (1, 17), (18, 17)):              # esquinas doradas
        d.point((cx, cy), fill=GOLD)
    if not open_:
        d.rectangle([8, 7, 11, 11], fill=GOLD)                       # cerradura
        d.point((9, 9), fill=C("3a2010")); d.point((9, 8), fill=C("fff0a0"))
    return outline(img)


def strip(frames):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h))
    for i, f in enumerate(frames):
        s.paste(f, (i * w, 0), f)
    return s


def main():
    strip([candle_frame(k) for k in range(4)]).save(os.path.join(OUT, "candle.png"))
    strip([brazier_frame(k) for k in range(4)]).save(os.path.join(OUT, "brazier.png"))
    bench().save(os.path.join(OUT, "bench.png"))
    strip([chest_frame(False), chest_frame(True)]).save(os.path.join(OUT, "chest.png"))
    print("Velas, cálices, banco y cofre generados")


if __name__ == "__main__":
    main()

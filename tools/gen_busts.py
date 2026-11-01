#!/usr/bin/env python3
"""Bustos 48x48 de los PNJ para el cuadro de diálogo (3/4 mirando a la derecha).
Cada hoja tiene 3 fotogramas: normal, hablando (boca abierta) y parpadeo.
Uso: python3 tools/gen_busts.py  -> assets/sprites/bust_<pnj>.png"""
from PIL import Image, ImageDraw
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
W = H = 48
INK = (20, 10, 24, 255)


def sh(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


def outline(img):
    px = img.load()
    out = img.copy()
    po = out.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                        po[x, y] = INK
                        break
    return out


def wings(d, col):
    # ala trasera (izquierda) y punta de la delantera (derecha), plumas marcadas
    d.polygon([(13, 44), (3, 30), (1, 20), (4, 22), (8, 30), (15, 37)], fill=sh(col, 0.8))
    d.polygon([(3, 22), (0, 14), (3, 15), (7, 26)], fill=sh(col, 0.95))
    for k in range(4):
        d.line([(3 + k, 24 + k * 4), (9 + k, 31 + k * 3)], fill=sh(col, 1.15 - k * 0.08))
    d.polygon([(39, 40), (46, 27), (47, 33), (44, 44)], fill=sh(col, 0.7))
    for k in range(3):
        d.line([(45 - k, 30 + k * 4), (41 - k, 35 + k * 3)], fill=sh(col, 0.9))


def torso(d, col, trim, collar=None):
    d.polygon([(5, 48), (8, 39), (16, 35), (34, 35), (42, 39), (45, 48)], fill=col)
    d.polygon([(5, 48), (8, 39), (16, 35), (20, 35), (17, 48)], fill=sh(col, 0.72))
    d.line([(16, 36), (34, 36)], fill=sh(col, 1.3))
    d.line([(26, 37), (26, 47)], fill=trim)
    if collar:
        d.polygon([(19, 34), (33, 34), (30, 39), (26, 41), (22, 39)], fill=collar)
        d.line([(22, 39), (26, 41), (30, 39)], fill=sh(collar, 0.75))


def neck(d, skin):
    d.rectangle([22, 28, 29, 35], fill=sh(skin, 0.78))


def face(d, skin, eye, frame, old=False, mask=False):
    # cabeza en 3/4: óvalo + mentón hacia la derecha
    d.ellipse([18, 11, 34, 29], fill=skin)
    d.polygon([(21, 25), (31, 25), (30, 30), (25, 31), (22, 28)], fill=skin)
    d.ellipse([18, 12, 23, 28], fill=sh(skin, 0.82))                 # lado en sombra
    d.ellipse([18, 18, 22, 24], fill=sh(skin, 0.7))                  # oreja
    d.point((20, 21), fill=sh(skin, 0.5))
    d.line([(32, 16), (33, 22)], fill=sh(skin, 1.12))                # luz en la mejilla
    if mask:
        return
    # ojos
    blink = frame == 2
    if blink:
        d.line([(24, 21), (26, 21)], fill=INK)
        d.line([(29, 21), (31, 21)], fill=INK)
    else:
        d.rectangle([24, 19, 25, 21], fill=INK)
        d.point((25, 19), fill=eye)
        d.rectangle([29, 19, 31, 21], fill=INK)
        d.rectangle([30, 19, 31, 20], fill=eye)
        d.point((31, 19), fill=(255, 255, 255, 255))
    # cejas
    d.line([(23, 17), (26, 17)], fill=sh(skin, 0.45))
    d.line([(29, 17), (32, 16)], fill=sh(skin, 0.45))
    # nariz
    d.line([(33, 21), (34, 24)], fill=sh(skin, 0.75))
    d.point((33, 24), fill=sh(skin, 0.6))
    # boca
    if frame == 1:
        d.rectangle([28, 26, 30, 27], fill=(70, 20, 30, 255))
        d.point((29, 27), fill=(150, 60, 70, 255))
    else:
        d.line([(28, 26), (31, 26)], fill=sh(skin, 0.55))
    if old:
        d.line([(23, 23), (25, 24)], fill=sh(skin, 0.72))
        d.line([(30, 23), (31, 25)], fill=sh(skin, 0.72))
        d.line([(23, 15), (27, 15)], fill=sh(skin, 0.8))


SKIN = (236, 190, 160)
SKIN_PALE = (226, 200, 186)
SKIN_TAN = (200, 150, 112)


def brenna(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    hair = (214, 92, 46)
    d.polygon([(16, 12), (14, 22), (15, 30), (21, 31), (21, 18)], fill=sh(hair, 0.75))   # melena trasera
    torso(d, (120, 78, 46), (232, 180, 70), collar=(70, 46, 40))
    d.polygon([(18, 37), (34, 37), (36, 48), (16, 48)], fill=(92, 58, 36))               # delantal de cuero
    d.rectangle([24, 41, 28, 43], fill=(232, 180, 70))                                  # hebilla
    d.point((26, 42), fill=(120, 78, 46))
    neck(d, SKIN)
    face(d, SKIN, (70, 140, 90), frame)
    # pelo corto a lo paje con flequillo
    d.ellipse([16, 6, 35, 17], fill=hair)
    d.polygon([(16, 11), (15, 26), (19, 27), (22, 14)], fill=hair)
    d.polygon([(23, 12), (35, 12), (35, 16), (33, 15), (30, 17), (28, 15), (25, 16)], fill=sh(hair, 1.12))
    d.line([(20, 10), (30, 9)], fill=sh(hair, 1.3))
    d.point((22, 28), fill=sh(SKIN, 0.6))                                               # hollín
    d.line([(31, 28), (32, 29)], fill=(60, 50, 50, 255))
    return img


def carto(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    wings(d, (150, 150, 165))
    torso(d, (40, 48, 92), (220, 190, 110), collar=(60, 70, 120))
    d.rectangle([33, 40, 41, 46], fill=(220, 200, 150))                                 # mapa enrollado
    d.line([(34, 42), (40, 42)], fill=(150, 110, 70))
    d.line([(34, 44), (39, 44)], fill=(150, 110, 70))
    neck(d, SKIN_PALE)
    face(d, SKIN_PALE, (90, 120, 200), frame, old=True)
    hair = (220, 222, 232)
    d.polygon([(16, 13), (19, 8), (26, 6), (33, 9), (35, 14), (31, 12), (27, 13), (22, 12), (20, 18), (17, 25), (15, 20)], fill=hair)
    d.line([(19, 9), (25, 7)], fill=(255, 255, 255, 255))
    # gafas redondas
    d.ellipse([28, 18, 32, 22], outline=(230, 190, 90, 255))
    d.line([(26, 20), (28, 20)], fill=(230, 190, 90, 255))
    return img


def ozias(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    hood = (30, 92, 100)
    d.polygon([(12, 30), (13, 14), (20, 6), (30, 5), (37, 11), (38, 24), (35, 30)], fill=hood)
    torso(d, (24, 52, 64), (90, 230, 230))
    d.polygon([(23, 39), (26, 36), (29, 39), (26, 44)], fill=(90, 230, 230))             # runa brillante
    d.point((26, 39), fill=(220, 255, 255, 255))
    neck(d, SKIN_TAN)
    face(d, SKIN_TAN, (110, 240, 240), frame, old=True)
    # capucha por delante (deja ver la cara)
    d.polygon([(13, 14), (20, 6), (30, 5), (37, 11), (36, 15), (30, 10), (22, 11), (18, 18), (17, 30), (13, 30)], fill=hood)
    d.line([(21, 7), (30, 6)], fill=sh(hood, 1.4))
    d.line([(15, 18), (16, 28)], fill=(90, 230, 230))
    d.polygon([(30, 29), (34, 28), (32, 33), (28, 32)], fill=(200, 200, 205))           # barba corta
    return img


def ilse(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    veil = (34, 36, 78)
    d.polygon([(11, 40), (12, 16), (19, 7), (31, 6), (37, 13), (37, 30), (34, 36)], fill=veil)
    torso(d, (30, 32, 70), (230, 230, 240), collar=(236, 236, 244))
    d.line([(26, 40), (26, 46)], fill=(236, 236, 244))
    d.line([(24, 42), (28, 42)], fill=(236, 236, 244))
    neck(d, SKIN)
    face(d, SKIN, (110, 100, 160), frame, old=True)
    # toca blanca enmarcando la cara
    d.polygon([(17, 12), (22, 9), (31, 9), (35, 13), (35, 15), (30, 12), (22, 13), (19, 19), (19, 29), (24, 33), (31, 32), (33, 30), (34, 33), (28, 36), (20, 34), (16, 28)], fill=(240, 240, 248))
    d.line([(20, 10), (31, 10)], fill=(255, 255, 255, 255))
    return img


def nyx(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    wings(d, (40, 34, 52))
    hair = (24, 18, 34)
    d.polygon([(14, 12), (11, 30), (13, 40), (20, 38), (21, 18)], fill=hair)            # melena negra
    torso(d, (26, 22, 34), (230, 180, 60), collar=(50, 40, 60))
    d.line([(17, 38), (34, 38)], fill=(230, 180, 60))
    neck(d, SKIN_PALE)
    face(d, SKIN_PALE, (230, 180, 60), frame, mask=True)
    # máscara de pico negra con ojo dorado
    d.polygon([(19, 13), (33, 13), (35, 18), (44, 26), (42, 28), (33, 25), (25, 27), (20, 24)], fill=(32, 28, 40))
    d.line([(33, 19), (43, 26)], fill=(80, 70, 96))
    d.ellipse([27, 17, 32, 21], fill=(10, 8, 14))
    if frame != 2:
        d.ellipse([28, 18, 31, 20], fill=(250, 200, 70))
        d.point((30, 18), fill=(255, 255, 220, 255))
    d.ellipse([15, 6, 34, 18], fill=hair)
    d.polygon([(26, 8), (35, 12), (31, 13)], fill=sh(hair, 1.6))
    if frame == 1:
        d.line([(36, 26), (40, 28)], fill=(10, 8, 14))
    return img


def velaria(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    veil = (150, 26, 40)
    d.polygon([(12, 40), (12, 17), (19, 7), (31, 6), (37, 13), (36, 30), (33, 36)], fill=veil)
    torso(d, (140, 24, 36), (240, 190, 80), collar=(110, 18, 30))
    d.ellipse([23, 39, 29, 45], fill=(240, 190, 80))
    d.point((26, 42), fill=(140, 24, 36))
    neck(d, SKIN)
    face(d, SKIN, (180, 60, 60), frame)
    hair = (200, 70, 50)
    d.polygon([(19, 13), (24, 11), (33, 12), (35, 16), (30, 14), (25, 16), (21, 20), (19, 26)], fill=hair)
    # diadema roja con aureola
    d.polygon([(17, 11), (23, 6), (31, 6), (36, 11), (33, 10), (26, 9), (20, 11)], fill=sh(veil, 1.35))
    d.ellipse([20, 1, 34, 6], outline=(255, 120, 110, 255))
    return img


def preso(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    torso(d, (70, 66, 70), (110, 104, 110))
    d.line([(10, 42), (14, 46)], fill=(50, 46, 52))
    d.line([(36, 42), (40, 45)], fill=(50, 46, 52))
    # collar de hierro y cadena
    d.rectangle([19, 33, 33, 36], fill=(120, 118, 128))
    d.line([(19, 33), (33, 33)], fill=(170, 168, 180))
    for k in range(3):
        d.ellipse([33 + k * 3, 36 + k * 3, 36 + k * 3, 39 + k * 3], outline=(140, 138, 150, 255))
    neck(d, (210, 176, 150))
    face(d, (210, 176, 150), (120, 120, 140), frame, old=True)
    hair = (140, 138, 140)
    d.polygon([(16, 14), (18, 8), (24, 6), (31, 7), (35, 12), (32, 11), (27, 12), (22, 11), (20, 17), (18, 25), (15, 21)], fill=hair)
    d.line([(19, 8), (17, 5)], fill=hair)
    d.line([(26, 6), (27, 3)], fill=hair)
    # barba gris
    d.polygon([(22, 25), (24, 28), (28, 29), (32, 27), (34, 26), (33, 31), (29, 35), (24, 34), (21, 30)], fill=(170, 168, 172))
    d.line([(25, 31), (27, 34)], fill=(130, 128, 132))
    if frame == 1:
        d.rectangle([28, 27, 30, 28], fill=(60, 20, 30))
    return img


def peregrina(frame):
    img = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(img)
    wings(d, (232, 228, 214))
    hood = (150, 128, 90)
    d.polygon([(12, 32), (13, 15), (20, 6), (30, 5), (37, 12), (37, 26), (33, 32)], fill=sh(hood, 0.8))
    torso(d, (130, 110, 76), (230, 190, 90))
    d.line([(40, 30), (38, 48)], fill=(150, 110, 60))                                 # bastón
    d.ellipse([38, 26, 43, 31], fill=(240, 200, 90))
    neck(d, SKIN)
    face(d, SKIN, (140, 110, 70), frame)
    d.polygon([(13, 15), (20, 6), (30, 5), (37, 12), (36, 16), (30, 11), (22, 12), (18, 19), (18, 31), (13, 31)], fill=hood)
    d.line([(21, 7), (30, 6)], fill=sh(hood, 1.3))
    return img


NPCS = {"brenna": brenna, "carto": carto, "ozias": ozias, "ilse": ilse, "nyx": nyx,
        "velaria": velaria, "preso": preso, "peregrina": peregrina}

if __name__ == "__main__":
    for name, fn in NPCS.items():
        sheet = Image.new("RGBA", (W * 3, H))
        for f in range(3):
            sheet.paste(outline(fn(f)), (f * W, 0))
        sheet.save(os.path.join(OUT, f"bust_{name}.png"))
    print("Bustos generados:", ", ".join(NPCS))

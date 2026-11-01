#!/usr/bin/env python3
"""SERAPHALL - hojas "indexadas" del protagonista para el creador de personaje.
Cada píxel guarda la PARTE (R = parte*12), el SOMBREADO (G = factor*128) y B = 1.
El juego (scripts/world/look.gd) las recolorea con la paleta elegida, quita las plumas
perdidas y dibuja el contorno en tiempo real.
Partes: 1 piel, 2 pelo, 3 ojos, 4 armadura, 5 piernas, 6 detalle, 7 capa, 8 ala, 9 aureola,
10-14 plumas ala izquierda, 15-19 plumas ala derecha, 20 pestañas/labios (detalle de cara)."""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "look")
os.makedirs(OUT, exist_ok=True)

def P(part, f=1.0):
    return (part * 12, max(0, min(255, int(128 * f))), 1, 255)

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def ell(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)

def sheet(rows):
    w, h = rows[0][0].size
    maxn = max(len(r) for r in rows)
    s = canvas(w * maxn, h * len(rows))
    for j, r in enumerate(rows):
        for i, f in enumerate(r):
            s.paste(f, (i * w, j * h), f)
    return s

def wing(d, cx, sh_y, side, flap, dark):
    x0 = cx - side * 2
    sf = 0.72 if dark else 1.0
    d.polygon([(x0, sh_y + 1), (x0 - side * 6, sh_y - 4 - flap), (x0 - side * 8, sh_y - flap // 2),
               (x0 - side * 5, sh_y + 5), (x0 - side, sh_y + 4)], fill=P(8, sf))
    base = 10 if side == -1 else 15
    for k in range(5):
        t = k / 4.0
        ax = x0 - side * round(7 - 3.5 * t)
        ay = sh_y - round(4 - 8 * t) - round(flap * (1 - t))
        ex = ax - side * round(3 - 1.2 * t)
        ey = ay + round(1 + 1.5 * t)
        d.line([(ax, ay), (ex, ey)], fill=P(base + k, sf * (1.05 - 0.08 * k)), width=1)
        d.point((ex, ey + 1), fill=P(base + k, sf * 0.8))

# ====================================================================== v0.5: protagonista detallado 32x32
FW, FH = 32, 32

class Px:
    def __init__(self, w, h):
        self.img = canvas(w, h)
        self.w, self.h = w, h
    def put(self, x, y, part, f=1.0):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), P(part, f) if part > 0 else (18, 14, 24, 255))
    def rect(self, x0, y0, x1, y1, part, f=1.0):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, part, f)
    def pattern(self, x0, y0, rows, cmap):
        for dy, r in enumerate(rows):
            for dx, ch in enumerate(r):
                if ch in cmap:
                    part, f = cmap[ch]
                    self.put(x0 + dx, y0 + dy, part, f)

# Cara (14 columnas desde x=8, filas desde y=3). Mira a la derecha.
FACE = [
    "..............",  # y3
    "..............",  # y4
    "......kSSSS...",  # y5
    ".....kSSSSSSS.",  # y6
    ".....SSSSSSSSS",  # y7
    ".....sSSSSSSSS",  # y8
    ".....sSSSSBBSS",  # y9  ceja
    ".....sSsSSWESS",  # y10 oreja + ojo (2x2, con brillo)
    ".....sSsSSEeSn",  # y11
    ".....ssSSSSSm.",  # y12 boca
    "......sssSSS..",  # y13
    "........sS....",  # y14 cuello
]
FACE_F = list(FACE)
FACE_F[6] = ".....sSSSSSBlS"   # ceja fina + pestaña
FACE_F[7] = ".....sSsSSWEeS"   # ojo más grande
FACE_F[8] = ".....sSsSpEeSn"   # ojo (2 filas) y rubor
FACE_HURT = ".....sSsSSBBSS"   # ojos cerrados de dolor
FACE_HURT2 = ".....sSsSSSSSn"  # fila de debajo con los ojos cerrados
FACE_MAP = {"S": (1, 1.0), "s": (1, 0.82), "k": (1, 1.12), "n": (1, 0.86), "W": (21, 1.0), "E": (3, 1.0), "e": (3, 0.6),
            "B": (2, 0.5), "l": (2, 0.35), "m": (20, 1.0), "p": (22, 1.0)}
HAIR_MAP = {"H": (2, 1.0), "h": (2, 0.74), "L": (2, 1.3), "D": (2, 0.52), "T": (6, 1.1)}

HAIRS = {
    ("m", 0): [  # corto peinado hacia delante
        "..............",
        "......DDDD....",
        "....DHHLLHD...",
        "...DHHLLLHHD..",
        "...DHHHHLHHHD.",
        "...DhHHHhHhHHD",
        "...DhHhh.h....",
        "...DhH........",
        "....Dh........",
        ".....D........",
    ],
    ("m", 1): [  # despeinado en punta
        ".....D..D.D...",
        "....DHDDHDHD..",
        "...DHLHHLHHD..",
        "..DHHLLHHLHHD.",
        "...DHHHHHHHLHD",
        "...DhHhHHhHHHD",
        "..DhHhh..h....",
        "...DhH........",
        "....Dh........",
        ".....D........",
    ],
    ("m", 2): [  # largo atado a la espalda
        "..............",
        "......DDDD....",
        "....DHHLLHD...",
        "...DHHLLLHHD..",
        "...DHHHHLHHHD.",
        "...DhHHHhHhHHD",
        "..DTDhh.h.....",
        "..DhD.........",
        "..DhD.........",
        "..DhhD........",
        "...DhD........",
        "...DhD........",
        "....D.........",
    ],
    ("f", 0): [  # melena larga
        "..............",
        "......DDDD....",
        "....DHHLLHDD..",
        "...DHHLLLHHHD.",
        "..DHHHHHLHHHHD",
        "..DHhHHHhHhHHD",
        "..DHhH.h......",
        "..DHhHh.......",
        "..DHhHh.......",
        "..DHhhH.......",
        "..DHhhD.......",
        "...DhhD.......",
        "...DhD........",
        "...DhD........",
        "....D.........",
    ],
    ("f", 1): [  # coleta alta
        "..DD..........",
        ".DLHDDDDD.....",
        ".DHTHHLLHD....",
        "DhHDHHLLLHD...",
        "DhD.DHHHHLHHD.",
        "DhD.DhHHHhHhHD",
        "DhD.DhH.h.....",
        ".DhD.Dh.......",
        ".DhD..........",
        "..DhD.........",
        "..DhD.........",
        "...D..........",
    ],
    ("f", 2): [  # media melena
        "..............",
        "......DDDD....",
        "....DHHLLHDD..",
        "...DHHLLLHHHD.",
        "..DHHHHHLHHHHD",
        "..DHhHHHhHhHHD",
        "..DHhH.h......",
        "..DHhHh.......",
        "..DhhHh.......",
        "...DhhD.......",
        "....DD........",
    ],
    ("f", 3): [  # dos trenzas (v0.8)
        "..............",
        "......DDDD....",
        "....DHHLLHDD..",
        "...DHHLLLHHHD.",
        "..DHHHHHLHHHHD",
        "..DHhHHHhHhHHD",
        "..DHhD.h.....D",
        "..DhD.......DH",
        "..DHD.......DH",
        "..DhD.......Dh",
        "..DHD........T",
        "..DTD.........",
        "...H..........",
    ],
    ("m", 3): [  # rapado (v0.8)
        "..............",
        "..............",
        ".....DDDDD....",
        "...DDhHhHhDD..",
        "...DhHLLHhHD..",
        "...DhHHhHHhD..",
        "...Dh.........",
        "....D.........",
    ],
}

def wing(c, root, side, flap, dark, feather_base):
    """Ala con brazo, membrana y 5 plumas (cada pluma es una parte que se puede perder)."""
    sf = 0.78 if dark else 1.0
    rx, ry = root
    tip = (rx + side * 9, ry - 6 - flap)
    # membrana
    for k in range(10):
        t = k / 9.0
        ax = rx + (tip[0] - rx) * t
        ay = ry + (tip[1] - ry) * t
        depth = int(2 + 2 * (1 - abs(t - 0.45) * 1.6))
        for d in range(depth):
            c.put(ax, ay + 1 + d, 8, sf * (0.82 - d * 0.04))
    # brazo del ala
    for k in range(11):
        t = k / 10.0
        ax = rx + (tip[0] - rx) * t
        ay = ry + (tip[1] - ry) * t
        c.put(ax, ay, 8, sf * 1.12)
        c.put(ax, ay - 1, 8, sf * 1.3 if t > 0.2 else sf * 1.0)
    # plumas (de la punta hacia el cuerpo)
    for k in range(5):
        t = 0.05 + k * 0.19
        ax = tip[0] + (rx - tip[0]) * t
        ay = tip[1] + (ry - tip[1]) * t + 1
        length = [6, 6, 5, 5, 4][k]
        part = feather_base + k
        for L in range(length):
            fx = ax + side * (0.45 * L) * (1.0 - k * 0.12)
            fy = ay + L
            c.put(fx, fy, part, sf * (1.05 - 0.03 * L))
            c.put(fx - side, fy, part, sf * 0.72)
        c.put(ax + side * (0.45 * length) * (1.0 - k * 0.12), ay + length, part, sf * 0.6)

def hero(body, hair, pose):
    c = Px(FW, FH)
    cx = 16
    bob = pose.get("bob", 0)
    flap = pose.get("flap", 0)
    sway = pose.get("cloak", 0)
    arm = pose.get("arm", 0)
    swing = pose.get("swing", 0)
    base = 30
    hip = 23
    sh = 15 + bob
    # ---- alas (detrás): la derecha en sombra, la izquierda delante
    if pose.get("wings", True):
        wing(c, (cx + 2, sh + 1), 1, flap, True, 15)
        wing(c, (cx - 3, sh + 1), -1, flap, False, 10)
    # ---- capa (por detrás del cuerpo)
    for y in range(sh + 1, base):
        k = (y - sh - 1) / float(base - sh - 2)
        back = int(round(cx - 4 - k * 3.5 + sway * k))
        for x in range(back, cx + 1):
            f = 0.85
            if x == back:
                f = 0.62
            elif (x - back) % 3 == 1 and k > 0.35:
                f = 0.7
            elif x == back + 1:
                f = 0.95
            c.put(x, y, 7, f)
        if y == base - 1:
            for x in range(back, cx):
                c.put(x, y, 6, 0.7)
    # ---- piernas y botas
    legs = ((-1, pose.get("l", 0), 0.74), (1, pose.get("r", 0), 1.0))
    for side, lx, f in legs:
        x0 = cx - 3 + lx if side < 0 else cx + 1 + lx
        for y in range(hip, base - 2):
            c.put(x0, y, 5, f)
            c.put(x0 + 1, y, 5, f * 0.82)
        c.put(x0, hip + 2, 5, f * 1.25)  # rodilla
        for y in range(base - 2, base + 1):
            c.put(x0, y, 5, 0.5 * (f + 0.2))
            c.put(x0 + 1, y, 5, 0.42 * (f + 0.2))
        c.put(x0 + 2, base, 5, 0.42)  # puntera
        c.put(x0, base - 2, 6, 0.75)  # vuelta de la bota
        c.put(x0 + 1, base - 2, 6, 0.6)
    # ---- brazo lejano
    if arm == 0:
        c.rect(cx - 5, sh + 2, cx - 4, sh + 5, 4, 0.55)
        c.put(cx - 5, sh + 6, 1, 0.7)
    # ---- torso
    if body == "m":
        for y in range(sh + 1, hip):
            for x in range(cx - 4, cx + 5):
                f = 1.0
                if x <= cx - 4:
                    f = 0.72
                elif x == cx - 3:
                    f = 1.18
                elif x >= cx + 3:
                    f = 0.78
                elif x >= cx + 1:
                    f = 0.9
                c.put(x, y, 4, f)
        c.rect(cx - 4, hip, cx + 4, hip, 4, 0.66)              # faldón corto
        c.put(cx - 2, hip, 4, 0.5); c.put(cx + 2, hip, 4, 0.5)
    else:
        for y in range(sh + 1, hip):
            narrow = 1 if y >= sh + 5 else 0
            for x in range(cx - 4 + narrow, cx + 4):
                f = 1.0
                if x <= cx - 4 + narrow:
                    f = 0.72
                elif x == cx - 3 + narrow:
                    f = 1.18
                elif x >= cx + 2:
                    f = 0.8
                c.put(x, y, 4, f)
        for y in range(hip - 1, hip + 3):                    # falda con pliegues
            w = y - (hip - 1)
            for x in range(cx - 4 - w, cx + 4 + w):
                f = 0.7 if (x - cx) % 3 == 0 else 0.92
                c.put(x, y, 4, f)
            if y == hip + 2:
                for x in range(cx - 4 - w, cx + 4 + w):
                    c.put(x, y, 6, 0.85)
    # cinturón y hebilla
    by = hip - 1 if body == "m" else hip - 2
    c.rect(cx - 4, by, cx + 4 if body == "m" else cx + 3, by, 6, 0.6)
    c.put(cx, by, 6, 1.45)
    # emblema del pecho
    c.put(cx, sh + 3, 6, 1.35); c.put(cx - 1, sh + 4, 6, 1.0); c.put(cx + 1, sh + 4, 6, 1.0); c.put(cx, sh + 5, 6, 0.8)
    # bufanda / cuello
    c.rect(cx - 3, sh, cx + 3, sh, 7, 1.18)
    c.rect(cx - 3, sh + 1, cx + 2, sh + 1, 7, 0.92)
    c.put(cx - 4, sh + 1, 7, 0.8); c.put(cx - 5 + sway, sh + 2, 7, 0.75); c.put(cx - 6 + sway, sh + 3, 7, 0.65)
    # hombrera delantera
    c.rect(cx + 2, sh, cx + 5, sh, 6, 1.25)
    c.rect(cx + 2, sh + 1, cx + 5, sh + 1, 6, 0.95)
    c.rect(cx + 3, sh + 2, cx + 5, sh + 2, 6, 0.7)
    # ---- brazo cercano
    if arm == 0:
        ax = (cx + 5 if body == "m" else cx + 4) + swing
        for y in range(sh + 2, sh + 6):
            c.put(ax - 1, y, 4, 0.55)                    # sombra entre brazo y cuerpo
            c.put(ax, y, 4, 1.0)
            c.put(ax + 1, y, 4, 0.78)
        c.rect(ax, sh + 6, ax + 1, sh + 7, 4, 0.58)      # guantelete
        c.put(ax, sh + 6, 6, 0.95)
        c.put(ax, sh + 8, 1, 1.0)                        # mano
        c.put(ax + 1, sh + 8, 1, 0.8)
    elif arm == 1:
        pts = [(cx + 3, sh + 1), (cx + 2, sh), (cx + 1, sh - 1), (cx, sh - 1), (cx - 1, sh - 2), (cx - 2, sh - 2)]
        for i, (x, y) in enumerate(pts):
            c.put(x, y, 4, 0.92 if i < 4 else 0.6)
            c.put(x, y + 1, 4, 0.75)
        c.put(cx - 3, sh - 3, 1, 1.0)
    else:
        for x in range(cx + 4, cx + 10):
            c.put(x, sh + 2, 4, 0.95 if x < cx + 8 else 0.6)
            c.put(x, sh + 3, 4, 0.75 if x < cx + 8 else 0.5)
        c.put(cx + 7, sh + 2, 6, 0.9)
        c.put(cx + 10, sh + 2, 1, 1.0); c.put(cx + 10, sh + 3, 1, 0.85)
    # ---- cabeza
    face = list(FACE_F if body == "f" else FACE)
    if pose.get("hurt"):
        face[7] = FACE_HURT
        face[8] = FACE_HURT2
    c.pattern(8, 2 + bob, face, FACE_MAP)
    c.pattern(8, 2 + bob, HAIRS[(body, hair)], HAIR_MAP)
    # ---- aureola (sin contorno en el juego)
    if not pose.get("halo", True):
        return c.img
    hy = bob
    for x in range(cx - 3, cx + 4):
        c.put(x, hy, 9, 1.0 if x not in (cx - 2, cx - 1) else 1.35)
        c.put(x, hy + 2, 9, 0.7)
    c.put(cx - 4, hy + 1, 9, 0.9); c.put(cx + 4, hy + 1, 9, 0.9)
    return c.img

def anim(body, hair):
    rows = []
    rows.append([hero(body, hair, {"bob": [0, 0, 1, 1][i], "flap": [0, 1, 2, 1][i], "cloak": [0, 0, 1, 1][i]}) for i in range(4)])
    cyc = [(-2, 2), (-1, 1), (1, -1), (2, -2), (1, -1), (-1, 1)]
    rows.append([hero(body, hair, {"l": cyc[i][0], "r": cyc[i][1], "bob": [0, 1, 0, 0, 1, 0][i], "flap": i % 3, "cloak": -2 + (i % 2),
                                   "swing": [1, 0, -1, -1, 0, 1][i]}) for i in range(6)])
    rows.append([hero(body, hair, {"arm": a, "l": l, "r": -l, "flap": f}) for a, l, f in ((1, -1, 0), (2, 2, 3), (2, 1, 1))])
    hurt = hero(body, hair, {"bob": 1, "flap": 3, "hurt": True})
    dead = hero(body, hair, {"bob": 1}).rotate(90, expand=False, resample=Image.NEAREST)
    rows.append([hurt, dead])
    return sheet(rows)

def back(body, hair):
    """Vista de espaldas para las cinemáticas de jefe (30x40)."""
    W, H = 30, 40
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx = W // 2
    d.polygon([(cx - 3, 14), (cx - 13, 6), (cx - 14, 18), (cx - 6, 22)], fill=P(8))
    d.polygon([(cx + 3, 14), (cx + 13, 6), (cx + 14, 18), (cx + 6, 22)], fill=P(8, 0.85))
    for k in range(5):
        d.line([(cx - 12 + k, 8 + k * 2), (cx - 15 + k, 12 + k * 2)], fill=P(10 + k))
        d.line([(cx + 12 - k, 8 + k * 2), (cx + 15 - k, 12 + k * 2)], fill=P(15 + k, 0.85))
    w = 7 if body == "m" else 6
    d.polygon([(cx - w, 14), (cx + w, 14), (cx + 9, 36), (cx - 9, 36)], fill=P(7))
    d.line([(cx, 15), (cx, 35)], fill=P(7, 0.8))
    d.line([(cx - 8, 34), (cx + 8, 34)], fill=P(6, 0.9))
    d.rectangle([cx - 5, 35, cx - 2, 39], fill=P(5)); d.rectangle([cx + 2, 35, cx + 5, 39], fill=P(5))
    ell(d, cx, 9, 5, 5.5, P(2))
    if body == "f" and hair == 0:
        d.rectangle([cx - 5, 9, cx + 5, 19], fill=P(2, 0.9))
    elif body == "f" and hair == 1:
        d.polygon([(cx - 2, 4), (cx + 2, 4), (cx + 2, 17), (cx, 20), (cx - 2, 17)], fill=P(2, 0.85))
    elif body == "f":
        d.rectangle([cx - 5, 9, cx + 5, 14], fill=P(2, 0.9))
    elif hair == 1:
        for x in range(cx - 4, cx + 5, 2):
            d.point((x, 3), fill=P(2, 1.1))
    elif hair == 2:
        d.line([(cx, 12), (cx, 19)], fill=P(2, 0.85), width=2)
    if body == "f" and hair == 3:
        for sx in (-4, 4):
            d.line([(cx + sx, 10), (cx + sx, 20)], fill=P(2, 0.85), width=2)
            d.point((cx + sx, 21), fill=P(6, 1.0))
    d.ellipse([cx - 5, 0, cx + 5, 3], outline=P(9))
    d.line([(cx + 9, 18), (cx + 13, 38)], fill=(224, 228, 240, 255), width=2)
    return img

# ====================================================================== v0.7: retrato del HUD (busto 40x40)
BW_, BH_ = 40, 40
EXPRS = ["neutral", "blink", "hurt", "strain", "smile", "fierce"]

def bust(body, hair, expr):
    """Busto de 3/4 mirando a la derecha para el medallón del HUD. Mismas partes recoloreables."""
    img = canvas(BW_, BH_); d = ImageDraw.Draw(img)
    fem = body == "f"
    # ---- alas asomando detrás de los hombros
    d.polygon([(10, 30), (1, 18), (0, 24), (2, 33), (7, 39), (12, 39)], fill=P(8, 0.85))
    for k in range(4):
        d.line([(2 + k, 20 + k * 4), (8 + k, 26 + k * 3)], fill=P(10 + k, 0.7))
    d.polygon([(31, 31), (38, 20), (39, 27), (36, 39), (31, 39)], fill=P(8, 0.68))
    for k in range(3):
        d.line([(37 - k, 23 + k * 4), (33 - k, 28 + k * 3)], fill=P(15 + k, 0.55))
    # ---- pelo largo por detrás (melena y coleta baja)
    if fem and hair == 0:
        d.polygon([(10, 10), (6, 22), (5, 36), (12, 39), (17, 30), (16, 14)], fill=P(2, 0.62))
        d.polygon([(27, 14), (31, 16), (32, 30), (29, 34), (28, 24)], fill=P(2, 0.7))
    if fem and hair == 1:
        d.polygon([(9, 6), (4, 3), (2, 8), (3, 18), (6, 28), (9, 31), (11, 22), (12, 10)], fill=P(2, 0.78))
        d.line([(4, 5), (4, 17)], fill=P(2, 1.15))
    if not fem and hair == 2:
        d.polygon([(11, 16), (8, 22), (7, 33), (10, 36), (13, 28), (14, 19)], fill=P(2, 0.66))
        d.rectangle([9, 21, 12, 22], fill=P(6, 1.0))
    if fem and hair == 3:
        for k in range(5):                                                               # trenza trasera
            d.ellipse([7 + (k % 2), 14 + k * 4, 12 + (k % 2), 19 + k * 4], fill=P(2, 0.62 + 0.06 * (k % 2)))
        d.rectangle([8, 33, 11, 34], fill=P(6, 1.0))
    # ---- hombros y armadura
    d.polygon([(7, 39), (9, 33), (14, 30), (28, 30), (33, 33), (35, 39)], fill=P(4, 0.95))
    d.polygon([(7, 39), (9, 33), (14, 30), (17, 30), (15, 39)], fill=P(4, 0.72))
    d.line([(15, 32), (27, 32)], fill=P(4, 1.25))
    d.polygon([(21, 33), (23, 35), (21, 37), (19, 35)], fill=P(6, 1.25))          # emblema
    d.point((21, 35), fill=P(6, 1.6))
    d.ellipse([25, 29, 35, 36], fill=P(6, 1.05))                                    # hombrera delantera
    d.line([(26, 30), (33, 30)], fill=P(6, 1.45))
    d.ellipse([7, 30, 14, 35], fill=P(6, 0.7))
    # ---- cuello y bufanda
    d.rectangle([18, 23, 24, 29], fill=P(1, 0.8))
    d.line([(18, 26), (24, 26)], fill=P(1, 0.66))
    d.polygon([(13, 29), (16, 26), (27, 26), (29, 29), (27, 31), (15, 31)], fill=P(7, 1.0))
    d.line([(16, 27), (27, 27)], fill=P(7, 1.3))
    d.polygon([(14, 30), (11, 35), (13, 37), (17, 31)], fill=P(7, 0.78))            # punta de la bufanda
    # ---- cabeza
    d.ellipse([12, 4, 30, 25], fill=P(1, 1.0))
    d.polygon([(13, 17), (21, 27), (28, 22), (30, 15)], fill=P(1, 1.0))             # mandíbula
    d.polygon([(13, 10), (12, 18), (15, 23), (16, 12)], fill=P(1, 0.82))            # lado en sombra
    d.ellipse([12, 13, 15, 18], fill=P(1, 0.86))                                     # oreja
    d.point((13, 15), fill=P(1, 0.7))
    d.line([(29, 12), (30, 16)], fill=P(1, 1.12))                                    # luz en la mejilla
    d.point((30, 18), fill=P(1, 0.82)); d.point((30, 19), fill=P(1, 0.86))          # nariz
    d.point((31, 18), fill=P(1, 1.0))
    # ---- ojos
    def eye(x0, w, far):
        if expr == "blink":
            d.line([(x0, 16), (x0 + w, 16)], fill=P(2, 0.4)); return
        if expr == "smile":
            d.line([(x0, 16), (x0 + 1, 15)], fill=P(2, 0.4)); d.line([(x0 + 1, 15), (x0 + w, 16)], fill=P(2, 0.4)); return
        if expr == "hurt":
            d.line([(x0, 14), (x0 + w, 16)], fill=P(2, 0.4)); d.line([(x0, 18), (x0 + w, 16)], fill=P(2, 0.4)); return
        top = 15 if expr in ("fierce", "strain") else 14
        d.rectangle([x0, top, x0 + w, 17], fill=P(21, 1.0))
        ix = x0 + w - 2 if not far else x0 + w - 1
        glow = 1.4 if expr == "fierce" else 1.0
        d.rectangle([ix, top, ix + 1, 17], fill=P(3, glow))
        d.point((ix, 17), fill=P(3, 0.6))
        if expr != "fierce":
            d.point((ix + 1, top), fill=P(21, 1.0))                                  # brillo
        d.line([(x0 - (1 if not far else 0), top - 1), (x0 + w + (1 if fem and not far else 0), top - 1)], fill=P(2, 0.35))   # pestañas
        if fem and not far:
            d.point((x0 + w + 1, top), fill=P(2, 0.35))
    eye(23, 4, False)
    eye(16, 2, True)
    # ---- cejas según la expresión
    if expr in ("strain", "fierce"):
        d.line([(23, 11), (27, 12)], fill=P(2, 0.5)); d.line([(16, 12), (18, 11)], fill=P(2, 0.5))
    elif expr == "hurt":
        d.line([(23, 12), (27, 10)], fill=P(2, 0.5)); d.line([(16, 10), (18, 12)], fill=P(2, 0.5))
    else:
        d.line([(23, 11), (27, 11)], fill=P(2, 0.5)); d.line([(16, 11), (18, 11)], fill=P(2, 0.5))
    # ---- boca
    if expr == "smile":
        d.line([(24, 21), (25, 22)], fill=P(20, 1.0)); d.line([(25, 22), (27, 21)], fill=P(20, 1.0))
    elif expr == "hurt":
        d.rectangle([24, 21, 26, 23], fill=P(20, 1.0)); d.point((25, 23), fill=P(22, 1.0))
    elif expr == "strain":
        d.rectangle([23, 21, 27, 22], fill=P(21, 1.0)); d.line([(23, 21), (27, 21)], fill=P(20, 1.0)); d.line([(25, 21), (25, 22)], fill=P(20, 0.8))
    elif expr == "fierce":
        d.line([(24, 22), (27, 21)], fill=P(20, 1.0))
    else:
        d.line([(24, 22), (26, 22)], fill=P(20, 1.0))
    # ---- rubor
    if fem or expr in ("smile", "hurt"):
        d.point((26, 19), fill=P(22, 1.0)); d.point((27, 19), fill=P(22, 1.0)); d.point((17, 19), fill=P(22, 1.0))
    # ---- sudor con poca vida
    if expr == "strain":
        d.point((29, 9), fill=P(21, 1.0)); d.point((29, 10), fill=P(21, 0.85)); d.point((30, 10), fill=P(21, 0.7))
    # ---- pelo delantero (casquete y flequillo)
    d.chord([11, 2, 31, 20], 180, 360, fill=P(2, 1.0))
    d.polygon([(11, 11), (11, 18), (14, 22), (16, 12)], fill=P(2, 0.8))               # patilla / lado
    fringe = {("m", 0): [(15, 8), (18, 13), (20, 9), (23, 12), (25, 9), (28, 12), (30, 9), (31, 7)],
              ("m", 1): [(14, 8), (17, 14), (19, 8), (22, 13), (24, 8), (27, 13), (29, 8), (32, 10)],
              ("m", 2): [(15, 8), (19, 12), (21, 9), (25, 12), (27, 9), (30, 11), (31, 7)],
              ("f", 0): [(14, 8), (17, 14), (20, 9), (22, 13), (24, 9), (27, 12), (30, 10), (31, 13), (31, 7)],
              ("f", 1): [(15, 8), (18, 12), (21, 9), (24, 12), (27, 9), (30, 12), (31, 7)],
              ("f", 2): [(14, 8), (16, 13), (19, 9), (22, 13), (25, 9), (28, 13), (31, 11), (32, 15), (31, 7)],
              ("f", 3): [(14, 8), (17, 12), (20, 9), (23, 12), (26, 9), (29, 12), (31, 10), (31, 7)],
              ("m", 3): [(15, 6), (18, 8), (21, 6), (24, 8), (27, 6), (30, 7), (31, 5)]}[(body, hair)]
    d.polygon([(12, 8)] + fringe + [(30, 4), (21, 2), (13, 4)], fill=P(2, 1.0))
    d.arc([12, 2, 30, 18], 200, 290, fill=P(2, 1.32))                                # brillo
    d.line([(22, 3), (27, 5)], fill=P(2, 1.25))
    if hair == 1 and not fem:
        for x, y in ((13, 3), (17, 0), (21, 1), (25, 0), (29, 3)):                    # puntas
            d.polygon([(x - 2, y + 4), (x, y), (x + 2, y + 4)], fill=P(2, 1.05))
    if fem and hair == 2:
        d.polygon([(11, 10), (10, 24), (14, 25), (15, 13)], fill=P(2, 0.9))
        d.polygon([(30, 12), (32, 22), (29, 23), (29, 15)], fill=P(2, 0.95))
    if fem and hair == 0:
        d.polygon([(11, 10), (9, 26), (13, 30), (15, 14)], fill=P(2, 0.9))
        d.polygon([(30, 11), (32, 24), (30, 28), (29, 16)], fill=P(2, 0.95))
    if fem and hair == 1:
        d.ellipse([8, 4, 13, 9], fill=P(6, 1.0))                                      # lazo de la coleta
    if fem and hair == 3:
        for k in range(5):                                                           # trenza delantera
            d.ellipse([28 - (k % 2), 12 + k * 4, 33 - (k % 2), 17 + k * 4], fill=P(2, 0.92 + 0.08 * (k % 2)))
        d.rectangle([29, 31, 32, 32], fill=P(6, 1.1))
    # ---- aureola (anillo flotante, sin contorno en el juego)
    d.ellipse([13, 0, 29, 3], outline=P(9, 1.0))
    d.point((15, 0), fill=P(9, 1.4)); d.point((16, 0), fill=P(9, 1.4))
    return img

def bust_sheet(body, hair):
    s = canvas(BW_ * len(EXPRS), BH_)
    for i, e in enumerate(EXPRS):
        f = bust(body, hair, e)
        s.paste(f, (i * BW_, 0), f)
    return s

if __name__ == "__main__":
    for body in ("f", "m"):
        for hair in range(4):
            bust_sheet(body, hair).save(f"{OUT}/bu_{body}{hair}.png")
    for body in ("f", "m"):
        for hair in range(4):
            anim(body, hair).save(f"{OUT}/pl_{body}{hair}.png")
            back(body, hair).save(f"{OUT}/pb_{body}{hair}.png")
    print("Hojas de aspecto generadas en", OUT)

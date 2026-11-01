#!/usr/bin/env python3
"""SERAPHALL v0.8 - arte de las batallas secretas.
- weapon_verdugo.png (32x12): la Hoja del Verdugo, recompensa del duelo del Cadalso.
- coloso_head.png / coloso_body.png / coloso_hand.png: el Coloso del Abismo (piedra, runas cian, aureola rota).
Uso: python3 tools/gen_secret.py"""
import os, math
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
INK = (16, 10, 24, 255)
rng = np.random.default_rng(7)


def C(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def outline(img):
    w, h = img.size
    px = img.load(); out = img.copy(); po = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 128:
                        po[x, y] = INK
                        break
    return out


# ------------------------------------------------------------------ Hoja del Verdugo
def weapon_verdugo():
    img = Image.new("RGBA", (32, 12)); d = ImageDraw.Draw(img); y = 6
    d.rectangle([0, y - 1, 4, y], fill=C("3a2430"))                     # empuñadura envuelta
    d.point((1, y - 1), fill=C("6a4450")); d.point((3, y), fill=C("6a4450"))
    d.rectangle([5, y - 4, 6, y + 3], fill=C("d0a040"))                 # guarda de oro
    d.point((5, y - 4), fill=C("fff0a0"))
    d.polygon([(7, y - 3), (26, y - 3), (29, y - 2), (29, y + 2), (7, y + 2)], fill=C("4a4458"))   # hoja ancha y roma
    d.line([(7, y - 3), (26, y - 3)], fill=C("9a94b0"))
    d.line([(8, y + 2), (28, y + 2)], fill=C("2a2434"))
    for x in (11, 16, 21):                                               # runas carmesí
        d.point((x, y - 1), fill=C("ff3050")); d.point((x + 1, y), fill=C("ff3050"))
    d.rectangle([26, y - 1, 27, y], fill=C("1a1420"))                    # agujero del verdugo
    return outline(img)


# ------------------------------------------------------------------ Coloso: utilidades de piedra
STONE = np.array([0x5a, 0x54, 0x6a]); STONE_L = np.array([0x8e, 0x88, 0xa4]); STONE_D = np.array([0x2e, 0x2a, 0x3a])
GLOW = (143, 240, 255, 255); GLOW_D = (60, 150, 200, 255)


def stone_fill(mask, light_dir=(-0.6, -0.8), seed=0, bands=True):
    """Rellena una máscara con piedra sombreada: luz desde arriba-izquierda, ruido y vetas."""
    h, w = mask.shape
    r = np.random.default_rng(seed)
    ys, xs = np.mgrid[0:h, 0:w]
    # distancia al borde para un falso relieve
    from scipy.ndimage import distance_transform_edt, sobel
    dist = distance_transform_edt(mask)
    height = np.sqrt(np.clip(dist, 0, 12) / 12.0)
    gx = sobel(height, axis=1); gy = sobel(height, axis=0)
    shade = -(gx * light_dir[0] + gy * light_dir[1]) * 1.6
    noise = r.normal(0, 0.035, (h, w))
    coarse = np.kron(r.normal(0, 0.1, (h // 6 + 1, w // 6 + 1)), np.ones((6, 6)))[:h, :w]
    v = 0.5 + shade + noise + coarse
    v = np.clip(v, 0, 1)
    # cuantizar en 4 tonos (pixel art)
    q = np.digitize(v, [0.32, 0.5, 0.7])
    pal = [STONE_D, STONE * 0.85 + STONE_D * 0.15, STONE, STONE_L]
    img = np.zeros((h, w, 4), dtype=np.uint8)
    for i, c in enumerate(pal):
        m = (q == i) & mask
        img[m, :3] = np.clip(c, 0, 255)
        img[m, 3] = 255
    return img


def cracks(d, n, box, seed, col=C("1e1a28")):
    r = np.random.default_rng(seed)
    x0, y0, x1, y1 = box
    for _ in range(n):
        x = r.integers(x0, x1); y = r.integers(y0, y1)
        for _ in range(r.integers(4, 9)):
            nx = x + r.integers(-3, 4); ny = y + r.integers(0, 4)
            d.line([(x, y), (nx, ny)], fill=col)
            x, y = nx, ny


def coloso_head():
    W, H = 96, 88
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    # yelmo-rostro: frente ancha, pómulos y mandíbula cuadrada
    d.polygon([(22, 22), (34, 12), (62, 12), (74, 22), (78, 44), (72, 62), (62, 74), (34, 74), (24, 62), (18, 44)], fill=255)
    d.polygon([(30, 70), (66, 70), (60, 84), (36, 84)], fill=255)       # mandíbula
    d.polygon([(14, 34), (22, 30), (22, 52), (14, 50)], fill=255)        # orejeras
    d.polygon([(82, 34), (74, 30), (74, 52), (82, 50)], fill=255)
    mask = np.array(m) > 0
    arr = stone_fill(mask, seed=3)
    img = Image.fromarray(arr, "RGBA"); dd = ImageDraw.Draw(img)
    # aureola rota sobre la cabeza (fragmentos de anillo dorado ennegrecido)
    for a0, a1 in ((200, 250), (262, 300), (312, 344)):
        dd.arc([18, 0, 78, 22], a0, a1, fill=C("b8a060"), width=3)
        dd.arc([18, 0, 78, 22], a0, a1, fill=C("e8d890"), width=1)
    # cuencas profundas y ojos que brillan
    for ex in (36, 60):
        dd.polygon([(ex - 9, 38), (ex + 9, 36), (ex + 8, 46), (ex - 8, 47)], fill=C("120e1a"))
        dd.ellipse([ex - 4, 39, ex + 4, 45], fill=GLOW_D)
        dd.ellipse([ex - 2, 40, ex + 2, 44], fill=GLOW)
        dd.point((ex - 1, 41), fill=(255, 255, 255, 255))
    # nariz y boca (una grieta)
    dd.line([(48, 46), (46, 58), (50, 59)], fill=C("2a2434"))
    dd.line([(38, 66), (48, 68), (58, 66)], fill=C("120e1a"), width=2)
    # runas en la frente
    for i, x in enumerate((40, 48, 56)):
        dd.line([(x, 20), (x, 26)], fill=GLOW_D)
        dd.point((x + (1 if i % 2 else -1), 22), fill=GLOW)
    cracks(dd, 6, (22, 16, 74, 70), 11)
    # musgo/liquen
    for _ in range(40):
        x = rng.integers(20, 76); y = rng.integers(14, 80)
        if mask[y, x]:
            dd.point((int(x), int(y)), fill=C("5a7a5a") if rng.random() < 0.6 else C("7a9a6a"))
    return outline(img)


def coloso_body():
    W, H = 200, 112
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    # hombreras enormes y pecho; la parte baja se pierde en el abismo
    d.ellipse([0, 8, 70, 70], fill=255)
    d.ellipse([130, 8, 200, 70], fill=255)
    d.polygon([(40, 20), (160, 20), (176, 60), (164, 112), (36, 112), (24, 60)], fill=255)
    mask = np.array(m) > 0
    arr = stone_fill(mask, seed=5)
    # se desvanece hacia abajo (sale de la niebla del abismo)
    for y in range(H):
        k = np.clip((H - y) / 46.0, 0, 1)
        arr[y, :, 3] = (arr[y, :, 3] * k).astype(np.uint8)
        arr[y, :, :3] = (arr[y, :, :3] * (0.55 + 0.45 * k)).astype(np.uint8)
    img = Image.fromarray(arr, "RGBA"); dd = ImageDraw.Draw(img)
    # bordes de las hombreras
    dd.arc([0, 8, 70, 70], 180, 330, fill=C("a8a2bc"), width=2)
    dd.arc([130, 8, 200, 70], 210, 360, fill=C("a8a2bc"), width=2)
    # hueco del núcleo en el pecho (el núcleo se dibuja aparte y late)
    dd.ellipse([86, 40, 114, 66], fill=C("120e1a"))
    dd.ellipse([84, 38, 116, 68], outline=C("b8a060"), width=2)
    # cadenas rotas cruzando el pecho
    for i in range(14):
        x = 44 + i * 8; y = 30 + int(abs(i - 6.5) * 2.2)
        dd.ellipse([x, y, x + 6, y + 4], outline=C("3a3644"), width=2)
        dd.point((x + 2, y), fill=C("8a8698"))
    # runas que recorren los hombros
    for cx, cy in ((34, 34), (166, 34)):
        for k in range(5):
            a = math.pi * (0.9 + k * 0.28)
            px = cx + math.cos(a) * 22; py = cy + math.sin(a) * 18
            dd.rectangle([px, py, px + 1, py + 2], fill=GLOW_D)
    cracks(dd, 10, (20, 14, 180, 80), 21)
    return outline(img)


def coloso_hand():
    W, H = 72, 60
    m = Image.new("L", (W, H)); d = ImageDraw.Draw(m)
    # puño visto desde arriba: muñeca arriba, nudillos abajo, pulgar a un lado
    d.rectangle([22, 0, 50, 16], fill=255)                               # muñeca
    d.polygon([(12, 14), (60, 14), (66, 30), (64, 48), (8, 48), (6, 30)], fill=255)
    for i in range(4):                                                   # nudillos/dedos
        x = 9 + i * 14
        d.rounded_rectangle([x, 40, x + 13, 58], 4, fill=255)
    d.polygon([(60, 20), (70, 26), (68, 40), (60, 38)], fill=255)        # pulgar
    mask = np.array(m) > 0
    arr = stone_fill(mask, seed=9)
    img = Image.fromarray(arr, "RGBA"); dd = ImageDraw.Draw(img)
    for i in range(1, 4):
        x = 9 + i * 14
        dd.line([(x, 42), (x, 57)], fill=C("1e1a28"))
    for i in range(4):
        x = 9 + i * 14
        dd.line([(x + 3, 46), (x + 10, 46)], fill=C("a8a2bc"))
    # runa del dorso (es el punto débil: brilla cuando la mano descansa)
    dd.polygon([(36, 22), (42, 28), (36, 34), (30, 28)], outline=GLOW_D)
    dd.point((36, 28), fill=GLOW)
    dd.line([(36, 18), (36, 22)], fill=GLOW_D); dd.line([(36, 34), (36, 38)], fill=GLOW_D)
    cracks(dd, 4, (12, 14, 62, 44), 31)
    # grillete de la muñeca
    dd.rectangle([20, 6, 52, 11], fill=C("3a3644")); dd.line([(20, 6), (52, 6)], fill=C("8a8698"))
    return outline(img)


if __name__ == "__main__":
    weapon_verdugo().save(f"{OUT}/weapon_verdugo.png")
    cine = os.path.join(OUT, "cinematic")
    coloso_head().save(f"{cine}/coloso_head.png")
    coloso_body().save(f"{cine}/coloso_body.png")
    coloso_hand().save(f"{cine}/coloso_hand.png")
    print("ok")

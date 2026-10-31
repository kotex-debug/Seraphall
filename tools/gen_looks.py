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

def hero(W, H, body, hair, pose):
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    cx = W // 2
    bob = pose.get("bob", 0)
    base = H - 2
    hip_y = base - 5
    sh_y = hip_y - 7 + bob
    head_y = sh_y - 3
    flap = pose.get("flap", 0)
    # alas (detrás): izquierda clara, derecha en sombra
    wing(d, cx, sh_y, 1, flap, True)
    wing(d, cx, sh_y, -1, flap, False)
    # pelo largo por detrás (melena / coleta)
    if body == "f" and hair == 0:  # melena larga
        d.rectangle([cx - 4, head_y - 1, cx + 3, sh_y + 4], fill=P(2, 0.8))
    if body == "f" and hair == 1:  # coleta alta que se balancea
        sw = pose.get("cloak", 0)
        d.polygon([(cx - 3, head_y - 3), (cx - 6 + sw, head_y - 1), (cx - 7 + sw, sh_y + 3), (cx - 5 + sw, sh_y + 4), (cx - 3, head_y + 1)], fill=P(2, 0.85))
    if body == "m" and hair == 2:  # pelo largo atado
        d.line([(cx - 3, head_y), (cx - 4, sh_y + 4)], fill=P(2, 0.8), width=2)
    # capa
    cl = pose.get("cloak", 0)
    d.polygon([(cx - 3, sh_y + 1), (cx + 3, sh_y + 1), (cx + 4 + cl, base - 1), (cx - 5 + cl, base - 1)], fill=P(7, 0.8))
    d.line([(cx - 4 + cl, base - 2), (cx + 3 + cl, base - 2)], fill=P(6, 0.9))
    # piernas
    for off, lx in ((-1, pose.get("l", 0)), (1, pose.get("r", 0))):
        x = cx + off * 1 + (0 if off == -1 else 1) + lx
        d.rectangle([x - 1, hip_y + bob // 2, x, base], fill=P(5, 1.0 if off == -1 else 0.8))
        d.rectangle([x - 1, base - 1, x + 1, base], fill=P(5, 0.55))
    # torso: chico hombros anchos con hombreras; chica cintura y faldón
    if body == "m":
        d.rectangle([cx - 3, sh_y, cx + 3, hip_y + bob // 2], fill=P(4))
        d.rectangle([cx + 1, sh_y + 1, cx + 3, hip_y + bob // 2], fill=P(4, 0.78))
        d.rectangle([cx - 4, sh_y, cx - 3, sh_y + 1], fill=P(6))
        d.rectangle([cx + 3, sh_y, cx + 4, sh_y + 1], fill=P(6, 0.8))
    else:
        d.rectangle([cx - 3, sh_y, cx + 2, hip_y - 1 + bob // 2], fill=P(4))
        d.rectangle([cx + 1, sh_y + 1, cx + 2, hip_y - 1 + bob // 2], fill=P(4, 0.78))
        d.polygon([(cx - 3, hip_y - 1 + bob // 2), (cx + 2, hip_y - 1 + bob // 2), (cx + 4, hip_y + 2 + bob // 2), (cx - 5, hip_y + 2 + bob // 2)], fill=P(4, 0.9))
        d.point((cx - 1, sh_y + 2), fill=P(6))
    d.line([(cx - 3, hip_y - 1 + bob // 2), (cx + 3 if body == "m" else cx + 2, hip_y - 1 + bob // 2)], fill=P(6))
    d.point((cx - 1, sh_y + 2), fill=P(4, 1.25))
    # brazo
    arm = pose.get("arm", 0)
    if arm == 0:
        d.rectangle([cx + 2, sh_y + 1, cx + 3, sh_y + 5], fill=P(4, 0.9))
    elif arm == 1:
        d.rectangle([cx - 4, sh_y, cx - 2, sh_y + 3], fill=P(4, 0.9))
    else:
        d.rectangle([cx + 2, sh_y + 1, cx + 6, sh_y + 2], fill=P(4, 0.9))
    # cabeza
    ell(d, cx, head_y, 3.5, 3.5, P(1))
    ell(d, cx - 0.5, head_y - 1.2, 3.5, 2.2, P(2))
    if hair == 0 and body == "m":     # corto
        d.rectangle([cx - 3, head_y - 1, cx - 2, head_y + 2], fill=P(2))
    elif hair == 1 and body == "m":   # despeinado
        for x, y in ((cx - 3, head_y - 4), (cx - 1, head_y - 5), (cx + 1, head_y - 4), (cx + 3, head_y - 3)):
            d.point((x, y), fill=P(2, 1.15))
        d.rectangle([cx - 3, head_y - 1, cx - 2, head_y + 2], fill=P(2))
        d.point((cx + 2, head_y - 1), fill=P(2, 0.9))
    elif hair == 2 and body == "m":   # largo atado
        d.rectangle([cx - 3, head_y - 1, cx - 2, head_y + 2], fill=P(2))
    elif body == "f" and hair == 0:   # melena larga: mechón delantero
        d.rectangle([cx - 4, head_y - 1, cx - 2, head_y + 4], fill=P(2))
        d.line([(cx + 3, head_y - 1), (cx + 3, head_y + 3)], fill=P(2, 0.9))
    elif body == "f" and hair == 1:   # coleta: flequillo
        d.rectangle([cx - 3, head_y - 1, cx - 2, head_y + 1], fill=P(2))
        d.point((cx + 2, head_y - 1), fill=P(2, 1.1))
    else:                              # media melena (bob)
        d.rectangle([cx - 4, head_y - 1, cx - 2, head_y + 3], fill=P(2))
        d.rectangle([cx + 2, head_y, cx + 3, head_y + 3], fill=P(2, 0.9))
    d.point((cx + 1, int(head_y)), fill=P(3))
    if body == "f":
        d.point((cx + 2, int(head_y) - 1), fill=P(20, 0.6))  # pestaña
    # aureola (sin contorno)
    hy = int(head_y - 3.5 - 2)
    d.ellipse([cx - 3, hy - 1, cx + 3, hy + 1], outline=P(9))
    return img

def anim(body, hair):
    W, H = 24, 26
    rows = []
    rows.append([hero(W, H, body, hair, {"bob": [0, 0, 1, 1][i], "flap": [0, 1, 2, 1][i]}) for i in range(4)])
    cyc = [(-2, 2), (-1, 1), (1, -1), (2, -2), (1, -1), (-1, 1)]
    rows.append([hero(W, H, body, hair, {"l": cyc[i][0], "r": cyc[i][1], "bob": [0, 1, 0, 0, 1, 0][i], "flap": i % 3, "cloak": -1}) for i in range(6)])
    rows.append([hero(W, H, body, hair, {"arm": a, "l": l, "r": -l, "flap": f}) for a, l, f in ((1, -1, 0), (2, 2, 3), (2, 1, 1))])
    hurt = hero(W, H, body, hair, {"bob": 1, "flap": 3})
    dead = hero(W, H, body, hair, {"bob": 2}).rotate(90, expand=False, resample=Image.NEAREST)
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
    d.ellipse([cx - 5, 0, cx + 5, 3], outline=P(9))
    d.line([(cx + 9, 18), (cx + 13, 38)], fill=(224, 228, 240, 255), width=2)
    return img

for body in ("f", "m"):
    for hair in range(3):
        anim(body, hair).save(f"{OUT}/pl_{body}{hair}.png")
        back(body, hair).save(f"{OUT}/pb_{body}{hair}.png")
print("Hojas de aspecto generadas en", OUT)

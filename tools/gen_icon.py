#!/usr/bin/env python3
"""SERAPHALL - icono de la aplicación (pixel art).
Un serafín caído: espada que desciende al vórtice, un ala entera y otra a la que le faltan plumas,
y la aureola rota encima. Se dibuja a 64x64 y se escala sin suavizado; para 16 y 32 px hay una
versión simplificada para que se lea bien en la barra de tareas.
Uso: python3 tools/gen_icon.py  (escribe icon.png, icon.ico y assets/sprites/app_icon.png)"""
import math, os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..")
INK = (18, 10, 24, 255)

def C(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def outline(img, col=INK):
    src = img.load(); w, h = img.size
    out = img.copy(); o = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0 and src[nx, ny][:3] != INK[:3]:
                    o[x, y] = col
                    break
    return out

def background(S):
    """Losa redondeada con el vórtice ardiente del título."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    p = img.load()
    cx, cy = S / 2 - 0.5, S * 0.62
    r_out = S * 0.47
    for y in range(S):
        for x in range(S):
            # esquinas redondeadas
            rx = min(x, S - 1 - x); ry = min(y, S - 1 - y); rad = S * 0.18
            if rx < rad and ry < rad and math.hypot(rad - rx, rad - ry) > rad:
                continue
            d = math.hypot(x - cx, (y - cy) * 1.35) / r_out
            a = math.atan2(y - cy, x - cx)
            swirl = 0.5 + 0.5 * math.sin(a * 3 + d * 9.0)
            t = min(1.0, d)
            # centro: brasa; borde: púrpura del abismo
            c0 = (255, 196, 110); c1 = (232, 70, 52); c2 = (120, 22, 60); c3 = (34, 12, 48)
            if t < 0.25:
                k = t / 0.25; col = [c0[i] + (c1[i] - c0[i]) * k for i in range(3)]
            elif t < 0.6:
                k = (t - 0.25) / 0.35; col = [c1[i] + (c2[i] - c1[i]) * k for i in range(3)]
            else:
                k = (t - 0.6) / 0.4; col = [c2[i] + (c3[i] - c2[i]) * k for i in range(3)]
            band = 1.0 + 0.16 * (swirl - 0.5) * (1.0 - t)
            col = [max(0, min(255, int(v * band))) for v in col]
            # tramado de 2 tonos para que se vea pixel art
            if (x + y) % 2 == 0 and 0.55 < t < 0.95:
                col = [int(v * 0.88) for v in col]
            p[x, y] = (*col, 255)
    d = ImageDraw.Draw(img)
    # ruinas en silueta al fondo (agujas como en la pantalla de inicio)
    for i, (x, h) in enumerate(((0.12, 0.30), (0.2, 0.22), (0.8, 0.26), (0.89, 0.34))):
        bx = int(S * x); top = int(S * (0.98 - h))
        d.polygon([(bx - S * 0.025, S - 1), (bx, top), (bx + S * 0.025, S - 1)], fill=(24, 8, 30, 255))
    # borde de la losa
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.18), outline=INK, width=max(1, S // 32))
    d.rounded_rectangle([S // 32, S // 32, S - 1 - S // 32, S - 1 - S // 32], radius=int(S * 0.16), outline=(255, 120, 150, 255), width=1)
    return img

def wing(d, root, side, S, missing=()):
    """Ala en abanico: brazo curvo, fila de coberteras y 7 primarias largas en punta.
    Las primarias de 'missing' se han caído (el ala desplumada)."""
    u = S / 64.0
    rx, ry = root
    pts = []
    for k in range(12):                      # brazo: curva que sube y se abre
        t = k / 11.0
        pts.append((rx + side * 23 * u * t, ry - 16 * u * math.sin(t * 1.9) + 4 * u * t * t))
    tipx, tipy = pts[-1]
    W1 = (250, 247, 240, 255); W2 = (226, 220, 232, 255); W3 = (176, 166, 192, 255)
    # primarias: de la punta hacia el cuerpo, cada una más corta
    for k in range(7):
        if k in missing:
            continue
        t = 1.0 - k * 0.13
        bx, by = pts[int(round(t * 11))]
        L = (21 - k * 1.9) * u
        ang = math.radians(90 - side * (38 - k * 6))
        ex, ey = bx + math.cos(ang) * L, by + math.sin(ang) * L
        nx, ny = -math.sin(ang), math.cos(ang)
        w = (3.2 - k * 0.15) * u
        leaf = [(bx + nx * w, by + ny * w), (bx - nx * w, by - ny * w), (ex, ey)]
        d.polygon(leaf, fill=W2 if k % 2 else W1)
        d.line([(bx, by), (ex, ey)], fill=W3, width=max(1, int(u)))
    # coberteras (plumas cortas y redondas sobre el brazo)
    for k in range(6):
        t = 0.15 + k * 0.15
        bx, by = pts[int(round(t * 11))]
        r = (4.2 - k * 0.3) * u
        d.ellipse([bx - r, by - r * 0.4, bx + r, by + r * 1.3], fill=W1 if k % 2 == 0 else W2)
        d.arc([bx - r, by - r * 0.4, bx + r, by + r * 1.3], 20, 160, fill=W3)
    # borde superior del brazo, iluminado
    d.line(pts, fill=(255, 255, 255, 255), width=max(2, int(2.4 * u)))

def big_icon():
    S = 64
    img = background(S)
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    cx = 32
    # alas: izquierda entera, derecha desplumada
    wing(d, (cx - 4, 27), -1, S)
    wing(d, (cx + 4, 27), 1, S, missing=(1, 3, 4))
    # pluma que cae
    d.line([(51, 44), (54, 50)], fill=(244, 240, 234, 255), width=2)
    d.point((53, 51), fill=(160, 150, 176, 255))
    # espada que cae al vórtice (hoja de plata, guarda y pomo de oro)
    d.polygon([(cx - 3, 22), (cx + 3, 22), (cx + 3, 46), (cx, 54), (cx - 3, 46)], fill=(222, 228, 240, 255))
    d.line([(cx - 1, 23), (cx - 1, 47)], fill=(255, 255, 255, 255))
    d.line([(cx + 2, 23), (cx + 2, 46)], fill=(150, 156, 180, 255))
    d.rectangle([cx - 8, 19, cx + 8, 22], fill=(240, 190, 70, 255))
    d.line([(cx - 8, 19), (cx + 8, 19)], fill=(255, 236, 160, 255))
    d.rectangle([cx - 2, 12, cx + 2, 19], fill=(120, 40, 50, 255))
    d.line([(cx - 2, 13), (cx + 2, 13)], fill=(170, 60, 70, 255)); d.line([(cx - 2, 16), (cx + 2, 16)], fill=(170, 60, 70, 255))
    d.ellipse([cx - 3, 8, cx + 3, 13], fill=(240, 190, 70, 255))
    d.point((cx - 1, 9), fill=(255, 246, 200, 255))
    d.polygon([(cx - 1, 20), (cx + 1, 20), (cx, 21)], fill=(255, 80, 100, 255))     # gema
    # aureola rota encima
    for a in range(0, 360, 4):
        if 300 < a < 335:   # el trozo que falta
            continue
        rad = math.radians(a)
        x = cx + math.cos(rad) * 12; y = 6 + math.sin(rad) * 2.6
        d.rectangle([x - 0.5, y - 0.5, x + 0.5, y + 0.5], fill=(255, 224, 120, 255))
    d.point((cx + 12, 3), fill=(255, 224, 120, 255)); d.point((cx + 14, 2), fill=(255, 224, 120, 255))   # astillas
    fg = outline(fg)
    img.alpha_composite(fg)
    # brillo del vórtice por delante de la punta
    d2 = ImageDraw.Draw(img)
    d2.point((cx, 56), fill=(255, 240, 200, 255)); d2.point((cx - 1, 57), fill=(255, 200, 120, 255)); d2.point((cx + 1, 57), fill=(255, 200, 120, 255))
    return img

def small_icon(S):
    """Versión simplificada (16/32 px): espada, alas y aureola en pocos píxeles."""
    img = background(S)
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(fg)
    u = S / 16.0
    cx = S // 2
    W = (244, 240, 234, 255); G = (240, 190, 70, 255); B = (222, 228, 240, 255)
    # alas
    d.polygon([(cx - 1 * u, 8 * u), (cx - 7 * u, 3.5 * u), (cx - 6.5 * u, 9 * u), (cx - 2 * u, 10 * u)], fill=W)
    d.polygon([(cx + 1 * u, 8 * u), (cx + 7 * u, 3.5 * u), (cx + 6 * u, 7 * u), (cx + 5 * u, 8.2 * u), (cx + 2 * u, 10 * u)], fill=(214, 208, 222, 255))
    # espada
    d.rectangle([cx - 1 * u, 5 * u, cx, 12 * u], fill=B)
    d.rectangle([cx - 3 * u, 4.5 * u, cx + 2 * u, 5 * u + max(0, u - 1)], fill=G)
    d.rectangle([cx - 1 * u, 2.5 * u, cx, 4.4 * u], fill=(120, 40, 50, 255))
    d.point((cx - 1, int(13 * u)), fill=B)
    # aureola
    d.ellipse([cx - 4 * u, 0.5 * u, cx + 3 * u, 2.2 * u], outline=(255, 224, 120, 255))
    fg = outline(fg)
    img.alpha_composite(fg)
    return img

if __name__ == "__main__":
    big = big_icon()
    sizes = {}
    for s in (256, 128, 64, 48):
        sizes[s] = big.resize((s, s), Image.NEAREST)
    sizes[32] = small_icon(32)
    sizes[16] = small_icon(16)
    sizes[256].save(os.path.join(ROOT, "icon.png"))
    sizes[256].save(os.path.join(ROOT, "assets", "sprites", "app_icon.png"))
    order = [256, 128, 64, 48, 32, 16]
    sizes[256].save(os.path.join(ROOT, "icon.ico"), format="ICO", sizes=[(s, s) for s in order],
                    append_images=[sizes[s] for s in order[1:]])
    # vista previa de todos los tamaños
    prev = Image.new("RGBA", (256 + 128 + 64 + 48 + 32 + 16 + 70, 256), (30, 24, 36, 255))
    x = 0
    for s in order:
        prev.paste(sizes[s], (x, 256 - s), sizes[s]); x += s + 10
    prev.save("/tmp/icon_preview.png")
    print("Icono generado: icon.png / icon.ico")

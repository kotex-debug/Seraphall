#!/usr/bin/env python3
"""SERAPHALL — arte de los Estratos II, III y IV del juego base.
- tiles.png: añade suelos y muros del Bosque de Plumas Muertas, la Fundición de Halos y el Trono Vacío.
- Enemigos nuevos recoloreando las hojas del Estrato I (mismo esqueleto de animación, paleta propia).
- Arcontes: Orrun, el Ciervo Hueco (64x64) y Vulkaris, el Herrero de Aureolas (64x64).
- Azrahel: piezas de Seravel recoloreadas (negro, violeta y oro).
- PNJ nuevos (Hermano Oso, el Archivero, Lirio) y accesorios (árboles, nidos, yunques, crisoles, rosales, trono).
Uso: python3 tools/gen_strata.py"""
import os, math, colorsys
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
INK = (16, 10, 24, 255)
rng = np.random.default_rng(23)


def C(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def load(n):
    return Image.open(os.path.join(OUT, n + ".png")).convert("RGBA")


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


# ------------------------------------------------------------------ recoloreado por paleta
def recolor(img, hue=None, sat=1.0, val=1.0, hue_shift=0.0, glow=None, gold=None, keep_dark=0.13, val_add=0.0):
    """Cambia el tono de una hoja conservando sombras y contorno.
    glow: color para los píxeles muy saturados y brillantes (ojos, runas, fuego).
    gold: color para los dorados (tono 0.08-0.17, saturados)."""
    a = np.array(img).astype(np.float32) / 255.0
    out = a.copy()
    h, w = a.shape[:2]
    for y in range(h):
        for x in range(w):
            r, g, b, al = a[y, x]
            if al < 0.05:
                continue
            hh, ss, vv = colorsys.rgb_to_hsv(r, g, b)
            if vv < keep_dark:
                continue
            if glow is not None and ss > 0.55 and vv > 0.72 and not (0.07 < hh < 0.18):
                gr, gg, gb = glow
                k = vv
                out[y, x, :3] = (gr * k, gg * k, gb * k)
                continue
            if gold is not None and 0.07 < hh < 0.18 and ss > 0.45 and vv > 0.5:
                gr, gg, gb = gold
                out[y, x, :3] = (gr * vv, gg * vv, gb * vv)
                continue
            nh = (hh + hue_shift) % 1.0 if hue is None else hue
            ns = min(1.0, ss * sat)
            nv = min(1.0, vv * val + val_add)
            out[y, x, :3] = colorsys.hsv_to_rgb(nh, ns, nv)
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")


def hexf(h):
    return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)


ENEMIES = {
    # Estrato II — Bosque de Plumas Muertas
    "enemy_musgoso": ("enemy_hueco", dict(hue=0.27, sat=0.55, val=1.05, glow=hexf("b8fff0"))),
    "enemy_nidal": ("enemy_acolito", dict(hue=0.07, sat=0.6, val=0.95, glow=hexf("d8ffb0"), gold=hexf("f0ead8"))),
    "enemy_espino": ("enemy_planidera", dict(hue=0.36, sat=0.75, val=0.9, glow=hexf("e8ff90"))),
    "enemy_garza": ("enemy_bestia", dict(hue=0.6, sat=0.12, val=1.45, val_add=0.08, glow=hexf("70f0e0"))),
    "enemy_lacrima": ("enemy_planidera", dict(hue=0.5, sat=0.5, val=0.75, glow=hexf("ffffff"))),
    # Estrato III — Fundición de Halos
    "enemy_ascua": ("enemy_hueco", dict(hue=0.02, sat=0.6, val=0.7, glow=hexf("ffb040"))),
    "enemy_fundidor": ("enemy_guardia", dict(hue=0.6, sat=0.25, val=1.1, glow=hexf("ff9a30"))),
    "enemy_chispero": ("enemy_penitente", dict(hue=0.04, sat=1.2, val=1.15, glow=hexf("fff080"))),
    "enemy_forjador": ("enemy_acolito", dict(hue=0.0, sat=0.25, val=0.5, glow=hexf("ff7a30"), gold=hexf("ff9a40"))),
    "enemy_kronagh": ("enemy_custodio", dict(hue=0.09, sat=0.7, val=0.95, glow=hexf("ffe080"))),
    # Estrato IV — El Trono Vacío
    "enemy_cortesano": ("enemy_acolito", dict(hue=0.75, sat=0.3, val=0.45, glow=hexf("ffd060"), gold=hexf("ffd860"))),
    "enemy_caballero": ("enemy_guardia", dict(hue=0.72, sat=0.2, val=0.6, glow=hexf("c890ff"), gold=hexf("ffd060"))),
    "enemy_doncella": ("enemy_planidera", dict(hue=0.97, sat=0.8, val=0.8, glow=hexf("ffd870"))),
    "enemy_sabueso": ("enemy_bestia", dict(hue=0.75, sat=0.25, val=0.55, glow=hexf("ffcc40"))),
    "enemy_ysolde": ("enemy_custodio", dict(hue=0.12, sat=0.35, val=1.15, glow=hexf("d0a0ff"))),
}

NPCS = {
    "npc_oso": ("npc_preso", dict(hue=0.07, sat=0.9, val=0.9, glow=hexf("ffd080"))),
    "bust_oso": ("bust_preso", dict(hue=0.07, sat=0.9, val=0.9, glow=hexf("ffd080"))),
    "npc_archivero": ("npc_carto", dict(hue=0.1, sat=0.45, val=0.9, glow=hexf("a0e8ff"))),
    "bust_archivero": ("bust_carto", dict(hue=0.1, sat=0.45, val=0.9, glow=hexf("a0e8ff"))),
    "npc_lirio": ("npc_ilse", dict(hue=0.33, sat=0.6, val=1.0, glow=hexf("ffe080"))),
    "bust_lirio": ("bust_ilse", dict(hue=0.33, sat=0.6, val=1.0, glow=hexf("ffe080"))),
}

AZRAHEL = {
    "cinematic/azrahel_body": ("cinematic/seravel_body", dict(hue=0.75, sat=0.35, val=0.42, glow=hexf("c080ff"), gold=hexf("ffc850"))),
    "cinematic/azrahel_wing": ("cinematic/seravel_wing", dict(hue=0.74, sat=0.45, val=0.32, glow=hexf("b070ff"), gold=hexf("e0b040"))),
    "cinematic/azrahel_sword": ("cinematic/seravel_sword", dict(hue=0.76, sat=0.5, val=0.45, glow=hexf("d090ff"))),
    "cinematic/azrahel_halo": ("cinematic/seravel_halo", dict(hue=0.78, sat=0.8, val=0.9, glow=hexf("d8a0ff"), gold=hexf("b070ff"))),
    "cinematic/azrahel_eyes": ("cinematic/seravel_eyes", dict(hue=0.78, sat=1.0, val=1.0, glow=hexf("e0b0ff"))),
}


# ------------------------------------------------------------------ baldosas nuevas
def tile_noise(base, var=0.06, seed=0):
    r = np.random.default_rng(seed)
    t = np.zeros((16, 16, 4), dtype=np.float32)
    b = np.array(base[:3], dtype=np.float32) / 255.0
    n = r.normal(0, var, (16, 16))
    coarse = np.kron(r.normal(0, var * 0.8, (4, 4)), np.ones((4, 4)))
    for y in range(16):
        for x in range(16):
            k = 1.0 + n[y, x] + coarse[y, x]
            t[y, x, :3] = np.clip(b * k, 0, 1)
            t[y, x, 3] = 1.0
    return Image.fromarray((t * 255).astype(np.uint8), "RGBA")


def tiles():
    out = []
    # --- Bosque: musgo, raíces, hojarasca de plumas, flores pálidas; muros de corteza
    t = tile_noise(C("2e3a2c"), 0.08, 1); d = ImageDraw.Draw(t)
    for _ in range(6):
        x, y = rng.integers(0, 15, 2); d.point((int(x), int(y)), fill=C("4a5a40"))
    out.append(t)
    t = tile_noise(C("2c3628"), 0.07, 2); d = ImageDraw.Draw(t)
    d.line([(0, 9), (5, 7), (10, 9), (15, 6)], fill=C("4a3426")); d.line([(0, 10), (5, 8), (10, 10), (15, 7)], fill=C("2a1c14"))
    out.append(t)
    t = tile_noise(C("303a2e"), 0.06, 3); d = ImageDraw.Draw(t)
    for _ in range(3):
        x, y = rng.integers(2, 13, 2)
        d.line([(int(x), int(y)), (int(x) + 3, int(y) - 2)], fill=C("d8d4c8")); d.point((int(x) + 1, int(y)), fill=C("9a968a"))
    out.append(t)
    t = tile_noise(C("2a3426"), 0.07, 4); d = ImageDraw.Draw(t)
    for _ in range(2):
        x, y = rng.integers(3, 12, 2)
        d.point((int(x), int(y)), fill=C("e8e0f0")); d.point((int(x) + 1, int(y)), fill=C("c8b8e0")); d.point((int(x), int(y) + 1), fill=C("6a8a50"))
    out.append(t)
    for s in (5, 6):
        t = tile_noise(C("3a2a20"), 0.1, s); d = ImageDraw.Draw(t)
        for x in range(0, 16, 4):
            d.line([(x + 1, 0), (x + 1, 15)], fill=C("241812"))
        d.line([(0, 15), (15, 15)], fill=C("1a120c"))
        d.rectangle([0, 0, 15, 2], fill=C("2e3a2c")); d.line([(0, 3), (15, 3)], fill=C("4a5a40"))
        if s == 6:
            d.line([(3, 6), (6, 12)], fill=C("6a5a40")); d.line([(10, 5), (12, 11)], fill=C("6a5a40"))
        out.append(t)
    # --- Fundición: planchas de hierro, rejilla con brasas, hollín, remaches; muros de ladrillo con tuberías
    t = tile_noise(C("3a3a44"), 0.05, 7); d = ImageDraw.Draw(t)
    d.rectangle([0, 0, 15, 15], outline=C("26262e")); d.line([(1, 1), (14, 1)], fill=C("5a5a66"))
    for p in ((2, 2), (13, 2), (2, 13), (13, 13)):
        d.point(p, fill=C("7a7a88"))
    out.append(t)
    t = tile_noise(C("26222a"), 0.05, 8); d = ImageDraw.Draw(t)
    for x in range(1, 16, 3):
        d.line([(x, 1), (x, 14)], fill=C("141018"))
    for x in range(2, 16, 3):
        d.line([(x, 3), (x, 12)], fill=C("ff7a20") if x % 2 else C("c04010"))
    out.append(t)
    t = tile_noise(C("2e2a2c"), 0.09, 9); d = ImageDraw.Draw(t)
    for _ in range(5):
        x, y = rng.integers(0, 15, 2); d.point((int(x), int(y)), fill=C("1a1618"))
    out.append(t)
    t = tile_noise(C("36343e"), 0.05, 10); d = ImageDraw.Draw(t)
    d.line([(0, 7), (15, 7)], fill=C("24222a")); d.line([(7, 0), (7, 15)], fill=C("24222a"))
    d.point((3, 3), fill=C("ffa040")); d.point((12, 11), fill=C("c06020"))
    out.append(t)
    for s in (11, 12):
        t = tile_noise(C("4a2a24"), 0.07, s); d = ImageDraw.Draw(t)
        for y in range(0, 16, 4):
            d.line([(0, y), (15, y)], fill=C("2a1612"))
            off = 0 if (y // 4) % 2 == 0 else 4
            for x in range(off, 16, 8):
                d.line([(x, y), (x, y + 3)], fill=C("2a1612"))
        if s == 12:
            d.rectangle([6, 0, 9, 15], fill=C("3a3a44")); d.line([(6, 0), (6, 15)], fill=C("6a6a78")); d.point((7, 9), fill=C("ff8a30"))
        out.append(t)
    # --- Trono: mármol negro con vetas de oro, obsidiana, junta dorada, mármol agrietado; muros de pilastras
    t = tile_noise(C("1e1a24"), 0.05, 13); d = ImageDraw.Draw(t)
    d.line([(0, 12), (6, 8), (15, 9)], fill=C("8a6a30"))
    out.append(t)
    t = tile_noise(C("16121c"), 0.04, 14); d = ImageDraw.Draw(t)
    d.rectangle([0, 0, 15, 15], outline=C("2a2232")); d.point((1, 1), fill=C("4a3a5a"))
    out.append(t)
    t = tile_noise(C("1c1822"), 0.04, 15); d = ImageDraw.Draw(t)
    d.line([(0, 15), (15, 15)], fill=C("c8a040")); d.line([(15, 0), (15, 15)], fill=C("c8a040")); d.point((15, 15), fill=C("fff0a0"))
    out.append(t)
    t = tile_noise(C("201a26"), 0.06, 16); d = ImageDraw.Draw(t)
    d.line([(3, 0), (6, 6), (5, 11), (9, 15)], fill=C("0c0a10")); d.point((6, 6), fill=C("7a50a0"))
    out.append(t)
    for s in (17, 18):
        t = tile_noise(C("221c2a"), 0.04, s); d = ImageDraw.Draw(t)
        d.rectangle([0, 0, 15, 3], fill=C("2a2232")); d.line([(0, 3), (15, 3)], fill=C("c8a040"))
        d.rectangle([5, 4, 10, 15], fill=C("2e2638")); d.line([(5, 4), (5, 15)], fill=C("4a3e5a")); d.line([(10, 4), (10, 15)], fill=C("141018"))
        if s == 18:
            d.ellipse([6, 7, 9, 10], fill=C("8a50c0")); d.point((7, 8), fill=C("e0b0ff"))
        out.append(t)
    # alfombra real (violeta y oro)
    t = tile_noise(C("4a1a5a"), 0.04, 19); d = ImageDraw.Draw(t)
    d.line([(1, 0), (1, 15)], fill=C("c8a040")); d.line([(14, 0), (14, 15)], fill=C("c8a040"))
    d.point((7, 7), fill=C("e8c060")); d.point((8, 8), fill=C("e8c060"))
    out.append(t)
    return out


# ------------------------------------------------------------------ Orrun, el Ciervo Hueco (64x64)
def orrun_frame(kind="idle", f=0):
    img = Image.new("RGBA", (64, 64)); d = ImageDraw.Draw(img)
    bob = [0, 1, 1, 0][f % 4] if kind in ("idle", "walk") else 0
    lower = 0
    if kind == "attack":
        lower = [0, 6, 10][f]
    body = C("d8d0c0"); body_d = C("9a9284"); body_l = C("f4eee0"); hollow = C("120e1a")
    fire = C("70d0ff"); fire_l = C("d0f8ff"); antler = C("e8e0cc"); antler_d = C("a89c88")
    if kind == "dead":
        d.ellipse([10, 44, 54, 58], fill=body_d)
        d.ellipse([12, 42, 52, 54], fill=body)
        d.polygon([(40, 44), (58, 40), (60, 48), (44, 52)], fill=body)
        for i in range(4):
            d.line([(46 + i * 3, 40), (50 + i * 4, 30 + i * 2)], fill=antler)
        return outline(img)
    by = 36 + bob
    # patas (las de atrás más oscuras)
    phase = f % 4 if kind == "walk" else 0
    leg_off = [(-2, 2), (1, -1), (2, -2), (-1, 1)][phase]
    for lx, off, col in ((18, leg_off[0], body_d), (26, leg_off[1], body), (40, leg_off[1], body_d), (46, leg_off[0], body)):
        d.line([(lx, by + 10), (lx + off, by + 20), (lx + off, by + 26)], fill=col, width=3)
        d.rectangle([lx + off - 1, by + 25, lx + off + 1, by + 27], fill=C("3a3430"))
    # cuerpo hueco: costillas y fuego azul dentro
    d.ellipse([12, by - 2, 52, by + 16], fill=body)
    d.ellipse([20, by + 1, 44, by + 13], fill=hollow)
    for i in range(5):
        x = 22 + i * 5
        d.line([(x, by + 1), (x - 1, by + 13)], fill=body_l)
    fl = [0, 1, 2, 1][f % 4]
    d.ellipse([27, by + 4 - fl, 37, by + 12], fill=fire)
    d.ellipse([30, by + 6 - fl, 34, by + 11], fill=fire_l)
    # plumas en el lomo
    for i in range(6):
        x = 16 + i * 6
        d.polygon([(x, by - 1), (x + 3, by - 6 - (i % 2) * 2), (x + 5, by - 1)], fill=C("f0ece4"))
    # cuello y cabeza (baja al embestir)
    hx, hy = 50, by - 12 + lower
    d.polygon([(44, by + 2), (50, by - 4 + lower // 2), (54, by + 0 + lower // 2), (48, by + 6)], fill=body)
    d.polygon([(hx - 3, hy), (hx + 6, hy - 2), (hx + 12, hy + 6), (hx + 9, hy + 9), (hx, hy + 7)], fill=body)
    d.point((hx + 4, hy + 2), fill=fire_l); d.point((hx + 5, hy + 2), fill=fire)
    d.polygon([(hx + 9, hy + 6), (hx + 13, hy + 7), (hx + 10, hy + 9)], fill=C("2a2420"))
    # astas ramificadas (enormes)
    ax, ay = hx + 2, hy - 1
    tilt = lower * 0.6
    def branch(x0, y0, ang, ln, depth):
        if depth == 0 or ln < 3:
            return
        x1 = x0 + math.cos(ang) * ln; y1 = y0 + math.sin(ang) * ln
        d.line([(x0, y0), (x1, y1)], fill=antler if depth > 1 else antler_d, width=2 if depth > 2 else 1)
        branch(x1, y1, ang - 0.5, ln * 0.62, depth - 1)
        branch(x1, y1, ang + 0.35, ln * 0.7, depth - 1)
    branch(ax, ay, -math.pi / 2 - 0.5 + tilt * 0.08, 13, 4)
    branch(ax + 3, ay, -math.pi / 2 + 0.35 + tilt * 0.1, 12, 4)
    # llamitas azules en las puntas
    if kind == "attack" and f >= 1:
        for k in range(5):
            px = ax - 6 + k * 5; py = ay - 14 + (k % 2) * 3 + lower // 2
            d.point((int(px), int(py)), fill=fire_l)
    return outline(img)


def orrun_sheet():
    sheet = Image.new("RGBA", (64 * 4, 64 * 4))
    for i in range(4):
        sheet.alpha_composite(orrun_frame("idle", i), (i * 64, 0))
        sheet.alpha_composite(orrun_frame("walk", i), (i * 64, 64))
    for i in range(3):
        sheet.alpha_composite(orrun_frame("attack", i), (i * 64, 128))
    sheet.alpha_composite(orrun_frame("dead", 0), (0, 192))
    return sheet


# ------------------------------------------------------------------ Vulkaris, el Herrero de Aureolas (64x64)
def vulkaris_frame(kind="idle", f=0):
    img = Image.new("RGBA", (64, 64)); d = ImageDraw.Draw(img)
    skin = C("6a4a3a"); skin_d = C("4a3026"); apron = C("3a2a22"); apron_l = C("5a4234")
    iron = C("4a4a58"); iron_l = C("8a8a9a"); molten = C("ff8a30"); molten_l = C("fff0a0"); mask = C("2a2a34")
    bob = [0, 1, 1, 0][f % 4] if kind in ("idle", "walk") else 0
    if kind == "dead":
        d.ellipse([8, 46, 56, 60], fill=apron)
        d.ellipse([14, 42, 40, 54], fill=skin)
        d.rectangle([40, 48, 60, 54], fill=iron)
        d.ellipse([20, 36, 50, 46], outline=molten, width=2)
        return outline(img)
    by = 20 + bob
    # aureola fundida a la espalda (anillo al rojo)
    glow = [0, 1, 2, 1][f % 4]
    d.ellipse([15, by - 12, 49, by + 12], outline=C("c04010"), width=3)
    d.ellipse([16, by - 11, 48, by + 11], outline=molten, width=1)
    d.arc([16, by - 11, 48, by + 11], 200 + glow * 25, 250 + glow * 25, fill=molten_l, width=2)
    # piernas
    ph = f % 4 if kind == "walk" else 0
    lo = [(0, 0), (-2, 1), (0, 0), (2, -1)][ph]
    d.rectangle([22 + lo[0], by + 30, 28 + lo[0], by + 42], fill=skin_d)
    d.rectangle([36 + lo[1], by + 30, 42 + lo[1], by + 42], fill=skin_d)
    d.rectangle([20 + lo[0], by + 40, 29 + lo[0], by + 43], fill=iron)
    d.rectangle([35 + lo[1], by + 40, 44 + lo[1], by + 43], fill=iron)
    # torso enorme con pecho agrietado de metal fundido
    d.polygon([(16, by + 4), (48, by + 4), (50, by + 22), (44, by + 32), (20, by + 32), (14, by + 22)], fill=skin)
    d.polygon([(18, by + 14), (46, by + 14), (44, by + 34), (20, by + 34)], fill=apron)
    d.line([(18, by + 14), (46, by + 14)], fill=apron_l)
    d.line([(26, by + 7), (30, by + 11), (34, by + 8), (38, by + 12)], fill=molten, width=2)
    d.point((30, by + 10), fill=molten_l)
    # cabeza con máscara de hierro y ojos al rojo
    d.rectangle([26, by - 6, 38, by + 5], fill=mask)
    d.line([(26, by - 6), (38, by - 6)], fill=iron_l)
    d.rectangle([28, by - 2, 30, by - 1], fill=molten); d.rectangle([34, by - 2, 36, by - 1], fill=molten)
    d.line([(32, by - 6), (32, by + 4)], fill=C("1a1a22"))
    # brazos: el izquierdo agarra tenazas; el derecho, el martillo
    d.rectangle([10, by + 6, 16, by + 22], fill=skin)
    d.line([(12, by + 22), (8, by + 34)], fill=iron_l, width=2)
    ham_y = {"idle": by + 18, "walk": by + 18}.get(kind, [by - 18, by - 6, by + 26][f] if kind == "attack" else by + 18)
    d.rectangle([48, by + 6, 54, by + 20], fill=skin)
    hx = 54
    d.line([(51, by + 18), (hx, ham_y)], fill=C("5a3a24"), width=3)
    d.rectangle([hx - 6, ham_y - 6, hx + 8, ham_y + 4], fill=iron)
    d.rectangle([hx - 6, ham_y - 6, hx + 8, ham_y - 5], fill=iron_l)
    if kind == "attack" and f == 2:
        d.rectangle([hx - 6, ham_y + 2, hx + 8, ham_y + 4], fill=molten)
    return outline(img)


def vulkaris_sheet():
    sheet = Image.new("RGBA", (64 * 4, 64 * 4))
    for i in range(4):
        sheet.alpha_composite(vulkaris_frame("idle", i), (i * 64, 0))
        sheet.alpha_composite(vulkaris_frame("walk", i), (i * 64, 64))
    for i in range(3):
        sheet.alpha_composite(vulkaris_frame("attack", i), (i * 64, 128))
    sheet.alpha_composite(vulkaris_frame("dead", 0), (0, 192))
    return sheet


# ------------------------------------------------------------------ accesorios
def tree_dead():
    img = Image.new("RGBA", (40, 64)); d = ImageDraw.Draw(img)
    bark = C("6a5a50"); bark_d = C("3a302a"); feather = C("e8e4dc")
    d.polygon([(17, 63), (23, 63), (22, 30), (20, 18), (18, 30)], fill=bark)
    d.line([(18, 62), (19, 30)], fill=bark_d)
    for (x0, y0, x1, y1) in ((20, 34, 6, 22), (20, 28, 34, 14), (20, 22, 10, 8), (21, 20, 30, 4), (20, 40, 32, 30)):
        d.line([(x0, y0), (x1, y1)], fill=bark, width=2)
        d.polygon([(x1 - 2, y1), (x1 + 1, y1 - 4), (x1 + 3, y1 + 1)], fill=feather)
    for _ in range(14):
        x = int(rng.integers(4, 36)); y = int(rng.integers(2, 36))
        d.point((x, y), fill=feather)
    d.polygon([(13, 63), (17, 58), (16, 63)], fill=bark_d); d.polygon([(27, 63), (23, 58), (24, 63)], fill=bark_d)
    return outline(img)


def nest():
    img = Image.new("RGBA", (24, 14)); d = ImageDraw.Draw(img)
    d.ellipse([1, 3, 23, 13], fill=C("6a5038")); d.ellipse([4, 4, 20, 10], fill=C("2a2018"))
    for x in (8, 12, 16):
        d.ellipse([x - 2, 5, x + 2, 9], fill=C("e8e0f0"))
    for i in range(8):
        d.line([(2 + i * 3, 4), (4 + i * 3, 12)], fill=C("8a6a48"))
    return outline(img)


def anvil():
    img = Image.new("RGBA", (32, 22)); d = ImageDraw.Draw(img)
    d.polygon([(2, 4), (26, 4), (31, 7), (26, 9), (22, 9), (20, 14), (24, 20), (8, 20), (12, 14), (10, 9), (4, 9)], fill=C("4a4a58"))
    d.line([(2, 4), (26, 4)], fill=C("9a9aaa")); d.line([(26, 4), (31, 7)], fill=C("9a9aaa"))
    d.ellipse([12, 1, 18, 5], fill=C("ff8a30")); d.point((15, 2), fill=C("fff0a0"))
    return outline(img)


def crucible(glow):
    img = Image.new("RGBA", (24, 28)); d = ImageDraw.Draw(img)
    d.polygon([(3, 8), (21, 8), (19, 24), (5, 24)], fill=C("3a3440"))
    d.line([(3, 8), (21, 8)], fill=C("7a7488"))
    d.ellipse([4, 5, 20, 11], fill=C("ff7a20") if glow else C("e06010"))
    d.ellipse([7, 6, 17, 9], fill=C("fff0a0") if glow else C("ffb040"))
    d.rectangle([1, 12, 3, 14], fill=C("2a2430")); d.rectangle([21, 12, 23, 14], fill=C("2a2430"))
    d.rectangle([6, 24, 8, 27], fill=C("2a2430")); d.rectangle([16, 24, 18, 27], fill=C("2a2430"))
    if glow:
        d.point((10, 2), fill=C("ffd060")); d.point((14, 0), fill=C("ff8a30"))
    return outline(img)


def halo_mold():
    img = Image.new("RGBA", (28, 28)); d = ImageDraw.Draw(img)
    d.rectangle([2, 10, 25, 25], fill=C("4a3a34")); d.line([(2, 10), (25, 10)], fill=C("7a6a5a"))
    d.ellipse([5, 2, 22, 14], outline=C("c8a040"), width=2)
    d.arc([5, 2, 22, 14], 190, 250, fill=C("fff0a0"))
    return outline(img)


def rosebush():
    img = Image.new("RGBA", (24, 20)); d = ImageDraw.Draw(img)
    d.ellipse([1, 4, 23, 19], fill=C("2a3a24"))
    for i in range(10):
        x = int(rng.integers(3, 21)); y = int(rng.integers(5, 17))
        d.line([(x, y), (x + 2, y - 2)], fill=C("5a4a20"))
    for (x, y) in ((6, 8), (14, 6), (18, 12), (9, 14)):
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=C("e8c040")); d.point((x, y), fill=C("fff0a0"))
    return outline(img)


def throne():
    img = Image.new("RGBA", (48, 60)); d = ImageDraw.Draw(img)
    gold = C("c8a040"); gold_l = C("fff0a0"); black = C("1e1a24"); vel = C("4a1a5a")
    d.polygon([(10, 58), (38, 58), (38, 30), (34, 8), (24, 2), (14, 8), (10, 30)], fill=black)
    d.polygon([(14, 30), (34, 30), (32, 10), (24, 5), (16, 10)], fill=vel)
    d.line([(24, 2), (24, 30)], fill=C("2a0e34"))
    d.rectangle([6, 30, 42, 40], fill=black); d.line([(6, 30), (42, 30)], fill=gold)
    d.rectangle([4, 40, 12, 58], fill=black); d.rectangle([36, 40, 44, 58], fill=black)
    d.line([(4, 40), (12, 40)], fill=gold); d.line([(36, 40), (44, 40)], fill=gold)
    for (x, y) in ((24, 2), (14, 8), (34, 8)):
        d.polygon([(x - 2, y), (x, y - 5), (x + 2, y)], fill=gold); d.point((x, y - 4), fill=gold_l)
    d.rectangle([12, 54, 36, 58], fill=C("2a2232"))
    return outline(img)


def rift(frame):
    img = Image.new("RGBA", (40, 40)); d = ImageDraw.Draw(img)
    for i in range(6, 0, -1):
        a = 255 if i < 3 else 120
        col = (60 + i * 20, 20 + i * 10, 120 + i * 20, a)
        r = i * 3 + (frame % 2)
        d.ellipse([20 - r, 20 - r * 0.7, 20 + r, 20 + r * 0.7], fill=col)
    d.ellipse([16, 17, 24, 23], fill=(10, 4, 16, 255))
    return img


if __name__ == "__main__":
    # baldosas: se añaden al final de tiles.png (las del Estrato I no cambian de índice)
    base = load("tiles")
    n0 = base.width // 16
    if n0 <= 34:
        new = tiles()
        out = Image.new("RGBA", (16 * (34 + len(new)), 16))
        out.alpha_composite(base.crop((0, 0, 16 * 34, 16)), (0, 0))
        for i, t in enumerate(new):
            out.alpha_composite(t, (16 * (34 + i), 0))
        out.save(os.path.join(OUT, "tiles.png"))
        print("tiles", 34, "->", 34 + len(new))
    for name, (src, kw) in {**ENEMIES, **NPCS, **AZRAHEL}.items():
        recolor(load(src), **kw).save(os.path.join(OUT, name + ".png"))
    orrun_sheet().save(os.path.join(OUT, "enemy_orrun.png"))
    vulkaris_sheet().save(os.path.join(OUT, "enemy_vulkaris.png"))
    tree_dead().save(os.path.join(OUT, "tree_dead.png"))
    nest().save(os.path.join(OUT, "nest.png"))
    anvil().save(os.path.join(OUT, "anvil.png"))
    c = Image.new("RGBA", (48, 28)); c.alpha_composite(crucible(False), (0, 0)); c.alpha_composite(crucible(True), (24, 0))
    c.save(os.path.join(OUT, "crucible.png"))
    halo_mold().save(os.path.join(OUT, "halo_mold.png"))
    rosebush().save(os.path.join(OUT, "rosebush.png"))
    throne().save(os.path.join(OUT, "throne.png"))
    r = Image.new("RGBA", (80, 40)); r.alpha_composite(rift(0), (0, 0)); r.alpha_composite(rift(1), (40, 0))
    r.save(os.path.join(OUT, "rift.png"))
    print("ok")

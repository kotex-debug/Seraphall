#!/usr/bin/env python3
"""Generador procedural de pixel art para SERAPHALL.
Uso: python3 tools/gen_art.py  (escribe PNG en assets/sprites)
Todo el arte provisional se genera aquí para que el proyecto sea 100% texto."""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)
R = random.Random(7)

OUTLINE = (18, 14, 24, 255)

def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def shade(c, f):
    return (max(0, min(255, int(c[0] * f))), max(0, min(255, int(c[1] * f))), max(0, min(255, int(c[2] * f))), c[3])

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def outline(img, color=OUTLINE):
    a = np.array(img)
    alpha = a[:, :, 3] > 0
    pad = np.pad(alpha, 1)
    n = pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:]
    edge = n & ~alpha
    a[edge] = color
    return Image.fromarray(a)

def ell(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)

def strip(frames):
    w, h = frames[0].size
    s = canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        s.paste(f, (i * w, 0), f)
    return s

def sheet(rows):
    """rows: lista de listas de frames (mismo tamaño). Devuelve imagen con una fila por animación."""
    w, h = rows[0][0].size
    maxn = max(len(r) for r in rows)
    s = canvas(w * maxn, h * len(rows))
    for j, r in enumerate(rows):
        for i, f in enumerate(r):
            s.paste(f, (i * w, j * h), f)
    return s

# ---------------------------------------------------------------- humanoides
def humanoid(W, H, pal, pose, wings=True, halo=False, cloak=True, scale=1.0, weapon_arm=0):
    img = canvas(W, H)
    d = ImageDraw.Draw(img)
    cx = W // 2
    bob = pose.get("bob", 0)
    base = H - 2
    s = scale
    leg_h = int(5 * s)
    torso_h = int(7 * s)
    head_r = 3.5 * s
    hip_y = base - leg_h
    sh_y = hip_y - torso_h + bob
    head_y = sh_y - head_r + 0.5
    # alas (detrás)
    if wings:
        flap = pose.get("flap", 0)
        wc = pal["wing"]
        wd = shade(wc, 0.72)
        for side in (-1, 1):
            x0 = cx - side * 2
            pts = [(x0, sh_y + 1), (x0 - side * int(7 * s), sh_y - int(4 * s) - flap),
                   (x0 - side * int(9 * s), sh_y + int(1 * s) - flap // 2), (x0 - side * int(6 * s), sh_y + int(6 * s)),
                   (x0 - side * 1, sh_y + int(5 * s))]
            d.polygon(pts, fill=wd if side == 1 else wc)
            # plumas
            for k in range(3):
                fx = x0 - side * int((4 + k * 1.6) * s)
                d.line([(fx, sh_y + int(2 * s) - flap // 3), (fx - side, sh_y + int(5 * s))], fill=shade(wc, 0.55))
    # capa
    if cloak:
        cc = pal["cloak"]
        d.polygon([(cx - int(3 * s), sh_y + 1), (cx + int(3 * s), sh_y + 1), (cx + int(4 * s) + pose.get("cloak", 0), base - 1),
                   (cx - int(5 * s) + pose.get("cloak", 0), base - 1)], fill=shade(cc, 0.8))
    # piernas
    lc = pal["legs"]
    for off, lx in ((-1, pose.get("l", 0)), (1, pose.get("r", 0))):
        x = cx + off * int(1.5 * s) + lx
        d.rectangle([x - int(1 * s), hip_y + bob // 2, x + int(0.5 * s), base], fill=lc if off == -1 else shade(lc, 0.8))
        d.rectangle([x - int(1 * s), base - 1, x + int(1.2 * s), base], fill=shade(lc, 0.55))
    # torso
    tc = pal["armor"]
    d.rectangle([cx - int(3 * s), sh_y, cx + int(3 * s), hip_y + bob // 2], fill=tc)
    d.rectangle([cx + int(1 * s), sh_y + 1, cx + int(3 * s), hip_y + bob // 2], fill=shade(tc, 0.78))
    d.line([(cx - int(3 * s), hip_y - 1 + bob // 2), (cx + int(3 * s), hip_y - 1 + bob // 2)], fill=pal["accent"])
    d.point((cx - int(1 * s), sh_y + 2), fill=shade(tc, 1.25))
    # brazo
    ac = pal["armor"]
    arm = pose.get("arm", 0)
    if arm == 0:
        d.rectangle([cx + int(2 * s), sh_y + 1, cx + int(3.5 * s), sh_y + int(5 * s)], fill=shade(ac, 0.9))
    elif arm == 1:  # preparando
        d.rectangle([cx - int(4 * s), sh_y, cx - int(2 * s), sh_y + int(3 * s)], fill=shade(ac, 0.9))
    else:  # golpe
        d.rectangle([cx + int(2 * s), sh_y + 1, cx + int(6 * s), sh_y + int(2.5 * s)], fill=shade(ac, 0.9))
    # cabeza
    ell(d, cx, head_y, head_r, head_r, pal["skin"])
    ell(d, cx - 0.5, head_y - 1.2 * s, head_r, head_r * 0.62, pal["hair"])
    d.rectangle([cx - int(head_r), head_y - 1, cx - int(head_r) + 1, head_y + 2 * s], fill=pal["hair"])
    d.point((cx + int(1.5 * s), int(head_y)), fill=pal["eye"])
    if halo:
        hy = int(head_y - head_r - 2 * s)
        d.ellipse([cx - int(3.5 * s), hy - 1, cx + int(3.5 * s), hy + 1], outline=pal["halo"])
    out = outline(img)
    if halo:  # halo brillante sin contorno encima
        d2 = ImageDraw.Draw(out)
        hy = int(head_y - head_r - 2 * s)
        d2.ellipse([cx - int(3.5 * s), hy - 1, cx + int(3.5 * s), hy + 1], outline=pal["halo"])
    return out

def anim_set(W, H, pal, **kw):
    rows = []
    # idle 4
    rows.append([humanoid(W, H, pal, {"bob": [0, 0, 1, 1][i], "flap": [0, 1, 2, 1][i]}, **kw) for i in range(4)])
    # run 6
    cyc = [(-2, 2), (-1, 1), (1, -1), (2, -2), (1, -1), (-1, 1)]
    rows.append([humanoid(W, H, pal, {"l": cyc[i][0], "r": cyc[i][1], "bob": [0, 1, 0, 0, 1, 0][i], "flap": i % 3, "cloak": -1}, **kw) for i in range(6)])
    # attack 3
    rows.append([humanoid(W, H, pal, {"arm": a, "l": l, "r": -l, "flap": f}, **kw) for a, l, f in ((1, -1, 0), (2, 2, 3), (2, 1, 1))])
    # hurt 1, dead 1
    hurt = humanoid(W, H, pal, {"bob": 1, "flap": 3}, **kw)
    dead = humanoid(W, H, pal, {"bob": 2}, **kw).rotate(90, expand=False)
    rows.append([hurt, dead])
    return sheet(rows)

P1 = dict(skin=C("f2d0b0"), hair=C("e8e0d0"), eye=C("3a7bd5"), armor=C("d8d2c4"), legs=C("5a5068"), accent=C("e0b040"),
          cloak=C("9a2a34"), wing=C("f4f0ea"), halo=C("ffe27a"))
P2 = dict(skin=C("c89878"), hair=C("2a2238"), eye=C("ff7040"), armor=C("3e3a52"), legs=C("2a2638"), accent=C("40c0b0"),
          cloak=C("1e6a70"), wing=C("6a6478"), halo=C("8af0ff"))
BRENNA = dict(skin=C("d8a882"), hair=C("c0522a"), eye=C("201820"), armor=C("6a4a38"), legs=C("3a2c28"), accent=C("ffa040"),
              cloak=C("4a3a30"), wing=C("8a8070"), halo=C("ffffff"))
CARTO = dict(skin=C("b8b0a8"), hair=C("d8d8d8"), eye=C("d8d8f0"), armor=C("38405a"), legs=C("282a38"), accent=C("90a0ff"),
             cloak=C("2a3050"), wing=C("707a90"), halo=C("ffffff"))

anim_set(24, 26, P1, wings=True, halo=True).save(f"{OUT}/player_p1.png")
anim_set(24, 26, P2, wings=True, halo=True).save(f"{OUT}/player_p2.png")
sheet([[humanoid(24, 26, BRENNA, {"bob": [0, 0, 1, 1][i], "arm": [0, 1, 2, 0][i]}, wings=False) for i in range(4)]]).save(f"{OUT}/npc_brenna.png")
sheet([[humanoid(24, 26, CARTO, {"bob": [0, 1, 1, 0][i]}, wings=True) for i in range(4)]]).save(f"{OUT}/npc_carto.png")

# ---------------------------------------------------------------- enemigos
def hueco(pose):
    W, H = 22, 24
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx, base = 11, H - 2
    bob = pose.get("bob", 0); lean = pose.get("lean", 0)
    body = C("5a5262"); dark = C("3a3442"); ember = C("ff8a30")
    for off, lx in ((-1, pose.get("l", 0)), (1, pose.get("r", 0))):
        x = cx + off * 2 + lx
        d.rectangle([x - 1, base - 5, x, base], fill=dark)
    d.polygon([(cx - 4 + lean, base - 5), (cx + 4 + lean, base - 5), (cx + 3 + lean, base - 13 + bob), (cx - 3 + lean, base - 13 + bob)], fill=body)
    d.line([(cx - 2 + lean, base - 10 + bob), (cx + 2 + lean, base - 8 + bob)], fill=dark)
    # brazos largos
    ax = pose.get("arm", 0)
    d.line([(cx + 3 + lean, base - 12 + bob), (cx + 6 + lean + ax, base - 6 + bob - ax)], fill=body, width=2)
    d.line([(cx - 3 + lean, base - 12 + bob), (cx - 6 + lean, base - 6 + bob)], fill=dark, width=2)
    if ax > 2:
        for k in range(3):
            d.point((cx + 7 + lean + ax + k % 2, base - 6 + bob - ax + k), fill=C("c8c0c8"))
    ell(d, cx + 1 + lean, base - 16 + bob, 3.5, 3.2, body)
    d.point((cx + 3 + lean, base - 16 + bob), fill=ember); d.point((cx + 1 + lean, base - 16 + bob), fill=ember)
    return outline(img)

rows = [[hueco({"bob": [0, 1, 1, 0][i]}) for i in range(4)],
        [hueco({"l": [-2, 0, 2, 0][i], "r": [2, 0, -2, 0][i], "bob": [0, 1, 0, 1][i], "lean": 1}) for i in range(4)],
        [hueco({"arm": a, "lean": l}) for a, l in ((-2, -1), (4, 2), (3, 2))],
        [hueco({"bob": 2}), hueco({"bob": 3}).rotate(90)]]
sheet(rows).save(f"{OUT}/enemy_hueco.png")

def acolito(pose):
    W, H = 22, 26
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx = 11; fy = pose.get("fly", 0)
    robe = C("3a2a52"); trim = C("b080ff"); face = C("1a1222")
    d.polygon([(cx - 5, 22 + fy), (cx + 5, 22 + fy), (cx + 3, 8 + fy), (cx - 3, 8 + fy)], fill=robe)
    for x in range(cx - 5, cx + 6, 2):
        d.point((x, 22 + fy + (x % 3 == 0)), fill=robe)
    d.line([(cx - 5, 21 + fy), (cx + 5, 21 + fy)], fill=trim)
    ell(d, cx, 7 + fy, 4, 4, robe)
    ell(d, cx + 1, 8 + fy, 2, 2.2, face)
    d.point((cx + 1, 8 + fy), fill=C("e0b0ff")); d.point((cx + 2, 8 + fy), fill=C("e0b0ff"))
    c = pose.get("cast", 0)
    if c:
        d.line([(cx + 3, 12 + fy), (cx + 8, 11 + fy - c)], fill=robe, width=2)
        ell(d, cx + 9, 10 + fy - c, 1 + c * 0.6, 1 + c * 0.6, C("d8a8ff"))
    else:
        d.line([(cx + 3, 12 + fy), (cx + 5, 16 + fy)], fill=robe, width=2)
    return outline(img)

rows = [[acolito({"fly": [0, -1, -1, 0][i]}) for i in range(4)],
        [acolito({"cast": c, "fly": -1}) for c in (1, 2, 3)],
        [acolito({"fly": 1}), acolito({"fly": 2}).rotate(90)]]
sheet(rows).save(f"{OUT}/enemy_acolito.png")

def bestia(pose):
    W, H = 32, 22
    img = canvas(W, H); d = ImageDraw.Draw(img)
    base = H - 2; bob = pose.get("bob", 0); st = pose.get("stretch", 0)
    hide = C("6a4838"); dark = C("42302a"); ember = C("ffb040"); horn = C("e8dcc8")
    legs = pose.get("legs", (0, 0, 0, 0))
    for i, x in enumerate((7, 11, 20, 24)):
        d.rectangle([x + legs[i], base - 5, x + 1 + legs[i], base], fill=dark if i % 2 else hide)
    d.ellipse([4 - st, base - 13 + bob, 27 + st, base - 4 + bob], fill=hide)
    d.line([(8, base - 12 + bob), (24, base - 12 + bob)], fill=shade(hide, 1.25))
    for x in range(8, 24, 3):
        d.point((x, base - 13 + bob), fill=ember)
    ell(d, 27 + st, base - 10 + bob, 4, 3.5, hide)
    d.line([(28 + st, base - 13 + bob), (31 + st, base - 17 + bob)], fill=horn, width=1)
    d.line([(26 + st, base - 13 + bob), (27 + st, base - 17 + bob)], fill=horn, width=1)
    d.point((29 + st, base - 10 + bob), fill=ember)
    return outline(img)

rows = [[bestia({"bob": [0, 1, 1, 0][i]}) for i in range(4)],
        [bestia({"legs": [(-1, 1, 1, -1), (0, 0, 0, 0), (1, -1, -1, 1), (0, 0, 0, 0)][i], "bob": i % 2}) for i in range(4)],
        [bestia({"stretch": 2, "legs": (-2, 2, 2, -2)}), bestia({"stretch": 3, "legs": (2, -2, -2, 2)})],
        [bestia({"bob": 2}), bestia({"bob": 2}).rotate(180)]]
sheet(rows).save(f"{OUT}/enemy_bestia.png")

def carcelero(pose):
    W, H = 40, 40
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx, base = 20, H - 2; bob = pose.get("bob", 0)
    metal = C("6a6670"); dark = C("3e3a44"); rust = C("8a4a30"); ember = C("ff6a20")
    for off, lx in ((-1, pose.get("l", 0)), (1, pose.get("r", 0))):
        x = cx + off * 5 + lx
        d.rectangle([x - 2, base - 9, x + 2, base], fill=dark)
    d.rectangle([cx - 9, base - 24 + bob, cx + 9, base - 8 + bob], fill=metal)
    d.rectangle([cx + 3, base - 23 + bob, cx + 9, base - 9 + bob], fill=shade(metal, 0.75))
    for y in range(base - 22 + bob, base - 9 + bob, 4):
        d.line([(cx - 9, y), (cx + 9, y)], fill=rust)
    ell(d, cx, base - 28 + bob, 6, 5, metal)
    d.rectangle([cx - 4, base - 29 + bob, cx + 5, base - 27 + bob], fill=C("140c10"))
    d.point((cx + 2, base - 28 + bob), fill=ember); d.point((cx - 1, base - 28 + bob), fill=ember)
    sl = pose.get("slam", 0)
    # brazo con cadena y bola
    ay = base - 22 + bob - sl * 4
    d.line([(cx + 9, base - 21 + bob), (cx + 13, ay)], fill=metal, width=3)
    for k in range(4):
        d.point((cx + 14 + k, ay + 2 + k + sl * 3), fill=C("a0a0a8"))
    ell(d, cx + 18 + sl, ay + 7 + sl * 4, 3.5, 3.5, C("4a4650"))
    d.line([(cx - 9, base - 21 + bob), (cx - 12, base - 12 + bob)], fill=dark, width=3)
    return outline(img)

rows = [[carcelero({"bob": [0, 0, 1, 1][i]}) for i in range(4)],
        [carcelero({"l": [-2, 0, 2, 0][i], "r": [2, 0, -2, 0][i], "bob": i % 2}) for i in range(4)],
        [carcelero({"slam": s}) for s in (2, 0, -1)],
        [carcelero({"bob": 2}), carcelero({"bob": 3}).rotate(90)]]
sheet(rows).save(f"{OUT}/enemy_carcelero.png")

SERAVEL = dict(skin=C("f8e0d0"), hair=C("a898d8"), eye=C("ff3050"), armor=C("ece6f4"), legs=C("b8aed0"), accent=C("ffd060"),
               cloak=C("c01838"), wing=C("fffaf0"), halo=C("ffe060"))
SERAVEL2 = dict(SERAVEL, cloak=C("5a0820"), wing=C("ffb0a0"), halo=C("ff4040"), armor=C("d8c8e0"))

def seravel(pal, pose):
    img = humanoid(52, 56, pal, pose, wings=True, halo=True, scale=2.0)
    return img

rows = [[seravel(SERAVEL, {"bob": [0, 1, 2, 2, 1, 0][i], "flap": [0, 2, 4, 5, 3, 1][i]}) for i in range(6)],
        [seravel(SERAVEL, {"arm": a, "flap": f}) for a, f in ((1, 2), (2, 6), (2, 4))],
        [seravel(SERAVEL2, {"bob": [0, 1, 2, 2, 1, 0][i], "flap": [0, 3, 6, 7, 4, 1][i]}) for i in range(6)],
        [seravel(SERAVEL2, {"arm": a, "flap": f}) for a, f in ((1, 2), (2, 7), (2, 4))],
        [seravel(SERAVEL2, {"bob": 2}).rotate(90)]]
sheet(rows).save(f"{OUT}/boss_seravel.png")

# ---------------------------------------------------------------- brasa (checkpoint)
def brasa(i, lit=True):
    W, H = 18, 26
    img = canvas(W, H); d = ImageDraw.Draw(img)
    # cuenco de piedra y espada clavada
    d.polygon([(2, 21), (16, 21), (14, 25), (4, 25)], fill=C("4a4450"))
    d.line([(2, 21), (16, 21)], fill=C("6a6472"))
    d.rectangle([8, 4, 9, 20], fill=C("a8a4b0"))
    d.rectangle([5, 8, 12, 9], fill=C("806040"))
    img = outline(img); d = ImageDraw.Draw(img)
    if lit:
        rr = random.Random(i * 31)
        for k in range(10):
            fx = 9 + rr.randint(-4, 4); fy = 20 - rr.randint(0, 8 + (i % 3))
            col = [C("fff0a0"), C("ffb040"), C("ff6020")][min(2, (20 - fy) // 3)]
            d.point((fx, fy), fill=col)
        ell(d, 9, 19, 3, 2, C("ffc050"))
        d.point((9, 18), fill=C("fffbe0"))
    else:
        d.line([(5, 20), (13, 20)], fill=C("3a2c2a"))
    return img

strip([brasa(0, False)] + [brasa(i) for i in range(6)]).save(f"{OUT}/brasa.png")

# ---------------------------------------------------------------- tileset 16x16
T = 16
def tile_floor(seed, tint=(1, 1, 1)):
    rr = random.Random(seed)
    a = np.zeros((T, T, 4), dtype=np.uint8)
    base = np.array([54, 48, 60])
    for y in range(T):
        for x in range(T):
            n = rr.randint(-5, 5)
            c = base + n
            a[y, x, :3] = np.clip(c * np.array(tint), 0, 255)
            a[y, x, 3] = 255
    # juntas de baldosas
    a[0, :, :3] = (36, 32, 42); a[:, 0, :3] = (36, 32, 42)
    a[8, 0:8, :3] = (40, 36, 46) if seed % 2 else a[8, 0:8, :3]
    # grietas
    if seed % 3 == 0:
        x, y = rr.randint(3, 12), rr.randint(3, 12)
        for k in range(6):
            a[y, x, :3] = (30, 26, 34)
            x += rr.choice([-1, 0, 1]); y += rr.choice([0, 1])
            x = max(1, min(T - 1, x)); y = max(1, min(T - 1, y))
    # luz arriba-izq
    a[1, 1:T, :3] = np.clip(a[1, 1:T, :3].astype(int) + 10, 0, 255)
    return Image.fromarray(a)

def tile_ash(seed):
    img = tile_floor(seed + 100, (1.08, 1.0, 0.95))
    d = ImageDraw.Draw(img); rr = random.Random(seed)
    for k in range(5):
        d.point((rr.randint(1, 15), rr.randint(1, 15)), fill=C("8a7a70"))
    if seed % 2:
        d.point((rr.randint(2, 14), rr.randint(2, 14)), fill=C("ff7030"))
    return img

def tile_wall_top():
    a = np.zeros((T, T, 4), dtype=np.uint8); rr = random.Random(5)
    for y in range(T):
        for x in range(T):
            v = 26 + rr.randint(-3, 3)
            a[y, x] = (v, v - 3, v + 6, 255)
    return Image.fromarray(a)

def tile_wall_face(seed):
    rr = random.Random(seed)
    img = canvas(T, T); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=C("4a4256"))
    for row, y in enumerate((0, 5, 10)):
        off = 0 if row % 2 == 0 else 4
        for x in range(-off, 16, 8):
            d.rectangle([x, y, x + 7, y + 4], fill=shade(C("4e465a"), 1 + rr.uniform(-0.08, 0.08)), outline=C("2e2838"))
    d.rectangle([0, 15, 15, 15], fill=C("1e1a24"))
    d.rectangle([0, 0, 15, 0], fill=C("6a6278"))
    if seed % 3 == 0:  # musgo de ceniza / vela
        d.point((rr.randint(2, 13), 14), fill=C("6a5a50"))
    return img

def tile_carpet(edge=False):
    img = canvas(T, T); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=C("6a1828"))
    d.line([(0, 2), (15, 2)], fill=C("b08a40")); d.line([(0, 13), (15, 13)], fill=C("b08a40"))
    for x in range(0, 16, 4):
        d.point((x + 1, 7), fill=C("8a2a3a")); d.point((x + 2, 8), fill=C("8a2a3a"))
    return img

def tile_seal(part):
    """Sello dorado del círculo del jefe (se coloca suelto como decoración)."""
    return None

def tile_grate():
    img = tile_floor(4); d = ImageDraw.Draw(img)
    d.rectangle([2, 2, 13, 13], fill=C("1a141e"))
    for x in range(3, 13, 3):
        d.line([(x, 2), (x, 13)], fill=C("5a5462"))
    return img

def tile_void():
    a = np.zeros((T, T, 4), dtype=np.uint8)
    for y in range(T):
        v = int(10 + 6 * math.sin(y * 0.6))
        a[y, :, :] = (v, v - 4 if v > 4 else 0, v + 8, 255)
    return Image.fromarray(a)

def tile_cliff(part, seed=0):
    """Cara de acantilado bajo el borde del suelo (part 0 = arriba, 1 = abajo con picos que se desvanecen)."""
    rr = random.Random(seed * 13 + part)
    a = np.zeros((T, T, 4), dtype=np.uint8)
    teeth = [rr.randint(3, 13) for _ in range(T)]
    for x in range(1, T):
        teeth[x] = (teeth[x] + teeth[x - 1]) // 2
    for y in range(T):
        for x in range(T):
            gy = y + part * T
            if part == 1 and y > teeth[x]:
                continue
            strata = (gy // 3 + (x // 5)) % 3
            base = 78 - gy * 1.6
            v = base + (8 if strata == 0 else (-6 if strata == 2 else 0)) + rr.randint(-3, 3)
            a[y, x] = (int(v * 0.92), int(v * 0.78), int(v * 1.12), 255)
    if part == 0:
        a[0, :, :3] = (150, 132, 160)
        a[1, :, :3] = (96, 84, 108)
        for x in range(0, T, 5):
            for y in range(3, 9):
                a[y, (x + seed) % T, :3] = (34, 26, 40)
    else:
        for x in range(T):
            ty = teeth[x]
            if 0 <= ty < T:
                a[ty, x, :3] = (30, 22, 36)
    return Image.fromarray(a)

def tile_clear():
    return canvas(T, T)

tiles = [tile_floor(0), tile_floor(1), tile_floor(2), tile_floor(3), tile_ash(0), tile_ash(1),
         tile_wall_top(), tile_wall_face(0), tile_wall_face(1), tile_wall_face(3), tile_carpet(), tile_grate(), tile_void(),
         tile_floor(6, (0.9, 0.95, 1.15)), tile_floor(7, (0.9, 0.95, 1.15)), tile_floor(9, (1.1, 1.0, 0.85)),
         tile_cliff(0, 1), tile_cliff(1, 1), tile_clear(), tile_floor(12, (0.95, 1.08, 0.95))]
strip(tiles).save(f"{OUT}/tiles.png")

# ---------------------------------------------------------------- decoración
def pillar(broken=False):
    img = canvas(16, 40); d = ImageDraw.Draw(img)
    d.rectangle([2, 34, 13, 39], fill=C("4a4456"))
    top = 14 if broken else 4
    d.rectangle([4, top, 11, 34], fill=C("6a6478"))
    d.rectangle([9, top, 11, 34], fill=C("524c60"))
    for y in range(top + 3, 34, 5):
        d.point((5, y), fill=C("8a8498"))
    if broken:
        d.polygon([(4, top), (7, top - 3), (9, top + 1), (11, top - 2), (11, top)], fill=C("6a6478"))
    else:
        d.rectangle([2, 2, 13, 5], fill=C("7a7488"))
    return outline(img)

def candle(i):
    img = canvas(10, 16); d = ImageDraw.Draw(img)
    d.rectangle([2, 12, 7, 15], fill=C("3a3440"))
    d.rectangle([3, 6, 4, 12], fill=C("e8dcc0")); d.rectangle([6, 8, 7, 12], fill=C("d8ccb0"))
    img = outline(img); d = ImageDraw.Draw(img)
    f = [(0, 0), (0, -1), (1, 0), (0, 1)][i % 4]
    d.point((3 + f[0], 5 + f[1]), fill=C("ffd060")); d.point((3, 4 + f[1]), fill=C("fff4c0"))
    d.point((6, 7 + f[1]), fill=C("ffb040"))
    return img

def statue():
    img = humanoid(28, 40, dict(skin=C("8a8496"), hair=C("7a7488"), eye=C("5a5468"), armor=C("8a8496"), legs=C("7a7488"),
                                accent=C("6a6478"), cloak=C("6a6478"), wing=C("9a94a6"), halo=C("ffe27a")),
                   {"flap": 2}, wings=True, halo=False, scale=1.4)
    d = ImageDraw.Draw(img)
    d.rectangle([4, 36, 23, 39], fill=C("4a4456"))
    return img

def chains():
    img = canvas(8, 32); d = ImageDraw.Draw(img)
    for y in range(0, 32, 4):
        d.ellipse([2, y, 5, y + 4], outline=C("6a6670"))
    return img

def rubble(seed):
    img = canvas(16, 12); d = ImageDraw.Draw(img); rr = random.Random(seed)
    for k in range(4):
        x, y = rr.randint(1, 11), rr.randint(4, 8)
        d.polygon([(x, y + 3), (x + 2, y), (x + 4, y + 1), (x + 5, y + 4)], fill=C("5a5466"))
    return outline(img)

def chest(open_=False):
    img = canvas(16, 14); d = ImageDraw.Draw(img)
    d.rectangle([1, 5, 14, 13], fill=C("6a4428"))
    d.rectangle([1, 5, 14, 6], fill=C("c09040"))
    d.rectangle([7, 7, 8, 9], fill=C("ffd060"))
    if open_:
        d.rectangle([1, 1, 14, 4], fill=C("4a2e1a"))
        d.rectangle([3, 4, 12, 6], fill=C("ffe090"))
    else:
        d.rectangle([1, 2, 14, 5], fill=C("7a5030"))
        d.line([(1, 2), (14, 2)], fill=C("c09040"))
    return outline(img)

def gate(open_=False):
    img = canvas(48, 40); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 47, 39], fill=C("2e2838"))
    d.rectangle([4, 4, 43, 39], fill=C("120c16"))
    if not open_:
        for x in range(6, 44, 5):
            d.rectangle([x, 4, x + 1, 39], fill=C("8a7a5a"))
        d.line([(4, 18), (43, 18)], fill=C("8a7a5a"), width=2)
        ell(d, 24, 18, 4, 4, C("ffd060"))
        d.point((24, 18), fill=C("fff8d0"))
    d.rectangle([0, 0, 47, 3], fill=C("6a6278"))
    return outline(img)

strip([pillar(False), pillar(True)]).save(f"{OUT}/pillar.png")
strip([candle(i) for i in range(4)]).save(f"{OUT}/candle.png")
statue().save(f"{OUT}/statue.png")
chains().save(f"{OUT}/chains.png")
strip([rubble(i) for i in range(3)]).save(f"{OUT}/rubble.png")
strip([chest(False), chest(True)]).save(f"{OUT}/chest.png")
strip([gate(False), gate(True)]).save(f"{OUT}/gate.png")

# ---------------------------------------------------------------- armas (apuntando a la derecha, empuñadura en x=2)
def weapon(kind):
    img = canvas(32, 12); d = ImageDraw.Draw(img); y = 6
    if kind == "sword":
        d.rectangle([1, y - 1, 5, y], fill=C("6a4428")); d.rectangle([5, y - 3, 6, y + 2], fill=C("d0a040"))
        d.polygon([(7, y - 1), (22, y - 1), (25, y), (22, y + 1), (7, y + 1)], fill=C("e0e4f0"))
        d.line([(7, y - 1), (22, y - 1)], fill=C("ffffff"))
    elif kind == "spear":
        d.rectangle([0, y, 24, y], fill=C("7a5a3a")); d.rectangle([0, y + 1, 24, y + 1], fill=C("5a3e28"))
        d.polygon([(24, y - 2), (31, y), (24, y + 3)], fill=C("d8dce8"))
    elif kind == "scythe":
        d.rectangle([1, y, 18, y + 1], fill=C("4a3a4a"))
        d.polygon([(16, y - 5), (24, y - 4), (27, y + 1), (22, y - 2), (16, y - 2)], fill=C("c0b8d8"))
    elif kind == "hammer":
        d.rectangle([1, y, 18, y + 1], fill=C("6a4428"))
        d.rectangle([18, y - 4, 26, y + 5], fill=C("6a6670")); d.rectangle([18, y - 4, 26, y - 3], fill=C("9a96a0"))
        d.point((22, y), fill=C("ff6a20"))
    elif kind == "seravel":
        d.rectangle([1, y - 1, 5, y], fill=C("f0e0ff")); d.rectangle([5, y - 4, 6, y + 3], fill=C("ffd060"))
        d.polygon([(7, y - 2), (24, y - 1), (29, y), (24, y + 1), (7, y + 2)], fill=C("fff4f0"))
        d.line([(8, y), (26, y)], fill=C("ff4060"))
    return outline(img)

for k in ("sword", "spear", "scythe", "hammer", "seravel"):
    weapon(k).save(f"{OUT}/weapon_{k}.png")

# ---------------------------------------------------------------- proyectiles y FX
def soft(size, col=(255, 255, 255), power=2.0):
    a = np.zeros((size, size, 4), dtype=np.uint8)
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            r = math.hypot(x - c, y - c) / c
            v = max(0.0, 1 - r) ** power
            a[y, x] = (*col, int(255 * v))
    return Image.fromarray(a)

soft(16).save(f"{OUT}/fx_soft.png")
soft(128, power=1.6).save(f"{OUT}/light.png")

img = canvas(4, 4); ImageDraw.Draw(img).rectangle([1, 1, 2, 2], fill=(255, 255, 255, 255)); img.save(f"{OUT}/fx_px.png")

img = canvas(8, 8); d = ImageDraw.Draw(img)
d.polygon([(1, 6), (5, 1), (7, 2), (3, 7)], fill=C("ffffff")); d.line([(1, 7), (6, 2)], fill=C("c8c8d0"))
img.save(f"{OUT}/fx_feather.png")

img = canvas(16, 6); d = ImageDraw.Draw(img)
d.polygon([(0, 3), (10, 0), (16, 3), (10, 5)], fill=C("fff4c0")); d.line([(2, 3), (14, 3)], fill=C("ffffff"))
img.save(f"{OUT}/proj_lance.png")

img = canvas(10, 10); d = ImageDraw.Draw(img)
ell(d, 5, 5, 4, 4, C("b060ff")); ell(d, 5, 5, 2, 2, C("f0d8ff")); img.save(f"{OUT}/proj_orb.png")

img = canvas(10, 10); d = ImageDraw.Draw(img)
ell(d, 5, 5, 4, 4, C("ff4040")); ell(d, 5, 5, 2, 2, C("ffe0d0")); img.save(f"{OUT}/proj_red.png")

weapon("seravel").save(f"{OUT}/proj_sword.png")

# ---------------------------------------------------------------- iconos 16x16
def icon(kind):
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    if kind == "eco":
        ell(d, 8, 8, 5, 5, C("80c8ff")); ell(d, 7, 7, 2, 2, C("e8f8ff"))
    elif kind == "feather":
        d.polygon([(3, 13), (11, 2), (13, 4), (6, 13)], fill=C("f4f0ea")); d.line([(2, 14), (12, 3)], fill=C("c0b8b0"))
    elif kind == "flask":
        d.rectangle([6, 2, 9, 5], fill=C("a0a0a8")); ell(d, 8, 10, 4.5, 4, C("ff6a50")); ell(d, 7, 9, 1.5, 1.2, C("ffd0c0"))
    elif kind == "filo":
        d.line([(3, 13), (12, 3)], fill=C("e0e4f0"), width=2); d.line([(3, 9), (7, 13)], fill=C("d0a040"), width=2)
    elif kind == "ala":
        d.polygon([(2, 12), (6, 3), (14, 2), (10, 7), (13, 8), (6, 13)], fill=C("f4f0ea"))
    elif kind == "luz":
        ell(d, 8, 8, 3, 3, C("fff0a0"))
        for k in range(8):
            a = k * math.pi / 4
            d.line([(8 + 4 * math.cos(a), 8 + 4 * math.sin(a)), (8 + 6.5 * math.cos(a), 8 + 6.5 * math.sin(a))], fill=C("ffd060"))
    elif kind == "ceniza":
        d.polygon([(8, 2), (13, 5), (13, 10), (8, 14), (3, 10), (3, 5)], fill=C("6a6478")); d.polygon([(8, 5), (10, 7), (8, 11), (6, 7)], fill=C("ff8030"))
    elif kind == "arconte":
        d.ellipse([3, 2, 13, 6], outline=C("ffd060")); d.polygon([(8, 7), (12, 14), (4, 14)], fill=C("c01838"))
    elif kind == "lance":
        d.polygon([(2, 9), (11, 6), (15, 8), (11, 10)], fill=C("fff4c0"))
    elif kind == "nova":
        d.ellipse([2, 2, 14, 14], outline=C("ff8030")); ell(d, 8, 8, 3, 3, C("ffd060"))
    elif kind == "orbit":
        for k in range(3):
            a = k * 2 * math.pi / 3
            d.line([(8 + 2 * math.cos(a), 8 + 2 * math.sin(a)), (8 + 6 * math.cos(a), 8 + 6 * math.sin(a))], fill=C("fff4f0"), width=2)
    elif kind == "fire":
        d.polygon([(8, 2), (12, 9), (10, 14), (6, 14), (4, 9)], fill=C("ff6020")); d.polygon([(8, 7), (10, 11), (8, 14), (6, 11)], fill=C("ffd060"))
    elif kind == "quest":
        d.rectangle([4, 2, 12, 14], fill=C("d8c8a0")); d.line([(6, 5), (10, 5)], fill=C("6a4a30")); d.line([(6, 8), (10, 8)], fill=C("6a4a30"))
    return outline(img)

def item_icon(kind):
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    if kind == "bomb":
        ell(d, 8, 9, 5, 5, C("3a3442")); ell(d, 7, 8, 2, 2, C("6a6278")); d.line([(10, 4), (12, 2)], fill=C("c8a060"))
        d.point((13, 1), fill=C("ffd040")); d.point((12, 1), fill=C("ff7030"))
    elif kind == "phoenix":
        d.polygon([(3, 14), (10, 2), (13, 3), (7, 14)], fill=C("ff7030")); d.polygon([(5, 12), (10, 4), (11, 5), (7, 12)], fill=C("ffd060"))
        d.line([(2, 15), (11, 3)], fill=C("fff0c0"))
    elif kind == "incense":
        d.rectangle([5, 9, 10, 14], fill=C("8a6a4a")); d.rectangle([5, 9, 10, 10], fill=C("c09a60"))
        for i in range(4):
            d.point((7 + (i % 2), 7 - i * 2), fill=C("d8d0f0"))
    elif kind == "ointment":
        d.rectangle([4, 7, 11, 13], fill=C("6a7a8a")); d.rectangle([4, 5, 11, 7], fill=C("c0c8d0")); d.rectangle([6, 9, 9, 11], fill=C("40c0b0"))
    elif kind == "key":
        ell(d, 5, 6, 3, 3, C("ffd060")); ell(d, 5, 6, 1, 1, C("2a2030")); d.rectangle([7, 6, 14, 7], fill=C("ffd060")); d.rectangle([12, 8, 13, 10], fill=C("ffd060"))
    elif kind == "scroll":
        d.rectangle([3, 4, 12, 12], fill=C("e8d8b0")); d.rectangle([2, 3, 4, 13], fill=C("b89a70")); d.rectangle([11, 3, 13, 13], fill=C("b89a70"))
        d.line([(5, 6), (10, 6)], fill=C("8a6a4a")); d.line([(5, 9), (9, 9)], fill=C("8a6a4a"))
    elif kind == "iron":
        d.polygon([(2, 11), (8, 5), (14, 8), (9, 14)], fill=C("8aa0c8")); d.polygon([(8, 5), (14, 8), (10, 9)], fill=C("c8d8ff"))
    elif kind == "amulet_wing":
        d.line([(4, 1), (8, 6), (12, 1)], fill=C("c8a060")); ell(d, 8, 10, 4, 4, C("f0f0ff")); d.polygon([(6, 10), (8, 6), (10, 10), (8, 13)], fill=C("90c8ff"))
    elif kind == "amulet_ash":
        d.line([(4, 1), (8, 6), (12, 1)], fill=C("c8a060")); d.polygon([(8, 5), (12, 9), (8, 14), (4, 9)], fill=C("6a5a5a")); d.polygon([(8, 7), (10, 9), (8, 12), (6, 9)], fill=C("ff6a20"))
    elif kind == "amulet_eye":
        d.line([(4, 1), (8, 6), (12, 1)], fill=C("c8a060")); ell(d, 8, 10, 5, 3, C("f8e8f0")); ell(d, 8, 10, 2, 2, C("ff3050")); d.point((8, 10), fill=C("200810"))
    elif kind == "memory":
        d.polygon([(8, 1), (13, 8), (8, 15), (3, 8)], fill=C("a0d8ff")); d.polygon([(8, 3), (11, 8), (8, 13)], fill=C("e8f8ff"))
    elif kind == "heart":
        d.polygon([(8, 14), (2, 7), (2, 4), (4, 2), (7, 3), (8, 4), (9, 3), (12, 2), (14, 4), (14, 7)], fill=C("ff2e4d"))
        d.rectangle([4, 4, 5, 5], fill=C("ffb0c0"))
    elif kind == "bench":
        pass
    return outline(img)

for k in ("bomb", "phoenix", "incense", "ointment", "key", "scroll", "iron", "amulet_wing", "amulet_ash", "amulet_eye", "memory", "heart"):
    item_icon(k).save(f"{OUT}/icon_{k}.png")

def bench():
    img = canvas(28, 14); d = ImageDraw.Draw(img)
    d.rectangle([1, 4, 26, 7], fill=C("6a6478")); d.rectangle([1, 4, 26, 4], fill=C("8a8498"))
    d.rectangle([3, 8, 5, 13], fill=C("4a4456")); d.rectangle([22, 8, 24, 13], fill=C("4a4456"))
    d.point((10, 5), fill=C("5a5468")); d.point((17, 6), fill=C("5a5468"))
    return outline(img)
bench().save(f"{OUT}/bench.png")

def broken_wing():
    img = canvas(48, 40); d = ImageDraw.Draw(img)
    stone = C("8a8496"); dark = C("5a5468")
    for i in range(7):
        k = i / 6.0
        ang = math.radians(-20 - 60 * k)
        L = 38 - k * 14
        x0, y0 = 6, 36
        x1, y1 = x0 + math.cos(ang) * L, y0 + math.sin(ang) * L
        d.line([(x0, y0), (x1, y1)], fill=stone if i % 2 == 0 else dark, width=4)
    d.polygon([(0, 34), (16, 32), (20, 39), (0, 39)], fill=C("4a4456"))
    return outline(img)
broken_wing().save(f"{OUT}/broken_wing.png")

for k in ("eco", "feather", "flask", "filo", "ala", "luz", "ceniza", "arconte", "lance", "nova", "orbit", "fire", "quest"):
    icon(k).save(f"{OUT}/icon_{k}.png")

# ---------------------------------------------------------------- título y fondo de menú
def title_bg():
    W, H = 640, 360
    a = np.zeros((H, W, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:H, 0:W]
    g = 1 - (yy / H)
    a[..., 0] = (14 + 30 * (1 - g) ** 2).astype(np.uint8)
    a[..., 1] = (10 + 8 * (1 - g)).astype(np.uint8)
    a[..., 2] = (22 + 20 * g).astype(np.uint8)
    a[..., 3] = 255
    img = Image.fromarray(a); d = ImageDraw.Draw(img)
    # espiral descendente (anillos)
    for i in range(14):
        r = 300 - i * 20
        y0 = 250 + i * 6
        col = (40 + i * 6, 26 + i * 2, 50 + i * 3, 255)
        d.ellipse([320 - r, y0 - r * 0.22, 320 + r, y0 + r * 0.22], outline=col, width=2)
    # abismo central
    ell(d, 320, 330, 60, 14, (8, 4, 10, 255))
    # torres/agujas
    rr = random.Random(3)
    for k in range(18):
        x = rr.randint(0, W); h = rr.randint(40, 140)
        d.polygon([(x - 6, H), (x, H - h), (x + 6, H)], fill=(12, 8, 16, 255))
    return img

title_bg().save(f"{OUT}/title_bg.png")
print("Arte generado en", os.path.abspath(OUT))

# ================================================================ arte de cinemáticas (vista frontal)
CIN = os.path.join(OUT, "cinematic")
os.makedirs(CIN, exist_ok=True)

def hshade(img, light=1.12, dark=0.72):
    """Sombreado frontal: más claro a la izquierda, más oscuro a la derecha, por silueta."""
    a = np.array(img).astype(float)
    alpha = a[:, :, 3] > 0
    h, w = alpha.shape
    for y in range(h):
        xs = np.where(alpha[y])[0]
        if len(xs) == 0:
            continue
        x0, x1 = xs.min(), xs.max()
        span = max(1, x1 - x0)
        for x in xs:
            k = (x - x0) / span
            f = light if k < 0.3 else (dark if k > 0.72 else 1.0)
            a[y, x, :3] *= f
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))

def feather_wing(W, H, base, shade_col, tip_col, seed=1):
    """Ala izquierda vista de frente: raíz a la derecha, plumas en abanico hacia la izquierda."""
    img = canvas(W, H); d = ImageDraw.Draw(img); rr = random.Random(seed)
    root = (W - 8, 28)
    layers = [  # (n, longitud, anchura, color, desfase)
        (11, 74, 4.5, tip_col, 0.0),
        (10, 54, 5.0, shade_col, 0.05),
        (9, 32, 5.5, base, 0.1),
    ]
    for (n, L, wdt, col, off) in layers:
        for i in range(n):
            k = i / (n - 1)
            a = math.pi + 1.05 - k * 1.95 + off
            length = L * (0.55 + 0.45 * math.sin(0.35 + k * 2.4)) * (0.95 + 0.1 * rr.random())
            bx = root[0] - 6 * k
            by = root[1] + 18 * k
            dx, dy = math.cos(a), math.sin(a)
            tipx, tipy = bx + dx * length, by + dy * length
            px, py = -dy * wdt, dx * wdt
            d.polygon([(bx + px * 0.5, by + py * 0.5), (bx + dx * length * 0.7 + px, by + dy * length * 0.7 + py),
                       (tipx, tipy), (bx + dx * length * 0.7 - px * 0.3, by + dy * length * 0.7 - py * 0.3), (bx - px * 0.3, by - py * 0.3)], fill=col)
            d.line([(bx, by), (bx + dx * length * 0.85, by + dy * length * 0.85)], fill=shade(col, 0.82))
    # hueso del ala (borde superior)
    d.line([root, (root[0] - 30, root[1] - 18), (root[0] - 52, root[1] - 26)], fill=base, width=4)
    return outline(img)

def seravel_cine():
    W, H = 72, 112
    body = canvas(W, H); d = ImageDraw.Draw(body)
    cx = W // 2
    white, lav, crimson, gold, skin = C("f4eefa"), C("b8a8d8"), C("c01838"), C("ffd060"), C("f8e0d0")
    hair = C("a898d8"); armor = C("e0dcec")
    # vestido largo flotante con bajos rasgados
    pts = [(cx - 9, 46), (cx + 9, 46), (cx + 16, 80), (cx + 22, 104)]
    for i in range(6):
        x = cx + 22 - i * 9
        pts.append((x - 4, 111 if i % 2 == 0 else 104))
    pts += [(cx - 22, 104), (cx - 16, 80)]
    d.polygon(pts, fill=white)
    d.polygon([(cx - 3, 46), (cx + 3, 46), (cx + 6, 108), (cx - 6, 108)], fill=shade(white, 0.9))
    for k in range(4):
        d.line([(cx - 12 + k * 8, 60), (cx - 16 + k * 10, 104)], fill=lav)
    # fajín carmesí y borde dorado
    d.rectangle([cx - 10, 44, cx + 10, 49], fill=crimson)
    d.polygon([(cx + 2, 49), (cx + 7, 49), (cx + 10, 74), (cx + 5, 72)], fill=crimson)
    d.line([(cx - 22, 104), (cx + 22, 104)], fill=gold)
    # torso con coraza
    d.polygon([(cx - 11, 26), (cx + 11, 26), (cx + 9, 45), (cx - 9, 45)], fill=armor)
    d.line([(cx, 27), (cx, 44)], fill=gold)
    d.arc([cx - 9, 28, cx - 1, 38], 200, 340, fill=gold); d.arc([cx + 1, 28, cx + 9, 38], 200, 340, fill=gold)
    # hombreras
    ell(d, cx - 12, 28, 5, 4, armor); ell(d, cx + 12, 28, 5, 4, armor)
    d.arc([cx - 17, 24, cx - 7, 32], 180, 360, fill=gold); d.arc([cx + 7, 24, cx + 17, 32], 180, 360, fill=gold)
    # brazos
    d.polygon([(cx - 16, 30), (cx - 12, 30), (cx - 13, 52), (cx - 17, 52)], fill=white)
    d.polygon([(cx + 12, 30), (cx + 16, 30), (cx + 18, 50), (cx + 14, 52)], fill=white)
    ell(d, cx - 15, 54, 2.5, 2.5, skin); ell(d, cx + 16, 53, 2.5, 2.5, skin)
    # cuello y cabeza
    d.rectangle([cx - 3, 20, cx + 3, 26], fill=skin)
    ell(d, cx, 15, 7, 8, skin)
    # pelo largo a ambos lados
    d.polygon([(cx - 8, 10), (cx - 11, 22), (cx - 13, 40), (cx - 8, 36), (cx - 6, 18)], fill=hair)
    d.polygon([(cx + 8, 10), (cx + 11, 22), (cx + 13, 40), (cx + 8, 36), (cx + 6, 18)], fill=hair)
    d.chord([cx - 8, 5, cx + 8, 20], 180, 360, fill=hair)
    d.polygon([(cx - 8, 12), (cx - 2, 8), (cx - 4, 14)], fill=hair)
    # ojos cerrados y labios
    d.line([(cx - 4, 16), (cx - 2, 16)], fill=C("6a5070")); d.line([(cx + 2, 16), (cx + 4, 16)], fill=C("6a5070"))
    d.point((cx, 20), fill=C("c06070"))
    body = hshade(outline(body))
    body.save(f"{CIN}/seravel_body.png")
    # ojos abiertos (capa)
    eyes = canvas(W, H); de = ImageDraw.Draw(eyes)
    de.rectangle([cx - 5, 15, cx - 2, 16], fill=C("ff2040")); de.rectangle([cx + 2, 15, cx + 5, 16], fill=C("ff2040"))
    de.point((cx - 3, 15), fill=C("fff0f0")); de.point((cx + 4, 15), fill=C("fff0f0"))
    eyes.save(f"{CIN}/seravel_eyes.png")
    # alas
    wl = feather_wing(96, 104, C("fffaf2"), C("e4dcec"), C("c8bce0"), 3)
    wl.save(f"{CIN}/seravel_wing.png")
    # aureola
    hal = canvas(44, 14); dh = ImageDraw.Draw(hal)
    dh.ellipse([1, 1, 42, 12], outline=C("ffe060"), width=2); dh.ellipse([4, 3, 39, 10], outline=C("fff6c0"))
    hal.save(f"{CIN}/seravel_halo.png")
    # espada larga
    sw = canvas(12, 84); ds = ImageDraw.Draw(sw)
    ds.rectangle([4, 0, 7, 10], fill=C("f0e0ff")); ds.rectangle([0, 10, 11, 13], fill=C("ffd060"))
    ds.polygon([(3, 14), (8, 14), (8, 76), (5.5, 83), (3, 76)], fill=C("fff4f0"))
    ds.line([(5, 15), (5, 78)], fill=C("ff4060"))
    outline(sw).save(f"{CIN}/seravel_sword.png")

def carcelero_cine():
    W, H = 92, 112
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx = W // 2
    metal, dark, rust, chain = C("6e6a76"), C("3e3a46"), C("8a4a30"), C("9a96a2")
    # piernas
    d.rectangle([cx - 20, 82, cx - 7, 110], fill=dark); d.rectangle([cx + 7, 82, cx + 20, 110], fill=dark)
    d.rectangle([cx - 23, 104, cx - 5, 111], fill=metal); d.rectangle([cx + 5, 104, cx + 23, 111], fill=metal)
    # torso enorme
    d.polygon([(cx - 30, 30), (cx + 30, 30), (cx + 26, 84), (cx - 26, 84)], fill=metal)
    for y in range(36, 84, 7):
        d.line([(cx - 28, y), (cx + 28, y)], fill=rust)
    for k in range(-2, 3):
        d.line([(cx + k * 10, 32), (cx + k * 10, 82)], fill=shade(metal, 0.8))
    # cadenas cruzadas
    for i in range(0, 52, 4):
        d.ellipse([cx - 28 + i, 34 + i * 0.8, cx - 24 + i, 38 + i * 0.8], outline=chain)
        d.ellipse([cx + 24 - i, 34 + i * 0.8, cx + 28 - i, 38 + i * 0.8], outline=chain)
    # hombros y brazos
    ell(d, cx - 32, 34, 9, 8, metal); ell(d, cx + 32, 34, 9, 8, metal)
    d.polygon([(cx - 40, 38), (cx - 28, 38), (cx - 30, 74), (cx - 42, 74)], fill=dark)
    d.polygon([(cx + 28, 38), (cx + 40, 38), (cx + 42, 74), (cx + 30, 74)], fill=dark)
    ell(d, cx - 36, 78, 6, 5, metal); ell(d, cx + 36, 78, 6, 5, metal)
    # casco jaula
    d.rectangle([cx - 13, 6, cx + 13, 30], fill=C("140c12"))
    for x in range(cx - 13, cx + 14, 4):
        d.line([(x, 6), (x, 30)], fill=metal)
    d.line([(cx - 13, 14), (cx + 13, 14)], fill=metal); d.line([(cx - 13, 22), (cx + 13, 22)], fill=metal)
    d.arc([cx - 14, 0, cx + 14, 14], 180, 360, fill=metal, width=2)
    img = hshade(outline(img))
    img.save(f"{CIN}/carcelero_body.png")
    eyes = canvas(W, H); de = ImageDraw.Draw(eyes)
    de.rectangle([cx - 7, 17, cx - 3, 19], fill=C("ff6a20")); de.rectangle([cx + 3, 17, cx + 7, 19], fill=C("ff6a20"))
    de.point((cx - 5, 17), fill=C("fff0c0")); de.point((cx + 5, 17), fill=C("fff0c0"))
    eyes.save(f"{CIN}/carcelero_eyes.png")
    ball = canvas(40, 70); db = ImageDraw.Draw(ball)
    for y in range(0, 48, 4):
        db.ellipse([18, y, 22, y + 5], outline=chain)
    ell(db, 20, 58, 10, 10, C("4a4650"))
    for a in range(0, 360, 45):
        r = math.radians(a)
        db.polygon([(20 + math.cos(r) * 9, 58 + math.sin(r) * 9), (20 + math.cos(r + 0.25) * 9, 58 + math.sin(r + 0.25) * 9), (20 + math.cos(r + 0.12) * 15, 58 + math.sin(r + 0.12) * 15)], fill=C("8a8690"))
    outline(ball).save(f"{CIN}/carcelero_ball.png")

def player_back(pal, name):
    W, H = 30, 40
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx = W // 2
    # alas pequeñas
    d.polygon([(cx - 3, 14), (cx - 13, 6), (cx - 14, 18), (cx - 6, 22)], fill=pal["wing"])
    d.polygon([(cx + 3, 14), (cx + 13, 6), (cx + 14, 18), (cx + 6, 22)], fill=shade(pal["wing"], 0.85))
    # capa
    d.polygon([(cx - 7, 14), (cx + 7, 14), (cx + 9, 36), (cx - 9, 36)], fill=pal["cloak"])
    d.line([(cx, 15), (cx, 35)], fill=shade(pal["cloak"], 0.8))
    d.rectangle([cx - 5, 35, cx - 2, 39], fill=pal["legs"]); d.rectangle([cx + 2, 35, cx + 5, 39], fill=pal["legs"])
    # cabeza (pelo de espaldas)
    ell(d, cx, 9, 5, 5.5, pal["hair"])
    d.ellipse([cx - 5, 0, cx + 5, 3], outline=pal["halo"])
    # espada a un lado
    d.line([(cx + 9, 18), (cx + 13, 38)], fill=C("e0e4f0"), width=2)
    out = hshade(outline(img))
    out.save(f"{CIN}/{name}.png")

seravel_cine()
carcelero_cine()
player_back(P1, "player_back_p1")
player_back(P2, "player_back_p2")
print("Cinemáticas generadas")

# ================================================================ v0.3: objetos únicos, PNJ, jefes y salas
def unique_icon(kind):
    img = canvas(16, 16); d = ImageDraw.Draw(img)
    if kind == "bomb":  # Nudo de Brasa: plumas negras anudadas con brasa dentro
        d.polygon([(8, 2), (13, 7), (11, 13), (5, 13), (3, 7)], fill=C("2a1a2a"))
        d.line([(4, 5), (12, 11)], fill=C("4a3048")); d.line([(12, 5), (4, 11)], fill=C("4a3048"))
        ell(d, 8, 9, 2.5, 2.5, C("ff6020")); d.point((8, 8), fill=C("fff0a0"))
        d.line([(8, 2), (10, 0)], fill=C("ffb040"))
    elif kind == "incense":  # Himno Embotellado: vial con notas de luz
        d.rectangle([6, 1, 9, 3], fill=C("c8a060")); d.polygon([(5, 4), (10, 4), (12, 9), (10, 14), (5, 14), (3, 9)], fill=C("6a5aa0"))
        d.polygon([(5, 9), (10, 9), (10, 13), (5, 13)], fill=C("ffd860"))
        d.point((6, 6), fill=C("fff8e0")); d.point((9, 11), fill=C("ffffff")); d.point((7, 12), fill=C("ffffff"))
    elif kind == "ointment":  # Escama de Querubín
        d.polygon([(8, 1), (14, 6), (12, 13), (8, 15), (4, 13), (2, 6)], fill=C("6ad8d0"))
        d.polygon([(8, 3), (12, 7), (8, 12), (4, 7)], fill=C("c8fff8")); d.line([(8, 3), (8, 13)], fill=C("3a9a98"))
    elif kind == "phoenix":  # Plumón de Aurora
        d.polygon([(3, 14), (9, 3), (13, 2), (12, 6), (6, 14)], fill=C("ff9ad0")); d.polygon([(5, 12), (10, 4), (11, 5), (7, 12)], fill=C("ffe0a0"))
        d.line([(2, 15), (12, 3)], fill=C("ffffff")); d.point((13, 1), fill=C("a0e0ff"))
    elif kind == "amulet_wing":  # Vértebra de Serafín
        d.line([(4, 1), (8, 4), (12, 1)], fill=C("c8a060"))
        for i, y in enumerate((5, 8, 11)):
            d.rectangle([6, y, 10, y + 2], fill=C("f0e8dc")); d.point((5, y + 1), fill=C("d0c8bc")); d.point((11, y + 1), fill=C("d0c8bc"))
        d.point((8, 14), fill=C("a0d0ff"))
    elif kind == "amulet_ash":  # Corazón de Rescoldo
        d.line([(4, 1), (8, 4), (12, 1)], fill=C("c8a060"))
        d.polygon([(8, 14), (3, 9), (3, 6), (5, 4), (8, 6), (11, 4), (13, 6), (13, 9)], fill=C("4a2a2a"))
        d.polygon([(8, 12), (5, 9), (6, 7), (8, 8), (10, 7), (11, 9)], fill=C("ff5a20")); d.point((8, 9), fill=C("ffe080"))
    elif kind == "amulet_eye":  # Ojo de la Guardiana
        d.line([(4, 1), (8, 4), (12, 1)], fill=C("c8a060")); ell(d, 8, 10, 5, 3, C("f8e8f0")); ell(d, 8, 10, 2, 2, C("ff3050")); d.point((8, 10), fill=C("200810"))
        d.ellipse([3, 4, 13, 7], outline=C("ffd060"))
    elif kind == "key":  # Llave de Hueso Cantor
        d.rectangle([3, 6, 12, 8], fill=C("e8dcc8")); ell(d, 3, 7, 2.5, 3, C("e8dcc8")); d.point((3, 7), fill=C("402030"))
        d.rectangle([10, 9, 11, 11], fill=C("e8dcc8")); d.rectangle([12, 9, 13, 12], fill=C("e8dcc8"))
        d.point((6, 5), fill=C("80d0ff")); d.point((8, 4), fill=C("80d0ff"))
    elif kind == "iron":  # Esquirla de Nimbo
        d.polygon([(8, 1), (12, 7), (9, 15), (5, 10), (5, 5)], fill=C("ffe27a")); d.polygon([(8, 1), (10, 6), (8, 12), (6, 6)], fill=C("fff8d0"))
    elif kind == "tear":  # Lágrima Cristalizada
        d.polygon([(8, 1), (12, 8), (11, 12), (8, 14), (5, 12), (4, 8)], fill=C("60a8ff")); d.polygon([(8, 4), (10, 9), (8, 12), (6, 9)], fill=C("d8f0ff"))
    elif kind == "choir_heart":  # Garganta de Cristal (amuleto del Coro)
        d.line([(4, 1), (8, 4), (12, 1)], fill=C("c8a060")); d.polygon([(8, 5), (12, 9), (8, 14), (4, 9)], fill=C("b090ff"))
        for i in range(3):
            d.arc([6 - i * 2, 7 - i * 2, 10 + i * 2, 11 + i * 2], 300, 60, fill=C("f0e0ff"))
    return outline(img)

for k in ("bomb", "incense", "ointment", "phoenix", "amulet_wing", "amulet_ash", "amulet_eye", "key", "iron", "tear", "choir_heart"):
    unique_icon(k).save(f"{OUT}/icon_{k}.png")

# ---------------------------------------------------------------- PNJ de la Sala del Nimbo
def npc_extra(pal, acc):
    rows = [humanoid(24, 26, pal, {"bob": [0, 0, 1, 1][i], "arm": [0, 0, 1, 0][i] if acc == "hammer" else 0}, wings=acc == "wings", halo=False) for i in range(4)]
    out = []
    for i, f in enumerate(rows):
        d = ImageDraw.Draw(f)
        if acc == "hood":       # capucha con runas
            d.polygon([(7, 3), (17, 3), (18, 9), (6, 9)], fill=pal["cloak"]); d.point((12, 2), fill=C("80f0ff")); d.point((9, 15 + (i % 2)), fill=C("80f0ff"))
        elif acc == "veil":     # velo blanco
            d.polygon([(7, 2), (17, 2), (19, 14), (5, 14)], fill=C("f0f0ff")); d.point((13, 7), fill=C("6080c0"))
        elif acc == "mask":     # máscara de pico y plumas negras
            d.polygon([(13, 5), (19, 7), (13, 8)], fill=C("e8dcc8")); d.line([(6, 10), (3, 6)], fill=C("201828")); d.line([(18, 10), (21, 6)], fill=C("201828"))
        elif acc == "censer":   # incensario rojo (hábito carmesí)
            sx = 18 + (i % 2)
            d.line([(17, 12), (sx, 18)], fill=C("c8a060")); ell(d, sx, 19, 1.5, 1.5, C("ffb040"))
        out.append(f)
    return sheet([out])

OZIAS = dict(skin=C("8a7a90"), hair=C("2a2a40"), eye=C("80f0ff"), armor=C("2a3a5a"), legs=C("1a2030"), accent=C("80f0ff"), cloak=C("1e2a48"), wing=C("707a90"), halo=C("ffffff"))
ILSE = dict(skin=C("e8d8d0"), hair=C("e8e8f8"), eye=C("6080c0"), armor=C("c8d8f0"), legs=C("8090b0"), accent=C("60a8ff"), cloak=C("a0b8e0"), wing=C("f0f0ff"), halo=C("ffffff"))
NYX = dict(skin=C("a08070"), hair=C("181020"), eye=C("ffd060"), armor=C("2a2030"), legs=C("181018"), accent=C("ffd060"), cloak=C("201828"), wing=C("2a2030"), halo=C("ffffff"))
VELARIA = dict(skin=C("e0c0b0"), hair=C("801020"), eye=C("ff6080"), armor=C("801828"), legs=C("401018"), accent=C("ffd060"), cloak=C("601020"), wing=C("c0a0a0"), halo=C("ffffff"))
npc_extra(OZIAS, "hood").save(f"{OUT}/npc_ozias.png")
npc_extra(ILSE, "veil").save(f"{OUT}/npc_ilse.png")
npc_extra(NYX, "mask").save(f"{OUT}/npc_nyx.png")
npc_extra(VELARIA, "censer").save(f"{OUT}/npc_velaria.png")

# ---------------------------------------------------------------- decoración de salas de combate
def cage():
    img = canvas(18, 30); d = ImageDraw.Draw(img)
    d.line([(9, 0), (9, 6)], fill=C("8a8690"))
    d.arc([1, 4, 17, 14], 180, 360, fill=C("6a6670"), width=2)
    for x in range(2, 17, 3):
        d.line([(x, 9), (x, 28)], fill=C("6a6670"))
    d.rectangle([1, 27, 17, 29], fill=C("4a4650")); d.line([(1, 18), (17, 18)], fill=C("6a6670"))
    d.point((7, 22), fill=C("e8dcc8")); d.point((8, 23), fill=C("e8dcc8")); d.point((10, 23), fill=C("e8dcc8"))
    return outline(img)

def brazier(i):
    img = canvas(16, 24); d = ImageDraw.Draw(img)
    d.polygon([(2, 12), (14, 12), (11, 17), (5, 17)], fill=C("5a5462")); d.rectangle([7, 17, 9, 22], fill=C("4a4456")); d.rectangle([4, 22, 12, 23], fill=C("4a4456"))
    img = outline(img); d = ImageDraw.Draw(img)
    rr = random.Random(i * 7)
    for k in range(9):
        x = 8 + rr.randint(-4, 4); y = 11 - rr.randint(0, 7 + i % 2)
        d.point((x, y), fill=[C("fff0a0"), C("ffb040"), C("ff5020")][min(2, (11 - y) // 3)])
    return img

def organ():
    img = canvas(40, 48); d = ImageDraw.Draw(img)
    for k, h in enumerate((30, 38, 44, 46, 44, 38, 30)):
        x = 3 + k * 5
        d.rectangle([x, 47 - h, x + 3, 47], fill=C("8a7a9a") if k % 2 else C("6a5a7a"))
        d.rectangle([x, 47 - h, x + 3, 48 - h], fill=C("c8b8d8")); d.point((x + 1, 47 - h + 6), fill=C("201828"))
    d.rectangle([0, 40, 39, 47], fill=C("3a2a48"))
    return outline(img)

def bones(i):
    img = canvas(16, 10); d = ImageDraw.Draw(img); rr = random.Random(i)
    for k in range(3):
        x, y = rr.randint(2, 12), rr.randint(3, 7)
        d.line([(x - 3, y), (x + 3, y + rr.randint(-1, 1))], fill=C("d8ccb8"))
        d.point((x - 3, y - 1), fill=C("d8ccb8")); d.point((x + 3, y + 1), fill=C("d8ccb8"))
    if i == 1:
        ell(d, 8, 4, 2.5, 2, C("e0d4c0")); d.point((7, 4), fill=C("201820")); d.point((9, 4), fill=C("201820"))
    return outline(img)

def banner(col):
    img = canvas(14, 30); d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 13, 1], fill=C("8a7a5a"))
    d.polygon([(1, 2), (12, 2), (12, 24), (6, 29), (1, 24)], fill=col)
    d.ellipse([3, 8, 10, 12], outline=C("ffd060")); d.line([(6, 13), (6, 20)], fill=C("ffd060"))
    return outline(img)

strip([cage(), cage()]).save(f"{OUT}/cage.png")
strip([brazier(i) for i in range(4)]).save(f"{OUT}/brazier.png")
organ().save(f"{OUT}/organ.png")
strip([bones(i) for i in range(3)]).save(f"{OUT}/bones.png")
strip([banner(C("8a1828")), banner(C("3a2a68"))]).save(f"{OUT}/banner.png")

# ---------------------------------------------------------------- El Coro Hueco (jefe opcional)
def singer(frame, tint):
    W, H = 26, 36
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx = 13; bob = [0, -1, -2, -1][frame % 4]
    robe = tint; dark = shade(tint, 0.6)
    # túnica flotante con jirones
    pts = [(cx - 5, 12 + bob), (cx + 5, 12 + bob), (cx + 8, 30 + bob)]
    for k in range(5):
        pts.append((cx + 8 - k * 4, (35 if k % 2 == 0 else 31) + bob + (frame % 2)))
    pts += [(cx - 8, 30 + bob)]
    d.polygon(pts, fill=robe)
    d.line([(cx, 13 + bob), (cx, 31 + bob)], fill=dark)
    # capucha
    ell(d, cx, 9 + bob, 6, 7, robe)
    ell(d, cx, 10 + bob, 3.5, 4.5, C("0c0610"))
    # boca que canta (brilla)
    mo = 1 + (frame % 2)
    d.ellipse([cx - 1, 11 + bob, cx + 1, 11 + bob + mo + 1], fill=C("f0d8ff"))
    d.point((cx - 2, 8 + bob), fill=C("c0a0ff")); d.point((cx + 2, 8 + bob), fill=C("c0a0ff"))
    # cintas
    for s in (-1, 1):
        d.line([(cx + 5 * s, 16 + bob), (cx + 11 * s, 20 + bob + (frame % 3)), (cx + 9 * s, 27 + bob)], fill=C("ffd060"))
    return outline(img)

sheet([[singer(i, C("4a3a7a")) for i in range(4)], [singer(i, C("7a3a6a")) for i in range(4)], [singer(i, C("3a5a7a")) for i in range(4)]]).save(f"{OUT}/boss_singer.png")

def choir_giant(frame, enraged=False):
    W, H = 72, 92
    img = canvas(W, H); d = ImageDraw.Draw(img)
    cx = 36; bob = [0, -1, -2, -1][frame % 4]
    robe = C("4a2a6a") if not enraged else C("6a1a3a"); dark = shade(robe, 0.6)
    pts = [(cx - 14, 26 + bob), (cx + 14, 26 + bob), (cx + 26, 80 + bob)]
    for k in range(7):
        pts.append((cx + 26 - k * 8.6, (91 if k % 2 == 0 else 84) + bob))
    pts += [(cx - 26, 80 + bob)]
    d.polygon(pts, fill=robe)
    for k in range(-2, 3):
        d.line([(cx + k * 4, 28 + bob), (cx + k * 9, 84 + bob)], fill=dark)
    # tres capuchas fusionadas
    for i, ox in enumerate((-13, 0, 13)):
        oy = 0 if ox == 0 else 6
        ell(d, cx + ox, 16 + oy + bob, 9, 11, robe)
        ell(d, cx + ox, 18 + oy + bob, 5, 7, C("0c0610"))
        glow = C("f0d8ff") if not enraged else C("ff8080")
        d.ellipse([cx + ox - 2, 20 + oy + bob, cx + ox + 2, 22 + oy + bob + (frame % 2) * 2], fill=glow)
        d.point((cx + ox - 2, 15 + oy + bob), fill=glow); d.point((cx + ox + 2, 15 + oy + bob), fill=glow)
    # coro de cintas doradas y corona de diapasones
    for s in (-1, 1):
        for k in range(3):
            d.line([(cx + 12 * s, 34 + k * 6 + bob), (cx + (26 + k * 3) * s, 30 + k * 10 + bob + (frame % 2))], fill=C("ffd060"))
    for k in range(5):
        x = cx - 16 + k * 8
        d.line([(x, 4 + bob), (x, 0 + bob)], fill=C("ffd060")); d.point((x - 1, 0 + bob), fill=C("ffd060")); d.point((x + 1, 0 + bob), fill=C("ffd060"))
    return outline(img)

sheet([[choir_giant(i) for i in range(4)], [choir_giant(i, True) for i in range(4)]]).save(f"{OUT}/boss_choir_giant.png")

def weapon_choir():
    img = canvas(32, 12); d = ImageDraw.Draw(img); y = 6
    d.rectangle([1, y - 1, 5, y], fill=C("6a4a8a")); d.rectangle([5, y - 3, 6, y + 2], fill=C("ffd060"))
    d.rectangle([7, y - 3, 26, y - 2], fill=C("e0d8ff")); d.rectangle([7, y + 1, 26, y + 2], fill=C("e0d8ff"))
    d.point((27, y - 2), fill=C("ffffff")); d.point((27, y + 1), fill=C("ffffff"))
    for x in range(9, 26, 4):
        d.point((x, y - 1), fill=C("b090ff"))
    return outline(img)
weapon_choir().save(f"{OUT}/weapon_choir.png")
proj = canvas(10, 10); dp = ImageDraw.Draw(proj)
dp.ellipse([1, 1, 8, 8], fill=C("c0a0ff")); dp.rectangle([5, 0, 6, 5], fill=C("ffffff")); dp.ellipse([3, 5, 6, 8], fill=C("ffffff"))
proj.save(f"{OUT}/proj_note.png")
print("v0.3: objetos, PNJ, salas y Coro generados")

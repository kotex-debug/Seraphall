#!/usr/bin/env python3
"""SERAPHALL - iconos del HUD estilo "fila de iconos" (corazones, llamas de aguante y cristales de Luz).
Escribe assets/sprites/hud_hearts.png, hud_flames.png y hud_crystals.png (una tira de fotogramas cada uno)."""
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
INK = (18, 10, 24, 255)

def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def from_pattern(rows, pal):
    h = len(rows); w = len(rows[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        assert len(r) == w, (r, len(r), w)
        for x, ch in enumerate(r):
            if ch != ".":
                img.putpixel((x, y), pal[ch])
    return img

def strip(frames):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.paste(f, (i * w, 0), f)
    return s

def half(rows, cut, empty_map):
    """Deja la mitad izquierda (columnas < cut) llena y vacía el resto."""
    out = []
    for r in rows:
        out.append("".join(ch if (x < cut or ch in ".X") else empty_map.get(ch, "e") for x, ch in enumerate(r)))
    return out

def emptied(rows, empty_map):
    return ["".join(ch if ch in ".X" else empty_map.get(ch, "e") for ch in r) for r in rows]

# ------------------------------------------------------------------ corazones (11x10)
HEART = [
    "..XXX.XXX..",
    ".XllrXrrrX.",
    "XlwlrrrrrdX",
    "XlwrrrrrrdX",
    "XlrrrrrrrdX",
    ".XrrrrrrdX.",
    "..XrrrrdX..",
    "...XrrdX...",
    "....XdX....",
    ".....X.....",
]
EMPTY_MAP = {"l": "E", "w": "E", "r": "e", "d": "e"}
def heart_pal(base, light, dark, outline=INK, empty=C("2a0f1c"), empty_hi=C("4a2032")):
    return {"X": outline, "l": light, "w": C("ffffff"), "r": base, "d": dark, "e": empty, "E": empty_hi}

red = heart_pal(C("e8203a"), C("ff7a86"), C("8e0e24"))
flash = heart_pal(C("ffffff"), C("ffffff"), C("ffd0d8"), outline=C("ffffff"), empty=C("ffb0bc"), empty_hi=C("ffe0e6"))
gold = heart_pal(C("f0b830"), C("fff0a0"), C("a06a10"))          # corazón dorado (escudo de Escama)
void = heart_pal(C("7a3ad8"), C("c8a0ff"), C("3a1478"))           # corazón del Desplumado (agrietado)
hearts = [
    from_pattern(HEART, red),
    from_pattern(half(HEART, 6, EMPTY_MAP), red),
    from_pattern(emptied(HEART, EMPTY_MAP), red),
    from_pattern(HEART, flash),
    from_pattern(half(HEART, 6, EMPTY_MAP), flash),
    from_pattern(emptied(HEART, EMPTY_MAP), flash),
    from_pattern(HEART, gold),
    from_pattern(half(HEART, 6, EMPTY_MAP), gold),
]
# grieta del Desplumado sobre un corazón lleno
cracked = [list(r) for r in HEART]
for x, y in ((5, 2), (4, 3), (5, 4), (6, 5), (5, 6)):
    cracked[y][x] = "X"
hearts.append(from_pattern(["".join(r) for r in cracked], red))
hearts.append(from_pattern(half(["".join(r) for r in cracked], 6, EMPTY_MAP), red))
strip(hearts).save(f"{OUT}/hud_hearts.png")

# ------------------------------------------------------------------ llamas de aguante (9x11)
FLAMES = [
    [
        "....X....",
        "...XyX...",
        "...XoyX..",
        "..XoyoX..",
        "..XoywoX.",
        ".XoywwyX.",
        ".XoywwyoX",
        "XroywwyoX",
        "XroyywyrX",
        ".XrooorX.",
        "..XXXXX..",
    ],
    [
        "...X.....",
        "..XyX....",
        "..XoyX...",
        "..XoyoX..",
        ".XooywoX.",
        ".XoywwyX.",
        "XooywwyoX",
        "XroywwyoX",
        "XroyywyrX",
        ".XrooorX.",
        "..XXXXX..",
    ],
    [
        ".....X...",
        "....XyX..",
        "...XyoX..",
        "..XoyoX..",
        ".XoywyoX.",
        ".XoywwyX.",
        "XooywwyoX",
        "XroywwyoX",
        "XroyywyrX",
        ".XrooorX.",
        "..XXXXX..",
    ],
]
fpal = {"X": INK, "y": C("ffd84a"), "o": C("ff8a1a"), "w": C("fff8d8"), "r": C("c8380e")}
FEMPTY = {"y": "e", "o": "e", "w": "E", "r": "e"}
fempty_pal = dict(fpal); fempty_pal.update({"e": C("2a2026"), "E": C("4a3a3c")})
gray = {"X": INK, "y": C("9a8a8a"), "o": C("6a5a5e"), "w": C("c8c0c0"), "r": C("4a3e44")}
flames = [from_pattern(f, fpal) for f in FLAMES]
flames += [from_pattern(half(f, 5, FEMPTY), fempty_pal) for f in FLAMES[:2]]
# carbón apagado con una brasa diminuta
coal = [
    ".........",
    ".........",
    ".........",
    ".........",
    ".........",
    "...XXX...",
    "..XeEeX..",
    ".XeeEeeX.",
    ".XeeeoeX.",
    ".XeeeeeX.",
    "..XXXXX..",
]
flames.append(from_pattern(coal, fempty_pal))
flames.append(from_pattern(FLAMES[0], gray))      # agotado
strip(flames).save(f"{OUT}/hud_flames.png")

# ------------------------------------------------------------------ cristales de Luz (9x11)
CRYSTAL = [
    "....X....",
    "...XwX...",
    "..XwlcX..",
    ".XwllccX.",
    "XwllcccdX",
    "XlllcccdX",
    "XllcccddX",
    ".XlccddX.",
    "..XcddX..",
    "...XdX...",
    "....X....",
]
cpal = {"X": INK, "w": C("ffffff"), "l": C("9af4ff"), "c": C("2ec8f0"), "d": C("1a6ab8")}
CEMPTY = {"w": "E", "l": "E", "c": "e", "d": "e"}
cempty_pal = dict(cpal); cempty_pal.update({"e": C("10223a"), "E": C("22405a")})
crystals = [from_pattern(CRYSTAL, cpal), from_pattern(half(CRYSTAL, 5, CEMPTY), cempty_pal), from_pattern(emptied(CRYSTAL, CEMPTY), cempty_pal)]
# destello que recorre el cristal (3 fotogramas)
for gx in (2, 4, 6):
    rows = [list(r) for r in CRYSTAL]
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in "lcd" and abs((x + y * 0.5) - (gx + 2.5)) < 0.8:
                rows[y][x] = "w"
    crystals.append(from_pattern(["".join(r) for r in rows], cpal))
strip(crystals).save(f"{OUT}/hud_crystals.png")
print("Iconos del HUD generados")

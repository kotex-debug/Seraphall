class_name Look
extends RefCounted
## Aspecto del protagonista: recolorea las hojas indexadas (tools/gen_looks.py),
## arranca las plumas perdidas del ala y dibuja el contorno en tiempo real.

const OUTLINE := Color8(18, 14, 24)
const HAIR_STYLES := {"f": [["Melena larga", "Long hair"], ["Coleta alta", "High ponytail"], ["Media melena", "Bob cut"], ["Trenzas", "Braids"]],
	"m": [["Corto", "Short"], ["Despeinado", "Tousled"], ["Largo atado", "Tied back"], ["Muy corto", "Cropped"]]}
const OPTIONS := {
	"hair_col": [["Platino", "Platinum", "e8e0d0"], ["Azabache", "Jet", "2a2238"], ["Castaño", "Chestnut", "6a4028"], ["Cobre", "Copper", "c0522a"],
		["Trigo", "Wheat", "e8c060"], ["Plata", "Silver", "a8b0c8"], ["Rosa alba", "Dawn pink", "e890b8"], ["Añil", "Indigo", "5a7ad8"]],
	"skin": [["Alba", "Dawn", "f8e0d0"], ["Marfil", "Ivory", "f2d0b0"], ["Miel", "Honey", "e0b090"], ["Canela", "Cinnamon", "c89878"],
		["Bronce", "Bronze", "a07050"], ["Ébano", "Ebony", "7a5038"]],
	"eye": [["Cielo", "Sky", "3a7bd5"], ["Ámbar", "Amber", "ff9a30"], ["Sangre", "Blood", "ff4050"], ["Jade", "Jade", "40c070"],
		["Amatista", "Amethyst", "a060ff"], ["Nimbo", "Nimbus", "e8f0ff"]],
	"cloak": [["Carmesí", "Crimson", "9a2a34"], ["Marea", "Tide", "1e6a70"], ["Penumbra", "Gloom", "5a2a7a"], ["Ceniza", "Ash", "2a2430"],
		["Oro viejo", "Old gold", "b08a30"], ["Abismo", "Abyss", "2a4a9a"], ["Rosa", "Rose", "c05a8a"], ["Sudario", "Shroud", "d8d4cc"]],
	"armor": [["Marfil", "Ivory", "d8d2c4", "5a5068", "e0b040"], ["Acero negro", "Black steel", "3e3a52", "2a2638", "40c0b0"],
		["Bronce", "Bronze", "9a6a3a", "4a3428", "ffd070"], ["Ónice", "Onyx", "2a2430", "1a1620", "ff4060"], ["Plata lunar", "Moon silver", "b8c0d0", "404858", "80d0ff"]],
	"wing": [["Alba", "Dawn", "f4f0ea"], ["Ceniza", "Ash", "6a6478"], ["Áurea", "Golden", "f0d070"], ["Carmesí", "Crimson", "d04050"],
		["Celeste", "Celestial", "90c8ff"], ["Vacío", "Void", "3a2a4a"]],
	"halo": [["Oro", "Gold", "ffe27a"], ["Cian", "Cyan", "8af0ff"], ["Rosa", "Rose", "ff9ad0"], ["Blanco", "White", "ffffff"], ["Brasa", "Ember", "ff6a3a"]],
}
const DEFAULT := {"body": "f", "hair": 0, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": ""}
## Orden en que se caen las plumas (alternando alas, de las puntas hacia dentro)
const LOSS_ORDER := [14, 19, 13, 18, 12, 17, 11, 16, 10, 15]

static var _cache := {}

static func defaults_p2() -> Dictionary:
	return {"body": "m", "hair": 1, "hair_col": 1, "skin": 3, "eye": 1, "cloak": 1, "armor": 1, "wing": 1, "halo": 1, "name": ""}

static func sane(look: Dictionary) -> Dictionary:
	var l := DEFAULT.duplicate()
	for k in look:
		if l.has(k):
			l[k] = look[k]
	l.body = "m" if str(l.body) == "m" else "f"
	l.hair = clampi(int(l.hair), 0, 3)
	for k in OPTIONS:
		l[k] = clampi(int(l[k]), 0, OPTIONS[k].size() - 1)
	l.name = str(l.name).substr(0, 14)
	return l

static func palette(look: Dictionary) -> Dictionary:
	var l := sane(look)
	var ar: Array = OPTIONS.armor[l.armor]
	var wc := Color.html(OPTIONS.wing[l.wing][2])
	var pal := {1: Color.html(OPTIONS.skin[l.skin][2]), 2: Color.html(OPTIONS.hair_col[l.hair_col][2]), 3: Color.html(OPTIONS.eye[l.eye][2]),
		4: Color.html(ar[2]), 5: Color.html(ar[3]), 6: Color.html(ar[4]), 7: Color.html(OPTIONS.cloak[l.cloak][2]), 8: wc,
		9: Color.html(OPTIONS.halo[l.halo][2]), 20: Color.html(OPTIONS.skin[l.skin][2]).darkened(0.45),
		21: Color(0.97, 0.96, 1.0), 22: Color.html(OPTIONS.skin[l.skin][2]).lerp(Color(1, 0.35, 0.45), 0.35)}
	for i in range(10, 20):
		pal[i] = wc
	return pal

## Sombreado con desplazamiento de tono: las sombras tiran a violeta frío y las luces a dorado cálido
static func _shade(base: Color, f: float) -> Color:
	var c := Color(clampf(base.r * f, 0, 1), clampf(base.g * f, 0, 1), clampf(base.b * f, 0, 1), 1.0)
	if f < 1.0:
		# solo las sombras hondas se enfrían; las suaves conservan su color
		return c.lerp(Color(0.2, 0.1, 0.3), clampf((0.85 - f) * 0.5, 0.0, 0.22))
	if f > 1.0:
		return c.lerp(Color(1.0, 0.95, 0.82), clampf((f - 1.0) * 0.45, 0.0, 0.2))
	return c

static func color_of(look: Dictionary, key: String) -> Color:
	var l := sane(look)
	return Color.html(OPTIONS[key][l[key]][2])

## Hoja de animación (144x104) con la paleta y las plumas que quedan.
static func texture(look: Dictionary, feathers := 10, kind := "pl") -> ImageTexture:
	var l := sane(look)
	var key := "%s_%s_%d_%d" % [kind, JSON.stringify(l), feathers, 0]
	if _cache.has(key):
		return _cache[key]
	var src: Image = load("res://assets/sprites/look/%s_%s%d.png" % [kind, l.body, l.hair]).get_image()
	src.convert(Image.FORMAT_RGBA8)
	var pal := palette(l)
	var lost := {}
	for i in clampi(10 - feathers, 0, 10):
		lost[LOSS_ORDER[i]] = true
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var r8 := c.r8
			if c.b8 == 1:
				var part := int(round(r8 / 12.0))
				if lost.has(part):
					continue
				var f := c.g8 / 128.0
				var base: Color = pal.get(part, Color.MAGENTA)
				var px := _shade(base, f)
				out.set_pixel(x, y, px)
				if part != 9:
					solid[y * w + x] = 1
			else:
				out.set_pixel(x, y, c)
				solid[y * w + x] = 1
	# contorno (sin cruzar de un fotograma a otro)
	var fw := 32 if kind == "pl" else (40 if kind == "bu" else w)
	var fh := 32 if kind == "pl" else (40 if kind == "bu" else h)
	for y in h:
		for x in w:
			if solid[y * w + x] == 1 or out.get_pixel(x, y).a > 0.5:
				continue
			var edge := false
			var nb := Color.BLACK
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				if nx / fw != x / fw or ny / fh != y / fh:
					continue
				if solid[ny * w + nx] == 1:
					edge = true
					nb = out.get_pixel(nx, ny)
					break
			if edge:
				# contorno selectivo: oscuro y teñido del color que rodea (más suave que el negro puro)
				out.set_pixel(x, y, Color(nb.r * 0.32, nb.g * 0.26, nb.b * 0.36).lerp(OUTLINE, 0.55))
	var tex := ImageTexture.create_from_image(out)
	_cache[key] = tex
	return tex

static func bust_texture(look: Dictionary, feathers := 10) -> ImageTexture:
	return texture(look, feathers, "bu")

static func back_texture(look: Dictionary, feathers := 10) -> ImageTexture:
	return texture(look, feathers, "pb")

static func display_name(look: Dictionary, variant := 1) -> String:
	var n := str(look.get("name", "")).strip_edges()
	if n == "":
		return G.L(["Desplumada", "Featherless"]) if str(look.get("body", "f")) == "f" else G.L(["Desplumado", "Featherless"])
	return n

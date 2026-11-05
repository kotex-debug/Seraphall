extends SceneTree
## Genera el arte de las armas (64x24, empuñadura a la izquierda) y otros iconos sin dependencias externas.
## Uso: godot --headless --path . --script res://tools/gen_weapons.gd   y luego   godot --headless --path . --import

const W := 64
const H := 24
const INK := Color(0.05, 0.03, 0.07)
var img: Image

func _init() -> void:
	for n in ["sword", "spear", "scythe", "hammer", "choir", "seravel", "reaper", "staff", "fists", "verdugo", "bow", "mangual", "yunque", "astas", "corona"]:
		_begin()
		call("_w_" + n)
		_finish("res://assets/sprites/weapon_%s.png" % n)
	_coin()
	_golden_feather()
	print("GEN_WEAPONS_OK")
	quit()

func _begin(w := W, h := H) -> void:
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)

func _finish(path: String) -> void:
	var out := img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and img.get_pixelv(q).a > 0.0:
					out.set_pixel(x, y, INK)
					break
	out.save_png(ProjectSettings.globalize_path(path))

func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in h:
		for i in w:
			_px(x + i, y + j, c)

func _line(a: Vector2, b: Vector2, c: Color) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		_px(int(round(p.x)), int(round(p.y)), c)

func _poly(pts: Array, c: Color) -> void:
	var ymin := 999.0
	var ymax := -999.0
	for p: Vector2 in pts:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	for yi in range(int(floor(ymin)), int(ceil(ymax)) + 1):
		var y := yi + 0.5
		var xs: Array[float] = []
		for i in pts.size():
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			for x in range(int(round(xs[k])), int(round(xs[k + 1]))):
				_px(x, yi, c)
			k += 2

func _circle(cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r - 1), int(cy + r + 2)):
		for x in range(int(cx - r - 1), int(cx + r + 2)):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				_px(x, y, c)

func _gem(x: int, y: int, c: Color) -> void:
	_rect(x - 1, y - 1, 3, 3, c.darkened(0.25))
	_px(x, y, c)
	_px(x - 1, y - 1, c.lightened(0.6))

func _grip(x0: int, x1: int, y := 12, c := Color(0.35, 0.2, 0.14)) -> void:
	_rect(x0, y - 1, x1 - x0, 3, c)
	for x in range(x0, x1, 3):
		_rect(x, y - 1, 1, 3, c.darkened(0.35))
	_rect(x0, y - 2, 2, 5, Color(0.8, 0.62, 0.25))

# ------------------------------------------------------------------ armas
func _w_sword() -> void:
	# la primera hoja: guarda con forma de ala
	_grip(1, 11)
	_poly([Vector2(11, 3), Vector2(15, 7), Vector2(15, 17), Vector2(11, 21), Vector2(13, 12)], Color(0.82, 0.63, 0.25))
	_line(Vector2(12, 5), Vector2(14, 8), Color(1, 0.88, 0.5))
	_gem(13, 12, Color(0.95, 0.3, 0.3))
	_poly([Vector2(15, 9), Vector2(54, 9), Vector2(62, 12), Vector2(54, 15), Vector2(15, 15)], Color(0.74, 0.77, 0.85))
	_poly([Vector2(15, 9), Vector2(54, 9), Vector2(62, 12), Vector2(15, 12)], Color(0.94, 0.96, 1.0))
	_rect(16, 11, 30, 2, Color(0.52, 0.56, 0.68))
	for x in [22, 30, 38]:
		_px(x, 11, Color(1, 0.85, 0.5))

func _w_spear() -> void:
	# asta larga de ceniza y moharra en forma de hoja
	_rect(0, 11, 44, 2, Color(0.36, 0.26, 0.24))
	_rect(0, 11, 44, 1, Color(0.5, 0.38, 0.34))
	for x in [8, 20, 32]:
		_rect(x, 10, 2, 4, Color(0.78, 0.62, 0.28))
	_poly([Vector2(42, 12), Vector2(50, 6), Vector2(63, 12), Vector2(50, 18)], Color(0.7, 0.74, 0.82))
	_poly([Vector2(42, 12), Vector2(50, 6), Vector2(63, 12)], Color(0.94, 0.96, 1.0))
	_line(Vector2(44, 12), Vector2(61, 12), Color(0.45, 0.5, 0.62))
	_poly([Vector2(40, 13), Vector2(45, 13), Vector2(43, 22), Vector2(39, 22)], Color(0.8, 0.18, 0.2))
	_line(Vector2(42, 14), Vector2(41, 21), Color(1, 0.42, 0.35))

func _w_scythe() -> void:
	# guadañas gemelas unidas por una cadena corta
	_grip(3, 16)
	_poly([Vector2(14, 11), Vector2(30, 1), Vector2(42, 2), Vector2(34, 6), Vector2(22, 12)], Color(0.62, 0.66, 0.78))
	_line(Vector2(16, 11), Vector2(36, 2), Color(0.95, 0.97, 1))
	for x in range(16, 26, 3):
		_rect(x, 16, 2, 2, Color(0.55, 0.52, 0.6))
	_grip(26, 39, 18)
	_poly([Vector2(38, 18), Vector2(52, 21), Vector2(63, 13), Vector2(55, 14), Vector2(44, 15)], Color(0.62, 0.66, 0.78))
	_line(Vector2(40, 17), Vector2(61, 14), Color(0.95, 0.97, 1))
	_gem(9, 12, Color(0.85, 0.3, 0.55))

func _w_hammer() -> void:
	# mango largo y cabeza enorme con el juramento grabado
	_rect(0, 11, 42, 3, Color(0.3, 0.2, 0.16))
	_rect(0, 11, 42, 1, Color(0.48, 0.34, 0.26))
	for x in [10, 18, 26, 34]:
		_rect(x, 10, 1, 5, Color(0.75, 0.6, 0.3))
	_poly([Vector2(40, 2), Vector2(60, 2), Vector2(63, 6), Vector2(63, 18), Vector2(60, 22), Vector2(40, 22), Vector2(38, 18), Vector2(38, 6)], Color(0.42, 0.42, 0.5))
	_poly([Vector2(40, 2), Vector2(60, 2), Vector2(63, 6), Vector2(38, 6)], Color(0.68, 0.68, 0.76))
	_rect(38, 18, 25, 2, Color(0.26, 0.26, 0.33))
	_rect(47, 7, 8, 10, Color(0.2, 0.1, 0.14))
	_line(Vector2(51, 8), Vector2(51, 16), Color(1, 0.55, 0.2))
	_line(Vector2(48, 11), Vector2(54, 11), Color(1, 0.75, 0.35))
	_rect(43, 2, 2, 20, Color(0.8, 0.62, 0.25))
	_rect(57, 2, 2, 20, Color(0.8, 0.62, 0.25))

func _w_choir() -> void:
	# diapasón: dos púas que vibran
	_grip(1, 12)
	_circle(15, 12, 4.0, Color(0.72, 0.58, 0.9))
	_gem(15, 12, Color(0.95, 0.9, 1.0))
	_poly([Vector2(17, 8), Vector2(58, 5), Vector2(62, 7), Vector2(20, 11)], Color(0.74, 0.62, 0.92))
	_poly([Vector2(17, 16), Vector2(58, 19), Vector2(62, 17), Vector2(20, 13)], Color(0.6, 0.48, 0.82))
	_line(Vector2(20, 8), Vector2(58, 5), Color(0.98, 0.92, 1))
	_line(Vector2(20, 14), Vector2(58, 18), Color(0.86, 0.74, 1))
	for p in [Vector2(30, 12), Vector2(40, 12), Vector2(50, 12)]:
		_rect(int(p.x), int(p.y) - 1, 2, 2, Color(0.95, 0.75, 1))
		_rect(int(p.x) + 1, int(p.y) - 3, 1, 2, Color(0.95, 0.75, 1))

func _w_seravel() -> void:
	# hoja de Arconte: oro blanco y dos alas en la guarda
	_grip(1, 9, 12, Color(0.45, 0.14, 0.2))
	_poly([Vector2(9, 12), Vector2(5, 1), Vector2(14, 4), Vector2(17, 10)], Color(1, 0.92, 0.65))
	_poly([Vector2(9, 12), Vector2(5, 23), Vector2(14, 20), Vector2(17, 14)], Color(0.92, 0.74, 0.35))
	_line(Vector2(7, 3), Vector2(12, 9), Color(1, 1, 0.9))
	_gem(14, 12, Color(1, 0.3, 0.45))
	_poly([Vector2(16, 8), Vector2(52, 7), Vector2(63, 12), Vector2(52, 17), Vector2(16, 16)], Color(0.96, 0.8, 0.45))
	_poly([Vector2(16, 8), Vector2(52, 7), Vector2(63, 12), Vector2(16, 12)], Color(1, 0.97, 0.82))
	_rect(18, 11, 28, 2, Color(1, 0.45, 0.5))

func _w_reaper() -> void:
	# guadaña de verdad: asta larga, hoja gigantesca y un cráneo
	_rect(0, 14, 50, 2, Color(0.2, 0.15, 0.2))
	_rect(0, 14, 50, 1, Color(0.38, 0.3, 0.36))
	_rect(14, 13, 2, 4, Color(0.7, 0.58, 0.3))
	_rect(30, 13, 2, 4, Color(0.7, 0.58, 0.3))
	_poly([Vector2(46, 15), Vector2(52, 3), Vector2(44, 1), Vector2(30, 1), Vector2(16, 6), Vector2(30, 4), Vector2(40, 5), Vector2(44, 9)], Color(0.55, 0.55, 0.68))
	_line(Vector2(18, 6), Vector2(30, 2), Color(0.95, 0.96, 1))
	_line(Vector2(30, 2), Vector2(50, 3), Color(0.82, 0.84, 0.95))
	_circle(52, 15, 5.0, Color(0.86, 0.84, 0.76))
	_rect(50, 14, 2, 2, Color(0.75, 0.12, 0.2))
	_rect(54, 14, 2, 2, Color(0.75, 0.12, 0.2))
	_rect(50, 18, 6, 1, Color(0.3, 0.25, 0.25))
	_rect(57, 12, 3, 8, Color(0.6, 0.15, 0.25))

func _w_staff() -> void:
	# báculo con un sol en la punta
	_rect(0, 11, 48, 2, Color(0.82, 0.68, 0.42))
	_rect(0, 11, 48, 1, Color(1, 0.88, 0.6))
	for x in [10, 22, 34]:
		_rect(x, 10, 2, 4, Color(0.6, 0.4, 0.2))
	for i in 8:
		var d := Vector2.from_angle(TAU * i / 8.0)
		_line(Vector2(54, 12) + d * 6.0, Vector2(54, 12) + d * 10.5, Color(1, 0.75, 0.3))
	_circle(54, 12, 6.0, Color(1, 0.82, 0.38))
	_circle(54, 12, 4.0, Color(1, 0.96, 0.7))
	_circle(53, 11, 1.5, Color(1, 1, 1))

func _w_fists() -> void:
	# guanteletes: nudillos enormes con clavos
	_rect(16, 7, 16, 10, Color(0.34, 0.24, 0.2))
	_rect(16, 7, 16, 2, Color(0.5, 0.38, 0.3))
	_rect(20, 6, 2, 12, Color(0.78, 0.62, 0.28))
	_poly([Vector2(32, 5), Vector2(50, 3), Vector2(55, 7), Vector2(55, 17), Vector2(50, 21), Vector2(32, 19)], Color(0.5, 0.5, 0.58))
	_poly([Vector2(32, 5), Vector2(50, 3), Vector2(55, 7), Vector2(32, 9)], Color(0.76, 0.76, 0.84))
	for y in [6, 11, 16]:
		_poly([Vector2(55, y), Vector2(62, y + 1.5), Vector2(55, y + 3)], Color(0.86, 0.87, 0.95))
		_rect(38, y, 12, 1, Color(0.3, 0.3, 0.38))
	_gem(42, 12, Color(1, 0.55, 0.2))

func _w_verdugo() -> void:
	# hoja del verdugo: una plancha negra con runas al rojo
	_grip(1, 10, 12, Color(0.26, 0.14, 0.16))
	_rect(10, 3, 3, 18, Color(0.62, 0.48, 0.22))
	_poly([Vector2(13, 3), Vector2(60, 2), Vector2(63, 6), Vector2(60, 19), Vector2(52, 21), Vector2(13, 18)], Color(0.14, 0.13, 0.18))
	_poly([Vector2(13, 3), Vector2(60, 2), Vector2(63, 6), Vector2(13, 6)], Color(0.34, 0.33, 0.4))
	_line(Vector2(14, 18), Vector2(52, 21), Color(0.72, 0.74, 0.82))
	for x in [20, 29, 38, 47]:
		_rect(x, 9, 2, 6, Color(0.95, 0.15, 0.22))
		_rect(x - 1, 11, 4, 2, Color(1, 0.45, 0.35))
	_rect(55, 6, 4, 4, Color(0.05, 0.03, 0.07))

func _w_bow() -> void:
	# arco de pluma: las palas son dos alas y la cuerda brilla
	for i in 24:
		var y := float(i)
		var x := 22.0 + 16.0 * sin(PI * y / 23.0)
		_rect(int(x), i, 3, 1, Color(0.7, 0.5, 0.28))
		_px(int(x) + 2, i, Color(0.95, 0.78, 0.45))
	_line(Vector2(23, 0), Vector2(23, 23), Color(0.95, 0.95, 1))
	_poly([Vector2(24, 0), Vector2(12, 1), Vector2(8, 6), Vector2(19, 6)], Color(0.95, 0.95, 1))
	_poly([Vector2(24, 23), Vector2(12, 22), Vector2(8, 17), Vector2(19, 17)], Color(0.8, 0.82, 0.92))
	_rect(14, 11, 46, 2, Color(0.6, 0.44, 0.3))
	_poly([Vector2(58, 9), Vector2(63, 12), Vector2(58, 15)], Color(1, 0.85, 0.45))
	_gem(36, 12, Color(0.45, 0.85, 1.0))

func _w_mangual() -> void:
	# mangual del Carcelero: cadena y bola de hierro con clavos
	_grip(1, 18)
	_rect(18, 10, 3, 5, Color(0.7, 0.55, 0.26))
	for i in 7:
		var x := 22 + i * 4
		var y := 12 + int(sin(i * 0.9) * 2.0)
		_rect(x, y, 3, 2, Color(0.62, 0.6, 0.68))
		_px(x + 1, y, Color(0.85, 0.83, 0.9))
	for i in 8:
		var d := Vector2.from_angle(TAU * i / 8.0 + 0.3)
		_poly([Vector2(52, 12) + d * 7.0 + d.orthogonal() * 2.0, Vector2(52, 12) + d * 11.5, Vector2(52, 12) + d * 7.0 - d.orthogonal() * 2.0], Color(0.82, 0.82, 0.9))
	_circle(52, 12, 8.0, Color(0.36, 0.35, 0.43))
	_circle(50, 10, 3.5, Color(0.56, 0.55, 0.64))
	_rect(51, 12, 2, 2, Color(1, 0.45, 0.2))

func _w_yunque() -> void:
	# maza del Gran Yunque: cabeza de pestañas candente rodeada por una aureola
	_rect(0, 11, 38, 3, Color(0.26, 0.2, 0.2))
	_rect(0, 11, 38, 1, Color(0.44, 0.36, 0.32))
	_rect(12, 10, 2, 5, Color(0.86, 0.5, 0.2))
	_rect(26, 10, 2, 5, Color(0.86, 0.5, 0.2))
	for i in 6:
		var d := Vector2.from_angle(TAU * i / 6.0)
		_poly([Vector2(48, 12) + d.orthogonal() * 2.5, Vector2(48, 12) + d * 11.0 + d.orthogonal() * 3.5, Vector2(48, 12) + d * 11.0 - d.orthogonal() * 3.5, Vector2(48, 12) - d.orthogonal() * 2.5], Color(0.46, 0.4, 0.42))
	_circle(48, 12, 5.0, Color(0.95, 0.42, 0.14))
	_circle(48, 12, 3.0, Color(1, 0.85, 0.45))
	for i in 28:
		var a := TAU * i / 28.0
		_px(int(48.0 + cos(a) * 14.5), int(12.0 + sin(a) * 11.0), Color(1, 0.8, 0.35))

func _w_astas() -> void:
	# glaive de Orrun: asta de hueso y dos cuernas de ciervo con fuego azul
	_rect(0, 11, 36, 2, Color(0.9, 0.86, 0.74))
	_rect(0, 12, 36, 1, Color(0.66, 0.6, 0.5))
	_gem(12, 12, Color(0.45, 0.85, 1.0))
	_line(Vector2(34, 11), Vector2(62, 2), Color(0.95, 0.92, 0.82))
	_line(Vector2(34, 12), Vector2(62, 3), Color(0.74, 0.7, 0.6))
	_line(Vector2(34, 13), Vector2(62, 22), Color(0.95, 0.92, 0.82))
	_line(Vector2(34, 12), Vector2(62, 21), Color(0.74, 0.7, 0.6))
	_line(Vector2(46, 7), Vector2(50, 0), Color(0.95, 0.92, 0.82))
	_line(Vector2(54, 5), Vector2(60, 0), Color(0.95, 0.92, 0.82))
	_line(Vector2(46, 17), Vector2(50, 23), Color(0.95, 0.92, 0.82))
	_line(Vector2(54, 19), Vector2(60, 23), Color(0.95, 0.92, 0.82))
	_circle(46, 12, 3.5, Color(0.4, 0.78, 1.0))
	_circle(46, 12, 1.5, Color(0.9, 1, 1))

func _w_corona() -> void:
	# cetro del Rey: la corona que nadie quiso, sobre un asta morada
	_rect(0, 11, 42, 2, Color(0.3, 0.16, 0.44))
	_rect(0, 11, 42, 1, Color(0.5, 0.3, 0.7))
	for x in [8, 18, 28, 38]:
		_rect(x, 10, 2, 4, Color(0.95, 0.75, 0.3))
	_poly([Vector2(42, 6), Vector2(46, 11), Vector2(50, 2), Vector2(54, 11), Vector2(60, 3), Vector2(60, 21), Vector2(42, 18)], Color(0.92, 0.72, 0.28))
	_poly([Vector2(42, 6), Vector2(46, 11), Vector2(50, 2), Vector2(54, 11), Vector2(60, 3), Vector2(60, 12), Vector2(42, 12)], Color(1, 0.9, 0.55))
	_gem(50, 15, Color(0.7, 0.4, 1.0))
	_gem(45, 15, Color(1, 0.3, 0.4))
	_gem(56, 15, Color(0.45, 0.85, 1.0))

# ------------------------------------------------------------------ iconos
func _coin() -> void:
	# Eco: una moneda de alma con el ala grabada
	_begin(16, 16)
	_circle(8, 8, 7.0, Color(0.1, 0.32, 0.55))
	_circle(8, 8, 6.0, Color(0.32, 0.72, 0.95))
	_circle(7, 7, 4.5, Color(0.62, 0.92, 1.0))
	_circle(8, 8, 3.5, Color(0.2, 0.58, 0.85))
	_poly([Vector2(5, 10), Vector2(8, 4), Vector2(11, 3), Vector2(10, 7), Vector2(8, 10)], Color(1, 0.98, 0.85))
	_line(Vector2(6, 10), Vector2(9, 5), Color(0.75, 0.55, 0.25))
	_px(4, 3, Color(1, 1, 1))
	_px(3, 4, Color(1, 1, 1))
	_finish("res://assets/sprites/icon_eco.png")

func _golden_feather() -> void:
	# la Pluma Dorada de la [Q]: proyectil grande e icono
	_begin(24, 10)
	_poly([Vector2(1, 5), Vector2(9, 1), Vector2(18, 2), Vector2(23, 5), Vector2(18, 8), Vector2(9, 9)], Color(0.95, 0.68, 0.2))
	_poly([Vector2(1, 5), Vector2(9, 1), Vector2(18, 2), Vector2(23, 5)], Color(1, 0.92, 0.52))
	_line(Vector2(0, 5), Vector2(23, 5), Color(1, 1, 0.88))
	for x in [7, 11, 15, 19]:
		_px(x, 3, Color(0.8, 0.5, 0.15))
		_px(x, 7, Color(0.75, 0.45, 0.12))
	_finish("res://assets/sprites/proj_gfeather.png")
	_begin(16, 16)
	_poly([Vector2(2, 14), Vector2(5, 7), Vector2(10, 2), Vector2(14, 1), Vector2(13, 6), Vector2(9, 11)], Color(0.95, 0.68, 0.2))
	_poly([Vector2(5, 7), Vector2(10, 2), Vector2(14, 1), Vector2(8, 8)], Color(1, 0.93, 0.55))
	_line(Vector2(1, 15), Vector2(13, 2), Color(1, 1, 0.9))
	_finish("res://assets/sprites/icon_lance.png")

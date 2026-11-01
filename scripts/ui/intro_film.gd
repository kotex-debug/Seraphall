extends CanvasLayer
## Corto de introducción de SERAPHALL: once láminas animadas con narración.
## Cada lámina tiene su movimiento de cámara (acercamiento y paneo), capas con paralaje, partículas,
## destellos y sonidos. El texto se escribe letra a letra con la voz del narrador.
## Se puede saltar (Esc / Intro). Al terminar emite "finished".

signal finished

const SCENES := [
	{"kind": "garden", "dur": 8.0, "zoom": [1.0, 1.07], "pan": [Vector2(-10, 0), Vector2(10, -4)], "lines": [
		["Antes de la Espiral había un cielo sin muros.", "Before the Spiral there was a sky without walls."],
		["Los serafines cantaban, y el Arquitecto los escuchaba.", "The seraphim sang, and the Architect listened."]]},
	{"kind": "choir", "dur": 7.5, "zoom": [1.08, 1.0], "pan": [Vector2(0, 8), Vector2(0, -6)], "cues": [[0.2, "bell_1", -8.0], [2.6, "bell_0", -10.0]], "lines": [
		["Su canto sostenía el mundo, nota a nota.", "Their song held the world together, note by note."],
		["Y a las puertas del cielo velaba Seravel, la primera de todos.", "And at the gates of heaven stood Seravel, the first of them all."]]},
	{"kind": "voice", "dur": 8.0, "zoom": [1.0, 1.14], "pan": [Vector2.ZERO, Vector2(0, 6)], "cues": [[0.6, "event", -10.0], [4.6, "glitch", -4.0]], "lines": [
		["Un día, el Arquitecto dejó de escuchar.", "One day, the Architect stopped listening."],
		["Y empezó a dar órdenes.", "And began to give orders."]], "glitch_at": 4.6},
	{"kind": "war", "dur": 7.5, "zoom": [1.04, 1.1], "pan": [Vector2(14, 0), Vector2(-14, 0)], "cues": [[0.4, "event", -4.0], [2.9, "slam", -10.0], [5.2, "event", -6.0]], "flash": true, "lines": [
		["Algunos se negaron.", "Some refused."],
		["El cielo ardió durante cien días.", "The sky burned for a hundred days."]]},
	{"kind": "executioner", "dur": 8.5, "zoom": [1.12, 1.0], "pan": [Vector2(0, -6), Vector2(0, 4)], "cues": [[5.2, "feather_tear", -2.0]], "lines": [
		["Para castigarlos, el Arquitecto necesitaba una mano: un verdugo sin rostro.", "To punish them, the Architect needed a hand: a faceless executioner."],
		["Nadie recuerda su nombre. Ni siquiera el propio verdugo.", "No one remembers its name. Not even the executioner itself."]]},
	{"kind": "fall", "dur": 7.5, "zoom": [1.0, 1.12], "pan": [Vector2(0, -12), Vector2(0, 12)], "cues": [[0.3, "feather_tear", -6.0], [3.4, "feather_tear", -8.0]], "lines": [
		["Los que no obedecieron cayeron.", "Those who would not obey fell."],
		["Les arrancaron las alas, pluma a pluma.", "Their wings were torn away, feather by feather."]]},
	{"kind": "spiral", "dur": 8.5, "zoom": [1.0, 1.0], "pan": [Vector2.ZERO, Vector2.ZERO], "cues": [[0.4, "gate", -8.0]], "lines": [
		["Para ellos levantó la Espiral: cien círculos de piedra que bajan hasta el Abismo.", "For them he raised the Spiral: a hundred circles of stone falling to the Abyss."],
		["Aquí nadie muere del todo.", "Here, no one ever fully dies."]]},
	{"kind": "archons", "dur": 9.0, "zoom": [1.0, 1.05], "pan": [Vector2(-6, 0), Vector2(6, 0)], "cues": [[2.2, "slam", -6.0], [4.4, "bell_2", -6.0], [6.6, "slam", -4.0]], "lines": [
		["En cada círculo, un Arconte guarda el paso hacia abajo.", "In every circle, an Archon guards the way down."],
		["El Carcelero. El Coro Hueco. Y la última de todos... Seravel.", "The Jailer. The Hollow Choir. And the last of them all... Seravel."]]},
	{"kind": "ember", "dur": 7.0, "zoom": [1.15, 1.0], "pan": [Vector2(0, 10), Vector2.ZERO], "cues": [[0.5, "heal", -8.0]], "lines": [
		["Solo las Brasas recuerdan el viejo cielo.", "Only the Embers remember the old sky."],
		["Donde arde una, los caídos pueden volver a levantarse.", "Where one burns, the fallen can rise again."]]},
	{"kind": "wake", "dur": 8.5, "zoom": [1.1, 1.0], "pan": [Vector2(0, 8), Vector2.ZERO], "cues": [[3.0, "levelup", -10.0]], "lines": [
		["Cada muerte te arranca una pluma. Y cada pluma, un recuerdo.", "Every death tears away a feather. And every feather, a memory."],
		["Acabas de despertar... y todavía te quedan diez.", "You have just woken... and you still have ten."]]},
	{"kind": "title", "dur": 5.0, "zoom": [1.06, 1.0], "pan": [Vector2.ZERO, Vector2.ZERO], "lines": [["", ""]]},
]

var _i := -1
var _t := 0.0
var _scene: FilmPlate
var _text: Label
var _fade: ColorRect
var _flash: ColorRect
var _done := false
var _chars := 0.0
var _line := -1
var _cues_done := {}
var _blip_last := 0
var _dbg := false

func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(640, 360)
	add_child(bg)
	_scene = FilmPlate.new()
	_scene.size = Vector2(640, 360)
	add_child(_scene)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = Vector2(640, 360)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	for y in [0.0, 318.0]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, y)
		bar.size = Vector2(640, 42)
		add_child(bar)
	_text = UIKit.label("", 15, Color(0.95, 0.92, 0.88))
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(50, 322)
	_text.size = Vector2(540, 36)
	add_child(_text)
	var hint := UIKit.label(G.L(["[Esc] saltar", "[Esc] skip"]), 8, Color(0.6, 0.55, 0.65), "head", 3)
	hint.position = Vector2(560, 14)
	add_child(hint)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = Vector2(640, 360)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	Audio.play_music("memory", 1.0)
	_next()

func _speed() -> float:
	return 0.12 if G.autotest != "" and G.autotest != "film" else 1.0

func _next() -> void:
	_i += 1
	if _i >= SCENES.size():
		_finish()
		return
	_enter(_i, 0.0)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.9)

func _enter(i: int, at: float) -> void:
	var sc: Dictionary = SCENES[i]
	_i = i
	_t = at
	_line = -1
	_cues_done = {}
	_scene.kind = sc.kind
	_scene.t = at
	_scene.dur = sc.dur
	_scene.glitch_at = sc.get("glitch_at", -1.0)
	_scene.zoom = sc.zoom
	_scene.pan = sc.pan
	if sc.get("flash", false):
		_flash.color.a = 0.8
		create_tween().tween_property(_flash, "color:a", 0.0, 0.8)
	if sc.kind == "title":
		Audio.play_music("theme", 2.0)
		Audio.sfx("hit_heavy", -6.0, 0.0)

## Para las pruebas: salta a una lámina concreta (fracción de su duración)
func debug_seek(i: int, frac: float) -> void:
	_fade.color.a = 0.0
	_enter(i, SCENES[i].dur * frac)
	_dbg = true

func _process(delta: float) -> void:
	if _done or _i < 0 or _i >= SCENES.size():
		return
	var sc: Dictionary = SCENES[_i]
	var sp := _speed()
	_t += delta / sp if sp < 1.0 else delta
	_scene.t = _t
	var dur: float = sc.dur
	# narración: cada línea ocupa su parte de la lámina
	var lines: Array = sc.lines
	var li := clampi(int(_t / dur * lines.size()), 0, lines.size() - 1)
	if li != _line:
		_line = li
		_chars = 0.0
		_text.text = G.L(lines[li])
		_text.visible_characters = 0
	_chars += delta * 40.0 / sp
	if _dbg:
		_chars = 999.0
	_text.visible_characters = int(_chars)
	var shown := mini(int(_chars), _text.text.length())
	if shown != _blip_last and shown % 3 == 0 and shown < _text.text.length() and G.autotest == "":
		var ch := _text.text.substr(shown, 1)
		if ch != " ":
			Audio.sfx("voice_default", -16.0, 0.05)
	_blip_last = shown
	# sonidos de la lámina
	for c in sc.get("cues", []):
		if _t >= c[0] and not _cues_done.has(c[0]):
			_cues_done[c[0]] = true
			if G.autotest == "":
				Audio.sfx(c[1], c[2], 0.0)
			if c[1] in ["event", "slam"]:
				_flash.color.a = 0.55
				create_tween().tween_property(_flash, "color:a", 0.0, 0.5)
	if _t >= dur:
		_t = -999.0
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.7 * sp)
		tw.tween_callback(_next)

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	tw.tween_callback(_emit)

func _emit() -> void:
	finished.emit()
	queue_free()


class FilmPlate extends Control:
	## Dibuja la lámina actual. Todo pasa por una "cámara" (acercamiento + paneo) y capas con paralaje.
	var kind := "garden"
	var t := 0.0
	var dur := 8.0
	var glitch_at := -1.0
	var zoom := [1.0, 1.0]
	var pan := [Vector2.ZERO, Vector2.ZERO]
	var _seed := []
	var _cam := Transform2D()
	var _shake := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r := RandomNumberGenerator.new()
		r.seed = 7
		for i in 90:
			_seed.append([r.randf() * 640.0, r.randf() * 360.0, r.randf(), r.randf_range(0.6, 1.4)])

	func _process(_delta: float) -> void:
		queue_redraw()

	# ------------------------------------------------------------------ utilidades
	func _poly(pts: PackedVector2Array, col: Color) -> void:
		if not Geometry2D.triangulate_polygon(pts).is_empty():
			draw_colored_polygon(pts, col)

	func _k() -> float:
		return clampf(t / dur, 0.0, 1.0)

	func _ease(x: float) -> float:
		return x * x * (3.0 - 2.0 * x)

	func _set_cam(par := 1.0) -> void:
		## par < 1: capa lejana (se mueve menos con la cámara)
		var e := _ease(_k())
		var z: float = lerpf(1.0, lerpf(zoom[0], zoom[1], e), par)
		var off: Vector2 = (pan[0] as Vector2).lerp(pan[1], e) * par + _shake
		_cam = Transform2D(0.0, Vector2(z, z), 0.0, Vector2(320, 180) * (1.0 - z) + off)
		draw_set_transform_matrix(_cam)

	func _local(p: Vector2, rot := 0.0, s := 1.0) -> void:
		draw_set_transform_matrix(_cam * Transform2D(rot, Vector2(s, s), 0.0, p))

	func _reset() -> void:
		draw_set_transform_matrix(_cam)

	func _sky(top: Color, bottom: Color) -> void:
		draw_set_transform_matrix(Transform2D())
		for y in range(0, 360, 4):
			var k := y / 360.0
			draw_rect(Rect2(0, y, 640, 4), top.lerp(bottom, k))

	func _vignette(strength := 0.55) -> void:
		draw_set_transform_matrix(Transform2D())
		for i in 10:
			var a := strength * (1.0 - i / 10.0) * 0.18
			draw_rect(Rect2(i * 6, 0, 6, 360), Color(0, 0, 0, a))
			draw_rect(Rect2(640 - (i + 1) * 6, 0, 6, 360), Color(0, 0, 0, a))
			draw_rect(Rect2(0, 42 + i * 4, 640, 4), Color(0, 0, 0, a))
			draw_rect(Rect2(0, 318 - (i + 1) * 4, 640, 4), Color(0, 0, 0, a))

	func _cloud(p: Vector2, s: float, col: Color) -> void:
		for c in [[Vector2(0, 0), 14.0], [Vector2(16, -6), 16.0], [Vector2(34, 0), 12.0], [Vector2(-14, 3), 9.0], [Vector2(18, 6), 13.0]]:
			draw_circle(p + c[0] * s, c[1] * s, col)

	func _feather(p: Vector2, rot: float, s: float, col: Color) -> void:
		_local(p, rot, s)
		_poly(PackedVector2Array([Vector2(0, -6), Vector2(2.4, -1), Vector2(0, 6), Vector2(-2.4, -1)]), col)
		draw_line(Vector2(0, -6), Vector2(0, 8), col.darkened(0.35), 1.0)
		_reset()

	func _angel(p: Vector2, s: float, col: Color, flap: float, rot := 0.0, halo := true, torn := 0) -> void:
		## Silueta de ángel con alas de tres plumas largas (torn = plumas que le faltan)
		_local(p, rot, s)
		var f := sin(flap) * 4.0
		for side in [-1.0, 1.0]:
			var tips := [Vector2(side * 16, -12 - f), Vector2(side * 18, -4 - f * 0.6), Vector2(side * 14, 3 - f * 0.3)]
			for k in 3:
				if side > 0.0 and k < torn:
					continue
				_poly(PackedVector2Array([Vector2(side * 2, -3), tips[k], Vector2(side * (6 + k * 2), 1)]), col)
		_poly(PackedVector2Array([Vector2(-3, -4), Vector2(3, -4), Vector2(5, 9), Vector2(-5, 9)]), col)
		draw_circle(Vector2(0, -7), 2.8, col)
		if halo:
			draw_arc(Vector2(0, -12), 3.5, PI * 1.05, TAU * 0.99, 10, Color(1, 0.9, 0.5, col.a), 1.2)
		_reset()

	func _rays(c: Vector2, n: int, r0: float, r1: float, col: Color, rot: float, width := 0.08) -> void:
		for k in n:
			var a := TAU * k / n + rot
			_poly(PackedVector2Array([c + Vector2.from_angle(a - width) * r0, c + Vector2.from_angle(a) * r1, c + Vector2.from_angle(a + width) * r0]), col)

	func _motes(n: int, col: Color, speed: float, up := true) -> void:
		for i in n:
			var s: Array = _seed[i % _seed.size()]
			var y: float = fmod(s[1] + t * speed * s[3] * (-1.0 if up else 1.0) + 720.0, 360.0)
			var x: float = s[0] + sin(t * 0.8 + s[2] * 9.0) * 10.0
			draw_rect(Rect2(Vector2(x, y), Vector2(1, 1) * (1.0 + float(int(s[3] * 1.5)))), Color(col, col.a * (0.4 + 0.6 * s[2])))

	# ------------------------------------------------------------------ láminas
	func _draw() -> void:
		_shake = Vector2.ZERO
		if kind == "war" or (kind == "voice" and glitch_at > 0.0 and absf(t - glitch_at) < 0.35):
			_shake = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		match kind:
			"garden": _garden()
			"choir": _choir()
			"voice": _voice()
			"war": _war()
			"executioner": _executioner()
			"fall": _fall()
			"spiral": _spiral()
			"archons": _archons()
			"ember": _ember()
			"wake": _wake()
			"title": _title()
		draw_set_transform_matrix(Transform2D())

	func _garden() -> void:
		_sky(Color(0.98, 0.8, 0.6), Color(0.58, 0.66, 0.95))
		_set_cam(0.3)
		var sun := Vector2(320, 140)
		_rays(sun, 16, 40.0, 260.0, Color(1, 0.96, 0.8, 0.12), t * 0.05, 0.06)
		for k in 4:
			draw_circle(sun, 70.0 - k * 14.0 + sin(t * 1.4) * 2.0, Color(1, 0.97, 0.85, 0.12 + k * 0.1))
		for i in 6:
			var s: Array = _seed[i]
			_cloud(Vector2(fmod(s[0] + t * 6.0, 760.0) - 60.0, 90.0 + s[1] * 0.25), 1.6, Color(1, 0.95, 0.92, 0.35))
		# islas flotantes (tres profundidades)
		for d in 3:
			_set_cam(0.5 + d * 0.25)
			var sc := 0.6 + d * 0.3
			for k in 2:
				var ix: float = 110.0 + k * 400.0 + d * 70.0 - (k * d * 40.0)
				var iy: float = 205.0 + d * 32.0 + sin(t * 0.7 + k + d) * 4.0
				var w := 90.0 * sc
				var rock := Color(0.48, 0.4, 0.52).lerp(Color(0.62, 0.66, 0.9), 0.5 - d * 0.2)
				_poly(PackedVector2Array([Vector2(ix - w, iy), Vector2(ix + w, iy), Vector2(ix + w * 0.5, iy + 28 * sc), Vector2(ix + w * 0.1, iy + 52 * sc), Vector2(ix - w * 0.4, iy + 30 * sc)]), rock)
				draw_rect(Rect2(ix - w, iy - 5 * sc, w * 2, 6 * sc), Color(0.46, 0.72, 0.46).lerp(Color(0.7, 0.8, 0.95), 0.4 - d * 0.15))
				# templete en la isla más cercana
				if d == 2 and k == 0:
					for c in 4:
						draw_rect(Rect2(ix - 30 + c * 18, iy - 34, 4, 30), Color(0.95, 0.92, 0.85))
					_poly(PackedVector2Array([Vector2(ix - 38, iy - 34), Vector2(ix + 38, iy - 34), Vector2(ix, iy - 52)]), Color(0.98, 0.95, 0.88))
		# ángeles en bandada (cerca de la cámara, paralaje fuerte)
		_set_cam(1.2)
		for i in 9:
			var s2: Array = _seed[10 + i]
			var row := i % 3
			var p := Vector2(fmod(-80.0 + t * 38.0 + i * 26.0, 780.0) - 70.0, 110.0 + row * 16.0 + absf(i - 4) * 8.0 + sin(t * 2.0 + i) * 3.0)
			_angel(p, 0.9 + s2[3] * 0.2, Color(1, 1, 1, 0.95), t * 9.0 + i)
		_set_cam(1.0)
		_motes(30, Color(1, 1, 0.9, 0.8), 14.0)
		_vignette(0.3)

	func _choir() -> void:
		_sky(Color(0.95, 0.75, 0.45), Color(0.45, 0.35, 0.6))
		_set_cam(0.4)
		var gate := Vector2(320, 205)
		_rays(gate + Vector2(0, -70), 20, 30.0, 300.0, Color(1, 0.92, 0.6, 0.12), -t * 0.04)
		# pórtico dorado
		for side in [-1.0, 1.0]:
			draw_rect(Rect2(gate.x + side * 70 - 9, gate.y - 140, 18, 150), Color(0.85, 0.66, 0.3))
			draw_rect(Rect2(gate.x + side * 70 - 9, gate.y - 140, 4, 150), Color(1, 0.88, 0.55))
		draw_arc(gate + Vector2(0, -140), 79.0, PI, TAU, 40, Color(0.85, 0.66, 0.3), 14.0)
		draw_arc(gate + Vector2(0, -140), 72.0, PI, TAU, 40, Color(1, 0.9, 0.6), 2.0)
		draw_rect(Rect2(gate.x - 61, gate.y - 140, 122, 150), Color(1, 0.97, 0.85, 0.35 + 0.1 * sin(t * 2.0)))
		# Seravel en la puerta: las alas se despliegan poco a poco
		_set_cam(0.7)
		var open := _ease(clampf((t - 2.4) / 3.0, 0.0, 1.0))
		var sp := gate + Vector2(0, -38)
		for side2 in [-1.0, 1.0]:
			for k in 6:
				var a = -PI / 2.0 + side2 * (0.25 + (0.25 + k * 0.22) * open)
				var L := 30.0 + k * 3.0 - k * k * 0.6
				draw_line(sp + Vector2(side2 * 4, -14), sp + Vector2(side2 * 4, -14) + Vector2.from_angle(a) * L * (0.4 + 0.6 * open), Color(1, 1, 1, 0.95), 5.0 - k * 0.4)
		_poly(PackedVector2Array([sp + Vector2(-7, -18), sp + Vector2(7, -18), sp + Vector2(10, 18), sp + Vector2(-10, 18)]), Color(0.98, 0.96, 0.94))
		draw_circle(sp + Vector2(0, -24), 6.0, Color(1, 0.92, 0.85))
		draw_arc(sp + Vector2(0, -36), 9.0, 0, TAU, 20, Color(1, 0.88, 0.4), 2.0)
		draw_line(sp + Vector2(14, -10), sp + Vector2(14, 26), Color(0.95, 0.95, 1), 3.0)
		draw_rect(Rect2(sp + Vector2(9, -12), Vector2(10, 3)), Color(1, 0.8, 0.3))
		# el coro sobre nubes, con notas que suben
		_set_cam(1.1)
		for i in 7:
			var cp := Vector2(70.0 + i * 85.0, 268.0 + (i % 2) * 8.0)
			_cloud(cp + Vector2(-16, 14), 1.0, Color(1, 0.96, 0.9, 0.85))
			var bob := sin(t * 2.0 + i * 0.9) * 2.0
			_angel(cp + Vector2(0, bob), 1.1, Color(1, 1, 1), t * 3.0 + i, 0.0, true)
			var nt := fmod(t * 0.7 + i * 0.37, 1.0)
			var np := cp + Vector2(sin(t + i) * 8.0, -20 - nt * 70.0)
			draw_circle(np, 2.0, Color(1, 0.95, 0.7, 1.0 - nt))
			draw_line(np + Vector2(1.5, 0), np + Vector2(1.5, -7), Color(1, 0.95, 0.7, 1.0 - nt), 1.0)
		_set_cam(1.0)
		_motes(24, Color(1, 0.95, 0.75, 0.8), 18.0)
		_vignette(0.35)

	func _voice() -> void:
		var dark := _ease(clampf(t / 5.0, 0.0, 1.0))
		_sky(Color(0.9, 0.7, 0.45).lerp(Color(0.12, 0.06, 0.16), dark), Color(0.6, 0.45, 0.6).lerp(Color(0.32, 0.1, 0.12), dark))
		_set_cam(0.6)
		var c := Vector2(320, 135)
		var open := _ease(clampf((t - 0.6) / 1.6, 0.0, 1.0))
		_rays(c, 28, 70.0, 240.0 + sin(t * 3.0) * 12.0, Color(1, 0.8, 0.4, 0.18 * open), t * 0.12, 0.05)
		draw_arc(c, 66.0, 0, TAU, 64, Color(1, 0.86, 0.45, 0.9 * open), 6.0)
		# ojo: los párpados se abren
		var h := 26.0 * open
		_poly(PackedVector2Array([c + Vector2(-52, 0), c + Vector2(0, -h), c + Vector2(52, 0), c + Vector2(0, h)]), Color(0.98, 0.94, 0.85))
		if open > 0.2:
			var look := Vector2(sin(t * 0.9) * 12.0, 0.0)
			if glitch_at > 0.0 and t > glitch_at:
				look = Vector2(0, 2)   # te mira a ti
			draw_circle(c + look, 16.0 * open, Color(0.85, 0.55, 0.18))
			draw_circle(c + look, 8.0 * open, Color(0.08, 0.03, 0.06))
			draw_circle(c + look + Vector2(-5, -5), 2.5 * open, Color(1, 1, 1, 0.8))
		draw_line(c + Vector2(-54, 0), c + Vector2(0, -h - 2), Color(0.2, 0.1, 0.12), 3.0)
		draw_line(c + Vector2(0, -h - 2), c + Vector2(54, 0), Color(0.2, 0.1, 0.12), 3.0)
		# ángeles que se arrodillan a medida que el ojo se abre
		_set_cam(1.0)
		for i in 11:
			var kp := Vector2(40.0 + i * 56.0, 292.0)
			var bow := _ease(clampf((t - 1.2 - i * 0.12) / 1.2, 0.0, 1.0))
			_local(kp)
			var col := Color(0.12, 0.07, 0.14)
			_poly(PackedVector2Array([Vector2(-7, 0), Vector2(7, 0), Vector2(5, -14 + bow * 6), Vector2(-5, -14 + bow * 6)]), col)
			draw_circle(Vector2(bow * 5, -18 + bow * 9), 3.6, col)
			_poly(PackedVector2Array([Vector2(-4, -12 + bow * 6), Vector2(-16, -24 + bow * 14), Vector2(-9, -4)]), col)
			_poly(PackedVector2Array([Vector2(4, -12 + bow * 6), Vector2(16, -24 + bow * 14), Vector2(9, -4)]), col)
			_reset()
		# fallo: la imagen se desgarra en franjas
		if glitch_at > 0.0 and absf(t - glitch_at) < 0.45:
			draw_set_transform_matrix(Transform2D())
			for k in 8:
				var y := randf_range(42, 318)
				draw_rect(Rect2(randf_range(-30, 30), y, 640, randf_range(2, 9)), Color(1, 0.2, 0.3, 0.35) if k % 2 else Color(0.3, 1, 0.9, 0.25))
		_vignette(0.6)

	func _war() -> void:
		_sky(Color(0.25, 0.03, 0.06), Color(0.95, 0.35, 0.12))
		var bolt := fmod(t, 2.4) < 0.12
		if bolt:
			draw_rect(Rect2(0, 0, 640, 360), Color(1, 0.9, 0.8, 0.35))
		_set_cam(0.4)
		for i in 8:
			var s: Array = _seed[i]
			_cloud(Vector2(fmod(s[0] - t * 10.0 + 700.0, 760.0) - 60.0, 70.0 + s[1] * 0.3), 1.8, Color(0.2, 0.04, 0.06, 0.7))
		if bolt:
			var bx := 120.0 + fmod(floor(t / 2.4) * 197.0, 400.0)
			var pts := PackedVector2Array([Vector2(bx, 42)])
			for k in 6:
				pts.append(Vector2(bx + randf_range(-26, 26), 42 + (k + 1) * 30))
			draw_polyline(pts, Color(1, 0.95, 0.85), 2.0)
		# dos bandos que chocan en el centro
		_set_cam(1.0)
		var clash := _ease(clampf(t / 3.0, 0.0, 1.0))
		for side in [-1.0, 1.0]:
			for i in 8:
				var s2: Array = _seed[20 + i + (8 if side > 0 else 0)]
				var home := Vector2(320 + side * (230 - clash * 150) + side * s2[0] * 0.12, 110 + s2[1] * 0.45)
				var col := Color(0.98, 0.95, 0.9) if side < 0 else Color(0.1, 0.03, 0.06)
				var p := home + Vector2(sin(t * 6.0 + i) * 6.0, cos(t * 5.0 + i) * 5.0)
				_angel(p, 1.0 + s2[3] * 0.3, col, t * 14.0 + i, side * 0.25, side < 0)
				if randf() < 0.05:
					draw_line(p, p + Vector2(-side * 30, randf_range(-14, 14)), Color(1, 1, 0.85, 0.9), 2.0)
		# chispas del choque
		var cc := Vector2(320, 175)
		for k2 in 14:
			var a := TAU * k2 / 14.0 + t * 2.0
			var r := fmod(t * 90.0 + k2 * 17.0, 90.0)
			draw_rect(Rect2(cc + Vector2.from_angle(a) * r, Vector2(2, 2)), Color(1, 0.8, 0.4, 1.0 - r / 90.0))
		_motes(50, Color(1, 0.55, 0.2, 0.9), 40.0)
		_vignette(0.7)

	func _executioner() -> void:
		_sky(Color(0.04, 0.02, 0.06), Color(0.16, 0.04, 0.08))
		_set_cam(0.5)
		var hc := Vector2(320, 150)
		# aureola gigante y agrietada
		draw_arc(hc, 110.0, 0, TAU, 80, Color(1, 0.7, 0.3, 0.18), 18.0)
		draw_arc(hc, 110.0, 0, TAU, 80, Color(1, 0.85, 0.5, 0.8), 3.0)
		for k in 4:
			var a := 0.4 + k * 1.6
			var p0 := hc + Vector2.from_angle(a) * 110.0
			draw_line(p0, p0 + Vector2.from_angle(a + 0.6) * 16.0, Color(0.04, 0.02, 0.06), 3.0)
		_set_cam(1.0)
		var ground := 286.0
		draw_rect(Rect2(0, ground, 640, 40), Color(0.05, 0.02, 0.05))
		# el ángel arrodillado (blanco) y el verdugo sin rostro (negro)
		var torn := t > 5.2
		var ap := Vector2(268, ground - 2)
		_local(ap)
		var wc := Color(0.96, 0.94, 0.92)
		for k2 in 5:
			if k2 == 4 and torn:
				continue
			draw_line(Vector2(4, -26), Vector2(4, -26) + Vector2.from_angle(-PI / 2.0 + 0.5 + k2 * 0.25) * (34.0 - k2 * 3.0), wc, 5.0 - k2 * 0.6)
		_poly(PackedVector2Array([Vector2(-9, 0), Vector2(11, 0), Vector2(8, -24), Vector2(-6, -26)]), wc)
		draw_circle(Vector2(4, -32), 6.0, Color(1, 0.92, 0.85))
		draw_arc(Vector2(4, -44), 8.0, 0, TAU, 18, Color(1, 0.85, 0.45), 1.5)
		_reset()
		var ep := Vector2(372, ground)
		var reach := _ease(clampf((t - 3.4) / 1.6, 0.0, 1.0)) - (_ease(clampf((t - 5.3) / 0.5, 0.0, 1.0)) * 0.8)
		_local(ep)
		var bk := Color(0.02, 0.01, 0.03)
		_poly(PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(11, -58), Vector2(0, -74), Vector2(-11, -58)]), bk)
		_poly(PackedVector2Array([Vector2(-10, -60), Vector2(0, -78), Vector2(10, -60), Vector2(6, -52), Vector2(-6, -52)]), bk)
		_poly(PackedVector2Array([Vector2(-4, -62), Vector2(4, -62), Vector2(2, -56), Vector2(-2, -56)]), Color(0.12, 0.06, 0.1))   # sin rostro
		draw_line(Vector2(-10, -46), Vector2(-10 - 50 * reach, -40 + 4 * reach), bk, 6.0)
		draw_line(Vector2(14, -40), Vector2(30, 6), Color(0.5, 0.45, 0.55), 3.0)   # espada en el suelo
		_reset()
		# la pluma arrancada vuela
		if torn:
			var ft := t - 5.2
			var fp := Vector2(300 + ft * 46.0, ground - 70 - ft * 30.0 + ft * ft * 18.0)
			_feather(fp, ft * 5.0, 2.2, Color(1, 0.98, 0.95))
			for k3 in 6:
				draw_rect(Rect2(fp - Vector2(ft * 20.0 * k3 / 6.0, -k3), Vector2(2, 2)), Color(1, 0.85, 0.5, 0.6 - k3 * 0.1))
			if ft < 0.25:
				draw_set_transform_matrix(Transform2D())
				draw_rect(Rect2(0, 0, 640, 360), Color(1, 1, 1, 0.5 * (1.0 - ft / 0.25)))
		_vignette(0.8)

	func _fall() -> void:
		_sky(Color(0.35, 0.05, 0.1), Color(0.95, 0.38, 0.15))
		_set_cam(0.5)
		for i in 7:
			var s: Array = _seed[i]
			_cloud(Vector2(s[0], fmod(s[1] - t * 30.0 + 720.0, 420.0) - 30.0), 2.0, Color(0.5, 0.12, 0.12, 0.35))
		_set_cam(1.0)
		for i2 in 22:
			var s2: Array = _seed[20 + i2]
			var y: float = fmod(s2[1] + t * 80.0 * s2[3], 440.0) - 50.0
			var p := Vector2(s2[0] + sin(t + i2) * 10.0, y)
			draw_line(p, p - Vector2(0, 40), Color(1, 0.6, 0.3, 0.3), 3.0)
			_angel(p, 0.9 * s2[3] + 0.3, Color(0.08, 0.03, 0.05), t * 16.0, sin(t * 2.0 + s2[2] * 6.0) * 0.9 + PI, false, 2)
		for i3 in 34:
			var s3: Array = _seed[50 + (i3 % 40)]
			var fp := Vector2(s3[0] + sin(t * 1.3 + s3[2] * 9.0) * 18.0, fmod(s3[1] + t * 34.0 * s3[3], 380.0))
			_feather(fp, t * 2.0 * s3[3] + s3[2] * 6.0, 1.0 + s3[3] * 0.4, Color(1, 0.96, 0.92, 0.9))
		_motes(40, Color(1, 0.65, 0.3, 0.9), 26.0)
		_vignette(0.6)

	func _spiral() -> void:
		_sky(Color(0.05, 0.02, 0.08), Color(0.14, 0.05, 0.14))
		draw_set_transform_matrix(Transform2D())
		var c := Vector2(320, 190)
		# descenso por la Espiral: los anillos vienen del fondo hacia la cámara
		var speed := 0.35
		for k in 10:
			var ph := fmod(t * speed + k / 10.0, 1.0)
			var s := pow(ph, 2.2) * 3.4 + 0.04
			var rx := 150.0 * s
			var ry := 52.0 * s
			var a := 0.9 - absf(ph - 0.55) * 1.1
			if a <= 0.0:
				continue
			var rot := t * 0.15 + k * 0.4
			var segs := 18
			for g in segs:
				if (g + k) % 7 == 0:
					continue   # huecos de la piedra
				var a0 := TAU * g / segs + rot
				var a1 := TAU * (g + 0.8) / segs + rot
				var p0 := c + Vector2(cos(a0) * rx, sin(a0) * ry)
				var p1 := c + Vector2(cos(a1) * rx, sin(a1) * ry)
				var p2 := c + Vector2(cos(a1) * rx * 0.86, sin(a1) * ry * 0.86 + 10 * s)
				var p3 := c + Vector2(cos(a0) * rx * 0.86, sin(a0) * ry * 0.86 + 10 * s)
				var lit := 0.5 + 0.5 * sin(a0)
				_poly(PackedVector2Array([p0, p1, p2, p3]), Color(0.38 + 0.2 * lit, 0.3 + 0.12 * lit, 0.42 + 0.15 * lit, a))
				if g % 5 == 0:
					draw_circle(p0 + Vector2(0, -3 * s), 2.0 * s + 0.5, Color(1, 0.6, 0.25, a))   # antorchas
			# cadenas que cuelgan del anillo
			for q in 3:
				var qa := rot + q * 2.1
				var qp := c + Vector2(cos(qa) * rx * 0.9, sin(qa) * ry * 0.9)
				draw_line(qp, qp + Vector2(0, 40 * s), Color(0.3, 0.25, 0.32, a * 0.8), maxf(1.0, s))
		# el Abismo al fondo
		for k2 in 5:
			draw_circle(c, 26.0 - k2 * 5.0, Color(0.5, 0.05, 0.08, 0.15 + k2 * 0.15))
		draw_circle(c, 6.0, Color(0, 0, 0))
		_motes(40, Color(1, 0.5, 0.3, 0.7), -30.0, false)
		_vignette(0.8)

	func _archons() -> void:
		_sky(Color(0.06, 0.02, 0.07), Color(0.12, 0.04, 0.1))
		_set_cam(1.0)
		var xs := [140.0, 320.0, 500.0]
		var cols := [Color(1, 0.45, 0.2), Color(0.7, 0.45, 1.0), Color(1, 0.85, 0.5)]
		for i in 3:
			var appear := _ease(clampf((t - 2.2 * (i + 1) + 0.3) / 0.6, 0.0, 1.0))
			if appear <= 0.0:
				continue
			var x: float = xs[i]
			var col: Color = cols[i]
			# foco que cae desde arriba
			_poly(PackedVector2Array([Vector2(x - 20, 42), Vector2(x + 20, 42), Vector2(x + 75, 300), Vector2(x - 75, 300)]), Color(col, 0.1 * appear))
			draw_set_transform_matrix(_cam * Transform2D(0.0, Vector2(1.0, 0.3), 0.0, Vector2(x, 296)))
			draw_circle(Vector2.ZERO, 60.0, Color(col, 0.18 * appear))
			_reset()
			var base := Vector2(x, 292 + (1.0 - appear) * 20.0)
			var bk := Color(0.02, 0.01, 0.03, appear)
			match i:
				0:   # el Carcelero: cabeza-jaula, hombros enormes, bola de pinchos
					_poly(PackedVector2Array([base + Vector2(-34, 0), base + Vector2(34, 0), base + Vector2(42, -70), base + Vector2(-42, -70)]), bk)
					draw_rect(Rect2(base + Vector2(-18, -110), Vector2(36, 40)), bk)
					for b in 5:
						draw_line(base + Vector2(-14 + b * 7, -108), base + Vector2(-14 + b * 7, -72), Color(col, 0.35 * appear), 1.0)
					draw_rect(Rect2(base + Vector2(-9, -94), Vector2(4, 3)), Color(col, appear))
					draw_rect(Rect2(base + Vector2(5, -94), Vector2(4, 3)), Color(col, appear))
					var bp := base + Vector2(56 + sin(t * 2.0) * 6.0, -20)
					draw_line(base + Vector2(38, -50), bp, Color(0.3, 0.28, 0.32, appear), 2.0)
					draw_circle(bp, 12.0, bk)
					for sp in 8:
						draw_line(bp, bp + Vector2.from_angle(TAU * sp / 8.0 + t) * 17.0, bk, 3.0)
				1:   # el Coro Hueco: tres encapuchados que giran
					for s in 3:
						var a := t * 1.2 + TAU * s / 3.0
						var sp2 := base + Vector2(cos(a) * 34.0, -50 + sin(a) * 10.0)
						var sc := 1.0 + 0.2 * sin(a)
						_local(sp2, 0.0, sc)
						_poly(PackedVector2Array([Vector2(-11, 26), Vector2(11, 26), Vector2(7, -16), Vector2(0, -26), Vector2(-7, -16)]), bk)
						draw_circle(Vector2(-3, -12), 1.5, Color(col, appear))
						draw_circle(Vector2(3, -12), 1.5, Color(col, appear))
						_reset()
				2:   # Seravel: alas abiertas, espada y aureola
					var sp3 := base + Vector2(0, -60 + sin(t * 2.0) * 3.0)
					for side in [-1.0, 1.0]:
						for k in 6:
							draw_line(sp3 + Vector2(0, -10), sp3 + Vector2(0, -10) + Vector2.from_angle(-PI / 2.0 + side * (0.5 + k * 0.26)) * (48.0 - k * 4.0), bk, 6.0 - k * 0.6)
					_poly(PackedVector2Array([sp3 + Vector2(-8, -14), sp3 + Vector2(8, -14), sp3 + Vector2(12, 40), sp3 + Vector2(-12, 40)]), bk)
					draw_circle(sp3 + Vector2(0, -22), 7.0, bk)
					draw_arc(sp3 + Vector2(0, -36), 11.0, 0, TAU, 24, Color(col, appear), 2.0)
					draw_line(sp3 + Vector2(18, -6), sp3 + Vector2(18, 50), Color(0.8, 0.8, 0.9, appear), 2.0)
			# nombre bajo cada silueta
			var nm: String = [G.L(["EL CARCELERO", "THE JAILER"]), G.L(["EL CORO HUECO", "THE HOLLOW CHOIR"]), "SERAVEL"][i]
			var f := UIKit.font("head")
			var w := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			f.draw_string_outline(get_canvas_item(), Vector2(x - w / 2.0, 312), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, appear))
			f.draw_string(get_canvas_item(), Vector2(x - w / 2.0, 312), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(col, appear))
		_motes(24, Color(0.8, 0.6, 0.8, 0.5), 10.0)
		_vignette(0.8)

	func _ember() -> void:
		_sky(Color(0.02, 0.01, 0.03), Color(0.06, 0.02, 0.04))
		_set_cam(1.0)
		var bc := Vector2(320, 236)
		var grow := _ease(clampf(t / 2.5, 0.0, 1.0))
		for k in 7:
			draw_circle(bc + Vector2(0, -14), (110.0 - k * 14.0) * grow, Color(1, 0.5, 0.18, 0.04 + k * 0.025 + sin(t * 5.0) * 0.008))
		# piedra de la Brasa
		_poly(PackedVector2Array([bc + Vector2(-24, 6), bc + Vector2(24, 6), bc + Vector2(16, -4), bc + Vector2(-16, -4)]), Color(0.22, 0.16, 0.2))
		# llama en capas
		var fl := sin(t * 9.0) * 3.0
		_poly(PackedVector2Array([bc + Vector2(-12, -4), bc + Vector2(-4, -30 - fl), bc + Vector2(0, -44 * grow - fl), bc + Vector2(5, -28), bc + Vector2(12, -4)]), Color(1, 0.45, 0.15))
		_poly(PackedVector2Array([bc + Vector2(-7, -4), bc + Vector2(0, -30 * grow + fl * 0.5), bc + Vector2(7, -4)]), Color(1, 0.8, 0.35))
		_poly(PackedVector2Array([bc + Vector2(-3, -4), bc + Vector2(0, -16 * grow), bc + Vector2(3, -4)]), Color(1, 0.98, 0.85))
		# plumas que orbitan la llama (de cerca, más grandes)
		for i in 7:
			var a := t * 0.6 + TAU * i / 7.0
			var depth := sin(a)
			var fp := bc + Vector2(cos(a) * 70.0, -26 + depth * 18.0)
			_feather(fp, a + PI / 2.0, 1.4 + depth * 0.5, Color(1, 0.95, 0.9, 0.5 + 0.5 * (depth * 0.5 + 0.5)))
		_motes(40, Color(1, 0.6, 0.25, 0.9), 22.0)
		_vignette(0.7)

	func _wake() -> void:
		_sky(Color(0.02, 0.01, 0.04), Color(0.08, 0.03, 0.06))
		_set_cam(1.0)
		var bc := Vector2(392, 262)
		for k in 6:
			draw_circle(bc + Vector2(0, -12), 80.0 - k * 12.0, Color(1, 0.5, 0.2, 0.04 + k * 0.025 + sin(t * 6.0) * 0.01))
		_poly(PackedVector2Array([bc + Vector2(-7, 0), bc + Vector2(0, -26 - sin(t * 9.0) * 3.0), bc + Vector2(7, 0)]), Color(1, 0.6, 0.2))
		_poly(PackedVector2Array([bc + Vector2(-3, 0), bc + Vector2(0, -13), bc + Vector2(3, 0)]), Color(1, 0.95, 0.7))
		# te levantas: de rodillas a de pie
		var rise := _ease(clampf((t - 0.8) / 2.2, 0.0, 1.0))
		var tex := Look.back_texture(G.look, 10)
		var hh := 80.0 * (0.72 + 0.28 * rise)
		draw_texture_rect(tex, Rect2(Vector2(262, 262 - hh), Vector2(60, hh)), false, Color(0.8, 0.65, 0.62).lerp(Color(1, 0.85, 0.75), rise))
		# las diez plumas se encienden una a una sobre ti
		var wc := Look.color_of(G.look, "wing")
		for i in 10:
			var on := clampf((t - 3.0 - i * 0.18) / 0.3, 0.0, 1.0)
			if on <= 0.0:
				continue
			var a := PI + PI * (i + 0.5) / 10.0
			var fp := Vector2(292, 196) + Vector2(cos(a) * 64.0, sin(a) * 40.0) + Vector2(0, sin(t * 2.0 + i) * 2.0)
			draw_circle(fp, 7.0 * on, Color(1, 0.8, 0.5, 0.15 * on))
			_feather(fp, a + PI / 2.0, 1.5 * on, Color(wc, on))
		_motes(26, Color(1, 0.6, 0.25, 0.7), 16.0)
		_vignette(0.75)

	func _title() -> void:
		_sky(Color(0.1, 0.03, 0.12), Color(0.38, 0.08, 0.18))
		_set_cam(1.0)
		var c := Vector2(320, 196)
		var a2 := clampf(t / 1.2, 0.0, 1.0)
		_rays(c + Vector2(0, -20), 24, 60.0, 340.0, Color(1, 0.6, 0.4, 0.07 * a2), t * 0.06, 0.05)
		UIKit.wing(self, c + Vector2(-150, -20), -1.0, 46.0 * a2, Color(1, 1, 1, 0.9 * a2), 0.8 + 0.2 * sin(t * 2.0))
		UIKit.wing(self, c + Vector2(150, -20), 1.0, 46.0 * a2, Color(1, 1, 1, 0.9 * a2), 0.8 + 0.2 * sin(t * 2.0))
		draw_arc(c + Vector2(0, -72), 34.0, 0, TAU, 40, Color(1, 0.85, 0.45, 0.85 * a2), 2.0)
		var f := UIKit.font("logo")
		var txt := "SERAPHALL"
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x
		f.draw_string_outline(get_canvas_item(), c + Vector2(-w / 2.0, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, 10, Color(UIKit.RED_DARK, a2))
		f.draw_string_outline(get_canvas_item(), c + Vector2(-w / 2.0, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, 10, Color(UIKit.INK, a2))
		f.draw_string(get_canvas_item(), c + Vector2(-w / 2.0, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color(1, 1, 1, a2))
		var sub := G.L(["LA CAÍDA DEL SERAFÍN", "THE FALL OF THE SERAPH"])
		var hf := UIKit.font("head")
		var sw := hf.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		hf.draw_string(get_canvas_item(), c + Vector2(-sw / 2.0, 30), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(UIKit.GOLD, clampf((t - 0.8) / 0.8, 0.0, 1.0)))
		_motes(50, Color(1, 0.55, 0.3, 0.9), 24.0)
		_vignette(0.6)

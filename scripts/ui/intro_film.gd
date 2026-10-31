extends CanvasLayer
## Corto de introducción: seis láminas animadas con narración que cuentan de qué va SERAPHALL.
## Se puede saltar (Esc / Intro). Al terminar emite "finished".

signal finished

const SCENES := [
	{"kind": "garden", "dur": 6.5, "text": ["Antes de la Espiral había un cielo sin muros. Los serafines cantaban y el Arquitecto los escuchaba.",
		"Before the Spiral there was a sky without walls. The seraphim sang, and the Architect listened."]},
	{"kind": "voice", "dur": 6.0, "text": ["Un día dejó de escuchar... y empezó a dar órdenes.",
		"One day he stopped listening... and began to give orders."]},
	{"kind": "fall", "dur": 6.5, "text": ["Quienes se negaron a obedecer cayeron. Les arrancaron las alas, pluma a pluma.",
		"Those who refused to obey fell. Their wings were torn away, feather by feather."]},
	{"kind": "spiral", "dur": 6.5, "text": ["Para ellos levantó la Espiral: cien círculos de piedra que bajan hasta el Abismo. Aquí nadie muere del todo.",
		"For them he raised the Spiral: a hundred circles of stone falling to the Abyss. Here, no one ever fully dies."]},
	{"kind": "wake", "dur": 7.0, "text": ["Cada muerte te arranca una pluma, y cada pluma, un recuerdo. Acabas de despertar... y todavía te quedan diez.",
		"Every death tears away a feather, and every feather, a memory. You have just woken... and you still have ten."]},
	{"kind": "title", "dur": 4.5, "text": ["", ""]},
]

var _i := -1
var _t := 0.0
var _scene: FilmPlate
var _text: Label
var _fade: ColorRect
var _done := false
var _chars := 0.0

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
	for y in [0.0, 318.0]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, y)
		bar.size = Vector2(640, 42)
		add_child(bar)
	_text = UIKit.label("", 15, Color(0.95, 0.92, 0.88))
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(60, 322)
	_text.size = Vector2(520, 36)
	add_child(_text)
	var hint := UIKit.label(G.L(["[Esc] saltar", "[Esc] skip"]), 8, Color(0.6, 0.55, 0.65), "head", 3)
	hint.position = Vector2(560, 8)
	add_child(hint)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = Vector2(640, 360)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	Audio.play_music("memory", 1.0)
	_next()

func _next() -> void:
	_i += 1
	if _i >= SCENES.size():
		_finish()
		return
	var sc: Dictionary = SCENES[_i]
	_t = 0.0
	_chars = 0.0
	_scene.kind = sc.kind
	_scene.t = 0.0
	_text.text = G.L(sc.text)
	_text.visible_characters = 0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.8)
	if sc.kind == "title":
		Audio.play_music("theme", 2.0)
		Audio.sfx("hit_heavy", -6.0, 0.0)

func _process(delta: float) -> void:
	if _done or _i < 0 or _i >= SCENES.size():
		return
	_t += delta
	_chars += delta * 38.0
	_text.visible_characters = int(_chars)
	var dur: float = SCENES[_i].dur * (0.12 if G.autotest != "" and G.autotest != "film" else 1.0)
	if _t >= dur:
		_t = -999.0
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.7)
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
	## Dibuja la lámina actual con animación propia
	var kind := "garden"
	var t := 0.0
	var _seed := []
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r := RandomNumberGenerator.new()
		r.seed = 7
		for i in 60:
			_seed.append([r.randf() * 640.0, r.randf() * 360.0, r.randf(), r.randf_range(0.6, 1.4)])
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _sky(top: Color, bottom: Color) -> void:
		for y in range(0, 360, 6):
			var k := y / 360.0
			draw_rect(Rect2(0, y, 640, 6), top.lerp(bottom, k))
	func _angel(p: Vector2, s: float, col: Color, flap: float, rot := 0.0) -> void:
		draw_set_transform(p, rot, Vector2(s, s))
		var f := sin(flap) * 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(-1, -2), Vector2(-12, -9 - f), Vector2(-9, 0), Vector2(-2, 2)]), col)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -2), Vector2(12, -9 - f), Vector2(9, 0), Vector2(2, 2)]), col)
		draw_rect(Rect2(-2, -4, 4, 9), col)
		draw_circle(Vector2(0, -6), 2.2, col)
		draw_arc(Vector2(0, -10), 3.0, PI, TAU, 8, Color(1, 0.9, 0.5, col.a), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	func _draw() -> void:
		match kind:
			"garden":
				_sky(Color(0.98, 0.78, 0.55), Color(0.55, 0.62, 0.92))
				draw_circle(Vector2(320, 120), 70.0 + sin(t) * 2.0, Color(1, 0.97, 0.85, 0.5))
				for k in 4:
					var ix := 80.0 + k * 160.0 + sin(t * 0.3 + k) * 6.0
					var iy := 230.0 + (k % 2) * 30.0
					draw_colored_polygon(PackedVector2Array([Vector2(ix - 60, iy), Vector2(ix + 60, iy), Vector2(ix + 30, iy + 40), Vector2(ix - 20, iy + 50)]), Color(0.42, 0.35, 0.45))
					draw_rect(Rect2(ix - 60, iy - 6, 120, 6), Color(0.45, 0.7, 0.45))
				for s in _seed.slice(0, 18):
					var p := Vector2(fmod(s[0] + t * 22.0 * s[3], 700.0) - 30.0, 60.0 + s[1] * 0.45 + sin(t * 1.5 + s[2] * 6.0) * 8.0)
					_angel(p, 0.8 * s[3], Color(1, 1, 1, 0.9), t * 8.0 + s[2] * 6.0)
			"voice":
				_sky(Color(0.25, 0.2, 0.35), Color(0.75, 0.55, 0.35))
				var c := Vector2(320, 110)
				for k in 24:
					var a := TAU * k / 24.0 + t * 0.15
					draw_line(c + Vector2.from_angle(a) * 70.0, c + Vector2.from_angle(a) * (150.0 + sin(t * 3.0 + k) * 10.0), Color(1, 0.85, 0.45, 0.25), 3.0)
				draw_arc(c, 62.0, 0, TAU, 64, Color(1, 0.88, 0.5), 6.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-46, 0), c + Vector2(0, -24), c + Vector2(46, 0), c + Vector2(0, 24)]), Color(0.98, 0.94, 0.85))
				var look := Vector2(sin(t * 0.7) * 10.0, 0)
				draw_circle(c + look, 15.0, Color(0.85, 0.6, 0.2))
				draw_circle(c + look, 7.0, Color(0.1, 0.05, 0.08))
				for k2 in 9:
					var kp := Vector2(80.0 + k2 * 60.0, 285.0)
					draw_set_transform(kp, 0.0, Vector2(1.2, 1.2))
					draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(4, -8), Vector2(-4, -8)]), Color(0.12, 0.08, 0.14))
					draw_circle(Vector2(0, -10), 3.0, Color(0.12, 0.08, 0.14))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"fall":
				_sky(Color(0.35, 0.05, 0.1), Color(0.95, 0.35, 0.15))
				for s in _seed.slice(0, 26):
					var y := fmod(s[1] + t * 70.0 * s[3], 420.0) - 40.0
					var p2 := Vector2(s[0], y)
					draw_line(p2, p2 - Vector2(0, 30), Color(1, 0.6, 0.3, 0.35), 2.0)
					_angel(p2, 0.9 * s[3], Color(0.08, 0.04, 0.06), t * 14.0, sin(t * 2.0 + s[2] * 6.0) * 0.8 + PI)
				for s2 in _seed.slice(26, 60):
					var fp := Vector2(s2[0] + sin(t + s2[2] * 9.0) * 14.0, fmod(s2[1] + t * 40.0 * s2[3], 380.0))
					draw_line(fp, fp + Vector2(3, 6), Color(1, 0.95, 0.9, 0.85), 2.0)
			"spiral":
				_sky(Color(0.06, 0.03, 0.1), Color(0.18, 0.08, 0.2))
				for k in 12:
					var depth := float(k) / 12.0
					var rx := 280.0 * (1.0 - depth * 0.85)
					var ry := rx * 0.28
					var cy := 70.0 + depth * 230.0 + fmod(t * 6.0, 19.0)
					draw_arc(Vector2(320, cy), 1.0, 0, TAU, 2, Color.BLACK, 1.0)
					draw_set_transform(Vector2(320, cy), 0.0, Vector2(1.0, ry / rx))
					draw_arc(Vector2.ZERO, rx, 0, TAU, 72, Color(0.55, 0.45, 0.62, 0.9 - depth * 0.6), 6.0)
					draw_arc(Vector2.ZERO, rx - 5.0, 0, TAU, 72, Color(0.25, 0.18, 0.3, 0.9 - depth * 0.6), 3.0)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_circle(Vector2(320, 320), 30.0, Color(0, 0, 0))
				for k2 in 8:
					var cx := 60.0 + k2 * 75.0
					draw_line(Vector2(cx, 0), Vector2(cx + sin(t + k2) * 6.0, 90.0 + (k2 % 3) * 25.0), Color(0.35, 0.3, 0.38), 2.0)
			"wake":
				_sky(Color(0.02, 0.01, 0.04), Color(0.08, 0.03, 0.06))
				var bc := Vector2(320, 250)
				for k in 5:
					draw_circle(bc + Vector2(0, -12), 60.0 - k * 10.0, Color(1, 0.5, 0.2, 0.05 + k * 0.03 + sin(t * 6.0) * 0.01))
				draw_colored_polygon(PackedVector2Array([bc + Vector2(-6, 0), bc + Vector2(0, -22 - sin(t * 9.0) * 3.0), bc + Vector2(6, 0)]), Color(1, 0.6, 0.2))
				draw_colored_polygon(PackedVector2Array([bc + Vector2(-3, 0), bc + Vector2(0, -12), bc + Vector2(3, 0)]), Color(1, 0.95, 0.7))
				var tex := Look.back_texture(G.look, 10)
				draw_texture_rect(tex, Rect2(Vector2(250, 150), Vector2(60, 80)), false, Color(0.75, 0.6, 0.6))
				var fy := fmod(t * 22.0, 140.0)
				var fpp := Vector2(300 + sin(t * 2.0) * 16.0, 140.0 + fy)
				draw_line(fpp, fpp + Vector2(4, 8), Look.color_of(G.look, "wing"), 2.0)
			"title":
				_sky(Color(0.1, 0.03, 0.12), Color(0.35, 0.08, 0.18))
				var f := UIKit.font("logo")
				var txt := "SERAPHALL"
				var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x
				var a2 := clampf(t / 1.2, 0.0, 1.0)
				f.draw_string_outline(get_canvas_item(), Vector2(320 - w / 2.0, 200 + 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, 10, Color(UIKit.RED_DARK, a2))
				f.draw_string_outline(get_canvas_item(), Vector2(320 - w / 2.0, 200), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, 10, Color(UIKit.INK, a2))
				f.draw_string(get_canvas_item(), Vector2(320 - w / 2.0, 200), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color(1, 1, 1, a2))
				var sub := G.L(["LA CAÍDA DEL SERAFÍN", "THE FALL OF THE SERAPH"])
				var hf := UIKit.font("head")
				var sw := hf.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
				hf.draw_string(get_canvas_item(), Vector2(320 - sw / 2.0, 226), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(UIKit.GOLD, clampf((t - 0.8) / 0.8, 0.0, 1.0)))

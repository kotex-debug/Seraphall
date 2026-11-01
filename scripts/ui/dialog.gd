extends CanvasLayer
## Cuadro de diálogo pixel art con retrato animado, nombre en cinta y texto a máquina de escribir.
## Líneas: [hablante, [es, en]] o [hablante, [es, en], [verdad_es, verdad_en]]:
## con el tercer elemento el texto "falla" y deja ver la verdad unos instantes (el Arquitecto miente).

var box: DialogBox
var _lines: Array = []
var _i := 0
var _done: Callable
var _open := false
var _auto_t := 0.0
var _cinematic := false

const PORTRAITS := {
	"Brenna": ["bust_brenna", Rect2(0, 0, 48, 48)],
	"El Cartógrafo": ["bust_carto", Rect2(0, 0, 48, 48)],
	"Seravel": ["boss_seravel", Rect2(0, 0, 52, 40)],
	"El Carcelero": ["enemy_carcelero", Rect2(0, 0, 40, 30)],
	"El Custodio": ["enemy_custodio", Rect2(0, 0, 48, 36)],
	"Ozias": ["bust_ozias", Rect2(0, 0, 48, 48)],
	"Madre Ilse": ["bust_ilse", Rect2(0, 0, 48, 48)],
	"Nyx": ["bust_nyx", Rect2(0, 0, 48, 48)],
	"Sor Velaria": ["bust_velaria", Rect2(0, 0, 48, 48)],
	"Tobías": ["bust_preso", Rect2(0, 0, 48, 48)],
	"Sael": ["bust_peregrina", Rect2(0, 0, 48, 48)],
	"El Coro": ["boss_singer", Rect2(0, 0, 26, 36)],
}

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	box = DialogBox.new()
	box.position = Vector2(60, 272)
	box.size = Vector2(520, 70)
	box.visible = false
	add_child(box)

func is_open() -> bool:
	return _open

func play(lines: Array, on_done: Callable, cinematic := false) -> void:
	_lines = lines
	_i = 0
	_done = on_done
	_cinematic = cinematic
	if lines.is_empty():
		_open = false
		if on_done.is_valid():
			on_done.call_deferred()
		return
	_open = true
	box.visible = true
	box.pivot_offset = box.size / 2.0
	box.scale = Vector2(1.0, 0.1)
	box.create_tween().tween_property(box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_line()

func _show_line() -> void:
	var ln: Array = _lines[_i]
	var speaker: String = ln[0]
	box.speaker = speaker
	box.text = G.L(ln[1])
	box.truth = G.L(ln[2]) if ln.size() > 2 else ""
	box.glitch = 0.0
	box.chars = 0.0
	box.portrait = PORTRAITS.get(speaker, [])
	box.pop = 1.0
	_auto_t = 2.4 + box.text.length() * 0.045
	Audio.sfx("ui_move", -8.0)

func _advance() -> void:
	if box.chars < box.text.length():
		box.chars = box.text.length()
		return
	_i += 1
	if _i >= _lines.size():
		_open = false
		var tw := box.create_tween()
		tw.tween_property(box, "scale", Vector2(1.0, 0.0), 0.12)
		tw.tween_callback(box.hide)
		if _done.is_valid():
			_done.call()
		return
	_show_line()

func _process(delta: float) -> void:
	if not _open:
		return
	if box.chars < box.text.length():
		var before := int(box.chars)
		box.chars = min(float(box.text.length()), box.chars + delta * 45.0)
		if int(box.chars) != before and int(box.chars) % 2 == 0 and box.text.substr(int(box.chars) - 1, 1) != " ":
			Audio.voice(box.speaker)
	if box.truth != "" and box.chars >= box.text.length() * 0.6:
		box.glitch_t -= delta
		if box.glitch_t <= 0.0:
			box.glitch = 0.16
			box.glitch_t = randf_range(0.9, 1.6)
			Audio.sfx("glitch", -6.0, 0.2)
	box.glitch = max(0.0, box.glitch - delta)
	if G.autotest != "":
		_auto_t = min(_auto_t, 0.05)
	if _cinematic or G.autotest != "":
		_auto_t -= delta
		if _auto_t <= 0.0:
			box.chars = box.text.length()
			_advance()

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("dash") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

class DialogBox extends Control:
	var speaker := ""
	var text := ""
	var chars := 0.0
	var portrait: Array = []
	var truth := ""
	var glitch := 0.0
	var glitch_t := 0.5
	var pop := 0.0
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		pop = max(0.0, pop - delta * 4.0)
		queue_redraw()
	func _draw() -> void:
		var has_p := not portrait.is_empty()
		UIKit.frame(self, Rect2(Vector2.ZERO, size), UIKit.RED, Color(0.07, 0.03, 0.1, 0.96), 4.0, t)
		var tx := 12.0
		if has_p:
			var pr := Rect2(Vector2(8, 8), Vector2(54, 54))
			UIKit.frame(self, pr, UIKit.GOLD_DARK, Color(0.16, 0.06, 0.2), 3.0)
			var tex := Fx.tex(portrait[0])
			var reg: Rect2 = portrait[1]
			var bust: bool = str(portrait[0]).begins_with("bust_")
			if bust:
				# busto propio: boca que se mueve mientras escribe y parpadeo de vez en cuando
				var talking := int(chars) < text.length()
				var fr := 0
				if talking and int(t * 9.0) % 2 == 0:
					fr = 1
				elif fmod(t, 3.3) < 0.13:
					fr = 2
				reg.position.x = fr * 48.0
				var bob2 := roundf(sin(t * 2.2) * 0.6 - pop * 3.0)
				draw_texture_rect_region(tex, Rect2(pr.position + Vector2(3, 3 + bob2), Vector2(48, 48)), reg)
				draw_rect(Rect2(pr.position + Vector2(3, 50), Vector2(48, 1)), UIKit.GOLD_DARK)
			else:
				var frame := int(t * 4.0) % 4
				reg.position.x = frame * reg.size.x if portrait[0] != "enemy_carcelero" else reg.position.x
				var scale = 48.0 / max(reg.size.x, reg.size.y)
				var ds = reg.size * scale
				var bob := roundf(sin(t * 3.0) * 1.0 - pop * 3.0)
				draw_texture_rect_region(tex, Rect2(pr.get_center() - ds / 2.0 + Vector2(0, bob + 4), ds), reg)
			tx = 72.0
		if speaker != "":
			var f := UIKit.font("head")
			var sw := f.get_string_size(speaker.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var band := Rect2(Vector2(tx - 4, -8 - roundf(pop * 3.0)), Vector2(sw + 18, 14))
			UIKit.slash_band(self, Rect2(band.position + Vector2(2, 2), band.size), Color(0, 0, 0, 0.6), 5.0)
			UIKit.slash_band(self, band, UIKit.RED, 5.0)
			f.draw_string_outline(get_canvas_item(), band.position + Vector2(9, 11), speaker.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), band.position + Vector2(9, 11), speaker.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		var bf := UIKit.font("body")
		var shown := text.substr(0, int(chars))
		var tcol := UIKit.WHITE
		var off := Vector2.ZERO
		if glitch > 0.0:
			shown = truth
			tcol = Color(1, 0.25, 0.3)
			off = Vector2(randf_range(-2, 2), randf_range(-1, 1)).round()
			for k in 4:
				var gy := randf_range(4, size.y - 8)
				draw_rect(Rect2(Vector2(randf_range(0, size.x * 0.5), gy), Vector2(randf_range(40, 200), 2)), Color(1, 0.2, 0.3, 0.5))
		bf.draw_multiline_string_outline(get_canvas_item(), Vector2(tx, 24) + off, shown, HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 14, 15, 3, 3, UIKit.INK)
		if glitch > 0.0:
			bf.draw_multiline_string(get_canvas_item(), Vector2(tx + 2, 24) + off, shown, HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 14, 15, 3, Color(0.3, 0.8, 1, 0.7))
		bf.draw_multiline_string(get_canvas_item(), Vector2(tx, 24) + off, shown, HORIZONTAL_ALIGNMENT_LEFT, size.x - tx - 14, 15, 3, tcol)
		if int(chars) >= text.length():
			var ay := size.y - 10 + roundf(sin(t * 8.0) * 2.0)
			for i in 4:
				draw_rect(Rect2(Vector2(size.x - 18 + i, ay + i), Vector2(8 - i * 2, 1)), UIKit.GOLD)

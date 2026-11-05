extends Control
## Elegir partida: tres huecos. Uno vacío empieza una partida nueva; uno ocupado la continúa o se puede borrar.

signal chosen(slot: int, occupied: bool)
signal cancelled

var sel := 0
var _t := 0.0
var _pop := 0.0
var _cards: Array[Rect2] = []
var _data: Array = []
var _busts: Array = []
var _del_btns: Array[Button] = []
var _confirm_del := -1

func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reload()
	sel = clampi(Prog.slot - 1, 0, Prog.SAVE_SLOTS - 1)
	for i in Prog.SAVE_SLOTS:
		var r := Rect2(Vector2(36, 54 + i * 88), Vector2(568, 80))
		_cards.append(r)
		var b := Button.new()
		b.theme = UIKit.button_theme(8)
		b.custom_minimum_size = Vector2(92, 20)
		b.position = r.end - Vector2(104, 30)
		b.pressed.connect(_on_delete.bind(i))
		add_child(b)
		UIKit.juicy(b)
		_del_btns.append(b)
	var back := Button.new()
	back.text = G.T("back").to_upper()
	back.theme = UIKit.button_theme(8)
	back.custom_minimum_size = Vector2(90, 20)
	back.position = Vector2(24, 328)
	back.pressed.connect(_on_back)
	add_child(back)
	UIKit.juicy(back)
	_refresh_buttons()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _reload() -> void:
	_data.clear()
	_busts.clear()
	for i in Prog.SAVE_SLOTS:
		var has := Prog.has_save(i + 1)
		var d: Dictionary = Prog.peek_save(i + 1) if has else {}
		_data.append({"has": has, "ok": not d.is_empty(), "d": d})
		var lk: Dictionary = d.get("look", {})
		_busts.append(Look.bust_texture(Look.sane(lk), int(d.get("wing_feathers", 10))) if not lk.is_empty() else null)

func _refresh_buttons() -> void:
	for i in _del_btns.size():
		_del_btns[i].visible = _data[i].has
		_del_btns[i].text = G.L(["¿SEGURO?", "SURE?"]) if _confirm_del == i else G.L(["BORRAR", "DELETE"])
		_del_btns[i].add_theme_color_override("font_color", UIKit.RED if _confirm_del == i else UIKit.WHITE)

func _on_delete(i: int) -> void:
	sel = i
	if _confirm_del != i:
		_confirm_del = i
		Audio.sfx("ui_move")
		_refresh_buttons()
		return
	Prog.delete_save(i + 1)
	_confirm_del = -1
	Audio.sfx("feather_tear", -4.0, 0.0)
	G.flash(Color(1, 0.3, 0.3, 0.25), 0.2)
	_pop = 1.0
	_reload()
	_refresh_buttons()

func _pick() -> void:
	_confirm_del = -1
	Audio.sfx("ui_ok")
	G.flash(Color(1, 1, 1, 0.3), 0.15)
	chosen.emit(sel + 1, bool(_data[sel].has))
	queue_free()

func _on_back() -> void:
	Audio.sfx("ui_move")
	cancelled.emit()
	queue_free()

func _move(d: int) -> void:
	sel = wrapi(sel + d, 0, Prog.SAVE_SLOTS)
	_confirm_del = -1
	_pop = 0.6
	Audio.sfx("ui_move", -4.0)
	_refresh_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm_del >= 0:
			_confirm_del = -1
			_refresh_buttons()
		else:
			_on_back()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("up"):
		_move(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("down"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_pick()
	elif _data[sel].has and ((event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_DELETE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y)):
		_on_delete(sel)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		for i in _cards.size():
			if _cards[i].has_point(event.position) and sel != i:
				_move(i - sel)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _cards.size():
			if _cards[i].has_point(event.position):
				sel = i
				_pick()
				return

func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(0.0, _pop - delta * 3.0)
	queue_redraw()

func _str(p: Vector2, txt: String, col: Color, sz := 8, kind := "head", w := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var f := UIKit.font(kind)
	f.draw_string_outline(get_canvas_item(), p, txt, align, w, sz, 4 if sz > 10 else 3, UIKit.INK)
	f.draw_string(get_canvas_item(), p, txt, align, w, sz, col)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.01, 0.06, 0.86))
	var off := fmod(_t * 14.0, 32.0)
	for i in range(-20, 40):
		var x := i * 32.0 + off
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 10, 0), Vector2(x - 350, 360), Vector2(x - 360, 360)]), Color(1, 0.2, 0.35, 0.03))
	draw_rect(Rect2(0, 0, 640, 40), Color(0.06, 0.02, 0.08, 0.9))
	draw_rect(Rect2(0, 40, 640, 2), UIKit.RED)
	draw_rect(Rect2(0, 318, 640, 42), Color(0.06, 0.02, 0.08, 0.9))
	draw_rect(Rect2(0, 318, 640, 1), UIKit.RED_DARK)
	var lf := UIKit.font("logo")
	var title := G.L(["ELIGE TU PARTIDA", "CHOOSE YOUR SAVE"])
	var tw := lf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
	var tp := Vector2(320 - tw / 2.0, 32 - _pop * 4.0).round()
	lf.draw_string_outline(get_canvas_item(), tp + Vector2(0, 3), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 8, UIKit.RED_DARK)
	lf.draw_string_outline(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 8, UIKit.INK)
	lf.draw_string(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UIKit.WHITE)
	for i in _cards.size():
		_draw_card(i)
	_str(Vector2(0, 357), G.L(["[FLECHAS] ELEGIR    [ENTER] ABRIR    [SUPR] BORRAR    [ESC] VOLVER", "[ARROWS] CHOOSE    [ENTER] OPEN    [DEL] DELETE    [ESC] BACK"]), UIKit.TEXT_DIM, 8, "head", 640, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_card(i: int) -> void:
	var r: Rect2 = _cards[i]
	var picked := i == sel
	var info: Dictionary = _data[i]
	var d: Dictionary = info.d
	var dcol: Color = UIKit.GOLD
	if info.ok:
		dcol = Prog.DIFFICULTIES[clampi(int(d.get("difficulty", 2)), 0, Prog.DIFFICULTIES.size() - 1)].color
	UIKit.frame(self, r, (dcol if picked else dcol.darkened(0.55)) if info.has else (UIKit.WHITE if picked else Color(0.3, 0.2, 0.36)), Color(0.09, 0.03, 0.12, 0.96), 4.0, _t if picked else -1.0)
	# número del hueco
	var nc := r.position + Vector2(28, 40)
	UIKit.diamond(self, nc, 19.0, UIKit.INK)
	UIKit.diamond(self, nc, 17.0, dcol.darkened(0.45) if picked else Color(0.18, 0.1, 0.22))
	_str(nc + Vector2(-20, 7), str(i + 1), UIKit.WHITE, 20, "logo", 40.0, HORIZONTAL_ALIGNMENT_CENTER)
	if not info.has:
		_str(r.position + Vector2(64, 46), G.L(["PARTIDA NUEVA", "NEW GAME"]), UIKit.WHITE if picked else UIKit.TEXT_DIM, 24, "logo")
		_str(r.position + Vector2(66, 62), G.L(["Hueco libre: aquí empieza tu descenso.", "Empty slot: your descent starts here."]), UIKit.TEXT_DIM, 10, "title")
		return
	if not info.ok:
		_str(r.position + Vector2(64, 40), G.L(["PARTIDA DAÑADA", "DAMAGED SAVE"]), UIKit.RED, 20, "logo")
		_str(r.position + Vector2(66, 56), G.L(["No se puede leer este archivo. Puedes borrarlo.", "This file can't be read. You may delete it."]), UIKit.TEXT_DIM, 10, "title")
		return
	# retrato
	var br := Rect2(r.position + Vector2(56, 8), Vector2(64, 64))
	draw_rect(br.grow(1), UIKit.INK)
	draw_rect(br, Color(0.14, 0.06, 0.18))
	if _busts[i]:
		var fr := 1 if fmod(_t + i, 3.4) < 0.12 else 0
		draw_texture_rect_region(_busts[i], br.grow(-2), Rect2(fr * 40, 0, 40, 40))
	draw_rect(br, dcol.darkened(0.2), false, 1.0)
	# nombre, nivel y dónde estabas
	var lk: Dictionary = d.get("look", {})
	var nm: String = Look.display_name(Look.sane(lk)) if not lk.is_empty() else "?"
	_str(r.position + Vector2(130, 26), nm.to_upper(), UIKit.WHITE, 20, "logo")
	var nw := UIKit.font("logo").get_string_size(nm.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	_str(r.position + Vector2(138 + nw, 25), "%s %d" % [G.T("level"), int(d.get("level", 1))], UIKit.GOLD, 10, "title")
	var brasa: String = str(d.get("last_brasa", "sanct"))
	var place: String = G.L(Strata.BRASA_NAMES.get(brasa, Strata.BRASA_NAMES.sanct))
	_str(r.position + Vector2(130, 40), place, UIKit.CYAN, 10, "title")
	var ddef: Dictionary = Prog.DIFFICULTIES[clampi(int(d.get("difficulty", 2)), 0, Prog.DIFFICULTIES.size() - 1)]
	var tag: String = G.L(ddef.name) + ((" · NG+%d" % int(d.ng)) if int(d.get("ng", 0)) > 0 else "")
	_str(r.position + Vector2(130, 53), tag, dcol, 10, "title")
	# plumas que te quedan
	var wf := int(d.get("wing_feathers", 10))
	var ft := Fx.tex("icon_feather")
	for k in Prog.WING_MAX:
		draw_texture_rect(ft, Rect2(r.position + Vector2(130 + k * 11, 58), Vector2(12, 12)), false, Color.WHITE if k < wf else Color(0.25, 0.2, 0.3, 0.6))
	# tiempo y Arcontes caídos
	var pt := float(d.get("playtime", 0.0))
	_str(r.position + Vector2(r.size.x - 110, 20), "%d:%02d" % [int(pt / 3600.0), int(pt / 60.0) % 60], UIKit.WHITE, 16, "head", 98.0, HORIZONTAL_ALIGNMENT_RIGHT)
	var flags: Dictionary = d.get("flags", {})
	var ax := r.size.x - 62.0
	for k in 4:
		var a: String = ["seravel", "orrun", "vulkaris", "azrahel"][k]
		var dp := r.position + Vector2(ax + k * 13.0, 32)
		UIKit.diamond(self, dp, 5.0, UIKit.INK)
		UIKit.diamond(self, dp, 4.0, UIKit.RED if flags.get(a + "_dead", false) else Color(0.22, 0.14, 0.26))
	if flags.get("base_complete", false):
		_str(r.position + Vector2(r.size.x - 250, 42), G.L(["FINAL ALCANZADO", "ENDING REACHED"]), UIKit.GOLD, 8, "head", 240.0, HORIZONTAL_ALIGNMENT_RIGHT)

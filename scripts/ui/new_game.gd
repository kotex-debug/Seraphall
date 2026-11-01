extends Control
## Nueva partida: 1) elegir el Descenso (dificultad)  2) crear al Desplumado (chica o chico y detalles).

signal finished(difficulty: int, look: Dictionary)
signal cancelled

var stage := "diff"
var diff_sel := 2
var look := {}
var row_sel := 0
var _t := 0.0
var _pop := 0.0
var _anim_t := 0.0
var _cards: Array[Rect2] = []
var _rows: Array = []          # [clave, rect de fila, [rects de opciones]]
var _name_edit: LineEdit
var _btns: Array[Button] = []
var _bust_tex: Texture2D
var _preview_tex: Texture2D
var _facing := 1
var _burst := 0.0

const ROWS := ["body", "hair", "hair_col", "skin", "eye", "cloak", "armor", "wing", "halo", "name"]

func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_STOP
	look = Look.sane(G.look if not G.look.is_empty() else {})
	diff_sel = clampi(Prog.difficulty, 0, Prog.DIFFICULTIES.size() - 1)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_enter_diff()

func _clear_ui() -> void:
	for b in _btns:
		b.queue_free()
	_btns.clear()
	if _name_edit:
		_name_edit.queue_free()
		_name_edit = null

func _btn(text: String, pos: Vector2, w: float, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = Vector2(w, 20)
	b.theme = UIKit.button_theme(8)
	b.pressed.connect(cb)
	add_child(b)
	UIKit.juicy(b)
	_btns.append(b)
	return b

# ====================================================================== etapa 1: dificultad
func _enter_diff() -> void:
	stage = "diff"
	_clear_ui()
	_pop = 1.0
	_btn(G.T("back").to_upper(), Vector2(24, 328), 90, _on_back)
	_btn(G.L(["CONTINUAR", "CONTINUE"]), Vector2(516, 328), 100, _confirm_diff)

func _confirm_diff() -> void:
	Audio.sfx("ui_ok")
	G.flash(Color(Prog.DIFFICULTIES[diff_sel].color, 0.25), 0.2)
	_enter_creator()

func _on_back() -> void:
	Audio.sfx("ui_move")
	if stage == "creator":
		_enter_diff()
	else:
		cancelled.emit()
		queue_free()

# ====================================================================== etapa 2: creador
func _enter_creator() -> void:
	stage = "creator"
	_clear_ui()
	_pop = 1.0
	row_sel = 0
	_refresh_preview()
	_name_edit = LineEdit.new()
	_name_edit.max_length = 14
	_name_edit.placeholder_text = Look.display_name({"body": look.body})
	_name_edit.text = str(look.get("name", ""))
	_name_edit.position = Vector2(372, 280)
	_name_edit.size = Vector2(150, 18)
	_name_edit.theme = UIKit.button_theme(8)
	_name_edit.add_theme_font_override("font", UIKit.font("head"))
	_name_edit.add_theme_font_size_override("font_size", 8)
	_name_edit.text_changed.connect(_on_name)
	add_child(_name_edit)
	_btn(G.T("back").to_upper(), Vector2(24, 328), 90, _on_back)
	_btn(G.T("randomize"), Vector2(128, 328), 100, _randomize)
	var go := _btn(G.T("begin_descent"), Vector2(428, 328), 188, _finish)
	go.grab_focus.call_deferred()

func _on_name(t: String) -> void:
	look.name = t
	_pop = 0.4

func _refresh_preview() -> void:
	_preview_tex = Look.texture(look, Prog.WING_MAX)
	_bust_tex = Look.bust_texture(look, Prog.WING_MAX)
	_burst = 1.0

func _randomize() -> void:
	look.body = ["f", "m"][randi() % 2]
	look.hair = randi() % 3
	for k in Look.OPTIONS:
		look[k] = randi() % Look.OPTIONS[k].size()
	Audio.sfx("ui_ok")
	_refresh_preview()

func _change(key: String, delta: int) -> void:
	match key:
		"body":
			look.body = "m" if look.body == "f" else "f"
			if _name_edit:
				_name_edit.placeholder_text = Look.display_name({"body": look.body})
		"hair":
			look.hair = wrapi(int(look.hair) + delta, 0, 3)
		"name":
			return
		_:
			look[key] = wrapi(int(look[key]) + delta, 0, Look.OPTIONS[key].size())
	Audio.sfx("ui_move", -4.0)
	_refresh_preview()

func _set_opt(key: String, v) -> void:
	if key == "body":
		look.body = v
		if _name_edit:
			_name_edit.placeholder_text = Look.display_name({"body": look.body})
	else:
		look[key] = v
	Audio.sfx("ui_move", -4.0)
	_refresh_preview()

func _finish() -> void:
	if _name_edit:
		look.name = _name_edit.text.strip_edges()
	Audio.sfx("levelup", -4.0)
	G.flash(Color(1, 1, 1, 0.5), 0.3)
	finished.emit(diff_sel, Look.sane(look))
	queue_free()

# ====================================================================== entrada
func _unhandled_input(event: InputEvent) -> void:
	if _name_edit and _name_edit.has_focus():
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_name_edit.release_focus()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()
		return
	if stage == "diff":
		if event.is_action_pressed("ui_left") or event.is_action_pressed("left"):
			diff_sel = wrapi(diff_sel - 1, 0, Prog.DIFFICULTIES.size()); _pop = 0.6; Audio.sfx("ui_move", -4.0)
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("right"):
			diff_sel = wrapi(diff_sel + 1, 0, Prog.DIFFICULTIES.size()); _pop = 0.6; Audio.sfx("ui_move", -4.0)
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_confirm_diff()
	else:
		if event.is_action_pressed("up"):
			row_sel = wrapi(row_sel - 1, 0, ROWS.size()); Audio.sfx("ui_move", -8.0)
		elif event.is_action_pressed("down"):
			row_sel = wrapi(row_sel + 1, 0, ROWS.size()); Audio.sfx("ui_move", -8.0)
		elif event.is_action_pressed("left"):
			_change(ROWS[row_sel], -1)
		elif event.is_action_pressed("right"):
			_change(ROWS[row_sel], 1)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = event.position
	if stage == "diff":
		for i in _cards.size():
			if _cards[i].has_point(p):
				if diff_sel == i:
					_confirm_diff()
				else:
					diff_sel = i
					_pop = 0.6
					Audio.sfx("ui_move", -4.0)
		return
	for r in _rows:
		if (r[1] as Rect2).has_point(p):
			row_sel = ROWS.find(r[0])
		var opts: Array = r[2]
		for j in opts.size():
			if (opts[j][0] as Rect2).has_point(p):
				if r[0] == "hair":
					_change("hair", opts[j][1])
				else:
					_set_opt(r[0], opts[j][1])
				return

# ====================================================================== dibujo
func _process(delta: float) -> void:
	_t += delta
	_anim_t += delta
	_pop = max(0.0, _pop - delta * 3.0)
	_burst = max(0.0, _burst - delta * 2.5)
	if fmod(_t, 6.0) < delta:
		_facing = -_facing
	queue_redraw()

func _str(p: Vector2, txt: String, col: Color, sz := 8, kind := "head", w := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var f := UIKit.font(kind)
	f.draw_string_outline(get_canvas_item(), p, txt, align, w, sz, 4 if sz > 10 else 3, UIKit.INK)
	f.draw_string(get_canvas_item(), p, txt, align, w, sz, col)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.01, 0.06, 0.82))
	var off := fmod(_t * 14.0, 32.0)
	for i in range(-20, 40):
		var x := i * 32.0 + off
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 10, 0), Vector2(x - 350, 360), Vector2(x - 360, 360)]), Color(1, 0.2, 0.35, 0.03))
	draw_rect(Rect2(0, 0, 640, 40), Color(0.06, 0.02, 0.08, 0.9))
	draw_rect(Rect2(0, 40, 640, 2), UIKit.RED)
	draw_rect(Rect2(0, 318, 640, 42), Color(0.06, 0.02, 0.08, 0.9))
	draw_rect(Rect2(0, 318, 640, 1), UIKit.RED_DARK)
	if stage == "diff":
		_draw_diff()
	else:
		_draw_creator()

func _draw_diff() -> void:
	var lf := UIKit.font("logo")
	var title := G.L(["ELIGE TU DESCENSO", "CHOOSE YOUR DESCENT"])
	var tw := lf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
	var tp := Vector2(320 - tw / 2.0, 32 - _pop * 4.0).round()
	lf.draw_string_outline(get_canvas_item(), tp + Vector2(0, 3), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 8, UIKit.RED_DARK)
	lf.draw_string_outline(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, 8, UIKit.INK)
	lf.draw_string(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UIKit.WHITE)
	_cards.clear()
	var n := Prog.DIFFICULTIES.size()
	var cw := 142.0
	var gap := 10.0
	var x0 := 320.0 - (n * cw + (n - 1) * gap) / 2.0
	for i in n:
		var d: Dictionary = Prog.DIFFICULTIES[i]
		var sel := i == diff_sel
		var lift := (10.0 + sin(_t * 3.0) * 2.0) if sel else 0.0
		var r := Rect2(Vector2(x0 + i * (cw + gap), 62 - lift), Vector2(cw, 238))
		_cards.append(r)
		var col: Color = d.color
		if sel:
			for k in 8:
				var a := TAU * k / 8.0 + _t * 0.6
				var dv := Vector2.from_angle(a)
				var c := r.get_center() + Vector2(0, -50)
				draw_colored_polygon(PackedVector2Array([c + dv * 20 + dv.orthogonal() * 5, c + dv * 90, c + dv * 20 - dv.orthogonal() * 5]), Color(col, 0.09))
		UIKit.frame(self, r, col if sel else Color(col.darkened(0.55), 1.0), Color(0.09, 0.03, 0.12, 0.96), 4.0, _t if sel else -1.0)
		# emblema: calaveras / pluma
		var ec := r.position + Vector2(cw / 2.0, 46)
		draw_circle(ec, 22.0, UIKit.INK)
		draw_circle(ec, 20.0, Color(col, 0.25 if sel else 0.12))
		draw_arc(ec, 20.0, 0, TAU, 32, col, 2.0)
		var sk := int(d.skulls)
		if sk == 0:
			draw_colored_polygon(PackedVector2Array([ec + Vector2(0, -12), ec + Vector2(6, -2), ec + Vector2(3, 10), ec + Vector2(-3, 10), ec + Vector2(-6, -2)]), col)
			draw_line(ec + Vector2(0, -10), ec + Vector2(0, 12), UIKit.INK, 1.0)
		for k in sk:
			var sp := ec + Vector2((k - (sk - 1) / 2.0) * 11.0, 0)
			draw_rect(Rect2(sp - Vector2(4, 5), Vector2(9, 8)), UIKit.INK)
			draw_rect(Rect2(sp - Vector2(3, 4), Vector2(7, 6)), col)
			draw_rect(Rect2(sp + Vector2(-2, -2), Vector2(2, 2)), UIKit.INK)
			draw_rect(Rect2(sp + Vector2(1, -2), Vector2(2, 2)), UIKit.INK)
			draw_rect(Rect2(sp + Vector2(-2, 3), Vector2(5, 2)), col.darkened(0.3))
		_str(r.position + Vector2(0, 92), G.L(d.name).to_upper(), UIKit.WHITE if sel else UIKit.TEXT_DIM, 20, "logo", cw, HORIZONTAL_ALIGNMENT_CENTER)
		_str(r.position + Vector2(0, 108), G.L(d.tag), col, 10, "title", cw, HORIZONTAL_ALIGNMENT_CENTER)
		var bf := UIKit.font("body")
		var desc := G.L(d.desc)
		bf.draw_multiline_string_outline(get_canvas_item(), r.position + Vector2(10, 128), desc, HORIZONTAL_ALIGNMENT_LEFT, cw - 20, 15, 7, 3, UIKit.INK)
		bf.draw_multiline_string(get_canvas_item(), r.position + Vector2(10, 128), desc, HORIZONTAL_ALIGNMENT_LEFT, cw - 20, 15, 7, Color(1, 1, 1, 0.92) if sel else UIKit.TEXT_DIM)
		if i == 2:
			UIKit.slash_band(self, Rect2(r.position + Vector2(18, -8), Vector2(cw - 36, 13)), UIKit.RED, 4.0)
			_str(r.position + Vector2(0, 2), G.L(["RECOMENDADO", "RECOMMENDED"]), UIKit.WHITE, 8, "head", cw, HORIZONTAL_ALIGNMENT_CENTER)
	_str(Vector2(0, 357), G.L(["[<- ->] ELEGIR    [ENTER] CONFIRMAR    [ESC] VOLVER", "[<- ->] CHOOSE    [ENTER] CONFIRM    [ESC] BACK"]), UIKit.TEXT_DIM, 8, "head", 640, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_creator() -> void:
	var lf := UIKit.font("logo")
	var title := G.T("create_char")
	var tw := lf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	var tp := Vector2(320 - tw / 2.0, 31 - _pop * 4.0).round()
	lf.draw_string_outline(get_canvas_item(), tp + Vector2(0, 3), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, UIKit.RED_DARK)
	lf.draw_string_outline(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, UIKit.INK)
	lf.draw_string(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UIKit.WHITE)
	# ---- vista previa
	var pr := Rect2(20, 50, 236, 262)
	var halo_c := Look.color_of(look, "halo")
	var wing_c := Look.color_of(look, "wing")
	UIKit.frame(self, pr, UIKit.RED, Color(0.08, 0.03, 0.11, 0.95), 4.0, _t)
	var c := pr.position + Vector2(pr.size.x / 2.0, 150)
	for k in 12:
		var a := TAU * k / 12.0 + _t * 0.4
		var dv := Vector2.from_angle(a)
		draw_colored_polygon(PackedVector2Array([c + dv * 40 + dv.orthogonal() * 6, c + dv * (110 + _burst * 30), c + dv * 40 - dv.orthogonal() * 6]), Color(halo_c, 0.08 + _burst * 0.1))
	# pedestal
	for k in 5:
		draw_rect(Rect2(c + Vector2(-70 + k * 10, 78 - k * 3), Vector2(140 - k * 20, 3)), Color(halo_c, 0.12 + k * 0.08))
	# plumas que caen
	for k in 7:
		var fp := Vector2(pr.position.x + 16 + fmod(k * 41.0 + _t * 9.0, pr.size.x - 32), pr.position.y + fmod(_t * 18.0 + k * 53.0, pr.size.y - 20) + 10)
		draw_line(fp, fp + Vector2(2, 5), Color(wing_c, 0.5), 2.0)
	if _preview_tex:
		var cyc := fmod(_anim_t, 7.0)
		var row := 0
		var nfr := 4
		var fps := 5.0
		if cyc > 3.0 and cyc < 5.0:
			row = 1; nfr = 6; fps = 10.0
		elif cyc >= 5.0 and cyc < 5.6:
			row = 2; nfr = 3; fps = 6.0
		var fr := int(_anim_t * fps) % nfr
		var sc := 5.0 + _burst * 0.5
		var ds := Vector2(32, 32) * sc
		var bob := roundf(sin(_t * 3.0) * 2.0)
		var dest := Rect2(c - Vector2(ds.x / 2.0, ds.y - 82) + Vector2(0, bob), ds)
		if _facing < 0:
			draw_set_transform(Vector2(c.x * 2.0, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect_region(_preview_tex, dest, Rect2(fr * 32, row * 32, 32, 32))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# retrato en primer plano (el mismo del HUD), en un medallón abajo a la izquierda
	if _bust_tex:
		var mr := Rect2(pr.position + Vector2(10, pr.size.y - 66), Vector2(56, 56))
		draw_rect(mr.grow(2), UIKit.INK)
		draw_rect(mr, Color(0.12, 0.05, 0.16))
		var bfr := 1 if fmod(_t, 3.6) < 0.12 else (4 if fmod(_t, 9.0) > 7.5 else 0)
		draw_texture_rect_region(_bust_tex, Rect2(mr.position + Vector2(4, 4), Vector2(48, 48)), Rect2(bfr * 40, 0, 40, 40))
		draw_rect(mr, Look.color_of(look, "halo"), false, 1.0)
	var nm := str(look.get("name", "")).strip_edges()
	if _name_edit:
		nm = _name_edit.text.strip_edges()
	if nm == "":
		nm = Look.display_name({"body": look.body})
	_str(pr.position + Vector2(0, 24), nm.to_upper(), UIKit.GOLD, 20, "logo", pr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_str(pr.position + Vector2(0, 36), (G.T("girl") if look.body == "f" else G.T("boy")).to_upper() + "  -  " + G.L(["DESCENSO ", "DESCENT "]) + G.L(Prog.DIFFICULTIES[diff_sel].name).to_upper(), Prog.DIFFICULTIES[diff_sel].color, 8, "head", pr.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	# ---- opciones
	var panel := Rect2(268, 50, 352, 262)
	UIKit.frame(self, panel, UIKit.PURPLE, Color(0.08, 0.03, 0.11, 0.95), 4.0, -1.0)
	_rows.clear()
	var y := 60.0
	for i in ROWS.size():
		var key: String = ROWS[i]
		var rr := Rect2(Vector2(274, y - 2), Vector2(340, 23))
		var sel := i == row_sel
		if sel:
			UIKit.slash_band(self, rr, Color(UIKit.RED, 0.35 + 0.1 * sin(_t * 6.0)), 5.0)
			draw_rect(Rect2(Vector2(276, y + 3), Vector2(3, 12)), UIKit.PINK)
		var label: String = G.T("hairstyle") if key == "hair" else (G.T("char_name") if key == "name" else G.T(key))
		_str(Vector2(284, y + 13), label.to_upper(), UIKit.WHITE if sel else UIKit.TEXT_DIM, 8)
		var opts := []
		var ox := 372.0
		match key:
			"body":
				for b in [["f", G.T("girl")], ["m", G.T("boy")]]:
					var br := Rect2(Vector2(ox, y), Vector2(70, 17))
					var on: bool = look.body == b[0]
					UIKit.frame(self, br, UIKit.GOLD if on else Color(0.35, 0.22, 0.4), Color(0.14, 0.05, 0.18) if on else Color(0.06, 0.02, 0.08), 3.0, _t if on else -1.0)
					_str(br.position + Vector2(0, 12), str(b[1]).to_upper(), UIKit.WHITE if on else UIKit.TEXT_DIM, 8, "head", 70, HORIZONTAL_ALIGNMENT_CENTER)
					opts.append([br, b[0]])
					ox += 78.0
			"hair":
				var l1 := Rect2(Vector2(ox, y), Vector2(18, 17))
				var r1 := Rect2(Vector2(ox + 160, y), Vector2(18, 17))
				for ar in [[l1, "<"], [r1, ">"]]:
					UIKit.frame(self, ar[0], Color(0.35, 0.22, 0.4), Color(0.06, 0.02, 0.08), 2.0, -1.0)
					_str((ar[0] as Rect2).position + Vector2(0, 12), ar[1], UIKit.GOLD, 8, "head", 18, HORIZONTAL_ALIGNMENT_CENTER)
				_str(Vector2(ox + 18, y + 13), G.L(Look.HAIR_STYLES[look.body][look.hair]).to_upper(), UIKit.WHITE, 8, "head", 142, HORIZONTAL_ALIGNMENT_CENTER)
				opts.append([l1, -1])
				opts.append([r1, 1])
			"name":
				pass
			_:
				var arr: Array = Look.OPTIONS[key]
				for j in arr.size():
					var sw := Rect2(Vector2(ox + j * 19, y + 1), Vector2(15, 15))
					var on2: bool = int(look[key]) == j
					var cc := Color.html(arr[j][2])
					if on2:
						var gp := 2.0 + absf(sin(_t * 5.0))
						draw_rect(sw.grow(gp + 1), UIKit.INK)
						draw_rect(sw.grow(gp), UIKit.WHITE)
					draw_rect(sw.grow(1), UIKit.INK)
					draw_rect(sw, cc)
					draw_rect(Rect2(sw.position, Vector2(sw.size.x, 3)), cc.lightened(0.3))
					draw_rect(Rect2(sw.position + Vector2(0, sw.size.y - 3), Vector2(sw.size.x, 3)), cc.darkened(0.35))
					if key == "armor":
						draw_rect(Rect2(sw.position + Vector2(4, 6), Vector2(7, 2)), Color.html(arr[j][4]))
					opts.append([sw, j])
				var on_name: String = G.L([arr[look[key]][0], arr[look[key]][1]])
				_str(Vector2(ox + arr.size() * 19 + 6, y + 13), on_name.to_upper(), Color.html(arr[look[key]][2]).lerp(UIKit.WHITE, 0.4), 8)
		_rows.append([key, rr, opts])
		y += 25.0
	_str(Vector2(0, 357), G.L(["[ARRIBA/ABAJO] ELEGIR    [IZQ/DCHA] CAMBIAR    [RATÓN] TOCAR", "[UP/DOWN] SELECT    [LEFT/RIGHT] CHANGE    [MOUSE] CLICK"]), UIKit.TEXT_DIM, 8, "head", 640, HORIZONTAL_ALIGNMENT_CENTER)

extends Control
## Pantalla de título animada: cielo con shader, capas de ruinas en parallax, partículas,
## título dorado letra a letra con alas, y menú con selector fluido.

signal action(name: String, arg: String)

var main: Node
var sky: ColorRect
var layers: Array[Node2D] = []
var title_box: Control
var letters: Array[Label] = []
var wings: Control
var sub: Label
var press: Label
var menu_box: VBoxContainer
var selector: Control
var panel: Control
var footer: Label
var _stage := "intro"   # intro | menu | panel
var _t := 0.0
var _mouse := Vector2.ZERO
var _code_edit: LineEdit
var status_label: Label

func _ready() -> void:
	size = Vector2(640, 360)
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = UIKit.button_theme(8)
	sky = ColorRect.new()
	sky.size = Vector2(640, 360)
	sky.material = UIKit.mat("title_sky")
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	_build_layers()
	_build_particles()
	_build_title()
	_build_menu()
	footer = UIKit.label("ALFA 0.8  -  ESTRATO I    ·    " + G.T("fullscreen_hint"), 10, Color(0.65, 0.55, 0.7), "title")
	footer.position = Vector2(8, 344)
	add_child(footer)
	press = UIKit.label(G.T("press_any").to_upper(), 8, UIKit.WHITE, "head")
	press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press.size = Vector2(640, 16)
	press.position = Vector2(0, 268)
	press.modulate.a = 0.0
	add_child(press)
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(640, 360)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var tw := fade.create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(fade.queue_free)
	_animate_title_in()

# ====================================================================== capas de ruinas (parallax)
func _build_layers() -> void:
	var specs := [
		{"depth": 0.25, "col": Color(0.12, 0.05, 0.13), "kind": "spires", "y": 238.0},
		{"depth": 0.5, "col": Color(0.06, 0.025, 0.08), "kind": "island", "y": 150.0},
		{"depth": 0.8, "col": Color(0.035, 0.015, 0.05), "kind": "ruins", "y": 360.0},
		{"depth": 1.2, "col": Color(0.015, 0.008, 0.02), "kind": "front", "y": 360.0},
	]
	for s in specs:
		var l := Silhouette.new()
		l.depth = s.depth
		l.col = s.col
		l.kind = s.kind
		l.base_y = s.y
		add_child(l)
		layers.append(l)

func _build_particles() -> void:
	var embers := CPUParticles2D.new()
	embers.position = Vector2(320, 380)
	embers.amount = 70
	embers.lifetime = 8.0
	embers.preprocess = 8.0
	embers.texture = Fx.tex("fx_soft")
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(340, 10)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(4, -5)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 38.0
	embers.scale_amount_min = 0.08
	embers.scale_amount_max = 0.28
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.6, 0.2, 0))
	g.add_point(0.15, Color(1, 0.75, 0.35, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 0.3, 0.1, 0))
	embers.color_ramp = g
	embers.material = Fx.add_material()
	add_child(embers)
	var feathers := CPUParticles2D.new()
	feathers.position = Vector2(320, -20)
	feathers.amount = 14
	feathers.lifetime = 12.0
	feathers.preprocess = 12.0
	feathers.texture = Fx.tex("fx_feather")
	feathers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	feathers.emission_rect_extents = Vector2(340, 10)
	feathers.direction = Vector2(0.3, 1)
	feathers.spread = 30.0
	feathers.gravity = Vector2(3, 5)
	feathers.initial_velocity_min = 6.0
	feathers.initial_velocity_max = 16.0
	feathers.angular_velocity_min = -80.0
	feathers.angular_velocity_max = 80.0
	feathers.scale_amount_min = 0.8
	feathers.scale_amount_max = 1.5
	var g2 := Gradient.new()
	g2.set_color(0, Color(1, 1, 1, 0))
	g2.add_point(0.15, Color(1, 0.97, 0.92, 0.85))
	g2.set_color(g2.get_point_count() - 1, Color(1, 1, 1, 0))
	feathers.color_ramp = g2
	add_child(feathers)

# ====================================================================== título
var logo: UIKit.PixelText
var halo: Control

func _build_title() -> void:
	title_box = Control.new()
	title_box.position = Vector2(0, 0)
	title_box.size = Vector2(640, 150)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_box)
	wings = WingsDeco.new()
	wings.position = Vector2(320, 70)
	title_box.add_child(wings)
	logo = UIKit.pixel_text("SERAPHALL", 70, "logo", UIKit.WHITE)
	logo.outline = 8
	logo.extrude = 5
	logo.extrude_color = UIKit.RED
	logo.wave = 2.0
	logo.wave_speed = 2.5
	logo.align = 1
	logo.position = Vector2(0, 26)
	logo.size = Vector2(640, 70)
	logo.appear = 0.0
	title_box.add_child(logo)
	var band := SubBand.new()
	band.position = Vector2(320, 106)
	band.name = "flourish"
	title_box.add_child(band)
	sub = UIKit.label(G.T("title_sub").to_upper(), 8, UIKit.WHITE, "head", 4)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(640, 12)
	sub.position = Vector2(0, 100)
	sub.modulate.a = 0.0
	title_box.add_child(sub)

func _animate_title_in() -> void:
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(logo, "appear", 10.0, 1.1)
	tw.tween_callback(_logo_impact)
	tw.tween_property(wings, "open", 1.0, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sub, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(title_box.get_node("flourish"), "grow", 1.0, 0.5).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_show_press)
	if G.autotest == "title":
		_skip_intro()

func _logo_impact() -> void:
	logo.flash = 1.0
	logo.shake = 3.0
	Audio.sfx("hit_heavy", -4.0, 0.0)
	Audio.sfx("parry", -10.0, 0.0)
	var tw := create_tween()
	tw.tween_property(logo, "shake", 0.0, 0.4)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.5)
	flash.size = Vector2(640, 360)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw2 := flash.create_tween()
	tw2.tween_property(flash, "color:a", 0.0, 0.35)
	tw2.tween_callback(flash.queue_free)
	_burst(Vector2(320, 64), UIKit.GOLD, 40)
	_burst(Vector2(320, 64), UIKit.WHITE, 20)

func _burst(pos: Vector2, col: Color, n: int) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 1.0
	p.texture = Fx.tex("fx_px")
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(150, 18)
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 160.0
	p.damping_min = 80.0
	p.damping_max = 140.0
	p.gravity = Vector2(0, 60)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = col
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

func _show_press() -> void:
	if _stage != "intro":
		return
	var tw := press.create_tween().set_loops()
	tw.tween_property(press, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(press, "modulate:a", 0.2, 0.45).set_trans(Tween.TRANS_SINE)

func _skip_intro() -> void:
	logo.appear = 10.0
	wings.open = 1.0
	sub.modulate.a = 1.0
	title_box.get_node("flourish").grow = 1.0
	_open_menu()

func _unhandled_input(event: InputEvent) -> void:
	if _stage == "intro" and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_ok", -2.0, 0.0)
		if logo.appear < 9.0:
			_skip_intro()
		else:
			_open_menu()
	elif _stage == "panel" and event.is_action_pressed("ui_cancel"):
		emit_signal("action", "back", "")

func _open_menu() -> void:
	if _stage == "menu":
		return
	_stage = "menu"
	press.create_tween().tween_property(press, "modulate:a", 0.0, 0.2)
	show_main_menu()

# ====================================================================== menú
func _build_menu() -> void:
	selector = Selector.new()
	selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(selector)
	menu_box = VBoxContainer.new()
	menu_box.position = Vector2(160, 150)
	menu_box.custom_minimum_size = Vector2(320, 0)
	menu_box.add_theme_constant_override("separation", 2)
	add_child(menu_box)

func _clear_menu() -> void:
	for c in menu_box.get_children():
		c.queue_free()
	if panel:
		panel.queue_free()
		panel = null
	selector.target = null

func _menu_button(text: String, act: String, arg := "") -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, empty)
	b.add_theme_font_override("font", UIKit.font("head"))
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.86, 0.8, 0.9))
	b.add_theme_color_override("font_hover_color", UIKit.WHITE)
	b.add_theme_color_override("font_focus_color", UIKit.WHITE)
	b.add_theme_color_override("font_pressed_color", UIKit.GOLD)
	b.add_theme_color_override("font_outline_color", UIKit.INK)
	b.add_theme_constant_override("outline_size", 6)
	b.custom_minimum_size = Vector2(320, 22)
	b.pressed.connect(_on_button.bind(act, arg))
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(_on_focus.bind(b))
	return b

func _on_focus(b: Button) -> void:
	selector.target = b
	Audio.sfx("ui_move", -10.0, 0.0)
	b.pivot_offset = b.size / 2.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.15, 0.85), 0.05)
	tw.tween_property(b, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_button(act: String, arg: String) -> void:
	Audio.sfx("ui_ok", -3.0, 0.0)
	selector.pulse()
	_burst(selector.cur.get_center(), UIKit.GOLD, 16)
	emit_signal("action", act, arg)

func show_main_menu() -> void:
	_stage = "menu"
	_clear_menu()
	var items := []
	if Prog.has_save():
		items.append([G.T("continue"), "continue"])
	items.append([G.T("new_game"), "new"])
	items.append([G.T("host"), "host"])
	items.append([G.T("join"), "join_menu"])
	items.append([G.T("language"), "lang"])
	items.append([G.fs_label(), "fullscreen"])
	items.append([G.T("quit"), "quit"])
	var i := 0
	for it in items:
		var b := _menu_button(it[0], it[1])
		b.modulate.a = 0.0
		menu_box.add_child(b)
		b.pivot_offset = Vector2(160, 11)
		b.scale = Vector2(0.4, 1.6)
		var tw := b.create_tween().set_parallel(true)
		tw.tween_property(b, "modulate:a", 1.0, 0.15).set_delay(0.06 * i)
		tw.tween_property(b, "scale", Vector2.ONE, 0.45).set_delay(0.06 * i).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		i += 1
	menu_box.get_child(0).grab_focus.call_deferred()

## Panel ornamentado (crear/unirse)
func show_panel(kind: String) -> void:
	_stage = "panel"
	_clear_menu()
	panel = OrnatePanel.new()
	panel.position = Vector2(150, 140)
	panel.size = Vector2(340, 190)
	add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	panel.pivot_offset = panel.size / 2
	var tw := panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	var box := VBoxContainer.new()
	box.position = Vector2(20, 14)
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	if kind == "host":
		var h := UIKit.gold_label(G.L(["PARTIDA COOPERATIVA", "CO-OP GAME"]), 16)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.custom_minimum_size = Vector2(300, 0)
		box.add_child(h)
		var l := UIKit.label(G.T("host_wait"), 15, UIKit.TEXT_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(300, 0)
		box.add_child(l)
		status_label = UIKit.label(G.T("code_online") + ":  ...", 10, UIKit.TEXT_DIM, "title")
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_label.custom_minimum_size = Vector2(300, 0)
		box.add_child(status_label)
		var code_l := UIKit.gold_label(Net.lan_code(), 24, "head")
		code_l.name = "code"
		code_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		code_l.custom_minimum_size = Vector2(300, 0)
		box.add_child(code_l)
		var lan := UIKit.label(G.T("code_lan"), 10, UIKit.CYAN, "title")
		lan.name = "codekind"
		lan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lan.custom_minimum_size = Vector2(300, 0)
		box.add_child(lan)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		for b in [[G.L(["Copiar", "Copy"]), "copy"], [G.L(["Empezar", "Start"]), "host_start"], [G.T("back"), "back"]]:
			var bt := Button.new()
			bt.text = b[0]
			bt.pressed.connect(_on_button.bind(b[1], ""))
			UIKit.juicy(bt)
			row.add_child(bt)
		row.get_child(1).grab_focus.call_deferred()
	else:
		var h2 := UIKit.gold_label(G.L(["UNIRSE A UNA PARTIDA", "JOIN A GAME"]), 16)
		h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h2.custom_minimum_size = Vector2(300, 0)
		box.add_child(h2)
		var l2 := UIKit.label(G.T("enter_code"), 15, UIKit.TEXT_DIM)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.custom_minimum_size = Vector2(300, 0)
		box.add_child(l2)
		_code_edit = LineEdit.new()
		_code_edit.placeholder_text = "XXXXX-XXXXX  /  IP"
		_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_code_edit.max_length = 21
		_code_edit.custom_minimum_size = Vector2(300, 26)
		_code_edit.text_submitted.connect(_on_code_submitted)
		box.add_child(_code_edit)
		var row2 := HBoxContainer.new()
		row2.alignment = BoxContainer.ALIGNMENT_CENTER
		row2.add_theme_constant_override("separation", 10)
		box.add_child(row2)
		var c := Button.new()
		c.text = G.T("connect")
		c.pressed.connect(_on_code_submitted.bind(""))
		UIKit.juicy(c)
		row2.add_child(c)
		var bk := Button.new()
		bk.text = G.T("back")
		bk.pressed.connect(_on_button.bind("back", ""))
		UIKit.juicy(bk)
		row2.add_child(bk)
		status_label = UIKit.label("", 15, UIKit.PINK)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.custom_minimum_size = Vector2(300, 0)
		box.add_child(status_label)
		_code_edit.grab_focus.call_deferred()

func _on_code_submitted(_t: String) -> void:
	emit_signal("action", "join", _code_edit.text)

func set_online_code(code: String, ok: bool) -> void:
	if panel == null:
		return
	var code_l: Label = panel.find_child("code", true, false)
	var kind_l: Label = panel.find_child("codekind", true, false)
	if ok and code != "" and code_l:
		code_l.text = code
		kind_l.text = G.T("code_online") + " · " + G.T("upnp_ok")
		kind_l.label_settings.font_color = Color(0.7, 1.0, 0.75)
		status_label.text = G.T("code_lan") + ": " + Net.lan_code()
	elif status_label:
		status_label.text = G.T("upnp_fail")

func set_status(t: String) -> void:
	if status_label and is_instance_valid(status_label):
		status_label.text = t

func toast(text: String) -> void:
	var l := UIKit.label(text, 15, UIKit.GOLD)
	l.position = Vector2(0, 322)
	l.size = Vector2(640, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

# ====================================================================== bucle
func _process(delta: float) -> void:
	_t += delta
	var m := get_viewport().get_mouse_position() / Vector2(640, 360) - Vector2(0.5, 0.5)
	_mouse = _mouse.lerp(m, clamp(delta * 2.5, 0.0, 1.0))
	(sky.material as ShaderMaterial).set_shader_parameter("parallax", _mouse * 4.0)
	for l in layers:
		l.offset = Vector2(-_mouse.x * 30.0 * l.depth, -_mouse.y * 12.0 * l.depth)
		l.queue_redraw()
	title_box.position.y = round(sin(_t * 1.2) * 2.0)

# ====================================================================== clases de dibujo
class Silhouette extends Node2D:
	var depth := 0.5
	var col := Color.BLACK
	var kind := "ruins"
	var base_y := 360.0
	var offset := Vector2.ZERO
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
	func _draw() -> void:
		var o := offset
		match kind:
			"spires":
				var rng := RandomNumberGenerator.new()
				rng.seed = 11
				for i in 22:
					var x := -40.0 + i * 33.0 + rng.randf_range(-10, 10)
					if x > 190 and x < 450:
						continue
					var h: float = rng.randf_range(30, 95) * (1.0 - 0.5 * clamp(1.0 - abs(x - 320.0) / 320.0, 0.0, 1.0))
					var w := rng.randf_range(4, 10)
					var y := base_y + rng.randf_range(-4, 10)
					draw_colored_polygon(PackedVector2Array([o + Vector2(x - w, y + 40), o + Vector2(x - w * 0.5, y - h * 0.7), o + Vector2(x, y - h), o + Vector2(x + w * 0.5, y - h * 0.7), o + Vector2(x + w, y + 40)]), col)
			"island":
				var bob := sin(t * 0.6) * 3.0
				var c := o + Vector2(470, base_y + bob)
				# isla flotante con templo en ruinas
				draw_colored_polygon(PackedVector2Array([c + Vector2(-50, 0), c + Vector2(50, 0), c + Vector2(30, 14), c + Vector2(10, 34), c + Vector2(-4, 44), c + Vector2(-20, 26), c + Vector2(-38, 12)]), col)
				for k in 5:
					var px := -36.0 + k * 17.0
					var ph := 26.0 if k != 3 else 14.0
					draw_rect(Rect2(c + Vector2(px, -ph), Vector2(5, ph)), col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-42, -26), c + Vector2(0, -42), c + Vector2(30, -30), c + Vector2(30, -26)]), col)
				# cadenas que cuelgan
				for k in 3:
					var cx := c.x - 20 + k * 22
					for j in 6:
						draw_arc(Vector2(cx, c.y + 30 + j * 5 + k * 3), 1.8, 0, TAU, 6, col, 1.0)
				# segunda isla lejana a la izquierda
				var c2 := o + Vector2(150, base_y - 40 + sin(t * 0.5 + 2.0) * 2.0)
				draw_colored_polygon(PackedVector2Array([c2 + Vector2(-24, 0), c2 + Vector2(24, 0), c2 + Vector2(8, 18), c2 + Vector2(-6, 22), c2 + Vector2(-16, 10)]), col.lightened(0.05))
				draw_rect(Rect2(c2 + Vector2(-6, -18), Vector2(4, 18)), col.lightened(0.05))
				draw_rect(Rect2(c2 + Vector2(6, -12), Vector2(4, 12)), col.lightened(0.05))
			"ruins":
				# arcos rotos y estatua de ángel caído
				var y0 := base_y
				draw_colored_polygon(PackedVector2Array([o + Vector2(-60, y0), o + Vector2(-60, y0 - 70), o + Vector2(10, y0 - 95), o + Vector2(60, y0 - 75), o + Vector2(95, y0 - 40), o + Vector2(120, y0)]), col)
				draw_colored_polygon(PackedVector2Array([o + Vector2(520, y0), o + Vector2(545, y0 - 50), o + Vector2(600, y0 - 85), o + Vector2(700, y0 - 100), o + Vector2(700, y0)]), col)
				# arco
				var ac := o + Vector2(560, y0 - 85)
				draw_rect(Rect2(ac + Vector2(-8, -60), Vector2(10, 60)), col)
				draw_arc(ac + Vector2(30, -60), 36.0, PI, TAU * 0.86, 20, col, 8.0)
				# estatua arrodillada con alas
				var st := o + Vector2(40, y0 - 95)
				draw_circle(st + Vector2(0, -28), 6.0, col)
				draw_colored_polygon(PackedVector2Array([st + Vector2(-8, -22), st + Vector2(8, -22), st + Vector2(10, 0), st + Vector2(-10, 0)]), col)
				draw_colored_polygon(PackedVector2Array([st + Vector2(4, -20), st + Vector2(40, -50), st + Vector2(46, -36), st + Vector2(30, -14), st + Vector2(8, -6)]), col)
				draw_colored_polygon(PackedVector2Array([st + Vector2(-4, -20), st + Vector2(-34, -44), st + Vector2(-40, -30), st + Vector2(-24, -10), st + Vector2(-8, -6)]), col)
			"front":
				# primer plano: rocas, espada clavada y hierba muerta
				var y1 := base_y
				draw_colored_polygon(PackedVector2Array([o + Vector2(-60, y1), o + Vector2(-60, y1 - 30), o + Vector2(40, y1 - 22), o + Vector2(120, y1 - 8), o + Vector2(160, y1)]), col)
				draw_colored_polygon(PackedVector2Array([o + Vector2(470, y1), o + Vector2(540, y1 - 16), o + Vector2(620, y1 - 26), o + Vector2(700, y1 - 34), o + Vector2(700, y1)]), col)
				var sw := o + Vector2(600, y1 - 26)
				draw_line(sw, sw + Vector2(6, -56), col, 4.0)
				draw_line(sw + Vector2(-6, -44), sw + Vector2(16, -48), col, 3.0)
				for k in 30:
					var gx := -40.0 + k * 7.0 + sin(k * 3.1) * 3.0
					if gx > 150 and gx < 470:
						continue
					var sway := sin(t * 1.5 + k) * 2.0
					draw_line(o + Vector2(gx, y1 - 18), o + Vector2(gx + sway, y1 - 30 - (k % 4) * 3), col, 1.0)

class WingsDeco extends Control:
	var open := 0.0:
		set(v):
			open = v
			queue_redraw()
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if open <= 0.01:
			return
		var flap := 1.0 + sin(t * 3.0) * 0.08
		UIKit.wing(self, Vector2(-150, 0), -1.0, 80.0 * open, UIKit.WHITE, open * flap)
		UIKit.wing(self, Vector2(147, 0), 1.0, 80.0 * open, UIKit.WHITE, open * flap)
		# aureola pixelada sobre el logo
		var hy := -54.0 + roundf(sin(t * 2.0) * 2.0)
		var rx := 44.0 * open
		for i in 48:
			var a := TAU * i / 48.0
			var p := Vector2(cos(a) * rx, sin(a) * 7.0 + hy).round()
			var c := UIKit.GOLD if sin(a * 3.0 + t * 4.0) > -0.2 else UIKit.GOLD_DARK
			draw_rect(Rect2(p, Vector2(2, 2)), c)
		# brillo bajo la aureola
		for i in 3:
			draw_rect(Rect2(Vector2(-rx * (0.8 - i * 0.2), hy + 6 + i * 2).round(), Vector2(rx * (1.6 - i * 0.4), 1)), Color(1, 0.85, 0.3, 0.25 - i * 0.07))

class SubBand extends Control:
	var grow := 0.0:
		set(v):
			grow = v
			queue_redraw()
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if grow < 0.01:
			return
		var w := 150.0 * grow
		UIKit.slash_band(self, Rect2(Vector2(-w - 2, -7 + 2), Vector2(w * 2 + 4, 15)), UIKit.INK, 8.0)
		UIKit.slash_band(self, Rect2(Vector2(-w, -7), Vector2(w * 2, 15)), UIKit.RED, 8.0)
		UIKit.slash_band(self, Rect2(Vector2(-w, -7), Vector2(w * 2, 3)), Color(1, 0.55, 0.62), 2.0)
		for k in 3:
			var x := fmod(t * 90.0 + k * 100.0, w * 2.0) - w
			draw_rect(Rect2(Vector2(x, -7), Vector2(3, 15)), Color(1, 1, 1, 0.25))

class Selector extends Control:
	## Franja roja que sigue al botón enfocado, con flechas que rebotan.
	var target: Control
	var cur := Rect2()
	var _pulse := 0.0
	var t := 0.0
	func pulse() -> void:
		_pulse = 1.0
	func _process(delta: float) -> void:
		t += delta
		_pulse = max(0.0, _pulse - delta * 3.0)
		if target and is_instance_valid(target) and target.is_visible_in_tree():
			var r := Rect2(target.global_position, target.size)
			if cur.size == Vector2.ZERO:
				cur = r
			cur.position = cur.position.lerp(r.position, clamp(delta * 18.0, 0.0, 1.0))
			cur.size = cur.size.lerp(r.size, clamp(delta * 18.0, 0.0, 1.0))
			modulate.a = lerpf(modulate.a, 1.0, clamp(delta * 10.0, 0.0, 1.0))
		else:
			modulate.a = lerpf(modulate.a, 0.0, clamp(delta * 10.0, 0.0, 1.0))
		queue_redraw()
	func _draw() -> void:
		if cur.size == Vector2.ZERO:
			return
		var c := cur.get_center().round()
		var w := 130.0 + 6.0 * sin(t * 6.0) + 20.0 * _pulse
		var band := Rect2(c + Vector2(-w, -10), Vector2(w * 2, 20))
		UIKit.slash_band(self, Rect2(band.position + Vector2(3, 3), band.size), Color(0, 0, 0, 0.5), 10.0)
		UIKit.slash_band(self, band, UIKit.RED.lerp(UIKit.WHITE, _pulse * 0.8), 10.0)
		UIKit.slash_band(self, Rect2(band.position, Vector2(band.size.x, 4)), Color(1, 0.6, 0.66), 2.0)
		var bob := roundf(sin(t * 10.0) * 3.0)
		_arrow(c + Vector2(-w - 16 - bob, 0), 1)
		_arrow(c + Vector2(w + 16 + bob, 0), -1)
	func _arrow(p: Vector2, dir: int) -> void:
		for i in 5:
			var h := 5 - i
			draw_rect(Rect2(p + Vector2((i * 2) * dir - (2 if dir < 0 else 0), -h), Vector2(2, h * 2)), UIKit.WHITE)
		draw_rect(Rect2(p + Vector2(-2 * dir - 1, -1), Vector2(2, 2)), UIKit.GOLD)

class OrnatePanel extends Control:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		UIKit.frame(self, Rect2(Vector2.ZERO, size), UIKit.RED, UIKit.PANEL, 4.0, t)
		UIKit.slash_band(self, Rect2(Vector2(size.x / 2 - 60, -6), Vector2(120, 8)), UIKit.RED, 4.0)

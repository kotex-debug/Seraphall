extends Node
## Raíz del juego: pantalla de título, creación/unión de partidas y carga del mundo.

var title: Control
var title_layer: CanvasLayer
var world: Node2D
var _panel: Control
var _status: Label
var _code_edit: LineEdit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Net.connected_ok.connect(_on_connected)
	Net.connect_failed.connect(_on_connect_failed)
	Net.upnp_done.connect(_on_upnp_done)
	G.language_changed.connect(_build_title)
	match G.autotest:
		"", "none":
			_build_title()
		"host":
			Net.host()
			start_game("new")
		"join":
			Net.join_ip("127.0.0.1")
		"title":
			_build_title()
			await get_tree().create_timer(1.5).timeout
			await _shot(OS.get_environment("SERAPHALL_SHOTS") + "/00_titulo.png")
			get_tree().quit()
		_:
			Prog.reset()
			start_game("new")

# ====================================================================== título
func _build_title() -> void:
	if world:
		return
	if title_layer:
		title_layer.queue_free()
	title_layer = CanvasLayer.new()
	add_child(title_layer)
	title = Control.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(title)
	var bg := TextureRect.new()
	bg.texture = Fx.tex("title_bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.add_child(bg)
	# brasas flotando
	var p := CPUParticles2D.new()
	p.position = Vector2(320, 380)
	p.amount = 60
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.texture = Fx.tex("fx_px")
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(340, 10)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(3, -6)
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 40.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.6, 0.2, 0))
	g.add_point(0.2, Color(1, 0.7, 0.3, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 0.3, 0.1, 0))
	p.color_ramp = g
	p.material = Fx.add_material()
	title.add_child(p)
	var feathers := p.duplicate() as CPUParticles2D
	feathers.texture = Fx.tex("fx_feather")
	feathers.amount = 10
	feathers.position = Vector2(320, -20)
	feathers.direction = Vector2(0.2, 1)
	feathers.gravity = Vector2(4, 6)
	feathers.material = null
	var g2 := Gradient.new()
	g2.set_color(0, Color(1, 1, 1, 0))
	g2.add_point(0.2, Color(1, 1, 1, 0.7))
	g2.set_color(g2.get_point_count() - 1, Color(1, 1, 1, 0))
	feathers.color_ramp = g2
	feathers.angular_velocity_min = -90.0
	feathers.angular_velocity_max = 90.0
	title.add_child(feathers)
	# halo detrás del título
	var halo := TextureRect.new()
	halo.texture = Fx.tex("light")
	halo.modulate = Color(1, 0.75, 0.4, 0.35)
	halo.position = Vector2(192, -10)
	halo.size = Vector2(256, 160)
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	halo.material = Fx.add_material()
	title.add_child(halo)
	var tw := halo.create_tween().set_loops()
	tw.tween_property(halo, "modulate:a", 0.55, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(halo, "modulate:a", 0.3, 2.5).set_trans(Tween.TRANS_SINE)
	var t := _label("SERAPHALL", 44, Color(1, 0.9, 0.7))
	t.label_settings.outline_size = 8
	t.label_settings.outline_color = Color(0.25, 0.05, 0.08)
	t.label_settings.shadow_size = 6
	t.label_settings.shadow_color = Color(1, 0.4, 0.2, 0.35)
	t.position = Vector2(0, 36)
	t.size = Vector2(640, 56)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_child(t)
	var st := _label(G.T("title_sub").to_upper(), 10, Color(0.95, 0.75, 0.55))
	st.position = Vector2(0, 92)
	st.size = Vector2(640, 14)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_child(st)
	_show_main_buttons()
	var ver := _label("v0.1 demo · Estrato I", 7, Color(0.6, 0.55, 0.6))
	ver.position = Vector2(6, 348)
	title.add_child(ver)
	Audio.play_music("theme")

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 3
	ls.outline_color = Color(0.03, 0.01, 0.05)
	l.label_settings = ls
	return l

func _menu_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 11
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.06, 0.04, 0.08, 0.75)
	n.border_color = Color(0.5, 0.4, 0.3, 0.6)
	n.set_border_width_all(1)
	n.content_margin_top = 4; n.content_margin_bottom = 4
	var h := n.duplicate()
	h.bg_color = Color(0.25, 0.12, 0.1, 0.9)
	h.border_color = Color(1, 0.75, 0.4)
	th.set_stylebox("normal", "Button", n)
	th.set_stylebox("hover", "Button", h)
	th.set_stylebox("focus", "Button", h)
	th.set_stylebox("pressed", "Button", h)
	th.set_color("font_color", "Button", Color(0.92, 0.86, 0.78))
	th.set_color("font_hover_color", "Button", Color(1, 0.9, 0.55))
	th.set_color("font_focus_color", "Button", Color(1, 0.9, 0.55))
	var le := StyleBoxFlat.new()
	le.bg_color = Color(0.04, 0.03, 0.06)
	le.border_color = Color(1, 0.75, 0.4)
	le.set_border_width_all(1)
	le.content_margin_left = 6
	th.set_stylebox("normal", "LineEdit", le)
	th.set_stylebox("focus", "LineEdit", le)
	return th

func _clear_panel() -> VBoxContainer:
	if _panel:
		_panel.queue_free()
	var box := VBoxContainer.new()
	box.position = Vector2(200, 130)
	box.custom_minimum_size = Vector2(240, 0)
	box.add_theme_constant_override("separation", 5)
	box.theme = _menu_theme()
	title.add_child(box)
	_panel = box
	return box

func _button(box: Container, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	b.pressed.connect(Audio.sfx.bind("ui_ok", -4.0, 0.0))
	b.focus_entered.connect(Audio.sfx.bind("ui_move", -12.0, 0.0))
	box.add_child(b)
	return b

func _show_main_buttons() -> void:
	var box := _clear_panel()
	var first: Button
	if Prog.has_save():
		first = _button(box, G.T("continue"), _on_continue)
	var ng := _button(box, G.T("new_game"), _on_new)
	if first == null:
		first = ng
	_button(box, G.T("host"), _on_host)
	_button(box, G.T("join"), _show_join)
	_button(box, G.T("language"), G.toggle_language)
	_button(box, G.T("quit"), get_tree().quit)
	first.grab_focus.call_deferred()

func _on_continue() -> void:
	Prog.load_game()
	Net.close()
	start_game("continue")

func _on_new() -> void:
	Prog.reset()
	Net.close()
	start_game("new")

func _on_host() -> void:
	if Net.host() != OK:
		_toast_title(G.T("conn_failed"))
		return
	var box := _clear_panel()
	box.position = Vector2(140, 120)
	box.custom_minimum_size = Vector2(360, 0)
	var l := _label(G.T("host_wait"), 10, Color(0.9, 0.85, 0.8))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	var lan := _label(G.T("code_lan") + ":  " + Net.lan_code(), 14, Color(0.7, 0.9, 1))
	box.add_child(lan)
	_status = _label(G.T("code_online") + ":  ...", 14, Color(1, 0.85, 0.5))
	box.add_child(_status)
	var copy := _button(box, G.L(["Copiar código online", "Copy online code"]), _copy_code)
	copy.name = "copy"
	var cont := Prog.has_save()
	_button(box, G.T("start_alone"), func(): _start_host(cont))
	_button(box, G.T("back"), _back_main)

func _start_host(cont: bool) -> void:
	if cont:
		Prog.load_game()
	else:
		Prog.reset()
	start_game("continue" if cont else "new")

func _copy_code() -> void:
	var c := Net.online_code()
	if c == "":
		c = Net.lan_code()
	DisplayServer.clipboard_set(c)
	_toast_title(G.L(["Código copiado", "Code copied"]) + ": " + c)

func _on_upnp_done(ok: bool, _ip: String) -> void:
	if _status and is_instance_valid(_status):
		if ok:
			_status.text = G.T("code_online") + ":  " + Net.online_code() + "\n" + G.T("upnp_ok")
		else:
			_status.text = G.T("code_online") + ":  —\n" + G.T("upnp_fail")
		_status.label_settings.font_size = 11
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _back_main() -> void:
	Net.close()
	_show_main_buttons()

func _show_join() -> void:
	var box := _clear_panel()
	box.add_child(_label(G.T("enter_code"), 10, Color(0.9, 0.85, 0.8)))
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "XXXXX-XXXXX"
	_code_edit.max_length = 21
	_code_edit.text_submitted.connect(func(_t): _do_join())
	box.add_child(_code_edit)
	_button(box, G.T("connect"), _do_join)
	_button(box, G.T("back"), _back_main)
	_status = _label("", 9, Color(1, 0.7, 0.6))
	box.add_child(_status)
	_code_edit.grab_focus.call_deferred()

func _do_join() -> void:
	var err := Net.join(_code_edit.text)
	if err != OK:
		_status.text = G.T("conn_failed")
		return
	_status.text = G.T("connecting")

func _on_connected() -> void:
	# el cliente usa su propio personaje guardado (o uno nuevo)
	if not Prog.load_game():
		Prog.reset()
	start_game("client")

func _on_connect_failed() -> void:
	if _status and is_instance_valid(_status):
		_status.text = G.T("conn_failed")

func _toast_title(text: String) -> void:
	var l := _label(text, 9, Color(1, 0.85, 0.6))
	l.position = Vector2(0, 330)
	l.size = Vector2(640, 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)

# ====================================================================== partida
func start_game(mode: String) -> void:
	if title_layer:
		title_layer.queue_free()
		title_layer = null
	_panel = null
	_status = null
	world = preload("res://scripts/world/world.gd").new()
	world.setup(self, mode)
	add_child(world)
	if G.autotest != "":
		_run_autotest()

func back_to_title(msg: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if world:
		world.queue_free()
		world = null
	Net.close()
	await get_tree().process_frame
	_build_title()
	if msg != "":
		_toast_title(msg)

# ====================================================================== pruebas automáticas
## --autotest=shots   capturas de pantalla de varias situaciones
## --autotest=host / join   prueba de red local con dos instancias
func _run_autotest() -> void:
	var out := OS.get_environment("SERAPHALL_SHOTS")
	if out == "":
		out = "user://shots"
	DirAccess.make_dir_recursive_absolute(out)
	await get_tree().create_timer(1.0).timeout
	var w := world
	match G.autotest:
		"shots":
			var lp: Player = w.local_player()
			await _shot(out + "/01_santuario.png")
			w._light_brasa("sanct")
			await get_tree().create_timer(1.2).timeout
			await _shot(out + "/02_brasa.png")
			# combate en el pasillo
			lp.respawn_at(w.tile_pos(46, 66))
			await get_tree().create_timer(1.5).timeout
			for i in 6:
				lp.aim = (w.enemies[1].global_position - lp.global_position).normalized()
				lp._start_attack()
				await get_tree().create_timer(0.12).timeout
				if i == 2:
					await _shot(out + "/03_combate.png")
				await get_tree().create_timer(0.2).timeout
			lp.light = 60.0
			lp._cast_lance()
			await get_tree().create_timer(0.1).timeout
			await _shot(out + "/04_hechizo.png")
			lp.wrath = 100.0
			lp._cast_wrath()
			await get_tree().create_timer(0.15).timeout
			await _shot(out + "/05_ira.png")
			await get_tree().create_timer(1.0).timeout
			# galería
			lp.respawn_at(w.tile_pos(80, 60))
			await get_tree().create_timer(2.0).timeout
			await _shot(out + "/06_galeria.png")
			# jefe
			Prog.flags["carcelero_dead"] = true
			w.wflags["carcelero_dead"] = true
			for e in w.enemies:
				if e.type == "carcelero":
					e.die()
			w.set_gate(true)
			lp.respawn_at(w.tile_pos(49, 22))
			await get_tree().create_timer(4.0).timeout
			await _shot(out + "/07_jefe_intro.png")
			await get_tree().create_timer(6.0).timeout
			await _shot(out + "/08_jefe_combate.png")
			var boss: Enemy = w.active_boss
			if boss:
				w._server_damage(boss.idx, boss.max_hp * 0.55, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(4.0).timeout
			await _shot(out + "/09_jefe_fase2.png")
			# menús
			Prog.ecos = 2000
			Prog.skill_points = 5
			Prog.unlock("f1"); Prog.unlock("a1"); Prog.unlock("l1")
			w.menu.open("skills", {})
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/10_arbol.png")
			w.menu.tab = "weapons"; w.menu.ctx = {"forge": true}; w.menu._rebuild()
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/11_forja.png")
			w.menu.tab = "char"; w.menu.ctx = {"brasa": true}; w.menu._rebuild()
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/12_personaje.png")
			w.menu.tab = "quests"; w.menu._rebuild()
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/13_misiones.png")
			w.menu.close()
			print("AUTOTEST_SHOTS_OK")
			get_tree().quit()
		"flow":
			var lp: Player = w.local_player()
			w._light_brasa("sanct")
			w._talk("brenna")
			await get_tree().create_timer(1.0).timeout
			w.menu.close()
			w._talk("carto")
			await get_tree().create_timer(1.0).timeout
			print("Q after talk: ", Prog.quests)
			for e in w.enemies:
				if e.type == "hueco":
					w._server_damage(e.idx, 999.0, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(0.5).timeout
			for id in ["f1", "f2", "f3", "f4", "map"]:
				lp.respawn_at(w.interactables[id].position)
				await get_tree().create_timer(0.3).timeout
			lp.respawn_at(w.interactables["chest_chains"].position + Vector2(0, 8))
			await get_tree().create_timer(0.2).timeout
			w.try_interact(lp)
			for e in w.enemies:
				if e.type == "carcelero":
					e.active = true
					w._server_damage(e.idx, 9999.0, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(3.5).timeout
			print("gate_open=", w.gate_open, " weapons=", Prog.weapons, " feathers=", Prog.feathers, " ecos=", Prog.ecos, " sp=", Prog.skill_points)
			print("Q: ", Prog.quests)
			lp.respawn_at(w.tile_pos(46, 64))
			lp.take_hit(9999.0, Vector2.RIGHT, -1)
			await get_tree().create_timer(4.0).timeout
			print("after death state=", lp.state, " hp=", lp.hp, " dropped=", Prog.dropped_ecos, " pos=", lp.position)
			Prog.upgrade_weapon("sword")
			print("upgrade sword=", Prog.weapons)
			lp.respawn_at(w.tile_pos(49, 22))
			await get_tree().create_timer(9.0).timeout
			var boss: Enemy = w.active_boss
			print("boss active=", boss.active if boss else null, " state=", boss.state if boss else null)
			if boss:
				w._server_damage(boss.idx, 99999.0, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(14.0).timeout
			print("seravel_dead=", Prog.flags.get("seravel_dead"), " main1=", Prog.quests.get("main1"), " k1 can=", Prog.can_unlock("k1"), " weapons=", Prog.weapons.keys())
			print("AUTOTEST_FLOW_OK")
			get_tree().quit()
		"host":
			await get_tree().create_timer(20.0).timeout
			print("HOST players=", w.players.keys(), " joined=", w.joined_peers, " enemy0_hp=", w.enemies[0].hp, " p2pos=", w.players.values()[-1].position)
			get_tree().quit()
		"join":
			await get_tree().create_timer(6.0).timeout
			var lp2: Player = w.local_player()
			if lp2:
				lp2.respawn_at(w.tile_pos(46, 64))
			await get_tree().create_timer(1.0).timeout
			w.request_damage_enemy(w.enemies[0], 20.0, Vector2.RIGHT, 1.0, false)
			await get_tree().create_timer(2.0).timeout
			print("JOIN enemy0_hp=", w.enemies[0].hp, " mypos=", lp2.position if lp2 else Vector2.ZERO)
			print("JOIN players=", w.players.keys(), " my=", Net.my_id(), " alive_enemies=", w.enemies_alive().size())
			get_tree().quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT ", path)

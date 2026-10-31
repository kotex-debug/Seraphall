extends CanvasLayer
## Interfaz en partida: barras, misiones, jefe, avisos, cinemáticas.

var world: Node
var bars: Control
var ecos_label: Label
var feather_label: Label
var quest_box: VBoxContainer
var prompt: Label
var progress: ProgressBar
var boss_panel: Control
var boss_name: Label
var boss_bar: Control
var area_title: Label
var area_sub: Label
var big: Label
var big_band: ColorRect
var toast_box: VBoxContainer
var lb_top: ColorRect
var lb_bot: ColorRect
var flash_rect: ColorRect
var fade_rect: ColorRect
var card: Control
var sub_label: Label
var weapon_icon: TextureRect
var weapon_label: Label
var spells: HBoxContainer
var _boss: Enemy
var _shown_ecos := 0.0

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# viñeta
	var vg := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	var gr := Gradient.new()
	gr.set_color(0, Color(0, 0, 0, 0))
	gr.add_point(0.6, Color(0, 0, 0, 0.0))
	gr.set_color(gr.get_point_count() - 1, Color(0.02, 0, 0.04, 0.75))
	gt.gradient = gr
	gt.width = 128
	gt.height = 72
	vg.texture = gt
	vg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vg.stretch_mode = TextureRect.STRETCH_SCALE
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vg)
	bars = StatBars.new()
	bars.hud = self
	bars.position = Vector2(10, 10)
	bars.size = Vector2(200, 60)
	root.add_child(bars)
	# Ecos / plumas (abajo a la derecha)
	var res := HBoxContainer.new()
	res.position = Vector2(520, 336)
	res.add_theme_constant_override("separation", 4)
	root.add_child(res)
	var fi := TextureRect.new(); fi.texture = Fx.tex("icon_feather"); res.add_child(fi)
	feather_label = _label(9, Color(0.9, 0.9, 1)); res.add_child(feather_label)
	var ei := TextureRect.new(); ei.texture = Fx.tex("icon_eco"); res.add_child(ei)
	ecos_label = _label(10, Color(0.65, 0.88, 1)); res.add_child(ecos_label)
	# arma y hechizos (abajo a la izquierda)
	var wbox := HBoxContainer.new()
	wbox.position = Vector2(10, 330)
	wbox.add_theme_constant_override("separation", 6)
	root.add_child(wbox)
	weapon_icon = TextureRect.new()
	weapon_icon.custom_minimum_size = Vector2(32, 12)
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	wbox.add_child(weapon_icon)
	weapon_label = _label(8, Color(0.95, 0.9, 0.8))
	wbox.add_child(weapon_label)
	spells = HBoxContainer.new()
	spells.position = Vector2(10, 306)
	spells.add_theme_constant_override("separation", 4)
	root.add_child(spells)
	for k in [["Q", "lance"], ["E", "nova"], ["R", "luz"]]:
		var sb := SpellSlot.new()
		sb.key = k[0]
		sb.icon = Fx.tex("icon_" + k[1])
		sb.hud = self
		sb.custom_minimum_size = Vector2(20, 20)
		spells.add_child(sb)
	# misiones
	quest_box = VBoxContainer.new()
	quest_box.position = Vector2(440, 10)
	quest_box.custom_minimum_size = Vector2(190, 0)
	quest_box.add_theme_constant_override("separation", 1)
	root.add_child(quest_box)
	# aviso de interacción
	prompt = _label(9, Color(1, 0.95, 0.8))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(170, 270)
	prompt.size = Vector2(300, 14)
	root.add_child(prompt)
	progress = ProgressBar.new()
	progress.position = Vector2(270, 286)
	progress.size = Vector2(100, 5)
	progress.show_percentage = false
	progress.max_value = 1.0
	progress.visible = false
	root.add_child(progress)
	# jefe
	boss_panel = Control.new()
	boss_panel.position = Vector2(170, 314)
	boss_panel.size = Vector2(320, 30)
	boss_panel.visible = false
	root.add_child(boss_panel)
	boss_name = _label(9, Color(1, 0.88, 0.75))
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.size = Vector2(320, 12)
	boss_panel.add_child(boss_name)
	boss_bar = BossBar.new()
	boss_bar.hud = self
	boss_bar.position = Vector2(0, 14)
	boss_bar.size = Vector2(320, 10)
	boss_panel.add_child(boss_bar)
	# título de zona
	area_title = _label(9, Color(0.85, 0.8, 0.75))
	area_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_title.position = Vector2(0, 92)
	area_title.size = Vector2(640, 14)
	area_title.modulate.a = 0.0
	root.add_child(area_title)
	area_sub = _label(16, Color(1, 0.92, 0.8))
	area_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_sub.position = Vector2(0, 106)
	area_sub.size = Vector2(640, 22)
	area_sub.modulate.a = 0.0
	root.add_child(area_sub)
	# franjas de cine
	lb_top = ColorRect.new(); lb_top.color = Color.BLACK; lb_top.size = Vector2(640, 0); root.add_child(lb_top)
	lb_bot = ColorRect.new(); lb_bot.color = Color.BLACK; lb_bot.position = Vector2(0, 360); lb_bot.size = Vector2(640, 0); root.add_child(lb_bot)
	# mensaje grande
	big_band = ColorRect.new()
	big_band.color = Color(0, 0, 0, 0.6)
	big_band.position = Vector2(0, 150)
	big_band.size = Vector2(640, 48)
	big_band.modulate.a = 0.0
	root.add_child(big_band)
	big = _label(26, Color(1, 0.85, 0.5))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big.position = Vector2(0, 150)
	big.size = Vector2(640, 48)
	big.modulate.a = 0.0
	root.add_child(big)
	sub_label = _label(10, Color(1, 0.9, 0.85))
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.position = Vector2(40, 290)
	sub_label.size = Vector2(560, 14)
	sub_label.modulate.a = 0.0
	root.add_child(sub_label)
	toast_box = VBoxContainer.new()
	toast_box.position = Vector2(120, 34)
	toast_box.custom_minimum_size = Vector2(400, 0)
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(toast_box)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash_rect)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)
	for c in root.get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	G.flash_requested.connect(_on_flash)
	G.toast_requested.connect(toast)
	Prog.changed.connect(_refresh_quests)
	Prog.quest_updated.connect(_on_quest_updated)
	G.language_changed.connect(_refresh_quests)
	_refresh_quests()

func _on_quest_updated(_id: String) -> void:
	_refresh_quests()

func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 3 if size < 14 else 5
	ls.outline_color = Color(0.03, 0.01, 0.05)
	ls.shadow_size = 1
	ls.shadow_color = Color(0, 0, 0, 0.5)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _process(delta: float) -> void:
	_shown_ecos = lerp(_shown_ecos, float(Prog.ecos), clamp(delta * 8.0, 0.0, 1.0))
	if abs(_shown_ecos - Prog.ecos) < 1.0:
		_shown_ecos = Prog.ecos
	ecos_label.text = str(int(round(_shown_ecos)))
	feather_label.text = str(Prog.feathers) + "   "
	var w := Prog.weapon_data()
	weapon_icon.texture = Fx.tex("weapon_" + w.sprite)
	var up: int = Prog.weapons.get(Prog.equipped, 0)
	weapon_label.text = G.L(w.name) + ("  +%d" % up if up > 0 else "")
	var lp: Player = world.local_player() if world else null
	if lp:
		var it: Interactable = world.nearest_interactable(lp) if lp.is_alive() and not world.is_menu_open() else null
		prompt.text = it.prompt() if it else ""
	bars.queue_redraw()
	boss_bar.queue_redraw()
	for s in spells.get_children():
		s.queue_redraw()
	if _boss and (not is_instance_valid(_boss) or not _boss.is_alive()):
		hide_boss()

func set_progress(v: float, text: String) -> void:
	progress.visible = v >= 0.0 and text != ""
	if v >= 0.0:
		progress.value = v
	if text != "":
		prompt.text = text

func _refresh_quests() -> void:
	for c in quest_box.get_children():
		c.queue_free()
	var order := ["main1", "feathers", "husks", "map", "jailer_hunt"]
	var shown := 0
	for id in order:
		if not Prog.quest_active(id) or shown >= 3:
			continue
		shown += 1
		var q: Dictionary = Prog.QUESTS[id]
		var t := _label(8, Color(1, 0.82, 0.45) if q.type == "main" else Color(0.75, 0.88, 1.0))
		t.text = ("◆ " if q.type == "main" else "◇ ") + G.L(q.title)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		t.custom_minimum_size = Vector2(190, 0)
		quest_box.add_child(t)
		var o := _label(7, Color(0.88, 0.86, 0.84))
		o.text = Prog.quest_text(id)
		o.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		o.custom_minimum_size = Vector2(190, 0)
		quest_box.add_child(o)

func toast(text: String, color := Color(1, 0.9, 0.6)) -> void:
	var l := _label(8, color)
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(400, 0)
	l.modulate.a = 0.0
	toast_box.add_child(l)
	while toast_box.get_child_count() > 4:
		toast_box.get_child(0).free()
	var long := text.length() > 80
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(6.0 if long else 3.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

func show_area(title: String, sub: String) -> void:
	area_title.text = title
	area_sub.text = sub
	for l in [area_title, area_sub]:
		var tw = l.create_tween()
		tw.tween_property(l, "modulate:a", 1.0, 0.8)
		tw.tween_interval(2.2)
		tw.tween_property(l, "modulate:a", 0.0, 1.2)

func big_message(text: String, color: Color, dur := 2.5, slow := false) -> void:
	big.text = text
	big.label_settings.font_color = color
	big.pivot_offset = Vector2(320, 24)
	big.scale = Vector2(1.15, 1.15) if not slow else Vector2(0.95, 0.95)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(big, "modulate:a", 1.0, 0.6 if slow else 0.3)
	tw.tween_property(big_band, "modulate:a", 1.0, 0.4)
	tw.tween_property(big, "scale", Vector2.ONE, dur).set_ease(Tween.EASE_OUT)
	var tw2 := create_tween()
	tw2.tween_interval(dur)
	tw2.tween_property(big, "modulate:a", 0.0, 0.8)
	tw2.parallel().tween_property(big_band, "modulate:a", 0.0, 0.8)

func subtitle(speaker: String, text: String, dur := 3.0) -> void:
	sub_label.text = speaker + ": " + text if speaker != "" else text
	var tw := sub_label.create_tween()
	tw.tween_property(sub_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(dur)
	tw.tween_property(sub_label, "modulate:a", 0.0, 0.5)

func show_boss(e: Enemy) -> void:
	_boss = e
	boss_name.text = G.T(e.cfg.get("title", "boss_carcelero"))
	boss_panel.visible = true
	boss_panel.modulate.a = 0.0
	create_tween().tween_property(boss_panel, "modulate:a", 1.0, 0.6)

func hide_boss() -> void:
	_boss = null
	boss_panel.visible = false

func letterbox(on: bool) -> void:
	var h := 34.0 if on else 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lb_top, "size:y", h, 0.6).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lb_bot, "position:y", 360.0 - h, 0.6).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lb_bot, "size:y", h, 0.6).set_trans(Tween.TRANS_CUBIC)

func title_card(title: String, sub_pair: Array) -> void:
	area_title.text = G.L(sub_pair)
	area_sub.text = title
	area_sub.label_settings.font_color = Color(1, 0.75, 0.6)
	for l in [area_title, area_sub]:
		var tw = l.create_tween()
		tw.tween_property(l, "modulate:a", 1.0, 0.5)
		tw.tween_interval(3.0)
		tw.tween_property(l, "modulate:a", 0.0, 1.0)
	var tw2 := create_tween()
	tw2.tween_interval(4.6)
	tw2.tween_callback(_reset_sub_color)

func _reset_sub_color() -> void:
	area_sub.label_settings.font_color = Color(1, 0.92, 0.8)

func fade_from_black(dur: float) -> void:
	fade_rect.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade_rect, "color:a", 0.0, dur)

func end_card(title: String, body: String) -> void:
	var c := ColorRect.new()
	c.color = Color(0.02, 0.01, 0.04, 0.0)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var t := _label(24, Color(1, 0.85, 0.5))
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 130)
	t.size = Vector2(640, 30)
	c.add_child(t)
	var b := _label(10, Color(0.9, 0.88, 0.85))
	b.text = body + "\n\n" + G.L(["Gracias por jugar a SERAPHALL.", "Thank you for playing SERAPHALL."])
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.position = Vector2(0, 170)
	b.size = Vector2(640, 60)
	c.add_child(b)
	var tw := create_tween()
	tw.tween_property(c, "color:a", 0.85, 1.5)
	tw.tween_interval(6.0)
	tw.tween_property(c, "modulate:a", 0.0, 1.5)
	tw.tween_callback(c.queue_free)

func _on_flash(color: Color, dur: float) -> void:
	flash_rect.color = color
	var tw := create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, dur)

# ====================================================================== controles dibujados
class StatBars extends Control:
	var hud: Node
	var _hp_trail := 1.0
	func _draw() -> void:
		var lp: Player = hud.world.local_player() if hud.world else null
		if lp == null:
			return
		var mhp := Prog.max_hp()
		var hp_r: float = clamp(lp.hp / mhp, 0.0, 1.0)
		_hp_trail = max(hp_r, lerp(_hp_trail, hp_r, 0.04))
		var w := 90.0 + mhp * 0.3
		_bar(Vector2(0, 0), Vector2(w, 7), hp_r, _hp_trail, Color(0.78, 0.12, 0.2), Color(1, 0.9, 0.8))
		var sw := 70.0 + Prog.max_stamina() * 0.25
		_bar(Vector2(0, 10), Vector2(sw, 4), clamp(lp.stamina / Prog.max_stamina(), 0.0, 1.0), 0.0, Color(0.55, 0.75, 0.35), Color.WHITE)
		var lw := 50.0 + Prog.max_light() * 0.4
		_bar(Vector2(0, 16), Vector2(lw, 4), clamp(lp.light / Prog.max_light(), 0.0, 1.0), 0.0, Color(0.45, 0.65, 1.0), Color.WHITE)
		var full := lp.wrath >= 100.0
		var wc := Color(1, 0.85, 0.35) if not full else Color(1, 0.95, 0.6).lerp(Color(1, 0.6, 0.3), 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01))
		_bar(Vector2(0, 22), Vector2(60, 3), lp.wrath / 100.0, 0.0, wc, Color.WHITE)
		# lágrimas
		var ic := Fx.tex("icon_flask")
		for i in Prog.flask_count():
			var a := 1.0 if i < lp.flasks else 0.25
			draw_texture(ic, Vector2(i * 11, 28), Color(1, 1, 1, a))
		# compañero
		var y := 46.0
		for p in hud.world.players_list():
			if p != lp:
				var r: float = p.hp_ratio()
				draw_string(ThemeDB.fallback_font, Vector2(0, y + 5), "P%d" % p.variant, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.95, 1))
				_bar(Vector2(14, y), Vector2(60, 4), r, 0.0, Color(0.3, 0.75, 0.75) if p.is_alive() else Color(0.5, 0.2, 0.2), Color.WHITE)
				y += 8.0
	func _bar(pos: Vector2, sz: Vector2, v: float, trail: float, col: Color, trail_col: Color) -> void:
		draw_rect(Rect2(pos - Vector2(1, 1), sz + Vector2(2, 2)), Color(0.05, 0.02, 0.07, 0.9))
		draw_rect(Rect2(pos, sz), Color(0.18, 0.14, 0.2))
		if trail > v:
			draw_rect(Rect2(pos, Vector2(sz.x * trail, sz.y)), trail_col)
		draw_rect(Rect2(pos, Vector2(sz.x * v, sz.y)), col)
		draw_rect(Rect2(pos, Vector2(sz.x * v, 1)), col.lightened(0.35))

class BossBar extends Control:
	var hud: Node
	var _trail := 1.0
	func _draw() -> void:
		var b: Enemy = hud._boss
		if b == null or not is_instance_valid(b):
			return
		var r: float = clamp(b.hp / b.max_hp, 0.0, 1.0)
		_trail = max(r, lerp(_trail, r, 0.03))
		draw_rect(Rect2(-1, -1, size.x + 2, 8), Color(0.05, 0.02, 0.07, 0.95))
		draw_rect(Rect2(0, 0, size.x, 6), Color(0.2, 0.1, 0.14))
		draw_rect(Rect2(0, 0, size.x * _trail, 6), Color(1, 0.85, 0.7))
		var c := Color(0.75, 0.1, 0.2) if b.phase == 1 else Color(0.95, 0.2, 0.15)
		draw_rect(Rect2(0, 0, size.x * r, 6), c)
		draw_rect(Rect2(0, 0, size.x * r, 1), c.lightened(0.4))
		var pr: float = clamp(b.poise / b.max_poise, 0.0, 1.0)
		draw_rect(Rect2(size.x * 0.5 * (1.0 - pr), 8, size.x * pr, 2), Color(1, 0.8, 0.35, 0.9))

class SpellSlot extends Control:
	var key := "Q"
	var icon: Texture2D
	var hud: Node
	func _draw() -> void:
		var lp: Player = hud.world.local_player() if hud.world else null
		var ok := true
		var fill := 1.0
		if lp:
			match key:
				"Q":
					ok = lp.light >= 15.0
				"E":
					ok = Prog.has_skill("l2") and lp.light >= 28.0
					if not Prog.has_skill("l2"):
						fill = 0.0
				"R":
					fill = lp.wrath / 100.0
					ok = lp.wrath >= 100.0
		draw_rect(Rect2(0, 0, 20, 20), Color(0.06, 0.03, 0.08, 0.85))
		draw_rect(Rect2(0, 20 - 20 * fill, 20, 20 * fill), Color(0.3, 0.25, 0.15, 0.6))
		draw_texture(icon, Vector2(2, 2), Color(1, 1, 1, 1.0 if ok else 0.35))
		draw_rect(Rect2(0, 0, 20, 20), Color(1, 0.85, 0.5, 0.8) if ok else Color(0.4, 0.35, 0.4), false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(1, 27), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.9, 0.9, 0.9))

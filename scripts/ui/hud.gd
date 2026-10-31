extends CanvasLayer
## HUD pixel art enérgico: medallón con anillo de Ira, barras líquidas que tiemblan, ranuras de
## habilidades que rebotan, contador de Ecos que salta, misiones, avisos, jefe y cinemáticas.

var world: Node
var root: Control
var status: StatusCluster
var skills: SkillBar
var ecos_box: EcosCounter
var quest_box: VBoxContainer
var boss_panel: BossPanel
var prompt: FloatingPrompt
var toast_box: VBoxContainer
var lb_top: ColorRect
var lb_bot: ColorRect
var flash_rect: ColorRect
var fade_rect: ColorRect
var big_layer: Control
var sub_label: Label
var progress: ProgressBar
var _boss: Enemy
var minimap: Minimap
var combo_ui: ComboCounter
var hurt_ui: HurtIndicator

func _ready() -> void:
	layer = 10
	root = Control.new()
	root.size = Vector2(640, 360)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	status = StatusCluster.new()
	status.hud = self
	status.position = Vector2(6, 6)
	root.add_child(status)
	skills = SkillBar.new()
	skills.hud = self
	skills.position = Vector2(8, 306)
	root.add_child(skills)
	ecos_box = EcosCounter.new()
	ecos_box.position = Vector2(520, 318)
	root.add_child(ecos_box)
	quest_box = VBoxContainer.new()
	quest_box.position = Vector2(448, 82)
	quest_box.custom_minimum_size = Vector2(186, 0)
	quest_box.add_theme_constant_override("separation", 2)
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(quest_box)
	minimap = Minimap.new()
	minimap.hud = self
	minimap.position = Vector2(544, 6)
	minimap.size = Vector2(90, 70)
	root.add_child(minimap)
	combo_ui = ComboCounter.new()
	combo_ui.position = Vector2(560, 196)
	root.add_child(combo_ui)
	hurt_ui = HurtIndicator.new()
	hurt_ui.size = Vector2(640, 360)
	root.add_child(hurt_ui)
	prompt = FloatingPrompt.new()
	prompt.hud = self
	root.add_child(prompt)
	progress = ProgressBar.new()
	progress.position = Vector2(280, 262)
	progress.size = Vector2(80, 6)
	progress.show_percentage = false
	progress.max_value = 1.0
	progress.visible = false
	var pf := StyleBoxFlat.new(); pf.bg_color = UIKit.GOLD
	var pb := StyleBoxFlat.new(); pb.bg_color = UIKit.INK; pb.border_color = UIKit.WHITE; pb.set_border_width_all(1)
	progress.add_theme_stylebox_override("fill", pf)
	progress.add_theme_stylebox_override("background", pb)
	root.add_child(progress)
	boss_panel = BossPanel.new()
	boss_panel.hud = self
	boss_panel.position = Vector2(140, 316)
	boss_panel.size = Vector2(360, 36)
	boss_panel.visible = false
	root.add_child(boss_panel)
	big_layer = Control.new()
	big_layer.size = Vector2(640, 360)
	big_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(big_layer)
	lb_top = ColorRect.new(); lb_top.color = Color.BLACK; lb_top.size = Vector2(640, 0); root.add_child(lb_top)
	lb_bot = ColorRect.new(); lb_bot.color = Color.BLACK; lb_bot.position = Vector2(0, 360); lb_bot.size = Vector2(640, 0); root.add_child(lb_bot)
	sub_label = UIKit.label("", 15, UIKit.WHITE)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.position = Vector2(40, 292)
	sub_label.size = Vector2(560, 16)
	sub_label.modulate.a = 0.0
	root.add_child(sub_label)
	toast_box = VBoxContainer.new()
	toast_box.position = Vector2(170, 84)
	toast_box.custom_minimum_size = Vector2(300, 0)
	toast_box.add_theme_constant_override("separation", 3)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_box)
	flash_rect = ColorRect.new()
	flash_rect.size = Vector2(640, 360)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash_rect)
	fade_rect = ColorRect.new()
	fade_rect.size = Vector2(640, 360)
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)
	G.flash_requested.connect(_on_flash)
	G.toast_requested.connect(toast)
	Prog.changed.connect(_refresh_quests)
	Prog.quest_updated.connect(_on_quest_updated)
	G.language_changed.connect(_refresh_quests)
	_refresh_quests()
	# entrada animada del HUD
	status.position.x = -120
	skills.position.y = 400
	ecos_box.position.x = 700
	minimap.position.y = -90
	var tw := create_tween().set_parallel(true)
	tw.tween_property(status, "position:x", 6.0, 0.6).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(skills, "position:y", 306.0, 0.6).set_delay(0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ecos_box, "position:x", 520.0, 0.6).set_delay(0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(minimap, "position:y", 6.0, 0.6).set_delay(0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func combo_hit(n := 1) -> void:
	combo_ui.hit(n)

func combo_break() -> void:
	combo_ui.reset()

func hurt_from(dir: Vector2) -> void:
	hurt_ui.add(dir)

func _on_quest_updated(_id: String) -> void:
	_refresh_quests()
	if quest_box.get_child_count() > 0:
		var c: Control = quest_box.get_child(0)
		c.pivot_offset = Vector2(186, 6)
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector2(1.15, 1.15), 0.06)
		tw.tween_property(c, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

var _beat_t := 0.0

func _process(delta: float) -> void:
	if _boss and (not is_instance_valid(_boss) or not _boss.is_alive()):
		hide_boss()
	# latido con poca vida (cada vez más rápido)
	var lp: Player = world.local_player() if world else null
	if lp and lp.is_alive() and lp.hp / Prog.max_hp() <= 0.25:
		_beat_t -= delta
		if _beat_t <= 0.0:
			var r: float = lp.hp / Prog.max_hp()
			_beat_t = 0.55 + r * 1.6
			Audio.sfx("heartbeat", -2.0, 0.0)
	else:
		_beat_t = 0.0

func set_progress(v: float, text: String) -> void:
	progress.visible = v >= 0.0 and text != ""
	if v >= 0.0:
		progress.value = v

# ====================================================================== misiones
func _refresh_quests() -> void:
	for c in quest_box.get_children():
		c.queue_free()
	var order := ["main1", "feathers", "husks", "map", "choir", "jailer_hunt"]
	var shown := 0
	for id in order:
		if not Prog.quest_active(id) or shown >= 3:
			continue
		shown += 1
		var q: Dictionary = Prog.QUESTS[id]
		var e := QuestEntry.new()
		e.title = G.L(q.title).to_upper()
		e.objective = Prog.quest_text(id)
		e.main = q.type == "main"
		if q.has("count"):
			e.progress = float(Prog.quests[id].progress) / float(q.count)
		e.custom_minimum_size = Vector2(186, 30)
		quest_box.add_child(e)

# ====================================================================== avisos
func toast(text: String, color := Color(1, 0.9, 0.6)) -> void:
	var t := ToastBand.new()
	t.text = text
	t.color = color
	t.custom_minimum_size = Vector2(300, 18)
	toast_box.add_child(t)
	while toast_box.get_child_count() > 4:
		toast_box.get_child(0).free()

func show_area(title: String, sub: String) -> void:
	for old in big_layer.get_children():
		if old is AreaTitle:
			old.queue_free()
	var a := AreaTitle.new()
	a.small = title
	a.big = sub
	a.size = Vector2(640, 80)
	a.position = Vector2(0, 104)
	big_layer.add_child(a)

func big_message(text: String, color: Color, dur := 2.5, slow := false) -> void:
	var b := BigMessage.new()
	b.text = text
	b.color = color
	b.duration = dur
	b.dramatic = slow
	b.size = Vector2(640, 360)
	big_layer.add_child(b)

func subtitle(speaker: String, text: String, dur := 3.0) -> void:
	sub_label.text = (speaker + ": " if speaker != "" else "") + text
	var tw := sub_label.create_tween()
	tw.tween_property(sub_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(dur)
	tw.tween_property(sub_label, "modulate:a", 0.0, 0.5)

func show_boss(e: Enemy) -> void:
	_boss = e
	boss_panel.boss = e
	boss_panel.title = G.T(e.cfg.get("title", "boss_carcelero"))
	boss_panel.visible = true
	boss_panel.intro = 0.0
	create_tween().tween_property(boss_panel, "intro", 1.0, 0.9).set_trans(Tween.TRANS_CUBIC)

func hide_boss() -> void:
	_boss = null
	boss_panel.visible = false

func letterbox(on: bool) -> void:
	var h := 38.0 if on else 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lb_top, "size:y", h, 0.6).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lb_bot, "position:y", 360.0 - h, 0.6).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lb_bot, "size:y", h, 0.6).set_trans(Tween.TRANS_CUBIC)
	var t2 := create_tween()
	for n in [status, skills, ecos_box, quest_box, toast_box, minimap, combo_ui]:
		t2.parallel().tween_property(n, "modulate:a", 0.0 if on else 1.0, 0.4)

func title_card(title: String, sub_pair: Array) -> void:
	show_area(G.L(sub_pair), title)

func fade_from_black(dur: float) -> void:
	fade_rect.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade_rect, "color:a", 0.0, dur)

func fade_to(alpha: float, dur: float) -> void:
	create_tween().tween_property(fade_rect, "color:a", alpha, dur)

func end_card(title: String, body: String) -> void:
	var c := ColorRect.new()
	c.color = Color(0.05, 0.02, 0.08, 0.0)
	c.size = Vector2(640, 360)
	root.add_child(c)
	var t := UIKit.pixel_text(title, 40, "logo", UIKit.GOLD)
	t.align = 1
	t.size = Vector2(640, 44)
	t.position = Vector2(0, 120)
	t.appear = 0.0
	t.extrude = 4
	t.extrude_color = UIKit.RED
	c.add_child(t)
	var b := UIKit.label(body + "\n\n" + G.L(["Gracias por jugar a SERAPHALL.", "Thank you for playing SERAPHALL."]), 15, UIKit.WHITE)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.position = Vector2(0, 176)
	b.size = Vector2(640, 60)
	b.modulate.a = 0.0
	c.add_child(b)
	var tw := create_tween()
	tw.tween_property(c, "color:a", 0.9, 1.2)
	tw.tween_property(t, "appear", float(title.length()) + 1.0, 1.0)
	tw.tween_property(b, "modulate:a", 1.0, 0.8)
	tw.tween_interval(6.0)
	tw.tween_property(c, "modulate:a", 0.0, 1.5)
	tw.tween_callback(c.queue_free)

## Secuencia de recuerdo (contemplar): versos que aparecen y se desvanecen. Se puede saltar.
func memory_sequence(title: String, lines: Array) -> void:
	var c := Control.new()
	c.size = Vector2(640, 360)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(c)
	var head := UIKit.label(title.to_upper(), 8, Color(0.75, 0.9, 1.0), "head", 4)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.position = Vector2(0, 196)
	head.size = Vector2(640, 12)
	head.modulate.a = 0.0
	c.add_child(head)
	c.create_tween().tween_property(head, "modulate:a", 1.0, 1.5)
	await get_tree().create_timer(1.6 if G.autotest == "" else 0.1).timeout
	var skipped := false
	for i in lines.size():
		if skipped:
			break
		var l := UIKit.label(lines[i], 15, Color(0.95, 0.95, 1.0), "body", 4)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector2(40, 216 + i * 18)
		l.size = Vector2(560, 18)
		l.modulate.a = 0.0
		c.add_child(l)
		var tw := l.create_tween().set_parallel(true)
		tw.tween_property(l, "modulate:a", 1.0, 1.6)
		tw.tween_property(l, "position:y", l.position.y - 4, 2.0).from(l.position.y + 4)
		var wait := 3.6 if G.autotest == "" else 0.1
		var waited := 0.0
		while waited < wait:
			await get_tree().process_frame
			waited += get_process_delta_time()
			if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("pause"):
				waited = wait
				skipped = true
	await get_tree().create_timer(2.0 if G.autotest == "" else 0.1).timeout
	var tw2 := c.create_tween()
	tw2.tween_property(c, "modulate:a", 0.0, 1.5)
	await tw2.finished
	c.queue_free()

func _on_flash(color: Color, dur: float) -> void:
	flash_rect.color = color
	var tw := create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, dur)

# ====================================================================== piezas dibujadas
class StatusCluster extends Control:
	## Medallón con anillo de Ira y filas de iconos animados (estilo Minecraft):
	## corazones de vida, llamas de aguante y cristales de Luz. Debajo, Lágrimas, efectos y plumas.
	var hud: Node
	var _t := 0.0
	var _wrath_full_t := 0.0
	var _hearts_tex: Texture2D
	var _flames_tex: Texture2D
	var _crys_tex: Texture2D
	# estado para las animaciones
	var _last := {"hp": -1, "st": -1, "li": -1}
	var _hurt_t := 0.0
	var _heal_t := 0.0
	var _regen_t := 0.0
	var _ignite := {}         # índice de llama -> tiempo del "pop"
	var _parts: Array = []    # [pos, vel, vida, color, gravedad, tamaño]
	var _jit := []
	var _jit_t := 0.0
	var _rows := {}           # posiciones calculadas de cada fila

	const HX := 54.0          # x de inicio de las filas
	const HEART_W := 10.0
	const FLAME_W := 9.0
	const CRYS_W := 9.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(240, 74)
		_hearts_tex = Fx.tex("hud_hearts")
		_flames_tex = Fx.tex("hud_flames")
		_crys_tex = Fx.tex("hud_crystals")

	# ------------------------------------------------------------ cálculo de unidades (medias)
	static func _count(maxv: float, lo: int, hi: int) -> int:
		return clampi(int(round(maxv / 10.0)), lo, hi)

	static func _halves(v: float, maxv: float, n: int) -> int:
		if v <= 0.0:
			return 0
		var u := int(round(v / maxv * n * 2.0))
		return clampi(max(u, 1), 0, n * 2)

	func _layout() -> void:
		var nh := clampi(int(ceil(Prog.max_hp() / 10.0)), 1, 20)
		var hrows := 1 if nh <= 10 else 2
		var y_flames := 3.0 + hrows * 10.0 + 2.0
		_rows = {"nh": nh, "hrows": hrows, "y_hearts": 3.0, "y_flames": y_flames, "y_crys": y_flames + 12.0,
			"nf": _count(Prog.max_stamina(), 6, 15), "nc": _count(Prog.max_light(), 4, 14), "y_flask": y_flames + 25.0}
		size.y = _rows.y_flask + 36.0

	func _heart_pos(i: int) -> Vector2:
		var row := i / 10
		return Vector2(HX + (i % 10) * HEART_W, _rows.y_hearts + row * 10.0)

	func _process(delta: float) -> void:
		_t += delta
		var lp: Player = hud.world.local_player() if hud.world else null
		if lp == null:
			return
		_layout()
		var nh: int = _rows.nh
		var hu := _halves(lp.hp, Prog.max_hp(), nh)
		var su := _halves(lp.stamina, Prog.max_stamina(), _rows.nf)
		var lu := _halves(lp.light, Prog.max_light(), _rows.nc)
		# vida: daño -> parpadeo y corazones que estallan; curación -> ola de regeneración
		if _last.hp >= 0:
			if hu < _last.hp:
				_hurt_t = 0.45
				for k in range(hu, _last.hp):
					var hp0 := _heart_pos(k / 2) + Vector2(5, 5)
					for q in 5:
						_parts.append([hp0, Vector2(randf_range(-50, 50), randf_range(-90, -30)), 0.6, Color(1, 0.2, 0.3) if q % 2 == 0 else Color(1, 0.75, 0.8), 260.0, 2.0])
			elif hu > _last.hp:
				_heal_t = 0.8
				for k in range(_last.hp, hu):
					var hp1 := _heart_pos(k / 2) + Vector2(5, 3)
					_parts.append([hp1, Vector2(randf_range(-10, 10), randf_range(-40, -20)), 0.7, Color(1, 0.9, 0.95), -20.0, 1.0])
		# aguante: humo al gastar, chispa al volver a prender
		if _last.st >= 0:
			if su < _last.st:
				for k2 in range(su, _last.st):
					var fp := Vector2(HX + (k2 / 2) * FLAME_W + 4, _rows.y_flames + 3)
					_parts.append([fp, Vector2(randf_range(-6, 6), randf_range(-30, -18)), 0.7, Color(0.55, 0.5, 0.55, 0.8), -10.0, 2.0])
					_parts.append([fp + Vector2(0, 4), Vector2(randf_range(-30, 30), randf_range(-50, -20)), 0.4, Color(1, 0.6, 0.2), 120.0, 1.0])
			elif su > _last.st:
				for k3 in range(_last.st, su):
					if k3 % 2 == 1:
						_ignite[k3 / 2] = 0.25
		# Luz: destellos al recuperarla
		if _last.li >= 0 and lu > _last.li:
			for k6 in range(_last.li, lu):
				var cp2 := Vector2(HX + (k6 / 2) * CRYS_W + 4, _rows.y_crys + 5)
				_parts.append([cp2, Vector2(randf_range(-8, 8), randf_range(-26, -12)), 0.6, Color(0.75, 1.0, 1.0), -10.0, 1.0])
		# Luz: esquirlas cian al gastar
		if _last.li >= 0 and lu < _last.li:
			for k4 in range(lu, _last.li):
				var cp := Vector2(HX + (k4 / 2) * CRYS_W + 4, _rows.y_crys + 5)
				for q2 in 4:
					_parts.append([cp, Vector2(randf_range(-60, 60), randf_range(-70, -10)), 0.5, Color(0.6, 0.95, 1.0), 200.0, 1.0 if q2 % 2 else 2.0])
		_last = {"hp": hu, "st": su, "li": lu}
		_hurt_t = max(0.0, _hurt_t - delta)
		_heal_t = max(0.0, _heal_t - delta)
		for k5 in _ignite.keys():
			_ignite[k5] -= delta
			if _ignite[k5] <= 0.0:
				_ignite.erase(k5)
		# temblor de corazones con poca vida (cambia cada pocos fotogramas)
		_jit_t -= delta
		if _jit_t <= 0.0:
			_jit_t = 0.07
			_jit.clear()
			for i in nh:
				_jit.append(randi_range(-1, 1))
		# partículas
		for pp in _parts:
			pp[1].y += pp[4] * delta
			pp[0] += pp[1] * delta
			pp[2] -= delta
		_parts = _parts.filter(func(pp): return pp[2] > 0.0)
		if lp.wrath >= 100.0:
			_wrath_full_t += delta
		else:
			_wrath_full_t = 0.0
		queue_redraw()

	# ------------------------------------------------------------ dibujo
	func _icon(tex: Texture2D, frame: int, w: int, h: int, pos: Vector2, mod := Color.WHITE) -> void:
		draw_texture_rect_region(tex, Rect2(pos.round(), Vector2(w, h)), Rect2(frame * w, 0, w, h), mod)

	func _draw() -> void:
		var lp: Player = hud.world.local_player() if hud.world else null
		if lp == null or _rows.is_empty():
			return
		var c := Vector2(24, 24)
		# anillo de Ira: bloques alrededor del medallón
		var n := 20
		var filled := int(lp.wrath / 100.0 * n)
		var full := lp.wrath >= 100.0
		for i in n:
			var a := -PI / 2.0 + TAU * i / n + (_t * 1.5 if full else 0.0)
			var rr := 25.0 + (sin(_t * 12.0 + i) * 1.5 if full else 0.0)
			var p := (c + Vector2(cos(a), sin(a)) * rr).round()
			var col := Color(0.2, 0.1, 0.25)
			if i < filled:
				col = UIKit.GOLD.lerp(UIKit.WHITE, float(i) / n * 0.6)
				if full:
					col = UIKit.GOLD.lerp(UIKit.RED, 0.5 + 0.5 * sin(_t * 10.0 + i * 0.6))
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), UIKit.INK)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), col)
		# medallón
		UIKit.frame(self, Rect2(c - Vector2(17, 17), Vector2(34, 34)), UIKit.RED if not full else UIKit.GOLD, Color(0.16, 0.06, 0.2), 4.0)
		var tex: Texture2D = lp.sprite.texture
		var bob := roundf(sin(_t * 3.0))
		draw_texture_rect_region(tex, Rect2(c + Vector2(-14, -16 + bob), Vector2(28, 26)), Rect2(9, 1, 14, 13))
		var lv := "LV%d" % Prog.level
		var f := UIKit.font("head")
		var tag := Rect2(c + Vector2(-17, 12), Vector2(f.get_string_size(lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 6, 10))
		draw_rect(tag.grow(1), UIKit.INK)
		draw_rect(tag, UIKit.RED)
		f.draw_string(get_canvas_item(), tag.position + Vector2(3, 8), lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		# ---------------------------------------------------- corazones
		var nh: int = _rows.nh
		var hu: int = _last.hp
		var ratio := lp.hp / Prog.max_hp()
		var low := ratio <= 0.25 and lp.is_alive()
		var blink := _hurt_t > 0.0 and int(_hurt_t * 16.0) % 2 == 0
		var golden := Prog.buffs.has("ointment")
		var cracked := Prog.is_desplumado()
		if _heal_t > 0.0:
			var hk := _heal_t / 0.8
			var gw2: float = min(nh, 10) * HEART_W + 5.0
			draw_rect(Rect2(Vector2(HX - 3, _rows.y_hearts - 3), Vector2(gw2, _rows.hrows * 10.0 + 5.0)), Color(1, 0.75, 0.8, 0.22 * hk))
			var sx: float = HX + (1.0 - hk) * gw2
			draw_rect(Rect2(Vector2(sx - 3, _rows.y_hearts - 2), Vector2(6, _rows.hrows * 10.0 + 3.0)), Color(1, 1, 1, 0.5 * hk))
		if low:
			var ga := 0.25 + 0.2 * sin(_t * 8.0)
			var gw: float = min(nh, 10) * HEART_W + 3.0
			draw_rect(Rect2(Vector2(HX - 2, _rows.y_hearts - 2), Vector2(gw, _rows.hrows * 10.0 + 3.0)), Color(1, 0.1, 0.2, ga * 0.35))
		for i in nh:
			var hp := _heart_pos(i)
			if low:
				hp.y += _jit[i] if i < _jit.size() else 0
			if _heal_t > 0.0:
				var wave := (0.8 - _heal_t) * 22.0 - i
				if wave > 0.0 and wave < 2.0:
					hp.y -= roundf(sin(wave / 2.0 * PI) * 2.0)
			var st := 2
			if hu >= (i + 1) * 2:
				st = 0
			elif hu == i * 2 + 1:
				st = 1
			var fr := st
			if blink:
				fr = 3 + st
			elif st < 2:
				if golden:
					fr = 6 + st
				elif cracked:
					fr = 8 + st
			_icon(_hearts_tex, fr, 11, 10, hp)
		# ---------------------------------------------------- llamas de aguante
		var nf: int = _rows.nf
		var su: int = _last.st
		var exhausted := lp.stamina <= 0.5
		for i in nf:
			var fp := Vector2(HX + i * FLAME_W, _rows.y_flames)
			var st2 := 2
			if su >= (i + 1) * 2:
				st2 = 0
			elif su == i * 2 + 1:
				st2 = 1
			var fr2 := 5
			if st2 == 0:
				fr2 = int(_t * 9.0 + i * 1.7) % 3
			elif st2 == 1:
				fr2 = 3 + int(_t * 7.0 + i) % 2
			elif exhausted:
				fp.x += randi_range(-1, 1)
			var mod := Color.WHITE
			if _ignite.has(i):
				var k: float = _ignite[i] / 0.25
				fp.y -= roundf(k * 2.0)
				mod = Color(1.0 + k, 1.0 + k, 1.0 + k)
			_icon(_flames_tex, fr2, 9, 11, fp, mod)
		# ---------------------------------------------------- cristales de Luz
		var nc: int = _rows.nc
		var lu: int = _last.li
		var lfull := lu >= nc * 2
		var sweep := fmod(_t, 2.6) * 10.0
		for i in nc:
			var cpos := Vector2(HX + i * CRYS_W, _rows.y_crys)
			var st3 := 2
			if lu >= (i + 1) * 2:
				st3 = 0
			elif lu == i * 2 + 1:
				st3 = 1
			var fr3 := st3
			if st3 == 0:
				var dd := sweep - i
				if dd >= 0.0 and dd < 3.0:
					fr3 = 3 + int(dd)
				if lfull:
					cpos.y -= roundf(maxf(0.0, sin(_t * 4.0 - i * 0.7)) * 1.0)
			_icon(_crys_tex, fr3, 9, 11, cpos)
		# partículas de los iconos
		for pp in _parts:
			var a2: float = clampf(pp[2] / 0.4, 0.0, 1.0)
			var col2: Color = pp[3]
			draw_rect(Rect2((pp[0] as Vector2).round(), Vector2(pp[5], pp[5])), Color(col2, col2.a * a2))
		# ---------------------------------------------------- Lágrimas y efectos
		var fy: float = _rows.y_flask
		var ic := Fx.tex("icon_flask")
		for i in Prog.flask_count():
			var on := i < lp.flasks
			var y := fy + (roundf(sin(_t * 4.0 + i) * 1.0) if on else 0.0)
			draw_texture(ic, Vector2(HX + i * 13, y), Color(1, 1, 1, 1.0 if on else 0.25))
		var bx := HX + Prog.flask_count() * 13 + 6
		for b in Prog.buffs:
			var bic := Fx.tex("icon_" + Prog.ITEMS[b].icon)
			draw_texture(bic, Vector2(bx, fy))
			var frac: float = Prog.buffs[b] / 30.0
			draw_rect(Rect2(Vector2(bx, fy + 17), Vector2(16, 2)), UIKit.INK)
			draw_rect(Rect2(Vector2(bx, fy + 17), Vector2(16 * frac, 2)), UIKit.GOLD)
			bx += 20
		# ---------------------------------------------------- plumas del ala
		var wc := Look.color_of(G.look, "wing")
		for i in Prog.WING_MAX:
			var have := i < Prog.wing_feathers
			var fp2 := Vector2(HX + 4 + i * 6, fy + 25)
			var fc := wc if have else Color(0.22, 0.14, 0.26)
			var leaf := PackedVector2Array([fp2 + Vector2(1, -5), fp2 + Vector2(3, -1), fp2 + Vector2(1, 3), fp2 + Vector2(-1, -1)])
			var big := PackedVector2Array([fp2 + Vector2(1, -7), fp2 + Vector2(4, -1), fp2 + Vector2(1, 5), fp2 + Vector2(-2, -1)])
			draw_colored_polygon(big, UIKit.INK)
			draw_colored_polygon(leaf, fc)
			if have:
				draw_line(fp2 + Vector2(1, 4), fp2 + Vector2(1, -4), fc.darkened(0.35), 1.0)
				draw_rect(Rect2(fp2 + Vector2(1, -5), Vector2(1, 1)), Color.WHITE)
		if Prog.is_desplumado():
			var dt := G.T("desplumado_mode")
			var dw := f.get_string_size(dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var dp := Vector2(HX + 2 + Prog.WING_MAX * 6 + 6, fy + 21)
			UIKit.slash_band(self, Rect2(dp - Vector2(4, 0), Vector2(dw + 10, 10)), UIKit.RED.lerp(UIKit.PINK, 0.5 + 0.5 * sin(_t * 6.0)), 3.0)
			f.draw_string_outline(get_canvas_item(), dp + Vector2(1, 8), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), dp + Vector2(1, 8), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)

class SkillBar extends Control:
	var hud: Node
	var _t := 0.0
	var _pop := {}
	var _was_ready := {}
	const SLOTS := [["Q", "spell1"], ["E", "spell2"], ["R", "wrath"], ["X", "item"], ["C", "heal"]]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(200, 50)

	func _process(delta: float) -> void:
		_t += delta
		for k in _pop.keys():
			_pop[k] = max(0.0, _pop[k] - delta * 3.0)
		queue_redraw()

	func _draw() -> void:
		var lp: Player = hud.world.local_player() if hud.world else null
		if lp == null:
			return
		var f := UIKit.font("head")
		# arma equipada
		var w := Prog.weapon_data()
		var up: int = Prog.weapons.get(Prog.equipped, 0)
		var wname := G.L(w.name).to_upper() + ("  +%d" % up if up > 0 else "")
		draw_texture(Fx.tex("weapon_" + w.sprite), Vector2(0, -16))
		var bf := UIKit.font("title")
		bf.draw_string_outline(get_canvas_item(), Vector2(34, -6), wname, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
		bf.draw_string(get_canvas_item(), Vector2(34, -6), wname, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.WHITE)
		var x := 0.0
		for s in SLOTS:
			var key: String = s[0]
			var locked := (key == "Q" and not Prog.ability("lance")) or (key == "E" and not Prog.ability("nova")) or (key == "R" and not Prog.ability("wrath"))
			var ready := true
			var fill := 1.0
			var icon: Texture2D
			var count := -1
			match key:
				"Q":
					icon = Fx.tex("icon_lance"); ready = lp.light >= 15.0; fill = clamp(lp.light / 15.0, 0.0, 1.0)
				"E":
					icon = Fx.tex("icon_nova")
					ready = lp.light >= 28.0; fill = clamp(lp.light / 28.0, 0.0, 1.0)
				"R":
					icon = Fx.tex("icon_luz"); ready = lp.wrath >= 100.0; fill = lp.wrath / 100.0
				"X":
					var qi := Prog.quick_item
					icon = Fx.tex("icon_" + Prog.ITEMS.get(qi, Prog.ITEMS.bomb).icon)
					count = Prog.item_count(qi)
					ready = count > 0
				"C":
					icon = Fx.tex("icon_flask"); count = lp.flasks; ready = lp.flasks > 0
			if locked:
				ready = false; fill = 1.0
			if ready and not _was_ready.get(key, true):
				_pop[key] = 1.0
			_was_ready[key] = ready
			var pop: float = _pop.get(key, 0.0)
			var sz := 22.0 + pop * 4.0
			var r := Rect2(Vector2(x + 11 - sz / 2, 11 - sz / 2), Vector2(sz, sz)).abs()
			r.position = r.position.round()
			UIKit.frame(self, r, (UIKit.GOLD if key == "R" and ready else (UIKit.RED if ready else Color(0.3, 0.2, 0.35))), Color(0.1, 0.04, 0.14), 3.0)
			if fill < 1.0:
				var fh := roundf((r.size.y - 4) * fill)
				draw_rect(Rect2(r.position + Vector2(2, r.size.y - 2 - fh), Vector2(r.size.x - 4, fh)), Color(0.35, 0.15, 0.3, 0.8))
			var ip := (r.get_center() - Vector2(8, 8)).round()
			if key == "R" and ready:
				ip.y += roundf(sin(_t * 10.0) * 1.0)
			if locked:
				# candado
				var lc := r.get_center().round()
				draw_arc(lc + Vector2(0, -2), 3.0, PI, TAU, 8, UIKit.INK, 3.0)
				draw_arc(lc + Vector2(0, -2), 3.0, PI, TAU, 8, Color(0.75, 0.7, 0.8), 1.0)
				draw_rect(Rect2(lc + Vector2(-5, -1), Vector2(10, 7)), UIKit.INK)
				draw_rect(Rect2(lc + Vector2(-4, 0), Vector2(8, 5)), Color(0.7, 0.62, 0.75))
				draw_rect(Rect2(lc + Vector2(-1, 1), Vector2(2, 2)), UIKit.INK)
			else:
				draw_texture(icon, ip, Color(1, 1, 1, 1.0 if ready else 0.35).lerp(Color(2, 2, 2, 1), pop))
			# tecla (la que el jugador haya configurado)
			var kl := G.key_label(s[1])
			if kl.length() > 3:
				kl = kl.substr(0, 3)
			var kw := f.get_string_size(kl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 4
			var kr := Rect2(r.position + Vector2(-3, -4), Vector2(max(9.0, kw), 9))
			draw_rect(kr.grow(1), UIKit.INK)
			draw_rect(kr, UIKit.WHITE if ready else Color(0.5, 0.45, 0.5))
			f.draw_string(get_canvas_item(), kr.position + Vector2(2, 8), kl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.INK)
			if count >= 0:
				var ct := str(count)
				var cp := r.end + Vector2(-7 - (6 if count > 9 else 0), -1)
				f.draw_string_outline(get_canvas_item(), cp, ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
				f.draw_string(get_canvas_item(), cp, ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
			x += 30.0

class EcosCounter extends Control:
	var _shown := 0.0
	var _bump := 0.0
	var _t := 0.0
	var _last := 0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(116, 36)
		_shown = Prog.ecos
		_last = Prog.ecos
	func _process(delta: float) -> void:
		_t += delta
		if Prog.ecos != _last:
			if Prog.ecos > _last:
				_bump = 1.0
			_last = Prog.ecos
		_shown = lerpf(_shown, float(Prog.ecos), clamp(delta * 7.0, 0.0, 1.0))
		if absf(_shown - Prog.ecos) < 1.0:
			_shown = Prog.ecos
		_bump = max(0.0, _bump - delta * 2.5)
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("head")
		var txt := str(int(round(_shown)))
		var fs := 16
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x := size.x - w
		var y := 16.0 - roundf(_bump * 4.0)
		var col := UIKit.CYAN.lerp(UIKit.WHITE, _bump)
		f.draw_string_outline(get_canvas_item(), Vector2(x, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(x, y + 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.CYAN_DARK)
		f.draw_string(get_canvas_item(), Vector2(x, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		# orbe que gira
		var sx := absf(cos(_t * 3.0)) * 0.8 + 0.2
		var ic := Fx.tex("icon_eco")
		draw_set_transform(Vector2(x - 12, 9), 0.0, Vector2(sx, 1.0))
		draw_texture(ic, Vector2(-8, -8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# plumas
		var ft := str(Prog.feathers)
		var fw := f.get_string_size(ft, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		f.draw_string_outline(get_canvas_item(), Vector2(size.x - fw, 31), ft, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(size.x - fw, 31), ft, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		draw_texture(Fx.tex("icon_feather"), Vector2(size.x - fw - 18, 19))

class QuestEntry extends Control:
	var title := ""
	var objective := ""
	var main := false
	var progress := -1.0
	var _t := 0.0
	var _in := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		_t += delta
		_in = min(1.0, _in + delta * 3.0)
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("head")
		var b := UIKit.font("title")
		var accent := UIKit.GOLD if main else UIKit.CYAN
		var slide := roundf((1.0 - _in) * 40.0)
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var x := size.x - tw + slide
		UIKit.slash_band(self, Rect2(Vector2(x - 8, 0), Vector2(tw + 12, 11)), Color(0, 0, 0, 0.55), 4.0)
		draw_rect(Rect2(Vector2(size.x - 2 + slide, 0), Vector2(2, 11)), accent)
		f.draw_string_outline(get_canvas_item(), Vector2(x - 3, 9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(x - 3, 9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, accent)
		var ow := b.get_string_size(objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var ox := size.x - ow - 3 + slide
		b.draw_string_outline(get_canvas_item(), Vector2(ox, 21), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
		b.draw_string(get_canvas_item(), Vector2(ox, 21), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.WHITE)
		if progress >= 0.0:
			var pw := 60.0
			var pr := Rect2(Vector2(size.x - pw - 3 + slide, 24), Vector2(pw, 3))
			draw_rect(pr.grow(1), UIKit.INK)
			draw_rect(Rect2(pr.position, Vector2(pw * progress, 3)), accent)

class ToastBand extends Control:
	var text := ""
	var color := Color.WHITE
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = Vector2(150, 9)
		scale = Vector2(0.2, 1.6)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_interval(3.4 if text.length() < 80 else 7.0)
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("title")
		var fs := 10
		var lines := text.length() > 64
		var tw := minf(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 420.0)
		var h := 14.0 if not lines else 26.0
		custom_minimum_size.y = h + 2
		var r := Rect2(Vector2(150 - tw / 2 - 10, 0), Vector2(tw + 20, h))
		UIKit.slash_band(self, Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.5), 5.0)
		UIKit.slash_band(self, r, Color(0.12, 0.05, 0.16, 0.95), 5.0)
		UIKit.slash_band(self, Rect2(r.position, Vector2(r.size.x, 2)), color, 1.0)
		var sx := fmod(_t * 120.0, r.size.x + 20.0) - 10.0
		draw_rect(Rect2(r.position + Vector2(sx, 0), Vector2(3, h)), Color(1, 1, 1, 0.12))
		f.draw_multiline_string(get_canvas_item(), r.position + Vector2(10, 10), text, HORIZONTAL_ALIGNMENT_CENTER, tw, fs, 2, color)

class AreaTitle extends Control:
	var small := ""
	var big := ""
	var _t := 0.0
	var _pt: UIKit.PixelText
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pt = UIKit.pixel_text(big.to_upper(), 30, "logo", UIKit.WHITE)
		_pt.align = 1
		_pt.size = Vector2(640, 32)
		_pt.position = Vector2(0, 16)
		_pt.appear = 0.0
		_pt.extrude = 3
		_pt.extrude_color = UIKit.RED
		add_child(_pt)
		var tw := create_tween()
		tw.tween_property(_pt, "appear", float(big.length()) + 1.0, 0.6)
		tw.tween_interval(2.4)
		tw.tween_property(self, "modulate:a", 0.0, 0.8)
		tw.tween_callback(queue_free)
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var g: float = clamp(_t * 2.0, 0.0, 1.0)
		var w := 170.0 * g
		UIKit.slash_band(self, Rect2(Vector2(320 - w, 52), Vector2(w * 2, 4)), UIKit.RED, 3.0)
		if small != "":
			var f := UIKit.font("head")
			var sw := f.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			f.draw_string_outline(get_canvas_item(), Vector2(320 - sw / 2, 10), small, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), Vector2(320 - sw / 2, 10), small, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.8, 0.5, g))

class BigMessage extends Control:
	var text := ""
	var color := Color.WHITE
	var duration := 2.5
	var dramatic := false
	var _t := 0.0
	var _pt: UIKit.PixelText
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pt = UIKit.pixel_text(text, 48, "logo", color)
		_pt.align = 1
		_pt.size = Vector2(640, 52)
		_pt.position = Vector2(0, 150)
		_pt.appear = 0.0
		_pt.extrude = 5
		_pt.extrude_color = UIKit.RED_DARK if dramatic else UIKit.RED
		_pt.outline = 8
		_pt.wave = 2.5
		add_child(_pt)
		var tw := create_tween()
		tw.tween_property(_pt, "appear", float(text.length()) + 1.0, 0.9 if dramatic else 0.45)
		tw.tween_callback(_impact)
		tw.tween_interval(duration)
		tw.tween_property(self, "modulate:a", 0.0, 0.8)
		tw.tween_callback(queue_free)
	func _impact() -> void:
		_pt.flash = 1.0
		_pt.shake = 3.0
		create_tween().tween_property(_pt, "shake", 0.0, 0.5)
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var g: float = clamp(_t * 3.0, 0.0, 1.0)
		var h := 56.0 * g
		draw_rect(Rect2(Vector2(0, 176 - h / 2), Vector2(640, h)), Color(0, 0, 0, 0.6))
		UIKit.slash_band(self, Rect2(Vector2(0, 176 - h / 2), Vector2(640 * g, 2)), color, 0.0)
		UIKit.slash_band(self, Rect2(Vector2(640 * (1.0 - g), 176 + h / 2 - 2), Vector2(640 * g, 2)), color, 0.0)

class BossPanel extends Control:
	var hud: Node
	var boss: Enemy
	var title := ""
	var intro := 1.0
	var _trail := 1.0
	var _last := -1.0
	var _shake := 0.0
	var _t := 0.0
	var bar: ColorRect
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar = ColorRect.new()
		bar.size = Vector2(340, 10)
		bar.position = Vector2(10, 16)
		var m := UIKit.mat("liquid_bar")
		m.set_shader_parameter("col_deep", Color(0.35, 0.0, 0.08))
		m.set_shader_parameter("col_bright", Color(1.0, 0.15, 0.25))
		m.set_shader_parameter("size", bar.size)
		m.set_shader_parameter("tip", 5.0)
		m.set_shader_parameter("flow_speed", 1.6)
		bar.material = m
		add_child(bar)
	func _process(delta: float) -> void:
		_t += delta
		if boss == null or not is_instance_valid(boss):
			return
		var r: float = clamp(boss.hp / boss.max_hp, 0.0, 1.0)
		if _last >= 0.0 and boss.hp < _last - 0.5:
			_shake = 0.2
		_last = boss.hp
		_shake = max(0.0, _shake - delta)
		_trail = max(r, lerpf(_trail, r, delta * 1.5))
		var m: ShaderMaterial = bar.material
		m.set_shader_parameter("fill", r * intro)
		m.set_shader_parameter("trail", _trail * intro)
		m.set_shader_parameter("pulse", 0.4 if boss.phase == 2 else 0.0)
		m.set_shader_parameter("col_bright", Color(1.0, 0.15, 0.25) if boss.phase == 1 else Color(1.0, 0.45, 0.1))
		bar.position = Vector2(10, 16) + (Vector2(randf_range(-2, 2), randf_range(-1, 1)) * (_shake / 0.2)).round()
		queue_redraw()
	func _draw() -> void:
		if boss == null or not is_instance_valid(boss):
			return
		var f := UIKit.font("head")
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var x := size.x / 2 - tw / 2
		UIKit.slash_band(self, Rect2(Vector2(x - 12, 2), Vector2(tw + 24, 12)), UIKit.RED_DARK, 5.0)
		f.draw_string_outline(get_canvas_item(), Vector2(x, 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(x, 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		var r := Rect2(bar.position - Vector2(2, 2), bar.size + Vector2(4, 4))
		draw_rect(r.grow(1), UIKit.INK)
		draw_rect(r, Color(1, 1, 1, 0.9), false, 1.0)
		# muesca de fase
		var nx := bar.position.x + bar.size.x * 0.5
		draw_rect(Rect2(Vector2(nx - 1, bar.position.y - 3), Vector2(2, bar.size.y + 6)), UIKit.GOLD)
		# alas a los lados
		UIKit.wing(self, Vector2(4, 20), -1.0, 14.0, Color(1, 1, 1, 0.9), 0.8 + 0.1 * sin(_t * 4.0))
		UIKit.wing(self, Vector2(size.x - 6, 20), 1.0, 14.0, Color(1, 1, 1, 0.9), 0.8 + 0.1 * sin(_t * 4.0))
		# rango del Arconte (rombos) y Ascensión
		var rk: int = Prog.BOSS_INFO.get(boss.type, {}).get("rank", 1)
		for i in rk:
			var dp := Vector2(x + tw + 20 + i * 9, 8)
			UIKit.diamond(self, dp, 4.0, UIKit.INK)
			UIKit.diamond(self, dp, 3.0, UIKit.GOLD)
		if boss.asc > 0:
			var at: String = G.T("ascension") + " " + ["I", "II", "III"][clampi(boss.asc - 1, 0, 2)]
			var aw := f.get_string_size(at, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			UIKit.slash_band(self, Rect2(Vector2(x - aw - 34, 2), Vector2(aw + 14, 12)), UIKit.PINK, 4.0)
			f.draw_string_outline(get_canvas_item(), Vector2(x - aw - 27, 12), at, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), Vector2(x - aw - 27, 12), at, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		if hud.world and (hud.world.diff().phase3 or boss.asc >= 1) and boss.type in ["seravel", "choir"]:
			var nx3 := bar.position.x + bar.size.x * (0.25 if boss.type == "seravel" else 0.2)
			draw_rect(Rect2(Vector2(nx3 - 1, bar.position.y - 3), Vector2(2, bar.size.y + 6)), UIKit.PINK)
		# postura
		var pr: float = clamp(boss.poise / boss.max_poise, 0.0, 1.0)
		var pw := bar.size.x * 0.6
		var pp := Vector2(size.x / 2 - pw / 2, bar.position.y + bar.size.y + 4)
		draw_rect(Rect2(pp - Vector2(1, 1), Vector2(pw + 2, 4)), UIKit.INK)
		draw_rect(Rect2(pp + Vector2(pw / 2 * (1.0 - pr), 0), Vector2(pw * pr, 2)), UIKit.GOLD.lerp(UIKit.WHITE, pr))

class FloatingPrompt extends Control:
	## Tecla [F] flotante sobre el objeto interactuable.
	var hud: Node
	var _t := 0.0
	var _a := 0.0
	var _text := ""
	var _pos := Vector2.ZERO
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(640, 360)
	func _process(delta: float) -> void:
		_t += delta
		var w: Node = hud.world
		var lp: Player = w.local_player() if w else null
		var it: Interactable = null
		if lp and lp.is_alive() and not w.is_menu_open() and not lp.cutscene:
			it = w.nearest_interactable(lp)
		var want := 0.0
		var sp: Enemy = w._spare_target if w and is_instance_valid(w._spare_target) else null
		if sp and lp and lp.is_alive():
			_text = G.T("spare") + " - " + G.T(sp.cfg.get("title", "boss_carcelero"))
			var vt0 := get_viewport().get_canvas_transform()
			_pos = (vt0 * (sp.global_position + Vector2(0, sp.cfg.off * 2.0 - 16.0))).round()
			want = 1.0
			it = null
		if it:
			var txt := it.prompt()
			if txt != "":
				_text = txt.replace("[F] ", "")
				var vt := get_viewport().get_canvas_transform()
				_pos = (vt * (it.global_position + Vector2(0, -34))).round()
				want = 1.0
		_a = move_toward(_a, want, delta * 6.0)
		queue_redraw()
	func _draw() -> void:
		if _a <= 0.01:
			return
		var f := UIKit.font("title")
		var hf := UIKit.font("head")
		var bob := roundf(sin(_t * 6.0) * 2.0)
		var tw := f.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var total := tw + 18
		var p := _pos + Vector2(-total / 2, bob)
		var s := 0.6 + 0.4 * _a
		draw_set_transform(_pos + Vector2(0, bob), 0.0, Vector2(s, s))
		var o := Vector2(-total / 2, 0)
		# tecla
		var kr := Rect2(o + Vector2(0, -6), Vector2(12, 12))
		draw_rect(Rect2(kr.position + Vector2(1, 2), kr.size), UIKit.INK)
		draw_rect(kr.grow(1), UIKit.INK)
		draw_rect(kr, UIKit.WHITE)
		draw_rect(Rect2(kr.position + Vector2(0, kr.size.y - 2), Vector2(kr.size.x, 2)), Color(0.7, 0.65, 0.75))
		hf.draw_string(get_canvas_item(), kr.position + Vector2(3, 9), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.INK)
		var lr := Rect2(o + Vector2(15, -6), Vector2(tw + 6, 12))
		draw_rect(lr, Color(0.08, 0.03, 0.1, 0.85 * _a))
		draw_rect(Rect2(lr.position, Vector2(2, lr.size.y)), UIKit.RED)
		f.draw_string_outline(get_canvas_item(), lr.position + Vector2(4, 9), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), lr.position + Vector2(4, 9), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, _a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Minimap extends Control:
	## Minimapa: silueta real del Estrato alrededor del jugador, iconos y zona actual.
	var hud: Node
	var t := 0.0
	const PX := 2.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var w = hud.world
		if w == null or w.grid.is_empty():
			return
		var view := Rect2(Vector2(2, 2), Vector2(size.x - 4, 52))
		UIKit.frame(self, Rect2(Vector2.ZERO, Vector2(size.x, 56)), UIKit.RED_DARK, Color(0.05, 0.02, 0.07, 0.85), 3.0, -1.0)
		var lp: Player = w.local_player()
		var center: Vector2 = lp.global_position / 16.0 if lp else Vector2(49, 86)
		var tiles := view.size / PX
		var src := Rect2(center - tiles / 2.0, tiles)
		var tex: ImageTexture = w.map_texture()
		draw_texture_rect_region(tex, view, src)
		for m in w.map_markers():
			var mp: Vector2 = view.position + (m[1] - src.position) * PX
			if not view.grow(-2).has_point(mp):
				if m[0] == "boss":
					var cl := Vector2(clamp(mp.x, view.position.x + 3, view.end.x - 3), clamp(mp.y, view.position.y + 3, view.end.y - 3))
					UIKit.diamond(self, cl, 2.0 + absf(sin(t * 4.0)), UIKit.RED)
				continue
			mp = mp.round()
			match m[0]:
				"brasa":
					draw_rect(Rect2(mp - Vector2(1, 2), Vector2(3, 4)), m[2])
				"npc":
					draw_rect(Rect2(mp - Vector2(1, 1), Vector2(3, 3)), UIKit.CYAN)
				"boss":
					UIKit.diamond(self, mp, 3.0, UIKit.RED)
				"chest":
					draw_rect(Rect2(mp - Vector2(1, 1), Vector2(3, 2)), UIKit.GOLD)
				"ecos":
					UIKit.diamond(self, mp, 2.0 + absf(sin(t * 5.0)), Color(0.5, 0.85, 1.0))
				"ally":
					draw_rect(Rect2(mp - Vector2(1, 1), Vector2(3, 3)), m[2])
		if lp:
			var c := (view.position + view.size / 2.0).round()
			var fd: Vector2 = lp.aim.normalized() if lp.aim.length() > 0.1 else Vector2.DOWN
			draw_colored_polygon(PackedVector2Array([c + fd * 5.0, c + fd.orthogonal() * 2.5, c - fd.orthogonal() * 2.5]), UIKit.WHITE)
			draw_rect(Rect2(c - Vector2(1, 1), Vector2(3, 3)), UIKit.PINK if int(t * 3.0) % 2 == 0 else UIKit.WHITE)
		# zona y dificultad
		var f := UIKit.font("title")
		var a: String = w.current_area()
		var nm := G.T(a).to_upper() if a != "" else ""
		var fs := 10
		while fs > 6 and f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - 2:
			fs -= 1
		var tw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var ac: Color = w.AREA_COLORS.get(a, UIKit.WHITE)
		f.draw_string_outline(get_canvas_item(), Vector2(size.x - tw - 1, 66), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(size.x - tw - 1, 66), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ac)
		var d: Dictionary = w.diff()
		for i in int(d.skulls):
			var sp := view.position + Vector2(5 + i * 6, 5)
			draw_rect(Rect2(sp - Vector2(3, 3), Vector2(5, 5)), UIKit.INK)
			draw_rect(Rect2(sp - Vector2(2, 2), Vector2(3, 3)), d.color)
		if w.event != "":
			var ec := Color(1, 0.55, 0.3) if w.event == "ash" else Color(0.7, 0.45, 1.0)
			draw_rect(Rect2(view.position + Vector2(2, view.size.y - 5), Vector2((view.size.x - 4) * clampf(w.event_t / 75.0, 0.0, 1.0), 3)), ec)
		draw_rect(Rect2(view.position + Vector2(view.size.x - 9, 3), Vector2(6, 1)), Color(1, 1, 1, 0.5))
		f.draw_string_outline(get_canvas_item(), view.position + Vector2(view.size.x - 10, 12), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), view.position + Vector2(view.size.x - 10, 12), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.TEXT_DIM)

class ComboCounter extends Control:
	## Contador de golpes estilo arcade: número gordo que salta, rango y barra de tiempo.
	var count := 0
	var timer := 0.0
	var pop := 0.0
	var t := 0.0
	var best_flash := 0.0
	const KEEP := 2.4
	const RANKS := [[5, ["BIEN", "NICE"]], [12, ["FEROZ", "FIERCE"]], [25, ["BRUTAL", "BRUTAL"]], [45, ["SERÁFICO", "SERAPHIC"]], [80, ["ARCONTE", "ARCHON"]]]
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func hit(n: int) -> void:
		var old := _rank()
		count += n
		timer = KEEP
		pop = 1.0
		if _rank() != old and _rank() != "":
			best_flash = 1.0
			Audio.sfx("ui_ok", -6.0, 0.0)
	func reset() -> void:
		if count >= 5:
			best_flash = 0.0
		count = 0
		timer = 0.0
	func _rank() -> String:
		var r := ""
		for k in RANKS:
			if count >= k[0]:
				r = G.L(k[1])
		return r
	func _process(delta: float) -> void:
		t += delta
		timer = max(0.0, timer - delta)
		if timer <= 0.0:
			count = 0
		pop = max(0.0, pop - delta * 6.0)
		best_flash = max(0.0, best_flash - delta * 1.5)
		queue_redraw()
	func _draw() -> void:
		if count < 2:
			return
		var f := UIKit.font("logo")
		var txt := str(count)
		var fs := 34 + int(pop * 10.0)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := Vector2(64 - w, 30 - pop * 3.0).round()
		var col := UIKit.WHITE.lerp(UIKit.GOLD, clamp(count / 40.0, 0.0, 1.0))
		f.draw_string_outline(get_canvas_item(), p + Vector2(2, 3), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, UIKit.RED_DARK)
		f.draw_string_outline(get_canvas_item(), p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, UIKit.INK)
		f.draw_string(get_canvas_item(), p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.lerp(UIKit.RED, pop * 0.6))
		var h := UIKit.font("head")
		h.draw_string_outline(get_canvas_item(), Vector2(18, 42), G.T("combo_hits"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		h.draw_string(get_canvas_item(), Vector2(18, 42), G.T("combo_hits"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.PINK)
		# barra de tiempo
		var k := timer / KEEP
		draw_rect(Rect2(Vector2(10, 46), Vector2(56, 4)), UIKit.INK)
		draw_rect(Rect2(Vector2(11, 47), Vector2(54 * k, 2)), UIKit.RED if k < 0.3 and int(t * 10.0) % 2 == 0 else UIKit.PINK)
		var r := _rank()
		if r != "":
			var rw := h.get_string_size(r, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var rp := Vector2(66 - rw, 62 + roundf(sin(t * 6.0)))
			UIKit.slash_band(self, Rect2(rp - Vector2(6, 10), Vector2(rw + 12, 13)), Color(UIKit.RED, 0.9).lerp(UIKit.GOLD, best_flash), 4.0)
			h.draw_string_outline(get_canvas_item(), rp, r, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			h.draw_string(get_canvas_item(), rp, r, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)

class HurtIndicator extends Control:
	## Marca roja en el borde de la pantalla que señala de dónde viene el golpe.
	var marks := []
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func add(dir: Vector2) -> void:
		if dir.length() < 0.1:
			return
		marks.append([dir.normalized(), 1.0])
	func _process(delta: float) -> void:
		for m in marks:
			m[1] -= delta * 1.6
		marks = marks.filter(func(m): return m[1] > 0.0)
		queue_redraw()
	func _draw() -> void:
		var c := Vector2(320, 172)
		for m in marks:
			var d: Vector2 = m[0]
			var a: float = m[1]
			var p := c + Vector2(d.x * 150.0, d.y * 110.0)
			var o := d.orthogonal()
			for i in 3:
				var pp := p + d * (i * 7.0)
				draw_colored_polygon(PackedVector2Array([pp + d * 8.0, pp + o * (10.0 - i * 2.0), pp - o * (10.0 - i * 2.0)]), Color(1, 0.15, 0.2, a * (0.9 - i * 0.25)))

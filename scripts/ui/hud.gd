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
var pickups: PickupFeed

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
	boss_panel.position = Vector2(92, 250)
	boss_panel.size = Vector2(456, 64)
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
	sub_label.position = Vector2(40, 240)
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
	pickups = PickupFeed.new()
	pickups.position = Vector2(470, 196)
	pickups.size = Vector2(166, 100)
	root.add_child(pickups)
	G.pickup_requested.connect(pickups.add)
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
		e.qtype = q.type
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

func death_screen(feathers_before: int) -> void:
	var d := DeathScreen.new()
	d.size = Vector2(640, 360)
	d.feathers = feathers_before
	big_layer.add_child(d)

func subtitle(speaker: String, text: String, dur := 3.0, color := UIKit.WHITE) -> void:
	sub_label.text = (speaker + ": " if speaker != "" else "") + text
	sub_label.add_theme_color_override("font_color", color)
	var tw := sub_label.create_tween()
	tw.tween_property(sub_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(dur)
	tw.tween_property(sub_label, "modulate:a", 0.0, 0.5)

func show_boss(e: Enemy) -> void:
	if _boss == e and boss_panel.visible:
		return
	_boss = e
	boss_panel.setup(e)

func hide_boss() -> void:
	_boss = null
	boss_panel.outro()

var trial_banner: TrialBanner
func show_trial(title: String, wave: int, total: int) -> void:
	if trial_banner == null:
		trial_banner = TrialBanner.new()
		trial_banner.size = Vector2(640, 30)
		root.add_child(trial_banner)
		root.move_child(trial_banner, boss_panel.get_index())
	trial_banner.title = title
	trial_banner.wave = wave
	trial_banner.total = total
	trial_banner._hide = false
	trial_banner.visible = true

func hide_trial() -> void:
	if trial_banner:
		trial_banner._hide = true

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
	# resumen del estrato: cinco cifras en fichas
	var echoes := 0
	for k in Lore.GHOST_ECHOES.keys():
		if Prog.flags.get("echo_" + k, false):
			echoes += 1
	var stats := [
		[G.L(["TIEMPO", "TIME"]), "%d:%02d" % [int(Prog.playtime / 3600.0), int(Prog.playtime / 60.0) % 60]],
		[G.L(["CAÍDAS", "FALLS"]), str(Prog.deaths)],
		[G.L(["PLUMAS", "FEATHERS"]), "%d/%d" % [Prog.wing_feathers, Prog.WING_MAX]],
		[G.L(["RECUERDOS", "MEMORIES"]), "%d/%d" % [Prog.memories.size(), Prog.MEMORIES.size()]],
		[G.L(["ECOS", "ECHOES"]), "%d/%d" % [echoes, Lore.GHOST_ECHOES.size()]],
		[G.L(["LOGROS", "FEATS"]), "%d/%d" % [Prog.achievements_count(), Prog.ACHIEVEMENTS.size()]],
	]
	var row := Control.new()
	row.position = Vector2(60, 262)
	row.size = Vector2(520, 44)
	row.modulate.a = 0.0
	c.add_child(row)
	for i in stats.size():
		var cell := Control.new()
		cell.position = Vector2(i * 88.0, 0)
		cell.size = Vector2(80, 40)
		row.add_child(cell)
		var bgc := ColorRect.new()
		bgc.color = Color(0.12, 0.05, 0.16, 0.9)
		bgc.size = Vector2(80, 40)
		cell.add_child(bgc)
		var top := ColorRect.new()
		top.color = UIKit.GOLD_DARK
		top.size = Vector2(80, 2)
		cell.add_child(top)
		var hl := UIKit.label(stats[i][0], 8, UIKit.GOLD, "head", 3)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hl.position = Vector2(0, 5)
		hl.size = Vector2(80, 10)
		cell.add_child(hl)
		var vl := UIKit.label(stats[i][1], 15, UIKit.WHITE)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.position = Vector2(0, 18)
		vl.size = Vector2(80, 18)
		cell.add_child(vl)
	var tw := create_tween()
	tw.tween_property(c, "color:a", 0.9, 1.2)
	tw.tween_property(t, "appear", float(title.length()) + 1.0, 1.0)
	tw.tween_property(b, "modulate:a", 1.0, 0.8)
	tw.tween_property(row, "modulate:a", 1.0, 0.6)
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
	# retrato animado
	var _bust: Texture2D
	var _bust_key := ""
	var _blink_t := 3.0
	var _expr_hold := 0.0
	var _expr := 0
	var _shake_p := 0.0

	const HX := 64.0          # x de inicio de las filas
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
		_update_expr(lp, delta)
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

	# ------------------------------------------------------------ retrato
	func _update_expr(lp: Player, delta: float) -> void:
		## 0 normal, 1 parpadeo, 2 dolor, 3 apurado (poca vida), 4 sonrisa (curación), 5 furia (Ira llena)
		_blink_t -= delta
		_expr_hold = max(0.0, _expr_hold - delta)
		_shake_p = max(0.0, _shake_p - delta)
		if _hurt_t > 0.3:
			_expr = 2
			_expr_hold = 0.45
			_shake_p = 0.3
			return
		if _expr_hold > 0.0:
			return
		if _heal_t > 0.2:
			_expr = 4
			_expr_hold = 0.6
			return
		if lp.wrath >= 100.0:
			_expr = 5
		elif lp.hp / Prog.max_hp() <= 0.25:
			_expr = 3
		else:
			_expr = 0
		if _blink_t <= 0.0:
			_expr = 1
			if _blink_t < -0.12:
				_blink_t = randf_range(2.5, 4.5)

	func _draw_portrait(lp: Player, c: Vector2, full: bool) -> void:
		var key := JSON.stringify(G.look) + str(Prog.wing_feathers)
		if key != _bust_key:
			_bust_key = key
			_bust = Look.bust_texture(G.look, Prog.wing_feathers)
		var ratio := lp.hp / Prog.max_hp()
		var jit := Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * (1.0 if _shake_p > 0.0 else 0.0)
		var ctr := c + jit
		var area_col: Color = hud.world.AREA_COLORS.get(hud.world.current_area(), Color(0.6, 0.5, 0.8)) if hud.world else Color(0.6, 0.5, 0.8)
		var rim := UIKit.RED if not full else UIKit.GOLD.lerp(UIKit.WHITE, 0.3 + 0.3 * sin(_t * 8.0))
		if _heal_t > 0.0:
			rim = rim.lerp(Color(1, 0.75, 0.85), _heal_t / 0.8)
		# octógono del marco con fondo del color de la zona (cielo del retrato)
		var pts := PackedVector2Array()
		var pts_in := PackedVector2Array()
		for k in 8:
			var a := TAU * k / 8.0 + PI / 8.0
			pts.append(ctr + Vector2(cos(a), sin(a)) * 25.0)
			pts_in.append(ctr + Vector2(cos(a), sin(a)) * 21.0)
		draw_colored_polygon(pts, UIKit.INK)
		var inner := PackedVector2Array()
		for k2 in 8:
			var a2 := TAU * k2 / 8.0 + PI / 8.0
			inner.append(ctr + Vector2(cos(a2), sin(a2)) * 23.0)
		draw_colored_polygon(inner, rim.darkened(0.25))
		draw_colored_polygon(pts_in, area_col.darkened(0.72))
		for k3 in 5:
			var band := ctr + Vector2(-20, -18 + k3 * 8)
			draw_rect(Rect2(band, Vector2(40, 4)), Color(area_col.darkened(0.55), 0.35 + 0.08 * k3))
		# el busto (recortado al octógono aproximando con un rectángulo interior)
		if _bust:
			var fr := _expr
			var bob := roundf(sin(_t * 2.2)) if _expr != 2 else 0.0
			var breathe := 1.0 + (0.03 * sin(_t * 9.0) if _expr == 3 else 0.0)
			var src := Rect2(fr * 40, 2, 40, 37)
			var dst := Rect2(ctr + Vector2(-19, -19 + bob) - Vector2(0, 1) * (breathe - 1.0) * 20.0, Vector2(38, 36.0 * breathe))
			var mod := Color.WHITE
			if _hurt_t > 0.0 and int(_hurt_t * 20.0) % 2 == 0:
				mod = Color(1.6, 0.5, 0.5)
			elif Prog.is_desplumado():
				mod = Color(0.82, 0.78, 0.9)
			draw_texture_rect_region(_bust, dst, src, mod)
		# viñeta roja que late con poca vida
		if ratio <= 0.25 and lp.is_alive():
			var pa := 0.18 + 0.14 * sin(_t * 7.0)
			draw_polyline(pts_in + PackedVector2Array([pts_in[0]]), Color(1, 0.1, 0.2, pa * 2.0), 3.0)
		# grietas en el marco si estás Desplumado
		if Prog.is_desplumado():
			draw_line(ctr + Vector2(14, -18), ctr + Vector2(9, -11), UIKit.INK, 1.0)
			draw_line(ctr + Vector2(9, -11), ctr + Vector2(12, -6), UIKit.INK, 1.0)
		# bisel brillante y remaches
		draw_polyline(pts + PackedVector2Array([pts[0]]), rim.lightened(0.25), 1.0)
		for k4 in 4:
			var a4 := TAU * k4 / 4.0 + PI / 4.0
			UIKit.diamond(self, ctr + Vector2(cos(a4), sin(a4)) * 24.0, 2.5, UIKit.INK)
			UIKit.diamond(self, ctr + Vector2(cos(a4), sin(a4)) * 24.0, 1.5, rim.lightened(0.4))
		# destello de curación que cruza el retrato
		if _heal_t > 0.0:
			var hk := 1.0 - _heal_t / 0.8
			var sx := ctr.x - 22.0 + hk * 44.0
			draw_line(Vector2(sx, ctr.y - 20), Vector2(sx - 8, ctr.y + 20), Color(1, 1, 1, 0.55 * (1.0 - hk)), 3.0)

	# ------------------------------------------------------------ dibujo
	func _icon(tex: Texture2D, frame: int, w: int, h: int, pos: Vector2, mod := Color.WHITE) -> void:
		draw_texture_rect_region(tex, Rect2(pos.round(), Vector2(w, h)), Rect2(frame * w, 0, w, h), mod)

	func _draw() -> void:
		var lp: Player = hud.world.local_player() if hud.world else null
		if lp == null or _rows.is_empty():
			return
		var c := Vector2(30, 30)
		# anillo de Ira: bloques alrededor del medallón
		var n := 24
		var filled := int(lp.wrath / 100.0 * n)
		var full := lp.wrath >= 100.0
		for i in n:
			var a := -PI / 2.0 + TAU * i / n + (_t * 1.5 if full else 0.0)
			var rr := 29.0 + (sin(_t * 12.0 + i) * 1.5 if full else 0.0)
			var p := (c + Vector2(cos(a), sin(a)) * rr).round()
			var col := Color(0.2, 0.1, 0.25)
			if i < filled:
				col = UIKit.GOLD.lerp(UIKit.WHITE, float(i) / n * 0.6)
				if full:
					col = UIKit.GOLD.lerp(UIKit.RED, 0.5 + 0.5 * sin(_t * 10.0 + i * 0.6))
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), UIKit.INK)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), col)
		# medallón con el retrato animado
		_draw_portrait(lp, c, full)
		var lv := "LV%d" % Prog.level
		var f := UIKit.font("head")
		var tag := Rect2(c + Vector2(-22, 16), Vector2(f.get_string_size(lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 6, 10))
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
	var qtype := "side"
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
		# icono del tipo de misión
		var ic := Vector2(x - 16, 5)
		match qtype:
			"main":
				UIKit.diamond(self, ic, 5.0, UIKit.INK)
				UIKit.diamond(self, ic, 4.0, UIKit.GOLD.lerp(UIKit.WHITE, 0.3 + 0.3 * sin(_t * 4.0)))
				UIKit.diamond(self, ic, 1.5, UIKit.INK)
			"bounty":
				draw_line(ic + Vector2(-4, -4), ic + Vector2(4, 4), UIKit.INK, 3.0)
				draw_line(ic + Vector2(4, -4), ic + Vector2(-4, 4), UIKit.INK, 3.0)
				draw_line(ic + Vector2(-4, -4), ic + Vector2(4, 4), UIKit.RED, 1.5)
				draw_line(ic + Vector2(4, -4), ic + Vector2(-4, 4), UIKit.RED, 1.5)
			_:
				draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -5), ic + Vector2(3, 0), ic + Vector2(0, 5), ic + Vector2(-3, 0)]), UIKit.INK)
				draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -4), ic + Vector2(2, 0), ic + Vector2(0, 4), ic + Vector2(-2, 0)]), UIKit.CYAN)
				draw_line(ic + Vector2(0, -4), ic + Vector2(0, 5), UIKit.INK, 1.0)
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
		var full := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tw := minf(full, 300.0)
		var nl := clampi(ceili(full / 290.0), 1, 3)
		var h := 14.0 if nl == 1 else 2.0 + 12.0 * nl
		custom_minimum_size.y = h + 2
		var r := Rect2(Vector2(150 - tw / 2 - 10, 0), Vector2(tw + 20, h))
		UIKit.slash_band(self, Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.5), 5.0)
		UIKit.slash_band(self, r, Color(0.12, 0.05, 0.16, 0.95), 5.0)
		UIKit.slash_band(self, Rect2(r.position, Vector2(r.size.x, 2)), color, 1.0)
		var sx := fmod(_t * 120.0, r.size.x + 20.0) - 10.0
		draw_rect(Rect2(r.position + Vector2(sx, 0), Vector2(3, h)), Color(1, 1, 1, 0.12))
		f.draw_multiline_string(get_canvas_item(), r.position + Vector2(10, 10), text, HORIZONTAL_ALIGNMENT_CENTER, tw, fs, nl, color)

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
	## Barra de jefe épica: marco propio de cada Arconte (hierro y cadenas, tubos de órgano, plumas de oro),
	## entrada animada, daño acumulado, muescas de fase que se rompen, postura y estallido al morir.
	var hud: Node
	var boss: Enemy
	var title := ""
	var sub := ""
	var bstyle := "carcelero"
	var intro := 1.0
	var _trail := 1.0
	var _last := -1.0
	var _shake := 0.0
	var _t := 0.0
	var _dmg_acc := 0.0
	var _dmg_t := 0.0
	var _phase := 1
	var _phase_t := 0.0
	var _out := -1.0
	var _parts: Array = []
	var _letters := 0.0
	var bar: ColorRect
	var over: Control
	var BW := 400.0
	var BX := 28.0
	const BY := 32.0
	const BH := 11.0
	const THEMES := {
		"carcelero": {"deep": Color(0.32, 0.05, 0.02), "bright": Color(1.0, 0.38, 0.1), "frame": Color(0.36, 0.33, 0.38), "accent": Color(1.0, 0.55, 0.2), "glow": Color(1, 0.45, 0.15)},
		"choir": {"deep": Color(0.16, 0.03, 0.28), "bright": Color(0.78, 0.42, 1.0), "frame": Color(0.36, 0.25, 0.5), "accent": Color(0.85, 0.7, 1.0), "glow": Color(0.7, 0.45, 1.0)},
		"seravel": {"deep": Color(0.4, 0.26, 0.04), "bright": Color(1.0, 0.86, 0.42), "frame": Color(0.85, 0.66, 0.25), "accent": Color(1.0, 0.95, 0.75), "glow": Color(1, 0.85, 0.5)},
		"custodio": {"deep": Color(0.3, 0.27, 0.22), "bright": Color(0.95, 0.88, 0.62), "frame": Color(0.72, 0.7, 0.68), "accent": Color(1.0, 0.85, 0.45), "glow": Color(1, 0.9, 0.6)},
	}
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar = ColorRect.new()
		var m := UIKit.mat("liquid_bar")
		m.set_shader_parameter("tip", 5.0)
		m.set_shader_parameter("flow_speed", 1.6)
		bar.material = m
		add_child(bar)
		over = Control.new()
		over.mouse_filter = Control.MOUSE_FILTER_IGNORE
		over.draw.connect(_draw_over)
		add_child(over)
	func setup(e: Enemy) -> void:
		boss = e
		bstyle = e.type if THEMES.has(e.type) else "carcelero"
		title = G.T(e.cfg.get("title", "boss_carcelero"))
		sub = G.T("sub_" + e.type) if G.TXT.has("sub_" + e.type) else ""
		var elite: bool = e.cfg.get("elite", false)
		BW = 300.0 if elite else 380.0
		BX = (size.x - BW) / 2.0
		bar.size = Vector2(BW, BH)
		bar.position = Vector2(BX, BY)
		over.size = size
		var th: Dictionary = THEMES[bstyle]
		var m: ShaderMaterial = bar.material
		m.set_shader_parameter("size", bar.size)
		m.set_shader_parameter("col_deep", th.deep)
		m.set_shader_parameter("col_bright", th.bright)
		intro = 0.0
		_letters = 0.0
		_out = -1.0
		_phase = e.phase
		_trail = 1.0
		_last = -1.0
		_dmg_acc = 0.0
		modulate.a = 1.0
		visible = true
		var tw := create_tween()
		tw.tween_property(self, "intro", 1.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		Audio.sfx("charge", -8.0, 0.0)
	func outro() -> void:
		if _out >= 0.0 or not visible:
			return
		_out = 0.0
		var r := Rect2(Vector2(BX, BY), Vector2(BW, BH))
		var th: Dictionary = THEMES[bstyle]
		for k in 46:
			var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
			_parts.append([p, Vector2(randf_range(-60, 60), randf_range(-90, -10)), randf_range(0.6, 1.3), th.bright if k % 3 else th.frame, 240.0, randf_range(1.0, 3.0)])
	func _process(delta: float) -> void:
		_t += delta
		for pp in _parts:
			pp[1].y += pp[4] * delta
			pp[0] += pp[1] * delta
			pp[2] -= delta
		_parts = _parts.filter(func(pp): return pp[2] > 0.0)
		if _out >= 0.0:
			_out += delta
			modulate.a = clampf(1.0 - _out / 1.1, 0.0, 1.0)
			bar.visible = false
			queue_redraw(); over.queue_redraw()
			if _out > 1.4:
				visible = false
				bar.visible = true
				_out = -1.0
				_parts.clear()
			return
		if boss == null or not is_instance_valid(boss):
			return
		_letters += delta * 22.0
		var r: float = clamp(boss.hp / boss.max_hp, 0.0, 1.0)
		if _last >= 0.0 and boss.hp < _last - 0.5:
			var d := _last - boss.hp
			_shake = 0.22
			_dmg_acc += d
			_dmg_t = 1.4
			var th: Dictionary = THEMES[bstyle]
			var px := BX + BW * r
			for k in clampi(int(d / 8.0) + 2, 2, 10):
				_parts.append([Vector2(px + randf_range(-2, 6), BY + randf() * BH), Vector2(randf_range(10, 70), randf_range(-70, -10)), randf_range(0.4, 0.8), th.bright.lightened(0.3), 220.0, randf_range(1.0, 2.0)])
		_last = boss.hp
		_dmg_t = max(0.0, _dmg_t - delta)
		if _dmg_t <= 0.0:
			_dmg_acc = 0.0
		_shake = max(0.0, _shake - delta)
		_trail = max(r, lerpf(_trail, r, delta * (0.8 if _dmg_t > 0.6 else 2.5)))
		if boss.phase != _phase:
			_phase = boss.phase
			_phase_t = 1.6
			var th2: Dictionary = THEMES[bstyle]
			for k2 in 30:
				_parts.append([Vector2(BX + randf() * BW, BY + BH / 2), Vector2(randf_range(-80, 80), randf_range(-100, -20)), randf_range(0.5, 1.0), th2.accent, 200.0, 2.0])
		_phase_t = max(0.0, _phase_t - delta)
		var th3: Dictionary = THEMES[bstyle]
		var bright: Color = th3.bright
		if bstyle == "seravel" and boss.phase == 2:
			bright = Color(1.0, 0.25, 0.32)
		elif bstyle == "seravel" and boss.phase >= 3:
			bright = Color(1.0, 0.97, 0.9)
		elif boss.phase >= 2:
			bright = bright.lerp(Color(1, 0.3, 0.2), 0.35)
		var m: ShaderMaterial = bar.material
		var fill_in: float = clamp((intro - 0.25) / 0.75, 0.0, 1.0)
		m.set_shader_parameter("fill", r * fill_in)
		m.set_shader_parameter("trail", _trail * fill_in)
		m.set_shader_parameter("pulse", (0.4 if boss.phase >= 2 else 0.0) + (0.5 + 0.5 * sin(_t * 9.0) if r < 0.25 else 0.0) * 0.4)
		m.set_shader_parameter("col_bright", bright.lerp(Color.WHITE, _phase_t / 1.6 * 0.7))
		bar.position = Vector2(BX, BY) + (Vector2(randf_range(-2, 2), randf_range(-1, 1)) * (_shake / 0.22)).round()
		queue_redraw()
		over.queue_redraw()

	func _txt(f: Font, pos: Vector2, text: String, fs: int, col: Color, outline := 3) -> void:
		f.draw_string_outline(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, UIKit.INK)
		f.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	func _draw() -> void:
		if boss == null or not is_instance_valid(boss):
			return
		var th: Dictionary = THEMES[bstyle]
		var fr: Color = th.frame
		var acc: Color = th.accent
		var k: float = clamp(intro / 0.35, 0.0, 1.0)
		var cx := BX + BW / 2.0
		var hw := (BW / 2.0 + 10.0) * k
		var outer := Rect2(Vector2(cx - hw, BY - 5), Vector2(hw * 2.0, BH + 10))
		# sombra y resplandor bajo la barra
		draw_rect(outer.grow(3), Color(0, 0, 0, 0.45))
		var glow: Color = th.glow
		draw_rect(outer.grow(1), Color(glow, 0.12 + 0.06 * sin(_t * 3.0)))
		# marco principal (bisel)
		draw_rect(outer, UIKit.INK)
		draw_rect(Rect2(outer.position + Vector2(1, 1), outer.size - Vector2(2, 2)), fr.darkened(0.45))
		draw_rect(Rect2(outer.position + Vector2(1, 1), Vector2(outer.size.x - 2, 1)), fr.lightened(0.35))
		draw_rect(Rect2(outer.position + Vector2(1, outer.size.y - 2), Vector2(outer.size.x - 2, 1)), fr.darkened(0.2))
		draw_rect(Rect2(Vector2(BX - 2, BY - 2), Vector2(BW + 4, BH + 4)), UIKit.INK)
		if k < 1.0:
			return
		match bstyle:
			"carcelero":
				# remaches y cadenas colgando de los extremos
				var x := BX + 8.0
				while x < BX + BW - 4:
					draw_rect(Rect2(Vector2(x, BY - 4), Vector2(2, 2)), fr.lightened(0.5))
					draw_rect(Rect2(Vector2(x, BY + BH + 2), Vector2(2, 2)), fr.lightened(0.2))
					x += 24.0
				for side in [-1.0, 1.0]:
					var ex = cx + side * (BW / 2.0 + 12.0)
					for i in 5:
						var sway := sin(_t * 2.0 + i * 0.7) * i * 0.6
						var cp := Vector2(ex + sway, BY - 2 + i * 5)
						draw_rect(Rect2(cp - Vector2(2, 2), Vector2(4, 5)), UIKit.INK)
						draw_rect(Rect2(cp - Vector2(1, 1), Vector2(2, 3)), fr.lightened(0.3) if i % 2 == 0 else fr)
					# grillete
					var gp := Vector2(ex + sin(_t * 2.0 + 3.5) * 3.0, BY + 24)
					draw_arc(gp, 4.0, 0, TAU, 12, UIKit.INK, 3.0)
					draw_arc(gp, 4.0, 0, TAU, 12, fr.lightened(0.2), 1.0)
				# llave en el centro superior
				var kc := Vector2(cx, BY - 7)
				draw_circle(kc, 3.5, UIKit.INK); draw_circle(kc, 2.5, acc); draw_circle(kc, 1.0, UIKit.INK)
			"choir":
				# tubos de órgano a los lados que vibran con la música
				for side2 in [-1.0, 1.0]:
					for i2 in 5:
						var h := 10.0 + i2 * 4.0 + sin(_t * 6.0 + i2) * (2.0 if boss.phase >= 2 else 1.0)
						var px = cx + side2 * (BW / 2.0 + 6.0 + i2 * 4.0)
						draw_rect(Rect2(Vector2(px - 2, BY + BH + 4 - h), Vector2(5, h)), UIKit.INK)
						draw_rect(Rect2(Vector2(px - 1, BY + BH + 5 - h), Vector2(3, h - 2)), fr.lightened(0.15))
						draw_rect(Rect2(Vector2(px - 1, BY + BH + 5 - h), Vector2(1, h - 2)), acc)
						draw_rect(Rect2(Vector2(px - 1, BY + BH - 2), Vector2(3, 1)), UIKit.INK)
				# notas que suben
				for i3 in 6:
					var ph := fmod(_t * 0.4 + i3 * 0.17, 1.0)
					var np := Vector2(BX + BW * fmod(i3 * 0.37 + 0.1, 1.0), BY - ph * 22.0)
					var a := 1.0 - ph
					draw_rect(Rect2(np, Vector2(2, 2)), Color(acc, a))
					draw_rect(Rect2(np + Vector2(1, -4), Vector2(1, 4)), Color(acc, a))
			"seravel":
				# plumas de oro a los lados y aureola sobre el nombre
				for side3 in [-1.0, 1.0]:
					var root := Vector2(cx + side3 * (BW / 2.0 + 8.0), BY + BH / 2.0)
					UIKit.wing(self, root, side3, 18.0, Color(acc, 0.95), 0.85 + 0.15 * sin(_t * 3.0))
				var hc := Vector2(cx, BY - 27)
				var hr := 14.0 + sin(_t * 2.0)
				draw_arc(hc, hr, 0, TAU, 32, Color(glow, 0.25), 4.0)
				draw_arc(hc, hr, 0, TAU, 32, Color(acc, 0.8) if boss.phase != 2 else Color(1, 0.3, 0.35, 0.9), 1.0)
			"custodio":
				for side4 in [-1.0, 1.0]:
					var sp := Vector2(cx + side4 * (BW / 2.0 + 10.0), BY + BH / 2.0)
					UIKit.diamond(self, sp, 6.0, UIKit.INK)
					UIKit.diamond(self, sp, 5.0, fr)
					UIKit.diamond(self, sp, 2.0, acc)
		# nombre (se escribe letra a letra) y epíteto
		var f := UIKit.font("head")
		var shown := title.substr(0, int(_letters))
		var fs := 16 if bstyle != "custodio" and title.length() <= 18 else 12
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tx := cx - tw / 2.0
		var ty := BY - (12.0 if bstyle != "seravel" else 14.0)
		UIKit.slash_band(self, Rect2(Vector2(tx - 16, ty - 13), Vector2(tw + 32, 15)), Color(0, 0, 0, 0.55), 6.0)
		_txt(f, Vector2(tx, ty), shown, fs, UIKit.WHITE, 4)
		if sub != "" and _letters > title.length() + 4:
			var fs2 := UIKit.font("body")
			var sw := fs2.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			_txt(fs2, Vector2(cx - sw / 2.0, BY + BH + 15), sub, 12, Color(acc, clampf((_letters - title.length() - 4) / 10.0, 0.0, 1.0)), 3)
		# rango (rombos) y Ascensión
		var rk: int = Prog.BOSS_INFO.get(boss.type, {}).get("rank", 0)
		for i in rk:
			var dp := Vector2(tx + tw + 12 + i * 9, ty - 5)
			UIKit.diamond(self, dp, 4.0, UIKit.INK)
			UIKit.diamond(self, dp, 3.0, UIKit.GOLD)
		if boss.asc > 0:
			var at: String = G.T("ascension") + " " + ["I", "II", "III"][clampi(boss.asc - 1, 0, 2)]
			var aw := f.get_string_size(at, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var ay := ty - 19.0 if bstyle != "seravel" else ty - 36.0
			UIKit.slash_band(self, Rect2(Vector2(cx - aw / 2.0 - 7, ay - 10), Vector2(aw + 14, 12)), UIKit.PINK, 4.0)
			_txt(f, Vector2(cx - aw / 2.0, ay), at, 8, UIKit.WHITE)

	func _draw_over() -> void:
		var ci := over
		for pp in _parts:
			ci.draw_rect(Rect2(pp[0].round(), Vector2(pp[5], pp[5])), Color(pp[3], clampf(pp[2] * 2.0, 0.0, 1.0)))
		if boss == null or not is_instance_valid(boss) or _out >= 0.0 or intro < 0.4:
			return
		var th: Dictionary = THEMES[bstyle]
		var r: float = clamp(boss.hp / boss.max_hp, 0.0, 1.0)
		# barrido de luz durante la entrada
		if intro < 1.0:
			var sx = BX + BW * clamp((intro - 0.25) / 0.75, 0.0, 1.0)
			ci.draw_rect(Rect2(Vector2(sx - 3, BY - 1), Vector2(6, BH + 2)), Color(1, 1, 1, 0.8))
		# muescas de fase: rombo entero si aún no se ha cruzado, roto si ya
		var notches := [0.5]
		if hud.world and (hud.world.diff().phase3 or boss.asc >= 1) and boss.type in ["seravel", "choir"]:
			notches.append(0.25 if boss.type == "seravel" else 0.2)
		for nt in notches:
			var nx: float = BX + BW * nt
			var crossed: bool = r < nt
			ci.draw_rect(Rect2(Vector2(nx - 1, BY - 3), Vector2(2, BH + 6)), UIKit.INK)
			var dc := Vector2(nx, BY - 5)
			UIKit.diamond(ci, dc, 4.0, UIKit.INK)
			if crossed:
				UIKit.diamond(ci, dc + Vector2(-1, 1), 2.0, Color(th.frame, 0.7))
				ci.draw_line(dc + Vector2(-2, -2), dc + Vector2(2, 2), UIKit.INK, 1.0)
			else:
				UIKit.diamond(ci, dc, 3.0, th.accent)
		# brillo de la punta del líquido
		var tipx := BX + BW * r
		if r > 0.0:
			ci.draw_rect(Rect2(Vector2(tipx - 1, BY), Vector2(1, BH)), Color(1, 1, 1, 0.55 + 0.3 * sin(_t * 12.0)))
		# número de daño acumulado
		if _dmg_acc > 0.5:
			var f := UIKit.font("num")
			var txt := "-%d" % int(round(_dmg_acc))
			var a := clampf(_dmg_t / 0.4, 0.0, 1.0)
			var pos := Vector2(minf(tipx + 4, BX + BW - 10), BY - 2 - (1.4 - _dmg_t) * 4.0)
			f.draw_string_outline(ci.get_canvas_item(), pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(UIKit.INK, a))
			f.draw_string(ci.get_canvas_item(), pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.95, 0.8, a))
		# postura
		var pr: float = clamp(boss.poise / boss.max_poise, 0.0, 1.0)
		var pw := BW * 0.5
		var pp2 := Vector2(BX + BW / 2.0 - pw / 2.0, BY + BH + 3)
		ci.draw_rect(Rect2(pp2 - Vector2(1, 1), Vector2(pw + 2, 4)), UIKit.INK)
		var pc: Color = UIKit.GOLD.lerp(UIKit.WHITE, pr)
		if boss.is_staggered():
			pc = Color(1, 1, 1) if int(_t * 12.0) % 2 == 0 else UIKit.GOLD
			pr = 1.0
		ci.draw_rect(Rect2(pp2 + Vector2(pw / 2.0 * (1.0 - pr), 0), Vector2(pw * pr, 2)), pc)
		# rótulo de cambio de fase
		if _phase_t > 0.0:
			var f2 := UIKit.font("head")
			var roman = ["I", "II", "III", "IV"][clampi(_phase - 1, 0, 3)]
			var pt := G.T("boss_phase") % roman
			var pw2 := f2.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var a2 := clampf(_phase_t / 0.5, 0.0, 1.0)
			var sc := 1.0 + (1.6 - _phase_t) * 0.1
			var ppos := Vector2(BX + BW / 2.0 - pw2 * sc / 2.0, BY + BH - 1)
			ci.draw_set_transform(ppos, 0.0, Vector2(sc, sc))
			f2.draw_string_outline(ci.get_canvas_item(), Vector2.ZERO, pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(UIKit.INK, a2))
			f2.draw_string(ci.get_canvas_item(), Vector2.ZERO, pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(th.accent, a2))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

class TrialBanner extends Control:
	## Rótulo de prueba arriba en el centro: nombre y oleadas (rombos que se llenan)
	var title := ""
	var wave := 0
	var total := 1
	var _t := 0.0
	var _in := 0.0
	var _hide := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		_t += delta
		_in = move_toward(_in, 0.0 if _hide else 1.0, delta * 3.0)
		if _hide and _in <= 0.0:
			visible = false
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("head")
		var lab := G.T("trial_label") + " · " + title
		var w := f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 24 + total * 10
		var y := -20.0 + 26.0 * _in
		var r := Rect2(Vector2(size.x / 2.0 - w / 2.0, y), Vector2(w, 16))
		UIKit.slash_band(self, r.grow(1), UIKit.INK, 6.0)
		UIKit.slash_band(self, r, Color(0.35, 0.08, 0.1, 0.92), 6.0)
		f.draw_string_outline(get_canvas_item(), r.position + Vector2(10, 12), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), r.position + Vector2(10, 12), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.8, 0.6))
		for i in total:
			var dp := Vector2(r.end.x - 10 - (total - 1 - i) * 10, r.position.y + 8)
			UIKit.diamond(self, dp, 4.0, UIKit.INK)
			if i < wave - 1:
				UIKit.diamond(self, dp, 3.0, UIKit.GOLD)
			elif i == wave - 1:
				UIKit.diamond(self, dp, 3.0, UIKit.RED.lerp(UIKit.GOLD, 0.5 + 0.5 * sin(_t * 8.0)))
			else:
				UIKit.diamond(self, dp, 2.0, Color(0.4, 0.3, 0.35))

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
		var ex: Enemy = w.exec_target if w and is_instance_valid(w.exec_target) else null
		if ex and lp and lp.is_alive() and want == 0.0:
			_text = G.T("execute_btn")
			var vt1 := get_viewport().get_canvas_transform()
			_pos = (vt1 * (ex.global_position + Vector2(0, ex.cfg.off * 2.0 - 12.0))).round()
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
	const PX := 3.0
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
		# fondo estrellado y el mapa detallado con su grosor
		for k in 14:
			var spos := view.position + Vector2(fposmod(k * 37.0 - src.position.x * 0.6, view.size.x), fposmod(k * 23.0 - src.position.y * 0.6, view.size.y))
			draw_rect(Rect2(spos.floor(), Vector2(1, 1)), Color(1, 1, 1, 0.25 + 0.2 * sin(t * 2.0 + k)))
		var tex: ImageTexture = w.map_texture_hd()
		var hsrc := Rect2(src.position * 3.0, src.size * 3.0)
		draw_texture_rect_region(tex, Rect2(view.position + Vector2(0, 2), view.size), hsrc, Color(0.12, 0.06, 0.14, 1.0))
		draw_texture_rect_region(tex, view, hsrc)
		for m in w.map_markers():
			var mp: Vector2 = view.position + (m[1] - src.position) * PX
			if not view.grow(-2).has_point(mp):
				if m[0] == "objective":
					# flecha dorada en el borde hacia el objetivo
					var cc := view.get_center()
					var dirv := (mp - cc).normalized()
					var edge := Vector2(clamp(mp.x, view.position.x + 4, view.end.x - 4), clamp(mp.y, view.position.y + 4, view.end.y - 4))
					draw_colored_polygon(PackedVector2Array([edge + dirv * 4.0, edge + dirv.orthogonal() * 3.0 - dirv * 2.0, edge - dirv.orthogonal() * 3.0 - dirv * 2.0]), UIKit.GOLD.lerp(UIKit.WHITE, 0.3 + 0.3 * sin(t * 6.0)))
					continue
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
				"objective":
					UIKit.diamond(self, mp, 3.0 + absf(sin(t * 4.0)), UIKit.GOLD)
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


class PickupFeed extends Control:
	## Columna de objetos recogidos: icono + nombre, entran desde la derecha y se desvanecen
	var items: Array = []   # [textura, texto, color, tiempo]
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func add(icon: String, text: String, color: Color) -> void:
		var tex: Texture2D = Fx.tex(icon) if ResourceLoader.exists("res://assets/sprites/%s.png" % icon) else null
		items.append([tex, text, color, 0.0])
		while items.size() > 5:
			items.pop_front()
		Audio.sfx("pickup", -10.0, 0.05)
	func _process(delta: float) -> void:
		for it in items:
			it[3] += delta
		items = items.filter(func(it): return it[3] < 3.2)
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("title")
		var y := size.y - 18.0
		for i in range(items.size() - 1, -1, -1):
			var it: Array = items[i]
			var t: float = it[3]
			var slide := (1.0 - clampf(t / 0.18, 0.0, 1.0)) * 60.0
			var a := clampf((3.2 - t) / 0.5, 0.0, 1.0)
			var tw := f.get_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var w := tw + 30.0
			var x := size.x - w + slide
			var col: Color = it[2]
			UIKit.slash_band(self, Rect2(Vector2(x - 4, y), Vector2(w + 6, 16)), Color(0, 0, 0, 0.6 * a), 5.0)
			draw_rect(Rect2(Vector2(size.x - 2 + slide, y), Vector2(2, 16)), Color(col, a))
			if it[0]:
				var pop := 1.0 + maxf(0.0, 0.4 - t) * 1.2
				var tex: Texture2D = it[0]
				var ts := Vector2(16, 16) * pop
				draw_texture_rect(tex, Rect2(Vector2(x + 8, y + 8) - ts / 2.0, ts), false, Color(1, 1, 1, a))
			f.draw_string_outline(get_canvas_item(), Vector2(x + 20, y + 12), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(UIKit.INK, a))
			f.draw_string(get_canvas_item(), Vector2(x + 20, y + 12), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col.lerp(Color.WHITE, 0.3), a))
			y -= 19.0


class DeathScreen extends Control:
	## Pantalla de caída: viñeta roja que late, grietas, "HAS CAÍDO" y tus plumas, una de ellas arrancada
	var feathers := 10
	var _t := 0.0
	var _pt: UIKit.PixelText
	var _line := ""
	const LINES := [
		["La Voz se ríe en algún lugar muy abajo.", "The Voice laughs somewhere far below."],
		["La Brasa te llama. Siempre te llama.", "The Ember calls you. It always does."],
		["Un recuerdo se te escapa entre los dedos.", "A memory slips through your fingers."],
		["Tus alas pesan un poco menos. Eso no es bueno.", "Your wings weigh a little less. That is not good."],
		["Aquí nadie muere del todo.", "Here, no one ever fully dies."],
	]
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_line = G.L(LINES[randi() % LINES.size()])
		_pt = UIKit.pixel_text(G.T("you_died"), 52, "logo", Color(0.9, 0.12, 0.15))
		_pt.align = 1
		_pt.size = Vector2(640, 56)
		_pt.position = Vector2(0, 128)
		_pt.appear = 0.0
		_pt.extrude = 6
		_pt.extrude_color = Color(0.25, 0.02, 0.05)
		_pt.outline = 8
		_pt.wave = 1.5
		add_child(_pt)
		var tw := create_tween()
		tw.tween_property(_pt, "appear", float(G.T("you_died").length()) + 1.0, 1.0)
		tw.tween_interval(1.9)
		tw.tween_property(self, "modulate:a", 0.0, 0.6)
		tw.tween_callback(queue_free)
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var a := clampf(_t / 0.6, 0.0, 1.0)
		# oscurecer y viñeta roja que late
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.0, 0.02, 0.45 * a))
		var pulse := 0.5 + 0.5 * sin(_t * 5.0)
		for i in 12:
			var k := 1.0 - i / 12.0
			var c := Color(0.55, 0.0, 0.05, (0.06 + 0.04 * pulse) * k * a)
			draw_rect(Rect2(i * 7, 0, 7, 360), c)
			draw_rect(Rect2(640 - (i + 1) * 7, 0, 7, 360), c)
			draw_rect(Rect2(0, i * 5, 640, 5), c)
			draw_rect(Rect2(0, 360 - (i + 1) * 5, 640, 5), c)
		# grietas que se extienden desde las esquinas
		var g := clampf(_t / 0.8, 0.0, 1.0)
		for corner in [Vector2(0, 0), Vector2(640, 0), Vector2(0, 360), Vector2(640, 360)]:
			var dir = (Vector2(320, 180) - corner).normalized()
			var p = corner
			for k2 in 6:
				var nxt = p + dir.rotated(sin(k2 * 2.3 + corner.x) * 0.6) * 22.0 * g
				draw_line(p, nxt, Color(0.02, 0.0, 0.02, 0.8 * a), 2.0)
				p = nxt
		# banda central
		var h := 70.0 * a
		draw_rect(Rect2(Vector2(0, 158 - h / 2.0), Vector2(640, h)), Color(0, 0, 0, 0.55))
		# las plumas que te quedan (la última, arrancada)
		var n := clampi(feathers, 0, 10)
		var wc := Look.color_of(G.look, "wing")
		var total_w := 10 * 14.0
		for i in 10:
			var fp := Vector2(320 - total_w / 2.0 + i * 14.0 + 7.0, 214.0)
			var have := i < n - 1
			var torn := i == n - 1
			var col := wc if have else Color(0.25, 0.12, 0.18)
			if torn:
				var k3 := clampf((_t - 0.9) / 1.2, 0.0, 1.0)
				fp += Vector2(k3 * 22.0, k3 * k3 * 50.0)
				col = Color(wc, 1.0 - k3)
			var rot := (_t * 4.0 if torn and _t > 0.9 else 0.0)
			draw_set_transform(fp, rot, Vector2.ONE)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(3, -1), Vector2(0, 7), Vector2(-3, -1)]), col)
			draw_line(Vector2(0, -7), Vector2(0, 9), Color(0.1, 0.05, 0.08, col.a), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var f := UIKit.font("title")
		var la := clampf((_t - 1.1) / 0.5, 0.0, 1.0)
		var w := f.get_string_size(_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		f.draw_string_outline(get_canvas_item(), Vector2(320 - w / 2.0, 244), _line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0, 0, 0, la))
		f.draw_string(get_canvas_item(), Vector2(320 - w / 2.0, 244), _line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.8, 0.8, la))

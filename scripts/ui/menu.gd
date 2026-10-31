extends CanvasLayer
## Menú de partida: Personaje, Árbol de habilidades, Armas (forja), Misiones, Opciones.

var world: Node
var root: Control
var content: Control
var tabs_box: HBoxContainer
var tab := "char"
var ctx := {}
var _sel_skill := ""
var _sel_weapon := ""
var _info: Label

const TABS := ["char", "skills", "weapons", "quests", "options"]
const TAB_KEYS := {"char": "tab_char", "skills": "tab_skills", "weapons": "tab_weapons", "quests": "tab_quests", "options": "tab_options"}

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.05, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var border := Panel.new()
	border.position = Vector2(12, 10)
	border.size = Vector2(616, 340)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.1, 0.8)
	sb.border_color = Color(0.7, 0.55, 0.3, 0.7)
	sb.set_border_width_all(1)
	border.add_theme_stylebox_override("panel", sb)
	root.add_child(border)
	tabs_box = HBoxContainer.new()
	tabs_box.position = Vector2(20, 16)
	tabs_box.add_theme_constant_override("separation", 4)
	root.add_child(tabs_box)
	content = Control.new()
	content.position = Vector2(20, 40)
	content.size = Vector2(600, 300)
	root.add_child(content)
	_apply_theme(root)
	Prog.changed.connect(_on_changed)
	G.language_changed.connect(_on_changed)

func _on_changed() -> void:
	if visible:
		_rebuild()

func _on_tab(t: String) -> void:
	tab = t
	Audio.sfx("ui_move")
	_rebuild()

func _on_buy(k: String) -> void:
	if Prog.buy_level(k):
		Audio.sfx("levelup")
		G.toast(G.T("level_up"), Color(1, 0.85, 0.4))
		var lp: Player = world.local_player()
		if lp:
			lp.hp = Prog.max_hp()

func _on_skill_sel(id: String) -> void:
	_sel_skill = id
	Audio.sfx("ui_move")
	_rebuild()

func _on_unlock() -> void:
	if Prog.unlock(_sel_skill):
		Audio.sfx("levelup")
		var lp: Player = world.local_player()
		if lp:
			lp.refresh_stats(false)

func _on_weapon_sel(id: String) -> void:
	_sel_weapon = id
	Audio.sfx("ui_move")
	_rebuild()

func _on_equip() -> void:
	Prog.equipped = _sel_weapon
	Prog.changed.emit()
	Audio.sfx("ui_ok")

func _on_upgrade() -> void:
	if Prog.upgrade_weapon(_sel_weapon):
		Audio.sfx("hit_heavy")
		Audio.sfx("levelup", -6.0)
		G.flash(Color(1, 0.6, 0.3, 0.3), 0.2)
	else:
		G.toast(G.T("not_enough"), Color(1, 0.5, 0.5))

func _on_music(v: float) -> void:
	G.music_volume = v
	Audio.refresh_volume()
	G.save_settings()

func _on_sfx(v: float) -> void:
	G.sfx_volume = v
	G.save_settings()

func _on_save_quit() -> void:
	Prog.save_game()
	close()
	world.main.back_to_title("")

func _apply_theme(c: Control) -> void:
	var th := Theme.new()
	th.default_font_size = 9
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.09, 0.15)
	normal.border_color = Color(0.45, 0.38, 0.3)
	normal.set_border_width_all(1)
	normal.content_margin_left = 6; normal.content_margin_right = 6; normal.content_margin_top = 2; normal.content_margin_bottom = 2
	var hover := normal.duplicate()
	hover.bg_color = Color(0.22, 0.16, 0.24)
	hover.border_color = Color(0.95, 0.75, 0.4)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.35, 0.22, 0.15)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.08, 0.07, 0.09)
	disabled.border_color = Color(0.25, 0.22, 0.25)
	th.set_stylebox("normal", "Button", normal)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("focus", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", disabled)
	th.set_color("font_color", "Button", Color(0.92, 0.88, 0.82))
	th.set_color("font_hover_color", "Button", Color(1, 0.9, 0.6))
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.42, 0.45))
	th.set_color("font_color", "Label", Color(0.92, 0.9, 0.86))
	c.theme = th

func toggle(t: String) -> void:
	if visible:
		close()
	else:
		open(t, {})

func open(t: String, p_ctx: Dictionary) -> void:
	tab = t
	ctx = p_ctx
	visible = true
	if not Net.is_online():
		get_tree().paused = true
	Audio.sfx("ui_ok", -6.0)
	_rebuild()

func close() -> void:
	visible = false
	ctx = {}
	get_tree().paused = false
	Audio.sfx("ui_move", -6.0)

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("menu") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()

func _rebuild() -> void:
	for c in tabs_box.get_children():
		c.queue_free()
	for t in TABS:
		var b := Button.new()
		b.text = G.T(TAB_KEYS[t])
		b.toggle_mode = true
		b.button_pressed = t == tab
		b.pressed.connect(_on_tab.bind(t))
		tabs_box.add_child(b)
	var cb := Button.new()
	cb.text = G.T("close")
	cb.pressed.connect(close)
	tabs_box.add_child(cb)
	for c in content.get_children():
		c.queue_free()
	match tab:
		"char": _build_char()
		"skills": _build_skills()
		"weapons": _build_weapons()
		"quests": _build_quests()
		"options": _build_options()

func _lbl(text: String, pos: Vector2, size := 9, color := Color(0.92, 0.9, 0.86), width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 2
	ls.outline_color = Color(0, 0, 0, 0.7)
	l.label_settings = ls
	if width > 0.0:
		l.size = Vector2(width, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)
	return l

func _btn(text: String, pos: Vector2, cb: Callable, enabled := true, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.disabled = not enabled
	if min_w > 0.0:
		b.custom_minimum_size = Vector2(min_w, 0)
	b.pressed.connect(cb)
	content.add_child(b)
	return b

# ------------------------------------------------------------------ personaje
func _build_char() -> void:
	var at_brasa: bool = ctx.get("brasa", false)
	_lbl("%s %d" % [G.T("level"), Prog.level], Vector2(0, 0), 14, Color(1, 0.85, 0.5))
	_lbl("%s: %d" % [G.T("ecos"), Prog.ecos], Vector2(0, 22), 9, Color(0.65, 0.88, 1))
	var cost := Prog.level_cost()
	_lbl(G.T("buy_level") % cost, Vector2(0, 36), 9, Color(0.9, 0.85, 0.7))
	if not at_brasa:
		_lbl(G.T("only_at_brasa"), Vector2(0, 50), 8, Color(0.7, 0.6, 0.55), 280)
	var y := 72.0
	for k in ["vigor", "aguante", "fuerza", "destreza", "fe", "arcano"]:
		_lbl(G.T(k), Vector2(0, y), 10)
		_lbl(str(Prog.attr[k]), Vector2(110, y), 10, Color(1, 0.9, 0.6))
		var can := at_brasa and Prog.ecos >= cost
		_btn("+", Vector2(140, y - 2), _on_buy.bind(k), can)
		_lbl(G.T(k + "_d"), Vector2(170, y + 1), 8, Color(0.7, 0.68, 0.66), 150)
		y += 26.0
	# estadísticas
	var x := 360.0
	var s := [
		["HP", "%d" % Prog.max_hp()], [G.T("aguante"), "%d" % Prog.max_stamina()], ["Luz / Light", "%d" % Prog.max_light()],
		[G.T("damage"), "%d" % Prog.weapon_damage()], ["Crit", "%d%%" % int(Prog.crit_chance() * 100)],
		[G.L(["Lágrimas", "Tear Flasks"]), str(Prog.flask_count())], [G.T("skill_points"), str(Prog.skill_points)],
		[G.T("feathers"), str(Prog.feathers)], [G.L(["Tiempo", "Playtime"]), "%d min" % int(Prog.playtime / 60.0)],
	]
	var yy := 0.0
	for row in s:
		_lbl(row[0], Vector2(x, yy), 9, Color(0.75, 0.72, 0.7))
		_lbl(row[1], Vector2(x + 140, yy), 9, Color(1, 0.92, 0.75))
		yy += 18.0
	var portrait := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = Fx.tex("player_p1" if (world.local_player() == null or world.local_player().variant == 1) else "player_p2")
	at.region = Rect2(0, 0, 24, 26)
	portrait.texture = at
	portrait.position = Vector2(470, 190)
	portrait.scale = Vector2(4, 4)
	content.add_child(portrait)

# ------------------------------------------------------------------ árbol de habilidades
func _build_skills() -> void:
	_lbl("%s: %d" % [G.T("skill_points"), Prog.skill_points], Vector2(0, 0), 11, Color(1, 0.85, 0.5))
	var lines := SkillLines.new()
	lines.menu = self
	lines.size = Vector2(600, 260)
	content.add_child(lines)
	var col_x := {"filo": 0.0, "ala": 128.0, "luz": 256.0, "ceniza": 384.0, "arconte": 520.0}
	for b in Prog.BRANCHES:
		var bd: Dictionary = Prog.BRANCHES[b]
		var hdr := _lbl(G.L(bd.name), Vector2(col_x[b] + 20, 18), 10, bd.color)
		hdr.size = Vector2(80, 0)
	for id in Prog.SKILLS:
		var s: Dictionary = Prog.SKILLS[id]
		var p := _skill_pos(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(24, 24)
		b.size = Vector2(24, 24)
		b.position = p - Vector2(12, 12)
		b.icon = Fx.tex("icon_" + Prog.BRANCHES[s.branch].icon)
		b.expand_icon = false
		var owned := Prog.has_skill(id)
		if owned:
			b.modulate = Color(1.2, 1.1, 0.9)
		elif not Prog.can_unlock(id):
			b.modulate = Color(0.55, 0.5, 0.55)
		b.pressed.connect(_on_skill_sel.bind(id))
		b.mouse_entered.connect(_show_skill_info.bind(id))
		content.add_child(b)
		if owned:
			var glow := TextureRect.new()
			glow.texture = Fx.tex("fx_soft")
			glow.modulate = Color(Prog.BRANCHES[s.branch].color, 0.5)
			glow.position = p - Vector2(16, 16)
			glow.size = Vector2(32, 32)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow.material = Fx.add_material()
			content.add_child(glow)
	_info = _lbl("", Vector2(0, 232), 9, Color(0.9, 0.88, 0.85), 440)
	if _sel_skill == "":
		_sel_skill = "f1"
	_show_skill_info(_sel_skill)
	var can := Prog.can_unlock(_sel_skill)
	var label := G.T("unlocked") if Prog.has_skill(_sel_skill) else G.T("unlock")
	_btn(label, Vector2(470, 240), _on_unlock, can, 110)

func _skill_pos(id: String) -> Vector2:
	var s: Dictionary = Prog.SKILLS[id]
	var col_x := {"filo": 0.0, "ala": 128.0, "luz": 256.0, "ceniza": 384.0, "arconte": 520.0}
	return Vector2(col_x[s.branch] + 20 + s.pos.x * 36, 52 + s.pos.y * 44)

func _show_skill_info(id: String) -> void:
	if _info == null or not is_instance_valid(_info):
		return
	var s: Dictionary = Prog.SKILLS[id]
	var extra := ""
	if not Prog.has_skill(id):
		extra = "   " + G.T("cost") % s.cost
		if s.has("archon") and not Prog.flags.get(s.archon + "_dead", false):
			extra += "   (" + G.T("locked_archon") + ")"
		else:
			for r in s.req:
				if not Prog.has_skill(r):
					extra += "   (" + G.T("locked_req") + ")"
					break
	_info.text = G.L(s.name) + extra + "\n" + G.L(s.desc)

# ------------------------------------------------------------------ armas / forja
func _build_weapons() -> void:
	var forge: bool = ctx.get("forge", false)
	if _sel_weapon == "" or not Prog.weapons.has(_sel_weapon):
		_sel_weapon = Prog.equipped
	var y := 0.0
	for id in Prog.WEAPONS:
		if not Prog.weapons.has(id):
			continue
		var w: Dictionary = Prog.WEAPONS[id]
		var b := Button.new()
		b.text = G.L(w.name) + ("  +%d" % Prog.weapons[id] if Prog.weapons[id] > 0 else "") + ("  ✦" if id == Prog.equipped else "")
		b.icon = Fx.tex("weapon_" + w.sprite)
		b.position = Vector2(0, y)
		b.custom_minimum_size = Vector2(220, 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_weapon_sel.bind(id))
		if id == _sel_weapon:
			b.modulate = Color(1.2, 1.1, 0.85)
		content.add_child(b)
		y += 26.0
	var w2: Dictionary = Prog.WEAPONS[_sel_weapon]
	var x := 250.0
	var big := TextureRect.new()
	big.texture = Fx.tex("weapon_" + w2.sprite)
	big.position = Vector2(x, 0)
	big.scale = Vector2(3, 3)
	content.add_child(big)
	_lbl(G.L(w2.name) + "  +%d" % Prog.weapons[_sel_weapon], Vector2(x, 42), 12, Color(1, 0.85, 0.5))
	_lbl(G.L(w2.desc), Vector2(x, 60), 9, Color(0.82, 0.8, 0.78), 340)
	var stats := [[G.T("damage"), "%d" % Prog.weapon_damage(_sel_weapon)], [G.T("speed"), "%.2f" % w2.speed], [G.T("reach"), "%d" % w2.range],
		[G.T("combo"), str(w2.combo)], [G.T("scaling"), "%s %s %s" % [_grade(w2.fue, "FUE"), _grade(w2.des, "DES"), _grade(w2.fe, "FE")]]]
	var yy := 92.0
	for s in stats:
		_lbl(s[0], Vector2(x, yy), 9, Color(0.75, 0.72, 0.7))
		_lbl(s[1], Vector2(x + 120, yy), 9, Color(1, 0.92, 0.75))
		yy += 16.0
	var eq := _sel_weapon == Prog.equipped
	_btn(G.T("equipped") if eq else G.T("equip"), Vector2(x, 180), _on_equip, not eq, 110)
	var lv: int = Prog.weapons[_sel_weapon]
	if lv >= 10:
		_lbl(G.T("max_level"), Vector2(x, 210), 9, Color(1, 0.85, 0.5))
	elif forge:
		var c := Prog.upgrade_cost(_sel_weapon)
		var txt := G.T("upgrade_cost") % [lv + 1, c[0], c[1]]
		if Prog.free_upgrades > 0:
			txt = G.L(["Mejora gratuita disponible (+%d)", "Free upgrade available (+%d)"]) % (lv + 1)
		_lbl(txt, Vector2(x, 210), 9, Color(0.9, 0.85, 0.7), 340)
		var can = Prog.free_upgrades > 0 or (Prog.ecos >= c[0] and Prog.feathers >= c[1])
		_btn(G.T("upgrade"), Vector2(x, 228), _on_upgrade, can, 110)
	else:
		_lbl(G.T("upgrade_at_forge"), Vector2(x, 210), 8, Color(0.7, 0.62, 0.55), 340)

func _grade(v: float, n: String) -> String:
	if v <= 0.0:
		return ""
	var g := "E"
	if v >= 0.9: g = "A"
	elif v >= 0.7: g = "B"
	elif v >= 0.45: g = "C"
	elif v >= 0.25: g = "D"
	return n + ":" + g

# ------------------------------------------------------------------ misiones
func _build_quests() -> void:
	_lbl(G.T("active_quests"), Vector2(0, 0), 11, Color(1, 0.85, 0.5))
	var y := 20.0
	for id in Prog.QUESTS:
		if not Prog.quest_active(id):
			continue
		var q: Dictionary = Prog.QUESTS[id]
		var col := Color(1, 0.82, 0.45) if q.type == "main" else (Color(1, 0.6, 0.5) if q.type == "bounty" else Color(0.75, 0.88, 1.0))
		_lbl(("◆ " if q.type == "main" else "◇ ") + G.L(q.title), Vector2(0, y), 10, col)
		_lbl("   " + Prog.quest_text(id), Vector2(0, y + 14), 9, Color(0.85, 0.83, 0.8), 360)
		var r: Dictionary = q.reward
		var rt := []
		if r.get("ecos", 0) > 0: rt.append("%d %s" % [r.ecos, G.T("ecos")])
		if r.get("sp", 0) > 0: rt.append("%d %s" % [r.sp, G.T("skill_points")])
		if r.has("weapon"): rt.append(G.L(Prog.WEAPONS[r.weapon].name))
		if r.has("flask"): rt.append(G.T("flask_up"))
		if r.has("feathers"): rt.append("%d %s" % [r.feathers, G.T("feathers")])
		if r.has("free_upgrade"): rt.append(G.T("upgrade") + " +1")
		_lbl("   " + G.T("reward") + ": " + ", ".join(rt), Vector2(0, y + 28), 8, Color(0.65, 0.8, 0.65), 380)
		y += 48.0
	_lbl(G.T("done_quests"), Vector2(400, 0), 11, Color(0.6, 0.85, 0.6))
	var y2 := 20.0
	for id in Prog.QUESTS:
		if Prog.quest_done(id):
			_lbl("✓ " + G.L(Prog.QUESTS[id].title), Vector2(400, y2), 9, Color(0.6, 0.75, 0.6))
			y2 += 16.0

# ------------------------------------------------------------------ opciones
func _build_options() -> void:
	_btn(G.T("resume"), Vector2(0, 0), close, true, 200)
	_btn(G.T("language"), Vector2(0, 30), G.toggle_language, true, 200)
	_lbl(G.T("music_vol"), Vector2(0, 66), 9)
	var ms := HSlider.new()
	ms.position = Vector2(120, 66)
	ms.size = Vector2(160, 12)
	ms.min_value = 0.0; ms.max_value = 1.0; ms.step = 0.05
	ms.value = G.music_volume
	ms.value_changed.connect(_on_music)
	content.add_child(ms)
	_lbl(G.T("sfx_vol"), Vector2(0, 88), 9)
	var ss := HSlider.new()
	ss.position = Vector2(120, 88)
	ss.size = Vector2(160, 12)
	ss.min_value = 0.0; ss.max_value = 1.0; ss.step = 0.05
	ss.value = G.sfx_volume
	ss.value_changed.connect(_on_sfx)
	content.add_child(ss)
	if Net.is_online() and Net.is_host:
		var code := Net.online_code()
		_lbl(G.T("code_online") + ": " + (code if code != "" else "—"), Vector2(0, 120), 11, Color(1, 0.85, 0.5))
		_lbl(G.T("code_lan") + ": " + Net.lan_code(), Vector2(0, 138), 11, Color(0.7, 0.9, 1))
	_lbl(G.T("controls"), Vector2(0, 170), 8, Color(0.75, 0.72, 0.7), 580)
	_btn(G.T("save_quit"), Vector2(0, 240), _on_save_quit, true, 200)

class SkillLines extends Control:
	var menu: Node
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for id in Prog.SKILLS:
			var s: Dictionary = Prog.SKILLS[id]
			for r in s.req:
				var a: Vector2 = menu._skill_pos(r)
				var b: Vector2 = menu._skill_pos(id)
				var on := Prog.has_skill(r) and Prog.has_skill(id)
				var col: Color = Prog.BRANCHES[s.branch].color if on else Color(0.35, 0.3, 0.35)
				draw_line(a, b, col, 2.0 if on else 1.0)

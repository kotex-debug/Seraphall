extends CanvasLayer
## Menú de partida (pixel art enérgico): Personaje, Habilidades (sigilo radial), Inventario,
## Armas (forja), Misiones, Mapa y Opciones. Fondo desenfocado y transiciones con rebote.

var world: Node
var root: Control
var backdrop: ColorRect
var deco: MenuDeco
var tab_bar: TabBar2
var content: Control
var tab := "char"
var ctx := {}
var _sel_skill := "f1"
var _sel_weapon := ""
var _sel_item := ""
var _inv_filter := "all"
var _info: Control
var _anim_dir := 1

const TABS := ["char", "skills", "inventory", "weapons", "quests", "map", "options"]
const TAB_KEYS := {"char": "tab_char", "skills": "tab_skills", "inventory": "tab_inventory", "weapons": "tab_weapons",
	"quests": "tab_quests", "map": "tab_map", "options": "tab_options"}

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	root = Control.new()
	root.size = Vector2(640, 360)
	root.theme = UIKit.button_theme(8)
	add_child(root)
	backdrop = ColorRect.new()
	backdrop.size = Vector2(640, 360)
	backdrop.material = UIKit.mat("menu_backdrop")
	root.add_child(backdrop)
	deco = MenuDeco.new()
	deco.size = Vector2(640, 360)
	root.add_child(deco)
	tab_bar = TabBar2.new()
	tab_bar.menu = self
	tab_bar.position = Vector2(0, 8)
	tab_bar.size = Vector2(640, 24)
	root.add_child(tab_bar)
	content = Control.new()
	content.position = Vector2(20, 44)
	content.size = Vector2(600, 296)
	root.add_child(content)
	var hint := UIKit.label(G.L(["[TAB] CERRAR   [Q/E] PESTAÑAS", "[TAB] CLOSE   [Q/E] TABS"]), 8, Color(0.75, 0.68, 0.8), "head", 3)
	hint.position = Vector2(14, 346)
	root.add_child(hint)
	Prog.changed.connect(_on_changed)
	G.language_changed.connect(_on_changed)

func get_tabs() -> Array:
	return TABS

func tab_key(t: String) -> String:
	return TAB_KEYS[t]

func sigil_c() -> Vector2:
	return SIGIL_C

func _on_changed() -> void:
	if visible:
		_rebuild(false)

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
	var m: ShaderMaterial = backdrop.material
	m.set_shader_parameter("amount", 0.0)
	var tw := create_tween()
	tw.tween_method(_set_blur, 0.0, 1.0, 0.25)
	root.scale = Vector2(1.04, 1.04)
	root.pivot_offset = Vector2(320, 180)
	root.modulate.a = 0.0
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(root, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(root, "modulate:a", 1.0, 0.15)
	_rebuild(true)

func _set_blur(v: float) -> void:
	(backdrop.material as ShaderMaterial).set_shader_parameter("amount", v)

func close() -> void:
	visible = false
	ctx = {}
	get_tree().paused = false
	Audio.sfx("ui_move", -6.0)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("spell1"):
		get_viewport().set_input_as_handled()
		switch_tab(TABS[(TABS.find(tab) - 1 + TABS.size()) % TABS.size()])
	elif event.is_action_pressed("spell2"):
		get_viewport().set_input_as_handled()
		switch_tab(TABS[(TABS.find(tab) + 1) % TABS.size()])

func switch_tab(t: String) -> void:
	if t == tab:
		return
	_anim_dir = 1 if TABS.find(t) > TABS.find(tab) else -1
	tab = t
	Audio.sfx("ui_move", -4.0)
	_rebuild(true)

func _rebuild(animate := true) -> void:
	tab_bar.queue_redraw()
	for c in content.get_children():
		c.queue_free()
	_info = null
	match tab:
		"char": _build_char()
		"skills": _build_skills()
		"inventory": _build_inventory()
		"weapons": _build_weapons()
		"quests": _build_quests()
		"map": _build_map()
		"options": _build_options()
	if animate:
		content.position.x = 20 + 40 * _anim_dir
		content.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(content, "position:x", 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(content, "modulate:a", 1.0, 0.15)

# ------------------------------------------------------------------ utilidades
func _lbl(text: String, pos: Vector2, size := 15, color := UIKit.WHITE, width := 0.0, kind := "body") -> Label:
	var l := UIKit.label(text, size, color, kind, 3 if size <= 10 else 4)
	l.position = pos
	content.add_child(l)
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
		l.size = Vector2(width, 0)
		l.set_deferred("size", Vector2(width, 0))
	return l

func _btn(text: String, pos: Vector2, cb: Callable, enabled := true, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.disabled = not enabled
	if min_w > 0.0:
		b.custom_minimum_size = Vector2(min_w, 18)
	b.pressed.connect(cb)
	content.add_child(b)
	UIKit.juicy(b)
	return b

func _panel(r: Rect2, col := UIKit.PURPLE) -> PanelBox:
	var p := PanelBox.new()
	p.position = r.position
	p.size = r.size
	p.col = col
	content.add_child(p)
	return p

# ------------------------------------------------------------------ personaje
func _build_char() -> void:
	var at_brasa: bool = ctx.get("brasa", false)
	_panel(Rect2(0, 0, 150, 296), UIKit.RED)
	var por := Portrait.new()
	por.position = Vector2(75, 112)
	por.variant = world.local_player().variant if world and world.local_player() else 1
	content.add_child(por)
	var name_pt := UIKit.pixel_text(G.L(["DESPLUMADO", "FEATHERLESS"]), 8, "head", UIKit.GOLD)
	name_pt.align = 1
	name_pt.size = Vector2(150, 10)
	name_pt.position = Vector2(0, 10)
	content.add_child(name_pt)
	var lvl := UIKit.pixel_text("%s %d" % [G.T("level").to_upper(), Prog.level], 24, "logo", UIKit.WHITE)
	lvl.align = 1
	lvl.size = Vector2(150, 26)
	lvl.position = Vector2(0, 196)
	lvl.extrude_color = UIKit.RED
	content.add_child(lvl)
	var cost := Prog.level_cost()
	_lbl("%s: %d" % [G.T("ecos"), Prog.ecos], Vector2(14, 232), 15, UIKit.CYAN)
	_lbl(G.T("buy_level") % cost, Vector2(14, 250), 10, UIKit.GOLD, 0.0, "title")
	if not at_brasa:
		_lbl(G.T("only_at_brasa"), Vector2(14, 264), 10, UIKit.PINK, 128, "title")
	# atributos
	_panel(Rect2(160, 0, 250, 296))
	var y := 12.0
	for k in ["vigor", "aguante", "fuerza", "destreza", "fe", "arcano"]:
		_lbl(G.T(k).to_upper(), Vector2(172, y), 8, UIKit.WHITE, 0.0, "head")
		var v: int = Prog.attr[k]
		var pips := PipBar.new()
		pips.value = v
		pips.position = Vector2(172, y + 14)
		content.add_child(pips)
		var vl := UIKit.pixel_text(str(v), 16, "head", UIKit.GOLD)
		vl.position = Vector2(330, y)
		content.add_child(vl)
		var can := at_brasa and Prog.ecos >= cost
		var b := _btn("+", Vector2(368, y), _on_buy.bind(k), can, 22)
		b.tooltip_text = G.T(k + "_d")
		_lbl(G.T(k + "_d"), Vector2(172, y + 22), 10, UIKit.TEXT_DIM, 0.0, "title")
		y += 46.0
	# estadísticas
	_panel(Rect2(420, 0, 180, 296))
	_lbl(G.L(["ESTADÍSTICAS", "STATS"]), Vector2(432, 10), 8, UIKit.GOLD, 0.0, "head")
	var s := [
		["heart", G.L(["Vida", "Health"]), "%d" % Prog.max_hp()], ["ala", G.T("aguante"), "%d" % Prog.max_stamina()],
		["luz", G.L(["Luz", "Light"]), "%d" % Prog.max_light()], ["filo", G.T("damage"), "%d" % Prog.weapon_damage()],
		["orbit", G.L(["Crítico", "Critical"]), "%d%%" % int(Prog.crit_chance() * 100)], ["flask", G.L(["Lágrimas", "Tears"]), str(Prog.flask_count())],
		["arconte", G.T("skill_points"), str(Prog.skill_points)], ["feather", G.T("feathers"), str(Prog.feathers)],
		["memory", G.T("memories"), "%d/%d" % [Prog.memories.size(), Prog.MEMORIES.size()]],
		["quest", G.L(["Tiempo", "Playtime"]), "%d min" % int(Prog.playtime / 60.0)],
	]
	var yy := 30.0
	for row in s:
		var ic := TextureRect.new()
		ic.texture = Fx.tex("icon_" + row[0])
		ic.position = Vector2(430, yy - 1)
		content.add_child(ic)
		_lbl(row[1], Vector2(450, yy - 2), 15, UIKit.TEXT_DIM)
		var vv := _lbl(row[2], Vector2(540, yy - 2), 15, UIKit.WHITE)
		vv.size = Vector2(50, 0)
		vv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		yy += 25.0

func _on_buy(k: String) -> void:
	if Prog.buy_level(k):
		Audio.sfx("levelup")
		G.toast(G.T("level_up"), UIKit.GOLD)
		var lp: Player = world.local_player()
		if lp:
			lp.hp = Prog.max_hp()

# ------------------------------------------------------------------ habilidades: sigilo radial
const SIGIL_C := Vector2(300, 140)
const DIRS := {"filo": Vector2(0, -1), "ala": Vector2(1, 0), "luz": Vector2(0, 1), "ceniza": Vector2(-1, 0)}

func skill_pos(id: String) -> Vector2:
	var s: Dictionary = Prog.SKILLS[id]
	if s.branch == "arconte":
		return SIGIL_C + Vector2(150, -96)
	var d: Vector2 = DIRS[s.branch]
	var tiers := [34.0, 62.0, 90.0, 118.0]
	var r: float = tiers[s.pos.y]
	var scale := Vector2(1.75, 1.0)
	var side := float(s.pos.x - 1)
	var perp := Vector2(-d.y, d.x) * side * 24.0
	return (SIGIL_C + d * r * scale + perp).round()

func _build_skills() -> void:
	var sig := SigilView.new()
	sig.menu = self
	sig.size = Vector2(600, 296)
	content.add_child(sig)
	var sp := UIKit.pixel_text("%s %d" % [G.L(["PUNTOS", "POINTS"]), Prog.skill_points], 16, "head", UIKit.GOLD)
	sp.position = Vector2(6, 6)
	content.add_child(sp)
	for b in ["filo", "ala", "luz", "ceniza", "arconte"]:
		var bd: Dictionary = Prog.BRANCHES[b]
		var pos: Vector2
		match b:
			"filo": pos = SIGIL_C + Vector2(-30, -146)
			"ala": pos = SIGIL_C + Vector2(226, -8)
			"luz": pos = SIGIL_C + Vector2(-30, 134)
			"ceniza": pos = SIGIL_C + Vector2(-292, -8)
			_: pos = SIGIL_C + Vector2(122, -124)
		var hl := UIKit.label(G.L(bd.name).to_upper(), 8, bd.color, "head", 3)
		hl.position = pos
		hl.size = Vector2(60, 10)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(hl)
	for id in Prog.SKILLS:
		var nb := SkillNode.new()
		nb.id = id
		nb.menu = self
		nb.position = skill_pos(id) - Vector2(11, 11)
		nb.size = Vector2(22, 22)
		nb.pressed.connect(_on_skill_sel.bind(id))
		nb.mouse_entered.connect(_on_skill_hover.bind(id))
		content.add_child(nb)
	_info = InfoCard.new()
	_info.position = Vector2(404, 196)
	_info.size = Vector2(196, 100)
	content.add_child(_info)
	_show_skill_info(_sel_skill)

func _on_skill_hover(id: String) -> void:
	_show_skill_info(id)

func _on_skill_sel(id: String) -> void:
	if _sel_skill == id and Prog.can_unlock(id):
		_on_unlock()
		return
	_sel_skill = id
	Audio.sfx("ui_move")
	_show_skill_info(id)

func _show_skill_info(id: String) -> void:
	if _info == null or not is_instance_valid(_info):
		return
	var s: Dictionary = Prog.SKILLS[id]
	var status := ""
	var col: Color = Prog.BRANCHES[s.branch].color
	if Prog.has_skill(id):
		status = G.T("unlocked").to_upper()
	elif s.has("archon") and not Prog.flags.get(s.archon + "_dead", false):
		status = G.T("locked_archon")
	else:
		var missing := false
		for r in s.req:
			if not Prog.has_skill(r):
				missing = true
		status = (G.T("locked_req") if missing else (G.T("cost") % s.cost) + (" - " + G.L(["clic para desbloquear", "click to unlock"]) if Prog.can_unlock(id) else ""))
	_info.set_content(G.L(s.name).to_upper(), G.L(s.desc), status, col, Fx.tex("icon_" + Prog.BRANCHES[s.branch].icon))

func _on_unlock() -> void:
	if Prog.unlock(_sel_skill):
		Audio.sfx("levelup")
		Audio.sfx("hit_heavy", -6.0)
		var lp: Player = world.local_player()
		if lp:
			lp.refresh_stats(false)
		var burst := UnlockBurst.new()
		burst.position = content.position + skill_pos(_sel_skill)
		burst.col = Prog.BRANCHES[Prog.SKILLS[_sel_skill].branch].color
		root.add_child(burst)

# ------------------------------------------------------------------ inventario
func _build_inventory() -> void:
	var filters := [["all", G.L(["TODO", "ALL"])], ["consumable", G.T("consumables").to_upper()], ["amulet", G.T("amulets").to_upper()],
		["key", G.T("key_items").to_upper()], ["material", G.T("materials").to_upper()]]
	var fx := 0.0
	for f in filters:
		var b := _btn(f[1], Vector2(fx, 0), _on_filter.bind(f[0]), true)
		if f[0] == _inv_filter:
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		fx += b.get_minimum_size().x + 6
	_panel(Rect2(0, 26, 360, 270))
	var ids := []
	for id in Prog.ITEMS:
		if Prog.item_count(id) > 0 and (_inv_filter == "all" or Prog.ITEMS[id].type == _inv_filter):
			ids.append(id)
	if _inv_filter in ["all", "material"] and Prog.feathers > 0:
		ids.append("_feathers")
	if _sel_item == "" or not (_sel_item in ids):
		_sel_item = ids[0] if ids.size() > 0 else ""
	for i in 30:
		var slot := ItemSlot.new()
		slot.position = Vector2(12 + (i % 6) * 56, 38 + (i / 6) * 50)
		slot.size = Vector2(48, 44)
		if i < ids.size():
			slot.item = ids[i]
			slot.selected = ids[i] == _sel_item
			slot.pressed.connect(_on_item_sel.bind(ids[i]))
			slot.delay = i * 0.03
		content.add_child(slot)
	# amuletos equipados
	_panel(Rect2(370, 26, 230, 62), UIKit.GOLD_DARK)
	_lbl(G.T("amulets").to_upper(), Vector2(380, 32), 8, UIKit.GOLD, 0.0, "head")
	for k in 2:
		var am: String = Prog.amulets_eq[k]
		var sl := ItemSlot.new()
		sl.position = Vector2(380 + k * 54, 44)
		sl.size = Vector2(40, 38)
		sl.item = am
		sl.equipped_slot = true
		content.add_child(sl)
	var buffs_txt := ""
	for b in Prog.buffs:
		buffs_txt += "%s %ds  " % [G.L(Prog.ITEMS[b].name), int(Prog.buffs[b])]
	_lbl(buffs_txt, Vector2(492, 50), 10, UIKit.GOLD, 100, "title")
	# detalle
	_panel(Rect2(370, 96, 230, 200), UIKit.RED)
	if _sel_item == "":
		_lbl(G.L(["Tu inventario está vacío.", "Your inventory is empty."]), Vector2(384, 110), 15, UIKit.TEXT_DIM, 200)
	else:
		_item_detail(_sel_item)
	# recuerdos
	var mx := 384.0
	_lbl(G.T("memories").to_upper() + " %d/%d" % [Prog.memories.size(), Prog.MEMORIES.size()], Vector2(380, 262), 8, Color(0.7, 0.9, 1.0), 0.0, "head")
	for m in Prog.MEMORIES:
		var ic := TextureRect.new()
		ic.texture = Fx.tex("icon_memory")
		ic.position = Vector2(mx, 274)
		ic.modulate = Color.WHITE if Prog.memories.has(m) else Color(0.2, 0.2, 0.3)
		ic.tooltip_text = G.L(Prog.MEMORIES[m].title) if Prog.memories.has(m) else "???"
		content.add_child(ic)
		mx += 20

func _item_detail(id: String) -> void:
	var it: Dictionary
	var count := 0
	if id == "_feathers":
		it = {"type": "material", "icon": "feather", "rarity": 1, "name": [G.T("feathers"), G.T("feathers")],
			"desc": ["Fragmentos de alas caídas. Brenna los usa para mejorar armas.", "Shards of fallen wings. Brenna uses them to upgrade weapons."]}
		count = Prog.feathers
	else:
		it = Prog.ITEMS[id]
		count = Prog.item_count(id)
	var big := BigIcon.new()
	big.tex = Fx.tex("icon_" + it.icon)
	big.position = Vector2(386, 108)
	big.col = Prog.RARITY_COLORS[it.rarity]
	content.add_child(big)
	var nm := UIKit.label(G.L(it.name).to_upper(), 8, Prog.RARITY_COLORS[it.rarity], "head", 3)
	nm.position = Vector2(446, 112)
	nm.size = Vector2(150, 0)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(nm)
	var types := {"consumable": G.T("consumables"), "amulet": G.T("amulets"), "key": G.T("key_items"), "material": G.T("materials")}
	_lbl(types[it.type] + "  x%d" % count, Vector2(446, 136), 10, UIKit.TEXT_DIM, 0.0, "title")
	_lbl(G.L(it.desc), Vector2(382, 160), 15, UIKit.WHITE, 206)
	match it.type:
		"consumable":
			if id != "phoenix":
				_btn(G.T("use"), Vector2(382, 232), _on_use_item.bind(id), true, 70)
				_btn(G.T("quick_slot"), Vector2(462, 232), _on_quick.bind(id), Prog.quick_item != id, 120)
		"amulet":
			if Prog.has_amulet(id):
				_btn(G.T("unequip"), Vector2(382, 232), _on_unequip.bind(id), true, 90)
			else:
				_btn(G.T("equip"), Vector2(382, 232), _on_equip_amulet.bind(id), true, 90)

func _on_filter(f: String) -> void:
	_inv_filter = f
	Audio.sfx("ui_move")
	_rebuild(false)

func _on_item_sel(id: String) -> void:
	_sel_item = id
	Audio.sfx("ui_move")
	_rebuild(false)

func _on_use_item(id: String) -> void:
	var lp: Player = world.local_player()
	if id == "bomb":
		Prog.quick_item = "bomb"
		G.toast(G.L(["Lanza la bomba con [X] en combate.", "Throw the bomb with [X] in combat."]), UIKit.GOLD)
		return
	if Prog.use_item(id):
		Audio.sfx("heal")
		if lp:
			Fx.ring(lp.global_position + Vector2(0, -8), 4.0, 36.0, UIKit.GOLD, 0.5, 4.0)

func _on_quick(id: String) -> void:
	Prog.quick_item = id
	Prog.changed.emit()
	Audio.sfx("ui_ok")

func _on_equip_amulet(id: String) -> void:
	Prog.equip_amulet(id)
	Audio.sfx("parry", -8.0)

func _on_unequip(id: String) -> void:
	Prog.unequip_amulet(id)
	Audio.sfx("ui_move")

# ------------------------------------------------------------------ armas / forja
func _build_weapons() -> void:
	var forge: bool = ctx.get("forge", false)
	if _sel_weapon == "" or not Prog.weapons.has(_sel_weapon):
		_sel_weapon = Prog.equipped
	_panel(Rect2(0, 0, 230, 296))
	var y := 10.0
	var i := 0
	for id in Prog.WEAPONS:
		if not Prog.weapons.has(id):
			continue
		var card := WeaponCard.new()
		card.id = id
		card.selected = id == _sel_weapon
		card.position = Vector2(8, y)
		card.size = Vector2(214, 40)
		card.delay = i * 0.05
		card.pressed.connect(_on_weapon_sel.bind(id))
		content.add_child(card)
		y += 46.0
		i += 1
	var w2: Dictionary = Prog.WEAPONS[_sel_weapon]
	_panel(Rect2(240, 0, 360, 296), UIKit.RED)
	var show := WeaponShowcase.new()
	show.tex = Fx.tex("weapon_" + w2.sprite)
	show.position = Vector2(420, 52)
	content.add_child(show)
	var lv: int = Prog.weapons[_sel_weapon]
	var nm := UIKit.pixel_text(G.L(w2.name).to_upper() + ("  +%d" % lv if lv > 0 else ""), 8, "head", UIKit.GOLD)
	nm.align = 1
	nm.size = Vector2(360, 10)
	nm.position = Vector2(240, 96)
	content.add_child(nm)
	var d := _lbl(G.L(w2.desc), Vector2(256, 110), 15, UIKit.TEXT_DIM, 330)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stats := [[G.T("damage"), Prog.weapon_damage(_sel_weapon), 60.0], [G.T("speed"), w2.speed, 1.6], [G.T("reach"), w2.range, 50.0], [G.L(["Postura", "Poise"]), w2.poise, 30.0]]
	var yy := 140.0
	for s in stats:
		_lbl(str(s[0]).to_upper(), Vector2(258, yy), 8, UIKit.WHITE, 0.0, "head")
		var sb := StatBar.new()
		sb.value = clamp(float(s[1]) / s[2], 0.0, 1.0)
		sb.position = Vector2(340, yy + 1)
		content.add_child(sb)
		_lbl(("%.1f" % s[1]) if s[1] is float and s[1] < 5.0 else str(int(s[1])), Vector2(552, yy - 4), 15, UIKit.GOLD)
		yy += 18.0
	_lbl("%s  %s %s %s" % [G.T("scaling").to_upper(), _grade(w2.fue, "FUE"), _grade(w2.des, "DES"), _grade(w2.fe, "FE")], Vector2(258, yy + 2), 10, UIKit.CYAN, 0.0, "title")
	var eq := _sel_weapon == Prog.equipped
	_btn(G.T("equipped") if eq else G.T("equip"), Vector2(258, 232), _on_equip, not eq, 100)
	if lv >= 10:
		_lbl(G.T("max_level"), Vector2(380, 236), 8, UIKit.GOLD, 0.0, "head")
	elif forge:
		var c := Prog.upgrade_cost(_sel_weapon)
		var txt := G.T("upgrade_cost") % [lv + 1, c[0], c[1]]
		if Prog.free_upgrades > 0:
			txt = G.L(["¡Mejora gratuita! (+%d)", "Free upgrade! (+%d)"]) % (lv + 1)
		_lbl(txt, Vector2(258, 258), 10, UIKit.GOLD, 330, "title")
		var can = Prog.free_upgrades > 0 or (Prog.ecos >= c[0] and Prog.feathers >= c[1])
		_btn(G.T("upgrade").to_upper(), Vector2(380, 232), _on_upgrade, can, 110)
	else:
		_lbl(G.T("upgrade_at_forge"), Vector2(258, 258), 10, UIKit.TEXT_DIM, 330, "title")

func _on_weapon_sel(id: String) -> void:
	_sel_weapon = id
	Audio.sfx("ui_move")
	_rebuild(false)

func _on_equip() -> void:
	Prog.equipped = _sel_weapon
	Prog.changed.emit()
	Audio.sfx("ui_ok")

func _on_upgrade() -> void:
	if Prog.upgrade_weapon(_sel_weapon):
		Audio.sfx("hit_heavy")
		Audio.sfx("levelup", -6.0)
		G.flash(Color(1, 0.6, 0.3, 0.35), 0.25)
		var burst := UnlockBurst.new()
		burst.position = content.position + Vector2(420, 52)
		burst.col = UIKit.GOLD
		burst.big = true
		root.add_child(burst)
	else:
		G.toast(G.T("not_enough"), UIKit.PINK)

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
	_panel(Rect2(0, 0, 390, 296), UIKit.RED)
	_lbl(G.T("active_quests").to_upper(), Vector2(12, 8), 8, UIKit.GOLD, 0.0, "head")
	var y := 26.0
	var i := 0
	for id in Prog.QUESTS:
		if not Prog.quest_active(id):
			continue
		var q: Dictionary = Prog.QUESTS[id]
		var card := QuestCard.new()
		card.id = id
		card.position = Vector2(10, y)
		card.size = Vector2(370, 50)
		card.delay = i * 0.06
		content.add_child(card)
		y += 54.0
		i += 1
	_panel(Rect2(400, 0, 200, 296))
	_lbl(G.T("done_quests").to_upper(), Vector2(412, 8), 8, Color(0.55, 1.0, 0.6), 0.0, "head")
	var y2 := 26.0
	for id in Prog.QUESTS:
		if Prog.quest_done(id):
			_lbl("+ " + G.L(Prog.QUESTS[id].title), Vector2(412, y2), 15, Color(0.6, 0.85, 0.65), 180)
			y2 += 20.0

# ------------------------------------------------------------------ mapa
func _build_map() -> void:
	_panel(Rect2(0, 0, 600, 296), UIKit.PURPLE)
	var mv := MapView.new()
	mv.world = world
	mv.position = Vector2(6, 6)
	mv.size = Vector2(588, 284)
	content.add_child(mv)

# ------------------------------------------------------------------ opciones
func _build_options() -> void:
	_panel(Rect2(140, 0, 320, 296), UIKit.RED)
	_btn(G.T("resume").to_upper(), Vector2(200, 16), close, true, 200)
	_btn(G.T("language").to_upper(), Vector2(200, 44), G.toggle_language, true, 200)
	_lbl(G.T("music_vol").to_upper(), Vector2(160, 82), 8, UIKit.WHITE, 0.0, "head")
	var ms := HSlider.new()
	ms.position = Vector2(300, 80)
	ms.size = Vector2(140, 14)
	ms.min_value = 0.0; ms.max_value = 1.0; ms.step = 0.05
	ms.value = G.music_volume
	ms.value_changed.connect(_on_music)
	content.add_child(ms)
	_lbl(G.T("sfx_vol").to_upper(), Vector2(160, 106), 8, UIKit.WHITE, 0.0, "head")
	var ss := HSlider.new()
	ss.position = Vector2(300, 104)
	ss.size = Vector2(140, 14)
	ss.min_value = 0.0; ss.max_value = 1.0; ss.step = 0.05
	ss.value = G.sfx_volume
	ss.value_changed.connect(_on_sfx)
	content.add_child(ss)
	if Net.is_online() and Net.is_host:
		var code := Net.online_code()
		_lbl(G.T("code_online") + ": " + (code if code != "" else "-"), Vector2(160, 134), 15, UIKit.GOLD)
		_lbl(G.T("code_lan") + ": " + Net.lan_code(), Vector2(160, 152), 15, UIKit.CYAN)
	_lbl(G.T("controls"), Vector2(160, 176), 10, UIKit.TEXT_DIM, 280, "title")
	_btn(G.T("save_quit").to_upper(), Vector2(200, 262), _on_save_quit, true, 200)

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

# ====================================================================== piezas
class MenuDeco extends Control:
	## Franjas diagonales en movimiento y marco general
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var off := fmod(t * 14.0, 32.0)
		for i in range(-20, 40):
			var x := i * 32.0 + off
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 10, 0), Vector2(x - 350, 360), Vector2(x - 360, 360)]), Color(1, 0.2, 0.35, 0.03))
		draw_rect(Rect2(0, 0, 640, 36), Color(0.06, 0.02, 0.08, 0.85))
		draw_rect(Rect2(0, 36, 640, 2), UIKit.RED)
		draw_rect(Rect2(0, 340, 640, 20), Color(0.06, 0.02, 0.08, 0.85))
		draw_rect(Rect2(0, 340, 640, 1), UIKit.RED_DARK)

class TabBar2 extends Control:
	var menu: Node
	var _cur := Rect2()
	var _t := 0.0
	var _rects := {}
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _process(delta: float) -> void:
		_t += delta
		if _rects.has(menu.tab):
			var r: Rect2 = _rects[menu.tab]
			if _cur.size == Vector2.ZERO:
				_cur = r
			_cur.position = _cur.position.lerp(r.position, clamp(delta * 16.0, 0.0, 1.0))
			_cur.size = _cur.size.lerp(r.size, clamp(delta * 16.0, 0.0, 1.0))
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("head")
		var x := 20.0
		_rects.clear()
		for t in menu.get_tabs():
			var txt := G.T(menu.tab_key(t)).to_upper()
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 18
			_rects[t] = Rect2(Vector2(x, 2), Vector2(w, 18))
			x += w + 4
		if _cur.size != Vector2.ZERO:
			UIKit.slash_band(self, Rect2(_cur.position + Vector2(2, 2), _cur.size), Color(0, 0, 0, 0.5), 5.0)
			UIKit.slash_band(self, _cur, UIKit.RED, 5.0)
			UIKit.slash_band(self, Rect2(_cur.position, Vector2(_cur.size.x, 3)), UIKit.PINK, 1.0)
		for t in menu.get_tabs():
			var r: Rect2 = _rects[t]
			var sel: bool = t == menu.tab
			var txt := G.T(menu.tab_key(t)).to_upper()
			var y := r.position.y + 13 - (roundf(sin(_t * 8.0) * 1.0) if sel else 0.0)
			f.draw_string_outline(get_canvas_item(), Vector2(r.position.x + 9, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 4, UIKit.INK)
			f.draw_string(get_canvas_item(), Vector2(r.position.x + 9, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE if sel else Color(0.7, 0.62, 0.75))
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for t in _rects:
				if _rects[t].has_point(event.position):
					menu.switch_tab(t)

class PanelBox extends Control:
	var col := UIKit.PURPLE
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		UIKit.frame(self, Rect2(Vector2.ZERO, size), col, Color(0.1, 0.04, 0.14, 0.92), 4.0, t)

class Portrait extends Control:
	var variant := 1
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		# aureola giratoria y rayos
		for i in 12:
			var a := TAU * i / 12.0 + t * 0.5
			var d := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([d * 30.0 + d.orthogonal() * 4.0, d * 70.0, d * 30.0 - d.orthogonal() * 4.0]), Color(1, 0.8, 0.3, 0.12))
		for i in 32:
			var a2 := TAU * i / 32.0 + t
			var p := (Vector2(cos(a2) * 34.0, sin(a2) * 7.0 - 58.0)).round()
			draw_rect(Rect2(p, Vector2(3, 3)), UIKit.GOLD if i % 2 == 0 else UIKit.GOLD_DARK)
		var frame := int(t * 6.0) % 4
		var tex := Fx.tex("player_p%d" % variant)
		var bob := roundf(sin(t * 3.0) * 2.0)
		draw_texture_rect_region(tex, Rect2(Vector2(-48, -60 + bob), Vector2(96, 104)), Rect2(frame * 24, 0, 24, 26))

class PipBar extends Control:
	var value := 1
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(150, 6)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var shown: int = min(int(t * 40.0), value)
		for i in 20:
			var on := i < mini(shown, 20)
			var c := UIKit.RED if on else Color(0.2, 0.1, 0.25)
			if on and i == shown - 1:
				c = UIKit.WHITE
			draw_rect(Rect2(Vector2(i * 7, 0), Vector2(6, 6)), UIKit.INK)
			draw_rect(Rect2(Vector2(i * 7 + 1, 1), Vector2(4, 4)), c)

class StatBar extends Control:
	var value := 0.5
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(200, 8)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var v: float = min(value, t * 2.5)
		draw_rect(Rect2(Vector2.ZERO, size), UIKit.INK)
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * v, size.y - 2)), UIKit.RED)
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * v, 2)), UIKit.PINK)
		var sx := fmod(t * 140.0, size.x)
		if sx < (size.x - 2) * v:
			draw_rect(Rect2(Vector2(sx, 1), Vector2(3, size.y - 2)), Color(1, 1, 1, 0.35))

class SigilView extends Control:
	## Dibuja el sigilo central, las conexiones y la energía que fluye por las ramas desbloqueadas.
	var menu: Node
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var c: Vector2 = menu.sigil_c()
		# anillos del sigilo
		for k in 3:
			var rr := 18.0 + k * 6.0
			for i in 24:
				var a := TAU * i / 24.0 + t * (0.6 if k % 2 == 0 else -0.4)
				var p := (c + Vector2(cos(a), sin(a)) * rr).round()
				draw_rect(Rect2(p, Vector2(2, 2)), Color(1, 0.8, 0.35, 0.4 + 0.3 * k))
		# fragmentos de los 10 Arcontes alrededor del núcleo
		for i in 10:
			var a2 := -PI / 2 + TAU * i / 10.0
			var p2 := (c + Vector2(cos(a2), sin(a2)) * 42.0 * Vector2(1.4, 1.0)).round()
			var lit = i == 0 and Prog.flags.get("seravel_dead", false)
			UIKit.diamond(self, p2, 3.0, UIKit.RED if lit else Color(0.25, 0.15, 0.3))
		UIKit.diamond(self, c, 9.0, UIKit.INK)
		UIKit.diamond(self, c, 7.0, UIKit.GOLD.lerp(UIKit.WHITE, 0.5 + 0.5 * sin(t * 3.0)))
		# conexiones
		for id in Prog.SKILLS:
			var s: Dictionary = Prog.SKILLS[id]
			var to: Vector2 = menu.skill_pos(id)
			var froms: Array = []
			if s.req.is_empty():
				froms.append(c)
			else:
				for r in s.req:
					froms.append(menu.skill_pos(r))
			var bc: Color = Prog.BRANCHES[s.branch].color
			for fp in froms:
				var on := Prog.has_skill(id)
				draw_line(fp, to, UIKit.INK, 4.0)
				draw_line(fp, to, bc if on else Color(0.3, 0.2, 0.35), 2.0)
				if on:
					for k in 3:
						var q := fmod(t * 0.8 + k / 3.0, 1.0)
						var pp: Vector2 = fp.lerp(to, q).round()
						draw_rect(Rect2(pp - Vector2(1, 1), Vector2(3, 3)), Color(1, 1, 1, 0.9))

class SkillNode extends Button:
	var id := ""
	var menu: Node
	var t := 0.0
	var _hover := 0.0
	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		var e := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			add_theme_stylebox_override(st, e)
		pivot_offset = size / 2.0
		mouse_entered.connect(func(): _hover = 1.0)
		focus_entered.connect(func(): _hover = 1.0)
	func _process(delta: float) -> void:
		t += delta
		if not is_hovered() and not has_focus():
			_hover = max(0.0, _hover - delta * 4.0)
		queue_redraw()
	func _draw() -> void:
		var s: Dictionary = Prog.SKILLS[id]
		var owned := Prog.has_skill(id)
		var can := Prog.can_unlock(id)
		var bc: Color = Prog.BRANCHES[s.branch].color
		var c := size / 2.0
		var r := 10.0 + _hover * 3.0 + (sin(t * 6.0) * 1.0 if can else 0.0)
		if menu._sel_skill == id:
			UIKit.diamond(self, c, r + 5.0, Color(1, 1, 1, 0.5 + 0.3 * sin(t * 8.0)), false)
		UIKit.diamond(self, c + Vector2(1, 2), r + 1.0, Color(0, 0, 0, 0.6))
		UIKit.diamond(self, c, r + 1.0, UIKit.INK)
		UIKit.diamond(self, c, r - 1.0, bc if owned else (bc.darkened(0.4) if can else Color(0.2, 0.12, 0.25)))
		UIKit.diamond(self, c, r - 4.0, Color(0.1, 0.04, 0.14))
		var tex := Fx.tex("icon_" + Prog.BRANCHES[s.branch].icon)
		draw_texture(tex, c - Vector2(8, 8), Color.WHITE if owned else (Color(1, 1, 1, 0.8) if can else Color(1, 1, 1, 0.25)))
		if owned:
			draw_rect(Rect2(c + Vector2(r - 4, -r + 2), Vector2(3, 3)), UIKit.WHITE)

class InfoCard extends Control:
	var title := ""
	var desc := ""
	var status := ""
	var col := Color.WHITE
	var icon: Texture2D
	var t := 0.0
	var _pop := 0.0
	var _tl: Label
	var _dl: Label
	var _sl: Label
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tl = UIKit.label("", 8, Color.WHITE, "head", 3)
		_tl.position = Vector2(28, 8)
		_tl.size = Vector2(size.x - 34, 0)
		_tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_tl)
		_dl = UIKit.label("", 15, UIKit.WHITE)
		_dl.position = Vector2(8, 30)
		_dl.size = Vector2(size.x - 16, 0)
		_dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(_dl)
		_sl = UIKit.label("", 10, UIKit.GOLD, "title", 3)
		_sl.position = Vector2(8, size.y - 16)
		add_child(_sl)
	func set_content(p_title: String, p_desc: String, p_status: String, p_col: Color, p_icon: Texture2D) -> void:
		title = p_title; desc = p_desc; status = p_status; col = p_col; icon = p_icon
		_tl.text = title
		_tl.label_settings.font_color = col
		_dl.text = desc
		_sl.text = status
		_pop = 1.0
	func _process(delta: float) -> void:
		t += delta
		_pop = max(0.0, _pop - delta * 5.0)
		queue_redraw()
	func _draw() -> void:
		var o := Vector2(0, -_pop * 4.0).round()
		UIKit.frame(self, Rect2(o, size), col, Color(0.1, 0.04, 0.14, 0.95), 4.0, t)
		if icon:
			draw_texture(icon, Vector2(8, 6) + o)

class UnlockBurst extends Node2D:
	var col := Color.WHITE
	var big := false
	var t := 0.0
	var parts := []
	func _ready() -> void:
		for i in (40 if big else 24):
			parts.append([Vector2.ZERO, Vector2.from_angle(randf() * TAU) * randf_range(60, 200 if big else 140)])
	func _process(delta: float) -> void:
		t += delta
		for p in parts:
			p[1] *= pow(0.05, delta)
			p[0] += p[1] * delta
		if t > 0.8:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / 0.8
		var r := 6.0 + k * (60.0 if big else 34.0)
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(col, 1.0 - k), 3.0 * (1.0 - k) + 1.0)
		draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 32, Color(1, 1, 1, 1.0 - k), 2.0)
		for p in parts:
			draw_rect(Rect2(p[0].round(), Vector2(2, 2)), Color(col.lerp(Color.WHITE, 0.4), 1.0 - k))

class ItemSlot extends Button:
	var item := ""
	var selected := false
	var equipped_slot := false
	var delay := 0.0
	var t := 0.0
	func _ready() -> void:
		flat = true
		var e := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			add_theme_stylebox_override(st, e)
		pivot_offset = size / 2.0
		scale = Vector2(0.2, 0.2)
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if item != "":
			UIKit.juicy(self)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var rc := Color(0.3, 0.2, 0.35)
		var tex: Texture2D = null
		var count := 0
		if item == "_feathers":
			tex = Fx.tex("icon_feather"); rc = Prog.RARITY_COLORS[1]; count = Prog.feathers
		elif item != "":
			var it: Dictionary = Prog.ITEMS[item]
			tex = Fx.tex("icon_" + it.icon)
			rc = Prog.RARITY_COLORS[it.rarity]
			count = Prog.item_count(item)
		UIKit.frame(self, r, rc if item != "" else Color(0.2, 0.12, 0.25), Color(0.08, 0.03, 0.1, 0.9), 3.0, t if selected else -1.0)
		if selected:
			draw_rect(r.grow(-3), Color(rc, 0.18 + 0.08 * sin(t * 6.0)))
		if tex:
			var bob := roundf(sin(t * 3.0 + position.x) * 1.0) if selected else 0.0
			draw_texture_rect(tex, Rect2(size / 2.0 - Vector2(16, 16) + Vector2(0, bob), Vector2(32, 32)), false)
		if count > 1:
			var f := UIKit.font("head")
			f.draw_string_outline(get_canvas_item(), Vector2(size.x - 14, size.y - 4), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), Vector2(size.x - 14, size.y - 4), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		if item != "" and Prog.has_amulet(item) and not equipped_slot:
			draw_rect(Rect2(Vector2(4, 4), Vector2(5, 5)), UIKit.GOLD)

class BigIcon extends Control:
	var tex: Texture2D
	var col := Color.WHITE
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var c := Vector2(24, 24)
		for i in 8:
			var a := TAU * i / 8.0 + t
			var d := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([c + d * 14 + d.orthogonal() * 3, c + d * 30, c + d * 14 - d.orthogonal() * 3]), Color(col, 0.18))
		var bob := roundf(sin(t * 2.5) * 2.0)
		draw_texture_rect(tex, Rect2(Vector2(0, bob), Vector2(48, 48)), false)

class WeaponCard extends Button:
	var id := ""
	var selected := false
	var delay := 0.0
	var t := 0.0
	func _ready() -> void:
		flat = true
		var e := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			add_theme_stylebox_override(st, e)
		pivot_offset = size / 2.0
		position.x -= 60
		modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "position:x", position.x + 60, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "modulate:a", 1.0, 0.2).set_delay(delay)
		UIKit.juicy(self)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var w: Dictionary = Prog.WEAPONS[id]
		var eq := id == Prog.equipped
		UIKit.frame(self, Rect2(Vector2.ZERO, size), UIKit.RED if selected else Color(0.3, 0.18, 0.36), Color(0.1, 0.04, 0.14, 0.95), 3.0, t if selected else -1.0)
		draw_texture_rect(Fx.tex("weapon_" + w.sprite), Rect2(Vector2(6, 8), Vector2(64, 24)), false)
		var f := UIKit.font("title")
		var nm := G.L(w.name).to_upper()
		f.draw_string_outline(get_canvas_item(), Vector2(76, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, size.x - 80, 10, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(76, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, size.x - 80, 10, UIKit.GOLD if selected else UIKit.WHITE)
		var lv: int = Prog.weapons.get(id, 0)
		for i in 10:
			var c := UIKit.GOLD if i < lv else Color(0.25, 0.15, 0.3)
			draw_rect(Rect2(Vector2(76 + i * 7, 26), Vector2(5, 5)), UIKit.INK)
			draw_rect(Rect2(Vector2(77 + i * 7, 27), Vector2(3, 3)), c)
		if eq:
			var b := UIKit.font("title")
			b.draw_string_outline(get_canvas_item(), Vector2(size.x - 50, 36), G.T("equipped").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
			b.draw_string(get_canvas_item(), Vector2(size.x - 50, 36), G.T("equipped").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.CYAN)

class WeaponShowcase extends Control:
	var tex: Texture2D
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		# pedestal de luz
		for i in 5:
			draw_rect(Rect2(Vector2(-50 + i * 8, 30 - i * 2), Vector2(100 - i * 16, 2)), Color(1, 0.4, 0.5, 0.25 + i * 0.1))
		for i in 6:
			var a := TAU * i / 6.0 + t * 0.7
			var d := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([d * 20 + d.orthogonal() * 4, d * 60, d * 20 - d.orthogonal() * 4]), Color(1, 0.75, 0.3, 0.1))
		var bob := roundf(sin(t * 2.0) * 3.0)
		draw_set_transform(Vector2(0, bob), sin(t * 1.3) * 0.15 - 0.2, Vector2(3, 3))
		draw_texture(tex, -tex.get_size() / 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var sp := fmod(t * 1.5, 2.0)
		if sp < 1.0:
			var p := Vector2(lerpf(-40, 40, sp), bob - 4 + lerpf(8, -8, sp)).round()
			draw_rect(Rect2(p, Vector2(3, 3)), Color.WHITE)

class QuestCard extends Control:
	var id := ""
	var delay := 0.0
	var t := 0.0
	var _l1: Label
	var _l2: Label
	var _l3: Label
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var q: Dictionary = Prog.QUESTS[id]
		var col := UIKit.GOLD if q.type == "main" else (UIKit.PINK if q.type == "bounty" else UIKit.CYAN)
		_l1 = UIKit.label(G.L(q.title).to_upper(), 8, col, "head", 3)
		_l1.position = Vector2(26, 6)
		add_child(_l1)
		_l2 = UIKit.label(Prog.quest_text(id), 15, UIKit.WHITE)
		_l2.position = Vector2(26, 17)
		add_child(_l2)
		var r: Dictionary = q.reward
		var rt := []
		if r.get("ecos", 0) > 0: rt.append("%d %s" % [r.ecos, G.T("ecos")])
		if r.get("sp", 0) > 0: rt.append("%d PH" % r.sp)
		if r.has("weapon"): rt.append(G.L(Prog.WEAPONS[r.weapon].name))
		if r.has("flask"): rt.append(G.T("flask_up"))
		if r.has("feathers"): rt.append("%d %s" % [r.feathers, G.T("feathers")])
		if r.has("free_upgrade"): rt.append(G.T("upgrade") + " +1")
		_l3 = UIKit.label(G.T("reward") + ": " + ", ".join(rt), 10, Color(0.6, 1.0, 0.65), "title", 3)
		_l3.position = Vector2(26, 36)
		add_child(_l3)
		modulate.a = 0.0
		position.x += 30
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "modulate:a", 1.0, 0.25).set_delay(delay)
		tw.tween_property(self, "position:x", position.x - 30, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var q: Dictionary = Prog.QUESTS[id]
		var col := UIKit.GOLD if q.type == "main" else (UIKit.PINK if q.type == "bounty" else UIKit.CYAN)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.03, 0.1, 0.8))
		draw_rect(Rect2(Vector2.ZERO, Vector2(3, size.y)), col)
		UIKit.diamond(self, Vector2(14, 11 + roundf(sin(t * 4.0))), 5.0, col)
		if q.has("count"):
			var p: float = float(Prog.quests[id].progress) / q.count
			draw_rect(Rect2(Vector2(250, 22), Vector2(110, 6)), UIKit.INK)
			draw_rect(Rect2(Vector2(251, 23), Vector2(108 * p, 4)), col)

class MapView extends Control:
	## Mapa del Estrato con niebla: solo se ven las zonas exploradas.
	var world: Node
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var sc := 3.0
		var off := Vector2(150, -6)
		# rejilla de fondo
		for gx in range(0, int(size.x), 16):
			draw_rect(Rect2(Vector2(gx, 0), Vector2(1, size.y)), Color(1, 1, 1, 0.03))
		for gy in range(0, int(size.y), 16):
			draw_rect(Rect2(Vector2(0, gy), Vector2(size.x, 1)), Color(1, 1, 1, 0.03))
		var colors := {"area_sanct": Color(1, 0.7, 0.4), "area_chains": Color(0.75, 0.6, 0.85), "area_gallery": Color(0.45, 0.6, 1.0),
			"area_yard": Color(1, 0.5, 0.4), "area_circle": Color(1, 0.3, 0.4), "area_mirador": Color(0.6, 0.9, 1.0)}
		for r in world.ROOMS:
			var rect: Rect2i = world._rect_of(r)
			var seen: bool = Prog.flags.get("seen_" + r.id, false)
			var a: String = world.AREAS.get(r.id, "")
			var c: Color = colors.get(a, Color.WHITE)
			var rr := Rect2(off + Vector2(rect.position) * sc, Vector2(rect.size) * sc)
			if seen:
				if r.has("c"):
					draw_circle(rr.get_center(), rr.size.x / 2.0 + 2, UIKit.INK)
					draw_circle(rr.get_center(), rr.size.x / 2.0, Color(c, 0.35))
					draw_arc(rr.get_center(), rr.size.x / 2.0, 0, TAU, 40, c, 1.0)
				else:
					draw_rect(rr.grow(2), UIKit.INK)
					draw_rect(rr, Color(c, 0.35))
					draw_rect(rr, c, false, 1.0)
			else:
				var adj := false
				for r2 in world.ROOMS:
					if Prog.flags.get("seen_" + r2.id, false) and world._rect_of(r2).grow(1).intersects(rect):
						adj = true
				if adj:
					var dash := int(t * 4.0) % 2
					for k in range(0, int(rr.size.x), 6):
						if (k / 6) % 2 == dash:
							draw_rect(Rect2(rr.position + Vector2(k, 0), Vector2(3, 1)), Color(1, 1, 1, 0.25))
							draw_rect(Rect2(rr.position + Vector2(k, rr.size.y), Vector2(3, 1)), Color(1, 1, 1, 0.25))
		# brasas, jefes
		for id in ["sanct", "gate"]:
			var it: Interactable = world.interactables.get(id)
			if it and Prog.flags.get("seen_" + world.room_at(it.position), false):
				var p: Vector2 = off + it.position / 16.0 * sc
				draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), UIKit.INK)
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), UIKit.GOLD if it.used else Color(0.5, 0.4, 0.3))
		for e in world.enemies:
			if e.is_boss and e.is_alive() and Prog.flags.get("seen_" + world.room_at(e.spawn_pos), false):
				var bp: Vector2 = off + e.spawn_pos / 16.0 * sc
				UIKit.diamond(self, bp, 5.0, UIKit.INK)
				UIKit.diamond(self, bp, 4.0, UIKit.RED)
		# jugador
		var lp: Player = world.local_player()
		if lp:
			var pp: Vector2 = (off + lp.global_position / 16.0 * sc).round()
			var pulse := 3.0 + 2.0 * absf(sin(t * 5.0))
			draw_arc(pp, pulse + 3, 0, TAU, 16, Color(1, 1, 1, 0.5), 1.0)
			draw_rect(Rect2(pp - Vector2(3, 3), Vector2(6, 6)), UIKit.INK)
			draw_rect(Rect2(pp - Vector2(2, 2), Vector2(4, 4)), UIKit.WHITE)
			var f := UIKit.font("title")
			f.draw_string_outline(get_canvas_item(), pp + Vector2(8, 4), G.T("you_are_here"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), pp + Vector2(8, 4), G.T("you_are_here"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.WHITE)
		# leyenda
		var hf := UIKit.font("head")
		var ly := 16.0
		for a in colors:
			var seen_any := false
			for r in world.ROOMS:
				if world.AREAS.get(r.id, "") == a and Prog.flags.get("seen_" + r.id, false):
					seen_any = true
			var name := G.T(a) if seen_any else "???"
			draw_rect(Rect2(Vector2(10, ly - 6), Vector2(6, 6)), colors[a] if seen_any else Color(0.3, 0.3, 0.3))
			hf.draw_string_outline(get_canvas_item(), Vector2(22, ly), name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			hf.draw_string(get_canvas_item(), Vector2(22, ly), name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE if seen_any else UIKit.TEXT_DIM)
			ly += 16.0
		var title := G.T("stratum1")
		hf.draw_string_outline(get_canvas_item(), Vector2(10, size.y - 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		hf.draw_string(get_canvas_item(), Vector2(10, size.y - 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)

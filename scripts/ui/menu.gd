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

const TABS := ["char", "skills", "inventory", "weapons", "quests", "codex", "map", "controls", "options"]
const TAB_KEYS := {"char": "tab_char", "skills": "tab_skills", "inventory": "tab_inventory", "weapons": "tab_weapons",
	"quests": "tab_quests", "codex": "tab_codex", "map": "tab_map", "controls": "tab_controls", "options": "tab_options"}

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
	return ["service"] if tab == "service" else TABS

func tab_key(t: String) -> String:
	if t == "service":
		return "svc_" + str(ctx.get("npc", "nyx"))
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
	if _rebinding != "":
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
			get_viewport().set_input_as_handled()
			if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
				_rebinding = ""
			else:
				G.rebind(_rebinding, event)
				Audio.sfx("ui_ok", -10.0)
				_rebinding = ""
			_rebuild(false)
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif tab == "service":
		return
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
		"service": _build_service()
		"controls": _build_controls()
		"codex": _build_codex()
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
	por.world = world
	content.add_child(por)
	var name_pt := UIKit.pixel_text(Look.display_name(G.look).to_upper(), 8, "head", UIKit.GOLD)
	name_pt.align = 1
	name_pt.size = Vector2(150, 10)
	name_pt.position = Vector2(0, 10)
	content.add_child(name_pt)
	# equipo: arma y dos amuletos bajo el retrato
	var eq := EquipStrip.new()
	eq.position = Vector2(19, 152)
	eq.size = Vector2(112, 36)
	content.add_child(eq)
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
	else:
		if not ctx.has("whisper"):
			ctx["whisper"] = Lore.brasa_whisper()
		var wl := _lbl(str(ctx["whisper"]), Vector2(10, 263), 10, Color(0.82, 0.7, 1.0), 132, "title")
		wl.modulate.a = 0.85
	# atributos
	_panel(Rect2(160, 0, 250, 296))
	var y := 12.0
	var attr_icons := {"vigor": "heart", "aguante": "ala", "fuerza": "iron", "destreza": "lance", "fe": "luz", "arcano": "orbit"}
	for k in ["vigor", "aguante", "fuerza", "destreza", "fe", "arcano"]:
		var aic := TextureRect.new()
		aic.texture = Fx.tex("icon_" + attr_icons[k])
		aic.position = Vector2(170, y - 3)
		aic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		content.add_child(aic)
		_lbl(G.T(k).to_upper(), Vector2(190, y), 8, UIKit.WHITE, 0.0, "head")
		var v: int = Prog.attr[k]
		var pips := PipBar.new()
		pips.value = v
		pips.position = Vector2(190, y + 14)
		content.add_child(pips)
		var vl := UIKit.pixel_text(str(v), 16, "head", UIKit.GOLD)
		vl.position = Vector2(330, y)
		content.add_child(vl)
		var can := at_brasa and Prog.ecos >= cost
		var b := _btn("+", Vector2(368, y), _on_buy.bind(k), can, 22)
		b.tooltip_text = G.T(k + "_d")
		_lbl(G.T(k + "_d"), Vector2(190, y + 22), 10, UIKit.TEXT_DIM, 0.0, "title")
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
	if id.begins_with("vial") and lp:
		Prog.quick_item = id
		lp._use_quick_item()
		return
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
	var locked_list: Array = []
	for id in Prog.WEAPONS:
		if not Prog.weapons.has(id):
			locked_list.append(id)
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
	# armas aún por encontrar: silueta y una pista de dónde están
	for lid in locked_list:
		if y > 250.0:
			break
		var lc := LockedWeaponCard.new()
		lc.id = lid
		lc.position = Vector2(8, y)
		lc.size = Vector2(214, 40)
		content.add_child(lc)
		y += 46.0
	_lbl(G.L(["ARSENAL %d/%d", "ARSENAL %d/%d"]) % [Prog.weapons.size(), Prog.WEAPONS.size()], Vector2(12, 282), 8, UIKit.TEXT_DIM, 0.0, "head")
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

# ------------------------------------------------------------------ controles
var _rebinding := ""
const ACTION_NAMES := {"up": ["Arriba", "Up"], "down": ["Abajo", "Down"], "left": ["Izquierda", "Left"], "right": ["Derecha", "Right"],
	"attack": ["Ataque", "Attack"], "heavy": ["Ataque cargado", "Heavy attack"], "dash": ["Esquivar", "Dash"], "parry": ["Desviar (parry)", "Parry"],
	"spell1": ["Lanza de Luz", "Lance of Light"], "spell2": ["Nova de Ceniza", "Ash Nova"], "wrath": ["Ira Seráfica", "Seraphic Wrath"],
	"heal": ["Curarse", "Heal"], "item": ["Objeto rápido", "Quick item"], "interact": ["Interactuar", "Interact"], "menu": ["Menú", "Menu"],
	"map": ["Mapa", "Map"], "photo": ["Modo foto", "Photo mode"]}

# ------------------------------------------------------------------ códice (bestiario)
const CODEX := [
	["hueco", "enemy_hueco", Rect2(0, 0, 32, 32), ["Hueco", "Husk"], ["Ángeles a los que la Voz vació por dentro. Arrastran cadenas que ya nadie sujeta y repiten, sin saberlo, la última orden que recibieron.", "Angels the Voice hollowed out. They drag chains no one holds anymore and repeat, unknowingly, the last order they were given."]],
	["acolito", "enemy_acolito", Rect2(0, 0, 32, 32), ["Acólito", "Acolyte"], ["Rezan con los ojos abiertos para no ver lo que adoran. Sus velas no queman: iluminan lo justo para que nadie se pierda... ni escape.", "They pray with open eyes so they won't see what they worship. Their candles don't burn: they shed just enough light so no one gets lost... or escapes."]],
	["planidera", "enemy_planidera", Rect2(0, 0, 32, 32), ["Plañidera", "Mourner"], ["Lloró tanto por los que cayeron que sus lágrimas aprendieron a caer también. Mira al suelo: la sombra avisa antes que la pena.", "She wept so much for the fallen that her tears learned to fall too. Watch the floor: the shadow warns before the grief does."]],
	["penitente", "enemy_penitente", Rect2(0, 0, 32, 32), ["Penitente", "Penitent"], ["Se encadenó a su propio incensario para no olvidar la culpa. Ya no recuerda cuál era, pero salta sobre cualquiera que se la recuerde.", "He chained himself to his own censer so as not to forget his guilt. He no longer remembers what it was, but he leaps on anyone who reminds him."]],
	["bestia", "enemy_bestia", Rect2(0, 0, 38, 28), ["Bestia de Ceniza", "Ash Beast"], ["Lo que queda cuando un ángel olvida que lo fue. Huele el miedo y la luz por igual.", "What remains when an angel forgets it ever was one. It smells fear and light alike."]],
	["guardia", "enemy_guardia", Rect2(0, 0, 32, 32), ["Guardia de las Celdas", "Cell Guard"], ["Llevan la puerta de su propia celda como escudo. Ataca por la espalda o rompe su postura: de frente, nada pasa.", "They carry the door of their own cell as a shield. Strike from behind or break their stance: from the front, nothing gets through."]],
	["custodio", "enemy_custodio", Rect2(0, 0, 48, 48), ["El Custodio del Umbral", "The Threshold Warden"], ["Estatua jurada a una sola puerta. Esperó mil años a que volviera el verdugo... y lo reconoció al instante.", "A statue sworn to a single door. It waited a thousand years for the executioner's return... and recognised it at once."]],
	["carcelero", "enemy_carcelero", Rect2(0, 0, 40, 40), ["El Carcelero", "The Jailer"], ["No encerraba a los presos para castigarlos, sino para esconderlos. Su llave no abre: impide que algo entre.", "He didn't lock the prisoners away to punish them, but to hide them. His key doesn't open: it keeps something out."]],
	["choir", "boss_singer", Rect2(0, 0, 26, 36), ["El Coro Hueco", "The Hollow Choir"], ["Tres voces que cantaban un nombre al revés para que su dueño no despertara. Cuando callaron, algo se dio la vuelta en el fondo.", "Three voices that sang a name backwards so its owner would not wake. When they fell silent, something turned over at the bottom."]],
	["seravel", "boss_seravel", Rect2(0, 0, 52, 56), ["Seravel, Guardiana de las Puertas", "Seravel, Warden of the Gates"], ["La primera de los serafines. Confió en el verdugo que le arrancó la primera pluma. Todavía lo espera a las puertas... del mismo lado, si la perdonas.", "First of the seraphim. She trusted the executioner who tore out her first feather. She still waits for them at the gates... on the same side, if you spare her."]],
]
var _codex_sel := "hueco"
const CODEX_NPCS := [
	["brenna", "brenna", ["Brenna", "Brenna"], ["Herrera del Santuario. Forjó la primera espada de Seravel y aún habla de ella con orgullo.", "Smith of the Sanctuary. She forged Seravel's first sword and still speaks of it with pride."]],
	["carto", "carto", ["El Cartógrafo", "The Cartographer"], ["Dibuja la Espiral desde hace siglos. Su mapa termina donde empieza su miedo.", "He has drawn the Spiral for centuries. His map ends where his fear begins."]],
	["ozias", "ozias", ["Ozias", "Ozias"], ["Grabador de runas. Talló el Himno en las campanas y olvidó para qué servía.", "Rune engraver. He carved the Hymn into the bells and forgot what it was for."]],
	["ilse", "ilse", ["Madre Ilse", "Mother Ilse"], ["Cose plumas a quien las pierde. Reza por todos, incluso por los que ya no recuerdan su nombre.", "She sews feathers for those who lose them. She prays for everyone, even those who forgot their name."]],
	["nyx", "nyx", ["Nyx", "Nyx"], ["Mercader de la máscara de pico. Compra barato, vende caro y nunca pregunta de dónde vienes.", "Beak-masked merchant. Buys cheap, sells dear and never asks where you come from."]],
	["velaria", "velaria", ["Sor Velaria", "Sister Velaria"], ["Guarda los ecos de los Arcontes caídos y deja que vuelvas a enfrentarte a ellos.", "Keeper of the fallen Archons' echoes; she lets you face them again."]],
	["preso", "preso", ["Tobías", "Tobias"], ["Preso de las Celdas de Espera. Lleva tanto tiempo esperando que ya no recuerda a quién.", "Prisoner of the Waiting Cells. He's waited so long he no longer remembers for whom."]],
	["peregrina", "peregrina", ["Sael, la Peregrina", "Sael, the Pilgrim"], ["Sube la Escalinata del Juicio desde hace trescientos años. Siempre despierta abajo.", "She has climbed the Stairs of Judgement for three hundred years. She always wakes at the bottom."]],
]

func _build_codex() -> void:
	_panel(Rect2(0, 0, 200, 296), UIKit.RED)
	_lbl(G.L(["CÓDICE", "CODEX"]), Vector2(14, 10), 8, UIKit.GOLD, 0.0, "head")
	var y := 28.0
	for e in CODEX:
		var known: bool = Prog.flags.get("killed_" + e[0], false)
		var nm := G.L(e[3]) if known else "???"
		var b := _btn(nm.to_upper() if known else nm, Vector2(12, y), _on_codex.bind(e[0]), true, 176)
		if e[0] == _codex_sel:
			b.add_theme_color_override("font_color", UIKit.GOLD)
		y += 21.0
	var met := 0
	for np in CODEX_NPCS:
		if Prog.flags.get("known_" + np[0], false):
			met += 1
	var nb := _btn(G.L(["PERSONAJES", "CHARACTERS"]) + "  %d/%d" % [met, CODEX_NPCS.size()], Vector2(12, 240), _on_codex.bind("_npc"), true, 176)
	if _codex_sel == "_npc":
		nb.add_theme_color_override("font_color", UIKit.GOLD)
	var ab := _btn(G.L(["LOGROS", "ACHIEVEMENTS"]) + "  %d/%d" % [Prog.achievements_count(), Prog.ACHIEVEMENTS.size()], Vector2(12, 266), _on_codex.bind("_ach"), true, 176)
	if _codex_sel == "_ach":
		ab.add_theme_color_override("font_color", UIKit.GOLD)
	_panel(Rect2(210, 0, 390, 296), UIKit.PURPLE)
	if _codex_sel == "_npc":
		var i2 := 0
		for np in CODEX_NPCS:
			var kn: bool = Prog.flags.get("known_" + np[0], false)
			var cx := 218.0 + (i2 % 4) * 95.0
			var cy := 10.0 + (i2 / 4) * 142.0
			var bp := CodexBust.new()
			bp.sheet = "bust_" + np[1]
			bp.known = kn
			bp.position = Vector2(cx + 16, cy)
			bp.size = Vector2(56, 56)
			content.add_child(bp)
			_lbl(G.L(np[2]).to_upper() if kn else "???", Vector2(cx, cy + 60), 8, UIKit.GOLD if kn else UIKit.TEXT_DIM, 90, "head")
			_lbl(G.L(np[3]) if kn else G.L(["Aún no os conocéis.", "You haven't met yet."]), Vector2(cx, cy + 74), 10, UIKit.WHITE if kn else Color(0.5, 0.45, 0.55), 90, "title")
			i2 += 1
		return
	if _codex_sel == "_ach":
		var yy := 14.0
		var i := 0
		for k in Prog.ACHIEVEMENTS:
			var got: bool = Prog.flags.get("ach_" + k, false)
			var a: Array = Prog.ACHIEVEMENTS[k]
			var x := 222.0 + (i % 2) * 190.0
			_lbl(("+ " if got else "- ") + G.L(a[0]).to_upper(), Vector2(x, yy), 8, UIKit.GOLD if got else UIKit.TEXT_DIM, 180, "head")
			_lbl(G.L(a[1]), Vector2(x + 10, yy + 12), 10, UIKit.WHITE if got else Color(0.5, 0.45, 0.55), 175, "title")
			if i % 2 == 1:
				yy += 40.0
			i += 1
		return
	for e2 in CODEX:
		if e2[0] != _codex_sel:
			continue
		var known2: bool = Prog.flags.get("killed_" + e2[0], false)
		var pv := CodexPortrait.new()
		pv.sheet = e2[1]
		pv.region = e2[2]
		pv.known = known2
		pv.position = Vector2(222, 16)
		pv.size = Vector2(140, 140)
		content.add_child(pv)
		_lbl(G.L(e2[3]).to_upper() if known2 else "???", Vector2(376, 24), 8, UIKit.GOLD if known2 else UIKit.TEXT_DIM, 210, "head")
		var boss: bool = e2[0] in ["carcelero", "choir", "seravel"]
		_lbl(G.L(["ARCONTE", "ARCHON"]) if boss else (G.L(["ÉLITE", "ELITE"]) if e2[0] == "custodio" else G.L(["CRIATURA DE LA ESPIRAL", "CREATURE OF THE SPIRAL"])), Vector2(376, 40), 8, UIKit.RED if boss else UIKit.CYAN, 210, "head")
		_lbl(G.L(e2[4]) if known2 else G.L(["Derrótalo para conocer su historia.", "Defeat it to learn its story."]), Vector2(376, 62), 15, UIKit.WHITE, 210)
		var kills := 0
		for w in Prog.weapon_kills.values():
			kills += int(w.get(e2[0], 0))
		if known2 and not boss and kills > 0:
			_lbl(G.L(["Abatidos: %d", "Slain: %d"]) % kills, Vector2(222, 170), 10, UIKit.TEXT_DIM, 0.0, "title")

func _on_codex(id: String) -> void:
	_codex_sel = id
	Audio.sfx("ui_move", -10.0)
	_rebuild(false)

func _build_controls() -> void:
	_panel(Rect2(0, 0, 600, 296), UIKit.CYAN)
	_lbl(G.L(["CONTROLES  -  pulsa una acción y luego la tecla o el botón nuevo", "CONTROLS  -  click an action, then press the new key or button"]), Vector2(14, 10), 8, UIKit.CYAN, 0.0, "head")
	var i := 0
	for a in G.REBINDABLE:
		var col := i / 9
		var row := i % 9
		var x := 16.0 + col * 296.0
		var y := 32.0 + row * 27.0
		_lbl(G.L(ACTION_NAMES[a]), Vector2(x, y + 1), 15, UIKit.WHITE)
		var txt := G.L(["...pulsa una tecla...", "...press a key..."]) if _rebinding == a else G.key_label(a)
		var b := _btn(txt, Vector2(x + 150, y), _on_rebind.bind(a), true, 120)
		if _rebinding == a:
			b.add_theme_color_override("font_color", UIKit.GOLD)
		i += 1
	_btn(G.L(["RESTABLECER", "RESET"]), Vector2(464, 268), _on_reset_keys, true, 120)
	_lbl(G.L(["Esc cancela. El mando funciona siempre con su esquema.", "Esc cancels. Gamepads keep their layout."]), Vector2(16, 272), 10, UIKit.TEXT_DIM, 0.0, "title")

func _on_rebind(a: String) -> void:
	_rebinding = a
	Audio.sfx("ui_move", -10.0)
	_rebuild(false)

func _on_reset_keys() -> void:
	G.reset_bindings()
	Audio.sfx("ui_ok", -10.0)
	_rebuild(false)

# ------------------------------------------------------------------ servicios de la Sala del Nimbo
var _svc_weapon := ""

func _build_service() -> void:
	var npc: String = ctx.get("npc", "nyx")
	var por := NpcBust.new()
	por.sheet = "npc_" + npc
	por.position = Vector2(0, 0)
	por.size = Vector2(150, 296)
	por.col = {"ozias": UIKit.CYAN, "ilse": Color(0.6, 0.75, 1.0), "nyx": UIKit.GOLD, "velaria": UIKit.RED}[npc]
	content.add_child(por)
	var quotes := {
		"ozias": ["Elige el grabado. El acero aprende rápido; olvida despacio.", "Choose the engraving. Steel learns fast; it forgets slowly."],
		"ilse": ["Cada Lágrima fue alguien. Cada pluma, también.", "Every Tear was someone. Every feather, too."],
		"nyx": ["No hago preguntas. Tampoco descuentos.", "I ask no questions. I give no discounts."],
		"velaria": ["Los ecos de los Arcontes duermen mal. Despiértalos.", "The Archons' echoes sleep poorly. Wake them."]}
	if npc == "ilse" and Prog.deaths >= 5:
		quotes.ilse = ["%d muertes, criatura. Tus alas se ven más ligeras... y más tristes." % Prog.deaths, "%d deaths, child. Your wings look lighter... and sadder." % Prog.deaths]
	_lbl(G.L(quotes[npc]), Vector2(10, 226), 15, UIKit.WHITE, 132)
	_panel(Rect2(160, 0, 440, 296), por.col)
	# recursos arriba a la derecha
	var res := "%s %d   %s %d   %s %d" % [G.T("ecos"), Prog.ecos, G.L(Prog.ITEMS.iron.name), Prog.item_count("iron"), G.L(Prog.ITEMS.tear.name), Prog.item_count("tear")]
	var rl := _lbl(res, Vector2(300, 8), 10, UIKit.CYAN, 0.0, "title")
	rl.size = Vector2(290, 12)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	match npc:
		"ozias": _svc_ozias()
		"ilse": _svc_ilse()
		"nyx": _svc_nyx()
		"velaria": _svc_velaria()

func _svc_ozias() -> void:
	if _svc_weapon == "" or not Prog.weapons.has(_svc_weapon):
		_svc_weapon = Prog.equipped
	_lbl(G.L(["GRABADOS RÚNICOS", "RUNIC ENGRAVINGS"]), Vector2(172, 10), 8, UIKit.CYAN, 0.0, "head")
	var y := 26.0
	for id in Prog.WEAPONS:
		if not Prog.weapons.has(id):
			continue
		var card := WeaponCard.new()
		card.id = id
		card.selected = id == _svc_weapon
		card.position = Vector2(170, y)
		card.size = Vector2(200, 34)
		card.pressed.connect(_on_svc_weapon.bind(id))
		content.add_child(card)
		var inf := Prog.infusion(id)
		if inf != "":
			var sw := ColorRect.new()
			sw.color = Prog.INFUSIONS[inf].color
			sw.position = Vector2(362, y + 4)
			sw.size = Vector2(5, 26)
			content.add_child(sw)
		y += 36.0
	var cur := Prog.infusion(_svc_weapon)
	var yy := 26.0
	for inf2 in Prog.INFUSIONS:
		if inf2 == "":
			continue
		var d: Dictionary = Prog.INFUSIONS[inf2]
		var row := ColorRect.new()
		row.color = Color(d.color, 0.16 if inf2 == cur else 0.06)
		row.position = Vector2(380, yy)
		row.size = Vector2(212, 54)
		content.add_child(row)
		var bar := ColorRect.new()
		bar.color = d.color
		bar.position = Vector2(380, yy)
		bar.size = Vector2(3, 54)
		content.add_child(bar)
		_lbl(G.L(d.name).to_upper(), Vector2(388, yy + 3), 8, d.color, 0.0, "head")
		_lbl(G.L(d.desc), Vector2(388, yy + 14), 10, UIKit.WHITE, 200, "title")
		if inf2 == cur:
			_lbl(G.L(["GRABADO", "ENGRAVED"]), Vector2(530, yy + 38), 8, UIKit.GOLD, 0.0, "head")
		else:
			var can := Prog.ecos >= 400 and Prog.item_count("iron") >= 1
			_btn(G.T("engrave") + " (400)", Vector2(470, yy + 34), _on_engrave.bind(inf2), can, 118)
		yy += 60.0
	_lbl(G.L(["Coste: 400 Ecos y 1 Esquirla de Nimbo. Un arma solo guarda un grabado.", "Cost: 400 Echoes and 1 Nimbus Shard. A weapon holds a single engraving."]), Vector2(172, 254), 10, UIKit.TEXT_DIM, 200, "title")

func _on_svc_weapon(id: String) -> void:
	_svc_weapon = id
	Audio.sfx("ui_move")
	_rebuild(false)

func _on_engrave(inf: String) -> void:
	if Prog.engrave(_svc_weapon, inf):
		Audio.sfx("hit_heavy")
		Audio.sfx("levelup", -6.0)
		G.flash(Color(Prog.INFUSIONS[inf].color, 0.35), 0.25)
		var burst := UnlockBurst.new()
		burst.position = content.position + Vector2(270, 60)
		burst.col = Prog.INFUSIONS[inf].color
		burst.big = true
		root.add_child(burst)
		Prog.changed.emit()
	else:
		G.toast(G.T("not_enough"), UIKit.PINK)

func _svc_ilse() -> void:
	_lbl(G.L(["LÁGRIMAS Y PLUMAS", "TEARS AND FEATHERS"]), Vector2(172, 10), 8, Color(0.6, 0.75, 1.0), 0.0, "head")
	var rows := [
		[G.L(["Aclarar las Lágrimas", "Clear the Tears"]), G.L(["Cada trago cura más. Nivel %d/5 (%d%% de vida).", "Each sip heals more. Level %d/5 (%d%% health)."]) % [Prog.flask_level, int(Prog.heal_ratio() * 100)],
			"%d %s" % [Prog.flask_upgrade_cost(), G.L(Prog.ITEMS.tear.name)], Prog.flask_level < 5 and Prog.item_count("tear") >= Prog.flask_upgrade_cost(), _on_ilse_potency],
		[G.L(["Otra Lágrima", "Another Tear"]), G.L(["Una carga más de curación. Tienes %d/8.", "One more healing charge. You have %d/8."]) % Prog.flasks_max,
			"2 " + G.L(Prog.ITEMS.tear.name), Prog.flasks_max < 8 and Prog.item_count("tear") >= 2, _on_ilse_charge],
		[G.L(["Coser una pluma", "Sew a feather"]), G.L(["Devuelve una pluma a tus alas. Te quedan %d/%d.", "Returns a feather to your wings. You have %d/%d."]) % [Prog.wing_feathers, Prog.WING_MAX],
			"1 " + G.L(Prog.ITEMS.tear.name), Prog.wing_feathers < Prog.WING_MAX and Prog.item_count("tear") >= 1, _on_ilse_feather],
	]
	var y := 30.0
	for r in rows:
		var bg := ColorRect.new()
		bg.color = Color(0.4, 0.55, 1.0, 0.07)
		bg.position = Vector2(172, y)
		bg.size = Vector2(416, 62)
		content.add_child(bg)
		_lbl(str(r[0]).to_upper(), Vector2(182, y + 6), 8, UIKit.WHITE, 0.0, "head")
		_lbl(r[1], Vector2(182, y + 20), 15, UIKit.TEXT_DIM, 260)
		_lbl(r[2], Vector2(470, y + 8), 10, UIKit.GOLD, 0.0, "title")
		_btn(G.L(["ACEPTAR", "ACCEPT"]), Vector2(470, y + 30), r[4], r[3], 104)
		y += 70.0
	var wi := WingMeter.new()
	wi.position = Vector2(380, 248)
	content.add_child(wi)

func _on_ilse_potency() -> void:
	if Prog.upgrade_flask_potency():
		Audio.sfx("heal")
		G.flash(Color(0.5, 0.7, 1.0, 0.3), 0.3)
		Prog.changed.emit()

func _on_ilse_charge() -> void:
	if Prog.buy_flask_charge():
		Audio.sfx("heal")
		var lp: Player = world.local_player()
		if lp:
			lp.flasks = Prog.flask_count()
		Prog.changed.emit()

func _on_ilse_feather() -> void:
	if Prog.item_count("tear") >= 1 and Prog.regrow_wing_feather():
		Prog.remove_item("tear", 1)
		Audio.sfx("levelup", -4.0)
		G.flash(Color(1, 1, 1, 0.35), 0.3)
		world.send_look()
		Prog.changed.emit()

func _svc_nyx() -> void:
	_lbl(G.L(["MERCANCÍA DE NYX", "NYX'S WARES"]), Vector2(172, 10), 8, UIKit.GOLD, 0.0, "head")
	var i := 0
	for e in Prog.SHOP:
		var id: String = e[0]
		var lim: int = e[1]
		var x := 172.0 + (i % 2) * 210.0
		var y := 28.0 + (i / 2) * 64.0
		var it: Dictionary = {"name": [G.T("feathers"), G.T("feathers")], "icon": "feather", "rarity": 1, "desc": ["", ""]} if id == "_feather" else Prog.ITEMS[id]
		var bg := ColorRect.new()
		bg.color = Color(Prog.RARITY_COLORS[it.rarity], 0.08)
		bg.position = Vector2(x, y)
		bg.size = Vector2(202, 60)
		content.add_child(bg)
		var ic := TextureRect.new()
		ic.texture = Fx.tex("icon_" + it.icon)
		ic.position = Vector2(x + 6, y + 8)
		ic.scale = Vector2(2, 2)
		content.add_child(ic)
		_lbl(G.L(it.name).to_upper(), Vector2(x + 44, y + 6), 8, Prog.RARITY_COLORS[it.rarity], 154, "head")
		var left := Prog.shop_left(id, lim)
		_lbl("%d %s" % [Prog.shop_price(id), G.T("ecos")], Vector2(x + 44, y + 28), 10, UIKit.CYAN, 0.0, "title")
		_lbl((G.T("stock") % left) if lim < 50 else "", Vector2(x + 130, y + 28), 10, UIKit.TEXT_DIM, 0.0, "title")
		if left > 0:
			_btn(G.T("buy"), Vector2(x + 44, y + 38), _on_nyx_buy.bind(id, lim), Prog.ecos >= Prog.shop_price(id), 80)
		else:
			_lbl(G.T("sold_out"), Vector2(x + 44, y + 42), 8, UIKit.PINK, 0.0, "head")
		i += 1

func _on_nyx_buy(id: String, lim: int) -> void:
	if Prog.buy(id, lim):
		Audio.sfx("pickup")
		Prog.changed.emit()
	else:
		G.toast(G.T("not_enough"), UIKit.PINK)

func _svc_velaria() -> void:
	_lbl(G.L(["ALTAR DE ASCENSIÓN", "ASCENSION ALTAR"]), Vector2(172, 10), 8, UIKit.RED, 0.0, "head")
	var y := 26.0
	var any := false
	for b in Prog.BOSS_INFO:
		var info: Dictionary = Prog.BOSS_INFO[b]
		var dead: bool = Prog.flags.get(info.flag, false)
		var bg := ColorRect.new()
		bg.color = Color(1, 0.2, 0.3, 0.07 if dead else 0.03)
		bg.position = Vector2(172, y)
		bg.size = Vector2(416, 52)
		content.add_child(bg)
		if not dead:
			_lbl("???  -  " + G.L(["Aún no has vencido a este Arconte.", "You have not yet defeated this Archon."]), Vector2(182, y + 18), 10, UIKit.TEXT_DIM, 0.0, "title")
			y += 58.0
			continue
		any = true
		var lv := int(Prog.ascension.get(b, 0))
		_lbl(G.T(info.title).to_upper(), Vector2(182, y + 5), 8, UIKit.WHITE, 0.0, "head")
		var pips := ""
		for k in 3:
			pips += ("I" if k == 0 else ("II" if k == 1 else "III")) + ("+ " if k < lv else "  ")
		_lbl(G.T("rank") + " %d   " % info.rank + G.T("ascension") + ": " + pips, Vector2(182, y + 18), 10, UIKit.PINK, 0.0, "title")
		if Prog.spared.has(b):
			_lbl(G.L(["Perdonado", "Spared"]), Vector2(182, y + 32), 10, Color(0.6, 1, 0.7), 0.0, "title")
		if lv < 3:
			var r: Dictionary = Prog.ASCENSION_REWARDS[lv + 1]
			_lbl(G.T("reward") + ": %d %s" % [r.ecos, G.T("ecos")], Vector2(300, y + 32), 10, UIKit.GOLD, 0.0, "title")
			_btn(G.L(["DESPERTAR ", "AWAKEN "]) + ["I", "II", "III"][lv], Vector2(486, y + 6), _on_velaria_asc.bind(b, lv + 1), true, 96)
		# juramento
		var od: Dictionary = Prog.OATHS[b]
		if Prog.oath == b:
			_lbl(G.L(["JURADO", "SWORN"]), Vector2(500, y + 34), 8, od.color, 0.0, "head")
		else:
			var ob := _btn(G.L(["JURAR", "SWEAR"]), Vector2(486, y + 28), _on_oath.bind(b), true, 96)
			ob.tooltip_text = G.L(od.name) + ": " + G.L(od.desc)
		y += 58.0
	if Prog.flags.get("seravel_dead", false):
		var can_ng := not Net.is_online() or multiplayer.is_server()
		_btn(G.T("ng_plus") + " (NG+%d)" % (Prog.ng + 1), Vector2(172, 244), _on_ng, can_ng, 200)
		_lbl(G.L(["Conservas nivel, armas y objetos. El Estrato renace más cruel.", "Keep level, weapons and items. The Stratum is reborn crueler."]), Vector2(380, 242), 10, UIKit.TEXT_DIM, 210, "title")
	if Prog.oath != "":
		var cur: Dictionary = Prog.OATHS[Prog.oath]
		_lbl(G.L(cur.name).to_upper() + ": " + G.L(cur.desc), Vector2(172, 210), 10, cur.color, 416, "title")
	elif any:
		var oy := 200.0
		for b2 in Prog.OATHS:
			if Prog.flags.get(Prog.BOSS_INFO[b2].flag, false):
				_lbl(G.L(Prog.OATHS[b2].name).to_upper() + ": " + G.L(Prog.OATHS[b2].desc), Vector2(172, oy), 10, Prog.OATHS[b2].color, 416, "title")
				oy += 14.0

func _on_velaria_asc(b: String, lvl: int) -> void:
	close()
	if multiplayer.is_server():
		world.start_ascension(b, lvl)
	else:
		world._rpc_start_ascension.rpc_id(1, b, lvl)

func _on_ng() -> void:
	Prog.start_ng()
	close()
	world.main.reload_continue()

func _on_oath(b: String) -> void:
	Prog.oath = b
	Audio.sfx("roar", -10.0)
	G.flash(Color(Prog.OATHS[b].color, 0.35), 0.4)
	G.toast(G.L(Prog.OATHS[b].name).to_upper(), Prog.OATHS[b].color)
	var lp: Player = world.local_player()
	if lp:
		lp.refresh_stats(false)
	Prog.changed.emit()

# ------------------------------------------------------------------ misiones
var _quest_sel := ""
const QUEST_LORE := {
	"main1": ["Despertaste con una orden grabada a fuego: descender y matar al Rey del Abismo. La Voz insiste en que es tu penitencia. Nunca dice por qué.", "You woke with an order burned into you: descend and slay the King of the Abyss. The Voice insists it is your penance. It never says why."],
	"feathers": ["Brenna necesita plumas para templar el acero. Dice que las armas recuerdan a quien se las dio.", "Brenna needs feathers to temper steel. She says weapons remember who gave them."],
	"husks": ["El Cartógrafo no puede medir el Pasillo mientras los Huecos sigan arrastrando cadenas por él.", "The Cartographer can't measure the Hall while the Husks keep dragging chains through it."],
	"map": ["El Cartógrafo perdió su mapa en la Galería Rota. Jura que alguien lo movió... o algo.", "The Cartographer lost his map in the Broken Gallery. He swears someone moved it... or something."],
	"choir": ["Sor Velaria quiere silencio. El Coro Hueco canta un nombre al revés y no la deja dormir desde hace siglos.", "Sister Velaria wants silence. The Hollow Choir sings a name backwards and hasn't let her sleep for centuries."],
	"hymns": ["Tres páginas del Himno de la Vigilia andan dispersas por el Estrato. Juntas quizá expliquen para qué servían las campanas.", "Three pages of the Hymn of the Vigil lie scattered across the Stratum. Together they might explain what the bells were for."],
	"jailer_hunt": ["Brenna quiere ver con sus propios ojos la llave del Carcelero. Dice que no es hierro de la Espiral.", "Brenna wants to see the Jailer's key with her own eyes. She says it isn't Spiral iron."],
}
const GIVERS := {"brenna": ["Brenna", "Brenna"], "carto": ["El Cartógrafo", "The Cartographer"], "velaria": ["Sor Velaria", "Sister Velaria"]}

func _build_quests() -> void:
	# --- diario: lista por categorías
	_panel(Rect2(0, 0, 222, 296), UIKit.RED)
	_lbl(G.L(["DIARIO", "JOURNAL"]), Vector2(12, 8), 8, UIKit.GOLD, 0.0, "head")
	var order := []
	for cat in ["main", "side", "bounty"]:
		for id in Prog.QUESTS:
			if Prog.QUESTS[id].type == cat and Prog.quest_active(id):
				order.append(id)
	var done := []
	for id in Prog.QUESTS:
		if Prog.quest_done(id):
			done.append(id)
	if _quest_sel == "" or not (Prog.quest_active(_quest_sel) or Prog.quest_done(_quest_sel)):
		_quest_sel = order[0] if not order.is_empty() else (done[0] if not done.is_empty() else "")
	var y := 24.0
	var cur_cat := ""
	var i := 0
	for id in order + done:
		var q: Dictionary = Prog.QUESTS[id]
		var cat: String = "done" if Prog.quest_done(id) else str(q.type)
		if cat != cur_cat:
			cur_cat = cat
			var hdr: String = {"main": G.L(["PRINCIPAL", "MAIN"]), "side": G.L(["ENCARGOS", "ERRANDS"]), "bounty": G.L(["CAZAS", "HUNTS"]), "done": G.L(["COMPLETADAS", "COMPLETED"])}[cat]
			_lbl(hdr, Vector2(14, y + 2), 8, UIKit.TEXT_DIM, 0.0, "head")
			y += 14.0
		var row := QuestRow.new()
		row.id = id
		row.menu = self
		row.selected = id == _quest_sel
		row.position = Vector2(8, y)
		row.size = Vector2(206, 20)
		row.delay = i * 0.04
		content.add_child(row)
		y += 22.0
		i += 1
		if y > 186.0:
			break
	var dv := DestinyScale.new()
	dv.position = Vector2(11, 196)
	dv.size = Vector2(200, 100)
	content.add_child(dv)
	# --- detalle de la misión elegida
	_panel(Rect2(232, 0, 368, 296), UIKit.PURPLE)
	if _quest_sel == "":
		_lbl(G.L(["No tienes misiones.", "You have no quests."]), Vector2(250, 20), 15, UIKit.TEXT_DIM)
		return
	var det := QuestDetail.new()
	det.id = _quest_sel
	det.position = Vector2(232, 0)
	det.size = Vector2(368, 296)
	content.add_child(det)
	var qd: Dictionary = Prog.QUESTS[_quest_sel]
	var lore := _lbl(G.L(QUEST_LORE.get(_quest_sel, ["", ""])), Vector2(306, 52), 10, Color(0.85, 0.8, 0.9), 282, "title")
	lore.modulate.a = 0.95
	# pasos o progreso
	var sy := 124.0
	var qs: Dictionary = Prog.quests.get(_quest_sel, {})
	if qd.has("steps"):
		var cur: int = qs.get("step", 0)
		var finished := Prog.quest_done(_quest_sel)
		for k in qd.steps.size():
			var done_k = finished or k < cur
			var now_k = not finished and k == cur
			var txt := G.L(qd.steps[k].text) if (done_k or now_k) else "? ? ?"
			var col := Color(0.55, 0.85, 0.6) if done_k else (UIKit.WHITE if now_k else Color(0.45, 0.4, 0.5))
			_lbl(txt, Vector2(270, sy), 10, col, 310, "title")
			sy += 16.0
	else:
		_lbl(Prog.quest_text(_quest_sel), Vector2(250, sy), 15, UIKit.WHITE, 330)
	_lbl(G.T("reward").to_upper(), Vector2(246, 248), 8, UIKit.GOLD, 0.0, "head")

func _on_quest(id: String) -> void:
	_quest_sel = id
	Audio.sfx("ui_move", -10.0)
	_rebuild(false)

# ------------------------------------------------------------------ mapa
func _build_map() -> void:
	_panel(Rect2(0, 0, 600, 296), UIKit.PURPLE)
	var mv := MapView.new()
	mv.world = world
	mv.position = Vector2(6, 6)
	mv.size = Vector2(588, 284)
	content.add_child(mv)

# ------------------------------------------------------------------ opciones
var _slider_theme: Theme

func _style_slider(sl: HSlider) -> void:
	## Deslizadores con el estilo del juego: carril oscuro con borde, relleno rojo y un rombo dorado
	if _slider_theme == null:
		_slider_theme = Theme.new()
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.1, 0.04, 0.13)
		track.border_color = Color(0.45, 0.25, 0.5)
		track.set_border_width_all(1)
		track.content_margin_top = 3
		track.content_margin_bottom = 3
		var fill := StyleBoxFlat.new()
		fill.bg_color = UIKit.RED
		fill.border_color = UIKit.PINK
		fill.border_width_top = 1
		fill.content_margin_top = 3
		fill.content_margin_bottom = 3
		var img := Image.create(9, 9, false, Image.FORMAT_RGBA8)
		for y in 9:
			for x in 9:
				var dd := absi(x - 4) + absi(y - 4)
				if dd <= 4:
					img.set_pixel(x, y, UIKit.INK if dd == 4 else (UIKit.GOLD if dd > 1 else Color(1, 0.97, 0.85)))
		var gtex := ImageTexture.create_from_image(img)
		_slider_theme.set_stylebox("slider", "HSlider", track)
		_slider_theme.set_stylebox("grabber_area", "HSlider", fill)
		_slider_theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
		_slider_theme.set_icon("grabber", "HSlider", gtex)
		_slider_theme.set_icon("grabber_highlight", "HSlider", gtex)
	sl.theme = _slider_theme

func _build_options() -> void:
	# ficha de pausa: tu Desplumado, dónde estás y cuánto llevas
	_panel(Rect2(0, 0, 132, 296), UIKit.PURPLE)
	_lbl(G.L(["EN PAUSA", "PAUSED"]), Vector2(12, 10), 8, UIKit.GOLD, 0.0, "head")
	var pb := PauseBust.new()
	pb.position = Vector2(22, 28)
	pb.size = Vector2(88, 88)
	content.add_child(pb)
	_lbl(Look.display_name(G.look).to_upper(), Vector2(8, 122), 8, UIKit.WHITE, 116, "head").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl("%s %d" % [G.T("level"), Prog.level], Vector2(8, 136), 10, UIKit.GOLD, 116, "title").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var area_key: String = world._area if world and world._area != "" else "area_sanct"
	_lbl(G.T(area_key), Vector2(8, 152), 10, UIKit.CYAN, 116, "title").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var info := [[G.L(["Tiempo", "Time"]), "%d:%02d" % [int(Prog.playtime / 3600.0), int(Prog.playtime / 60.0) % 60]],
		[G.L(["Plumas", "Feathers"]), "%d/%d" % [Prog.wing_feathers, Prog.WING_MAX]], [G.L(["Caídas", "Falls"]), str(Prog.deaths)]]
	var iy := 176.0
	for row in info:
		_lbl(row[0], Vector2(12, iy), 10, UIKit.TEXT_DIM, 0.0, "title")
		var v := _lbl(row[1], Vector2(70, iy), 10, UIKit.WHITE, 50, "title")
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		iy += 15.0
	if not ctx.has("whisper"):
		ctx["whisper"] = Lore.brasa_whisper()
	var wq := _lbl(str(ctx["whisper"]), Vector2(8, 228), 10, Color(0.82, 0.7, 1.0), 116, "title")
	wq.modulate.a = 0.85
	_panel(Rect2(140, 0, 320, 296), UIKit.RED)
	_btn(G.T("resume").to_upper(), Vector2(200, 16), close, true, 200)
	_btn(G.T("language").to_upper(), Vector2(152, 44), G.toggle_language, true, 144)
	_btn(G.fs_label().to_upper(), Vector2(304, 44), _on_fullscreen, true, 144)
	_lbl(G.T("music_vol").to_upper(), Vector2(160, 82), 8, UIKit.WHITE, 0.0, "head")
	var ms := HSlider.new()
	_style_slider(ms)
	ms.position = Vector2(300, 80)
	ms.size = Vector2(140, 14)
	ms.min_value = 0.0; ms.max_value = 1.0; ms.step = 0.05
	ms.value = G.music_volume
	ms.value_changed.connect(_on_music)
	content.add_child(ms)
	_lbl(G.T("sfx_vol").to_upper(), Vector2(160, 106), 8, UIKit.WHITE, 0.0, "head")
	var ss := HSlider.new()
	_style_slider(ss)
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
	# chuleta de controles con teclas dibujadas
	_lbl(G.L(["CONTROLES", "CONTROLS"]), Vector2(160, 134), 8, UIKit.GOLD, 0.0, "head")
	var kh := KeyHints.new()
	kh.position = Vector2(156, 146)
	kh.size = Vector2(296, 104)
	content.add_child(kh)
	_btn(G.T("save_quit").to_upper(), Vector2(200, 262), _on_save_quit, true, 200)
	# accesibilidad
	_panel(Rect2(470, 0, 130, 296), UIKit.CYAN)
	_lbl(G.T("access").to_upper(), Vector2(480, 10), 8, UIKit.CYAN, 0.0, "head")
	_lbl(G.T("shake_opt"), Vector2(480, 30), 10, UIKit.WHITE, 110, "title")
	var sh := HSlider.new()
	_style_slider(sh)
	sh.position = Vector2(480, 46); sh.size = Vector2(110, 14)
	sh.min_value = 0.0; sh.max_value = 1.0; sh.step = 0.1; sh.value = G.shake_mult
	sh.value_changed.connect(_on_access.bind("shake"))
	content.add_child(sh)
	_lbl(G.T("flash_opt"), Vector2(480, 68), 10, UIKit.WHITE, 110, "title")
	var fl := HSlider.new()
	_style_slider(fl)
	fl.position = Vector2(480, 84); fl.size = Vector2(110, 14)
	fl.min_value = 0.0; fl.max_value = 1.0; fl.step = 0.1; fl.value = G.flash_mult
	fl.value_changed.connect(_on_access.bind("flash"))
	content.add_child(fl)
	_lbl(G.T("tele_opt"), Vector2(480, 106), 10, UIKit.WHITE, 110, "title")
	_btn(G.T("on") if G.tele_boost else G.T("off"), Vector2(480, 124), _on_tele, true, 60)
	_lbl(G.L(["[P] Modo foto\n[M] Mapa", "[P] Photo mode\n[M] Map"]), Vector2(480, 160), 10, UIKit.TEXT_DIM, 110, "title")
	var dd: Dictionary = world.diff() if world else Prog.diff()
	_lbl(G.T("difficulty").to_upper(), Vector2(480, 214), 8, UIKit.WHITE, 0.0, "head")
	_lbl(G.L(dd.name).to_upper() + (("  NG+%d" % Prog.ng) if Prog.ng > 0 else ""), Vector2(480, 228), 10, dd.color, 110, "title")
	if Prog.oath != "":
		_lbl(G.L(Prog.OATHS[Prog.oath].name), Vector2(480, 252), 10, Prog.OATHS[Prog.oath].color, 110, "title")

func _on_access(v: float, which: String) -> void:
	if which == "shake":
		G.shake_mult = v
	else:
		G.flash_mult = v
	G.save_settings()

func _on_fullscreen() -> void:
	G.toggle_fullscreen()
	_rebuild(false)

func _on_tele() -> void:
	G.tele_boost = not G.tele_boost
	G.save_settings()
	_rebuild(false)

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
class DestinyScale extends Control:
	## Balanza del destino: hacia qué final se inclinan tus decisiones
	var t := 0.0
	var _ang := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = G.T("route_hint")
	func _process(delta: float) -> void:
		t += delta
		var want := clampf(-Prog.route_score() / 6.0, -1.0, 1.0) * 0.45
		_ang = lerpf(_ang, want + sin(t * 1.6) * 0.03, clampf(delta * 3.0, 0.0, 1.0))
		queue_redraw()
	func _draw() -> void:
		var f := UIKit.font("head")
		var tf := UIKit.font("title")
		draw_rect(Rect2(Vector2(8, 0), Vector2(size.x - 16, 1)), Color(1, 1, 1, 0.15))
		f.draw_string_outline(get_canvas_item(), Vector2(12, 14), G.T("destiny"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(12, 14), G.T("destiny"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)
		var c := Vector2(size.x / 2.0, 30)
		var wc := Color(0.75, 0.9, 1.0)
		var tc := Color(1, 0.35, 0.4)
		# halo de fondo hacia el lado que gana
		var lean := clampf(-_ang / 0.45, -1.0, 1.0)
		for k in 4:
			draw_circle(c + Vector2(-lean * 40.0, 22), 30.0 - k * 6.0, Color(wc if lean > 0 else tc, 0.03 + k * 0.015))
		# pie, columna con capitel y base escalonada
		draw_rect(Rect2(c + Vector2(-2, -4), Vector2(5, 46)), UIKit.INK)
		draw_rect(Rect2(c + Vector2(-1, -4), Vector2(3, 46)), UIKit.GOLD_DARK)
		draw_rect(Rect2(c + Vector2(0, -4), Vector2(1, 46)), UIKit.GOLD)
		for k in 3:
			draw_rect(Rect2(c + Vector2(-10 + k * 3, 42 - k * 2), Vector2(21 - k * 6, 3)), UIKit.GOLD_DARK.darkened(0.2 * k))
		draw_circle(c + Vector2(0, -7), 4.0, UIKit.INK)
		draw_circle(c + Vector2(0, -7), 3.0, UIKit.GOLD)
		draw_circle(c + Vector2(0, -7), 1.2, Color(1, 0.97, 0.85))
		# brazo con remates
		var d := Vector2.from_angle(_ang)
		var l := c - d * 62.0
		var r := c + d * 62.0
		draw_line(l, r, UIKit.INK, 5.0)
		draw_line(l, r, UIKit.GOLD_DARK, 3.0)
		draw_line(l + Vector2(0, -1), r + Vector2(0, -1), UIKit.GOLD, 1.0)
		UIKit.diamond(self, c, 5.0, UIKit.INK)
		UIKit.diamond(self, c, 4.0, UIKit.GOLD)
		for e in [l, r]:
			UIKit.diamond(self, e, 3.0, UIKit.GOLD)
		# platillos colgando de tres cadenas
		var pans := [[l, wc], [r, tc]]
		var pan_c: Array = []
		for pi in 2:
			var top: Vector2 = pans[pi][0]
			var pc: Color = pans[pi][1]
			var bot := top + Vector2(0, 22)
			for k in [-1, 0, 1]:
				var bp := bot + Vector2(k * 9, 0)
				for q in 4:
					var cp := top.lerp(bp, (q + 0.5) / 4.0)
					draw_rect(Rect2(cp - Vector2(0.5, 1), Vector2(1, 2)), Color(0.9, 0.8, 0.55, 0.8))
			var pts := PackedVector2Array([bot + Vector2(-13, 0), bot + Vector2(13, 0), bot + Vector2(9, 5), bot + Vector2(-9, 5)])
			draw_colored_polygon(pts, UIKit.INK)
			draw_colored_polygon(PackedVector2Array([bot + Vector2(-12, 1), bot + Vector2(12, 1), bot + Vector2(8, 4), bot + Vector2(-8, 4)]), UIKit.GOLD_DARK)
			draw_line(bot + Vector2(-12, 1), bot + Vector2(12, 1), UIKit.GOLD, 1.0)
			draw_circle(bot + Vector2(0, -6), 9.0, Color(pc, 0.1 + 0.05 * sin(t * 3.0 + pi)))
			pan_c.append(bot)
		# alas abiertas sobre el platillo izquierdo; trono vacío sobre el derecho
		var lp: Vector2 = pan_c[0] + Vector2(0, -3)
		UIKit.wing(self, lp + Vector2(-2, 0), -1.0, 11.0, wc, 0.8 + 0.1 * sin(t * 4.0))
		UIKit.wing(self, lp + Vector2(2, 0), 1.0, 11.0, wc, 0.8 + 0.1 * sin(t * 4.0))
		var rp: Vector2 = pan_c[1] + Vector2(0, -12)
		draw_rect(Rect2(rp + Vector2(-6, -4), Vector2(12, 15)), UIKit.INK)
		draw_rect(Rect2(rp + Vector2(-5, -3), Vector2(3, 12)), tc)
		draw_rect(Rect2(rp + Vector2(-5, 4), Vector2(10, 3)), tc)
		draw_rect(Rect2(rp + Vector2(2, 3), Vector2(3, 6)), tc.darkened(0.3))
		draw_rect(Rect2(rp + Vector2(-5, -6), Vector2(1, 2)), UIKit.GOLD)
		draw_rect(Rect2(rp + Vector2(-3, -6), Vector2(1, 2)), UIKit.GOLD)
		# rótulos de los dos finales
		var a1 := G.T("route_wings")
		var a2 := G.T("route_throne")
		tf.draw_string(get_canvas_item(), Vector2(4, 96), a1, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(wc, 0.55))
		tf.draw_string(get_canvas_item(), Vector2(size.x - 4 - tf.get_string_size(a2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, 96), a2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(tc, 0.55))
		var sc := Prog.route_score()
		var wn := G.T("route_wings") if sc >= 0 else G.T("route_throne")
		var col := wc if sc >= 0 else tc
		var w := tf.get_string_size(wn, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		tf.draw_string_outline(get_canvas_item(), Vector2(size.x / 2.0 - w / 2.0, 84), wn, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
		tf.draw_string(get_canvas_item(), Vector2(size.x / 2.0 - w / 2.0, 84), wn, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)

class NpcBust extends Control:
	## Retrato grande animado del PNJ del servicio
	var sheet := "npc_nyx"
	var col := Color.WHITE
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		UIKit.frame(self, Rect2(Vector2.ZERO, size), col, Color(0.08, 0.03, 0.1, 0.92), 4.0, t)
		var c := Vector2(size.x / 2.0, 110)
		for i in 10:
			var a := TAU * i / 10.0 + t * 0.4
			var d := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([c + d * 26.0 + d.orthogonal() * 4.0, c + d * 72.0, c + d * 26.0 - d.orthogonal() * 4.0]), Color(col, 0.1))
		var bob := roundf(sin(t * 2.0) * 2.0)
		var bust := "bust_" + sheet.trim_prefix("npc_")
		if ResourceLoader.exists("res://assets/sprites/%s.png" % bust):
			# busto grande a 2x con parpadeo
			var fb := 2 if fmod(t, 3.4) < 0.13 else 0
			var r := Rect2(c + Vector2(-48, -58 + bob), Vector2(96, 96))
			draw_rect(r.grow(3), Color(0.05, 0.02, 0.07, 0.8))
			draw_texture_rect_region(Fx.tex(bust), r, Rect2(fb * 48, 0, 48, 48))
			draw_rect(r.grow(3), col, false, 2.0)
		else:
			var fr := int(t * 4.0) % 4
			draw_texture_rect_region(Fx.tex(sheet), Rect2(c + Vector2(-60, -70 + bob), Vector2(120, 130)), Rect2(fr * 32, 0, 32, 32))
		for i in 6:
			var p := Vector2(fmod(i * 37.0 + t * 12.0, size.x - 10) + 5, 200.0 - fmod(t * 20.0 + i * 31.0, 160.0))
			draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(col, 0.6))

class WingMeter extends Control:
	## Las plumas de tus alas: cada muerte arranca una
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var wc := Look.color_of(G.look, "wing")
		for i in Prog.WING_MAX:
			var side := -1 if i % 2 == 0 else 1
			var k := i / 2
			var p := Vector2(100 + side * (14 + k * 14), 18 - k * 3)
			var have := i < Prog.wing_feathers
			var c := wc if have else Color(0.25, 0.18, 0.3)
			var tip := p + Vector2(side * 8, -12 + k * 2)
			draw_line(p, tip, UIKit.INK, 5.0)
			draw_line(p, tip, c, 3.0)
			if not have:
				draw_line(p + Vector2(-3, -3), p + Vector2(3, 3), UIKit.RED_DARK, 1.0)
		var f := UIKit.font("head")
		var txt := "%d/%d" % [Prog.wing_feathers, Prog.WING_MAX]
		f.draw_string_outline(get_canvas_item(), Vector2(88, 38), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), Vector2(88, 38), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.PINK if Prog.is_desplumado() else UIKit.WHITE)

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
		var tabs: Array = menu.get_tabs()
		var total := 0.0
		for t0 in tabs:
			total += f.get_string_size(G.T(menu.tab_key(t0)).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 18 + 4
		var squeeze := clampf((600.0 - total) / float(tabs.size() * 2), -5.0, 0.0)
		for t in tabs:
			var txt := G.T(menu.tab_key(t)).to_upper()
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 18 + squeeze * 2.0
			_rects[t] = Rect2(Vector2(x, 2), Vector2(w, 18))
			x += w + 4 + squeeze
		if _cur.size != Vector2.ZERO:
			UIKit.slash_band(self, Rect2(_cur.position + Vector2(2, 2), _cur.size), Color(0, 0, 0, 0.5), 5.0)
			UIKit.slash_band(self, _cur, UIKit.RED, 5.0)
			UIKit.slash_band(self, Rect2(_cur.position, Vector2(_cur.size.x, 3)), UIKit.PINK, 1.0)
		for t in menu.get_tabs():
			var r: Rect2 = _rects[t]
			var sel: bool = t == menu.tab
			var txt := G.T(menu.tab_key(t)).to_upper()
			var y := r.position.y + 13 - (roundf(sin(_t * 8.0) * 1.0) if sel else 0.0)
			var tx := r.position.x + (r.size.x - f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x) / 2.0
			f.draw_string_outline(get_canvas_item(), Vector2(tx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 4, UIKit.INK)
			f.draw_string(get_canvas_item(), Vector2(tx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE if sel else Color(0.7, 0.62, 0.75))
			if not sel:
				draw_rect(Rect2(Vector2(r.get_center().x - 1, r.end.y - 1), Vector2(2, 2)), Color(0.6, 0.4, 0.65, 0.6))
		# teclas para cambiar de pestaña a los lados
		if tabs.size() > 1:
			for side in [-1, 1]:
				var kp := Vector2(8 if side < 0 else size.x - 8, 11)
				var kr := Rect2(kp - Vector2(6, 6), Vector2(12, 12))
				draw_rect(kr.grow(1), UIKit.INK)
				draw_rect(kr, Color(0.22, 0.12, 0.28))
				draw_rect(Rect2(kr.position, Vector2(12, 2)), Color(0.45, 0.3, 0.55))
				var kl := G.key_label("spell1" if side < 0 else "spell2").left(1)
				f.draw_string(get_canvas_item(), kr.position + Vector2(3, 10), kl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)
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
	var world: Node
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
		var lp: Player = world.local_player() if world else null
		var tex: Texture2D = lp.sprite.texture if lp else Look.texture(G.look, Prog.wing_feathers)
		var bob := roundf(sin(t * 3.0) * 2.0)
		draw_texture_rect_region(tex, Rect2(Vector2(-48, -70 + bob), Vector2(96, 96)), Rect2(frame * 32, 0, 32, 32))

class PipBar extends Control:
	## Barra de atributo en segmentos con brillo; cada 5 puntos un segmento más alto
	var value := 1
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(130, 7)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var shown: int = min(int(t * 40.0), value)
		for i in 20:
			var on := i < mini(shown, 20)
			var tall := (i + 1) % 5 == 0
			var r := Rect2(Vector2(i * 6.5, 1 if tall else 2), Vector2(5, 6 if tall else 4))
			draw_rect(r.grow(1), UIKit.INK)
			if on:
				var c := UIKit.RED.lerp(UIKit.GOLD, float(i) / 19.0)
				if i == shown - 1:
					c = c.lerp(UIKit.WHITE, 0.4 + 0.3 * sin(t * 6.0))
				draw_rect(r, c)
				draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c.lightened(0.35))
			else:
				draw_rect(r, Color(0.18, 0.09, 0.22))

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
	## Mapa del Estrato como carta astral: salas con losas y relieve, muros, pozos, niebla sobre lo
	## inexplorado, rótulos en placas, iconos, rosa de los vientos y leyenda.
	var world: Node
	var t := 0.0
	const SC := 3.0
	const OFF := Vector2(150, -4)
	var _o := OFF
	var _stars: Array = []
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for k in 70:
			_stars.append([Vector2(rng.randf_range(140, size.x), rng.randf_range(0, size.y)), rng.randf_range(0.2, 0.7), rng.randf() * TAU])
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _str(p: Vector2, txt: String, col: Color, sz := 8, kind := "head") -> void:
		var f := UIKit.font(kind)
		f.draw_string_outline(get_canvas_item(), p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 3, UIKit.INK)
		f.draw_string(get_canvas_item(), p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	func _seen_bounds() -> Rect2:
		var b := Rect2()
		var first := true
		for r in world.ROOMS:
			if not Prog.flags.get("seen_" + r.id, false):
				continue
			var rc := Rect2(world._rect_of(r))
			b = rc if first else b.merge(rc)
			first = false
		return b
	func _draw() -> void:
		# --- fondo: carta astral (degradado, estrellas, la Espiral girando y viñeta)
		var area := Rect2(Vector2(144, 0), Vector2(size.x - 144, size.y))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.015, 0.06, 0.92))
		for k in 8:
			draw_rect(Rect2(Vector2(0, size.y * k / 8.0), Vector2(size.x, size.y / 8.0)), Color(0.25, 0.08, 0.3, 0.02 * k))
		var sc0 := area.get_center() + Vector2(0, 30)
		for k in 7:
			var rr2 := 30.0 + k * 22.0
			draw_arc(sc0, rr2, t * (0.05 + k * 0.01), t * (0.05 + k * 0.01) + PI * 1.4, 48, Color(0.75, 0.45, 0.85, 0.05), 1.0)
		for st in _stars:
			var sp: Vector2 = st[0]
			draw_rect(Rect2(sp, Vector2(1, 1)), Color(1, 0.95, 1.0, st[1] * (0.6 + 0.4 * sin(t * 1.5 + st[2]))))
		for gx in range(150, int(size.x), 24):
			draw_rect(Rect2(Vector2(gx, 0), Vector2(1, size.y)), Color(1, 1, 1, 0.018))
		for gy in range(0, int(size.y), 24):
			draw_rect(Rect2(Vector2(144, gy), Vector2(size.x - 144, 1)), Color(1, 1, 1, 0.018))
		# encuadre: centra lo explorado en el hueco de la derecha
		var sb := _seen_bounds()
		var tex: ImageTexture = world.map_texture_hd()
		_o = OFF
		if sb.size != Vector2.ZERO:
			var want := area.get_center() - sb.get_center() * SC
			var lo: float = area.position.x + 8.0 - sb.position.x * SC
			var hi: float = area.end.x - 8.0 - sb.end.x * SC
			want.x = clampf(want.x, minf(lo, hi), maxf(lo, hi))
			var lo2: float = 10.0 - sb.position.y * SC
			var hi2: float = size.y - 16.0 - sb.end.y * SC
			want.y = clampf(want.y, minf(lo2, hi2), maxf(lo2, hi2))
			_o = want.round()
		var cur: String = world.current_area()
		var full := Vector2(tex.get_width(), tex.get_height())
		# --- niebla sobre las salas vecinas sin explorar (rayado diagonal y "?")
		for r in world.ROOMS:
			if Prog.flags.get("seen_" + r.id, false):
				continue
			var rect: Rect2i = world._rect_of(r)
			var adj := false
			for r2 in world.ROOMS:
				if Prog.flags.get("seen_" + r2.id, false) and world._rect_of(r2).grow(1).intersects(rect):
					adj = true
			if adj:
				var rr := Rect2(_o + Vector2(rect.position) * SC, Vector2(rect.size) * SC)
				draw_rect(rr, Color(0.6, 0.5, 0.75, 0.05))
				var k2 := -rr.size.y
				while k2 < rr.size.x:
					var a0 := Vector2(maxf(k2, 0.0), maxf(-k2, 0.0))
					var a1 := Vector2(minf(k2 + rr.size.y, rr.size.x), minf(rr.size.x - k2, rr.size.y))
					draw_line(rr.position + a0, rr.position + a1, Color(0.75, 0.65, 0.9, 0.09), 1.0)
					k2 += 5.0
				draw_rect(rr, Color(0.75, 0.65, 0.9, 0.18 + 0.08 * sin(t * 2.0)), false, 1.0)
				_str(rr.get_center() - Vector2(3, -4), "?", Color(1, 1, 1, 0.35 + 0.2 * sin(t * 3.0)), 8)
		# --- salas: sombra, resplandor, grosor (extrusión) y el mapa detallado encima
		draw_texture_rect(tex, Rect2(_o + Vector2(5, 10), full), false, Color(0, 0, 0, 0.5))
		for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			draw_texture_rect(tex, Rect2(_o + d, full), false, Color(1, 0.85, 1.0, 0.07))
		for k in range(7, 0, -1):
			var ek := float(k) / 7.0
			draw_texture_rect(tex, Rect2(_o + Vector2(0, k), full), false, Color(0.3 - 0.2 * ek, 0.18 - 0.13 * ek, 0.26 - 0.18 * ek, 1.0))
		draw_texture_rect(tex, Rect2(_o, full), false)
		# zona actual: brillo pulsante sobre sus salas
		for r in world.ROOMS:
			if world.AREAS.get(r.id, "") == cur and Prog.flags.get("seen_" + r.id, false):
				var rcu := Rect2(_o + Vector2(world._rect_of(r).position) * SC, Vector2(world._rect_of(r).size) * SC)
				draw_rect(rcu, Color(1, 1, 1, 0.05 + 0.04 * sin(t * 4.0)))
		# marcadores
		var npc_labels := []
		for m in world.map_markers():
			var mp: Vector2 = (_o + m[1] * SC).round()
			var mc: Color = m[2]
			match m[0]:
				"brasa":
					draw_rect(Rect2(mp - Vector2(3, 4), Vector2(7, 8)), UIKit.INK)
					draw_colored_polygon(PackedVector2Array([mp + Vector2(0, -4), mp + Vector2(3, 2), mp + Vector2(-3, 2)]), mc)
					if mc == UIKit.GOLD:
						draw_rect(Rect2(mp + Vector2(-1, -1 - roundf(sin(t * 8.0))), Vector2(2, 2)), Color.WHITE)
				"npc":
					draw_circle(mp, 4.0, UIKit.INK)
					draw_circle(mp, 3.0, mc)
					draw_rect(Rect2(mp - Vector2(1, 1), Vector2(2, 2)), UIKit.INK)
				"chest":
					draw_rect(Rect2(mp - Vector2(3, 2), Vector2(7, 5)), UIKit.INK)
					draw_rect(Rect2(mp - Vector2(2, 1), Vector2(5, 3)), mc)
				"ecos":
					var pr := 3.0 + absf(sin(t * 5.0)) * 2.0
					UIKit.diamond(self, mp, pr + 1.0, UIKit.INK)
					UIKit.diamond(self, mp, pr, mc)
				"bench":
					draw_rect(Rect2(mp - Vector2(3, 1), Vector2(7, 3)), UIKit.INK)
					draw_rect(Rect2(mp - Vector2(2, 0), Vector2(5, 1)), mc)
				"boss", "boss_dead":
					var dead: bool = m[0] == "boss_dead"
					var bc := Color(0.45, 0.35, 0.4) if dead else mc
					var bp := 5.0 + (0.0 if dead else absf(sin(t * 3.0)))
					UIKit.diamond(self, mp, bp + 1.0, UIKit.INK)
					UIKit.diamond(self, mp, bp, bc)
					if dead:
						draw_line(mp + Vector2(-3, -3), mp + Vector2(3, 3), UIKit.INK, 2.0)
						draw_line(mp + Vector2(3, -3), mp + Vector2(-3, 3), UIKit.INK, 2.0)
					else:
						draw_arc(mp, 9.0 + fmod(t * 8.0, 6.0), 0, TAU, 16, Color(mc, 0.6 - fmod(t * 8.0, 6.0) / 10.0), 1.0)
				"trial", "trial_done":
					var done: bool = m[0] == "trial_done"
					var tcol := UIKit.GOLD if done else UIKit.RED.lerp(UIKit.PINK, 0.5 + 0.5 * sin(t * 5.0))
					draw_line(mp + Vector2(-4, -4), mp + Vector2(4, 4), UIKit.INK, 4.0)
					draw_line(mp + Vector2(4, -4), mp + Vector2(-4, 4), UIKit.INK, 4.0)
					draw_line(mp + Vector2(-4, -4), mp + Vector2(4, 4), tcol, 2.0)
					draw_line(mp + Vector2(4, -4), mp + Vector2(-4, 4), tcol, 2.0)
					if not done:
						draw_arc(mp, 7.0 + fmod(t * 6.0, 5.0), 0, TAU, 14, Color(tcol, 0.5 - fmod(t * 6.0, 5.0) / 10.0), 1.0)
				"lock":
					draw_rect(Rect2(mp - Vector2(4, 1), Vector2(8, 6)), UIKit.INK)
					draw_rect(Rect2(mp - Vector2(3, 0), Vector2(6, 4)), mc)
					draw_arc(mp + Vector2(0, -1), 3.0, PI, TAU, 8, UIKit.INK, 2.0)
				"lore":
					draw_rect(Rect2(mp - Vector2(2, 4), Vector2(5, 8)), UIKit.INK)
					draw_rect(Rect2(mp - Vector2(1, 3), Vector2(3, 6)), mc)
				"echo":
					# eco del pasado ya visto: fantasma pequeño
					var ga := 0.7 + 0.3 * sin(t * 3.0)
					draw_circle(mp + Vector2(0, -2), 4.0, UIKit.INK)
					draw_circle(mp + Vector2(0, -2), 3.0, Color(mc, ga))
					draw_colored_polygon(PackedVector2Array([mp + Vector2(-3, -2), mp + Vector2(3, -2), mp + Vector2(3, 3), mp + Vector2(1, 2), mp + Vector2(0, 4), mp + Vector2(-1, 2), mp + Vector2(-3, 3)]), Color(mc, ga))
					draw_rect(Rect2(mp + Vector2(-2, -3), Vector2(1, 1)), UIKit.INK)
					draw_rect(Rect2(mp + Vector2(1, -3), Vector2(1, 1)), UIKit.INK)
				"ally":
					draw_rect(Rect2(mp - Vector2(3, 3), Vector2(6, 6)), UIKit.INK)
					draw_rect(Rect2(mp - Vector2(2, 2), Vector2(4, 4)), mc)
					_str(mp + Vector2(6, 3), m[3], mc, 8)
		# jugador local con flecha de orientación
		var lp: Player = world.local_player()
		if lp:
			var pp: Vector2 = (_o + lp.global_position / 16.0 * SC).round()
			var pulse := 3.0 + 2.0 * absf(sin(t * 5.0))
			draw_arc(pp, pulse + 4, 0, TAU, 16, Color(1, 1, 1, 0.5), 1.0)
			var fd: Vector2 = lp.aim if lp.aim.length() > 0.1 else Vector2.DOWN
			var tip := pp + fd.normalized() * 7.0
			draw_colored_polygon(PackedVector2Array([tip, pp + fd.orthogonal() * 3.0, pp - fd.orthogonal() * 3.0]), UIKit.WHITE)
			draw_rect(Rect2(pp - Vector2(3, 3), Vector2(6, 6)), UIKit.INK)
			draw_rect(Rect2(pp - Vector2(2, 2), Vector2(4, 4)), UIKit.WHITE)
			var yt := G.T("you_are_here")
			var yw := UIKit.font("title").get_string_size(yt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			UIKit.slash_band(self, Rect2(pp + Vector2(-yw / 2.0 - 6, -24), Vector2(yw + 12, 12)), UIKit.RED, 3.0)
			_str(pp + Vector2(-yw / 2.0, -15), yt, UIKit.WHITE, 10, "title")
		# --- rótulos de zona en placas, encima de cada zona y sin pisar iconos
		var areas := {}
		for r in world.ROOMS:
			if not Prog.flags.get("seen_" + r.id, false):
				continue
			var a: String = world.AREAS.get(r.id, "")
			if a == "":
				continue
			var rc := Rect2(world._rect_of(r))
			if not areas.has(a):
				areas[a] = [rc, 0.0]
			else:
				areas[a][0] = (areas[a][0] as Rect2).merge(rc)
			areas[a][1] += rc.size.x * rc.size.y
		var lf := UIKit.font("title")
		var placed: Array[Rect2] = []
		var marks: Array[Rect2] = []
		var lp0: Player = world.local_player()
		if lp0:
			var pp0: Vector2 = (_o + lp0.global_position / 16.0 * SC).round()
			placed.append(Rect2(pp0 - Vector2(40, 26), Vector2(80, 34)))
		for m in world.map_markers():
			marks.append(Rect2((_o + m[1] * SC).round() - Vector2(6, 6), Vector2(12, 12)))
		var order: Array = areas.keys()
		order.sort_custom(func(x, y): return (1 if x == cur else 0) * 100000 + areas[x][1] > (1 if y == cur else 0) * 100000 + areas[y][1])
		for a in order:
			var ab: Rect2 = areas[a][0]
			var nm: String = G.T(a).to_upper()
			var w := lf.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var cands := [Vector2(ab.get_center().x, ab.position.y) * SC + _o + Vector2(0, -5),
				ab.get_center() * SC + _o,
				Vector2(ab.get_center().x, ab.end.y) * SC + _o + Vector2(0, 12),
				Vector2(ab.position.x * SC + _o.x - w / 2.0 - 6, ab.get_center().y * SC + _o.y),
				Vector2(ab.end.x * SC + _o.x + w / 2.0 + 6, ab.get_center().y * SC + _o.y),
				ab.get_center() * SC + _o + Vector2(0, 14), ab.get_center() * SC + _o + Vector2(0, -14)]
			var done := false
			for pass_i in 2:
				if done:
					break
				for cp in cands:
					var lr := Rect2(cp - Vector2(w / 2.0 + 5, 9), Vector2(w + 10, 13))
					if lr.position.x < 146.0 or lr.end.x > size.x - 2.0 or lr.position.y < 2.0 or lr.end.y > size.y - 2.0:
						continue
					var clash := false
					for q in placed:
						if q.intersects(lr):
							clash = true
					if pass_i == 0:
						for q2 in marks:
							if q2.intersects(lr):
								clash = true
					if not clash:
						cands = [cp]
						done = true
						break
			if not done:
				continue
			var col: Color = world.AREA_COLORS.get(a, Color.WHITE)
			if a == cur:
				col = col.lerp(Color.WHITE, 0.4 + 0.3 * sin(t * 4.0))
			for cp in cands:
				var lr := Rect2(cp - Vector2(w / 2.0 + 5, 9), Vector2(w + 10, 13))
				if lr.position.x < 146.0 or lr.end.x > size.x - 2.0 or lr.position.y < 2.0 or lr.end.y > size.y - 2.0:
					continue
				var clash := false
				for q in placed:
					if q.intersects(lr):
						clash = true
				if clash:
					continue
				placed.append(lr)
				UIKit.slash_band(self, Rect2(lr.position + Vector2(1, 1), lr.size), Color(0, 0, 0, 0.5), 3.0)
				UIKit.slash_band(self, lr, Color(0.07, 0.03, 0.1, 0.85), 3.0)
				draw_rect(Rect2(lr.position + Vector2(3, lr.size.y - 1), Vector2(lr.size.x - 6, 1)), Color(col, 0.8))
				_str((cp - Vector2(w / 2.0, -1)).round(), nm, col, 10, "title")
				break
		# --- rosa de los vientos (abajo a la derecha)
		var cr := Vector2(size.x - 26, size.y - 26)
		draw_arc(cr, 15.0, 0, TAU, 24, Color(1, 0.85, 0.5, 0.35), 1.0)
		draw_arc(cr, 11.0, 0, TAU, 24, Color(1, 0.85, 0.5, 0.2), 1.0)
		for q in 4:
			var dv := Vector2.from_angle(q * PI / 2.0 - PI / 2.0 + sin(t * 0.5) * 0.03)
			var colq := UIKit.RED if q == 0 else Color(1, 0.85, 0.5, 0.7)
			draw_colored_polygon(PackedVector2Array([cr + dv * 15.0, cr + dv.orthogonal() * 3.0, cr - dv.orthogonal() * 3.0]), colq)
		draw_circle(cr, 2.0, UIKit.GOLD)
		_str(cr + Vector2(-3, -18), "N", UIKit.WHITE, 8)
		# --- marco interior con esquinas doradas
		var fr := Rect2(Vector2(146, 2), Vector2(size.x - 148, size.y - 4))
		draw_rect(fr, Color(0.6, 0.4, 0.7, 0.25), false, 1.0)
		for cpt in [fr.position, Vector2(fr.end.x, fr.position.y), Vector2(fr.position.x, fr.end.y), fr.end]:
			var sx := 1.0 if cpt.x < size.x / 2.0 else -1.0
			var sy := 1.0 if cpt.y < size.y / 2.0 else -1.0
			draw_line(cpt, cpt + Vector2(10 * sx, 0), UIKit.GOLD_DARK, 2.0)
			draw_line(cpt, cpt + Vector2(0, 10 * sy), UIKit.GOLD_DARK, 2.0)
		# panel de leyenda (izquierda)
		UIKit.frame(self, Rect2(4, 4, 136, size.y - 8), UIKit.RED_DARK, Color(0.08, 0.03, 0.1, 0.85), 3.0, -1.0)
		var st_parts: PackedStringArray = G.T("stratum1").split(" - ")
		_str(Vector2(12, 16), st_parts[0], UIKit.GOLD, 8)
		if st_parts.size() > 1:
			_str(Vector2(12, 27), st_parts[1], UIKit.GOLD.darkened(0.15), 8)
		var ly := 40.0
		for a in world.AREA_COLORS:
			var seen_any: bool = areas.has(a)
			var nm2 := G.T(a).to_upper() if seen_any else "???"
			var ac: Color = world.AREA_COLORS[a] if seen_any else Color(0.3, 0.3, 0.3)
			if a == cur:
				UIKit.slash_band(self, Rect2(8, ly - 9, 128, 12), Color(UIKit.RED, 0.6), 3.0)
			draw_rect(Rect2(Vector2(12, ly - 6), Vector2(6, 6)), UIKit.INK)
			draw_rect(Rect2(Vector2(13, ly - 5), Vector2(4, 4)), ac)
			_str(Vector2(22, ly), nm2, UIKit.WHITE if seen_any else UIKit.TEXT_DIM, 10, "title")
			ly += 12.0
		ly += 5.0
		var legend := [["brasa", G.L(["Brasa", "Ember"])], ["npc", G.L(["Aliado", "Ally"])], ["boss", G.L(["Jefe", "Boss"])], ["trial", G.L(["Prueba", "Trial"])], ["echo", G.L(["Eco", "Echo"])],
			["lock", G.L(["Cerrado", "Sealed"])], ["chest", G.L(["Cofre", "Chest"])], ["ecos", G.L(["Ecos", "Echoes"])], ["lore", G.L(["Inscripción", "Inscription"])], ["you", G.L(["Tú", "You"])]]
		var ly0 := ly
		for li in legend.size():
			var lg: Array = legend[li]
			var colx := 0.0 if li < 5 else 66.0
			ly = ly0 + (li % 5) * 12.0
			var lp2 := Vector2(15 + colx, ly - 3)
			match lg[0]:
				"brasa": draw_colored_polygon(PackedVector2Array([lp2 + Vector2(0, -4), lp2 + Vector2(3, 2), lp2 + Vector2(-3, 2)]), UIKit.GOLD)
				"npc": draw_circle(lp2, 3.0, UIKit.CYAN)
				"boss": UIKit.diamond(self, lp2, 4.0, UIKit.RED)
				"chest": draw_rect(Rect2(lp2 - Vector2(2, 1), Vector2(5, 3)), UIKit.GOLD)
				"ecos": UIKit.diamond(self, lp2, 3.0, Color(0.5, 0.85, 1.0))
				"trial":
					draw_line(lp2 + Vector2(-3, -3), lp2 + Vector2(3, 3), UIKit.RED, 2.0)
					draw_line(lp2 + Vector2(3, -3), lp2 + Vector2(-3, 3), UIKit.RED, 2.0)
				"lock":
					draw_rect(Rect2(lp2 - Vector2(3, 0), Vector2(6, 4)), Color(0.75, 0.7, 0.8))
					draw_arc(lp2, 2.0, PI, TAU, 6, Color(0.75, 0.7, 0.8), 1.0)
				"lore": draw_rect(Rect2(lp2 - Vector2(1, 3), Vector2(3, 6)), Color(0.6, 0.85, 1.0))
				"echo":
					draw_circle(lp2 + Vector2(0, -1), 2.5, Color(0.6, 0.85, 1.0))
					draw_rect(Rect2(lp2 + Vector2(-2, -1), Vector2(5, 4)), Color(0.6, 0.85, 1.0))
				"you":
					draw_rect(Rect2(lp2 - Vector2(2, 2), Vector2(4, 4)), UIKit.WHITE)
			_str(Vector2(24 + colx, ly), lg[1], UIKit.TEXT_DIM, 10, "title")
		if Prog.item_count("map_carto") == 0:
			_str(Vector2(10, size.y - 12), G.L(["Sin cartografía: cofres ocultos", "No cartography: chests hidden"]), UIKit.PINK, 10, "title")


class CodexPortrait extends Control:
	## Retrato grande de una criatura del Códice (silueta si aún no la has derrotado)
	var sheet := ""
	var region := Rect2()
	var known := false
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.02, 0.07, 0.8))
		for i in 5:
			draw_arc(size / 2.0, 30.0 + i * 12.0, 0, TAU, 32, Color(0.6, 0.3, 0.5, 0.06), 1.0)
		var tex: Texture2D = Fx.tex(sheet)
		if tex == null:
			return
		var sc := floorf(minf(size.x / region.size.x, size.y / region.size.y) * 0.8)
		var ds := region.size * sc
		var bob := roundf(sin(_t * 2.0) * 2.0)
		var col := Color.WHITE if known else Color(0, 0, 0, 0.9)
		draw_texture_rect_region(tex, Rect2(size / 2.0 - ds / 2.0 + Vector2(0, bob), ds), region, col)
		if not known:
			var f := UIKit.font("logo")
			f.draw_string(get_canvas_item(), Vector2(size.x / 2.0 - 8, size.y / 2.0 + 14), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.7, 0.5, 0.8, 0.6))


class CodexBust extends Control:
	## Busto de PNJ en el Códice (en silueta si aún no lo conoces), con parpadeo
	var sheet := ""
	var known := false
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_t = randf() * 3.0
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		UIKit.frame(self, Rect2(Vector2.ZERO, size), UIKit.GOLD_DARK if known else UIKit.PURPLE, Color(0.12, 0.05, 0.16), 3.0)
		var fr := 2 if fmod(_t, 3.6) < 0.13 else 0
		var tex := Fx.tex(sheet)
		var dst := Rect2(Vector2(4, 4), Vector2(48, 48))
		if known:
			draw_texture_rect_region(tex, dst, Rect2(fr * 48, 0, 48, 48))
		else:
			draw_texture_rect_region(tex, dst, Rect2(0, 0, 48, 48), Color(0.05, 0.02, 0.08))


class PauseBust extends Control:
	## Busto de tu personaje en la ficha de pausa (con parpadeo)
	var _t := 0.0
	var _tex: Texture2D
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tex = Look.bust_texture(G.look, Prog.wing_feathers)
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		UIKit.frame(self, Rect2(Vector2.ZERO, size), UIKit.GOLD_DARK, Color(0.1, 0.04, 0.14), 3.0)
		var c := size / 2.0
		for i in 10:
			var a := TAU * i / 10.0 + _t * 0.3
			var d := Vector2.from_angle(a)
			draw_colored_polygon(PackedVector2Array([c + d * 18.0 + d.orthogonal() * 3.0, c + d * 46.0, c + d * 18.0 - d.orthogonal() * 3.0]), Color(1, 0.8, 0.4, 0.07))
		if _tex:
			var fr := 1 if fmod(_t, 3.5) < 0.12 else 0
			draw_texture_rect_region(_tex, Rect2(Vector2(4, 4), Vector2(80, 80)), Rect2(fr * 40, 0, 40, 40))


class QuestRow extends Control:
	## Entrada del diario: icono del tipo, título y barra de progreso fina
	var id := ""
	var menu: Node
	var selected := false
	var delay := 0.0
	var _t := 0.0
	var _hover := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_entered.connect(func(): _hover = true)
		mouse_exited.connect(func(): _hover = false)
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.2).set_delay(delay)
	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			menu._on_quest(id)
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var q: Dictionary = Prog.QUESTS[id]
		var done := Prog.quest_done(id)
		var col := UIKit.GOLD if q.type == "main" else (UIKit.PINK if q.type == "bounty" else UIKit.CYAN)
		if done:
			col = Color(0.5, 0.75, 0.55)
		var bg := Color(0.2, 0.08, 0.24) if selected else (Color(0.14, 0.06, 0.18) if _hover else Color(0.08, 0.03, 0.1, 0.8))
		UIKit.slash_band(self, Rect2(Vector2.ZERO, size), bg, 4.0)
		if selected:
			UIKit.slash_band(self, Rect2(Vector2.ZERO, Vector2(size.x, 1)), col, 4.0)
			draw_rect(Rect2(Vector2(size.x - 6, 6), Vector2(3, 8)), col)
		var ic := Vector2(12, 10)
		if done:
			draw_line(ic + Vector2(-4, 0), ic + Vector2(-1, 3), col, 2.0)
			draw_line(ic + Vector2(-1, 3), ic + Vector2(4, -4), col, 2.0)
		else:
			match str(q.type):
				"main":
					UIKit.diamond(self, ic, 5.0, UIKit.INK)
					UIKit.diamond(self, ic, 4.0, col.lerp(UIKit.WHITE, 0.25 + 0.25 * sin(_t * 4.0)))
				"bounty":
					draw_line(ic + Vector2(-4, -4), ic + Vector2(4, 4), col, 2.0)
					draw_line(ic + Vector2(4, -4), ic + Vector2(-4, 4), col, 2.0)
				_:
					draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -5), ic + Vector2(3, 0), ic + Vector2(0, 5), ic + Vector2(-3, 0)]), col)
		var f := UIKit.font("head")
		f.draw_string(get_canvas_item(), Vector2(24, 13), G.L(q.title).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 34, 8, col if not done else Color(0.55, 0.7, 0.6))
		# progreso fino bajo el título
		var p := 1.0 if done else 0.0
		var st: Dictionary = Prog.quests.get(id, {})
		if not done:
			if q.has("steps"):
				p = float(st.get("step", 0)) / q.steps.size()
			elif q.has("count"):
				p = float(st.get("progress", 0)) / q.count
		draw_rect(Rect2(Vector2(24, 16), Vector2(size.x - 40, 2)), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(Vector2(24, 16), Vector2((size.x - 40) * p, 2)), col)

class QuestDetail extends Control:
	## Hoja de la misión: cinta con el título, quién la encarga, pasos marcados y recompensas con icono
	var id := ""
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _draw() -> void:
		var q: Dictionary = Prog.QUESTS[id]
		var done := Prog.quest_done(id)
		var col := UIKit.GOLD if q.type == "main" else (UIKit.PINK if q.type == "bounty" else UIKit.CYAN)
		var hf := UIKit.font("head")
		var tf := UIKit.font("title")
		# cinta del título
		var title := G.L(q.title).to_upper()
		UIKit.slash_band(self, Rect2(Vector2(10, 10), Vector2(348, 18)), Color(0, 0, 0, 0.5), 6.0)
		UIKit.slash_band(self, Rect2(Vector2(8, 8), Vector2(348, 18)), col.darkened(0.55), 6.0)
		UIKit.slash_band(self, Rect2(Vector2(8, 8), Vector2(348, 2)), col, 6.0)
		hf.draw_string_outline(get_canvas_item(), Vector2(18, 21), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		hf.draw_string(get_canvas_item(), Vector2(18, 21), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
		var kind: String = {"main": G.L(["MISIÓN PRINCIPAL", "MAIN QUEST"]), "side": G.L(["ENCARGO", "ERRAND"]), "bounty": G.L(["CAZA", "HUNT"])}[str(q.type)]
		hf.draw_string(get_canvas_item(), Vector2(18, 40), kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
		# retrato de quien la encarga (o la orden grabada a fuego)
		var pr := Rect2(Vector2(14, 50), Vector2(52, 52))
		draw_rect(pr, Color(0.1, 0.04, 0.14))
		var giver := str(q.get("giver", ""))
		if giver != "" and ResourceLoader.exists("res://assets/sprites/bust_%s.png" % giver):
			var fr := 2 if fmod(_t, 3.3) < 0.13 else 0
			draw_texture_rect_region(Fx.tex("bust_" + giver), Rect2(pr.position + Vector2(2, 2), Vector2(48, 48)), Rect2(fr * 48, 0, 48, 48))
		else:
			# el ojo de la Voz: rayos dorados, iris rojo y un fallo de imagen de vez en cuando
			var c := pr.get_center()
			for k in 12:
				var a := TAU * k / 12.0 + _t * 0.4
				draw_line(c + Vector2.from_angle(a) * 14.0, c + Vector2.from_angle(a) * (21.0 + 2.0 * sin(_t * 3.0 + k)), Color(1, 0.8, 0.35, 0.5), 1.0)
			var eye := PackedVector2Array()
			for k in 17:
				var a2 := PI * k / 16.0
				eye.append(c + Vector2(-cos(a2) * 16.0, -sin(a2) * 8.0))
			for k in range(1, 16):
				var a3 := PI * k / 16.0
				eye.append(c + Vector2(cos(a3) * 16.0, sin(a3) * 8.0))
			draw_colored_polygon(eye, Color(0.95, 0.9, 0.82))
			var look := Vector2(sin(_t * 0.7) * 3.0, 0)
			draw_circle(c + look, 6.0, Color(0.85, 0.2, 0.25))
			draw_circle(c + look, 3.0, Color(0.08, 0.02, 0.06))
			draw_circle(c + look + Vector2(-1.5, -1.5), 1.0, Color(1, 1, 1))
			draw_polyline(eye + PackedVector2Array([eye[0]]), Color(0.5, 0.35, 0.2), 1.0)
			if fmod(_t, 2.7) < 0.15:
				for g in 3:
					draw_rect(Rect2(pr.position + Vector2(randf_range(0, 30), randf_range(10, 44)), Vector2(randf_range(10, 30), 2)), Color(1, 0.2, 0.3, 0.7))
		draw_rect(pr, col.darkened(0.2), false, 1.0)
		var gname: String = G.L(GIVERS[giver]) if GIVERS.has(giver) else G.L(["La Voz", "The Voice"])
		tf.draw_string(get_canvas_item(), Vector2(14, 112), gname, HORIZONTAL_ALIGNMENT_CENTER, 52, 10, UIKit.TEXT_DIM)
		# pasos: casillas marcadas
		var st: Dictionary = Prog.quests.get(id, {})
		if q.has("steps"):
			var cur: int = st.get("step", 0)
			var y := 124.0
			for k in q.steps.size():
				var done_k = done or k < cur
				var now_k = not done and k == cur
				var box := Rect2(Vector2(26, y + 1), Vector2(8, 8))
				draw_rect(box, Color(0.05, 0.02, 0.07))
				draw_rect(box, (Color(0.55, 0.85, 0.6) if done_k else (col if now_k else Color(0.35, 0.3, 0.4))), false, 1.0)
				if done_k:
					draw_line(box.position + Vector2(1, 4), box.position + Vector2(3, 7), Color(0.55, 0.95, 0.6), 2.0)
					draw_line(box.position + Vector2(3, 7), box.position + Vector2(8, 0), Color(0.55, 0.95, 0.6), 2.0)
				elif now_k:
					draw_rect(Rect2(box.position + Vector2(2, 2), Vector2(4, 4)), col.lerp(UIKit.WHITE, 0.3 + 0.3 * sin(_t * 5.0)))
					draw_line(Vector2(14, y + 5), Vector2(20, y + 5), col, 1.0)
				if k < q.steps.size() - 1:
					draw_line(Vector2(30, y + 10), Vector2(30, y + 16), Color(0.3, 0.25, 0.35), 1.0)
				y += 16.0
		elif q.has("count"):
			var n: int = st.get("progress", 0)
			if done:
				n = q.count
			var w := 300.0
			var seg = w / q.count
			for k in q.count:
				var r := Rect2(Vector2(20 + k * seg, 150), Vector2(seg - 3, 10))
				draw_rect(r, Color(0.05, 0.02, 0.07))
				if k < n:
					draw_rect(r.grow(-1), col)
					draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 2)), col.lerp(UIKit.WHITE, 0.4))
			hf.draw_string(get_canvas_item(), Vector2(20, 176), "%d / %d" % [n, q.count], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
		# recompensas con icono
		var r2: Dictionary = q.reward
		var chips := []
		if r2.get("ecos", 0) > 0: chips.append(["icon_eco", str(r2.ecos)])
		if r2.get("sp", 0) > 0: chips.append(["icon_arconte", "%d PH" % r2.sp])
		if r2.has("feathers"): chips.append(["icon_feather", "x%d" % r2.feathers])
		if r2.has("flask"): chips.append(["icon_flask", "+1"])
		if r2.has("free_upgrade"): chips.append(["icon_iron", "+1"])
		if r2.has("weapon"): chips.append(["icon_filo", G.L(Prog.WEAPONS[r2.weapon].name)])
		if r2.has("item"): chips.append(["icon_" + str(r2.item), G.L(Prog.ITEMS[r2.item].name) if Prog.ITEMS.has(r2.item) else ""])
		var cx := 14.0
		for ch in chips:
			var tw := tf.get_string_size(ch[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var cr := Rect2(Vector2(cx, 262), Vector2(tw + 26, 20))
			draw_rect(cr, Color(0.08, 0.03, 0.1))
			draw_rect(cr, col.darkened(0.3), false, 1.0)
			if ResourceLoader.exists("res://assets/sprites/%s.png" % ch[0]):
				draw_texture_rect(Fx.tex(ch[0]), Rect2(cr.position + Vector2(3, 2), Vector2(16, 16)), false)
			tf.draw_string(get_canvas_item(), cr.position + Vector2(21, 14), ch[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.WHITE)
			cx += cr.size.x + 6.0
		# sello de completada
		if done:
			draw_set_transform(Vector2(290, 70), -0.25, Vector2.ONE)
			draw_rect(Rect2(Vector2(-52, -14), Vector2(104, 28)), Color(0.55, 0.85, 0.6, 0.15))
			draw_rect(Rect2(Vector2(-52, -14), Vector2(104, 28)), Color(0.55, 0.95, 0.6, 0.8), false, 2.0)
			hf.draw_string(get_canvas_item(), Vector2(-46, 5), G.L(["COMPLETADA", "COMPLETED"]), HORIZONTAL_ALIGNMENT_CENTER, 92, 8, Color(0.6, 1.0, 0.65))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class EquipStrip extends Control:
	## Arma equipada y dos huecos de amuleto, en marcos con brillo
	var _t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
	func _slot(r: Rect2, col: Color) -> void:
		draw_rect(r.grow(1), UIKit.INK)
		draw_rect(r, Color(0.12, 0.05, 0.16))
		draw_rect(r, col, false, 1.0)
		draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), Color(col, 0.35))
	func _draw() -> void:
		# arma
		var wr := Rect2(Vector2(0, 2), Vector2(52, 30))
		_slot(wr, UIKit.GOLD_DARK)
		var wd: Dictionary = Prog.WEAPONS.get(Prog.equipped, {})
		if not wd.is_empty():
			var wt := Fx.tex("weapon_" + wd.sprite)
			if wt:
				var asp := float(wt.get_width()) / float(wt.get_height())
				var ww := minf(46.0, 26.0 * asp)
				var hh := ww / asp
				draw_texture_rect(wt, Rect2(wr.get_center() - Vector2(ww, hh) / 2.0, Vector2(ww, hh)), false)
			var lv: int = Prog.weapons.get(Prog.equipped, 0)
			if lv > 0:
				UIKit.font("head").draw_string(get_canvas_item(), wr.position + Vector2(3, wr.size.y - 3), "+%d" % lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)
		# amuletos
		for k in 2:
			var ar := Rect2(Vector2(58 + k * 27, 6), Vector2(24, 24))
			_slot(ar, UIKit.CYAN if Prog.amulets_eq[k] != "" else UIKit.PURPLE)
			var am: String = Prog.amulets_eq[k]
			if am != "":
				var it: Dictionary = Prog.ITEMS.get(am, {})
				var at := Fx.tex("icon_" + str(it.get("icon", am)))
				if at:
					var bob := roundf(sin(_t * 2.0 + k) * 1.0)
					draw_texture_rect(at, Rect2(ar.position + Vector2(4, 4 + bob), Vector2(16, 16)), false)
			else:
				draw_circle(ar.get_center(), 2.0, Color(0.4, 0.25, 0.5))


class KeyHints extends Control:
	## Dos columnas de acciones con su tecla en una pequeña tecla dibujada
	const ACTS := [["move", ["Moverse", "Move"]], ["attack", ["Atacar", "Attack"]], ["heavy", ["Cargado", "Heavy"]], ["dash", ["Esquivar", "Dash"]],
		["parry", ["Desviar", "Parry"]], ["heal", ["Curarse", "Heal"]], ["interact", ["Interactuar", "Interact"]], ["item", ["Objeto", "Item"]],
		["map", ["Mapa", "Map"]], ["menu", ["Menú", "Menu"]]]
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var hf := UIKit.font("head")
		var tf := UIKit.font("title")
		for i in ACTS.size():
			var a: Array = ACTS[i]
			var col := i / 5
			var row := i % 5
			var p := Vector2(col * 148, row * 20)
			var key: String = "WASD" if a[0] == "move" else G.key_label(a[0])
			key = key.replace("Clic izq", "LMB").replace("Clic der", "RMB").replace("Left click", "LMB").replace("Right click", "RMB")
			if key.length() > 8:
				key = key.left(8)
			var kw := maxf(16.0, hf.get_string_size(key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8)
			var kr := Rect2(p + Vector2(0, 1), Vector2(kw, 14))
			draw_rect(Rect2(kr.position + Vector2(0, 2), kr.size), UIKit.INK)
			draw_rect(kr, Color(0.24, 0.13, 0.3))
			draw_rect(Rect2(kr.position, Vector2(kr.size.x, 2)), Color(0.5, 0.34, 0.6))
			hf.draw_string(get_canvas_item(), kr.position + Vector2(4, 11), key.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.WHITE)
			tf.draw_string(get_canvas_item(), p + Vector2(kw + 6, 12), G.L(a[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.TEXT_DIM)


class LockedWeaponCard extends Control:
	## Arma que aún no tienes: silueta oscura y pista de dónde conseguirla
	var id := ""
	const HINTS := {"hammer": ["Derrota al Carcelero.", "Defeat the Jailer."], "choir": ["Silencia al Coro Hueco.", "Silence the Hollow Choir."],
		"seravel": ["Vence a la Guardiana de las Puertas.", "Defeat the Warden of the Gates."], "spear": ["Duerme en un cofre de la Galería Rota.", "It sleeps in a chest in the Broken Gallery."],
		"scythe": ["El Cartógrafo la da por limpiar el Pasillo.", "The Cartographer gives it for clearing the Hall."]}
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w: Dictionary = Prog.WEAPONS[id]
		UIKit.frame(self, Rect2(Vector2.ZERO, size), Color(0.22, 0.13, 0.26), Color(0.06, 0.03, 0.08, 0.9), 3.0, -1.0)
		draw_texture_rect(Fx.tex("weapon_" + w.sprite), Rect2(Vector2(6, 8), Vector2(64, 24)), false, Color(0.02, 0.01, 0.03, 0.95))
		var f := UIKit.font("title")
		f.draw_string(get_canvas_item(), Vector2(76, 18), "???", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.TEXT_DIM)
		f.draw_string(get_canvas_item(), Vector2(76, 32), G.L(HINTS.get(id, ["Sigue descendiendo.", "Keep descending."])), HORIZONTAL_ALIGNMENT_LEFT, size.x - 80, 10, Color(0.55, 0.45, 0.6))

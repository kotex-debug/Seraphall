extends RefCounted
## Capturas para la web (docs/img). No se exporta con el juego: solo la usan --autotest=webshots y webtitle.
## Con ventana de 1920x1080 cada píxel del juego son exactamente 3 de la imagen:
##   godot --path . --resolution 1920x1080 --audio-driver Dummy -- --autotest=webshots
## SERAPHALL_SHOTS indica la carpeta de salida.

var main: Node
var w
var out: String
var lp: Player

func _t(s: float) -> void:
	await main.get_tree().create_timer(s).timeout

func _shot(nm: String) -> void:
	await main._shot(out + "/" + nm + ".png")

## Sin bordes: con marco, Windows encoge la ventana a su área de trabajo y la escala deja de ser exacta
func _exact_size() -> void:
	var win: Window = main.get_window()
	win.borderless = true
	win.size = Vector2i(1920, 1080)
	win.position = Vector2i.ZERO
	await _t(0.3)
	print("WEB tamaño=", main.get_viewport().get_texture().get_size())

## La misma escena con la interfaz y sin ella
func _both(nm: String) -> void:
	await _shot(nm)
	w.hud.visible = false
	await main.get_tree().process_frame
	await _shot(nm + "_limpia")
	w.hud.visible = true

func _skip_dialogs(n := 12) -> void:
	for k in n:
		if w.dialog.is_open():
			w.dialog._advance()
		await _t(0.15)

func _keep_alive() -> void:
	lp.iframes = 9999.0
	lp.hp = Prog.max_hp()
	lp.stamina = 100.0

func _heal_enemies() -> void:
	for e in w.enemies_alive():
		e.hp = e.max_hp

func _nearest() -> Vector2:
	var best := Vector2.RIGHT
	var dist := 1e9
	for e in w.enemies_alive():
		var d: float = e.global_position.distance_to(lp.global_position)
		if d < dist and d > 1.0:
			dist = d
			best = (e.global_position - lp.global_position).normalized()
	return best

func _ready_to_act() -> void:
	lp.state = "move"
	lp.cutscene = false

func _fight(be: Enemy, pre: String, n: int) -> void:
	for k in n:
		_ready_to_act()
		var to: Vector2 = be.global_position - lp.global_position
		lp.aim = to.normalized()
		if to.length() > 95.0:
			lp.global_position = be.global_position - lp.aim * 95.0
		lp._start_attack()
		await _t(0.4)
		await _both(pre + "_%d" % k)
		await _t(0.5)

func _wait_boss(tp: String) -> Enemy:
	var be: Enemy = w._enemy_of(tp)
	var waited := 0.0
	while waited < 40.0 and not (be.active and not lp.cutscene and not w.dialog.is_open()):
		if w.dialog.is_open():
			w.dialog._advance()
		await _t(0.25)
		waited += 0.25
	await _t(1.0)
	return be

func _mate_near(mate: Player, dx: float) -> void:
	mate.position = lp.position + Vector2(dx, 26.0)
	mate.set("_net_pos", mate.position)

# ---------------------------------------------------------------------- mundo y combate
func run_world(p_main: Node, p_world, p_out: String) -> void:
	main = p_main
	w = p_world
	out = p_out
	await _exact_size()
	lp = w.local_player()
	main.get_tree().process_frame.connect(_keep_alive)
	Prog.level = 40
	Prog.attr.vigor = 20
	lp.refresh_stats(true)
	for fl in ["ab_lance", "ab_wrath", "ab_art", "ab_nova"]:
		Prog.flags[fl] = true
	for wid in Prog.WEAPONS:
		Prog.weapons[wid] = 5

	w._light_brasa("sanct")
	await _t(1.4)
	await _both("a_santuario")
	w._talk("brenna")
	await _t(0.6)
	await _shot("a_dialogo")
	while w.dialog.is_open():
		w.dialog._advance()
		await _t(0.2)
	w.menu.close()
	lp.respawn_at(w.tile_pos(34, 86.5))
	await _t(1.5)
	await _both("a_mirador")
	w._contemplate(w.interactables["bench_mirador"])
	await _t(1.2)
	await _shot("a_contemplar")
	while w._contemplating:
		await _t(0.2)

	# Artes de arma con enemigos reales alrededor
	lp.respawn_at(w.tile_pos(46, 62))
	await _t(1.0)
	_ready_to_act()
	lp.light = 60.0
	lp.aim = _nearest()
	lp._cast_lance()
	await _t(0.3)
	await _both("b_pluma_dorada")
	await _t(1.0)
	for wid2 in ["sword", "reaper", "seravel", "yunque", "mangual", "staff", "bow", "hammer", "verdugo", "astas", "corona", "scythe", "fists"]:
		_heal_enemies()
		Prog.equipped = wid2
		lp.art_cd = 0.0
		_ready_to_act()
		lp._update_weapon_sprite()
		lp.aim = _nearest()
		lp._cast_art()
		await _t(0.45)
		await _both("c_arte_%s" % wid2)
		await _t(0.9)
	Prog.equipped = "reaper"
	_ready_to_act()
	lp._update_weapon_sprite()
	lp.wrath = 100.0
	lp._cast_wrath()
	await _t(0.15)
	await _both("c_ira")
	await _t(1.2)

	# anuncio de habilidad
	w._reset_enemies(true)
	lp.respawn_at(w.tile_pos(49, 88))
	await _t(0.6)
	_ready_to_act()
	Prog.reveal_ability("wrath")
	await _t(1.0)
	await _shot("d_anuncio")
	await _t(5.0)
	_ready_to_act()

	# cooperativo: dos Desplumados
	lp.respawn_at(w.tile_pos(46, 62))
	var mate: Player = w._spawn_player(77, 2)
	mate.set_look(Look.defaults_p2(), 7)
	mate.iframes = 99999.0
	await _t(0.8)
	_mate_near(mate, 34.0)
	await _t(0.6)
	_ready_to_act()
	lp.aim = _nearest()
	lp._start_attack()
	await _t(0.3)
	await _both("e_coop")
	w._ping(Net.my_id(), lp.position + Vector2(70, -30))
	w._ping(77, lp.position + Vector2(-70, -20))
	await _t(0.7)
	await _both("e_coop_marcas")
	w.on_partner_revived(true)
	await _t(0.5)
	await _both("e_coop_alas")

	# presentaciones de jefe
	for kind in ["carcelero", "choir", "seravel"]:
		var cine: Node = preload("res://scripts/ui/boss_cinematic.gd").new()
		cine.setup(kind, 1)
		w.add_child(cine)
		var ended := [false]
		cine.finished.connect(func() -> void: ended[0] = true)
		var nf := 0
		while not ended[0] and nf < 16:
			await _t(1.0)
			await _shot("f_cine_%s_%02d" % [kind, nf])
			nf += 1
		while not ended[0]:
			await _t(0.3)
		Prog.flags["cine_" + kind] = true
		await _t(0.5)

	# Estrato I: el Carcelero, con Furia Final y Cataclismo
	var ca: Enemy = w._enemy_of("carcelero")
	w._reset_enemies(true)
	lp.respawn_at(w.tile_pos(49, 40))
	var waited := 0.0
	while w.active_boss != ca and waited < 30.0:
		if w.dialog.is_open():
			w.dialog._advance()
		await _t(0.25)
		waited += 0.25
	await _t(1.5)
	_mate_near(mate, -40.0)
	await _fight(ca, "g_carcelero", 3)
	w._server_damage(ca.idx, ca.max_hp * 0.8, Vector2.RIGHT, 0.0, false)
	await _t(0.8)
	ca.state = "chase"
	ca._cat_t = 0.0
	for k in 5:
		await _t(0.6)
		await _both("g_carcelero_cataclismo_%d" % k)
	await _t(4.0)
	w._server_damage(ca.idx, ca.max_hp * 2.0, Vector2.RIGHT, 0.0, false)
	await _t(4.0)
	await _skip_dialogs(20)
	await _t(1.0)

	# Seravel
	Prog.flags["carcelero_dead"] = true
	w.wflags["carcelero_dead"] = true
	w.set_gate(true)
	w.wflags["choir_dead"] = true
	Prog.flags["choir_dead"] = true
	lp.respawn_at(w.tile_pos(49, 22))
	var se: Enemy = await _wait_boss("seravel")
	_mate_near(mate, 40.0)
	await _fight(se, "h_seravel", 3)
	w._server_damage(se.idx, se.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
	await _t(1.8)
	await _fight(se, "h_seravel_f2", 4)
	w._server_damage(se.idx, se.max_hp * 2.0, Vector2.RIGHT, 0.0, false)
	await _t(4.5)
	await _skip_dialogs(20)
	await _t(1.5)
	w.wflags["seravel_dead"] = true

	# Estratos II a IV: sitios y Arcontes
	var stops := {2: [["llegada", Vector2(143.5, 86)], ["sendero", Vector2(140, 62)], ["nidos", Vector2(111, 62)], ["arboleda", Vector2(140, 39)]],
		3: [["llegada", Vector2(239.5, 86)], ["crisoles", Vector2(240, 60)], ["biblio", Vector2(205, 57)], ["fragua", Vector2(240, 33)]],
		4: [["llegada", Vector2(335.5, 86)], ["jardin", Vector2(336, 61)], ["corte", Vector2(302, 55)], ["escalera", Vector2(336, 35)]]}
	var boss_of := {2: ["orrun", Vector2(141, 16)], 3: ["vulkaris", Vector2(240, 16)], 4: ["azrahel", Vector2(336, 18)]}
	for stn: int in [2, 3, 4]:
		w._descend(stn)
		await _t(2.6)
		for st0: Array in stops[stn]:
			lp.respawn_at(w.tile_pos(st0[1].x, st0[1].y))
			await _t(1.4)
			await _skip_dialogs()
			await _both("s%d_%s" % [stn, st0[0]])
		w._reset_enemies(true)
		var bo: Array = boss_of[stn]
		lp.respawn_at(w.tile_pos(bo[1].x, bo[1].y))
		await _t(1.0)
		var be: Enemy = await _wait_boss(bo[0])
		_mate_near(mate, 40.0)
		await _fight(be, "s%d_arconte" % stn, 4)
		w._server_damage(be.idx, be.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
		await _t(1.8)
		await _fight(be, "s%d_arconte_f2" % stn, 4)
		if stn == 4:
			w._server_damage(be.idx, be.max_hp * 0.25, Vector2.RIGHT, 0.0, false)
			await _t(2.2)
			await _fight(be, "s4_arconte_f3", 5)
			break
		w._server_damage(be.idx, be.max_hp * 2.0, Vector2.RIGHT, 0.0, false)
		await _t(4.5)
		await _skip_dialogs(20)
		await _t(3.0)

	# menús con una partida avanzada
	w.active_boss = null
	Prog.ecos = 90000
	Prog.feathers = 40
	Prog.skill_points = 40
	Prog.add_item("iron", 9, true)
	Prog.add_item("tear", 9, true)
	for fl2 in ["carcelero_dead", "choir_dead", "seravel_dead", "orrun_dead", "vulkaris_dead"]:
		Prog.flags[fl2] = true
	for sk in ["f1", "f2", "f3", "f4", "f5", "f6", "f7", "f11", "a1", "a2", "p1", "p3", "k1", "k2", "l1", "l2"]:
		Prog.unlock(sk)
	w.menu.open("skills", {"brasa": true})
	await _t(0.5)
	await _shot("m_arbol_filo")
	for br in ["pluma", "arconte", "luz"]:
		w.menu._on_branch(br)
		await _t(0.35)
		await _shot("m_arbol_%s" % br)
	w.menu.tab = "weapons"
	w.menu.ctx = {"forge": true}
	w.menu._sel_weapon = "reaper"
	w.menu._weapon_page = 1
	w.menu._rebuild()
	await _t(0.5)
	await _shot("m_armas")
	for tb in ["char", "quests", "ach", "map", "codex"]:
		w.menu.tab = tb
		w.menu.ctx = {}
		w.menu._rebuild()
		await _t(0.5)
		await _shot("m_%s" % tb)
	print("AUTOTEST_WEBSHOTS_OK")
	main.get_tree().quit()

# ---------------------------------------------------------------------- portada y menús previos
func run_title(p_main: Node, p_out: String) -> void:
	main = p_main
	out = p_out
	await _exact_size()
	G.look = Look.sane({})
	main._build_title()
	var title: Control = main.title
	title._skip_intro()
	await _t(0.8)
	title.show_main_menu()
	await _t(2.5)
	await _shot("t_menu")
	if is_instance_valid(title._save_card):
		title._save_card.queue_free()
	for c: CanvasItem in [title.menu_box, title.footer, title.press]:
		c.visible = false
	await _t(0.2)
	await _shot("t_logo_fondo")
	title.title_box.visible = false
	await _t(0.2)
	await _shot("t_fondo")
	# logo solo, con fondo transparente
	title.title_box.visible = true
	title.logo.wave = 0.0
	for c2 in title.get_children():
		if c2 != title.title_box and c2 is CanvasItem:
			c2.visible = false
	main.get_viewport().transparent_bg = true
	await _t(0.3)
	await _shot("t_logo")
	main.get_viewport().transparent_bg = false
	for c3 in title.get_children():
		if c3 is CanvasItem:
			c3.visible = true
	for c4: CanvasItem in [title.menu_box, title.footer, title.press]:
		c4.visible = true
	main._open_new_game("new")
	await _t(1.2)
	await _shot("t_dificultad")
	var ng: Control = main.title_layer.get_child(main.title_layer.get_child_count() - 1)
	ng._confirm_diff()
	ng.look = Look.sane({"body": "f", "hair": 1, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": "Aurel"})
	ng._name_edit.text = "Aurel"
	ng._refresh_preview()
	ng.row_sel = 7
	await _t(1.4)
	await _shot("t_creador")
	print("AUTOTEST_WEBTITLE_OK")
	main.get_tree().quit()

# ---------------------------------------------------------------------- Artes de arma con enemigos alrededor
const ART_PLAN := [[1, Vector2(46, 62), ["hueco", "acolito", "penitente", "guardia", "bestia"], ["sword", "spear", "mangual", "reaper", "verdugo"]],
	[2, Vector2(140, 62), ["musgoso", "nidal", "espino", "garza", "musgoso"], ["astas", "bow", "scythe", "staff"]],
	[3, Vector2(240, 60), ["ascua", "fundidor", "chispero", "forjador", "ascua"], ["yunque", "hammer", "fists"]],
	[4, Vector2(336, 61), ["cortesano", "caballero", "doncella", "sabueso", "cortesano"], ["corona", "seravel", "choir"]]]

func _ring_of(types: Array, center: Vector2, radius: float) -> void:
	for i in types.size():
		w._spawn_trial_enemy(types[i], center + Vector2.from_angle(TAU * i / types.size() + 0.5) * radius)

func run_arts(p_main: Node, p_world, p_out: String) -> void:
	main = p_main
	w = p_world
	out = p_out
	await _exact_size()
	lp = w.local_player()
	main.get_tree().process_frame.connect(_keep_alive)
	Ach._layer.visible = false
	w.hud.visible = false
	G.combat_mode = 1
	Prog.level = 40
	Prog.attr.vigor = 20
	lp.refresh_stats(true)
	for fl in ["ab_lance", "ab_wrath", "ab_art", "ab_nova"]:
		Prog.flags[fl] = true
	for wid in Prog.WEAPONS:
		Prog.weapons[wid] = 5
	w.wflags["seravel_dead"] = true
	for st: Array in ART_PLAN:
		if st[0] > 1:
			w._descend(st[0])
			await _t(3.0)
			await _skip_dialogs(6)
		for wid2: String in st[3]:
			w._reset_enemies(true)
			w._trial_reset()
			lp.respawn_at(w.tile_pos(st[1].x, st[1].y))
			await _t(0.5)
			w.hud.visible = false
			Prog.equipped = wid2
			lp._update_weapon_sprite()
			_ring_of(st[2], lp.global_position, 52.0)
			await _t(0.7)
			lp.art_cd = 0.0
			_ready_to_act()
			lp.aim = _nearest()
			lp._cast_art()
			await _t(0.3)
			await _shot("x_%s_a" % wid2)
			await _t(0.35)
			await _shot("x_%s_b" % wid2)
			await _t(0.6)
			await _skip_dialogs(2)
	print("AUTOTEST_WEBARTS_OK")
	main.get_tree().quit()

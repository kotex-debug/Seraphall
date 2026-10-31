extends Node
## Raíz del juego: pantalla de título, creación/unión de partidas y carga del mundo.

var title: Control
var title_layer: CanvasLayer
var world: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Net.connected_ok.connect(_on_connected)
	Net.connect_failed.connect(_on_connect_failed)
	Net.upnp_done.connect(_on_upnp_done)
	G.language_changed.connect(_rebuild_title)
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
			await get_tree().create_timer(1.2).timeout
			await _shot(OS.get_environment("SERAPHALL_SHOTS") + "/00a_titulo_intro.png")
			await get_tree().create_timer(2.5).timeout
			await _shot(OS.get_environment("SERAPHALL_SHOTS") + "/00b_titulo.png")
			print("SKY rect ", title.sky.get_global_rect(), " title rect ", title.get_global_rect(), " mat ", title.sky.material)
			_on_title_action("join_menu", "")
			await get_tree().create_timer(0.6).timeout
			await _shot(OS.get_environment("SERAPHALL_SHOTS") + "/00c_unirse.png")
			get_tree().quit()
		_:
			Prog.reset()
			start_game("new")

func _rebuild_title() -> void:
	if title and is_instance_valid(title) and world == null:
		_build_title()
		title._skip_intro()

# ====================================================================== título
func _build_title() -> void:
	if world:
		return
	if title_layer:
		title_layer.queue_free()
	title_layer = CanvasLayer.new()
	add_child(title_layer)
	title = preload("res://scripts/ui/title_screen.gd").new()
	title.main = self
	title.action.connect(_on_title_action)
	title_layer.add_child(title)
	Audio.play_music("theme")

func _on_title_action(act: String, arg: String) -> void:
	match act:
		"continue":
			Prog.load_game()
			Net.close()
			_transition_to_game("continue")
		"new":
			Prog.reset()
			Net.close()
			_transition_to_game("new")
		"host":
			if Net.host() != OK:
				title.toast(G.T("conn_failed"))
				return
			title.show_panel("host")
		"host_start":
			if Prog.has_save():
				Prog.load_game()
			else:
				Prog.reset()
			_transition_to_game("continue" if Prog.has_save() else "new")
		"copy":
			var c := Net.online_code()
			if c == "":
				c = Net.lan_code()
			DisplayServer.clipboard_set(c)
			title.toast(G.L(["Código copiado", "Code copied"]) + ": " + c)
		"join_menu":
			title.show_panel("join")
		"join":
			var err := Net.join(arg)
			title.set_status(G.T("connecting") if err == OK else G.T("conn_failed"))
		"lang":
			G.toggle_language()
		"back":
			Net.close()
			title.show_main_menu()
		"quit":
			get_tree().quit()

func _transition_to_game(mode: String) -> void:
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(fade)
	Audio.stop_music(0.8)
	var tw := fade.create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.7)
	tw.tween_callback(start_game.bind(mode))

func _on_upnp_done(ok: bool, _ip: String) -> void:
	if title and is_instance_valid(title):
		title.set_online_code(Net.online_code(), ok)

func _on_connected() -> void:
	# el cliente usa su propio personaje guardado (o uno nuevo)
	if not Prog.load_game():
		Prog.reset()
	start_game("client")

func _on_connect_failed() -> void:
	if title and is_instance_valid(title):
		title.set_status(G.T("conn_failed"))

func _toast_title(text: String) -> void:
	if title and is_instance_valid(title):
		title.toast(text)

# ====================================================================== partida
func start_game(mode: String) -> void:
	if title_layer:
		title_layer.queue_free()
		title_layer = null
	title = null
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
		"shots2":
			var lp: Player = w.local_player()
			await get_tree().create_timer(2.5).timeout
			await _shot(out + "/s01_hud.png")
			w._talk("brenna")
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/s02_dialogo.png")
			while w.dialog.is_open():
				await get_tree().create_timer(0.2).timeout
			w.menu.close()
			# mirador
			lp.respawn_at(w.tile_pos(34, 86.5))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/s03_mirador.png")
			w._contemplate(w.interactables["bench_mirador"])
			await get_tree().create_timer(0.8).timeout
			await _shot(out + "/s04_contemplar.png")
			while w._contemplating:
				await get_tree().create_timer(0.2).timeout
			# combate
			lp.respawn_at(w.tile_pos(44, 63))
			await get_tree().create_timer(1.2).timeout
			for i in 4:
				lp.aim = (w.enemies[1].global_position - lp.global_position).normalized()
				lp._start_attack()
				await get_tree().create_timer(0.1).timeout
				if i == 2:
					await _shot(out + "/s05_combate.png")
				await get_tree().create_timer(0.2).timeout
			lp.state = "move"
			w.throw_bomb(lp.global_position, lp.global_position + Vector2(40, -10), Net.my_id())
			await get_tree().create_timer(0.56).timeout
			await _shot(out + "/s06_bomba.png")
			await get_tree().create_timer(0.6).timeout
			lp.wrath = 100.0
			lp.state = "move"
			lp._cast_wrath()
			await get_tree().create_timer(0.12).timeout
			await _shot(out + "/s07_ira.png")
			await get_tree().create_timer(1.0).timeout
			# cinemática del Carcelero
			var cine := preload("res://scripts/ui/boss_cinematic.gd").new()
			cine.setup("carcelero", 1)
			w.add_child(cine)
			for k in [1.5, 4.6, 7.9]:
				await get_tree().create_timer(k - (0.0 if k == 1.5 else (1.5 if k == 4.6 else 4.6)), true, false, true).timeout
				await _shot(out + "/s08_cine_carcelero_%d.png" % int(k))
			await cine.finished
			var cine2 := preload("res://scripts/ui/boss_cinematic.gd").new()
			cine2.setup("seravel", 1)
			w.add_child(cine2)
			for k in [1.5, 4.8, 8.4]:
				await get_tree().create_timer(k - (0.0 if k == 1.5 else (1.5 if k == 4.8 else 4.8)), true, false, true).timeout
				await _shot(out + "/s09_cine_seravel_%d.png" % int(k))
			await cine2.finished
			# menús
			Prog.ecos = 2400
			Prog.skill_points = 6
			Prog.unlock("f1"); Prog.unlock("a1"); Prog.unlock("l1"); Prog.unlock("l2"); Prog.unlock("f2")
			Prog.add_item("amulet_wing", 1, true); Prog.add_item("ointment", 2, true); Prog.add_item("iron", 1, true)
			Prog.equip_amulet("amulet_wing")
			for tb in ["char", "skills", "inventory", "weapons", "quests", "map"]:
				w.menu.open(tb, {"brasa": true, "forge": true})
				await get_tree().create_timer(0.7).timeout
				await _shot(out + "/s10_menu_%s.png" % tb)
				w.menu.close()
			print("AUTOTEST_SHOTS2_OK")
			get_tree().quit()
		"menus":
			Prog.ecos = 2400
			Prog.skill_points = 6
			Prog.unlock("f1"); Prog.unlock("a1"); Prog.unlock("l1"); Prog.unlock("l2"); Prog.unlock("f2")
			Prog.add_item("amulet_wing", 1, true); Prog.add_item("ointment", 2, true); Prog.add_item("iron", 1, true)
			Prog.equip_amulet("amulet_wing")
			Prog.flags["seen_sanct"] = true; Prog.flags["seen_chains"] = true; Prog.flags["seen_hall1"] = true; Prog.flags["seen_mirador"] = true
			await get_tree().create_timer(1.0).timeout
			for tb in ["char", "skills", "inventory", "weapons", "quests", "map", "options"]:
				w.menu.open(tb, {"brasa": true, "forge": true})
				await get_tree().create_timer(0.8).timeout
				await _shot(out + "/m_%s.png" % tb)
				w.menu.close()
			print("AUTOTEST_MENUS_OK")
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

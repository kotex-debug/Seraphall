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
		"newgame":
			var sd := OS.get_environment("SERAPHALL_SHOTS")
			_build_title()
			await get_tree().create_timer(0.5).timeout
			title._skip_intro()
			await get_tree().create_timer(1.0).timeout
			_on_title_action("new", "")
			await get_tree().create_timer(0.8).timeout
			await _shot(sd + "/n01_dificultad.png")
			var ng: Control = title_layer.get_child(title_layer.get_child_count() - 1)
			ng.diff_sel = 0
			await get_tree().create_timer(0.5).timeout
			await _shot(sd + "/n02_ala_ligera.png")
			ng.diff_sel = 2
			ng._confirm_diff()
			await get_tree().create_timer(0.8).timeout
			await _shot(sd + "/n03_creador_chica.png")
			ng.look = Look.sane({"body": "f", "hair": 1, "hair_col": 3, "skin": 2, "eye": 3, "cloak": 2, "armor": 3, "wing": 3, "halo": 4})
			ng._refresh_preview()
			ng.row_sel = 2
			await get_tree().create_timer(1.6).timeout
			await _shot(sd + "/n04_creador_chica2.png")
			ng.look = Look.sane({"body": "m", "hair": 1, "hair_col": 1, "skin": 4, "eye": 1, "cloak": 1, "armor": 1, "wing": 1, "halo": 1, "name": "Kael"})
			ng._name_edit.text = "Kael"
			ng._refresh_preview()
			ng._anim_t = 3.2
			await get_tree().create_timer(0.9).timeout
			await _shot(sd + "/n05_creador_chico.png")
			ng._finish()
			while world == null:
				await get_tree().create_timer(0.3).timeout
			await get_tree().create_timer(7.0).timeout
			await _shot(sd + "/n06_inicio.png")
			world.local_player().respawn_at(world.tile_pos(54, 62))
			world.camera.position = world.local_player().position
			await get_tree().create_timer(1.5).timeout
			await _shot(sd + "/n07_pozo.png")
			world.local_player().respawn_at(world.tile_pos(64, 88))
			await get_tree().create_timer(1.5).timeout
			await _shot(sd + "/n08_pnj.png")
			world.menu.open("controls", {})
			await get_tree().create_timer(0.5).timeout
			await _shot(sd + "/n09_controles.png")
			print("NEWGAME look=", G.look, " diff=", Prog.difficulty)
			get_tree().quit()
		"promo_title":
			var sd := OS.get_environment("SERAPHALL_SHOTS")
			G.look = Look.sane({})
			_build_title()
			await get_tree().create_timer(5.0).timeout
			await _shot(sd + "/p01_titulo.png")
			_on_title_action("new", "")
			await get_tree().create_timer(0.6).timeout
			var ng: Control = title_layer.get_child(title_layer.get_child_count() - 1)
			await get_tree().create_timer(0.6).timeout
			await _shot(sd + "/p02_descenso.png")
			ng._confirm_diff()
			ng.look = Look.sane({"body": "f", "hair": 1, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": "Aurel"})
			ng._name_edit.text = "Aurel"
			ng._refresh_preview()
			ng.row_sel = 7
			await get_tree().create_timer(1.4).timeout
			await _shot(sd + "/p03_creador.png")
			get_tree().quit()
		"film":
			var sd2 := OS.get_environment("SERAPHALL_SHOTS")
			G.look = Look.sane({"body": "f", "hair": 1})
			var film := preload("res://scripts/ui/intro_film.gd").new()
			add_child(film)
			await get_tree().create_timer(1.0).timeout
			for k in film.SCENES.size():
				film.debug_seek(k, 0.72 if k != 4 else 0.7)
				await get_tree().create_timer(0.35).timeout
				await _shot(sd2 + "/f%02d.png" % k)
			get_tree().quit()
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
			Net.close()
			_open_new_game("new")
		"host":
			if Net.host() != OK:
				title.toast(G.T("conn_failed"))
				return
			title.show_panel("host")
		"host_start":
			if Prog.has_save():
				Prog.load_game()
				_transition_to_game("continue")
			else:
				_open_new_game("host")
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
		"fullscreen":
			G.toggle_fullscreen()
		"back":
			Net.close()
			title.show_main_menu()
		"quit":
			get_tree().quit()

func _open_new_game(mode: String) -> void:
	var ng := preload("res://scripts/ui/new_game.gd").new()
	ng.finished.connect(_on_new_game_done.bind(mode))
	ng.cancelled.connect(_on_new_game_cancel.bind(mode))
	if title and is_instance_valid(title):
		title._clear_menu()
	title_layer.add_child(ng)

func _on_new_game_done(difficulty: int, look: Dictionary, mode: String) -> void:
	G.look = look
	G.save_settings()
	Prog.reset()
	Prog.difficulty = difficulty
	if mode == "new":
		Net.close()
	# corto de introducción y, después, la pregunta del prólogo
	var film := preload("res://scripts/ui/intro_film.gd").new()
	film.finished.connect(_ask_prologue)
	add_child(film)

func _ask_prologue() -> void:
	var ask := PrologueAsk.new()
	ask.chosen.connect(_on_prologue_chosen)
	if title_layer:
		title_layer.add_child(ask)
	else:
		_on_prologue_chosen(false)

func _on_prologue_chosen(play: bool) -> void:
	G.set_meta("prologue", play)
	_transition_to_game("new")

class PrologueAsk extends Control:
	## ¿Jugar el prólogo? (aprender los controles antes del Carcelero)
	signal chosen(play: bool)
	var t := 0.0
	func _ready() -> void:
		size = Vector2(640, 360)
		var bg := ColorRect.new()
		bg.color = Color(0.03, 0.01, 0.05, 0.94)
		bg.size = size
		add_child(bg)
		var title := UIKit.label(G.L(["¿JUGAR EL PRÓLOGO?", "PLAY THE PROLOGUE?"]), 24, UIKit.WHITE, "logo", 6)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.size = Vector2(640, 30)
		title.position = Vector2(0, 112)
		add_child(title)
		var d := UIKit.label(G.L(["Un recorrido guiado por el Santuario para aprender a moverte, combatir, curarte y usar el menú y el mapa antes de enfrentarte al Carcelero.",
			"A guided walk through the Sanctuary to learn how to move, fight, heal and use the menu and map before facing the Jailer."]), 15, UIKit.TEXT_DIM)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.position = Vector2(120, 150)
		d.size = Vector2(400, 40)
		add_child(d)
		var row := HBoxContainer.new()
		row.position = Vector2(170, 214)
		row.add_theme_constant_override("separation", 20)
		add_child(row)
		for opt in [[G.L(["JUGAR EL PRÓLOGO", "PLAY PROLOGUE"]), true], [G.L(["SALTARLO", "SKIP IT"]), false]]:
			var b := Button.new()
			b.text = opt[0]
			b.theme = UIKit.button_theme(8)
			b.custom_minimum_size = Vector2(130, 22)
			b.pressed.connect(_pick.bind(opt[1]))
			UIKit.juicy(b)
			row.add_child(b)
		row.get_child(0).grab_focus.call_deferred()
		if G.autotest != "":
			_pick.call_deferred(true)
	func _pick(v: bool) -> void:
		Audio.sfx("ui_ok", -6.0)
		chosen.emit(v)
		queue_free()

func _on_new_game_cancel(mode: String) -> void:
	if mode == "host":
		Net.close()
	if title and is_instance_valid(title):
		title.show_main_menu()

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

func _promo_clean(w: Node) -> void:
	for c in w.hud.toast_box.get_children():
		c.queue_free()
	for c2 in w.hud.big_layer.get_children():
		c2.queue_free()

func reload_continue() -> void:
	await back_to_title("")
	Prog.load_game()
	_transition_to_game("continue")

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
		"promo":
			var lp: Player = w.local_player()
			G.look = Look.sane({"body": "f", "hair": 1, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": "Aurel"})
			w.send_look()
			Prog.level = 14
			Prog.weapons = {"sword": 6, "seravel": 3, "choir": 2, "scythe": 4}
			Prog.equipped = "seravel"
			Prog.infusions = {"seravel": "brasa"}
			for sk in ["f1", "f2", "f3", "a1", "a2", "l1", "l2", "l4", "c1", "c2"]:
				Prog.skills[sk] = true
			Prog.spark = true
			Prog.wing_feathers = 8
			for rid in ["sanct", "hall1", "chains", "hall2", "east", "gallery", "yard", "nim_link", "nimbo", "mirador", "mir_link"]:
				Prog.flags["seen_" + rid] = true
			lp.refresh_stats(true)
			lp._update_weapon_sprite()
			w._light_brasa("sanct")
			# compañero de cooperativo (marioneta para la foto)
			var mate = w._spawn_player(424242, 2)
			mate.set_look({"body": "m", "hair": 1, "hair_col": 1, "skin": 3, "eye": 1, "cloak": 1, "armor": 1, "wing": 4, "halo": 1, "name": "Kael"}, 10)
			# 1. Santuario
			lp.respawn_at(w.tile_pos(49, 89))
			mate.position = lp.position + Vector2(22, 4); mate._net_pos = mate.position
			w.camera.zoom = Vector2(1.4, 1.4)
			await get_tree().create_timer(3.5).timeout
			_promo_clean(w)
			await _shot(out + "/p04_santuario.png")
			# 2. Sala del Nimbo
			lp.respawn_at(w.tile_pos(65, 89))
			mate.position = lp.position + Vector2(26, -2); mate._net_pos = mate.position
			await get_tree().create_timer(3.0).timeout
			_promo_clean(w)
			await _shot(out + "/p05_sala_del_nimbo.png")
			# 3. Combate cooperativo
			lp.respawn_at(w.tile_pos(44, 63))
			mate.position = lp.position + Vector2(-20, 14); mate._net_pos = mate.position
			await get_tree().create_timer(1.2).timeout
			for i in 5:
				lp.state = "move"
				lp.aim = (w.enemies[1].global_position - lp.global_position).normalized()
				lp._start_attack()
				await get_tree().create_timer(0.09 if i == 4 else 0.2).timeout
			_promo_clean(w)
			await _shot(out + "/p06_combate.png")
			await get_tree().create_timer(0.4).timeout
			lp.state = "move"
			lp.wrath = 100.0
			lp._cast_wrath()
			await get_tree().create_timer(0.4).timeout
			_promo_clean(w)
			await _shot(out + "/p07_ira_serafica.png")
			await get_tree().create_timer(1.2).timeout
			# 4. Cinemática de Seravel
			w.hud.visible = false
			lp.cutscene = true
			var cine := preload("res://scripts/ui/boss_cinematic.gd").new()
			cine.setup("seravel", 1)
			w.add_child(cine)
			await get_tree().create_timer(5.0, true, false, true).timeout
			await _shot(out + "/p08_seravel_despierta.png")
			await get_tree().create_timer(3.7, true, false, true).timeout
			await _shot(out + "/p09_seravel_nombre.png")
			await cine.finished
			var cine2 := preload("res://scripts/ui/boss_cinematic.gd").new()
			cine2.setup("choir", 1)
			w.add_child(cine2)
			await get_tree().create_timer(9.2, true, false, true).timeout
			await _shot(out + "/p10_coro_hueco.png")
			await cine2.finished
			lp.cutscene = false
			w.hud.visible = true
			# 5. Mirador (paz)
			lp.respawn_at(w.tile_pos(34, 86.5))
			mate.position = lp.position + Vector2(-16, 6); mate._net_pos = mate.position
			await get_tree().create_timer(1.5).timeout
			w._contemplate(w.interactables["bench_mirador"])
			await get_tree().create_timer(2.6).timeout
			_promo_clean(w)
			await _shot(out + "/p11_mirador.png")
			while w._contemplating:
				await get_tree().create_timer(0.2).timeout
			# 6. Lluvia de Ceniza en el Patio del Carcelero
			w.camera.zoom = Vector2(1.4, 1.4)
			w._world_event("ash", 40.0)
			lp.respawn_at(w.tile_pos(80, 60))
			mate.position = lp.position + Vector2(20, 6); mate._net_pos = mate.position
			await get_tree().create_timer(3.5).timeout
			_promo_clean(w)
			await _shot(out + "/p12_lluvia_de_ceniza.png")
			w._world_event_end()
			# 7. Combate contra Seravel
			Prog.flags["carcelero_dead"] = true
			w.wflags["carcelero_dead"] = true
			for e in w.enemies:
				if e.type == "carcelero":
					e.die()
			w.set_gate(true)
			w.camera.zoom = Vector2.ONE
			lp.respawn_at(w.tile_pos(49, 22))
			mate.position = lp.position + Vector2(24, 0); mate._net_pos = mate.position
			await get_tree().create_timer(12.0).timeout
			var boss: Enemy = w.active_boss
			if boss:
				w._server_damage(boss.idx, boss.max_hp * 0.55, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(3.5).timeout
			lp.hp = Prog.max_hp()
			if boss:
				lp.respawn_at(boss.global_position + Vector2(-50, 30))
			await get_tree().create_timer(0.6).timeout
			for i in 3:
				lp.state = "move"
				if boss:
					lp.aim = (boss.global_position - lp.global_position).normalized()
				lp._start_attack()
				await get_tree().create_timer(0.1 if i == 2 else 0.22).timeout
			_promo_clean(w)
			await _shot(out + "/p13_seravel_combate.png")
			await get_tree().create_timer(2.0).timeout
			await _shot(out + "/p14_seravel_fase2.png")
			print("AUTOTEST_PROMO_OK")
			get_tree().quit()
		"v7":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			var kill_trial := func():
				for e in w.enemies:
					if e.is_alive() and (e.get_meta("trial", false) or e.get_meta("extra", false)):
						w._server_damage(e.idx, 99999.0, Vector2.RIGHT, 0.0, false)
			# --- Celdas de Espera
			lp.respawn_at(w.tile_pos(35, 54))
			await get_tree().create_timer(1.0).timeout
			await _shot(out + "/a00_entrada_celdas.png")
			lp.respawn_at(w.tile_pos(30, 50))
			await get_tree().create_timer(2.6).timeout
			await _shot(out + "/a01_celdas_oleada1.png")
			for wv in 3:
				kill_trial.call()
				await get_tree().create_timer(2.4).timeout
				if wv == 1:
					await _shot(out + "/a02_celdas_oleada3.png")
			await get_tree().create_timer(1.2).timeout
			await _shot(out + "/a03_celdas_superada.png")
			print("V7 celdas=", w.trial_done("celdas"))
			lp.respawn_at(w.tile_pos(18.5, 50.5))
			await get_tree().create_timer(0.6).timeout
			w._talk("preso")
			await get_tree().create_timer(1.2).timeout
			await _shot(out + "/a04_tobias.png")
			for q in 6:
				if w.dialog.is_open():
					w.dialog._advance()
					await get_tree().create_timer(0.1).timeout
			# --- Atrio de las Voces
			lp.respawn_at(w.tile_pos(82, 53))
			await get_tree().create_timer(1.6).timeout
			await _shot(out + "/a05_atrio.png")
			for b in ["bell_2", "bell_1", "bell_0"]:
				w._ring_bell(b)
				await get_tree().create_timer(0.4).timeout
			await get_tree().create_timer(0.8).timeout
			await _shot(out + "/a06_atrio_fallo.png")
			kill_trial.call()
			for b2 in ["bell_0", "bell_1", "bell_2"]:
				w._ring_bell(b2)
				await get_tree().create_timer(0.4).timeout
			await get_tree().create_timer(1.0).timeout
			await _shot(out + "/a07_atrio_resuelto.png")
			print("V7 atrio=", w.trial_done("atrio"))
			# --- Escalinata y Antesala del Juicio
			Prog.flags["carcelero_dead"] = true; w.wflags["carcelero_dead"] = true
			w.set_gate(true, true)
			lp.respawn_at(w.tile_pos(63, 28))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/a08_escalinata.png")
			lp.respawn_at(w.tile_pos(69, 25))
			await get_tree().create_timer(2.6).timeout
			await _shot(out + "/a09_antesala.png")
			kill_trial.call()
			await get_tree().create_timer(2.6).timeout
			await _shot(out + "/a10_custodio.png")
			for e in w.enemies:
				if e.type == "custodio":
					w._server_damage(e.idx, e.max_hp * 0.35, Vector2.RIGHT, 30.0, false)
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/a11_custodio_golpe.png")
			kill_trial.call()
			await get_tree().create_timer(3.5).timeout
			await _shot(out + "/a12_juicio_abierto.png")
			print("V7 umbral=", w.trial_done("umbral"))
			# --- barras de jefe
			for bt in ["carcelero", "choir", "seravel"]:
				w.start_ascension(bt, 1)
				await get_tree().create_timer(0.9).timeout
				await _shot(out + "/b_%s_entrada.png" % bt)
				await get_tree().create_timer(3.0).timeout
				var bb: Enemy = w.active_boss
				if bb:
					w._server_damage(bb.idx, bb.max_hp * 0.55, Vector2.RIGHT, 10.0, false)
					await get_tree().create_timer(0.35).timeout
					await _shot(out + "/b_%s_fase.png" % bt)
				w._end_ascension(false)
				await get_tree().create_timer(5.0).timeout
			print("AUTOTEST_V7_OK")
			get_tree().quit()
		"promo7":
			# capturas promocionales de la ALFA 0.7 (1920x1080)
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			G.look = Look.sane({"body": "f", "hair": 1, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": "Aurel"})
			w.send_look()
			Prog.level = 14
			Prog.weapons = {"sword": 6, "seravel": 3, "choir": 2, "scythe": 4}
			Prog.equipped = "seravel"
			Prog.infusions = {"seravel": "brasa"}
			for sk in ["f1", "f2", "f3", "a1", "a2", "l1", "l2", "l4", "c1", "c2"]:
				Prog.skills[sk] = true
			Prog.grant_ability("lance"); Prog.grant_ability("wrath")
			Prog.wing_feathers = 8
			for rid in w.ROOMS:
				Prog.flags["seen_" + rid.id] = true
			Prog.add_item("map_carto", 1, true)
			lp.refresh_stats(true)
			lp._update_weapon_sprite()
			var mate = w._spawn_player(424242, 2)
			mate.set_look({"body": "m", "hair": 1, "hair_col": 1, "skin": 3, "eye": 1, "cloak": 1, "armor": 1, "wing": 4, "halo": 1, "name": "Kael"}, 10)
			mate.iframes = 9999.0
			w.camera.zoom = Vector2(1.35, 1.35)
			var kill_extra := func():
				for e in w.enemies:
					if e.is_alive() and e.get_meta("extra", false):
						w._server_damage(e.idx, 99999.0, Vector2.RIGHT, 0.0, false)
			# 1. Las Celdas se abren
			lp.respawn_at(w.tile_pos(27, 50.5))
			mate.position = lp.position + Vector2(-22, 6); mate._net_pos = mate.position
			await get_tree().create_timer(3.2).timeout
			for i in 3:
				lp.state = "move"
				lp.aim = Vector2(0, -1)
				lp._start_attack()
				await get_tree().create_timer(0.18).timeout
			_promo_clean(w)
			await _shot(out + "/q01_celdas.png")
			for wv in 3:
				kill_extra.call()
				await get_tree().create_timer(2.3).timeout
			await get_tree().create_timer(1.5).timeout
			# 2. Pozo de castigo con cadenas (3D)
			lp.respawn_at(w.tile_pos(30, 51))
			mate.position = lp.position + Vector2(18, 4); mate._net_pos = mate.position
			await get_tree().create_timer(2.0).timeout
			_promo_clean(w)
			await _shot(out + "/q02_pozo_cadenas.png")
			# 3. Atrio de las Voces
			lp.respawn_at(w.tile_pos(80.5, 52.6))
			mate.position = lp.position + Vector2(26, 2); mate._net_pos = mate.position
			for e in w.enemies:
				if e.type == "acolito" and w.room_at(e.global_position) == "atrio":
					e.position = w.tile_pos(86, 52)
			w._ring_bell("bell_0")
			await get_tree().create_timer(1.6).timeout
			_promo_clean(w)
			await _shot(out + "/q03_atrio.png")
			# 4. El Custodio del Umbral
			Prog.flags["carcelero_dead"] = true; w.wflags["carcelero_dead"] = true
			w.set_gate(true, true)
			lp.respawn_at(w.tile_pos(69, 25))
			await get_tree().create_timer(2.4).timeout
			kill_extra.call()
			await get_tree().create_timer(2.8).timeout
			lp.respawn_at(w.tile_pos(68, 15))
			mate.position = lp.position + Vector2(24, 4); mate._net_pos = mate.position
			for e in w.enemies:
				if e.type == "custodio":
					e.cooldown = 99.0
					e.position = w.tile_pos(69.5, 10.5); e._net_pos = e.position
					w._server_damage(e.idx, e.max_hp * 0.3, Vector2.UP, 20.0, false)
			await get_tree().create_timer(1.0).timeout
			for i in 3:
				lp.state = "move"
				lp.aim = Vector2(0.2, -1).normalized()
				lp._start_attack()
				await get_tree().create_timer(0.18).timeout
			_promo_clean(w)
			await _shot(out + "/q04_custodio.png")
			kill_extra.call()
			await get_tree().create_timer(3.5).timeout
			Prog.flags["carcelero_dead"] = false; w.wflags["carcelero_dead"] = false
			# 5. Jefes con barra épica y detalles 3D
			for bt in ["carcelero", "choir", "seravel"]:
				Prog.flags[bt + "_intro"] = true; w.wflags[bt + "_intro"] = true
				w.start_ascension(bt, 1)
				await get_tree().create_timer(5.5).timeout
				var bb: Enemy = w.active_boss
				if bb:
					bb.cooldown = 99.0
					lp.global_position = bb.global_position + Vector2(-60, 62)
					mate.position = bb.global_position + Vector2(56, 54); mate._net_pos = mate.position
					await get_tree().create_timer(0.4).timeout
					w._server_damage(bb.idx, bb.max_hp * (0.3 if bt != "seravel" else 0.56), Vector2.RIGHT, 10.0, false)
					var act: String = {"carcelero": "sweep", "choir": "rings", "seravel": "orbit"}[bt]
					bb.perform(act, lp.global_position, 7)
					await get_tree().create_timer(0.8 if bt != "seravel" else 2.0).timeout
					lp.state = "move"
					lp.aim = (bb.global_position - lp.global_position).normalized()
					lp._start_attack()
					await get_tree().create_timer(0.15).timeout
					_promo_clean(w)
					await _shot(out + "/q05_%s.png" % bt)
				w._end_ascension(false)
				await get_tree().create_timer(5.0).timeout
			# 6. Mapa
			w.menu.open("map", {})
			await get_tree().create_timer(0.8).timeout
			await _shot(out + "/q06_mapa.png")
			w.menu.close()
			print("AUTOTEST_PROMO7_OK")
			get_tree().quit()
		"v8":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			lp.respawn_at(w.tile_pos(84, 70))
			await get_tree().create_timer(1.2).timeout
			await _shot(out + "/e01_muro.png")
			for i in 4:
				lp.state = "move"
				lp.aim = Vector2.DOWN
				lp._start_attack()
				await get_tree().create_timer(0.45).timeout
			await get_tree().create_timer(0.8).timeout
			await _shot(out + "/e02_derrumbe.png")
			print("V8 broken=", w.wflags.get("broken_capilla", false))
			lp.respawn_at(w.tile_pos(84, 78.5))
			await get_tree().create_timer(2.0).timeout
			await _shot(out + "/e03_capilla.png")
			for pid in ["page_1", "page_2", "page_3"]:
				if w.interactables.has(pid):
					w._pickup(pid)
				await get_tree().create_timer(0.3).timeout
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/e04_himno.png")
			print("V8 hymns=", Prog.quest_done("hymns"), " bell=", Prog.item_count("amulet_bell"))
			print("AUTOTEST_V8_OK")
			get_tree().quit()
		"d3":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			for rid in w.ROOMS:
				Prog.flags["seen_" + rid.id] = true
			var spots := [[Vector2(44, 58), "d01_cadenas_izq"], [Vector2(58, 67), "d02_cadenas_der"], [Vector2(48, 69), "d03_borde_sur"],
				[Vector2(25, 52), "d04_celdas_pozo"], [Vector2(69, 22), "d05_antesala"], [Vector2(80, 66), "d06_galeria"]]
			Prog.flags["carcelero_dead"] = true; w.wflags["carcelero_dead"] = true
			w.set_gate(true, true)
			for sp in spots:
				lp.respawn_at(w.tile_pos(sp[0].x, sp[0].y))
				await get_tree().create_timer(1.4).timeout
				await _shot(out + "/" + sp[1] + ".png")
			Prog.flags["carcelero_dead"] = false; w.wflags["carcelero_dead"] = false
			# jefes con detalles 3D
			w.start_ascension("carcelero", 1)
			await get_tree().create_timer(4.2).timeout
			var bb: Enemy = w.active_boss
			if bb:
				bb.cooldown = 99.0
				lp.global_position = bb.global_position + Vector2(-70, 40)
				bb.perform("sweep", lp.global_position, 1)
				await get_tree().create_timer(0.75).timeout
				await _shot(out + "/d07_carcelero_bola.png")
				bb.perform("cages", lp.global_position, 2)
				await get_tree().create_timer(0.9).timeout
				await _shot(out + "/d08_carcelero_jaulas.png")
			w._end_ascension(false)
			await get_tree().create_timer(5.0).timeout
			w.start_ascension("choir", 1)
			await get_tree().create_timer(4.2).timeout
			await _shot(out + "/d09_coro_carrusel.png")
			w._end_ascension(false)
			await get_tree().create_timer(5.0).timeout
			w.start_ascension("seravel", 1)
			await get_tree().create_timer(4.2).timeout
			bb = w.active_boss
			if bb:
				bb.cooldown = 99.0
				lp.global_position = bb.global_position + Vector2(60, 70)
				await get_tree().create_timer(0.5).timeout
				await _shot(out + "/d10_seravel_aureola.png")
				bb.perform("judgment", lp.global_position, 3)
				await get_tree().create_timer(1.6).timeout
				await _shot(out + "/d11_seravel_asciende.png")
				await get_tree().create_timer(1.3).timeout
				await _shot(out + "/d12_seravel_impacto.png")
			print("AUTOTEST_D3_OK")
			get_tree().quit()
		"pit":
			var lp: Player = w.local_player()
			w.camera.zoom = Vector2(1.5, 1.5)
			lp.respawn_at(w.tile_pos(49, 62))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/pit1.png")
			lp.respawn_at(w.tile_pos(60, 58))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/pit2.png")
			lp.respawn_at(w.tile_pos(76, 64))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/pit3.png")
			get_tree().quit()
		"hud":
			var lp: Player = w.local_player()
			await get_tree().create_timer(1.0).timeout
			w._grant({"feathers": 1, "ecos": 250, "items": {"tear": 1, "iron": 2}})
			Prog.start_quest("choir")
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/h01_lleno.png")
			lp.hp -= 37.0
			lp.stamina = 45.0
			lp.light = 25.0
			await get_tree().create_timer(0.08).timeout
			await _shot(out + "/h02_golpe.png")
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/h03_medio.png")
			lp.hp = 18.0
			lp.stamina = 0.0
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/h04_poca_vida.png")
			Prog.buffs["ointment"] = 20.0
			lp.hp = 64.0
			Prog.attr.vigor = 12
			lp.stamina = 70.0
			lp.light = 60.0
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/h05_dorado_dos_filas.png")
			get_tree().quit()
		"cine":
			var cine := preload("res://scripts/ui/boss_cinematic.gd").new()
			cine.setup("choir", 1)
			w.add_child(cine)
			for k in 18:
				await get_tree().create_timer(0.5, true, false, true).timeout
				if is_instance_valid(cine) and cine.singers.size() > 0:
					print("t=", k * 0.5, " s0=", cine.singers[0].position, " vis=", cine.singers[0].visible, " giant=", cine.giant.visible, " done=", cine._done)
			get_tree().quit()
		"v3":
			var lp: Player = w.local_player()
			Prog.ecos = 5000
			Prog.add_item("iron", 3, true); Prog.add_item("tear", 6, true)
			for rid in ["sanct", "hall1", "chains", "hall2", "east", "gallery", "yard", "nim_link", "nimbo", "mirador", "mir_link", "choir_link", "choir", "alcove", "alc_link", "celdas", "cel_link", "cel_up", "atrio", "atr_link", "esc_link", "escala", "antesala", "jui_link"]:
				Prog.flags["seen_" + rid] = true
			Prog.add_item("map_carto", 1, true)
			Prog.spark = true
			# Sala del Nimbo
			lp.respawn_at(w.tile_pos(66, 89))
			await get_tree().create_timer(2.0).timeout
			await _shot(out + "/v01_nimbo.png")
			for npc in ["ozias", "ilse", "nyx", "velaria"]:
				w.menu.open("service", {"npc": npc})
				await get_tree().create_timer(0.7).timeout
				await _shot(out + "/v02_servicio_%s.png" % npc)
				w.menu.close()
			Prog.engrave("sword", "brasa")
			Prog.flags["carcelero_dead"] = true; w.wflags["carcelero_dead"] = true
			Prog.flags["choir_dead"] = true; w.wflags["choir_dead"] = true
			w.menu.open("service", {"npc": "velaria"})
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/v03_velaria_jefes.png")
			w.menu.close()
			w.menu.open("map", {})
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/v04_mapa.png")
			w.menu.close()
			# combate con grabado de brasa + combo
			lp.respawn_at(w.tile_pos(44, 63))
			await get_tree().create_timer(1.2).timeout
			for i in 7:
				lp.aim = (w.enemies[1].global_position - lp.global_position).normalized()
				lp.state = "move"
				lp._start_attack()
				await get_tree().create_timer(0.18).timeout
			await _shot(out + "/v05_combo.png")
			# muerte: pluma arrancada, segunda muerte -> sombra
			lp.take_hit(9999.0, Vector2.RIGHT, -1)
			await get_tree().create_timer(4.5).timeout
			Prog.ecos = 900
			lp.respawn_at(w.tile_pos(46, 66))
			await get_tree().create_timer(0.3).timeout
			lp.take_hit(9999.0, Vector2.RIGHT, -1)
			await get_tree().create_timer(5.0).timeout
			print("V3 deaths=", Prog.deaths, " feathers=", Prog.wing_feathers, " shadow=", Prog.shadow, " dropped=", Prog.dropped_ecos)
			var sh: Enemy = null
			for e in w.enemies:
				if e.type == "sombra":
					sh = e
			if sh:
				lp.respawn_at(sh.global_position + Vector2(-40, 0))
				await get_tree().create_timer(1.0).timeout
				await _shot(out + "/v06_sombra.png")
			# desplumado
			Prog.wing_feathers = 2
			w.send_look()
			lp.respawn_at(w.tile_pos(49, 86))
			await get_tree().create_timer(1.0).timeout
			await _shot(out + "/v07_desplumado.png")
			# evento del mundo
			w._world_event("eclipse", 30.0)
			lp.respawn_at(w.tile_pos(46, 64))
			await get_tree().create_timer(2.0).timeout
			await _shot(out + "/v08_eclipse.png")
			w._world_event_end()
			# cinemática del Coro
			var cine := preload("res://scripts/ui/boss_cinematic.gd").new()
			cine.setup("choir", 1)
			w.add_child(cine)
			lp.cutscene = true
			for k in [1.5, 4.6, 8.2]:
				await get_tree().create_timer(k - (0.0 if k == 1.5 else (1.5 if k == 4.6 else 4.6)), true, false, true).timeout
				await _shot(out + "/v09_cine_coro_%d.png" % int(k))
			await cine.finished
			lp.cutscene = false
			# Ascensión del Carcelero (arena decorada)
			w.start_ascension("carcelero", 2)
			await get_tree().create_timer(4.0).timeout
			await _shot(out + "/v10_ascension.png")
			var cb: Enemy = w.active_boss
			if cb:
				cb.poise = cb.max_poise * 2.0
				cb._start_stagger()
				cb.hp = cb.max_hp * 0.1
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/v11_boss_bar.png")
			print("V3 seals=", w._seals.size())
			for style_room in [["carcelero", "v11b_sello_celda"], ["choir", "v11c_sello_coro"], ["seravel", "v11d_sello_luz"]]:
				w.seal_for(style_room[0])
				await get_tree().create_timer(0.2).timeout
				if not w._seals.is_empty():
					var sp: Vector2 = w._seals[0].global_position
					w._cam_focus = sp
					await get_tree().create_timer(1.3).timeout
					await _shot(out + "/" + style_room[1] + ".png")
			w._cam_focus = null
			w.unseal_arena()
			# arena del Coro
			lp.respawn_at(w.tile_pos(82, 41))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/v12_nave_coro.png")
			lp.respawn_at(w.tile_pos(49, 18))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/v13_circulo.png")
			w.menu.open("options", {})
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/v14_opciones.png")
			w.menu.close()
			print("AUTOTEST_V3_OK")
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

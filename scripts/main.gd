extends Node
## Raíz del juego: pantalla de título, creación/unión de partidas y carga del mundo.

var title: Control
var title_layer: CanvasLayer
var world: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Net.connected_ok.connect(_on_connected)
	Net.world_ready.connect(_on_host_world_ready)
	Net.connect_failed.connect(_on_connect_failed)
	Net.upnp_done.connect(_on_upnp_done)
	Net.lobby_changed.connect(_on_lobby_changed)
	Net.host_closed.connect(_on_lobby_host_closed)
	G.language_changed.connect(_rebuild_title)
	match G.autotest:
		"", "none":
			_build_title()
		"prologue":
			Prog.reset()
			G.set_meta("prologue", true)
			start_game("new")
		"host":
			Net.host()
			start_game("new")
		"join":
			Net.join_ip("127.0.0.1")
		"slots":
			# tres huecos: independientes, se migra la partida antigua, se borra con confirmación
			var sd_s := OS.get_environment("SERAPHALL_SHOTS")
			var fails := []
			for s0 in [1, 2, 3]:
				Prog.delete_save(s0)
			# la partida antigua pasa al hueco 1 sin perderse
			var fl := FileAccess.open(Prog.legacy_path(), FileAccess.WRITE)
			Prog.slot = 1
			Prog.reset()
			Prog.level = 7
			G.look = Look.sane({"body": "f", "hair": 1, "name": "Antigua"})
			fl.store_string(JSON.stringify(Prog.to_dict()))
			fl.close()
			Prog.migrate_legacy()
			if not Prog.has_save(1) or int(Prog.peek_save(1).get("level", 0)) != 7 or FileAccess.file_exists(Prog.legacy_path()):
				fails.append("migración")
			# otra partida en el hueco 3, con su propio progreso
			Prog.slot = 3
			Prog.reset()
			Prog.level = 21
			Prog.difficulty = 3
			Prog.playtime = 12600.0
			Prog.wing_feathers = 4
			Prog.last_brasa = "yunque"
			Prog.flags = {"seravel_dead": true, "orrun_dead": true}
			G.look = Look.sane({"body": "m", "hair": 2, "name": "Kael"})
			Prog.save_game()
			if Prog.has_save(2) or int(Prog.peek_save(1).get("level", 0)) != 7 or int(Prog.peek_save(3).get("level", 0)) != 21:
				fails.append("huecos no independientes")
			# archivo dañado: el juego no se rompe
			Prog.slot = 2
			var bad_f := FileAccess.open(Prog.save_path(2), FileAccess.WRITE)
			bad_f.store_string("{esto no es json")
			bad_f.close()
			if not Prog.peek_save(2).is_empty() or Prog.load_game():
				fails.append("archivo dañado")
			_build_title()
			title._skip_intro()
			await get_tree().create_timer(0.5).timeout
			_open_slots("new")
			await get_tree().create_timer(0.8).timeout
			var ui: Control = title_layer.get_child(title_layer.get_child_count() - 1)
			await _shot(sd_s + "/s01_huecos.png")
			# borrar pide confirmación
			ui._on_delete(1)
			if not Prog.has_save(2):
				fails.append("borró sin confirmar")
			await get_tree().create_timer(0.3).timeout
			await _shot(sd_s + "/s02_confirmar.png")
			ui._on_delete(1)
			if Prog.has_save(2) or not Prog.has_save(1) or not Prog.has_save(3):
				fails.append("borrado incorrecto")
			await get_tree().create_timer(0.3).timeout
			await _shot(sd_s + "/s03_borrado.png")
			# elegir el hueco 3 carga esa partida
			Prog.reset()
			ui.sel = 2
			ui._pick()
			await get_tree().create_timer(2.0).timeout
			print("SLOTS hueco=", Prog.slot, " nivel=", Prog.level, " dificultad=", Prog.difficulty, " mundo=", world != null)
			if Prog.slot != 3 or Prog.level != 21 or world == null:
				fails.append("no carga el hueco")
			# guardar solo escribe en el suyo, y sin dejar temporales
			Prog.level = 22
			Prog.save_game()
			if int(Prog.peek_save(3).get("level", 0)) != 22 or int(Prog.peek_save(1).get("level", 0)) != 7 or FileAccess.file_exists(Prog.save_path(3) + ".tmp"):
				fails.append("guardado cruzado")
			for fs in fails:
				print("FALLO ", fs)
			for s9 in [1, 2, 3]:
				Prog.delete_save(s9)
			print("AUTOTEST_SLOTS_OK" if fails.is_empty() else "AUTOTEST_SLOTS_FAIL")
			get_tree().quit()
		"lobby_host":
			# el anfitrión se queda en la sala 8 s (el caso que antes colgaba al cliente) y luego empieza
			Prog.reset()
			_build_title()
			Net.host()
			await get_tree().create_timer(8.0).timeout
			print("LOBBY_HOST peers_en_sala=", Net.peers())
			start_game("new")
		"lobby_join":
			_build_title()
			Net.lan_listen_start()
			await get_tree().create_timer(3.0).timeout
			print("LOBBY_JOIN lan_games=", Net.lan_games)
			var found: Array = Net.lan_games.keys()
			Net.lan_listen_stop()
			if found.is_empty():
				print("LOBBY_JOIN aviso: sin partidas LAN, se conecta por IP")
			var err_j := Net.join("%s:%d" % [found[0] if found.size() > 0 else "127.0.0.1", Net.PORT])
			print("LOBBY_JOIN join=", err_j)
		"newgame":
			var sd := OS.get_environment("SERAPHALL_SHOTS")
			_build_title()
			await get_tree().create_timer(0.5).timeout
			title._skip_intro()
			await get_tree().create_timer(1.0).timeout
			_open_new_game("new")
			await get_tree().create_timer(0.8).timeout
			await _shot(sd + "/n01_dificultad.png")
			var ng: Control = title_layer.get_child(title_layer.get_child_count() - 1)
			ng.diff_sel = 0
			await get_tree().create_timer(0.5).timeout
			await _shot(sd + "/n02_ala_ligera.png")
			ng.diff_sel = 3
			await get_tree().create_timer(0.5).timeout
			await _shot(sd + "/n02b_serafin.png")
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
			_open_new_game("new")
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
		"teaser":
			var sd3 := OS.get_environment("SERAPHALL_SHOTS")
			var tz := preload("res://scripts/ui/intro_film.gd").new()
			tz.mode = "teaser"
			add_child(tz)
			await get_tree().create_timer(1.0).timeout
			for k in tz.TEASER.size():
				tz.debug_seek(k, 0.78)
				await get_tree().create_timer(0.35).timeout
				await _shot(sd3 + "/t%02d.png" % k)
			get_tree().quit()
		"title2":
			# ficha de "Continuar" con una partida de ejemplo
			Prog.reset()
			Prog.level = 9
			Prog.playtime = 5400.0
			Prog.wing_feathers = 7
			Prog.last_brasa = "nimbo"
			Prog.memories = {"m1": true, "m2": true}
			G.look = Look.sane({"body": "f", "hair": 1, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": "Aurel"})
			Prog.save_game()
			_build_title()
			title._skip_intro()
			await get_tree().create_timer(0.5).timeout
			title.show_main_menu()
			await get_tree().create_timer(1.2).timeout
			await _shot(OS.get_environment("SERAPHALL_SHOTS") + "/t2_continuar.png")
			print("AUTOTEST_TITLE2_OK")
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
			Prog.pick_latest()
			Prog.load_game()
			Net.close()
			_transition_to_game("continue")
		"new":
			Net.close()
			_open_slots("new")
		"host":
			if Net.host() != OK:
				title.toast(G.L(["No se pudo abrir el puerto 24680: ¿hay otra partida abierta?", "Could not open port 24680: is another game running?"]))
				return
			title.show_panel("host")
		"host_start":
			_open_slots("host")
		"copy":
			var c := Net.online_code()
			if c == "":
				c = Net.lan_code()
			DisplayServer.clipboard_set(c)
			title.toast(G.L(["Código copiado", "Code copied"]) + ": " + c)
		"copy_lan":
			DisplayServer.clipboard_set(Net.lan_code())
			title.toast(G.L(["Código copiado", "Code copied"]) + ": " + Net.lan_code())
		"join_menu":
			Net.lan_listen_start()
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
			Net.lan_listen_stop()
			title.show_main_menu()
		"quit":
			get_tree().quit()

func _open_slots(mode: String) -> void:
	var sl := preload("res://scripts/ui/save_slots.gd").new()
	sl.chosen.connect(_on_slot_chosen.bind(mode))
	sl.cancelled.connect(_on_new_game_cancel.bind(mode))
	if title and is_instance_valid(title):
		title._clear_menu()
	title_layer.add_child(sl)

func _on_slot_chosen(slot: int, occupied: bool, mode: String) -> void:
	Prog.slot = slot
	if not occupied:
		_open_new_game(mode)
	elif Prog.load_game():
		_transition_to_game("continue")
	else:
		_toast_title(G.L(["No se puede leer esa partida.", "That save can't be read."]))
		_open_slots(mode)

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
	if mode != "new":
		# en cooperativo tu compañero espera en la sala: se entra directo, sin corto ni prólogo
		G.set_meta("prologue", false)
		_transition_to_game("new")
		return
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
		var d := UIKit.label(G.L(["Un entrenamiento en una sala aparte: un jefe sencillo te enseña paso a paso a desviar, atacar, esquivar y curarte, deteniendo el juego cuando tengas que reaccionar. Terminas llegando al Santuario.",
			"Training in a separate room: a simple boss teaches you step by step to parry, attack, dodge and heal, pausing the game when you need to react. It ends with you arriving at the Sanctuary."]), 15, UIKit.TEXT_DIM)
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
			_pick.call_deferred(G.autotest == "prologue")
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
	## Enlace correcto: el cliente espera en la sala hasta que el anfitrión entre en la partida
	Net.lan_listen_stop()
	if title and is_instance_valid(title):
		title.show_waiting()

func _on_host_world_ready() -> void:
	if world or Net.is_host:
		return
	# el cliente usa su última partida (o un personaje nuevo)
	Prog.pick_latest()
	if not Prog.load_game():
		Prog.reset()
	start_game("client")

func _on_connect_failed(reason: String) -> void:
	var msg: String = G.T("conn_" + reason) if G.TXT.has("conn_" + reason) else G.T("conn_failed")
	if world:
		back_to_title(msg)
		return
	if title and is_instance_valid(title):
		Net.lan_listen_start()
		title.show_panel("join")
		title.set_status(msg)

func _on_lobby_changed() -> void:
	if title and is_instance_valid(title) and Net.is_host:
		title.refresh_lobby()

func _on_lobby_host_closed() -> void:
	if world == null and title and is_instance_valid(title):
		title.show_main_menu()
		title.toast(G.T("host_left"))

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
	world.process_mode = Node.PROCESS_MODE_PAUSABLE  # el tutorial detiene el mundo sin detener la interfaz raíz
	add_child(world)
	if Net.is_host:
		Net.announce_world_ready()
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
		"promo8":
			# capturas de las novedades de la noche (ALFA 0.8, 1920x1080)
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			G.look = Look.sane({"body": "f", "hair": 1, "hair_col": 0, "skin": 1, "eye": 0, "cloak": 0, "armor": 0, "wing": 0, "halo": 0, "name": "Aurel"})
			w.send_look()
			Prog.level = 12
			Prog.weapons = {"sword": 6, "seravel": 3}
			Prog.equipped = "seravel"
			Prog.wing_feathers = 8
			for rid in w.ROOMS:
				Prog.flags["seen_" + rid.id] = true
			for fl in ["nimbo_intro", "escala_seen", "atrio_echo", "echo_nimbo", "echo_galeria"]:
				Prog.flags[fl] = true
			for ar in ["area_nimbo", "area_gallery", "area_mirador", "area_juicio", "area_yard", "area_chains", "area_celdas", "area_capilla", "area_circle", "area_atrio", "area_choir"]:
				Prog.flags["thought_" + ar] = true
			lp.refresh_stats(true)
			lp._update_weapon_sprite()
			w.camera.zoom = Vector2(1.35, 1.35)
			for tid in ["celdas", "atrio", "umbral"]:
				Prog.flags["trial_" + tid] = true
				w.wflags["trial_" + tid] = true
			w._refresh_locks(true)
			var go := func(tx: float, ty: float) -> void:
				var pos: Vector2 = w.tile_pos(tx, ty)
				w._area = w.AREAS.get(w.room_at(pos), "")
				lp.respawn_at(pos)
			var clean := func() -> void:
				for c in w.hud.toast_box.get_children():
					c.queue_free()
			await get_tree().create_timer(12.0).timeout
			# 1. Sala del Nimbo: lámpara de araña, PNJ y sombras de los braseros
			go.call(63.5, 88.5)
			await get_tree().create_timer(2.5).timeout
			clean.call()
			await _shot(out + "/n01_nimbo_lampara.png")
			# 2. Diálogo con busto nuevo junto a Brenna
			go.call(46, 85.5)
			await get_tree().create_timer(2.0).timeout
			clean.call()
			var bx = w.dialog.box
			bx.visible = true
			bx.scale = Vector2.ONE
			bx.speaker = "Brenna"
			bx.text = G.L(["¿Has visto los esqueletos con alas del Pasillo? Algunos aún aprietan la empuñadura. Buen acero, ese.", "Seen the winged skeletons in the Hall? Some still grip their hilts. Good steel, that."])
			bx.chars = 999.0
			bx.portrait = w.dialog.PORTRAITS["Brenna"]
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/n02_dialogo_busto.png")
			bx.visible = false
			# 4. Mirador: estatua colosal y relámpago
			go.call(32, 87)
			await get_tree().create_timer(2.5).timeout
			clean.call()
			var ab = w.get_node("Abyss")
			ab._make_bolt()
			var sh: float = -240.0 - ab._bolt[0].x
			var nb := PackedVector2Array()
			for q in ab._bolt:
				nb.append(q + Vector2(sh, 0))
			ab._bolt = nb
			var nb2 := PackedVector2Array()
			for q2 in ab._bolt2:
				nb2.append(q2 + Vector2(sh, 0))
			ab._bolt2 = nb2
			ab._next_bolt = 60.0
			await get_tree().create_timer(0.05).timeout
			await _shot(out + "/n04_tormenta_coloso.png")
			# 5. Galería: la Plañidera llora sobre ti
			var mo: Enemy = null
			for e in w.enemies_alive():
				if e.type == "planidera":
					mo = e
					break
			if mo:
				w._area = "area_gallery"
				lp.respawn_at(mo.global_position + Vector2(-60, 40))
				await get_tree().create_timer(1.6).timeout
				clean.call()
				mo.cooldown = 99.0
				mo.perform("tears", lp.global_position + Vector2(10, 0), 3)
				await get_tree().create_timer(0.95).timeout
				await _shot(out + "/n05_planidera.png")
			# 6. Antesala del Juicio con sus lámparas
			go.call(69.5, 25.5)
			await get_tree().create_timer(2.2).timeout
			clean.call()
			await _shot(out + "/n06_antesala_lamparas.png")
			# 3. Eco del pasado en el Patio (al final: su diálogo dura un rato)
			Prog.flags["echo_patio"] = false
			go.call(52.5, 47.5)
			await get_tree().create_timer(1.0).timeout
			go.call(50.5, 45.6)
			await get_tree().create_timer(3.0).timeout
			clean.call()
			await _shot(out + "/n03_eco_del_pasado.png")
			await get_tree().create_timer(9.0).timeout
			# 7. Códice: personajes
			for kn in ["brenna", "carto", "ozias", "ilse", "nyx", "velaria", "preso", "peregrina"]:
				Prog.flags["known_" + kn] = true
			w.menu.open("codex", {})
			w.menu._on_codex("_npc")
			await get_tree().create_timer(0.7).timeout
			await _shot(out + "/n07_codice_personajes.png")
			w.menu.close()
			# 8. Resumen del Estrato
			Prog.playtime = 9420.0
			Prog.deaths = 6
			w.hud.end_card(G.T("demo_end_title"), G.T("demo_end_body") % Prog.route_name())
			await get_tree().create_timer(4.6).timeout
			await _shot(out + "/n08_fin_del_estrato.png")
			print("AUTOTEST_PROMO8_OK")
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
		"exec":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			var e: Enemy = w.enemies[0]
			lp.respawn_at(e.global_position + Vector2(-30, 0))
			await get_tree().create_timer(1.0).timeout
			e._start_stagger()
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/y01_prompt.png")
			w.try_interact(lp)
			await get_tree().create_timer(0.12).timeout
			await _shot(out + "/y02_ejecucion.png")
			await get_tree().create_timer(1.0).timeout
			print("EXEC dead=", not e.is_alive())
			get_tree().quit()
		"death":
			var lp: Player = w.local_player()
			lp.respawn_at(w.tile_pos(46, 64))
			await get_tree().create_timer(1.0).timeout
			lp.take_hit(9999.0, Vector2.RIGHT, -1)
			await get_tree().create_timer(2.0, true, false, true).timeout
			await _shot(out + "/x01_muerte.png")
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
		"thought":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			await get_tree().create_timer(1.0).timeout
			var cc: Vector2 = w._room_corner("mirador")
			lp.respawn_at(w.tile_pos(cc.x, cc.y))
			await get_tree().create_timer(3.4).timeout
			await _shot(out + "/t01_pensamiento.png")
			await get_tree().create_timer(5.0).timeout
			await _shot(out + "/t02_voz.png")
			print("AUTOTEST_THOUGHT_OK")
			get_tree().quit()
		"ghost":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			Prog.flags["thought_area_nimbo"] = true
			Prog.flags["thought_area_gallery"] = true
			Prog.flags["thought_area_yard"] = true
			var n := 1
			Prog.flags["nimbo_intro"] = true
			Prog.flags["thought_area_capilla"] = true
			for sp in [Vector2(66, 86.5), Vector2(67.5, 64.4), Vector2(49.5, 47.5), Vector2(84, 80.5)]:
				lp.respawn_at(w.tile_pos(sp.x, sp.y))
				await get_tree().create_timer(1.6).timeout
				await _shot(out + "/g%d_antes.png" % n)
				lp.respawn_at(w.tile_pos(sp.x, sp.y - 2.0))
				await get_tree().create_timer(2.6).timeout
				await _shot(out + "/g%d_eco.png" % n)
				await get_tree().create_timer(12.0).timeout
				n += 1
			print("GHOST flags ", Prog.flags.get("echo_nimbo"), Prog.flags.get("echo_galeria"), Prog.flags.get("echo_patio"), " ach=", Prog.flags.get("ach_echoes", false))
			print("AUTOTEST_GHOST_OK")
			get_tree().quit()
		"shadow":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			print("LIGHTS=", w.shadow_lights.size())
			var n := 1
			for sp in [Vector2(44.2, 81.2), Vector2(47.0, 82.5), Vector2(41.5, 41.0), Vector2(22.5, 47.5)]:
				lp.respawn_at(w.tile_pos(sp.x, sp.y))
				await get_tree().create_timer(1.5).timeout
				await _shot(out + "/s%d.png" % n)
				n += 1
			print("AUTOTEST_SHADOW_OK")
			get_tree().quit()
		"dlg":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			await get_tree().create_timer(1.0).timeout
			var n := 1
			for spk in ["Seravel", "El Carcelero", "Madre Ilse", "Sael"]:
				var bx = w.dialog.box
				bx.visible = true
				bx.scale = Vector2.ONE
				bx.speaker = spk
				bx.text = "Texto de prueba para ver el retrato y el cuadro de diálogo con una frase bastante larga, de dos líneas."
				bx.chars = 999.0 if n % 2 == 1 else 20.0
				bx.truth = ""
				bx.portrait = w.dialog.PORTRAITS.get(spk, [])
				await get_tree().create_timer(0.4).timeout
				await _shot(out + "/d%d.png" % n)
				n += 1
			print("AUTOTEST_DLG_OK")
			get_tree().quit()
		"chand":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			Prog.flags["echo_nimbo"] = true
			var n := 1
			for sp in [Vector2(66, 89), Vector2(62, 84), Vector2(49, 85.5)]:
				lp.respawn_at(w.tile_pos(sp.x, sp.y))
				await get_tree().create_timer(2.6).timeout
				await _shot(out + "/c%d.png" % n)
				n += 1
			print("AUTOTEST_CHAND_OK")
			get_tree().quit()
		"storm":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			lp.respawn_at(w.tile_pos(34, 86))
			await get_tree().create_timer(2.5).timeout
			var ab = w.get_node("Abyss")
			ab._next_bolt = 0.01
			await get_tree().create_timer(0.08).timeout
			print("STORM flash=", ab._flash, " pts=", ab._bolt.size(), " layer=", ab._bolt_layer, " bg=", w.has_node("Background"), " parent=", ab._bolt_layer.get_parent() if ab._bolt_layer else null)
			await _shot(out + "/storm.png")
			print("AUTOTEST_STORM_OK")
			get_tree().quit()
		"whisper":
			Prog.flags["carcelero_dead"] = true
			await get_tree().create_timer(1.0).timeout
			w.menu.open("char", {"brasa": true})
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/w1.png")
			print("AUTOTEST_WHISPER_OK")
			get_tree().quit()
		"fallen":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			var fs: Array = []
			for c in w.entities.get_children():
				if c.get_class() == "Node2D" and c.get("seed_v") != null:
					fs.append(c)
			print("FALLEN=", fs.size())
			var n := 1
			for k in [0, 3, 6]:
				if k < fs.size():
					lp.respawn_at(fs[k].global_position + Vector2(30, 20))
					await get_tree().create_timer(1.6).timeout
					await _shot(out + "/f%d.png" % n)
					n += 1
			print("AUTOTEST_FALLEN_OK")
			get_tree().quit()
		"endcard":
			await get_tree().create_timer(1.0).timeout
			Prog.playtime = 4210.0
			Prog.deaths = 7
			w.hud.end_card(G.T("demo_end_title"), G.T("demo_end_body") % Prog.route_name())
			await get_tree().create_timer(4.6).timeout
			await _shot(out + "/endcard.png")
			print("AUTOTEST_ENDCARD_OK")
			get_tree().quit()
		"sael":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			Prog.flags["escala_seen"] = true
			Prog.flags["thought_area_juicio"] = true
			lp.respawn_at(w.tile_pos(66, 29.2))
			await get_tree().create_timer(4.0).timeout
			await _shot(out + "/s1.png")
			lp.respawn_at(w.tile_pos(60.5, 29.0))
			await get_tree().create_timer(4.0).timeout
			await _shot(out + "/s2.png")
			print("SAEL pos ", w.interactables["peregrina"].global_position / 16.0)
			print("AUTOTEST_SAEL_OK")
			get_tree().quit()
		"nimbo":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			await get_tree().create_timer(1.0).timeout
			lp.respawn_at(w.tile_pos(66, 92.5))
			for i in 4:
				await get_tree().create_timer(0.9).timeout
				await _shot(out + "/n%d.png" % i)
			print("AUTOTEST_NIMBO_OK")
			get_tree().quit()
		"mourner":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			Prog.flags["thought_area_gallery"] = true
			Prog.flags["echo_galeria"] = true
			var mo: Enemy = null
			for e in w.enemies_alive():
				if e.type == "planidera":
					mo = e
					break
			print("MOURNER at ", mo.global_position / 16.0 if mo else null)
			lp.respawn_at(mo.global_position + Vector2(-60, 40))
			await get_tree().create_timer(2.0).timeout
			mo.cooldown = 99.0
			mo.perform("tears", lp.global_position, 7)
			await get_tree().create_timer(0.75).timeout
			await _shot(out + "/m1.png")
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/m2.png")
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/m3.png")
			print("AUTOTEST_MOURNER_OK")
			get_tree().quit()
		"penitent":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			for ar in ["area_chains", "area_gallery"]:
				Prog.flags["thought_" + ar] = true
			var pe: Enemy = null
			for e in w.enemies_alive():
				if e.type == "penitente":
					print("PENITENTE at ", e.global_position / 16.0, " wall=", w.is_wall_at(e.global_position))
					if pe == null:
						pe = e
			for e2 in w.enemies_alive():
				if e2 != pe and e2.global_position.distance_to(pe.global_position) < 260.0 and not e2.is_boss:
					w._server_damage(e2.idx, 99999.0, Vector2.RIGHT, 0.0, false)
			lp.respawn_at(pe.global_position + Vector2(-70, 10))
			await get_tree().create_timer(2.5).timeout
			pe.cooldown = 99.0
			pe.perform("leap", lp.global_position, 1)
			await get_tree().create_timer(0.75).timeout
			await _shot(out + "/p1.png")
			await get_tree().create_timer(0.35).timeout
			await _shot(out + "/p2.png")
			print("AUTOTEST_PENITENT_OK")
			get_tree().quit()
		"map":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			await get_tree().create_timer(1.0).timeout
			w.menu.open("map", {})
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/map1_inicio.png")
			w.menu.close()
			for rid in w.ROOMS:
				Prog.flags["seen_" + rid.id] = true
			Prog.flags["echo_patio"] = true
			Prog.flags["echo_nimbo"] = true
			Prog.add_item("map_carto", 1, true)
			lp.respawn_at(w.tile_pos(47, 60))
			await get_tree().create_timer(1.0).timeout
			w.menu.open("map", {})
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/map2_completo.png")
			print("AUTOTEST_MAP_OK")
			get_tree().quit()
		"hair3":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			G.look = Look.sane({"body": "f", "hair": 3, "hair_col": 3, "skin": 2, "eye": 3, "cloak": 2, "armor": 2, "wing": 2, "halo": 0, "name": "Trenza"})
			w.send_look()
			var mate = w._spawn_player(424242, 2)
			mate.set_look({"body": "m", "hair": 3, "hair_col": 4, "skin": 4, "eye": 4, "cloak": 5, "armor": 4, "wing": 4, "halo": 3, "name": "Rapado"}, 10)
			w.camera.zoom = Vector2(2.5, 2.5)
			await get_tree().create_timer(2.5).timeout
			mate.global_position = lp.global_position + Vector2(24, 0)
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/h3.png")
			print("AUTOTEST_HAIR3_OK")
			get_tree().quit()
		"ach":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			Ach.import_legacy(["awaken", "first_brasa", "nimbo", "first_blood", "jailer", "choir", "spare", "secret", "bells", "spark"])
			Ach.set_max("kills", 63)
			Ach.set_max("urns", 22)
			Ach.set_max("parries", 9)
			Ach.set_max("brasas", 2)
			await get_tree().create_timer(0.5).timeout
			Ach.unlock("seravel")
			for tt in [0.25, 0.6, 1.1, 2.0]:
				await get_tree().create_timer(tt - (0.0 if tt == 0.25 else 0.0)).timeout
				await _shot(out + "/a0%d_logro_%d.png" % [int(tt * 10), int(tt * 100)])
			await get_tree().create_timer(3.0).timeout
			Ach.unlock("sb_verdugo")
			await get_tree().create_timer(0.7).timeout
			await _shot(out + "/a10_epico_a.png")
			await get_tree().create_timer(0.9).timeout
			await _shot(out + "/a11_epico_b.png")
			await get_tree().create_timer(4.5).timeout
			Ach.add("urns", 0.0)
			Ach.set_max("kills", 50)
			Ach.set_max("cross", 12)
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/a12_progreso.png")
			await get_tree().create_timer(3.0).timeout
			w.menu.open("ach", {})
			await get_tree().create_timer(0.9).timeout
			await _shot(out + "/a20_menu_logros.png")
			w.menu._on_ach_filter("challenge")
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/a21_desafios.png")
			w.menu._on_ach_filter("dlc")
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/a22_dlc.png")
			w.menu._on_ach_filter("secret")
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/a23_secretos.png")
			print("ACH pct=", Ach.percent(), " xp=", Ach.xp_total(), " count=", Ach.count("base"))
			print("AUTOTEST_ACH_OK")
			get_tree().quit()
		"strata":
			var lp: Player = w.local_player()
			lp.iframes = 99999.0
			Prog.level = 40
			Prog.attr.vigor = 20
			lp.refresh_stats(true)
			var skip := func() -> void:
				for k in 12:
					if w.dialog.is_open():
						w.dialog._advance()
					await get_tree().create_timer(0.15).timeout
			w.wflags["seravel_dead"] = true
			w._refresh_rifts()
			lp.respawn_at(w.tile_pos(49, 9))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/s00_grieta.png")
			var stops := {2: [["llegada", Vector2(143.5, 86)], ["sendero", Vector2(140, 62)], ["nidos", Vector2(111, 62)], ["cienaga_borde", Vector2(160, 63)], ["arboleda", Vector2(140, 39)], ["madriguera", Vector2(110, 37)]],
				3: [["llegada", Vector2(239.5, 86)], ["crisoles", Vector2(240, 60)], ["biblio", Vector2(205, 57)], ["fragua", Vector2(240, 33)], ["archivo", Vector2(207, 31)]],
				4: [["llegada", Vector2(335.5, 86)], ["jardin", Vector2(336, 61)], ["corte", Vector2(302, 55)], ["escalera", Vector2(336, 35)]]}
			var boss_of := {2: ["orrun", Vector2(141, 16)], 3: ["vulkaris", Vector2(240, 16)], 4: ["azrahel", Vector2(336, 18)]}
			for stn in [2, 3, 4]:
				w._descend(stn)
				await get_tree().create_timer(2.6).timeout
				for st0 in stops[stn]:
					lp.respawn_at(w.tile_pos(st0[1].x, st0[1].y))
					await get_tree().create_timer(1.4).timeout
					await skip.call()
					await _shot(out + "/s%d_%s.png" % [stn, st0[0]])
				# mini-jefe de la prueba del estrato
				var tid: String = ["", "", "cienaga", "moldes", "galeria"][stn]
				var T: Dictionary = w.TRIALS[tid]
				var last: Array = T.waves[T.waves.size() - 1][0]
				lp.respawn_at(w.tile_pos(last[1], last[2] + 5))
				await get_tree().create_timer(0.8).timeout
				w._spawn_trial_enemy(last[0], w.tile_pos(last[1], last[2]))
				await get_tree().create_timer(2.2).timeout
				await _shot(out + "/s%d_minijefe.png" % stn)
				w._reset_enemies(true)
				w._trial_reset()
				# Arconte
				var bo: Array = boss_of[stn]
				lp.respawn_at(w.tile_pos(bo[1].x, bo[1].y))
				await get_tree().create_timer(1.6).timeout
				await _shot(out + "/s%d_arconte_intro.png" % stn)
				await skip.call()
				await get_tree().create_timer(2.5).timeout
				var be: Enemy = w._enemy_of(bo[0])
				print("ARCHON ", bo[0], " active=", be.active, " hp=", be.hp)
				for k2 in 4:
					await get_tree().create_timer(0.9).timeout
					await _shot(out + "/s%d_arconte_%d.png" % [stn, k2])
				w._server_damage(be.idx, be.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
				await get_tree().create_timer(1.5).timeout
				await _shot(out + "/s%d_arconte_fase2.png" % stn)
				for k3 in 3:
					await get_tree().create_timer(1.0).timeout
					await _shot(out + "/s%d_arconte_f2_%d.png" % [stn, k3])
				if stn == 4:
					w._server_damage(be.idx, be.max_hp * 0.25, Vector2.RIGHT, 0.0, false)
					await get_tree().create_timer(2.0).timeout
					await _shot(out + "/s4_arconte_fase3.png")
					for k4 in 3:
						await get_tree().create_timer(1.0).timeout
						await _shot(out + "/s4_arconte_f3_%d.png" % k4)
				w._server_damage(be.idx, be.max_hp, Vector2.RIGHT, 0.0, false)
				await get_tree().create_timer(4.5).timeout
				await _shot(out + "/s%d_arconte_muerte.png" % stn)
				for k5 in 20:
					if w.dialog.is_open():
						w.dialog._advance()
					await get_tree().create_timer(0.3).timeout
				await get_tree().create_timer(1.5).timeout
				await _shot(out + "/s%d_fin.png" % stn)
				await get_tree().create_timer(4.0).timeout
			await get_tree().create_timer(3.0).timeout
			await _shot(out + "/s9_creditos.png")
			print("STRATA flags orrun=", w.wflags.get("orrun_dead"), " vulkaris=", w.wflags.get("vulkaris_dead"), " azrahel=", w.wflags.get("azrahel_dead"), " base=", Prog.flags.get("base_complete"))
			print("ACH pct=", Ach.percent())
			print("AUTOTEST_STRATA_OK")
			get_tree().quit()
		"finale":
			var lp: Player = w.local_player()
			lp.iframes = 99999.0
			for b in ["seravel", "orrun", "vulkaris"]:
				w.wflags[b + "_dead"] = true
			w._descend(4)
			await get_tree().create_timer(2.5).timeout
			lp.respawn_at(w.tile_pos(336, 18))
			await get_tree().create_timer(1.6).timeout
			for k in 12:
				if w.dialog.is_open():
					w.dialog._advance()
				await get_tree().create_timer(0.15).timeout
			await get_tree().create_timer(2.0).timeout
			var be: Enemy = w._enemy_of("azrahel")
			await _shot(out + "/f00_azrahel.png")
			w._server_damage(be.idx, be.max_hp * 2.0, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(3.0).timeout
			for k2 in 14:
				await _shot(out + "/f1%02d_dialogo.png" % k2) if k2 % 3 == 0 else null
				if w.dialog.is_open():
					w.dialog._advance()
				await get_tree().create_timer(0.5).timeout
			await get_tree().create_timer(2.5).timeout
			await _shot(out + "/f20_grieta.png")
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/f21_fin.png")
			await get_tree().create_timer(2.2).timeout
			await _shot(out + "/f22_creditos.png")
			await get_tree().create_timer(1.0).timeout
			await _shot(out + "/f23_creditos.png")
			await get_tree().create_timer(4.0).timeout
			await _shot(out + "/f24_vuelta.png")
			print("FINALE base=", Prog.flags.get("base_complete"), " ending=", Ach.is_unlocked("ending"), " pct=", Ach.percent())
			print("AUTOTEST_FINALE_OK")
			get_tree().quit()
		"coopui":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			lp.respawn_at(w.tile_pos(49, 66))
			var mate: Player = w._spawn_player(77, 2)
			mate.set_look(Look.defaults_p2(), 7)
			mate.position = w.tile_pos(49, 60)
			mate.set("_net_pos", mate.position)
			mate.set("_net_hp_ratio", 0.62)
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/k01_companero_cerca.png")
			mate.position = w.tile_pos(80, 62)
			mate.set("_net_pos", mate.position)
			await get_tree().create_timer(0.8).timeout
			await _shot(out + "/k02_flecha.png")
			w._ping(Net.my_id(), w.tile_pos(56, 63))
			w._ping(77, w.tile_pos(40, 58))
			await get_tree().create_timer(0.8).timeout
			await _shot(out + "/k03_marcas.png")
			mate.state = "downed"
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/k04_caido.png")
			w.on_partner_revived(true)
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/k05_alas_unidas.png")
			print("AUTOTEST_COOPUI_OK")
			get_tree().quit()
		"verdugo":
			var lp: Player = w.local_player()
			Prog.level = 20
			Prog.attr.vigor = 12
			lp.refresh_stats(true)
			lp.iframes = 9999.0
			for k in Lore.GHOST_ECHOES.keys():
				Prog.flags["echo_" + k] = true
			w._open_cadalso(false)
			w.wflags["broken_capilla"] = true
			w._apply_world_flags(true)
			lp.respawn_at(w.tile_pos(84.5, 85.5))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/v01_reja_abierta.png")
			lp.respawn_at(w.tile_pos(84.5, 91.5))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/v02_cadalso.png")
			w._server_secret("verdugo")
			await get_tree().create_timer(1.6).timeout
			await _shot(out + "/v03_aparece.png")
			await get_tree().create_timer(2.6).timeout
			var vb: Enemy = w._enemy_of("verdugo")
			print("VERDUGO active=", vb.active, " vis=", vb.visible, " hp=", vb.hp)
			for k2 in 6:
				await get_tree().create_timer(0.7).timeout
				await _shot(out + "/v1%d_duelo.png" % k2)
			w._server_damage(vb.idx, vb.max_hp * 0.55, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(1.2).timeout
			await _shot(out + "/v20_fase2.png")
			for k3 in 6:
				await get_tree().create_timer(0.8).timeout
				await _shot(out + "/v3%d_fase2.png" % k3)
			w._server_damage(vb.idx, vb.max_hp, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(4.5).timeout
			await _shot(out + "/v40_recompensa.png")
			print("VERDUGO weapon=", Prog.weapons.has("verdugo"), " ach=", Ach.is_unlocked("sb_verdugo"))
			Prog.equipped = "verdugo"
			lp._update_weapon_sprite()
			for k4 in 3:
				lp.stamina = Prog.max_stamina()
				lp.state = "move"
				lp.combo_window = 0.3
				lp.aim = Vector2.RIGHT
				lp._start_attack()
				await get_tree().create_timer(0.4).timeout
			await _shot(out + "/v41_hoja.png")
			print("AUTOTEST_VERDUGO_OK")
			get_tree().quit()
		"coloso":
			var lp: Player = w.local_player()
			Prog.level = 20
			Prog.attr.vigor = 12
			lp.refresh_stats(true)
			lp.iframes = 9999.0
			w.wflags["seravel_dead"] = true
			lp.respawn_at(w.tile_pos(32, 84))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/c01_muro.png")
			w.wflags["broken_cornisa"] = true
			w._apply_world_flags(true)
			lp.respawn_at(w.tile_pos(24, 70))
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/c02_cornisa.png")
			w._server_secret("coloso")
			for k in 4:
				await get_tree().create_timer(1.1).timeout
				await _shot(out + "/c0%d_alzarse.png" % (k + 3))
			await get_tree().create_timer(1.0).timeout
			var cb: Enemy = w._enemy_of("coloso")
			print("COLOSO active=", cb.active, " hp=", cb.hp)
			for k2 in 10:
				await get_tree().create_timer(0.75).timeout
				await _shot(out + "/c1%d_combate.png" % k2)
				if cb.get("_vuln"):
					print("COLOSO vulnerable at ", cb.global_position)
					w._server_damage(cb.idx, 60.0, Vector2.ZERO, 0.0, false)
			cb.hp = cb.max_hp * 0.52
			w._server_damage(cb.idx, cb.max_hp * 0.05, Vector2.ZERO, 0.0, false)
			cb.set("_vuln", true)
			w._server_damage(cb.idx, cb.max_hp * 0.05, Vector2.ZERO, 0.0, false)
			await get_tree().create_timer(1.0).timeout
			await _shot(out + "/c20_fase2.png")
			for k3 in 8:
				await get_tree().create_timer(0.8).timeout
				await _shot(out + "/c3%d_fase2.png" % k3)
			cb.set("_vuln", true)
			w._server_damage(cb.idx, cb.max_hp, Vector2.ZERO, 0.0, false)
			await get_tree().create_timer(1.5).timeout
			await _shot(out + "/c40_cae.png")
			await get_tree().create_timer(3.0).timeout
			await _shot(out + "/c41_recompensa.png")
			print("COLOSO storm=", Prog.flags.get("storm_wing", false), " ach=", Ach.is_unlocked("sb_coloso"))
			lp.respawn_at(w.tile_pos(24, 70))
			lp._start_dash(Vector2.RIGHT)
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/c42_ala_tormenta.png")
			print("AUTOTEST_COLOSO_OK")
			get_tree().quit()
		"weapons":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			for ar in ["area_chains", "area_gallery"]:
				Prog.flags["thought_" + ar] = true
			for wid in ["reaper", "staff", "fists", "bow"]:
				Prog.add_weapon(wid)
			var n := 1
			for wid in ["reaper", "staff", "fists", "bow"]:
				Prog.equipped = wid
				lp._update_weapon_sprite()
				lp.respawn_at(w.tile_pos(47, 62))
				await get_tree().create_timer(1.2).timeout
				var tgt: Enemy = null
				for e in w.enemies_alive():
					if not e.is_boss and e.global_position.distance_to(lp.global_position) < 200.0:
						tgt = e
						break
				if tgt:
					lp.aim = (tgt.global_position - lp.global_position).normalized()
				lp.hp = Prog.max_hp() * 0.5
				var hp0: float = lp.hp
				for k in 3:
					lp.stamina = Prog.max_stamina()
					lp.state = "move"
					lp.combo_window = 0.3
					lp._start_attack()
					await get_tree().create_timer(0.38).timeout
				await _shot(out + "/w%d_%s.png" % [n, wid])
				if wid == "staff" or wid == "bow":
					lp.state = "move"
					lp.heavy_charge = 0.8
					lp.stamina = Prog.max_stamina()
					lp._release_heavy()
					await get_tree().create_timer(1.0).timeout
					await _shot(out + "/w%d_%s_cargado.png" % [n, wid])
				print("WEAPON ", wid, " hp ", hp0, " -> ", lp.hp)
				n += 1
			print("AUTOTEST_WEAPONS_OK")
			get_tree().quit()
		"urn":
			var lp: Player = w.local_player()
			lp.iframes = 9999.0
			print("URNS=", w.urns.size())
			var u: Node2D = w.urns[4]
			lp.respawn_at(u.global_position + Vector2(0, 14))
			await get_tree().create_timer(4.5).timeout
			await _shot(out + "/u01_urna.png")
			var e0 := Prog.ecos
			for i in 2:
				lp.state = "move"
				lp.aim = Vector2.UP
				lp._start_attack()
				await get_tree().create_timer(0.45).timeout
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/u02_rota.png")
			for k in range(10, 20):
				w.urns[k].smash(true)
			print("URN broken=", u.broken, " ecos ", e0, "->", Prog.ecos)
			print("AUTOTEST_URN_OK")
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
			for kt in ["hueco", "acolito", "guardia", "carcelero"]:
				Prog.flags["killed_" + kt] = true
			for ak in ["first_blood", "jailer", "secret", "bells"]:
				Prog.flags["ach_" + ak] = true
			Ach.import_legacy(["first_blood", "jailer", "secret", "bells", "awaken", "first_brasa", "nimbo"])
			Ach.set_max("kills", 37)
			Ach.set_max("urns", 12)
			for qid in ["feathers", "husks", "hymns", "jailer_hunt"]:
				Prog.start_quest(qid)
			Prog.quest_progress("feathers", 3)
			Prog.quest_progress("hymns", 1)
			Prog.quest_step("main1", "brasa")
			Prog.quest_step("main1", "talk_brenna")
			for tb in ["char", "skills", "inventory", "weapons", "quests", "codex", "map", "options"]:
				w.menu.open(tb, {"brasa": true, "forge": true})
				await get_tree().create_timer(0.8).timeout
				await _shot(out + "/m_%s.png" % tb)
				w.menu.close()
				if tb == "codex":
					w.menu.open("codex", {})
					w.menu._on_codex("_ach")
					await get_tree().create_timer(0.6).timeout
					await _shot(out + "/m_logros.png")
					w.menu.close()
					for kn in ["brenna", "ozias", "nyx", "preso", "ilse"]:
						Prog.flags["known_" + kn] = true
					w.menu.open("codex", {})
					w.menu._on_codex("_npc")
					await get_tree().create_timer(0.6).timeout
					await _shot(out + "/m_personajes.png")
					w.menu.close()
					w.menu.open("codex", {})
					w.menu._on_codex("carcelero")
					await get_tree().create_timer(0.6).timeout
					await _shot(out + "/m_codex_jefe.png")
					w.menu.close()
					Prog.flags["killed_seravel"] = true
					w.menu.open("codex", {})
					w.menu._on_codex("seravel")
					await get_tree().create_timer(0.6).timeout
					await _shot(out + "/m_codex_seravel.png")
					w.menu.close()
					w.menu.open("service", {"npc": "nyx"})
					await get_tree().create_timer(0.6).timeout
					await _shot(out + "/m_servicio.png")
					w.menu.close()
				if tb == "quests":
					w.menu._quest_sel = "feathers"
					w.menu.open("quests", {})
					await get_tree().create_timer(0.6).timeout
					await _shot(out + "/m_quests2.png")
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
		"prologue":
			# recorre el tutorial entero pulsando lo que pide; comprueba que acaba en el Santuario y con el jefe vencido
			var lp_p: Player = w.local_player()
			var waited := 0.0
			while w._prologue == null and waited < 8.0:
				await get_tree().create_timer(0.1).timeout
				waited += 0.1
			var pr: Node = w._prologue
			print("PROLOGUE room=", w.room_at(lp_p.global_position), " prologue=", pr != null)
			var log_steps := []
			var t_all := 0.0
			var shot_n := 0
			while is_instance_valid(pr) and not pr.done and t_all < 150.0:
				await get_tree().create_timer(0.25, true).timeout
				t_all += 0.25
				var act: String = pr.expect()
				if act != "" and (log_steps.is_empty() or log_steps[-1] != act):
					log_steps.append(act)
				if pr.is_frozen() and shot_n < 4 and out != "":
					shot_n += 1
					await _shot(out + "/pr%d_%s.png" % [shot_n, act])
				match act:
					"":
						pass
					"_move":
						lp_p.position += Vector2(30, 0) if int(t_all * 4.0) % 2 == 0 else Vector2(-30, 0)
					"menu":
						w.menu.open("char", {})
						await get_tree().create_timer(0.3, true).timeout
						w.menu.close()
					"map":
						w.menu.open("map", {})
						await get_tree().create_timer(0.3, true).timeout
						w.menu.close()
					"heavy":
						var evp := InputEventAction.new()
						evp.action = "heavy"
						evp.pressed = true
						Input.parse_input_event(evp)
						await get_tree().create_timer(0.3, true).timeout
						var evr := InputEventAction.new()
						evr.action = "heavy"
						evr.pressed = false
						Input.parse_input_event(evr)
					_:
						var ev := InputEventAction.new()
						ev.action = act
						ev.pressed = true
						Input.parse_input_event(ev)
						await get_tree().process_frame
						var ev2 := InputEventAction.new()
						ev2.action = act
						ev2.pressed = false
						Input.parse_input_event(ev2)
			print("PROLOGUE pasos=", log_steps, " t=", t_all, " done=", pr.done if is_instance_valid(pr) else "freed", " hp=", lp_p.hp, " ira=", lp_p.wrath)
			await _shot(out + "/pr9_salida.png")
			var it: Interactable = w.interactables.get("prologue_rift")
			if it:
				lp_p.position = it.position + Vector2(0, 10)
				await get_tree().create_timer(0.2).timeout
				w.try_interact(lp_p)
			await get_tree().create_timer(3.5).timeout
			var r_end: String = w.room_at(lp_p.global_position)
			print("PROLOGUE fin room=", r_end, " boss_vivo=", w.active_boss != null, " main1=", Prog.quests.get("main1"), " paused=", get_tree().paused)
			await _shot(out + "/pr10_santuario.png")
			var ok_p: bool = r_end == "sanct" and w._prologue == null and Prog.quest_active("main1") and not get_tree().paused
			print("AUTOTEST_PROLOGUE_OK" if ok_p else "AUTOTEST_PROLOGUE_FAIL")
			get_tree().quit()
		"economy":
			# reparto real de Ecos y puntos: una partida entera sin farmear, por estrato. Falla si se dispara.
			var by := {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0}
			var sp_by := {1: 0, 2: 0, 3: 0, 4: 0}
			var shards := 0
			var irons := 0
			var tears := 0
			var flask_rew := 0
			var phoenix := 0
			for en in w.enemies:
				if en.type == "eco_tutor" or en.type in ["verdugo", "coloso"]:
					continue
				by[Strata.stratum_of_room(w.room_at(en.spawn_pos))] += float(en.cfg.ecos)
			var stat_room := {"carcelero": 1, "choir": 1, "seravel": 1, "orrun": 2, "vulkaris": 3, "azrahel": 4}
			for tr5 in w.TRIALS:
				var st5 := Strata.stratum_of_room(w.TRIALS[tr5].room)
				for wv5 in w.TRIALS[tr5].waves:
					for sp5 in wv5:
						by[st5] += float(Enemy.TYPES[sp5[0]].ecos)
				var rw5: Dictionary = w.TRIALS[tr5].reward
				by[st5] += float(rw5.get("ecos", 0))
				shards += int(rw5.get("feathers", 0))
				irons += int(rw5.get("items", {}).get("iron", 0))
				tears += int(rw5.get("items", {}).get("tear", 0))
			for ik in w.interactables:
				var it5: Interactable = w.interactables[ik]
				if it5.kind != "chest":
					continue
				var st6 := Strata.stratum_of_room(w.room_at(it5.position))
				by[st6] += float(it5.data.get("ecos", 0))
				shards += int(it5.data.get("feathers", 0))
				irons += int(it5.data.get("items", {}).get("iron", 0))
				tears += int(it5.data.get("items", {}).get("tear", 0))
				phoenix += int(it5.data.get("items", {}).get("phoenix", 0))
			var q_st := {"main1": 1, "main2": 2, "main3": 3, "main4": 4, "eggs": 2, "names": 3, "roses": 4, "feathers": 1, "husks": 1, "map": 1, "choir": 1, "hymns": 1, "jailer_hunt": 1,
				"cirios": 1, "hilos": 2, "moldes_r": 3, "sellos": 4, "hunt_guardias": 1, "hunt_penitentes": 1, "hunt_musgosos": 2, "hunt_garzas": 2, "hunt_ascuas": 3, "hunt_forjadores": 3, "hunt_cortesanos": 4, "hunt_caballeros": 4}
			for qk in Prog.QUESTS:
				var rq: Dictionary = Prog.QUESTS[qk].reward
				var st7: int = int(q_st.get(qk, 1))
				by[st7] += float(rq.get("ecos", 0))
				sp_by[st7] += int(rq.get("sp", 0))
				shards += int(rq.get("feathers", 0))
				flask_rew += int(rq.get("flask", 0))
			for bs in stat_room:
				by[stat_room[bs]] += float(Enemy.TYPES[bs].ecos)
			# gasto supuesto: 70% en niveles, 30% en mejorar un arma; +15% de media por Resonancia en las bajas
			var bank := 0.0
			var lvl := 1
			var total_sp := 1
			var wlv := 0
			var wbank := 0.0
			var tree_cost := 0
			for sk5 in Prog.SKILLS:
				if not Prog.SKILLS[sk5].has("excl") or str(sk5) < str(Prog.SKILLS[sk5].excl):
					tree_cost += int(Prog.SKILLS[sk5].cost)
			var bad5 := []
			for st8 in [1, 2, 3, 4]:
				bank += by[st8] * 1.15 * 0.7
				wbank += by[st8] * 1.15 * 0.3
				while true:
					var lc := Prog.level_cost(lvl)
					if bank < lc:
						break
					bank -= lc
					lvl += 1
					total_sp += 1
				while wlv < 10:
					var uc: Array = Prog.upgrade_cost_at(wlv)
					if wbank < uc[0]:
						break
					wbank -= uc[0]
					wlv += 1
				total_sp += int(sp_by[st8])
				print("ECONOMY estrato ", st8, ": ecos=", int(by[st8]), " nivel=", lvl, " puntos_totales=", total_sp, " arma=+", wlv)
			print("ECONOMY arbol_coste=", tree_cost, " fragmentos=", shards, " esquirlas=", irons, " lagrimas=", tears, " lagrimas_extra=", flask_rew, " plumones=", phoenix)
			if lvl < 16 or lvl > 34:
				bad5.append("nivel final fuera de rango: %d" % lvl)
			if float(total_sp) / tree_cost > 0.6:
				bad5.append("se puede comprar demasiado árbol: %d/%d" % [total_sp, tree_cost])
			if wlv >= 10:
				bad5.append("un arma al máximo demasiado fácil")
			# los jefes aprietan incluso en las dificultades bajas
			for dd5 in Prog.DIFFICULTIES:
				if not dd5.phase3 or float(dd5.boss_hp) < 0.8 or float(dd5.boss_dmg) < 0.6:
					bad5.append("jefe blando en " + str(dd5.name[0]))
			# la furia final y el Cataclismo funcionan de principio a fin
			var lp5: Player = w.local_player()
			lp5.iframes = 9999.0
			var ca5: Enemy = w._enemy_of("carcelero")
			lp5.respawn_at(w.tile_pos(49, 40))
			var t5 := 0.0
			while w.active_boss != ca5 and t5 < 30.0:
				await get_tree().create_timer(0.25).timeout
				t5 += 0.25
			w._server_damage(ca5.idx, ca5.max_hp * 0.8, Vector2.RIGHT, 0.0, false)
			await get_tree().create_timer(0.5).timeout
			print("ECONOMY furia=", ca5.fury, " vida=", int(ca5.hp), "/", int(ca5.max_hp))
			if not ca5.fury:
				bad5.append("sin furia final")
			lp5.hp = Prog.max_hp()
			ca5.state = "chase"
			ca5._cat_t = 0.0
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/e01_cataclismo.png")
			await get_tree().create_timer(2.0).timeout
			await _shot(out + "/e02_cataclismo.png")
			await get_tree().create_timer(4.0).timeout
			print("ECONOMY tras_cataclismo estado=", ca5.state)
			if ca5.state == "busy" and ca5._attack_id == 0:
				bad5.append("cataclismo sin lanzar")
			for b5 in bad5:
				print("FALLO ", b5)
			print("AUTOTEST_ECONOMY_OK" if bad5.is_empty() else "AUTOTEST_ECONOMY_FAIL")
			get_tree().quit()
		"retry":
			# jefe: la primera vez con presentación; al morir y volver, directo a la pelea y con su barra
			var lpr: Player = w.local_player()
			var bad_r := []
			var car: Enemy = w._enemy_of("carcelero")
			w.set_gate(false, true)
			lpr.respawn_at(w.tile_pos(49, 40))
			lpr.iframes = 9999.0
			var wr := 0.0
			while w.active_boss != car and wr < 30.0:
				await get_tree().create_timer(0.25).timeout
				wr += 0.25
			print("RETRY primera vez t=", wr, " barra=", w.hud.boss_panel.visible, " sellos=", w._seals.size())
			if not (w.active_boss == car and w.hud.boss_panel.visible and w._seals.size() > 0):
				bad_r.append("el primer combate no arranca bien")
			lpr.iframes = 0.0
			lpr.take_hit(99999.0, Vector2.RIGHT, -1)
			await get_tree().create_timer(5.0).timeout
			print("RETRY tras morir jefe=", w.active_boss, " activo=", car.active, " sellos=", w._seals.size(), " sala=", w.room_at(lpr.global_position), " plumas=", Prog.wing_feathers)
			if w.active_boss != null or car.active or not w._seals.is_empty():
				bad_r.append("al morir el jefe no vuelve a dormir")
			lpr.respawn_at(w.tile_pos(49, 40))
			lpr.iframes = 9999.0
			wr = 0.0
			while w.active_boss != car and wr < 4.0:
				await get_tree().create_timer(0.1).timeout
				wr += 0.1
			await get_tree().create_timer(0.6).timeout
			print("RETRY segunda vez t=", wr, " barra=", w.hud.boss_panel.visible, " activo=", car.active, " sellos=", w._seals.size(), " cinematica_en_curso=", w.get_children().filter(func(c): return c.has_signal("finished")).size())
			if wr >= 4.0 or not w.hud.boss_panel.visible or not car.active or w._seals.is_empty():
				bad_r.append("el reintento no va directo a la pelea con barra")
			w._reset_enemies(true)
			# Arconte: el reintento tampoco repite diálogo
			Prog.flags["cine_orrun"] = true
			Prog.flags["trial_b_puerta"] = true
			w.wflags["trial_b_puerta"] = true
			w._refresh_locks(true)
			lpr.respawn_at(w.tile_pos(141, 14))
			await get_tree().create_timer(1.0).timeout
			var oru: Enemy = w._enemy_of("orrun")
			print("RETRY orrun jefe=", w.active_boss == oru, " barra=", w.hud.boss_panel.visible, " dialogo=", w.dialog.is_open(), " sellos=", w._seals.size())
			if w.active_boss != oru or not w.hud.boss_panel.visible or w.dialog.is_open() or w._seals.is_empty():
				bad_r.append("el Arconte repite presentación o no tiene barra")
			for b_r in bad_r:
				print("FALLO ", b_r)
			print("AUTOTEST_RETRY_OK" if bad_r.is_empty() else "AUTOTEST_RETRY_FAIL")
			get_tree().quit()
		"content":
			# comprueba el mapa y los datos: nada en un muro, todo alcanzable, todas las pruebas se pueden completar
			var bad := []
			# 1) inundación desde cada llegada: todas las salas del estrato alcanzables a pie
			var starts := {1: Vector2i(49, 86), 2: Vector2i(143, 87), 3: Vector2i(239, 87), 4: Vector2i(335, 87)}
			var seen := {}
			for st0 in starts:
				var stack: Array[Vector2i] = [starts[st0]]
				while not stack.is_empty():
					var c9: Vector2i = stack.pop_back()
					if seen.has(c9) or not w._floor_at(c9.x, c9.y):
						continue
					seen[c9] = true
					for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						stack.append(c9 + dd)
			for rm in w.ROOMS:
				if rm.id == "prologo":
					continue
				var rc9: Rect2i = w._rect_of(rm)
				var any9 := false
				for y9 in range(rc9.position.y, rc9.end.y):
					for x9 in range(rc9.position.x, rc9.end.x):
						if seen.has(Vector2i(x9, y9)):
							any9 = true
				if not any9:
					bad.append("sala inalcanzable: " + str(rm.id))
				if not w.AREAS.has(rm.id):
					bad.append("sala sin área: " + str(rm.id))
				elif not G.TXT.has(w.AREAS[rm.id]):
					bad.append("área sin nombre: " + str(w.AREAS[rm.id]))
			# 2) enemigos en su sala y sin mezclarse
			for e9 in w.enemies:
				if not e9.is_boss and e9.home_room == "":
					bad.append("enemigo fuera de sala: %s %s" % [e9.type, e9.spawn_pos / 16.0])
			# 3) interactuables sobre suelo
			for k9 in w.interactables:
				var it9: Interactable = w.interactables[k9]
				if w.is_wall_at(it9.position) and it9.kind != "bench":
					bad.append("objeto en muro: %s %s" % [k9, it9.position / 16.0])
			# 4) pruebas: oleadas dentro de su sala y títulos con texto
			for tr9 in w.TRIALS:
				var T9: Dictionary = w.TRIALS[tr9]
				if not G.TXT.has(T9.title):
					bad.append("prueba sin título: " + tr9)
				for wv in T9.waves:
					for sp9 in wv:
						if w.room_at(w.tile_pos(sp9[1], sp9[2])) != T9.room:
							bad.append("oleada fuera de sala: %s %s" % [tr9, sp9])
						if not Enemy.TYPES.has(sp9[0]):
							bad.append("tipo desconocido: " + str(sp9[0]))
				if w.room_at(w.tile_pos(T9.chest.x, T9.chest.y)) != T9.room:
					bad.append("cofre de prueba fuera: " + tr9)
			# 5) textos de los élites, misiones y árbol
			for ty9 in Enemy.TYPES:
				var cf9: Dictionary = Enemy.TYPES[ty9]
				if cf9.has("title") and not G.TXT.has(cf9.title):
					bad.append("élite sin nombre: " + ty9)
				if not ResourceLoader.exists("res://assets/sprites/%s.png" % cf9.sheet):
					bad.append("hoja inexistente: " + str(cf9.sheet))
			for q9 in Prog.QUESTS:
				if Prog.QUESTS[q9].has("kill") and not Enemy.TYPES.has(Prog.QUESTS[q9].kill):
					bad.append("caza sin enemigo: " + q9)
			for sk9 in Prog.SKILLS:
				var s9: Dictionary = Prog.SKILLS[sk9]
				for rq in s9.req + s9.get("any", []):
					if not Prog.SKILLS.has(rq):
						bad.append("nodo sin requisito: " + sk9)
			for wp in Prog.WEAPONS:
				if not (Prog.WEAPON_ARTS.has(wp) and Prog.WEAPON_AWAKE.has(wp)):
					bad.append("arma sin Arte o Despertar: " + wp)
				if not ResourceLoader.exists("res://assets/sprites/weapon_%s.png" % Prog.WEAPONS[wp].sprite):
					bad.append("arma sin sprite: " + wp)
			print("CONTENT salas=", w.ROOMS.size(), " enemigos=", w.enemies.size(), " objetos=", w.interactables.size(), " misiones=", Prog.QUESTS.size(), " pruebas=", w.TRIALS.size(), " armas=", Prog.WEAPONS.size(), " nodos=", Prog.SKILLS.size())
			# 6) cada prueba nueva se completa de verdad y abre la puerta
			var lp8: Player = w.local_player()
			for tr8 in ["osario", "raices", "copas", "escoria", "cadena", "mazmorra", "oratorio"]:
				var T8: Dictionary = w.TRIALS[tr8]
				lp8.respawn_at(w.tile_pos(T8.chest.x - 1.0, T8.chest.y + 2.0))
				lp8.iframes = 999.0
				var guard := 0
				await get_tree().create_timer(0.8).timeout
				while w._trial != "" and guard < 200:
					guard += 1
					await get_tree().create_timer(0.3).timeout
					lp8.hp = Prog.max_hp()
					for e8 in w.enemies.duplicate():
						if e8.is_alive() and e8.get_meta("trial", false):
							w._server_damage(e8.idx, 99999.0, Vector2.RIGHT, 0.0, false)
				if not w.trial_done(tr8):
					bad.append("prueba sin completar: " + tr8)
				print("CONTENT prueba ", tr8, " hecha=", w.trial_done(tr8), " sala=", w.room_at(lp8.global_position))
				await get_tree().create_timer(0.3).timeout
			print("CONTENT puertas b=", w.trial_done("b_puerta"), " f=", w.trial_done("f_puerta"), " t=", w.trial_done("t_puerta"), " armas=", Prog.weapons.keys())
			if not (w.trial_done("b_puerta") and w.trial_done("f_puerta") and w.trial_done("t_puerta")):
				bad.append("puertas sin abrir")
			# 7) sala cerrada: se cierra, despierta por tandas y se abre al limpiarla; al morir sigue limpia
			lp8.iframes = 999.0
			lp8.respawn_at(w.tile_pos(166, 82))
			await get_tree().create_timer(0.5).timeout
			var locked_ok: bool = w.room_lock == "b_charca"
			var awake_n := 0
			for e7 in w._room_enemies("b_charca"):
				if e7.active:
					awake_n += 1
			print("CONTENT cerrada=", w.room_lock, " activos=", awake_n, " sellos=", w._seals.size())
			var g7 := 0
			while w.room_lock != "" and g7 < 60:
				g7 += 1
				for e7b in w._room_enemies("b_charca"):
					if e7b.active:
						w._server_damage(e7b.idx, 99999.0, Vector2.RIGHT, 0.0, false)
				await get_tree().create_timer(0.3).timeout
			print("CONTENT abierta=", w.room_lock == "", " limpia=", w.wflags.get("clear_b_charca", false), " sellos=", w._seals.size())
			if not locked_ok or w.room_lock != "" or not w.wflags.get("clear_b_charca", false):
				bad.append("sala cerrada no funciona")
			w._reset_enemies(false)
			if not w._room_enemies("b_charca").is_empty():
				bad.append("sala limpia reaparece al morir")
			w._reset_enemies(true)
			if w._room_enemies("b_charca").is_empty():
				bad.append("sala no reaparece al descansar")
			# 8) los enemigos no salen de su sala ni te siguen
			var e6: Enemy = w._room_enemies("b_charca")[0]
			lp8.respawn_at(w.tile_pos(156, 83))
			await get_tree().create_timer(2.0).timeout
			if w.room_at(e6.global_position) != "b_charca":
				bad.append("enemigo salió de su sala")
			print("CONTENT enemigo sala=", w.room_at(e6.global_position), " estado=", e6.state, " jugador sala=", w.room_at(lp8.global_position))
			# 9) pluma por Brasa
			var fb9 := Prog.wing_feathers
			w.interactables["copas"].used = false
			lp8.respawn_at(w.interactables["copas"].position + Vector2(0, 8))
			await get_tree().create_timer(0.2).timeout
			w.exec_target = null
			w.try_interact(lp8)
			print("CONTENT plumas ", fb9, " -> ", Prog.wing_feathers)
			if Prog.wing_feathers != fb9 - 1:
				bad.append("la Brasa no cobra pluma")
			for b9 in bad:
				print("FALLO ", b9)
			print("AUTOTEST_CONTENT_OK" if bad.is_empty() else "AUTOTEST_CONTENT_FAIL %d" % bad.size())
			get_tree().quit()
		"v9":
			# recorre lo nuevo: Artes de todas las armas, Pluma Dorada, parry, anuncios, menús y modos de combate
			var lp9: Player = w.local_player()
			lp9.respawn_at(w.tile_pos(46, 62))
			await get_tree().create_timer(0.6).timeout
			print("V9 sala=", w.room_at(lp9.global_position), " cerrada=", w.room_lock, " activos=", w.enemies_alive().filter(func(e): return e.active and e.home_room == "chains").size())
			await _shot(out + "/v01_sala_cerrada.png")
			Prog.flags["ab_lance"] = true
			Prog.flags["ab_wrath"] = true
			Prog.flags["ab_art"] = true
			for wid in Prog.WEAPONS:
				Prog.weapons[wid] = 0
			lp9.light = 60.0
			lp9.aim = Vector2.RIGHT
			lp9._cast_lance()
			await get_tree().create_timer(0.3).timeout
			await _shot(out + "/v02_pluma_dorada.png")
			await get_tree().create_timer(1.2).timeout
			var n_art := 0
			for wid2 in Prog.WEAPONS:
				Prog.equipped = wid2
				lp9.art_cd = 0.0
				lp9.state = "move"
				lp9.cutscene = false
				lp9.hp = Prog.max_hp()
				lp9._update_weapon_sprite()
				lp9._cast_art()
				n_art += 1
				await get_tree().create_timer(0.45).timeout
				if wid2 in ["yunque", "reaper", "seravel"]:
					await _shot(out + "/v03_arte_%s.png" % wid2)
				await get_tree().create_timer(1.0).timeout
			print("V9 artes=", n_art)
			Prog.equipped = "sword"
			lp9.state = "move"
			# parry perfecto y normal contra un golpe real
			lp9.stamina = 100.0
			lp9._start_parry()
			var r1: String = lp9.take_hit(5.0, Vector2.RIGHT, -1)
			var p1: bool = lp9.last_parry_perfect
			await get_tree().create_timer(0.6).timeout
			lp9.state = "move"
			lp9.iframes = 0.0
			lp9._start_parry()
			lp9.parry_window = lp9.parry_total - lp9.parry_perfect - 0.02
			var r2: String = lp9.take_hit(5.0, Vector2.RIGHT, -1)
			var p2: bool = lp9.last_parry_perfect
			print("V9 parry1=", r1, " perfecto=", p1, " parry2=", r2, " perfecto=", p2)
			await get_tree().create_timer(0.5).timeout
			# modos de combate
			for md in [1, 2, 0]:
				G.combat_mode = md
				await get_tree().create_timer(0.3).timeout
				if md == 2:
					await _shot(out + "/v04_modo_camara.png")
			w._reset_enemies(true)
			await get_tree().create_timer(0.3).timeout
			lp9.respawn_at(w.tile_pos(49, 88))
			await get_tree().create_timer(0.5).timeout
			# anuncio épico
			lp9.cutscene = false
			Prog.reveal_ability("wrath")
			await get_tree().create_timer(0.35).timeout
			var was_auto := G.autotest
			await get_tree().create_timer(0.6).timeout
			await _shot(out + "/v05_anuncio.png")
			await get_tree().create_timer(1.2).timeout
			print("V9 autotest=", was_auto, " cutscene=", lp9.cutscene)
			# menús
			Prog.ecos = 90000
			Prog.feathers = 40
			Prog.skill_points = 40
			Prog.add_item("iron", 9, true)
			Prog.add_item("tear", 9, true)
			for fl in ["carcelero_dead", "choir_dead", "seravel_dead", "orrun_dead"]:
				Prog.flags[fl] = true
			for sk in ["f1", "f2", "f3", "f4", "f5", "f6", "f7", "f11", "a1", "a2", "p1", "p3", "k1", "k2", "l1", "l2"]:
				Prog.unlock(sk)
			w.menu.open("skills", {"brasa": true})
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/v06_arbol_filo.png")
			for br in ["pluma", "arconte", "luz"]:
				w.menu._on_branch(br)
				await get_tree().create_timer(0.35).timeout
				await _shot(out + "/v07_arbol_%s.png" % br)
			print("V9 nodos=", Prog.SKILLS.size(), " ramas filo=", Prog.branch_count("filo"), " maestria=", Prog.mastery("filo"))
			Prog.upgrade_weapon("sword"); Prog.upgrade_weapon("sword"); Prog.upgrade_weapon("sword")
			w.menu.tab = "weapons"; w.menu.ctx = {"forge": true}; w.menu._sel_weapon = "sword"; w.menu._rebuild()
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/v08_armas.png")
			Prog.weapons["reaper"] = 5
			w.menu._sel_weapon = "reaper"; w.menu._weapon_page = 1; w.menu._rebuild()
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/v09_armas2.png")
			w.menu.tab = "quests"; w.menu.ctx = {}; w.menu._rebuild()
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/v10_misiones.png")
			Prog.flags.erase("ab_wrath")
			w.menu.tab = "controls"; w.menu._rebuild()
			await get_tree().create_timer(0.4).timeout
			await _shot(out + "/v11_controles.png")
			Prog.flags["ab_wrath"] = true
			w.menu.tab = "options"; w.menu._rebuild()
			await get_tree().create_timer(0.4).timeout
			await _shot(out + "/v12_opciones.png")
			w.menu.close()
			Prog.ecos = 1234
			Prog.resonance = 3
			Prog.res_t = 15.0
			await get_tree().create_timer(0.5).timeout
			await _shot(out + "/v13_hud.png")
			print("AUTOTEST_V9_OK")
			get_tree().quit()
		"lobby_host":
			# el cliente sale al acabar su prueba: basta con ver una vez los dos jugadores y el daño compartido
			var e0: Enemy = w.enemies[0]
			var seen_two := false
			var seen_lock := false
			var seen_unlock := false
			for _i in 100:
				await get_tree().create_timer(0.2).timeout
				if w.joined_peers.size() == 1 and w.players.size() == 2 and e0.hp < e0.max_hp:
					seen_two = true
				if w.room_lock == "chains":
					seen_lock = true
				elif seen_lock:
					seen_unlock = true
				if seen_two and seen_unlock:
					break
			print("LOBBY_HOST dos_jugadores=", seen_two, " sala_cerrada_por_el_cliente=", seen_lock, " reabierta=", seen_unlock, " enemy0_hp=", e0.hp, "/", e0.max_hp)
			print("AUTOTEST_LOBBY_HOST_OK" if seen_two and seen_lock and seen_unlock else "AUTOTEST_LOBBY_HOST_FAIL")
			await get_tree().create_timer(5.0).timeout  # deja acabar al cliente
			get_tree().quit()
		"lobby_join":
			await get_tree().create_timer(4.0).timeout
			var me: Player = w.local_player()
			print("LOBBY_JOIN players=", w.players.keys(), " my=", Net.my_id(), " joined=", w.joined_peers, " dif=", w.world_difficulty)
			w.request_damage_enemy(w.enemies[0], 5.0, Vector2.RIGHT, 1.0, false)
			await get_tree().create_timer(1.5).timeout
			var e1: Enemy = w.enemies[0]
			print("LOBBY_JOIN enemy0_hp=", e1.hp, "/", e1.max_hp)
			var ok_j: bool = me != null and w.players.size() == 2 and w.joined_peers == [1] and e1.hp < e1.max_hp
			# el cliente entra en una sala con enemigos: se cierra en los dos, y las RPC nuevas funcionan
			me.position = w.tile_pos(46, 62)
			await get_tree().create_timer(1.2).timeout
			var lock_j: String = w.room_lock
			var seals_j: int = w._seals.size()
			w.request_parry_enemy(w._room_enemies("chains")[0].idx, false)
			# limpia la sala desde el cliente: se reabre en los dos
			var g_j := 0
			while w.room_lock != "" and g_j < 60:
				g_j += 1
				for ej in w._room_enemies("chains"):
					w.request_damage_enemy(ej, 99999.0, Vector2.RIGHT, 0.0, false)
				await get_tree().create_timer(0.3).timeout
			await get_tree().create_timer(1.0).timeout
			print("LOBBY_JOIN sala=", lock_j, " sellos=", seals_j, " tras_limpiar=", w.room_lock, " sellos=", w._seals.size())
			ok_j = ok_j and lock_j == "chains" and seals_j > 0 and w.room_lock == "" and w._seals.is_empty()
			print("AUTOTEST_LOBBY_JOIN_OK" if ok_j else "AUTOTEST_LOBBY_JOIN_FAIL")
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
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame  # sin pantalla no hay fotograma que capturar
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT ", path)

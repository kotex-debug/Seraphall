extends CanvasLayer
## Prólogo opcional en una sala aparte (la Cuna de Ceniza). Un jefe sencillo, el Eco del Instructor, enseña las
## mecánicas: cuando llega el momento de reaccionar el juego se detiene, se explica y se espera tu pulsación.
## Termina cruzando una grieta que lleva al Santuario, donde empieza la partida de verdad.

signal _resumed

const ROOM_CENTER := Vector2(17, 16)

var world: Node
var _boss: Enemy
var _frozen := false
var _wait_action := ""
var _box_action := ""
var _box_release := false
var _box_title := ""
var _box_text := ""
var _box_count := 0
var _box_need := 0
var _step := 0
var _t := 0.0
var _finishing := false
var box: PrologueBox
var overlay: FreezeOverlay
var done := false

const TOTAL_STEPS := 11

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	box = PrologueBox.new()
	box.owner_p = self
	box.position = Vector2(150, 40)
	box.size = Vector2(340, 74)
	box.visible = false
	add_child(box)
	overlay = FreezeOverlay.new()
	overlay.size = Vector2(640, 360)
	overlay.visible = false
	add_child(overlay)
	world.hud.minimap.visible = false
	_run()

func _exit_tree() -> void:
	if world:
		world.get_tree().paused = false

func lp() -> Player:
	return world.local_player()

## Qué acción espera ahora mismo el tutorial (la usa también la prueba automática)
func expect() -> String:
	if _frozen:
		return _wait_action
	return _box_action

func is_frozen() -> bool:
	return _frozen

func _key(action: String) -> String:
	return "[" + G.key_label(action) + "]"

func _sleep(t: float) -> void:
	await get_tree().create_timer(t, false).timeout

# ------------------------------------------------------------------ pausa didáctica
func _freeze(action: String, title: Array, text: Array) -> void:
	## Detiene el mundo, explica qué hacer y espera a que el jugador pulse la tecla
	_step += 1
	box.visible = false
	overlay.title = G.L(title)
	overlay.text = G.L(text) % _key(action) if G.L(text).contains("%s") else G.L(text)
	overlay.key_text = G.key_label(action)
	overlay.visible = true
	overlay.t = 0.0
	Audio.sfx("quest", -2.0)
	_wait_action = action
	_frozen = true
	get_tree().paused = true
	await _resumed

func _lesson(action: String, title: Array, text: Array, need := 1, release := false) -> void:
	## Lección sin pausa: un rótulo arriba y seguir jugando hasta hacerlo
	_step += 1
	_box_action = action
	_box_release = release
	_box_title = G.L(title)
	_box_text = G.L(text) % _key(action) if G.L(text).contains("%s") else G.L(text)
	_box_count = 0
	_box_need = need
	box.visible = true
	box.pop = 1.0
	Audio.sfx("quest", -6.0)
	while _box_count < _box_need and not _finishing:
		await get_tree().process_frame
	_box_action = ""
	box.visible = false
	if not _finishing:
		_nice()

func _nice() -> void:
	var p := lp()
	if p:
		Fx.text(p.global_position + Vector2(0, -30), G.L(["¡BIEN!", "NICE!"]), Color(0.6, 1, 0.7), 10)

func _say(line: Array, dur := 2.6) -> void:
	world.hud.subtitle(G.L(["El Eco", "The Echo"]), G.L(line), dur, Color(1, 0.9, 0.7))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_BACKSPACE:
		_skip()
		return
	if _frozen:
		if event.is_action_pressed(_wait_action):
			_frozen = false
			overlay.visible = false
			get_tree().paused = false
			get_viewport().set_input_as_handled()
			_resumed.emit()
		return
	if _box_action == "" or _box_action.begins_with("_"):
		return
	if _box_release:
		if event.is_action_released(_box_action):
			_box_count += 1
	elif event.is_action_pressed(_box_action):
		_box_count += 1

func _process(delta: float) -> void:
	_t += delta
	if _box_action == "_move":
		var p := lp()
		if p:
			_moved += p.global_position.distance_to(_last)
			_last = p.global_position
			if _moved > 90.0:
				_box_count = _box_need
	elif _box_action == "menu" and world.menu.visible:
		_box_count = _box_need
	elif _box_action == "map" and world.menu.visible and world.menu.tab == "map":
		_box_count = _box_need

var _moved := 0.0
var _last := Vector2.ZERO

# ------------------------------------------------------------------ guion
func _run() -> void:
	var p := lp()
	_last = p.global_position
	Audio.play_music("peace", 1.0)
	await _sleep(0.6)
	_box_action = "_move"
	_step = 0
	_step += 1
	_box_title = G.L(["MOVERSE", "MOVE"])
	_box_text = G.L(["Usa %s para caminar. Apuntas con el ratón (puedes cambiarlo en Opciones).", "Use %s to walk. You aim with the mouse (you can change it in Options)."]) % (G.key_label("up") + G.key_label("left") + G.key_label("down") + G.key_label("right"))
	_box_count = 0
	_box_need = 1
	box.visible = true
	box.pop = 1.0
	while _box_count < _box_need and not _finishing:
		await get_tree().process_frame
	_box_action = ""
	box.visible = false
	if _finishing: return
	_nice()
	await _sleep(0.4)
	await _spawn_boss()
	if _finishing: return
	# --- PARRY cuerpo a cuerpo
	_say(["Te enseñé a pelear antes de que cayeras. Veamos qué recuerdas.", "I taught you to fight before you fell. Let's see what you remember."])
	await _sleep(1.2)
	await _lesson_parry()
	if _finishing: return
	# --- ATAQUE: el parry le ha abierto la guardia
	_boss_dazed()
	await _sleep(0.5)
	await _freeze("attack", ["¡AHORA, ATACA!", "NOW, ATTACK!"], ["Un parry abre su guardia y tu siguiente golpe es crítico. Pulsa %s y sigue encadenando: cada golpe es distinto y el último remata.", "A parry opens their guard and your next hit is a critical. Press %s and keep chaining: each hit is different and the last one finishes."])
	if _finishing: return
	lp().stamina = Prog.max_stamina()
	lp()._start_attack()
	await _lesson("attack", ["COMBO", "COMBO"], ["Sigue pulsando %s: encadena 3 golpes más. Cada ataque gasta aguante (la barra azul).", "Keep pressing %s: chain 3 more hits. Attacks use stamina (the blue bar)."], 3)
	if _finishing: return
	# --- ESQUIVA
	_boss_ready()
	await _sleep(0.8)
	await _lesson_dodge()
	if _finishing: return
	# --- CARGADO
	_boss_dazed()
	await _sleep(0.6)
	lp().stamina = Prog.max_stamina()
	await _lesson("heavy", ["ATAQUE CARGADO", "HEAVY ATTACK"], ["Mantén %s para cargar y suelta: el golpe cargado destroza la postura del enemigo.", "Hold %s to charge, then release: the heavy blow shreds the enemy's posture."], 1, true)
	if _finishing: return
	# --- PARRY de proyectil
	_boss_ready()
	await _sleep(0.8)
	await _lesson_projectile()
	if _finishing: return
	# --- CURARSE
	await _sleep(0.8)
	await _lesson_heal()
	if _finishing: return
	# --- REMATE
	_boss.hp_floor = 0.0
	_boss.hp = minf(_boss.hp, _boss.max_hp * 0.12)
	_boss_dazed()
	_boss.hp_floor = 1.0
	world.hud.show_boss(_boss)
	await _sleep(0.6)
	_boss_close()
	await _freeze("interact", ["¡REMÁTALO!", "FINISH IT!"], ["Cuando un enemigo tiene la postura rota puedes ejecutarlo: acércate y pulsa %s.", "When an enemy's posture is broken you can execute it: get close and press %s."])
	if _finishing: return
	_boss.hp_floor = 0.0
	world._execute(lp(), _boss)
	await _sleep(1.0)
	if is_instance_valid(_boss) and _boss.is_alive():
		world._enemy_die(_boss.idx)
	world.active_boss = null
	world.hud.hide_boss()
	Audio.play_music("peace", 2.0)
	world.hud.big_message(G.L(["ECO DISIPADO", "ECHO DISPELLED"]), Color(1, 0.85, 0.5), 2.2)
	await _sleep(2.4)
	if _finishing: return
	_say(["Bien. Baja ahora. Recuerda: cada muerte te arranca una pluma, y encender una Brasa también.", "Good. Now go down. Remember: every death tears away a feather, and so does kindling an Ember."], 4.0)
	await _lesson("menu", ["EL MENÚ", "THE MENU"], ["Pulsa %s para abrir el menú: personaje, habilidades, armas, misiones y controles. Ciérralo cuando acabes.", "Press %s to open the menu: character, skills, weapons, quests and controls. Close it when you're done."])
	if _finishing: return
	while world.menu.visible and not _finishing:
		await get_tree().process_frame
	await _lesson("map", ["EL MAPA", "THE MAP"], ["Pulsa %s para ver el mapa.", "Press %s to see the map."])
	if _finishing: return
	while world.menu.visible and not _finishing:
		await get_tree().process_frame
	# --- SALIDA
	_open_exit()

func _spawn_boss() -> void:
	var p := lp()
	p.cutscene = true
	var pos: Vector2 = world.tile_pos(ROOM_CENTER.x, ROOM_CENTER.y - 3.0)
	_boss = world._add_enemy("eco_tutor", pos, true)
	_boss.scripted = true
	_boss.active = true
	_boss.state = "busy"
	_boss.dmg_mult = 0.35
	_boss.hp_floor = _boss.max_hp * 0.35
	world.active_boss = _boss
	Fx.burst(pos + Vector2(0, -16), Color(1, 0.85, 0.5), 40, 120.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.6)
	Fx.ring(pos, 6.0, 60.0, Color(1, 0.85, 0.5), 0.6, 4.0)
	Fx.light_flash(pos, Color(1, 0.85, 0.5), 3.0, 1.6, 0.8)
	Audio.sfx("slam", -2.0)
	G.shake(5.0, 0.5)
	world.hud.big_message(G.T("boss_eco_tutor"), Color(1, 0.85, 0.5), 2.0, true)
	world.hud.show_boss(_boss)
	Audio.play_music("trial", 0.6)
	await _sleep(2.6)
	p.cutscene = false

func _boss_face() -> Vector2:
	var to := lp().global_position - _boss.global_position
	_boss.facing = 1 if to.x >= 0.0 else -1
	return to.normalized() if to.length() > 0.1 else Vector2.RIGHT

func _boss_close() -> void:
	## Se coloca al lado del jugador, listo para la lección
	var p := lp()
	var side := Vector2(-26, -6) if p.global_position.x > _boss.global_position.x else Vector2(26, -6)
	var dest: Vector2 = p.global_position + side
	if world.room_at(dest) != "prologo":
		dest = p.global_position - side
	_boss.create_tween().tween_property(_boss, "position", dest, 0.28).set_trans(Tween.TRANS_QUAD)

func _boss_dazed() -> void:
	_boss.state = "stagger"
	_boss.stagger_t = 99.0
	Fx.ring(_boss.global_position + Vector2(0, -12), 4.0, 26.0, Color(1, 0.8, 0.3), 0.3, 3.0)

func _boss_ready() -> void:
	_boss.state = "busy"
	_boss.sprite.rotation = 0.0
	_boss._play("idle", 0)

func _lesson_parry() -> void:
	var p := lp()
	p.cutscene = true
	p.velocity = Vector2.ZERO
	p.state = "move"
	p.stamina = Prog.max_stamina()
	_boss_ready()
	_boss_close()
	await _sleep(0.4)
	var dir := _boss_face()
	_boss._play("attack", 0)
	_boss._tell(0.7)
	Audio.sfx("charge", -6.0)
	await _sleep(0.65)
	await _freeze("parry", ["¡PARRY!", "PARRY!"], ["Va a golpearte. Pulsa %s justo antes del impacto para desviarlo. Un parry perfecto lo aturde y llena tu Ira.", "They're about to hit you. Press %s right before the impact to deflect it. A perfect parry stuns them and builds your Wrath."])
	if _finishing:
		return
	p.cutscene = false
	p.state = "move"
	p._start_parry()
	_boss._play("attack", 1)
	Audio.sfx("swing", -2.0)
	Fx.slash(_boss.global_position + Vector2(0, -8) + dir * 6, dir.angle(), 22.0, 130.0, Color(1, 0.75, 0.4, 0.9), 10.0, 0.18)
	_boss._hit_circle(p.global_position, 8.0, _boss.cfg.dmg, dir)
	await _sleep(0.5)

func _lesson_dodge() -> void:
	var p := lp()
	p.cutscene = true
	p.velocity = Vector2.ZERO
	p.state = "move"
	p.stamina = Prog.max_stamina()
	var spot := p.global_position
	Fx.telegraph_circle(spot, 40.0, 0.8)
	_boss._play("attack", 0)
	_boss._tell(0.8)
	await _sleep(0.7)
	await _freeze("dash", ["¡ESQUIVA!", "DODGE!"], ["Ese círculo rojo es el golpe. Pulsa %s para esquivar: mientras esquivas eres invulnerable, y si lo haces en el último instante el tiempo se frena.", "That red circle is the blow. Press %s to dash: you can't be hurt while dashing, and doing it at the last moment slows time."])
	if _finishing:
		return
	p.cutscene = false
	p.state = "move"
	var input := Input.get_vector("left", "right", "up", "down")
	if input.length() < 0.1:
		input = (world.tile_pos(ROOM_CENTER.x, ROOM_CENTER.y) - p.global_position).normalized()
		if input.length() < 0.1:
			input = Vector2.RIGHT
	p._start_dash(input)
	_boss._play("attack", 1)
	_boss._slam_at(spot, 40.0, _boss.cfg.dmg)
	await _sleep(0.8)

func _lesson_projectile() -> void:
	var p := lp()
	p.cutscene = true
	p.velocity = Vector2.ZERO
	p.state = "move"
	p.stamina = Prog.max_stamina()
	var dir := _boss_face()
	var far: Vector2 = p.global_position - dir * 110.0
	if world.room_at(far) != "prologo":
		far = world.tile_pos(ROOM_CENTER.x, ROOM_CENTER.y - 5.0)
	_boss.create_tween().tween_property(_boss, "position", far, 0.4).set_trans(Tween.TRANS_QUAD)
	await _sleep(0.5)
	dir = _boss_face()
	_boss._play("attack", 2)
	_boss._tell(0.5, Color(0.8, 0.5, 1))
	await _sleep(0.5)
	Audio.sfx("enemy_shot")
	var orb: Projectile = world.spawn_projectile_local(_boss.global_position + Vector2(0, -12), dir * 130.0, _boss.cfg.dmg, "orb", "enemy", 1, 5.0, 6.0, 0)
	orb.damage = _boss.cfg.dmg * 0.35
	while is_instance_valid(orb) and orb.global_position.distance_to(p.global_position) > 26.0 and not _finishing:
		await get_tree().process_frame
	if _finishing or not is_instance_valid(orb):
		p.cutscene = false
		return
	await _freeze("parry", ["¡DEVUÉLVELO!", "SEND IT BACK!"], ["El parry también sirve con los proyectiles: pulsa %s y volverá contra el enemigo con el doble de fuerza.", "Parrying also works on projectiles: press %s and it flies back at the enemy twice as hard."])
	if _finishing:
		return
	p.cutscene = false
	p.state = "move"
	p._start_parry()
	await _sleep(0.7)

func _lesson_heal() -> void:
	var p := lp()
	p.cutscene = true
	_boss_ready()
	_boss_close()
	await _sleep(0.4)
	var dir := _boss_face()
	_boss._play("attack", 1)
	Audio.sfx("swing_heavy")
	Fx.slash(_boss.global_position + Vector2(0, -8) + dir * 6, dir.angle(), 26.0, 180.0, Color(1, 0.5, 0.3, 0.95), 14.0, 0.2)
	await _sleep(0.15)
	p.cutscene = false
	p.iframes = 0.0
	p.state = "move"
	p.hp = Prog.max_hp() * 0.8
	p.take_hit(Prog.max_hp() * 0.4, dir, -1)
	await _sleep(0.6)
	await _freeze("heal", ["¡CÚRATE!", "HEAL!"], ["Te ha herido. Pulsa %s para beber una Lágrima. Tienes pocas, pero se rellenan al descansar en una Brasa.", "You're hurt. Press %s to drink a Tear. You have few, but they refill when you rest at an Ember."])
	if _finishing:
		return
	p.state = "move"
	p.start_heal()
	await _sleep(0.8)

func _open_exit() -> void:
	var pos: Vector2 = world.tile_pos(ROOM_CENTER.x, ROOM_CENTER.y - 5.0)
	world._add_inter("rift", "prologue_rift", pos, {"to": 1})
	Fx.ring(pos, 6.0, 50.0, Color(0.7, 0.5, 1.0), 0.8, 4.0)
	Audio.sfx("gate", -2.0, 0.0)
	_step = TOTAL_STEPS
	_box_title = G.L(["LA GRIETA", "THE RIFT"])
	_box_text = G.L(["Se ha abierto una grieta al norte. Acércate y pulsa %s para bajar al Santuario de la Última Brasa.", "A rift has opened to the north. Walk up and press %s to go down to the Sanctuary of the Last Ember."]) % _key("interact")
	_box_action = "_exit"
	box.visible = true
	box.pop = 1.0
	done = true

func _skip() -> void:
	if _finishing:
		return
	if _frozen:
		_frozen = false
		overlay.visible = false
		get_tree().paused = false
		_finishing = true
		_resumed.emit()
	finish()

func finish() -> void:
	## Fin del prólogo: de la Cuna al Santuario
	if _finishing and _ended:
		return
	_finishing = true
	_ended = true
	var p := lp()
	box.visible = false
	overlay.visible = false
	get_tree().paused = false
	if p:
		p.cutscene = true
	if is_instance_valid(_boss):
		if _boss.is_alive():
			_boss.scripted = false
			_boss.hp_floor = 0.0
			_boss.die()
		world.enemies.erase(_boss)
		_boss.queue_free()
		for i in world.enemies.size():
			world.enemies[i].idx = i
	world.active_boss = null
	world.hud.hide_boss()
	world.hud.fade_to(1.0, 0.9)
	Audio.stop_music(0.8)
	Audio.sfx("shadow_rise", -2.0, 0.0)
	await get_tree().create_timer(1.0).timeout
	if world.interactables.has("prologue_rift"):
		world.interactables["prologue_rift"].queue_free()
		world.interactables.erase("prologue_rift")
	Prog.flags["prologue_done"] = true
	Prog.flags.erase("seen_prologo")
	if p:
		p.respawn_at(world._brasa_spawn("sanct"))
		world.camera.position = p.global_position
	world._area = ""
	world.hud.minimap.visible = true
	Prog.start_quest("main1")
	world._prologue = null
	Audio.play_music("peace", 2.0)
	await get_tree().create_timer(0.4).timeout
	world.hud.fade_to(0.0, 1.2)
	world.hud.show_area(G.T("stratum1"), G.T("area_sanct"))
	if p:
		p.cutscene = false
	if G.autotest == "":
		get_tree().create_timer(4.5).timeout.connect(G.toast.bind(G.L(["Enciende la Brasa del centro: cuesta una pluma, pero guarda tu partida y es adonde vuelves al caer.", "Kindle the Ember in the centre: it costs a feather, but it saves your game and is where you return when you fall."]), Color(1, 0.85, 0.6)))
	queue_free()

var _ended := false

# ------------------------------------------------------------------ interfaz
class PrologueBox extends Control:
	var owner_p: Node
	var t := 0.0
	var pop := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		pop = maxf(0.0, pop - delta * 3.0)
		queue_redraw()
	func _draw() -> void:
		var p = owner_p
		var o := Vector2(0, -pop * 6.0).round()
		UIKit.frame(self, Rect2(o, size), UIKit.GOLD, Color(0.07, 0.03, 0.1, 0.92), 4.0, t)
		var hf := UIKit.font("head")
		var head: String = G.L(["PRÓLOGO  %d/%d  -  ", "PROLOGUE  %d/%d  -  "]) % [p._step, p.TOTAL_STEPS] + p._box_title
		hf.draw_string_outline(get_canvas_item(), Vector2(12, 16) + o, head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		hf.draw_string(get_canvas_item(), Vector2(12, 16) + o, head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)
		var bf := UIKit.font("body")
		bf.draw_multiline_string_outline(get_canvas_item(), Vector2(12, 32) + o, p._box_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, 3, 3, UIKit.INK)
		bf.draw_multiline_string(get_canvas_item(), Vector2(12, 32) + o, p._box_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, 3, UIKit.WHITE)
		var tf := UIKit.font("title")
		var skip := G.L(["[Retroceso] saltar prólogo", "[Backspace] skip prologue"])
		tf.draw_string(get_canvas_item(), Vector2(size.x - 128, size.y - 6) + o, skip, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.TEXT_DIM)

class FreezeOverlay extends Control:
	## El mundo está detenido: se oscurece la pantalla y una gran tecla dice qué pulsar
	var title := ""
	var text := ""
	var key_text := ""
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.0, 0.05, 0.5 * clampf(t * 6.0, 0.0, 1.0)))
		var r := Rect2(Vector2(110, 226), Vector2(420, 112))
		UIKit.frame(self, r, UIKit.GOLD, Color(0.07, 0.03, 0.1, 0.96), 4.0, t)
		var hf := UIKit.font("logo")
		var tw := hf.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		var tp := Vector2(320 - tw / 2.0, r.position.y + 28)
		hf.draw_string_outline(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 5, UIKit.INK)
		hf.draw_string(get_canvas_item(), tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.GOLD.lerp(UIKit.WHITE, 0.5 + 0.5 * sin(t * 7.0)))
		var bf := UIKit.font("body")
		var bp := Vector2(r.position.x + 92, r.position.y + 48)
		bf.draw_multiline_string_outline(get_canvas_item(), bp, text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 106, 15, 4, 3, UIKit.INK)
		bf.draw_multiline_string(get_canvas_item(), bp, text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 106, 15, 4, UIKit.WHITE)
		# la tecla, latiendo
		var kf := UIKit.font("head")
		var s := 1.0 + 0.1 * sin(t * 9.0)
		var kw := maxf(46.0, kf.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16.0) * s
		var kh := 38.0 * s
		var kc := Vector2(r.position.x + 48, r.position.y + 76)
		var kr := Rect2(kc - Vector2(kw, kh) / 2.0, Vector2(kw, kh))
		draw_rect(kr.grow(2), UIKit.INK)
		draw_rect(kr, UIKit.GOLD)
		draw_rect(Rect2(kr.position + Vector2(2, 2), kr.size - Vector2(4, 8)), UIKit.WHITE)
		var ksz := kf.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		kf.draw_string(get_canvas_item(), kc + Vector2(-ksz.x / 2.0, 3), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.INK)

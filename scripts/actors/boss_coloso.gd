class_name BossColoso
extends Enemy
## EL COLOSO DEL ABISMO — lo que sostenía la Espiral (batalla secreta de la Cornisa del Coloso).
## Un gigante de piedra que se alza desde el vacío junto a la cornisa. Solo se le puede herir en las
## RUNAS DE SUS MANOS cuando descansan en el suelo tras un golpe y, en la fase II, en el NÚCLEO del pecho
## cuando se inclina sobre la cornisa. Ataques: Puñetazo, Doble puñetazo, Barrido, Mirada (rayo que gira),
## Lluvia de rocas y Tormenta (rayos). El nodo del enemigo se coloca en el punto vulnerable de cada momento.

const ARENA := Rect2(208, 1008, 336, 224)        # la cornisa (en píxeles)
const ANCHOR := Vector2(132, 1124)               # dónde se alza, en el abismo al oeste
var rig: ColosoRig
var hands: Array = []
var eye: Node2D
var summoned := false
var _vuln := false
var _vuln_mult := 1.0
var _invuln := false
var _t := 0.0
var _last := ""
var _next_hand := 0
var _transitioning := false

func _ready() -> void:
	super._ready()
	sprite.visible = false
	shadow.visible = false
	collision_layer = 0
	collision_mask = 0
	body_radius = 22.0
	for c in get_children():
		if c is Depth3D.CastShadow:
			c.queue_free()
	eye = Node2D.new()
	eye.top_level = true
	add_child(eye)
	_build_rig()
	_place_hidden()
	_apply_summoned()

func _build_rig() -> void:
	rig = ColosoRig.new()
	rig.boss = self
	rig.top_level = true
	rig.z_index = -11
	add_child(rig)
	hands = []
	for i in 2:
		var h := ColosoHand.new()
		h.boss = self
		h.side = -1 if i == 0 else 1
		h.top_level = true
		add_child(h)
		hands.append(h)

func _apply_summoned() -> void:
	if rig:
		rig.visible = summoned
		for h in hands:
			h.visible = summoned
	if not summoned:
		active = false

func _place_hidden() -> void:
	position = ANCHOR
	_net_pos = ANCHOR
	_vuln = false

func reset_state() -> void:
	super.reset_state()
	_invuln = false
	_transitioning = false
	_vuln = false
	_last = ""
	position = ANCHOR
	_net_pos = ANCHOR
	summoned = false
	if rig == null and eye != null:
		_build_rig()
	if rig:
		rig.rise = 0.0
		rig.lean = 0.0
		rig.modulate = Color.WHITE
		for h in hands:
			h.reset()
	_apply_summoned()

func summon() -> void:
	summoned = true
	_apply_summoned()

func cam_point() -> Vector2:
	return Vector2(ARENA.position.x + 40.0, ANCHOR.y - 40.0)

func shoulder(side: int) -> Vector2:
	if rig == null:
		return ANCHOR
	return rig.global_position + Vector2(side * 66.0, -30.0)

func rest_pos(side: int) -> Vector2:
	return ANCHOR + (Vector2(-70, 46) if side < 0 else Vector2(92, 40)) + (rig.offset_now() if rig else Vector2(0, 300))

# ====================================================================== IA (anfitrión)
func _server_tick(delta: float) -> void:
	cooldown -= delta
	slow_t = max(0.0, slow_t - delta)
	if state == "dead" or not active:
		return
	if state == "idle" or state == "chase":
		state = "chase"
		var target: Node2D = world.nearest_player(ARENA.get_center())
		if target and cooldown <= 0.0:
			_trigger(_pick(target.global_position), target.global_position)
	elif state == "stagger":
		stagger_t -= delta
		if stagger_t <= 0.0:
			state = "chase"

func _pick(tp: Vector2) -> String:
	var pool: Array = ["slam", "slam", "sweep", "gaze", "rocks"]
	if phase >= 2:
		pool = ["double", "slam", "sweep", "gaze", "storm", "core", "rocks", "double"]
	pool.erase(_last)
	var p: String = pool[randi() % pool.size()]
	_last = p
	return p

func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if _invuln or not _vuln:
		return {}
	var r := super.server_apply_damage(dmg * _vuln_mult, Vector2.ZERO, 0.0)
	return r

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, false)
	G.shake(1.5, 0.08)
	if not multiplayer.is_server() or _transitioning:
		return
	if phase == 1 and hp < max_hp * 0.5:
		_transitioning = true
		world.bcast("enemy_action", [idx, "phase2", global_position, 0])

func on_parried(_perfect := true) -> void:
	pass

# ====================================================================== ataques (todos los clientes)
func _set_weak(p: Vector2, mult := 1.0) -> void:
	_vuln = true
	_vuln_mult = mult
	if multiplayer.is_server():
		position = p
		_net_pos = p

func _clear_weak() -> void:
	_vuln = false
	_vuln_mult = 1.0
	if multiplayer.is_server():
		position = ANCHOR
		_net_pos = ANCHOR

func _arena_spot(rng: RandomNumberGenerator) -> Vector2:
	return Vector2(rng.randf_range(ARENA.position.x + 20, ARENA.end.x - 20), rng.randf_range(ARENA.position.y + 24, ARENA.end.y - 16))

func _clamp_arena(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, ARENA.position.x + 24, ARENA.end.x - 24), clampf(p.y, ARENA.position.y + 26, ARENA.end.y - 18))

func perform(act: String, tpos: Vector2, seed: int) -> void:
	if state == "dead":
		return
	_attack_id += 1
	var my_id := _attack_id
	state = "busy"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var spd := 1.0 if phase == 1 else 0.8
	tpos = _clamp_arena(tpos)
	match act:
		"rise":
			_invuln = true
			Audio.sfx("roar", 0.0, 0.0)
			Audio.sfx("gate", -4.0, 0.0)
			G.shake(4.0, 3.2)
			var tw := create_tween()
			tw.tween_property(rig, "rise", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			for k in 10:
				var dp := Vector2(ARENA.position.x + randf_range(0, 40), randf_range(ARENA.position.y, ARENA.end.y))
				world.get_node("FX").add_child(Depth3D.Debris.new().setup(dp, 6, Color(0.42, 0.38, 0.48), 0.9))
				if not await _wait(0.3, my_id): return
			Audio.sfx("roar", 2.0, 0.0)
			G.shockwave(rig.global_position + Vector2(0, -80), 2.2, 0.9)
			G.flash(Color(0.6, 0.95, 1.0, 0.35), 0.4)
			world.show_boss_line(["...¿QUIÉN... SOPLA... EL CUERNO?", "...WHO... BLOWS... THE HORN?"], "coloso")
			if not await _wait(1.2, my_id): return
			_invuln = false
		"slam":
			if hands.size() < 2:
				return
			var h: ColosoHand = hands[_next_hand]
			_next_hand = 1 - _next_hand
			await _do_slam([h], [tpos], spd, my_id)
		"double":
			var lp: Node2D = world.nearest_player(ARENA.get_center())
			var p2 := _clamp_arena(tpos + Vector2(rng.randf_range(-90, 90), rng.randf_range(-60, 60)))
			if lp is CharacterBody2D:
				p2 = _clamp_arena(lp.global_position + (lp as CharacterBody2D).velocity * 0.6)
			if p2.distance_to(tpos) < 60.0:
				p2 = _clamp_arena(tpos + Vector2(80, 0).rotated(rng.randf() * TAU))
			await _do_slam([hands[0], hands[1]], [tpos, p2], spd * 0.95, my_id)
		"sweep":
			# barrido: una mano rasa la cornisa de oeste a este a la altura de tu fila
			var h2: ColosoHand = hands[1]
			var y := tpos.y
			var x0 := ARENA.position.x - 10.0
			var x1 := ARENA.end.x + 10.0
			Fx.telegraph_line(Vector2(x0, y), 0.0, x1 - x0, 40.0, 0.95 * spd, Color(1, 0.3, 0.3))
			h2.move_to(Vector2(x0 - 20, y), 70.0, 0.5)
			Audio.sfx("charge", -2.0)
			if not await _wait(0.95 * spd, my_id): return
			Audio.sfx("swing_heavy", 2.0)
			Audio.sfx("dash", 0.0)
			var t := 0.0
			var dur := 0.75 * spd
			var hit := false
			while t < dur:
				var k := t / dur
				h2.ground = Vector2(lerpf(x0, x1, k), y)
				h2.h = 4.0
				if randf() < 0.7:
					world.get_node("FX").add_child(Depth3D.Debris.new().setup(h2.ground + Vector2(0, 6), 1, Color(0.45, 0.4, 0.5), 0.5))
				if not hit:
					hit = _hit_circle(h2.ground, 30.0, cfg.dmg * 1.1, Vector2(0, 1))
				if not await _wait(0.016, my_id): return
				t += 0.016
			G.shake(3.0, 0.2)
			h2.move_to(rest_pos(1), 0.0, 0.7)
			if not await _wait(0.8, my_id): return
		"gaze":
			# la mirada: un rayo sale de sus ojos y barre la cornisa
			rig.eye_charge = 1.0
			Audio.sfx("charge", 0.0)
			var a0 := (tpos - eye.global_position).angle()
			var dirs := -1.0 if rng.randf() < 0.5 else 1.0
			Haz.beams(eye, 1, 520.0, 0.42 * dirs / spd, 1.0 * spd, 2.6, cfg.dmg * 0.55 * dmg_mult, Color(0.55, 0.95, 1.0), a0 - 0.55 * dirs, Vector2.ZERO, idx)
			if phase >= 2:
				Haz.beams(eye, 1, 520.0, -0.42 * dirs / spd, 1.0 * spd, 2.6, cfg.dmg * 0.55 * dmg_mult, Color(0.75, 0.6, 1.0), a0 + 0.55 * dirs, Vector2.ZERO, idx)
			if not await _wait(1.0 * spd, my_id): return
			Audio.sfx("nova", -2.0)
			G.shake(2.0, 2.4)
			if not await _wait(2.7, my_id): return
			rig.eye_charge = 0.0
		"rocks":
			Audio.sfx("roar", -6.0)
			rig.shake = 1.0
			G.shake(4.0, 1.0)
			var n := 10 if phase == 1 else 15
			for i in n:
				var p := _arena_spot(rng)
				if i % 4 == 0:
					var lp2: Node2D = world.nearest_player(ARENA.get_center())
					if lp2:
						p = _clamp_arena(lp2.global_position)
				var d := 0.9 + i * 0.09
				Fx.telegraph_circle(p, 18.0, d, Color(1, 0.55, 0.3))
				_rock_fall(p, d)
			if not await _wait(1.0 + n * 0.09 + 0.4, my_id): return
		"storm":
			Audio.sfx("roar", -4.0)
			var abyss: Node = world.get_node_or_null("Abyss")
			for i in 7:
				var lp3: Node2D = world.nearest_player(ARENA.get_center())
				var p3: Vector2 = _clamp_arena(lp3.global_position) if lp3 and i % 2 == 0 else _arena_spot(rng)
				Fx.telegraph_circle(p3, 20.0, 0.7, Color(0.7, 0.85, 1.0))
				get_tree().create_timer(0.7, false).timeout.connect(_bolt.bind(p3, abyss))
				if not await _wait(0.38, my_id): return
			if not await _wait(1.0, my_id): return
		"core":
			# se inclina sobre la cornisa y deja el núcleo al alcance (¡ahora!)
			Audio.sfx("roar", -2.0)
			var tw2 := create_tween()
			tw2.tween_property(rig, "lean", 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			for h3 in hands:
				h3.move_to(h3.ground + Vector2(30, 0), 0.0, 0.6)
			if not await _wait(0.85, my_id): return
			_slam_at(Vector2(ARENA.position.x + 18, ANCHOR.y), 34.0, cfg.dmg)
			_set_weak(Vector2(ARENA.position.x + 22, ANCHOR.y - 6), 1.6)
			rig.core_open = 1.0
			world.hud.big_message(G.L(["¡EL NÚCLEO!", "THE CORE!"]), Color(0.6, 0.95, 1.0), 1.4)
			if not await _wait(3.2 * (1.0 if phase == 1 else 0.85), my_id):
				_clear_weak()
				return
			_clear_weak()
			rig.core_open = 0.0
			var tw3 := create_tween()
			tw3.tween_property(rig, "lean", 0.0, 0.6)
			Audio.sfx("roar", -4.0)
			Haz.ring_wave(Vector2(ARENA.position.x + 16, ANCHOR.y), 20.0, 300.0, 1.4, cfg.dmg * 0.7 * dmg_mult, Color(0.55, 0.95, 1.0), 10.0, idx)
			for h4 in hands:
				h4.move_to(rest_pos(h4.side), 0.0, 0.6)
			if not await _wait(1.2, my_id): return
		"phase2":
			_invuln = true
			_clear_weak()
			Audio.sfx("roar", 4.0, 0.0)
			G.shake(9.0, 1.6)
			G.flash(Color(0.7, 0.95, 1.0, 0.5), 0.5)
			G.chroma(2.0, 0.8)
			world.show_boss_line(["LA ESPIRAL... PESA. SI CAIGO... CAE TODO.", "THE SPIRAL... IS HEAVY. IF I FALL... ALL FALLS."], "coloso")
			rig.phase2 = true
			for k2 in 4:
				_bolt(_arena_spot(rng), world.get_node_or_null("Abyss"))
				if not await _wait(0.35, my_id):
					_invuln = false
					return
			phase = 2
			_invuln = false
			_transitioning = false
		"fall":
			pass
	if act != "fall":
		_end_attack(my_id)

func _do_slam(hs: Array, spots: Array, spd: float, my_id: int) -> void:
	var warn := 0.95 * spd
	for i in hs.size():
		var h: ColosoHand = hs[i]
		h.move_to(spots[i], 150.0, 0.45)
		Fx.telegraph_circle(spots[i], 38.0, warn, Color(1, 0.3, 0.3))
	Audio.sfx("charge", -4.0)
	if not await _wait(warn - 0.12, my_id): return
	for h in hs:
		h.drop(0.12)
	if not await _wait(0.12, my_id): return
	for i in hs.size():
		_slam_at(spots[i], 40.0, cfg.dmg * 1.2)
		world.get_node("FX").add_child(Depth3D.Debris.new().setup(spots[i], 10, Color(0.45, 0.4, 0.5), 1.1))
	G.shake(7.0, 0.35)
	# las runas de la mano brillan: es el momento de golpear
	var weak: ColosoHand = hs[0]
	var lp: Node2D = world.nearest_player(spots[0])
	if lp and hs.size() > 1 and lp.global_position.distance_to(spots[1]) < lp.global_position.distance_to(spots[0]):
		weak = hs[1]
	weak.weak = true
	_set_weak(weak.ground + Vector2(0, -6))
	var rest := 1.9 if phase == 1 else 1.4
	if not await _wait(rest, my_id):
		weak.weak = false
		_clear_weak()
		return
	weak.weak = false
	_clear_weak()
	for h in hs:
		h.move_to(rest_pos(h.side), 0.0, 0.7)
	if not await _wait(0.75, my_id): return

func _rock_fall(p: Vector2, dur: float) -> void:
	var f := Depth3D.Faller.new()
	f.tex = Fx.tex("fx_soft")
	f.height = 180.0
	f.dur = dur
	f.linger = 0.05
	f.modulate = Color(0.32, 0.28, 0.36)
	f.scale = Vector2(1.6, 1.6)
	f.position = p
	f.on_land = _rock_hit.bind(p)
	world.get_node("FX").add_child(f)

func _rock_hit(p: Vector2) -> void:
	Audio.sfx("hit_heavy", -8.0)
	Fx.burst(p, Color(0.5, 0.45, 0.55), 10, 80.0, 0.5, "fx_px", 180.0, Vector2.UP, 1.0, false, Vector2(0, 120))
	world.get_node("FX").add_child(Depth3D.Debris.new().setup(p, 4, Color(0.42, 0.38, 0.48), 0.7))
	if state != "dead":
		_hit_circle(p, 16.0, cfg.dmg * 0.75, Vector2.ZERO)

func _bolt(p: Vector2, abyss: Node) -> void:
	if state == "dead" or not is_inside_tree():
		return
	var b := Bolt.new()
	b.position = p
	world.get_node("FX").add_child(b)
	Audio.sfx("thunder" if ResourceLoader.exists("res://assets/audio/sfx_thunder.wav") else "slam", -4.0)
	G.flash(Color(0.75, 0.9, 1.0, 0.25), 0.12)
	Fx.light_flash(p, Color(0.7, 0.9, 1.0), 2.2, 1.6, 0.3)
	Fx.burst(p, Color(0.75, 0.9, 1.0), 14, 120.0, 0.4, "fx_px", 180.0)
	_hit_circle(p, 20.0, cfg.dmg * 0.9, Vector2.ZERO)
	if abyss and abyss.has_method("_make_bolt"):
		abyss.call("_make_bolt")

func die() -> void:
	super.die()
	_vuln = false
	if rig:
		# el cadáver de piedra se hunde en el abismo (vive en la capa de efectos: el jefe se oculta al morir)
		var fxl: Node = world.get_node("FX")
		rig.core_open = 0.0
		rig.reparent(fxl)
		var tw := rig.create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(rig, "rise", -0.3, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(rig, "modulate", Color(0.5, 0.5, 0.6, 0.0), 3.0)
		tw.tween_callback(rig.queue_free)
		for h in hands:
			h.reparent(fxl)
			h.fall()
		rig = null
		hands = []
	G.shake(8.0, 2.5)

# ====================================================================== animación (todos)
func _animate(delta: float) -> void:
	_t += delta
	if rig and eye:
		eye.global_position = rig.global_position + Vector2(0, -92) + Vector2(0, rig.lean * 16.0)

# ====================================================================== piezas
class ColosoRig extends Node2D:
	## cuerpo y cabeza (detrás de la cornisa, bajo el suelo) con núcleo que late y ojos que brillan
	var boss: BossColoso
	var rise := 0.0
	var lean := 0.0
	var shake := 0.0
	var eye_charge := 0.0
	var core_open := 0.0
	var phase2 := false
	var t := 0.0
	var body: Sprite2D
	var head: Sprite2D
	var light: PointLight2D
	var eye_light: PointLight2D
	func _ready() -> void:
		body = Sprite2D.new()
		body.texture = load("res://assets/sprites/cinematic/coloso_body.png")
		body.position = Vector2(0, 20)
		add_child(body)
		head = Sprite2D.new()
		head.texture = load("res://assets/sprites/cinematic/coloso_head.png")
		head.position = Vector2(0, -78)
		add_child(head)
		light = PointLight2D.new()
		light.texture = Fx.tex("light")
		light.color = Color(0.5, 0.9, 1.0)
		light.texture_scale = 3.0
		light.energy = 1.0
		light.position = Vector2(0, 10)
		add_child(light)
		eye_light = PointLight2D.new()
		eye_light.texture = Fx.tex("light")
		eye_light.color = Color(0.55, 0.95, 1.0)
		eye_light.texture_scale = 1.6
		eye_light.energy = 0.8
		eye_light.position = Vector2(0, -84)
		add_child(eye_light)
	func offset_now() -> Vector2:
		return Vector2(lean * 34.0, (1.0 - rise) * 300.0 + lean * 18.0)
	func _process(delta: float) -> void:
		t += delta
		shake = maxf(0.0, shake - delta)
		global_position = BossColoso.ANCHOR + offset_now() + Vector2(sin(t * 0.8) * 2.0, sin(t * 1.1) * 3.0) + Vector2(randf_range(-2, 2), 0) * shake
		head.position = Vector2(sin(t * 0.6) * 2.0, -78 + lean * 14.0)
		head.rotation = sin(t * 0.5) * 0.03 + lean * 0.08
		var ec := Color(0.55, 0.95, 1.0) if not phase2 else Color(0.85, 0.7, 1.0)
		eye_light.color = ec
		eye_light.energy = 0.8 + eye_charge * (1.6 + sin(t * 30.0) * 0.4)
		eye_light.position = head.position + Vector2(0, -6)
		light.energy = 1.0 + 0.3 * sin(t * 3.0) + core_open * 1.5
		queue_redraw()
	func _draw() -> void:
		# núcleo que late en el hueco del pecho
		var c := Vector2(0, 20 + 33)
		var pulse := 0.5 + 0.5 * sin(t * (3.0 if not phase2 else 5.0))
		var col := Color(0.5, 0.9, 1.0) if not phase2 else Color(0.8, 0.65, 1.0)
		draw_circle(c, 13.0, Color(col.darkened(0.6), 0.9))
		draw_circle(c, 8.0 + pulse * 2.0 + core_open * 3.0, Color(col, 0.85))
		draw_circle(c, 4.0 + pulse, Color(1, 1, 1, 0.9))
		if core_open > 0.0:
			for i in 8:
				var a := t * 2.0 + i * TAU / 8.0
				draw_line(c + Vector2.from_angle(a) * 14.0, c + Vector2.from_angle(a) * (26.0 + pulse * 6.0), Color(col, 0.6), 2.0)
		# ojos cargando la mirada
		if eye_charge > 0.0:
			for ex in [-12.0, 12.0]:
				var ep := head.position + Vector2(ex, -36)
				draw_circle(ep, 6.0 + sin(t * 30.0) * 1.5, Color(col, 0.5))
				draw_circle(ep, 3.0, Color(1, 1, 1, 0.9))

class ColosoHand extends Node2D:
	## mano de piedra: vuela alto (con su sombra en el suelo), golpea y descansa. Su runa es el punto débil.
	var boss: BossColoso
	var side := 1
	var ground := Vector2.ZERO
	var h := 0.0
	var weak := false
	var t := 0.0
	var spr: Sprite2D
	var _tw: Tween
	var _fallen := false
	func _ready() -> void:
		spr = Sprite2D.new()
		spr.texture = load("res://assets/sprites/cinematic/coloso_hand.png")
		spr.flip_h = side < 0
		add_child(spr)
		reset()
	func reset() -> void:
		_fallen = false
		weak = false
		h = 0.0
		modulate = Color.WHITE
		if boss and boss.rig:
			ground = boss.rest_pos(side)
		else:
			ground = BossColoso.ANCHOR + Vector2(side * 90, 300)
	func move_to(p: Vector2, height: float, dur: float) -> void:
		if _tw:
			_tw.kill()
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(self, "ground", p, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tw.tween_property(self, "h", height, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	func drop(dur: float) -> void:
		if _tw:
			_tw.kill()
		_tw = create_tween()
		_tw.tween_property(self, "h", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	func fall() -> void:
		_fallen = true
		if _tw:
			_tw.kill()
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(self, "ground", BossColoso.ANCHOR + Vector2(side * 60, 260), 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.8)
		_tw.tween_property(self, "modulate:a", 0.0, 2.6).set_delay(0.8)
		_tw.chain().tween_callback(queue_free)
	func _process(delta: float) -> void:
		t += delta
		if boss == null or not is_instance_valid(boss):
			return
		if _fallen:
			global_position = ground
			spr.position = Vector2(0, -h - 22)
			queue_redraw()
			return
		if boss.rig == null:
			return
		# en reposo sigue al cuerpo (sube y baja con él)
		if not boss.is_alive() and not _fallen:
			pass
		global_position = ground
		spr.position = Vector2(0, -h - 22)
		var s := 1.0 + h / 320.0
		spr.scale = Vector2(s, s)
		z_index = 22 if h > 10.0 else -5
		if boss.state != "busy" and not _fallen and boss.is_alive() and h < 1.0 and (_tw == null or not _tw.is_running()):
			ground = boss.rest_pos(side)
		queue_redraw()
	func _draw() -> void:
		# sombra en el suelo (crece al acercarse)
		var k := clampf(1.0 - h / 180.0, 0.15, 1.0)
		draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 30.0 * (0.6 + 0.4 * k), Color(0, 0, 0, 0.45 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# brazo hasta el hombro
		if boss == null or not is_instance_valid(boss) or boss.rig == null:
			return
		var sh := to_local(boss.shoulder(side))
		var hand := spr.position + Vector2(0, -24)
		draw_line(hand, sh, Color(0.09, 0.06, 0.12), 22.0)
		draw_line(hand, sh, Color(0.36, 0.33, 0.44), 18.0)
		draw_line(hand + Vector2(-4, 0), sh + Vector2(-4, 0), Color(0.5, 0.47, 0.6), 4.0)
		var seg := (sh - hand)
		for i in range(1, 4):
			var pp := hand + seg * (i / 4.0)
			draw_line(pp - seg.normalized().orthogonal() * 9.0, pp + seg.normalized().orthogonal() * 9.0, Color(0.15, 0.12, 0.2), 2.0)
		# runa débil: brilla y avisa de que ahora se le puede herir
		if weak:
			var rp := spr.position + Vector2(0, -2)
			var pulse := 0.5 + 0.5 * sin(t * 14.0)
			draw_circle(rp, 10.0 + pulse * 3.0, Color(0.55, 0.95, 1.0, 0.25))
			draw_circle(rp, 5.0, Color(0.8, 1.0, 1.0, 0.8))
			var f := UIKit.font("head")
			var tx := G.L(["¡GOLPEA LA RUNA!", "STRIKE THE RUNE!"])
			var w := f.get_string_size(tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			f.draw_string_outline(get_canvas_item(), rp + Vector2(-w / 2.0, -26), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), rp + Vector2(-w / 2.0, -26), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 1.0, 1.0, 0.6 + 0.4 * pulse))

class Bolt extends Node2D:
	## rayo de la tormenta: cae del cielo y deja el suelo chamuscado
	var t := 0.0
	var pts := PackedVector2Array()
	func _ready() -> void:
		z_index = 30
		material = Fx.add_material()
		var p := Vector2(randf_range(-30, 30), -340)
		pts.append(p)
		while p.y < 0.0:
			p += Vector2(randf_range(-14, 14), randf_range(18, 34))
			p.y = minf(p.y, 0.0)
			pts.append(p)
		pts[pts.size() - 1] = Vector2.ZERO
		Fx.scorch(global_position, 12.0)
	func _process(delta: float) -> void:
		t += delta
		if t > 0.35:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 - t / 0.35
		draw_polyline(pts, Color(0.6, 0.85, 1.0, 0.35 * a), 7.0)
		draw_polyline(pts, Color(0.85, 0.95, 1.0, a), 3.0)
		draw_polyline(pts, Color(1, 1, 1, a), 1.0)
		draw_circle(Vector2.ZERO, 10.0 * a, Color(0.8, 0.95, 1.0, a * 0.7))

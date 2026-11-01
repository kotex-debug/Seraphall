class_name BossCarcelero
extends Enemy
## EL CARCELERO, Guardián de la Llave (rango I).
## Cuerpo articulado: torso encadenado, casco-jaula con ojos de brasa y bola de pinchos con cadena.
## Ataques: Golpe, Barrido giratorio, Cadena de Captura (te arrastra), Lluvia de Jaulas,
## Terremoto (ondas que hay que saltar con el dash). Fase 2 (50%): furia, combos y prisioneros encadenados.

var rig: Node2D
var r_body: Sprite2D
var r_ball: Sprite2D
var r_eyes: Sprite2D
var _t := 0.0
var pose := "idle"
var _ball_rot := 0.3
var _stomp := 0.0
var _last_attack := ""
var _chain_line: Line2D
var _orbit_chain: Line2D
var _orbit_a := 0.0
var _kick := 0.0

const SC := 0.55

func _ready() -> void:
	super._ready()
	sprite.visible = false
	body_radius = 18.0
	shadow.scale = Vector2(5.0, 1.4)
	rig = Node2D.new()
	rig.position = Vector2(0, -32)
	add_child(rig)
	r_ball = Sprite2D.new()
	r_ball.texture = load("res://assets/sprites/cinematic/carcelero_ball.png")
	r_ball.offset = Vector2(0, 30)
	r_ball.position = Vector2(23, -12)
	r_ball.scale = Vector2(SC, SC)
	rig.add_child(r_ball)
	r_body = Sprite2D.new()
	r_body.texture = load("res://assets/sprites/cinematic/carcelero_body.png")
	r_body.scale = Vector2(SC, SC)
	rig.add_child(r_body)
	r_eyes = Sprite2D.new()
	r_eyes.texture = load("res://assets/sprites/cinematic/carcelero_eyes.png")
	r_eyes.scale = Vector2(SC, SC)
	r_eyes.material = Fx.add_material()
	rig.add_child(r_eyes)
	for s in [r_body, r_ball]:
		s.material = _flash_mat
	var cast := Depth3D.CastShadow.new()
	cast.src = r_body
	cast.world = world
	add_child(cast)
	move_child(cast, 0)
	var l := PointLight2D.new()
	l.texture = Fx.tex("light")
	l.color = Color(1, 0.45, 0.15)
	l.texture_scale = 1.2
	l.energy = 0.9
	l.position = Vector2(0, -50)
	add_child(l)
	_chain_line = Line2D.new()
	_chain_line.width = 2.0
	_chain_line.default_color = Color(0.7, 0.68, 0.75)
	_chain_line.visible = false
	add_child(_chain_line)
	_orbit_chain = Line2D.new()
	_orbit_chain.width = 2.0
	_orbit_chain.default_color = Color(0.6, 0.58, 0.66)
	_orbit_chain.visible = false
	rig.add_child(_orbit_chain)

func _animate(delta: float) -> void:
	_t += delta
	if state == "dead":
		return
	var moving := velocity.length() > 10.0 or (not multiplayer.is_server() and position.distance_to(_net_pos) > 1.0)
	if moving and pose == "idle":
		_stomp += delta * 7.0
		if int(_stomp / PI) != int((_stomp - delta * 7.0) / PI):
			G.shake(0.8, 0.08)
			Fx.burst(global_position + Vector2(0, 2), Color(0.6, 0.55, 0.55, 0.6), 4, 30.0, 0.5, "fx_soft", 60.0, Vector2.UP, 0.4, false)
	var target_ball := 0.3 + sin(_t * 1.8) * 0.25
	var target_y := -32.0 - absf(sin(_stomp)) * 3.0
	var tilt := sin(_stomp) * 0.06 if moving else 0.0
	match pose:
		"raise":
			target_ball = -2.7
			target_y = -36.0
		"slam":
			target_ball = 0.7
			target_y = -28.0
		"spin":
			target_ball = _ball_rot + delta * 14.0
		"throw":
			target_ball = -1.2
		"roar":
			target_y = -36.0
			tilt = sin(_t * 40.0) * 0.04
	if state == "stagger":
		target_y = -24.0
		tilt = 0.18
	var k: float = clamp(delta * (22.0 if pose == "slam" else 8.0), 0.0, 1.0)
	_ball_rot = target_ball if pose == "spin" else lerp_angle(_ball_rot, target_ball, k)
	if pose == "spin":
		# la bola gira alrededor del cuerpo en una elipse 3D: delante es más grande, detrás queda tapada
		_orbit_a += delta * 11.0
		var bp := Vector2(cos(_orbit_a) * 46.0, 18.0 + sin(_orbit_a) * 15.0)
		r_ball.rotation = 0.0
		r_ball.offset = Vector2.ZERO
		r_ball.position = Vector2(bp.x * float(facing), bp.y)
		r_ball.scale = Vector2(SC, SC) * (1.0 + 0.28 * sin(_orbit_a))
		r_ball.z_index = 1 if sin(_orbit_a) > 0.0 else -1
		r_ball.modulate = Color.WHITE.lerp(Color(0.55, 0.5, 0.6), clampf(-sin(_orbit_a), 0.0, 1.0) * 0.6)
		_orbit_chain.visible = true
		_orbit_chain.points = PackedVector2Array([Vector2(12 * facing, -8), r_ball.position])
		_orbit_chain.z_index = r_ball.z_index
		if randf() < 0.5:
			Fx.burst(global_position + Vector2(r_ball.position.x, rig.position.y + r_ball.position.y), Color(1, 0.6, 0.3, 0.7), 1, 20.0, 0.3, "fx_soft", 40.0, Vector2.UP, 0.25)
	else:
		r_ball.offset = Vector2(0, 30)
		r_ball.position = r_ball.position.lerp(Vector2(23, -12), clamp(delta * 12.0, 0.0, 1.0))
		r_ball.scale = Vector2(SC, SC)
		r_ball.z_index = 0
		r_ball.modulate = Color.WHITE
		r_ball.rotation = _ball_rot
		_orbit_chain.visible = false
	rig.position.y = lerpf(rig.position.y, target_y, clamp(delta * 10.0, 0.0, 1.0))
	rig.rotation = lerpf(rig.rotation, tilt, clamp(delta * 10.0, 0.0, 1.0))
	rig.scale.x = float(facing)
	_kick = lerpf(_kick, 0.0, clamp(delta * 12.0, 0.0, 1.0))
	Depth3D.lean_rig(rig, global_position, Depth3D.cam_center(self), -rig.position.y)
	rig.position.x += _kick
	r_eyes.modulate = Color(1, 0.5, 0.2, 0.7 + 0.3 * sin(_t * 6.0)) if phase == 1 else Color(1, 0.15, 0.1, 0.9 + 0.1 * sin(_t * 20.0))
	var tint := Color.WHITE if phase == 1 else Color(1.15, 0.8, 0.75)
	if slow_t > 0.0:
		tint = Color(0.7, 0.9, 1.3)
	r_body.modulate = tint
	if phase == 2 and randf() < 0.2:
		Fx.burst(global_position + Vector2(randf_range(-14, 14), -50), Color(1, 0.4, 0.1), 1, 25.0, 0.8, "fx_soft", 40.0, Vector2.UP, 0.25)
	var fl: float = _flash_mat.get_shader_parameter("flash")
	if fl > 0.0 and state != "busy":
		_flash_mat.set_shader_parameter("flash", max(0.0, fl - delta * 7.0))

func _chase(target: Node2D, delta: float) -> void:
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := to.normalized() if d > 46.0 else Vector2.ZERO
	velocity = velocity.lerp(want * cfg.speed * (1.35 if phase == 2 else 1.0) * (0.55 if slow_t > 0.0 else 1.0), clamp(delta * 5.0, 0.0, 1.0))
	if cooldown <= 0.0 and d < 220.0:
		_trigger(_pick(d), target.global_position)

func _pick(d: float) -> String:
	var pool := ["slam", "sweep", "chain", "cages", "quake"] if phase == 1 else ["slam", "sweep", "chain", "cages", "quake", "triple", "prisoners", "chain"]
	if d < 50.0:
		pool = ["sweep", "slam", "quake"]
	elif d > 120.0:
		pool = ["chain", "cages", "quake"]
	pool.erase(_last_attack)
	_last_attack = pool[randi() % pool.size()]
	return _last_attack

func perform(act: String, tpos: Vector2, seed: int) -> void:
	if state == "dead":
		return
	_attack_id += 1
	var my_id := _attack_id
	state = "busy"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var to := tpos - global_position
	facing = 1 if to.x >= 0.0 else -1
	var dir := to.normalized() if to.length() > 0.1 else Vector2.RIGHT
	var spd := 1.0 if phase == 1 else 0.8
	var dm := dmg_mult
	match act:
		"slam":
			pose = "raise"
			Fx.telegraph_circle(tpos, 42.0, 0.85 * spd)
			_tell(0.85 * spd)
			if not await _wait(0.85 * spd, my_id): return
			pose = "slam"
			_slam_at(tpos, 42.0, cfg.dmg * 1.15)
			if phase == 2:
				Haz.ring_wave(tpos, 10.0, 110.0, 0.8, cfg.dmg * 0.5 * dm, Color(1, 0.5, 0.2), 8.0, idx)
			if not await _wait(0.7 * spd, my_id): return
		"sweep":
			pose = "spin"
			Fx.telegraph_circle(global_position, 64.0, 0.6 * spd, Color(1, 0.4, 0.2))
			_tell(0.6 * spd)
			if not await _wait(0.6 * spd, my_id): return
			Audio.sfx("swing_heavy")
			for k in (2 if phase == 1 else 3):
				Fx.slash(global_position + Vector2(0, -20), dir.angle() + k * PI, 50.0, 300.0, Color(1, 0.6, 0.35, 0.9), 16.0, 0.3)
				_hit_circle(global_position, 64.0, cfg.dmg * 0.85, dir)
				if not await _wait(0.3, my_id): return
			if not await _wait(0.4, my_id): return
		"chain":
			# Cadena de Captura: lanza la cadena; si atrapa, arrastra y remata
			pose = "throw"
			Fx.telegraph_line(global_position + Vector2(0, -20), dir.angle(), 210.0, 14.0, 0.6 * spd, Color(1, 0.6, 0.2))
			_tell(0.6 * spd, Color(1, 0.6, 0.2))
			if not await _wait(0.6 * spd, my_id): return
			Audio.sfx("swing", 0.0)
			var caught := false
			var t := 0.0
			_chain_line.visible = true
			while t < 0.3:
				var tip := Vector2(0, -20) + dir * 210.0 * (t / 0.3)
				_chain_line.points = PackedVector2Array([Vector2(0, -20), tip])
				for p in world.local_players():
					if not caught and p.is_alive() and Haz.seg_dist(p.global_position + Vector2(0, -6), global_position + Vector2(0, -20), global_position + tip) < 10.0:
						var res: String = p.take_hit(cfg.dmg * 0.5 * dm, -dir, idx)
						if res == "hit":
							caught = true
							p.velocity = (global_position - p.global_position).normalized() * 420.0
							Fx.text(p.global_position, G.L(["¡ATRAPADO!", "CAUGHT!"]), Color(1, 0.6, 0.3), 9)
				if not await _wait(0.016, my_id):
					_chain_line.visible = false
					return
				t += 0.016
			_chain_line.visible = false
			if caught:
				pose = "raise"
				if not await _wait(0.35, my_id): return
				pose = "slam"
				_slam_at(global_position + dir * 26.0, 40.0, cfg.dmg * 1.2)
			if not await _wait(0.6, my_id): return
		"cages":
			# Lluvia de Jaulas
			pose = "roar"
			Audio.sfx("roar", -4.0)
			var n := 4 if phase == 1 else 7
			var spots := []
			for i in n:
				var p2 := tpos + (Vector2.ZERO if i == 0 else Vector2(rng.randf_range(-90, 90), rng.randf_range(-70, 70)))
				spots.append(p2)
				Fx.telegraph_circle(p2, 20.0, 1.0 + i * 0.12, Color(0.9, 0.7, 0.4))
			if not await _wait(1.0, my_id): return
			for p3 in spots:
				_cage_fall(p3)
				if not await _wait(0.12, my_id): return
			if not await _wait(0.6, my_id): return
		"quake":
			# Terremoto: pisotones que generan ondas expansivas (atraviésalas con el dash)
			pose = "raise"
			_tell(0.6)
			if not await _wait(0.6 * spd, my_id): return
			for k in (2 if phase == 1 else 3):
				pose = "slam"
				Audio.sfx("slam", -2.0)
				G.shake(4.0, 0.25)
				G.shockwave(global_position, 1.0, 0.5)
				Haz.ring_wave(global_position, 14.0, 200.0, 1.4, cfg.dmg * 0.7 * dm, Color(1, 0.5, 0.25), 10.0, idx)
				if not await _wait(0.55, my_id): return
				pose = "raise"
				if not await _wait(0.25, my_id): return
			pose = "idle"
			if not await _wait(0.5, my_id): return
		"triple":
			var spots2 := [tpos, tpos + Vector2(rng.randf_range(-50, 50), rng.randf_range(-40, 40)), tpos + Vector2(rng.randf_range(-60, 60), rng.randf_range(-50, 50))]
			for i in 3:
				Fx.telegraph_circle(spots2[i], 34.0, 0.7 + i * 0.35)
			_tell(0.7)
			for i in 3:
				pose = "raise"
				if not await _wait(0.6 if i == 0 else 0.25, my_id): return
				pose = "slam"
				_slam_at(spots2[i], 34.0, cfg.dmg)
				if not await _wait(0.1, my_id): return
			if not await _wait(0.8, my_id): return
		"prisoners":
			pose = "roar"
			Audio.sfx("roar")
			G.shake(3.0, 0.5)
			if multiplayer.is_server():
				for i in 2:
					world.spawn_extra_enemy("hueco", global_position + Vector2.from_angle(rng.randf() * TAU) * 70.0)
			if not await _wait(1.0, my_id): return
		"phase2":
			world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position, 18, Color(0.45, 0.36, 0.36), 1.4))
			pose = "roar"
			Audio.sfx("roar")
			G.shake(7.0, 1.0)
			G.shockwave(global_position, 1.8, 0.8)
			G.chroma(1.5, 0.6)
			G.flash(Color(1, 0.35, 0.1, 0.4), 0.4)
			world.show_boss_line(["¡NADIE ESCAPA DE MIS CADENAS!", "NO ONE ESCAPES MY CHAINS!"])
			Fx.burst(global_position + Vector2(0, -40), Color(1, 0.4, 0.1), 50, 200.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.6)
			phase = 2
			world.arena_fx("carcelero_p2")
			if not await _wait(1.4, my_id): return
	pose = "idle"
	_end_attack(my_id)

func _cage_fall(p: Vector2) -> void:
	# la jaula cae desde lo alto hacia la cámara: grande y desplazada, con su sombra creciendo en el suelo
	var c := Depth3D.Faller.new()
	c.tex = Fx.tex("cage")
	c.region = Rect2(0, 0, 18, 30)
	c.offset = Vector2(0, -15)
	c.height = 190.0
	c.dur = 0.34
	c.linger = 1.2
	c.position = p
	c.on_land = _cage_impact.bind(p)
	world.get_node("FX").add_child(c)

func _cage_impact(p: Vector2) -> void:
	Audio.sfx("hit_heavy", -2.0)
	G.shake(2.0, 0.15)
	Fx.burst(p, Color(0.6, 0.55, 0.6), 12, 80.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4, false)
	Fx.sparks(p, Vector2.UP, Color(1, 0.8, 0.4), 8, 140.0, 160.0)
	world.get_node("FX").add_child(Depth3D.Debris.new().setup(p, 5, Color(0.4, 0.36, 0.4), 0.6))
	for pl in world.local_players():
		if pl.is_alive() and pl.global_position.distance_to(p) < 22.0:
			var res: String = pl.take_hit(cfg.dmg * 0.8 * dmg_mult, Vector2.ZERO, idx)
			if res == "hit":
				pl.hurt_t = 0.9
				Fx.text(pl.global_position, G.L(["¡ENJAULADO!", "CAGED!"]), Color(1, 0.7, 0.4), 9)

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	if multiplayer.is_server() and phase == 1 and hp < max_hp * 0.5 and state != "dead":
		phase = 2
		state = "busy"
		world.bcast("enemy_action", [idx, "phase2", global_position, 0])

func die() -> void:
	super.die()
	if rig:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(rig, "rotation", 0.5, 0.8)
		tw.tween_property(rig, "position:y", -10.0, 0.8)
		tw.tween_property(r_eyes, "modulate:a", 0.0, 0.5)

func reset_state() -> void:
	super.reset_state()
	pose = "idle"
	_last_attack = ""
	if rig:
		rig.rotation = 0.0
		rig.position.y = -32.0

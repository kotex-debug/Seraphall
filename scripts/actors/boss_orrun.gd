class_name BossOrrun
extends Enemy
## ORRUN, EL CIERVO HUECO — Arconte del Estrato II (Bosque de Plumas Muertas).
## Un ciervo blanco con el pecho vacío donde arde un fuego azul. Guardaba los nidos de los serafines caídos.
## Ataques: Embestida (en la fase II, tres seguidas), Barrido de astas, Pisotón (onda que hay que saltar),
## Tormenta de plumas (abanico), Llamada de la manada (garzas) y Fuego del nido (columnas azules en línea).

var _t := 0.0
var _last := ""
var _transitioning := false
var _invuln := false
var _called := false
var _glow: PointLight2D

func _ready() -> void:
	super._ready()
	body_radius = 18.0
	shadow.scale = Vector2(5.0, 1.4)
	_glow = PointLight2D.new()
	_glow.texture = Fx.tex("light")
	_glow.color = Color(0.45, 0.8, 1.0)
	_glow.texture_scale = 2.2
	_glow.energy = 1.0
	_glow.position = Vector2(0, -26)
	add_child(_glow)

func reset_state() -> void:
	super.reset_state()
	_transitioning = false
	_invuln = false
	_called = false
	_last = ""
	if sprite:
		sprite.self_modulate = Color.WHITE
	if _glow:
		_glow.color = Color(0.45, 0.8, 1.0)

func _chase(target: Node2D, delta: float) -> void:
	if _transitioning:
		return
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := Vector2.ZERO
	if d > 150.0:
		want = to.normalized()
	elif d < 70.0:
		want = -to.normalized() * 0.7
	else:
		want = to.normalized().orthogonal() * (1.0 if int(_t / 2.6) % 2 == 0 else -1.0)
	velocity = velocity.lerp(want * cfg.speed * (0.6 if slow_t > 0.0 else 1.0), clamp(delta * 4.0, 0.0, 1.0))
	if cooldown <= 0.0:
		_trigger(_pick(d), target.global_position)

func _pick(d: float) -> String:
	var pool: Array = ["charge", "sweep", "stomp", "feathers", "charge"]
	if phase >= 2:
		pool = ["triple_charge", "sweep", "stomp", "feathers", "fire_line", "charge", "fire_line"]
	if not _called and hp < max_hp * 0.7:
		_called = true
		return "call"
	if d < 60.0:
		pool = ["sweep", "stomp"]
	pool.erase(_last)
	var p: String = pool[randi() % pool.size()]
	_last = p
	return p

func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if _invuln:
		return {}
	return super.server_apply_damage(dmg, dir, poise_dmg)

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	if new_hp <= 0.0:
		return
	if not multiplayer.is_server() or _transitioning:
		return
	if phase == 1 and hp < max_hp * 0.5:
		_transitioning = true
		state = "busy"
		world.bcast("enemy_action", [idx, "phase2", global_position, 0])

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
	match act:
		"charge", "triple_charge":
			var times := 3 if act == "triple_charge" else 1
			for rep in times:
				if rep > 0:
					var lp: Node2D = world.nearest_player(global_position)
					if lp:
						dir = (lp.global_position - global_position).normalized()
						facing = 1 if dir.x >= 0.0 else -1
				_play("attack", 0)
				Fx.telegraph_line(global_position, dir.angle(), 230.0, 30.0, 0.7 * spd if rep == 0 else 0.45, Color(0.5, 0.85, 1.0))
				_tell(0.7 * spd if rep == 0 else 0.45, Color(0.6, 0.9, 1.0))
				Audio.sfx("roar", -10.0, 0.2)
				if not await _wait(0.7 * spd if rep == 0 else 0.45, my_id): return
				_play("attack", 2)
				Audio.sfx("dash", 2.0)
				var t := 0.0
				var hit := false
				while t < 0.5:
					if multiplayer.is_server():
						velocity = dir * 470.0
						lunge = velocity
					if randf() < 0.7:
						Fx.burst(global_position + Vector2(0, -6), Color(0.85, 0.95, 1.0), 2, 40.0, 0.5, "fx_feather", 60.0, -dir, 0.8, false)
					if not hit:
						hit = _hit_circle(global_position, body_radius + 10.0, cfg.dmg * 1.25, dir)
					if not await _wait(0.016, my_id): return
					t += 0.016
				if multiplayer.is_server():
					velocity = Vector2.ZERO
					lunge = Vector2.ZERO
				G.shake(3.0, 0.2)
				world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position, 6, Color(0.5, 0.45, 0.4), 0.8))
				if not await _wait(0.35, my_id): return
			if not await _wait(0.5 * spd, my_id): return
		"sweep":
			_play("attack", 1)
			Fx.telegraph_circle(global_position, 66.0, 0.55 * spd, Color(0.5, 0.85, 1.0))
			_tell(0.55 * spd, Color(0.6, 0.9, 1.0))
			if not await _wait(0.55 * spd, my_id): return
			_play("attack", 2)
			Audio.sfx("swing_heavy")
			Fx.slash(global_position + Vector2(0, -20), dir.angle(), 54.0, 260.0, Color(0.85, 0.95, 1.0, 0.95), 18.0, 0.3)
			_hit_circle(global_position, 66.0, cfg.dmg, dir)
			if not await _wait(0.6, my_id): return
		"stomp":
			_play("attack", 0)
			var up := create_tween()
			up.tween_property(sprite, "position:y", -18.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tell(0.55 * spd, Color(0.6, 0.9, 1.0))
			if not await _wait(0.55 * spd, my_id): return
			var dn := create_tween()
			dn.tween_property(sprite, "position:y", 0.0, 0.1)
			if not await _wait(0.1, my_id): return
			_slam_at(global_position, 52.0, cfg.dmg * 1.1)
			Haz.ring_wave(global_position, 20.0, 210.0, 1.2, cfg.dmg * 0.75 * dmg_mult, Color(0.6, 0.9, 1.0), 9.0, idx)
			if phase >= 2:
				if not await _wait(0.5, my_id): return
				Haz.ring_wave(global_position, 20.0, 210.0, 1.2, cfg.dmg * 0.75 * dmg_mult, Color(0.6, 0.9, 1.0), 9.0, idx)
			if not await _wait(0.9, my_id): return
		"feathers":
			_play("attack", 0)
			Audio.sfx("charge", -4.0)
			_tell(0.6 * spd, Color(0.9, 0.95, 1.0))
			if not await _wait(0.6 * spd, my_id): return
			var volleys := 1 if phase == 1 else 2
			for v in volleys:
				_play("attack", 2)
				Audio.sfx("enemy_shot")
				var n := 11 if phase == 1 else 15
				for i in n:
					var a := dir.angle() + (i - (n - 1) / 2.0) * 0.13 + (0.065 if v == 1 else 0.0)
					world.spawn_projectile_local(global_position + Vector2(0, -26), Vector2.from_angle(a) * 150.0, cfg.dmg * 0.7 * dmg_mult, "feather", "enemy", 1, 5.0, 3.0, 0)
				if not await _wait(0.45, my_id): return
			if not await _wait(0.5, my_id): return
		"call":
			_play("attack", 1)
			Audio.sfx("roar")
			world.show_boss_line(["¡Manada! ¡A mí!", "Herd! To me!"], "orrun")
			G.shake(4.0, 0.6)
			if multiplayer.is_server():
				for k in 2:
					world.spawn_extra_enemy("garza", global_position + Vector2(-60 + k * 120, 40))
			if not await _wait(1.2, my_id): return
		"fire_line":
			# fuego del nido: columnas de llama azul que avanzan en línea hacia ti
			_play("attack", 1)
			Audio.sfx("nova", -6.0)
			for i in 7:
				var p := global_position + dir * (40.0 + i * 34.0)
				Fx.telegraph_circle(p, 18.0, 0.45, Color(0.4, 0.75, 1.0))
				get_tree().create_timer(0.45, false).timeout.connect(_blue_pillar.bind(p))
				if not await _wait(0.12, my_id): return
			if not await _wait(0.8, my_id): return
		"phase2":
			_transitioning = true
			_invuln = true
			Audio.sfx("roar", 2.0)
			G.shake(8.0, 1.2)
			G.flash(Color(0.5, 0.8, 1.0, 0.45), 0.5)
			G.chroma(1.6, 0.7)
			world.show_boss_line(Strata.ARCHONS["orrun"]["phase"], "orrun")
			Fx.ring(global_position + Vector2(0, -20), 8.0, 150.0, Color(0.5, 0.85, 1.0), 0.9, 7.0)
			Fx.burst(global_position + Vector2(0, -28), Color(0.6, 0.9, 1.0), 60, 200.0, 1.4, "fx_feather", 180.0, Vector2.UP, 1.4, false, Vector2(0, 40))
			sprite.self_modulate = Color(0.75, 0.9, 1.25)
			_glow.color = Color(0.3, 0.6, 1.0)
			_glow.energy = 1.8
			phase = 2
			if not await _wait(1.4, my_id):
				_invuln = false
				return
			_invuln = false
			_transitioning = false
	_end_attack(my_id)

func _blue_pillar(p: Vector2) -> void:
	if state == "dead" or not is_inside_tree():
		return
	Audio.sfx("hit_heavy", -10.0)
	Fx.burst(p, Color(0.5, 0.85, 1.0), 16, 90.0, 0.6, "fx_soft", 40.0, Vector2.UP, 0.5)
	Fx.light_flash(p, Color(0.4, 0.75, 1.0), 1.6, 0.9, 0.35)
	Fx.ring(p, 3.0, 20.0, Color(0.6, 0.9, 1.0), 0.3, 3.0)
	_hit_circle(p, 18.0, cfg.dmg * 0.8, Vector2.ZERO)

func _animate(delta: float) -> void:
	_t += delta
	super._animate(delta)
	if state != "dead" and _glow:
		_glow.energy = (1.0 if phase == 1 else 1.8) + 0.25 * sin(_t * 3.0)
		if randf() < (0.08 if phase == 1 else 0.2):
			Fx.burst(global_position + Vector2(facing * 6, -30), Color(0.5, 0.85, 1.0), 1, 20.0, 0.6, "fx_px", 40.0, Vector2.UP)

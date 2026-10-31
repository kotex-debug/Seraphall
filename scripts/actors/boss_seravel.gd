class_name BossSeravel
extends Enemy
## SERAVEL, Guardiana de las Puertas — Arconte del Estrato I.
## Fase 1: espadas orbitantes, tajo-dash, lluvia de espadas.
## Fase 2 (50%): aureola roja, espiral de proyectiles (bullet-hell), invocación de Huecos, ataques más rápidos.

var _halo_light: PointLight2D
var _float_t := 0.0
var _transitioning := false
var _attack_cycle := 0

func _ready() -> void:
	super._ready()
	_halo_light = PointLight2D.new()
	_halo_light.texture = Fx.tex("light")
	_halo_light.texture_scale = 2.2
	_halo_light.energy = 1.1
	_halo_light.color = Color(1, 0.85, 0.5)
	_halo_light.position = Vector2(0, -40)
	add_child(_halo_light)

func _animate(delta: float) -> void:
	super._animate(delta)
	_float_t += delta
	if state != "dead":
		sprite.offset.y = cfg.off + sin(_float_t * 2.4) * 2.5
	if randf() < 0.25 and visible and state != "dead":
		var c := Color(1, 0.9, 0.6) if phase == 1 else Color(1, 0.35, 0.35)
		Fx.burst(global_position + Vector2(randf_range(-14, 14), randf_range(-40, -8)), c, 1, 20.0, 0.9, "fx_feather" if randf() < 0.3 else "fx_px", 60.0, Vector2.DOWN, 0.9, false, Vector2(0, 25))

func _chase(target: Node2D, delta: float) -> void:
	if _transitioning:
		return
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := Vector2.ZERO
	if d > 120.0:
		want = to.normalized()
	elif d < 70.0:
		want = -to.normalized()
	else:
		want = to.normalized().orthogonal() * (1.0 if int(_float_t / 3.0) % 2 == 0 else -1.0)
	velocity = velocity.lerp(want * cfg.speed, clamp(delta * 4.0, 0.0, 1.0))
	if cooldown <= 0.0:
		_trigger(_pick(d), target.global_position)

func _pick(d: float) -> String:
	_attack_cycle += 1
	if phase == 1:
		var opts := ["orbit", "dash", "rain"]
		if d < 50.0:
			return "dash"
		return opts[_attack_cycle % 3]
	var opts2 := ["spiral", "dash", "rain", "orbit", "dash", "summon"]
	if d < 45.0:
		return "dash"
	return opts2[_attack_cycle % opts2.size()]

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
		"orbit":
			_play("attack", 0)
			Audio.sfx("lance", -2.0)
			var n := 6 if phase == 1 else 9
			for i in n:
				var a := TAU * i / n
				var p := global_position + Vector2(0, -22) + Vector2.from_angle(a) * 34.0
				var pr: Projectile = world.spawn_projectile_local(p, Vector2.from_angle(a) * 0.01, cfg.dmg * 0.8, "sword", "enemy", 1, 5.0, 4.0, 0)
				pr.delay = 0.7 * spd + i * 0.09
				pr.target_pos = tpos + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
				pr.speed_after = 260.0
			_play("attack", 1)
			if not await _wait(1.3 * spd, my_id): return
		"dash":
			_play("attack", 0)
			var length := 190.0
			Fx.telegraph_line(global_position, dir.angle(), length, 26.0, 0.55 * spd, Color(1, 0.3, 0.4))
			_tell(0.55 * spd, Color(1, 0.4, 0.5))
			if not await _wait(0.55 * spd, my_id): return
			_play("attack", 2)
			Audio.sfx("swing_heavy")
			var start := global_position
			var t := 0.0
			var hit := false
			while t < 0.24:
				if multiplayer.is_server():
					velocity = dir * (length / 0.24)
					lunge = velocity
				Fx.afterimage(sprite, sprite.global_position, Color(1, 0.5, 0.6, 0.55) if phase == 1 else Color(1, 0.2, 0.3, 0.6), 0.3)
				if not hit:
					hit = _hit_circle(global_position, 20.0, cfg.dmg * 1.1, dir)
				if not await _wait(0.016, my_id): return
				t += 0.016
			if multiplayer.is_server():
				velocity = Vector2.ZERO
				lunge = Vector2.ZERO
			Fx.slash(global_position + Vector2(0, -20), dir.angle(), 40.0, 200.0, Color(1, 0.5, 0.6, 0.9), 16.0, 0.3)
			_hit_arc(global_position + Vector2(0, -16), dir.angle(), 44.0, 200.0, cfg.dmg)
			if phase == 2:
				for i in 8:
					var a := TAU * i / 8.0
					world.spawn_projectile_local(global_position + Vector2(0, -16), Vector2.from_angle(a) * 120.0, cfg.dmg * 0.6, "red", "enemy", 1, 5.0, 2.5, 0)
			if not await _wait(0.6 * spd, my_id): return
		"rain":
			_play("attack", 0)
			Audio.sfx("roar", -10.0)
			var count := 7 if phase == 1 else 12
			var spots := []
			for i in count:
				var p := tpos + Vector2(rng.randf_range(-80, 80), rng.randf_range(-60, 60))
				if i == 0:
					p = tpos
				spots.append(p)
				Fx.telegraph_circle(p, 18.0, 0.9 * spd + i * 0.06, Color(1, 0.85, 0.4))
			_play("attack", 1)
			if not await _wait(0.9 * spd, my_id): return
			for i in count:
				_sword_fall(spots[i])
				if not await _wait(0.06, my_id): return
			if not await _wait(0.5 * spd, my_id): return
		"spiral":
			_play("attack", 0)
			Fx.ring(global_position + Vector2(0, -20), 40.0, 4.0, Color(1, 0.3, 0.3), 0.6, 3.0)
			_tell(0.6, Color(1, 0.3, 0.3))
			if not await _wait(0.6, my_id): return
			_play("attack", 1)
			var t2 := 0.0
			var base := rng.randf() * TAU
			while t2 < 2.6:
				for arm in 4:
					var a := base + arm * TAU / 4.0 + t2 * 2.1
					world.spawn_projectile_local(global_position + Vector2(0, -20), Vector2.from_angle(a) * 105.0, cfg.dmg * 0.55, "red", "enemy", 1, 4.0, 3.5, 0)
				Audio.sfx("enemy_shot", -12.0)
				if not await _wait(0.13, my_id): return
				t2 += 0.13
			if not await _wait(0.6, my_id): return
		"summon":
			_play("attack", 0)
			Audio.sfx("roar", -4.0)
			Fx.light_flash(global_position, Color(1, 0.3, 0.3), 2.0, 2.0, 0.6)
			if multiplayer.is_server():
				for i in 2:
					var p := global_position + Vector2.from_angle(rng.randf() * TAU) * 60.0
					world.spawn_extra_enemy("hueco", p)
			if not await _wait(1.0, my_id): return
		"phase2":
			_transitioning = true
			_play("attack", 1)
			Audio.sfx("roar")
			Audio.play_music("boss2", 0.5)
			G.shake(8.0, 1.2)
			G.flash(Color(1, 0.2, 0.2, 0.5), 0.5)
			Fx.ring(global_position + Vector2(0, -20), 10.0, 160.0, Color(1, 0.3, 0.3), 0.9, 8.0)
			Fx.burst(global_position + Vector2(0, -20), Color(1, 0.3, 0.3), 60, 200.0, 1.2, "fx_feather", 180.0, Vector2.UP, 1.4, false, Vector2(0, 40))
			_hit_circle(global_position, 60.0, 10.0, Vector2.ZERO)
			world.show_boss_line(["¡Basta! ¡Mira lo que el Arquitecto hizo de nosotros!", "Enough! Look what the Architect made of us!"])
			phase = 2
			_halo_light.color = Color(1, 0.3, 0.3)
			_halo_light.energy = 1.6
			if not await _wait(1.6, my_id): return
			_transitioning = false
	_end_attack(my_id)

func _sword_fall(p: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = Fx.tex("proj_sword")
	s.rotation = PI / 2.0
	s.position = p + Vector2(0, -90)
	s.material = Fx.add_material()
	world.get_node("FX").add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position", p, 0.12).set_ease(Tween.EASE_IN)
	tw.tween_callback(_sword_impact.bind(p))
	tw.tween_property(s, "modulate:a", 0.0, 0.4)
	tw.tween_callback(s.queue_free)

func _sword_impact(p: Vector2) -> void:
	Audio.sfx("hit_heavy", -6.0)
	Fx.ring(p, 4.0, 22.0, Color(1, 0.85, 0.4), 0.3, 3.0)
	Fx.burst(p, Color(1, 0.85, 0.5), 8, 80.0, 0.4)
	G.shake(1.5, 0.1)
	_hit_circle(p, 18.0, cfg.dmg * 0.9, Vector2.ZERO)

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	if phase == 1 and hp < max_hp * 0.5 and multiplayer.is_server() and not _transitioning:
		_transitioning = true
		state = "busy"
		world.bcast("enemy_action", [idx, "phase2", global_position, 0])

func reset_state() -> void:
	super.reset_state()
	_transitioning = false
	_attack_cycle = 0
	if _halo_light:
		_halo_light.color = Color(1, 0.85, 0.5)
		_halo_light.energy = 1.1

class_name BossVulkaris
extends Enemy
## VULKARIS, EL HERRERO DE AUREOLAS — Arconte del Estrato III (Fundición de Halos).
## Un gigante con máscara de hierro y una aureola al rojo a la espalda. Forjó todas las aureolas de la Espiral.
## Ataques: Martillazo (con onda en la fase II), Aureolas al rojo (anillos que salen en abanico y vuelven),
## Lluvia de metal fundido, Salto sobre el yunque y, en la fase II, Grietas de forja (líneas de lava que estallan).

var _t := 0.0
var _last := ""
var _transitioning := false
var _invuln := false
var _hover := 0.0
var _heat: PointLight2D

func _ready() -> void:
	super._ready()
	body_radius = 18.0
	shadow.scale = Vector2(5.0, 1.5)
	_heat = PointLight2D.new()
	_heat.texture = Fx.tex("light")
	_heat.color = Color(1, 0.5, 0.2)
	_heat.texture_scale = 2.4
	_heat.energy = 1.1
	_heat.position = Vector2(0, -28)
	add_child(_heat)

func reset_state() -> void:
	super.reset_state()
	_transitioning = false
	_invuln = false
	_hover = 0.0
	_last = ""
	if sprite:
		sprite.self_modulate = Color.WHITE
		sprite.position.y = 0.0

func _chase(target: Node2D, delta: float) -> void:
	if _transitioning:
		return
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := to.normalized() if d > 70.0 else Vector2.ZERO
	velocity = velocity.lerp(want * cfg.speed * (0.6 if slow_t > 0.0 else 1.0), clamp(delta * 4.0, 0.0, 1.0))
	if cooldown <= 0.0:
		_trigger(_pick(d), target.global_position)

func _pick(d: float) -> String:
	var pool: Array = ["hammer", "halos", "drops", "leap", "hammer"]
	if phase >= 2:
		pool = ["hammer", "halos", "drops", "leap", "cracks", "cracks", "halos"]
	if d > 160.0:
		pool = ["halos", "leap", "drops"] if phase == 1 else ["halos", "leap", "cracks"]
	pool.erase(_last)
	var p: String = pool[randi() % pool.size()]
	_last = p
	return p

func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if _invuln or _hover > 30.0:
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
	var spd := 1.0 if phase == 1 else 0.82
	match act:
		"hammer":
			var spot := global_position + to.limit_length(70.0)
			_play("attack", 0)
			Fx.telegraph_circle(spot, 46.0, 0.85 * spd, Color(1, 0.45, 0.15))
			_tell(0.85 * spd, Color(1, 0.55, 0.2))
			Audio.sfx("charge", -4.0)
			if not await _wait(0.6 * spd, my_id): return
			_play("attack", 1)
			if not await _wait(0.25 * spd, my_id): return
			_play("attack", 2)
			_slam_at(spot, 46.0, cfg.dmg * 1.3)
			Fx.burst(spot, Color(1, 0.6, 0.2), 30, 160.0, 0.8, "fx_px", 180.0, Vector2.UP, 1.0, true, Vector2(0, 200))
			if phase >= 2:
				Haz.ring_wave(spot, 20.0, 200.0, 1.1, cfg.dmg * 0.7 * dmg_mult, Color(1, 0.5, 0.2), 9.0, idx)
			if not await _wait(0.9, my_id): return
		"halos":
			# lanza aureolas al rojo en abanico; se frenan, giran y vuelven hacia ti
			_play("attack", 1)
			Audio.sfx("swing_heavy")
			_tell(0.5 * spd, Color(1, 0.6, 0.2))
			if not await _wait(0.5 * spd, my_id): return
			_play("attack", 2)
			var n := 5 if phase == 1 else 7
			for i in n:
				var a := dir.angle() + (i - (n - 1) / 2.0) * 0.3
				var pr: Projectile = world.spawn_projectile_local(global_position + Vector2(0, -24), Vector2.from_angle(a) * 220.0, cfg.dmg * 0.7 * dmg_mult, "halo", "enemy", 1, 8.0, 3.2, 0)
				pr.accel = -260.0
				pr.set_meta("boomerang", global_position)
			Audio.sfx("enemy_shot", 0.0)
			if not await _wait(1.6, my_id): return
		"drops":
			_play("attack", 0)
			Audio.sfx("roar", -8.0)
			G.shake(3.0, 0.8)
			var n2 := 10 if phase == 1 else 16
			for i in n2:
				var lp: Node2D = world.nearest_player(global_position)
				var c: Vector2 = lp.global_position if lp and i % 3 == 0 else global_position + Vector2(rng.randf_range(-150, 150), rng.randf_range(-110, 110))
				var d := 0.8 + i * 0.07
				Fx.telegraph_circle(c, 16.0, d, Color(1, 0.5, 0.15))
				_drop_metal(c, d)
			if not await _wait(1.2 + n2 * 0.07, my_id): return
		"leap":
			_play("attack", 0)
			_tell(0.4, Color(1, 0.55, 0.2))
			if not await _wait(0.4, my_id): return
			Audio.sfx("dash", 0.0)
			var up := create_tween()
			up.tween_property(self, "_hover", 150.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if not await _wait(0.6, my_id): return
			var lp2: Node2D = world.nearest_player(global_position)
			var land: Vector2 = lp2.global_position if lp2 else tpos
			Fx.telegraph_circle(land, 54.0, 0.75 * spd, Color(1, 0.35, 0.1))
			if multiplayer.is_server():
				position = land
				_net_pos = land
			if not await _wait(0.75 * spd, my_id): return
			var dn := create_tween()
			dn.tween_property(self, "_hover", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if not await _wait(0.14, my_id): return
			_play("attack", 2)
			_slam_at(global_position, 54.0, cfg.dmg * 1.5)
			G.flash(Color(1, 0.5, 0.2, 0.25), 0.2)
			Haz.ring_wave(global_position, 24.0, 180.0, 0.9, cfg.dmg * 0.6 * dmg_mult, Color(1, 0.55, 0.2), 8.0, idx)
			if not await _wait(1.0, my_id): return
		"cracks":
			# grietas de forja: líneas de lava que cruzan la sala y estallan tras el aviso
			_play("attack", 2)
			Audio.sfx("slam")
			G.shake(4.0, 0.4)
			var c2 := tpos
			var base := rng.randf() * PI
			for i in 4:
				var a2 := base + i * PI / 4.0
				var d2 := Vector2.from_angle(a2) * 260.0
				Haz.line_blast(c2 - d2, c2 + d2, 18.0, 1.0 * spd + i * 0.2, cfg.dmg * 0.9 * dmg_mult, Color(1, 0.45, 0.12), idx)
			if not await _wait(2.0, my_id): return
		"phase2":
			_transitioning = true
			_invuln = true
			Audio.sfx("roar", 2.0)
			G.shake(8.0, 1.2)
			G.flash(Color(1, 0.5, 0.2, 0.5), 0.5)
			G.chroma(1.8, 0.7)
			world.show_boss_line(Strata.ARCHONS["vulkaris"]["phase"], "vulkaris")
			Fx.ring(global_position + Vector2(0, -24), 8.0, 170.0, Color(1, 0.5, 0.2), 0.9, 8.0)
			Fx.burst(global_position + Vector2(0, -28), Color(1, 0.6, 0.2), 70, 220.0, 1.2, "fx_px", 180.0, Vector2.UP, 1.4, true, Vector2(0, 160))
			sprite.self_modulate = Color(1.25, 0.9, 0.8)
			_heat.color = Color(1, 0.35, 0.1)
			_heat.energy = 2.0
			phase = 2
			if not await _wait(1.4, my_id):
				_invuln = false
				return
			_invuln = false
			_transitioning = false
	_end_attack(my_id)

func _drop_metal(p: Vector2, dur: float) -> void:
	var f := Depth3D.Faller.new()
	f.tex = Fx.tex("proj_orb")
	f.height = 170.0
	f.dur = dur
	f.linger = 0.05
	f.additive = true
	f.modulate = Color(1, 0.6, 0.2)
	f.position = p
	f.on_land = _metal_splash.bind(p)
	world.get_node("FX").add_child(f)

func _metal_splash(p: Vector2) -> void:
	Audio.sfx("hit", -12.0, 0.3)
	Fx.ring(p, 4.0, 20.0, Color(1, 0.6, 0.2), 0.3, 3.0)
	Fx.burst(p, Color(1, 0.65, 0.25), 12, 80.0, 0.5, "fx_px", 180.0, Vector2.UP, 1.0, true, Vector2(0, 160))
	Fx.scorch(p, 10.0)
	if state != "dead":
		_hit_circle(p, 15.0, cfg.dmg * 0.75, Vector2.ZERO)

func _animate(delta: float) -> void:
	_t += delta
	super._animate(delta)
	if state == "dead":
		return
	sprite.position.y = -_hover
	if _hover > 1.0:
		sprite.scale = Vector2.ONE * (1.0 + _hover / 300.0)
	shadow.scale = Vector2(5.0, 1.5) * (1.0 - clampf(_hover / 220.0, 0.0, 0.6))
	_heat.position = Vector2(0, -28 - _hover)
	_heat.energy = (1.1 if phase == 1 else 2.0) + 0.3 * sin(_t * 5.0)
	if randf() < (0.1 if phase == 1 else 0.25):
		Fx.burst(global_position + Vector2(randf_range(-14, 14), -40 - _hover), Color(1, 0.6, 0.2), 1, 30.0, 0.7, "fx_px", 50.0, Vector2.UP)

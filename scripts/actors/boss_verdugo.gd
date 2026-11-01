class_name BossVerdugo
extends Enemy
## EL VERDUGO — el que fuiste (batalla secreta del Cadalso, bajo la Capilla Olvidada).
## Lleva TU aspecto tal y como eras antes de caer: alas intactas, aureola de oro y la Hoja del Verdugo.
## Duelo espejo con tu propio repertorio: combo de tres tajos, embestida, lanzas de luz, nova,
## guardia con contraataque y, en la fase II (plumas negras), la Sentencia: salta hacia la cámara
## y cae entre una lluvia de hojas.

var blade_pivot: Node2D
var blade: Sprite2D
var _aura: PointLight2D
var _t := 0.0
var _blade_rot := 0.7
var _blade_goal := 0.7
var _guard := 0.0
var _last := ""
var _invuln := false
var _transitioning := false
var _hover := 0.0
var _look := {}
var _feathers := 10
var summoned := false

func _ready() -> void:
	super._ready()
	body_radius = 9.0
	_look = G.look.duplicate()
	_look["armor"] = 1      # acero negro
	_look["cloak"] = 0      # carmesí
	_look["wing"] = 0       # alba: las alas de antes
	_look["halo"] = 0       # oro
	_look["eye"] = 6        # oro
	sprite.texture = Look.texture(_look, 10)
	blade_pivot = Node2D.new()
	blade_pivot.position = Vector2(0, -11)
	add_child(blade_pivot)
	blade = Sprite2D.new()
	blade.texture = Fx.tex("weapon_verdugo")
	blade.offset = Vector2(15, 0)
	blade.scale = Vector2(1.25, 1.25)
	blade.material = _flash_mat
	blade_pivot.add_child(blade)
	_aura = PointLight2D.new()
	_aura.texture = Fx.tex("light")
	_aura.color = Color(1, 0.3, 0.35)
	_aura.texture_scale = 1.1
	_aura.energy = 0.9
	_aura.position = Vector2(0, -14)
	add_child(_aura)
	_apply_summoned()

func _apply_summoned() -> void:
	visible = summoned
	if not summoned:
		active = false

func reset_state() -> void:
	super.reset_state()
	_invuln = false
	_transitioning = false
	_guard = 0.0
	_hover = 0.0
	_last = ""
	_feathers = 10
	if sprite and not _look.is_empty():
		sprite.texture = Look.texture(_look, 10)
		_aura.color = Color(1, 0.3, 0.35)
	summoned = false
	_apply_summoned()

func summon() -> void:
	summoned = true
	visible = true
	reset_hp_only()

func reset_hp_only() -> void:
	hp = max_hp
	phase = 1
	state = "idle"
	_feathers = 10
	sprite.texture = Look.texture(_look, 10)

# ====================================================================== IA (anfitrión)
func _chase(target: Node2D, delta: float) -> void:
	if _transitioning:
		return
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := Vector2.ZERO
	# rodea a su presa como un duelista: se acerca, se aparta y la flanquea
	if d > 110.0:
		want = to.normalized()
	elif d < 40.0:
		want = -to.normalized() * 0.6
	else:
		want = to.normalized().orthogonal() * (1.0 if int(_t / 2.2) % 2 == 0 else -1.0) * 0.8 + to.normalized() * 0.3
	velocity = velocity.lerp(want.limit_length(1.0) * cfg.speed * (0.6 if slow_t > 0.0 else 1.0), clamp(delta * 5.0, 0.0, 1.0))
	if cooldown <= 0.0:
		_trigger(_pick(d), target.global_position)

func _pick(d: float) -> String:
	var pool: Array = ["combo", "dash", "lances", "nova", "guard"]
	if phase >= 2:
		pool = ["combo", "dash", "lances", "nova", "guard", "sentence", "combo"]
	if d < 45.0:
		pool = ["combo", "nova", "guard"] if phase == 1 else ["combo", "nova", "sentence"]
	elif d > 130.0:
		pool = ["dash", "lances"] if phase == 1 else ["dash", "lances", "sentence"]
	pool.erase(_last)
	if pool.is_empty():
		pool = ["combo"]
	var p: String = pool[randi() % pool.size()]
	_last = p
	return p

func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if _invuln or _hover > 20.0:
		return {}
	if _guard > 0.0:
		# guardia: bloquea y contraataca por la espalda de quien le golpeó
		_guard = 0.0
		var tgt: Node2D = world.nearest_player(global_position)
		world.bcast("enemy_action", [idx, "riposte", tgt.global_position if tgt else global_position - dir * 30.0, randi()])
		return {}
	return super.server_apply_damage(dmg, dir, poise_dmg)

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	if not multiplayer.is_server() or _transitioning:
		return
	if phase == 1 and hp < max_hp * 0.5:
		_transitioning = true
		state = "busy"
		world.bcast("enemy_action", [idx, "phase2", global_position, 0])

# ====================================================================== ataques (todos los clientes)
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
		"combo":
			# tres tajos que vuelven a apuntar antes de cada golpe (como los tuyos)
			for i in 3:
				var lp: Node2D = world.nearest_player(global_position)
				if lp:
					dir = (lp.global_position - global_position).normalized()
					facing = 1 if dir.x >= 0.0 else -1
				_blade_goal = dir.angle() - 1.6 * facing
				_tell([0.42, 0.24, 0.32][i] * spd, Color(1, 0.35, 0.4))
				if not await _wait([0.42, 0.24, 0.32][i] * spd, my_id): return
				_blade_goal = dir.angle() + 1.4 * facing
				Audio.sfx("swing" if i < 2 else "swing_heavy", 0.0, 0.1)
				if multiplayer.is_server():
					lunge = dir * (170.0 if i < 2 else 240.0)
				var arc := 150.0 if i < 2 else 260.0
				Fx.slash(global_position + Vector2(0, -8) + dir * 6, dir.angle(), 30.0 if i < 2 else 38.0, arc, Color(1, 0.3, 0.38, 0.9), 10.0 if i < 2 else 15.0, 0.2, i % 2 == 0)
				if not await _wait(0.07, my_id): return
				_hit_arc(global_position + Vector2(0, -6), dir.angle(), 40.0 if i < 2 else 48.0, arc, cfg.dmg * (1.0 if i < 2 else 1.35))
				if i == 2 and phase >= 2:
					world.spawn_projectile_local(global_position + Vector2(0, -6) + dir * 12, dir * 200.0, cfg.dmg * 0.7 * dmg_mult, "verdict", "enemy", 1, 10.0, 0.9, 0)
				if not await _wait(0.16, my_id): return
			if not await _wait(0.45 * spd, my_id): return
		"riposte":
			# contraataque: aparece a tu espalda y corta
			_guard = 0.0
			Audio.sfx("parry")
			Fx.ring(global_position + Vector2(0, -10), 4.0, 30.0, Color(1, 0.9, 0.6), 0.25, 3.0)
			Fx.text(global_position + Vector2(0, -26), G.L(["¡CONTRA!", "COUNTER!"]), Color(1, 0.85, 0.5), 10)
			Fx.afterimage(sprite, sprite.global_position, Color(1, 0.4, 0.45, 0.6))
			var behind := tpos + (tpos - global_position).normalized() * 22.0
			if multiplayer.is_server():
				position = behind
				_net_pos = behind
			else:
				position = behind
			var d2 := (tpos - behind).normalized()
			facing = 1 if d2.x >= 0.0 else -1
			if not await _wait(0.22, my_id): return
			Audio.sfx("swing_heavy")
			Fx.slash(global_position + Vector2(0, -8), d2.angle(), 34.0, 200.0, Color(1, 0.9, 0.6, 0.95), 14.0, 0.22)
			_hit_arc(global_position + Vector2(0, -6), d2.angle(), 44.0, 200.0, cfg.dmg * 1.4)
			if not await _wait(0.6, my_id): return
		"dash":
			var length := 170.0
			Fx.telegraph_line(global_position, dir.angle(), length, 22.0, 0.55 * spd, Color(1, 0.3, 0.4))
			_tell(0.55 * spd, Color(1, 0.4, 0.45))
			_blade_goal = dir.angle() + PI * 0.9
			if not await _wait(0.55 * spd, my_id): return
			Audio.sfx("dash")
			var t := 0.0
			var hit := false
			var trail := []
			while t < 0.22:
				if multiplayer.is_server():
					velocity = dir * (length / 0.22)
					lunge = velocity
				Fx.afterimage(sprite, sprite.global_position, Color(1, 0.35, 0.45, 0.55), 0.3)
				if int(t * 100.0) % 4 == 0:
					trail.append(global_position)
				if not hit:
					hit = _hit_circle(global_position, 16.0, cfg.dmg * 1.1, dir)
				if not await _wait(0.016, my_id): return
				t += 0.016
			if multiplayer.is_server():
				velocity = Vector2.ZERO
				lunge = Vector2.ZERO
			Fx.slash(global_position + Vector2(0, -8), dir.angle(), 30.0, 180.0, Color(1, 0.4, 0.45, 0.9), 12.0, 0.2)
			_hit_arc(global_position + Vector2(0, -6), dir.angle(), 40.0, 180.0, cfg.dmg)
			if phase >= 2:
				# las plumas que suelta en la embestida estallan poco después
				for p in trail:
					Fx.telegraph_circle(p, 14.0, 0.55, Color(1, 0.3, 0.4))
				if not await _wait(0.55, my_id): return
				for p2 in trail:
					Fx.burst(p2, Color(1, 0.35, 0.4), 8, 60.0, 0.4, "fx_feather", 180.0, Vector2.UP, 0.9, false)
					Fx.ring(p2, 3.0, 16.0, Color(1, 0.4, 0.45), 0.25, 2.0)
					_hit_circle(p2, 14.0, cfg.dmg * 0.6, Vector2.ZERO)
			if not await _wait(0.4 * spd, my_id): return
		"lances":
			# tus Lanzas de Luz, pero carmesí
			_blade_goal = -PI / 2.0
			Audio.sfx("charge", -4.0)
			var n := 1 if phase == 1 else 5
			_tell(0.5 * spd, Color(1, 0.85, 0.5))
			if not await _wait(0.5 * spd, my_id): return
			Audio.sfx("lance")
			for i in n:
				var a := (i - (n - 1) / 2.0) * 0.22
				var pr: Projectile = world.spawn_projectile_local(global_position + Vector2(0, -12), dir.rotated(a) * 10.0, cfg.dmg * 0.8 * dmg_mult, "lance", "enemy", 1, 5.0, 2.2, 0)
				pr.delay = 0.12 * i
				pr.target_pos = tpos + Vector2.from_angle(dir.angle() + a) * 60.0
				pr.speed_after = 300.0
			if phase == 1:
				if not await _wait(0.35, my_id): return
				for i2 in 2:
					var lp2: Node2D = world.nearest_player(global_position)
					var tp: Vector2 = lp2.global_position if lp2 else tpos
					world.spawn_projectile_local(global_position + Vector2(0, -12), (tp - global_position).normalized() * 280.0, cfg.dmg * 0.8 * dmg_mult, "lance", "enemy", 1, 5.0, 2.0, 0)
					Audio.sfx("lance", -4.0)
					if not await _wait(0.3, my_id): return
			if not await _wait(0.6 * spd, my_id): return
		"nova":
			Fx.telegraph_circle(global_position, 58.0, 0.75 * spd, Color(1, 0.85, 0.5))
			_tell(0.75 * spd, Color(1, 0.9, 0.6))
			_blade_goal = -PI / 2.0
			if not await _wait(0.75 * spd, my_id): return
			Audio.sfx("nova")
			G.shockwave(global_position + Vector2(0, -8), 1.1, 0.4)
			Fx.ring(global_position + Vector2(0, -8), 8.0, 64.0, Color(1, 0.9, 0.6), 0.35, 6.0)
			Fx.burst(global_position + Vector2(0, -8), Color(1, 0.9, 0.6), 30, 140.0, 0.6, "fx_feather", 180.0, Vector2.UP, 1.0, false)
			_hit_circle(global_position, 58.0, cfg.dmg * 1.1, Vector2.ZERO)
			if phase >= 2:
				Haz.ring_wave(global_position, 30.0, 190.0, 1.1, cfg.dmg * 0.7 * dmg_mult, Color(1, 0.35, 0.4), 8.0, idx)
			if not await _wait(0.55 * spd, my_id): return
		"guard":
			# guardia: si le golpeas ahora, contraataca (lee el destello dorado y espera)
			_guard = 1.5 if phase == 1 else 1.1
			Audio.sfx("parry", -10.0)
			_blade_goal = -PI / 2.0 + 0.2 * facing
			var g := 0.0
			while g < 1.5 and _guard > 0.0:
				_flash(0.5 + 0.3 * sin(g * 20.0), Color(1, 0.9, 0.5))
				if randf() < 0.3:
					Fx.burst(global_position + Vector2(randf_range(-8, 8), -16), Color(1, 0.9, 0.6), 1, 20.0, 0.5, "fx_px", 40.0, Vector2.UP)
				if not await _wait(0.05, my_id):
					_guard = 0.0
					return
				g += 0.05
				_guard -= 0.05
			_guard = 0.0
			_flash(0.0, Color.WHITE)
			if not await _wait(0.2, my_id): return
		"sentence":
			# la Sentencia: salta hacia la cámara, llueven hojas y cae sobre ti
			_blade_goal = -PI / 2.0
			Audio.sfx("roar", -6.0)
			world.show_boss_line(["Yo también ejecuté a los que se negaban.", "I too executed those who refused."], "verdugo")
			var up := create_tween()
			up.tween_property(self, "_hover", 140.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if not await _wait(0.5, my_id): return
			var spots := []
			for i3 in 9:
				var lp3: Node2D = world.nearest_player(global_position)
				var c: Vector2 = lp3.global_position if lp3 else tpos
				spots.append(c + Vector2(rng.randf_range(-70, 70), rng.randf_range(-50, 50)) if i3 > 0 else c)
			for i4 in spots.size():
				Fx.telegraph_circle(spots[i4], 16.0, 0.7 + i4 * 0.07, Color(1, 0.3, 0.4))
				_blade_rain(spots[i4], 0.7 + i4 * 0.07)
			if not await _wait(1.3, my_id): return
			var lp4: Node2D = world.nearest_player(global_position)
			var land: Vector2 = lp4.global_position if lp4 else tpos
			Fx.telegraph_circle(land, 40.0, 0.6, Color(1, 0.2, 0.3))
			if multiplayer.is_server():
				position = land
				_net_pos = land
			if not await _wait(0.45, my_id): return
			var dn := create_tween()
			dn.tween_property(self, "_hover", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if not await _wait(0.15, my_id): return
			_slam_at(global_position, 40.0, cfg.dmg * 1.5)
			G.flash(Color(1, 0.2, 0.3, 0.25), 0.2)
			Haz.ring_wave(global_position, 20.0, 160.0, 0.9, cfg.dmg * 0.7 * dmg_mult, Color(1, 0.3, 0.4), 8.0, idx)
			if not await _wait(0.9, my_id): return
		"phase2":
			_transitioning = true
			_invuln = true
			Audio.sfx("feather_tear", 0.0, 0.0)
			Audio.sfx("roar", -4.0)
			G.shake(7.0, 1.0)
			G.flash(Color(1, 0.2, 0.25, 0.45), 0.5)
			G.chroma(2.0, 0.7)
			world.show_boss_line(["¿Recuerdas por qué empuñabas esto? Yo sí. Por eso me olvidaste.", "Do you remember why you wielded this? I do. That is why you forgot me."], "verdugo")
			# pierde las plumas: sus alas se vuelven negras, como las tuyas
			for k in 5:
				_feathers -= 1
				Fx.burst(global_position + Vector2(0, -16), Color(0.95, 0.92, 0.88), 10, 120.0, 1.2, "fx_feather", 180.0, Vector2.UP, 1.2, false, Vector2(0, 40))
				if not await _wait(0.18, my_id):
					_invuln = false
					return
			_look["wing"] = 5
			sprite.texture = Look.texture(_look, _feathers)
			_aura.color = Color(1, 0.15, 0.2)
			_aura.energy = 1.4
			phase = 2
			Fx.ring(global_position + Vector2(0, -12), 6.0, 120.0, Color(1, 0.25, 0.3), 0.8, 6.0)
			if not await _wait(0.9, my_id):
				_invuln = false
				return
			_invuln = false
			_transitioning = false
	_end_attack(my_id)

func _blade_rain(p: Vector2, dur: float) -> void:
	var f := Depth3D.Faller.new()
	f.tex = Fx.tex("weapon_verdugo")
	f.rot = PI / 2.0
	f.height = 160.0
	f.dur = dur
	f.linger = 0.4
	f.modulate = Color(1, 0.75, 0.8)
	f.position = p
	f.on_land = _blade_hit.bind(p)
	world.get_node("FX").add_child(f)

func _blade_hit(p: Vector2) -> void:
	Audio.sfx("hit_heavy", -8.0)
	Fx.ring(p, 3.0, 18.0, Color(1, 0.4, 0.45), 0.25, 3.0)
	Fx.burst(p, Color(1, 0.5, 0.5), 8, 70.0, 0.35)
	if state != "dead":
		_hit_circle(p, 16.0, cfg.dmg * 0.8, Vector2.ZERO)

# ====================================================================== animación
func _animate(delta: float) -> void:
	_t += delta
	super._animate(delta)
	if state == "dead":
		return
	# el salto de la Sentencia: sube hacia la cámara (más grande) y su sombra se encoge
	sprite.position.y = -_hover
	if _hover > 1.0:
		sprite.scale = Vector2.ONE * (1.0 + _hover / 260.0)
	shadow.scale = Vector2(body_radius / 6.0, body_radius / 14.0) * (1.0 - clampf(_hover / 200.0, 0.0, 0.6))
	blade_pivot.position = Vector2(0, -11 - _hover)
	if state != "busy":
		var lp: Node2D = world.nearest_player(global_position) if world else null
		if lp:
			_blade_goal = (lp.global_position - global_position).angle() + 0.9 * facing
	_blade_rot = lerp_angle(_blade_rot, _blade_goal, clampf(delta * 18.0, 0.0, 1.0))
	blade_pivot.rotation = _blade_rot
	blade.flip_v = absf(wrapf(_blade_rot, -PI, PI)) > PI / 2.0
	blade_pivot.z_index = -1 if sin(_blade_rot) < -0.3 else 1
	_aura.energy = (0.9 if phase == 1 else 1.4) + 0.2 * sin(_t * 4.0)

func die() -> void:
	super.die()
	var tw := create_tween()
	tw.tween_property(blade_pivot, "rotation", PI * 0.5, 0.5)
	tw.parallel().tween_property(_aura, "energy", 0.0, 1.2)

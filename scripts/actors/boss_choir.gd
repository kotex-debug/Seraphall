class_name BossChoir
extends Enemy
## EL CORO HUECO — jefe opcional (rango II). Tres cantores encapuchados que flotan en círculo y
## comparten una sola alma. Fase 1: Anillos del Coro, Armonía (haz entre cantores), Notas que persiguen.
## Fase 2 (50%): se FUNDEN en un gigante de tres rostros: Crescendo, Disonancia, Lamento en espiral.
## Fase 3 (20%, no en Peregrino): el gigante grita y se rompe de nuevo, todo más rápido.

var rig: Node2D
var singers: Array[Sprite2D] = []
var giant: Sprite2D
var _t := 0.0
var _orbit := 0.0
var _orbit_r := 34.0
var merged := false
var _last_attack := ""
var _invuln := false
var pose := "idle"
var _light: PointLight2D

func _ready() -> void:
	super._ready()
	sprite.visible = false
	body_radius = 42.0
	shadow.scale = Vector2(6.0, 1.6)
	shadow.modulate.a = 0.35
	rig = Node2D.new()
	rig.position = Vector2(0, -22)
	add_child(rig)
	for i in 3:
		var s := Sprite2D.new()
		s.texture = Fx.tex("boss_singer")
		s.region_enabled = true
		s.region_rect = Rect2(0, i * 36, 26, 36)
		s.material = _flash_mat
		rig.add_child(s)
		singers.append(s)
	giant = Sprite2D.new()
	giant.texture = Fx.tex("boss_choir_giant")
	giant.region_enabled = true
	giant.region_rect = Rect2(0, 0, 72, 92)
	giant.offset = Vector2(0, -24)
	giant.material = _flash_mat
	giant.visible = false
	rig.add_child(giant)
	_light = PointLight2D.new()
	_light.texture = Fx.tex("light")
	_light.color = Color(0.7, 0.5, 1.0)
	_light.texture_scale = 2.0
	_light.energy = 1.0
	_light.position = Vector2(0, -30)
	add_child(_light)

func singer_node(i: int) -> Node2D:
	return singers[i % 3]

func _animate(delta: float) -> void:
	_t += delta
	if state == "dead":
		return
	var spin := 0.9 if pose != "sing" else 2.2
	if phase >= 3:
		spin *= 1.6
	_orbit += delta * spin
	for i in singers.size():
		var s := singers[i]
		var a := _orbit + TAU * i / 3.0
		var target := Vector2(cos(a) * _orbit_r, sin(a) * _orbit_r * 0.55 + sin(_t * 3.0 + i) * 3.0)
		if pose == "merge":
			target = Vector2.ZERO
		s.position = s.position.lerp(target, clamp(delta * 8.0, 0.0, 1.0))
		s.z_index = 1 if sin(a) > 0 else -1
		var f := int(_t * 6.0 + i) % 4
		s.region_rect = Rect2(f * 26, i * 36, 26, 36)
		s.scale = Vector2(1.0, 1.0) * (1.0 + (0.12 * sin(_t * 12.0 + i) if pose == "sing" else 0.0))
	if merged:
		var gf := int(_t * 5.0) % 4
		giant.region_rect = Rect2(gf * 72, (1 if phase >= 3 else 0) * 92, 72, 92)
		giant.position.y = sin(_t * 2.0) * 3.0
		giant.scale = Vector2(1, 1) * (1.0 + (0.05 * sin(_t * 16.0) if pose == "sing" else 0.0))
	rig.scale.x = 1.0
	_light.energy = 1.0 + 0.3 * sin(_t * 4.0) + (0.6 if pose == "sing" else 0.0)
	if randf() < 0.25:
		var nc := Color(0.8, 0.6, 1.0) if phase < 3 else Color(1, 0.5, 0.6)
		Fx.burst(global_position + Vector2(randf_range(-40, 40), randf_range(-60, 0)), nc, 1, 15.0, 1.2, "proj_note" if randf() < 0.2 else "fx_px", 60.0, Vector2.UP, 0.6, false, Vector2(0, -15))
	var fl: float = _flash_mat.get_shader_parameter("flash")
	if fl > 0.0 and state != "busy":
		_flash_mat.set_shader_parameter("flash", max(0.0, fl - delta * 7.0))

func _chase(target: Node2D, delta: float) -> void:
	var to := target.global_position - global_position
	var d := to.length()
	var want := Vector2.ZERO
	if d > 130.0:
		want = to.normalized()
	elif d < 80.0:
		want = -to.normalized()
	else:
		want = to.normalized().orthogonal()
	velocity = velocity.lerp(want * cfg.speed * (0.55 if slow_t > 0.0 else 1.0), clamp(delta * 3.0, 0.0, 1.0))
	if cooldown <= 0.0:
		_trigger(_pick(), target.global_position)

func _pick() -> String:
	var pool := ["rings", "harmony", "notes"] if not merged else ["crescendo", "dissonance", "lament", "notes"]
	if phase >= 3:
		pool += ["harmony", "rings"]
	pool.erase(_last_attack)
	_last_attack = pool[randi() % pool.size()]
	return _last_attack

func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if _invuln:
		return {}
	return super.server_apply_damage(dmg, dir, poise_dmg * 0.7)

func perform(act: String, tpos: Vector2, seed: int) -> void:
	if state == "dead":
		return
	_attack_id += 1
	var my_id := _attack_id
	state = "busy"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var spd := 1.0 if phase == 1 else (0.85 if phase == 2 else 0.7)
	var dm := dmg_mult
	match act:
		"rings":
			pose = "sing"
			Audio.sfx("levelup", -10.0, 0.2)
			for i in 3:
				var s := singers[i]
				Fx.ring(s.global_position, 2.0, 18.0, Color(0.8, 0.6, 1.0), 0.4, 2.0)
				Haz.ring_wave(s.global_position, 8.0, 190.0, 1.6 * spd, cfg.dmg * 0.7 * dm, Color(0.75, 0.55, 1.0), 8.0, idx)
				Audio.sfx("enemy_shot", -6.0)
				if not await _wait(0.45 * spd, my_id): return
			if not await _wait(0.8, my_id): return
		"harmony":
			pose = "sing"
			Haz.link_beam(singers[0], singers[1], 2.6, cfg.dmg * 0.6 * dm, Color(0.8, 0.6, 1.0), idx)
			if phase >= 3 or world.diff().skulls >= 3:
				Haz.link_beam(singers[1], singers[2], 2.6, cfg.dmg * 0.6 * dm, Color(1.0, 0.5, 0.7), idx)
			_orbit_r = 64.0
			if not await _wait(2.8, my_id):
				_orbit_r = 34.0
				return
			_orbit_r = 34.0
			if not await _wait(0.4, my_id): return
		"notes":
			pose = "sing"
			var n := 3 if not merged else 6
			for i in n:
				var src: Vector2 = singers[i % 3].global_position if not merged else global_position + Vector2(0, -50)
				var a := rng.randf() * TAU
				var pr: Projectile = world.spawn_projectile_local(src, Vector2.from_angle(a) * 70.0, cfg.dmg * 0.6 * dm, "note", "enemy", 1, 5.0, 5.0, 0)
				pr.homing = 1.6
				Audio.sfx("enemy_shot", -8.0)
				if not await _wait(0.25, my_id): return
			if not await _wait(1.0 * spd, my_id): return
		"crescendo":
			pose = "sing"
			_tell(0.8, Color(0.8, 0.5, 1.0))
			Fx.ring(global_position + Vector2(0, -30), 60.0, 6.0, Color(0.8, 0.5, 1.0), 0.8, 3.0)
			if not await _wait(0.8 * spd, my_id): return
			Audio.sfx("roar", -2.0)
			G.shake(5.0, 0.4)
			G.shockwave(global_position, 1.6, 0.7)
			for k in 3:
				Haz.ring_wave(global_position, 10.0, 240.0, 1.5 * spd, cfg.dmg * 0.8 * dm, Color(0.8, 0.5, 1.0) if k % 2 == 0 else Color(1, 0.5, 0.7), 10.0, idx)
				if not await _wait(0.4 * spd, my_id): return
			if not await _wait(0.8, my_id): return
		"dissonance":
			pose = "sing"
			Audio.sfx("roar", -10.0)
			var count := 8 if phase < 3 else 12
			var spots := []
			for i in count:
				var p := tpos + Vector2(rng.randf_range(-110, 110), rng.randf_range(-80, 80))
				if i == 0:
					p = tpos
				spots.append(p)
				Fx.telegraph_circle(p, 22.0, 0.9 + i * 0.07, Color(0.8, 0.5, 1.0))
			if not await _wait(0.9, my_id): return
			for p2 in spots:
				Audio.sfx("hit", -10.0)
				Fx.ring(p2, 4.0, 26.0, Color(0.85, 0.6, 1.0), 0.3, 4.0)
				Fx.burst(p2, Color(0.85, 0.6, 1.0), 8, 80.0, 0.4)
				_hit_circle(p2, 22.0, cfg.dmg * 0.8, Vector2.ZERO)
				if not await _wait(0.07, my_id): return
			if not await _wait(0.6, my_id): return
		"lament":
			pose = "sing"
			var t2 := 0.0
			var base := rng.randf() * TAU
			while t2 < 2.4:
				for arm in 3:
					var a2 := base + arm * TAU / 3.0 - t2 * 1.8
					world.spawn_projectile_local(global_position + Vector2(0, -40), Vector2.from_angle(a2) * 95.0, cfg.dmg * 0.5 * dm, "note", "enemy", 1, 4.0, 3.5, 0)
				if not await _wait(0.16, my_id): return
				t2 += 0.16
			if not await _wait(0.6, my_id): return
		"merge":
			# fusión en el gigante de tres rostros
			_invuln = true
			pose = "merge"
			Audio.sfx("roar")
			world.show_boss_line(["...cantamos... juntas... una vez más...", "...we sing... together... once more..."])
			G.shake(4.0, 1.2)
			if not await _wait(1.0, my_id):
				_invuln = false
				return
			merged = true
			for s in singers:
				s.visible = false
			giant.visible = true
			giant.scale = Vector2(0.2, 0.2)
			create_tween().tween_property(giant, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			body_radius = 26.0
			G.flash(Color(0.85, 0.6, 1.0, 0.6), 0.5)
			G.shockwave(global_position, 2.2, 0.9)
			G.chroma(2.0, 0.7)
			Fx.burst(global_position + Vector2(0, -40), Color(0.85, 0.6, 1.0), 60, 220.0, 1.2, "fx_soft", 180.0, Vector2.UP, 0.6)
			phase = 2
			Audio.play_music("boss_choir", 0.5)
			if not await _wait(1.2, my_id):
				_invuln = false
				return
			_invuln = false
		"shatter":
			_invuln = true
			pose = "sing"
			Audio.sfx("roar")
			world.show_boss_line(["¡NO NOS SEPARARÉIS OTRA VEZ!", "YOU WILL NOT TEAR US APART AGAIN!"])
			G.flash(Color(1, 0.4, 0.5, 0.5), 0.5)
			G.shockwave(global_position, 2.0, 0.8)
			phase = 3
			_light.color = Color(1, 0.4, 0.5)
			Haz.ring_wave(global_position, 10.0, 260.0, 1.3, cfg.dmg * dm, Color(1, 0.5, 0.6), 12.0, idx)
			if not await _wait(1.4, my_id):
				_invuln = false
				return
			_invuln = false
	pose = "idle"
	_end_attack(my_id)

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	if not multiplayer.is_server() or _invuln:
		return
	if phase == 1 and hp < max_hp * 0.5 and not merged:
		state = "busy"
		_invuln = true
		world.bcast("enemy_action", [idx, "merge", global_position, 0])
	elif phase == 2 and hp < max_hp * 0.2 and (world.diff().phase3 or asc >= 1):
		state = "busy"
		_invuln = true
		world.bcast("enemy_action", [idx, "shatter", global_position, 0])

func reset_state() -> void:
	super.reset_state()
	merged = false
	_invuln = false
	pose = "idle"
	body_radius = 42.0
	if giant:
		giant.visible = false
		for s in singers:
			s.visible = true
		_light.color = Color(0.7, 0.5, 1.0)

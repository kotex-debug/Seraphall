class_name BossSeravel
extends Enemy
## SERAVEL, Guardiana de las Puertas — Arconte del Estrato I (rango III).
## Cuerpo articulado (alas, espada, aureola, ojos) con animación procedural.
## Fase 1: espadas orbitantes, tajo-dash, lluvia de espadas, Aureola Giratoria, Tormenta de Plumas.
## Fase 2 (50%): aureola carmesí, espiral bullet-hell, invocación, tajos dobles.
## Fase 3 (25%, no en Peregrino): JUICIO DEL NIMBO — asciende, cruces de luz y caída devastadora.

var rig: Node2D
var r_body: Sprite2D
var r_wl: Sprite2D
var r_wr: Sprite2D
var r_halo: Sprite2D
var r_sword: Sprite2D
var r_eyes: Sprite2D
var _halo_light: PointLight2D
var _float_t := 0.0
var _transitioning := false
var _last_attack := ""
var _invuln := false
var pose := "idle"
var _wing_base := 0.15
var _sword_rot := 2.8
var _rig_y := -44.0
var _kick := 0.0
var halo_back: HaloRing
var halo_front: HaloRing

const SC := 0.6

func _ready() -> void:
	super._ready()
	sprite.visible = false
	body_radius = 16.0
	shadow.scale = Vector2(4.0, 1.2)
	rig = Node2D.new()
	rig.position = Vector2(0, _rig_y)
	add_child(rig)
	r_wl = _part("res://assets/sprites/cinematic/seravel_wing.png", Vector2(-9, -32), false)
	r_wl.centered = false
	r_wl.offset = Vector2(-88, -28)
	r_wr = _part("res://assets/sprites/cinematic/seravel_wing.png", Vector2(9, -32), false)
	r_wr.centered = false
	r_wr.flip_h = true
	r_wr.offset = Vector2(-8, -28)
	r_body = _part("res://assets/sprites/cinematic/seravel_body.png", Vector2.ZERO, false)
	r_sword = _part("res://assets/sprites/cinematic/seravel_sword.png", Vector2(18, 2), false)
	r_sword.offset = Vector2(0, -36)
	r_eyes = _part("res://assets/sprites/cinematic/seravel_eyes.png", Vector2.ZERO, true)
	r_halo = _part("res://assets/sprites/cinematic/seravel_halo.png", Vector2(0, -61), true)
	r_halo.visible = false
	# aureola 3D: un anillo inclinado que gira; la mitad de atrás va detrás del cuerpo y la de delante, delante
	halo_back = HaloRing.new()
	halo_back.back = true
	halo_back.position = Vector2(0, -60)
	halo_back.z_index = -1
	rig.add_child(halo_back)
	rig.move_child(halo_back, 0)
	halo_front = HaloRing.new()
	halo_front.position = Vector2(0, -60)
	rig.add_child(halo_front)
	for s in [r_wl, r_wr, r_body, r_sword]:
		s.material = _flash_mat
	_halo_light = PointLight2D.new()
	_halo_light.texture = Fx.tex("light")
	_halo_light.texture_scale = 2.4
	_halo_light.energy = 1.1
	_halo_light.color = Color(1, 0.85, 0.5)
	_halo_light.position = Vector2(0, -90)
	add_child(_halo_light)

func _part(path: String, pos: Vector2, additive: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.position = pos
	s.scale = Vector2(SC, SC)
	if additive:
		s.material = Fx.add_material()
	rig.add_child(s)
	return s

# ====================================================================== animación procedural
func _animate(delta: float) -> void:
	_float_t += delta
	if state == "dead":
		return
	var t := _float_t
	var target_wing := 0.15
	var target_sword := 2.8
	var target_y := -44.0 + sin(t * 2.4) * 3.0
	match pose:
		"windup":
			target_wing = -0.35
			target_sword = -0.9
			target_y -= 6.0
		"slash":
			target_wing = 0.5
			target_sword = 2.2
		"dash":
			target_wing = 0.75
			target_sword = 1.4
		"cast":
			target_wing = -0.15
			target_sword = 3.0
			target_y -= 4.0
		"ascend":
			target_wing = -0.6
			target_y = -260.0
		"slam":
			target_wing = 0.9
			target_sword = 3.1
	if state == "stagger":
		target_wing = 0.95
		target_sword = 2.9
		target_y = -30.0
	var k: float = clamp(delta * (14.0 if pose == "slash" else 7.0), 0.0, 1.0)
	_wing_base = lerpf(_wing_base, target_wing, k)
	_sword_rot = lerp_angle(_sword_rot, target_sword, k)
	_rig_y = lerpf(_rig_y, target_y, clamp(delta * (3.0 if pose == "ascend" else 8.0), 0.0, 1.0))
	var flap := sin(t * (3.0 if phase == 1 else 4.5)) * 0.1
	r_wl.rotation = _wing_base + flap
	r_wr.rotation = -(_wing_base + flap)
	var ws := SC * (0.85 if pose == "dash" else 1.0)
	r_wl.scale = r_wl.scale.lerp(Vector2(ws, ws), k)
	r_wr.scale = r_wl.scale
	r_sword.rotation = _sword_rot
	rig.position.y = _rig_y
	# perspectiva: al elevarse se acerca a la cámara (más grande y desplazada hacia fuera de la pantalla)
	var up := clampf((-_rig_y - 44.0) / 216.0, 0.0, 1.0)
	var near := 1.0 + up * 0.45
	rig.scale = Vector2(float(facing) * (1.0 if pose != "slash" else 1.05), 1.0) * near
	_kick = lerpf(_kick, 0.0, clamp(delta * 12.0, 0.0, 1.0))
	Depth3D.lean_rig(rig, global_position, Depth3D.cam_center(self), -_rig_y)
	rig.position.x += _kick
	shadow.scale = Vector2(4.0, 1.2) * (1.0 - up * 0.6)
	for hr in [halo_back, halo_front]:
		hr.t = t
		hr.phase = phase
		hr.queue_redraw()
	r_halo.rotation = sin(t * 0.8) * 0.06
	r_halo.scale = Vector2(SC, SC) * (1.0 + 0.06 * sin(t * 3.0))
	r_eyes.modulate.a = 0.4 + 0.3 * sin(t * 5.0) + (0.4 if phase >= 2 else 0.0)
	var tint := Color.WHITE
	if phase == 2:
		tint = Color(1.0, 0.82, 0.86)
	elif phase >= 3:
		tint = Color(1.0, 0.7, 0.6)
	if slow_t > 0.0:
		tint = tint * Color(0.75, 0.9, 1.3)
	for s in [r_wl, r_wr, r_body]:
		s.modulate = tint
	r_halo.modulate = Color(1, 0.85, 0.4) if phase == 1 else (Color(1, 0.25, 0.3) if phase == 2 else Color(1, 1, 1))
	shadow.modulate.a = 0.55 if pose != "ascend" else 0.2
	if randf() < 0.3 and visible:
		var c := Color(1, 0.9, 0.6) if phase == 1 else Color(1, 0.35, 0.35)
		Fx.burst(global_position + Vector2(randf_range(-30, 30), _rig_y + randf_range(-30, 30)), c, 1, 20.0, 1.0, "fx_feather" if randf() < 0.35 else "fx_px", 60.0, Vector2.DOWN, 1.0, false, Vector2(0, 25))
	var fl: float = _flash_mat.get_shader_parameter("flash")
	if fl > 0.0 and state != "busy":
		_flash_mat.set_shader_parameter("flash", max(0.0, fl - delta * 7.0))

func _afterimage_rig(col: Color) -> void:
	for s in [r_body, r_wl, r_wr]:
		var a := Sprite2D.new()
		a.texture = s.texture
		a.centered = s.centered
		a.offset = s.offset
		a.flip_h = s.flip_h
		a.global_transform = s.global_transform
		a.modulate = col
		a.material = Fx.add_material()
		world.get_node("FX").add_child(a)
		var tw := a.create_tween()
		tw.tween_property(a, "modulate:a", 0.0, 0.3)
		tw.tween_callback(a.queue_free)

# ====================================================================== IA
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
	velocity = velocity.lerp(want * cfg.speed * (0.6 if slow_t > 0.0 else 1.0), clamp(delta * 4.0, 0.0, 1.0))
	if cooldown <= 0.0:
		_trigger(_pick(d), target.global_position)

func _pick(d: float) -> String:
	var pool: Array
	match phase:
		1:
			pool = ["orbit", "dash", "rain", "halo_beam", "wing_storm"]
		2:
			pool = ["spiral", "dash", "rain", "orbit", "double_dash", "summon", "halo_beam", "wing_storm"]
		_:
			pool = ["judgment", "double_dash", "spiral", "halo_beam", "rain", "wing_storm"]
	if world.diff().skulls >= 3 or asc >= 2:
		pool.append("double_dash")
	if d < 50.0:
		return "dash" if phase == 1 else "double_dash"
	pool.erase(_last_attack)
	var pick: String = pool[randi() % pool.size()]
	if phase >= 3 and _last_attack != "judgment" and randf() < 0.35:
		pick = "judgment"
	_last_attack = pick
	return pick

func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if _invuln:
		return {}
	return super.server_apply_damage(dmg, dir, poise_dmg)

# ====================================================================== ataques
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
	var spd := 1.0 if phase == 1 else (0.8 if phase == 2 else 0.7)
	var dm := dmg_mult
	match act:
		"orbit":
			pose = "cast"
			Audio.sfx("lance", -2.0)
			var n := 6 if phase == 1 else 9
			for i in n:
				var a := TAU * i / n
				var p := global_position + Vector2(0, -40) + Vector2.from_angle(a) * 40.0
				var pr: Projectile = world.spawn_projectile_local(p, Vector2.from_angle(a) * 0.01, cfg.dmg * 0.8 * dm, "sword", "enemy", 1, 5.0, 4.0, 0)
				pr.delay = 0.7 * spd + i * 0.09
				pr.target_pos = tpos + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
				pr.speed_after = 260.0
			if not await _wait(1.3 * spd, my_id): return
		"dash", "double_dash":
			var times := 2 if act == "double_dash" else 1
			for rep in times:
				pose = "windup"
				var length := 190.0
				var dd := dir
				if rep == 1:
					var lp: Node2D = world.nearest_player(global_position)
					if lp:
						dd = (lp.global_position - global_position).normalized()
				Fx.telegraph_line(global_position, dd.angle(), length, 26.0, 0.5 * spd, Color(1, 0.3, 0.4))
				_tell(0.5 * spd, Color(1, 0.4, 0.5))
				if not await _wait(0.5 * spd, my_id): return
				pose = "dash"
				Audio.sfx("swing_heavy")
				var t := 0.0
				var hit := false
				while t < 0.24:
					if multiplayer.is_server():
						velocity = dd * (length / 0.24)
						lunge = velocity
					_afterimage_rig(Color(1, 0.5, 0.6, 0.5) if phase == 1 else Color(1, 0.2, 0.3, 0.55))
					if not hit:
						hit = _hit_circle(global_position, 22.0, cfg.dmg * 1.1, dd)
					if not await _wait(0.016, my_id): return
					t += 0.016
				if multiplayer.is_server():
					velocity = Vector2.ZERO
					lunge = Vector2.ZERO
				pose = "slash"
				Fx.slash(global_position + Vector2(0, -30), dd.angle(), 44.0, 210.0, Color(1, 0.5, 0.6, 0.9), 16.0, 0.3)
				_hit_arc(global_position + Vector2(0, -16), dd.angle(), 48.0, 210.0, cfg.dmg)
				if phase >= 2:
					for i in 8:
						var a2 := TAU * i / 8.0 + rep * 0.4
						world.spawn_projectile_local(global_position + Vector2(0, -24), Vector2.from_angle(a2) * 120.0, cfg.dmg * 0.6 * dm, "red", "enemy", 1, 5.0, 2.5, 0)
				if not await _wait(0.35 * spd, my_id): return
			if not await _wait(0.35 * spd, my_id): return
		"rain":
			pose = "cast"
			Audio.sfx("roar", -10.0)
			var count := 7 if phase == 1 else 12
			var spots := []
			for i in count:
				var p2 := tpos + Vector2(rng.randf_range(-80, 80), rng.randf_range(-60, 60))
				if i == 0:
					p2 = tpos
				spots.append(p2)
				Fx.telegraph_circle(p2, 18.0, 0.9 * spd + i * 0.06, Color(1, 0.85, 0.4))
			if not await _wait(0.9 * spd, my_id): return
			for i in count:
				_sword_fall(spots[i])
				if not await _wait(0.06, my_id): return
			if not await _wait(0.5 * spd, my_id): return
		"halo_beam":
			# la aureola se desprende y gira lanzando rayos
			pose = "cast"
			Audio.sfx("levelup", -6.0)
			var tw := create_tween()
			tw.tween_property(r_halo, "position:y", -10.0, 0.4).set_trans(Tween.TRANS_BACK)
			var beams := 2 if phase == 1 else (3 if phase == 2 else 4)
			Haz.beams(self, beams, 230.0, 1.1 * (1.0 if rng.randf() < 0.5 else -1.0) / spd, 0.9, 2.8, cfg.dmg * 0.7 * dm, Color(1, 0.85, 0.4) if phase == 1 else Color(1, 0.35, 0.35), rng.randf() * TAU, Vector2(0, -20), idx)
			if not await _wait(3.8, my_id): return
			var tw2 := create_tween()
			tw2.tween_property(r_halo, "position:y", -61.0, 0.4)
			if not await _wait(0.3, my_id): return
		"wing_storm":
			pose = "windup"
			_tell(0.6, Color(1, 1, 1))
			if not await _wait(0.6 * spd, my_id): return
			pose = "slash"
			Audio.sfx("dash", 0.0)
			G.shake(2.0, 0.3)
			var waves := 2 if phase == 1 else 3
			for wv in waves:
				for i in 9:
					var a3 := dir.angle() + (i - 4) * 0.13 + (wv % 2) * 0.065
					world.spawn_projectile_local(global_position + Vector2(0, -36), Vector2.from_angle(a3) * (190.0 + wv * 30.0), cfg.dmg * 0.55 * dm, "feather", "enemy", 1, 4.0, 2.2, 0)
				Fx.burst(global_position + Vector2(0, -36), Color.WHITE, 12, 120.0, 0.6, "fx_feather", 40.0, dir, 1.2, false)
				if not await _wait(0.28, my_id): return
			if not await _wait(0.5 * spd, my_id): return
		"spiral":
			pose = "cast"
			Fx.ring(global_position + Vector2(0, -30), 40.0, 4.0, Color(1, 0.3, 0.3), 0.6, 3.0)
			_tell(0.6, Color(1, 0.3, 0.3))
			if not await _wait(0.6, my_id): return
			var t2 := 0.0
			var base := rng.randf() * TAU
			var arms := 4 if phase == 2 else 5
			while t2 < 2.6:
				for arm in arms:
					var a4 := base + arm * TAU / arms + t2 * 2.1
					world.spawn_projectile_local(global_position + Vector2(0, -30), Vector2.from_angle(a4) * 105.0, cfg.dmg * 0.55 * dm, "red", "enemy", 1, 4.0, 3.5, 0)
				Audio.sfx("enemy_shot", -12.0)
				if not await _wait(0.13, my_id): return
				t2 += 0.13
			if not await _wait(0.6, my_id): return
		"summon":
			pose = "cast"
			Audio.sfx("roar", -4.0)
			Fx.light_flash(global_position, Color(1, 0.3, 0.3), 2.0, 2.0, 0.6)
			if multiplayer.is_server():
				for i in 2:
					var p3 := global_position + Vector2.from_angle(rng.randf() * TAU) * 60.0
					world.spawn_extra_enemy("hueco", p3)
			if not await _wait(1.0, my_id): return
		"judgment":
			# JUICIO DEL NIMBO
			_invuln = true
			pose = "ascend"
			Audio.sfx("roar", 0.0)
			world.show_boss_line(["¡Que el Nimbo te juzgue!", "Let the Nimbus judge you!"])
			G.shake(3.0, 0.6)
			if not await _wait(0.9, my_id):
				_invuln = false
				return
			visible = true
			var arena: Vector2 = world.tile_pos(49, 14)
			for wave in 3:
				var lp2: Node2D = world.nearest_player(arena)
				var c: Vector2 = lp2.global_position if lp2 else arena
				c += Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))
				var rot := rng.randf() * PI
				for k in 2:
					var d2 := Vector2.from_angle(rot + k * PI / 2.0) * 240.0
					Haz.line_blast(c - d2, c + d2, 20.0, 0.9, cfg.dmg * 0.9 * dm, Color(1, 0.85, 0.45), idx)
				if not await _wait(0.75, my_id):
					_invuln = false
					return
			var lp3: Node2D = world.nearest_player(arena)
			var slam_at: Vector2 = lp3.global_position if lp3 else arena
			Fx.telegraph_circle(slam_at, 56.0, 1.0, Color(1, 0.9, 0.5))
			if multiplayer.is_server():
				position = slam_at + Vector2(0, -2)
				_net_pos = position
			if not await _wait(1.0, my_id):
				_invuln = false
				return
			pose = "slam"
			_rig_y = -44.0
			_invuln = false
			Audio.sfx("slam")
			Audio.sfx("nova")
			G.shake(9.0, 0.6)
			G.flash(Color(1, 0.95, 0.75, 0.5), 0.4)
			G.shockwave(global_position, 2.2, 0.8)
			G.chroma(2.0, 0.5)
			Fx.impact(global_position, Color(1, 0.9, 0.5), 50.0, 10)
			Fx.scorch(global_position, 50.0)
			world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position, 22, Color(0.55, 0.45, 0.35), 1.5))
			Fx.burst(global_position, Color(1, 0.85, 0.5), 60, 220.0, 1.0, "fx_feather", 180.0, Vector2.UP, 1.5, false, Vector2(0, 40))
			_hit_circle(global_position, 56.0, cfg.dmg * 1.6, Vector2.ZERO)
			Haz.ring_wave(global_position, 20.0, 230.0, 1.3, cfg.dmg * 0.8 * dm, Color(1, 0.8, 0.4), 10.0, idx)
			if not await _wait(1.4, my_id): return
		"phase2", "phase3":
			_transitioning = true
			_invuln = true
			pose = "windup"
			Audio.sfx("roar")
			if act == "phase2":
				Audio.play_music("boss_seravel3", 0.5)
			G.shake(8.0, 1.2)
			G.flash(Color(1, 0.2, 0.2, 0.5) if act == "phase2" else Color(1, 1, 1, 0.6), 0.5)
			G.shockwave(global_position + Vector2(0, -20), 2.2, 0.9)
			G.chroma(2.0, 0.8)
			Fx.ring(global_position + Vector2(0, -20), 10.0, 160.0, Color(1, 0.3, 0.3) if act == "phase2" else Color(1, 0.95, 0.7), 0.9, 8.0)
			Fx.burst(global_position + Vector2(0, -30), Color(1, 0.3, 0.3) if act == "phase2" else Color(1, 1, 0.9), 70, 220.0, 1.4, "fx_feather", 180.0, Vector2.UP, 1.6, false, Vector2(0, 40))
			_hit_circle(global_position, 60.0, 10.0, Vector2.ZERO)
			if act == "phase2":
				world.show_boss_line(["¡Basta! ¡Mira lo que el Arquitecto hizo de nosotros!", "Enough! Look what the Architect made of us!"])
				phase = 2
				_halo_light.color = Color(1, 0.3, 0.3)
				_halo_light.energy = 1.6
			else:
				world.show_boss_line(["Si he de caer... caerás conmigo hasta el fondo.", "If I must fall... you will fall with me to the bottom."])
				phase = 3
				_halo_light.color = Color(1, 0.95, 0.8)
				_halo_light.energy = 2.0
				world.arena_fx("seravel_p3")
			if not await _wait(1.6, my_id):
				_invuln = false
				return
			_invuln = false
			_transitioning = false
	pose = "idle"
	_end_attack(my_id)

func _sword_fall(p: Vector2) -> void:
	# espada de luz que cae del cielo en perspectiva (empieza enorme, cerca de la cámara)
	var f := Depth3D.Faller.new()
	f.tex = Fx.tex("proj_sword")
	f.rot = PI / 2.0
	f.height = 150.0
	f.dur = 0.2
	f.linger = 0.3
	f.additive = true
	f.position = p
	f.on_land = _sword_impact.bind(p)
	world.get_node("FX").add_child(f)

func _sword_impact(p: Vector2) -> void:
	Audio.sfx("hit_heavy", -6.0)
	Fx.ring(p, 4.0, 22.0, Color(1, 0.85, 0.4), 0.3, 3.0)
	Fx.burst(p, Color(1, 0.85, 0.5), 8, 80.0, 0.4)
	G.shake(1.5, 0.1)
	_hit_circle(p, 18.0, cfg.dmg * 0.9, Vector2.ZERO)

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	_kick = dir.x * 3.0
	if not multiplayer.is_server() or _transitioning:
		return
	if phase == 1 and hp < max_hp * 0.5:
		_transitioning = true
		state = "busy"
		world.bcast("enemy_action", [idx, "phase2", global_position, 0])
	elif phase == 2 and hp < max_hp * 0.25 and (world.diff().phase3 or asc >= 1):
		_transitioning = true
		state = "busy"
		world.bcast("enemy_action", [idx, "phase3", global_position, 0])

func die() -> void:
	super.die()
	if rig:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(r_wl, "rotation", 1.2, 0.8)
		tw.tween_property(r_wr, "rotation", -1.2, 0.8)
		tw.tween_property(rig, "position:y", -10.0, 0.8)
		tw.tween_property(r_halo, "modulate:a", 0.0, 0.6)

func reset_state() -> void:
	super.reset_state()
	_transitioning = false
	_invuln = false
	_last_attack = ""
	pose = "idle"
	if _halo_light:
		_halo_light.color = Color(1, 0.85, 0.5)
		_halo_light.energy = 1.1
	if rig:
		rig.visible = true
		r_halo.modulate.a = 1.0


class HaloRing extends Node2D:
	## Aureola de Seravel como anillo en 3D: elipse inclinada con runas que giran a su alrededor.
	## Se dibuja en dos mitades (atrás / delante) para que el cuerpo quede "dentro" del anillo.
	var back := false
	var t := 0.0
	var phase := 1
	func _draw() -> void:
		var col := Color(1, 0.85, 0.4) if phase == 1 else (Color(1, 0.25, 0.3) if phase == 2 else Color(1, 0.98, 0.9))
		var rx := 22.0
		var ry := 6.0 + sin(t * 0.9) * 1.5
		var tilt := sin(t * 0.7) * 0.12
		var n := 28
		var a0 := PI if back else 0.0
		var pts := PackedVector2Array()
		for i in n + 1:
			var a := a0 + PI * i / n
			pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(tilt))
		var k := 0.55 if back else 1.0
		draw_polyline(pts, Color(col.darkened(0.5), 0.6 * k), 4.0)
		draw_polyline(pts, Color(col, 0.9 * k), 2.0)
		draw_polyline(pts, Color(1, 1, 0.95, 0.7 * k), 1.0)
		# runas que recorren el anillo (solo las de esta mitad)
		for j in 8:
			var a2 := fmod(t * 1.4 + TAU * j / 8.0, TAU)
			var front := sin(a2) > 0.0
			if front == back:
				continue
			var rp := Vector2(cos(a2) * rx, sin(a2) * ry).rotated(tilt)
			var sz := 1.0 + (sin(a2) * 0.8 if not back else 0.0)
			draw_rect(Rect2(rp - Vector2(sz, sz), Vector2(sz * 2.0, sz * 2.0)), Color(1, 1, 0.9, k))

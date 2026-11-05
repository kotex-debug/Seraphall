class_name BossAzrahel
extends BossSeravel
## AZRAHEL, REY DEL ABISMO — Arconte del Estrato IV y jefe final del juego base (3 fases).
## El primer serafín que se negó, sentado en el Trono Vacío para que todos lo vieran y nadie lo escuchara.
## Hereda el repertorio de Seravel (es lo que ella aprendió de él) en negro y violeta, y añade:
## Eclipse (cuatro rayos que giran), Lluvia del Abismo (orbes que caen), Sombras (tus caídas, contra ti)
## y en la fase III, el Abismo: la sala se oscurece y el trono escupe ondas mientras él vuela sobre ti.

const ARENA_C := Vector2(336 * 16 + 8, 11 * 16 + 8)

func _ready() -> void:
	super._ready()
	r_body.texture = load("res://assets/sprites/cinematic/azrahel_body.png")
	r_wl.texture = load("res://assets/sprites/cinematic/azrahel_wing.png")
	r_wr.texture = r_wl.texture
	r_sword.texture = load("res://assets/sprites/cinematic/azrahel_sword.png")
	r_eyes.texture = load("res://assets/sprites/cinematic/azrahel_eyes.png")
	r_halo.texture = load("res://assets/sprites/cinematic/azrahel_halo.png")
	halo_back.modulate = Color(0.7, 0.45, 1.3)
	halo_front.modulate = Color(0.7, 0.45, 1.3)
	_halo_light.color = Color(0.7, 0.45, 1.0)

func reset_state() -> void:
	super.reset_state()
	if _halo_light:
		_halo_light.color = Color(0.7, 0.45, 1.0)
		_halo_light.energy = 1.3

func _pick(d: float) -> String:
	var pool: Array
	match phase:
		1:
			pool = ["orbit", "dash", "rain", "halo_beam", "wing_storm", "void_rain"]
		2:
			pool = ["spiral", "double_dash", "rain", "eclipse", "shadows", "halo_beam", "wing_storm", "void_rain"]
		_:
			pool = ["eclipse", "double_dash", "spiral", "abyss_wave", "void_rain", "shadows", "halo_beam"]
	if d < 50.0:
		return "dash" if phase == 1 else "double_dash"
	pool.erase(_last_attack)
	var pick: String = pool[randi() % pool.size()]
	_last_attack = pick
	return pick

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	super.on_hurt(new_hp, dmg, dir, crit, broke)
	if not multiplayer.is_server() or _transitioning:
		return
	# la fase III del Rey llega siempre, en cualquier dificultad
	if phase == 2 and hp < max_hp * 0.3:
		_transitioning = true
		state = "busy"
		world.bcast("enemy_action", [idx, "phase3", global_position, 0])

func perform(act: String, tpos: Vector2, seed: int) -> void:
	if state == "dead":
		return
	if not act in ["phase2", "phase3", "eclipse", "void_rain", "shadows", "abyss_wave"]:
		await super.perform(act, tpos, seed)
		return
	_attack_id += 1
	var my_id := _attack_id
	state = "busy"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var dm := dmg_mult
	match act:
		"eclipse":
			pose = "cast"
			Audio.sfx("charge", 0.0)
			Fx.ring(global_position + Vector2(0, -30), 60.0, 6.0, Color(0.7, 0.4, 1.0), 0.7, 3.0)
			Haz.beams(self, 4, 280.0, (0.9 if rng.randf() < 0.5 else -0.9), 1.0, 3.0, cfg.dmg * 0.6 * dm, Color(0.7, 0.45, 1.0), rng.randf() * TAU, Vector2(0, -24), idx)
			if not await _wait(4.2, my_id): return
		"void_rain":
			pose = "cast"
			Audio.sfx("roar", -8.0)
			var n := 10 if phase == 1 else 16
			for i in n:
				var lp: Node2D = world.nearest_player(global_position)
				var c: Vector2 = lp.global_position if lp and i % 3 == 0 else ARENA_C + Vector2(rng.randf_range(-140, 140), rng.randf_range(-120, 120))
				var d := 0.8 + i * 0.07
				Fx.telegraph_circle(c, 18.0, d, Color(0.7, 0.4, 1.0))
				_void_orb(c, d)
			if not await _wait(1.2 + n * 0.07, my_id): return
		"shadows":
			# tus caídas se alzan contra ti: dos Sombras con tu aspecto
			pose = "cast"
			Audio.sfx("shadow_rise", 0.0)
			world.show_boss_line(["Cada vez que caíste, yo me quedé con un poco de ti.", "Every time you fell, I kept a little of you."], "azrahel")
			if multiplayer.is_server():
				for i in 2:
					var p := ARENA_C + Vector2.from_angle(rng.randf() * TAU) * 90.0
					world.spawn_extra_enemy("sombra", p)
			if not await _wait(1.4, my_id): return
		"abyss_wave":
			pose = "ascend"
			Audio.sfx("nova", 0.0)
			G.shake(4.0, 1.0)
			for k in 3:
				Haz.ring_wave(ARENA_C, 20.0, 260.0, 1.3, cfg.dmg * 0.7 * dm, Color(0.65, 0.35, 1.0), 10.0, idx)
				if not await _wait(0.65, my_id): return
			pose = "idle"
			if not await _wait(0.6, my_id): return
		"phase2", "phase3":
			world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position, 20, Color(0.4, 0.3, 0.5), 1.5))
			_transitioning = true
			_invuln = true
			pose = "windup"
			Audio.sfx("roar")
			G.shake(9.0, 1.4)
			G.flash(Color(0.6, 0.3, 1.0, 0.55), 0.6)
			G.shockwave(global_position + Vector2(0, -20), 2.4, 1.0)
			G.chroma(2.2, 0.9)
			Fx.ring(global_position + Vector2(0, -20), 10.0, 180.0, Color(0.7, 0.4, 1.0), 1.0, 8.0)
			Fx.burst(global_position + Vector2(0, -30), Color(0.6, 0.35, 1.0), 80, 220.0, 1.4, "fx_feather", 180.0, Vector2.UP, 1.6, false, Vector2(0, 40))
			_hit_circle(global_position, 60.0, 10.0, Vector2.ZERO)
			if act == "phase2":
				world.show_boss_line(Strata.ARCHONS["azrahel"]["phase"], "azrahel")
				phase = 2
				_halo_light.energy = 1.8
			else:
				world.show_boss_line(Strata.ARCHONS["azrahel"]["phase3"], "azrahel")
				phase = 3
				_halo_light.color = Color(0.85, 0.6, 1.0)
				_halo_light.energy = 2.4
				world.arena_fx("azrahel_p3")
				Audio.play_music("boss_azrahel", 0.5)
			if not await _wait(1.6, my_id):
				_invuln = false
				return
			_invuln = false
			_transitioning = false
	pose = "idle"
	_end_attack(my_id)

func _void_orb(p: Vector2, dur: float) -> void:
	var f := Depth3D.Faller.new()
	f.tex = Fx.tex("proj_orb")
	f.height = 190.0
	f.dur = dur
	f.linger = 0.05
	f.additive = true
	f.modulate = Color(0.7, 0.4, 1.0)
	f.position = p
	f.on_land = _void_hit.bind(p)
	world.get_node("FX").add_child(f)

func _void_hit(p: Vector2) -> void:
	Audio.sfx("hit", -12.0, 0.3)
	Fx.ring(p, 4.0, 22.0, Color(0.7, 0.4, 1.0), 0.35, 3.0)
	Fx.burst(p, Color(0.75, 0.5, 1.0), 12, 70.0, 0.5, "fx_px", 180.0, Vector2.UP, 1.0, true, Vector2(0, 120))
	if state != "dead":
		_hit_circle(p, 16.0, cfg.dmg * 0.75, Vector2.ZERO)

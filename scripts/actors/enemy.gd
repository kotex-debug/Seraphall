class_name Enemy
extends CharacterBody2D
## Enemigo genérico. La IA corre en el anfitrión; los ataques (perform) se reproducen en todos
## los clientes y cada cliente comprueba los golpes solo contra su propio jugador.

const TYPES := {
	"hueco": {"sheet": "enemy_hueco", "fw": 22, "fh": 24, "hp": 48.0, "speed": 64.0, "radius": 7.0, "dmg": 14.0, "poise": 32.0,
		"ecos": 28, "aggro": 150.0, "range": 30.0, "cd": 1.1, "off": -10.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"acolito": {"sheet": "enemy_acolito", "fw": 22, "fh": 26, "hp": 36.0, "speed": 52.0, "radius": 7.0, "dmg": 12.0, "poise": 14.0,
		"ecos": 38, "aggro": 190.0, "range": 160.0, "cd": 2.0, "off": -12.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [0, 4, 7.0], "attack": [1, 3, 6.0], "dead": [2, 1]}},
	"bestia": {"sheet": "enemy_bestia", "fw": 32, "fh": 22, "hp": 78.0, "speed": 78.0, "radius": 10.0, "dmg": 20.0, "poise": 36.0,
		"ecos": 48, "aggro": 170.0, "range": 140.0, "cd": 2.2, "off": -9.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 10.0], "attack": [2, 2, 10.0], "dead": [3, 1]}},
	"carcelero": {"sheet": "enemy_carcelero", "fw": 40, "fh": 40, "hp": 680.0, "speed": 46.0, "radius": 14.0, "dmg": 28.0, "poise": 130.0,
		"ecos": 650, "aggro": 170.0, "range": 70.0, "cd": 1.4, "off": -18.0, "boss": true, "title": "boss_carcelero",
		"anims": {"idle": [0, 4, 4.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"seravel": {"sheet": "boss_seravel", "fw": 52, "fh": 56, "hp": 1500.0, "speed": 70.0, "radius": 13.0, "dmg": 24.0, "poise": 200.0,
		"ecos": 3000, "aggro": 400.0, "range": 200.0, "cd": 1.2, "off": -26.0, "boss": true, "title": "boss_seravel",
		"anims": {"idle": [0, 6, 7.0], "walk": [0, 6, 9.0], "attack": [1, 3, 8.0], "idle2": [2, 6, 9.0], "attack2": [3, 3, 9.0], "dead": [4, 0]}},
}

var idx := -1
var type := "hueco"
var cfg: Dictionary
var world: Node
var spawn_pos := Vector2.ZERO
var hp := 10.0
var max_hp := 10.0
var poise := 0.0
var max_poise := 10.0
var body_radius := 7.0
var state := "idle"   # idle | chase | busy | stagger | dead
var anim := "idle"
var facing := 1
var cooldown := 0.0
var stagger_t := 0.0
var last_hit_t := 0.0
var phase := 1
var is_boss := false
var active := true    # los jefes se activan con su escena
var lunge := Vector2.ZERO
var _attack_id := 0
var _net_pos := Vector2.ZERO
var _frame := 0.0
var sprite: Sprite2D
var shadow: Sprite2D
var _flash_mat: ShaderMaterial
var _hp_bar: Node2D

func setup(p_idx: int, p_type: String, pos: Vector2, p_world: Node) -> void:
	idx = p_idx
	type = p_type
	cfg = TYPES[type]
	world = p_world
	spawn_pos = pos
	position = pos
	_net_pos = pos
	name = "E%d" % idx
	is_boss = cfg.get("boss", false)
	active = not is_boss

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	body_radius = cfg.radius
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = body_radius * 0.7
	cs.shape = c
	add_child(cs)
	shadow = Sprite2D.new()
	shadow.texture = Fx.tex("fx_soft")
	shadow.modulate = Color(0, 0, 0, 0.55)
	shadow.scale = Vector2(body_radius / 6.0, body_radius / 14.0)
	shadow.z_index = -1
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = Fx.tex(cfg.sheet)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, cfg.fw, cfg.fh)
	sprite.offset = Vector2(0, cfg.off)
	_flash_mat = Fx.flash_material()
	sprite.material = _flash_mat
	add_child(sprite)
	if not is_boss:
		var el := PointLight2D.new()
		el.texture = Fx.tex("light")
		el.color = Color(1, 0.45, 0.3) if type != "acolito" else Color(0.7, 0.45, 1)
		el.texture_scale = 0.5
		el.energy = 0.5
		el.position = Vector2(0, cfg.off)
		add_child(el)
		_hp_bar = HpBar.new()
		_hp_bar.position = Vector2(0, cfg.off * 2 - 6)
		_hp_bar.visible = false
		add_child(_hp_bar)
	reset_state()

func reset_state() -> void:
	max_hp = cfg.hp * (1.35 if Net.is_online() else 1.0)
	hp = max_hp
	max_poise = cfg.poise
	poise = 0.0
	state = "idle"
	phase = 1
	position = spawn_pos
	_net_pos = spawn_pos
	visible = true
	sprite.rotation = 0.0
	_flash_mat.set_shader_parameter("dissolve", 0.0)
	_attack_id += 1
	if _hp_bar:
		_hp_bar.visible = false
	set_physics_process(true)

func is_alive() -> bool:
	return state != "dead"

func is_staggered() -> bool:
	return state == "stagger"

# ====================================================================== bucle
func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	if multiplayer.is_server():
		_server_tick(delta)
	else:
		position = position.lerp(_net_pos, clamp(delta * 12.0, 0.0, 1.0))
	_animate(delta)

func _server_tick(delta: float) -> void:
	cooldown -= delta
	last_hit_t += delta
	if last_hit_t > 2.0 and poise > 0.0:
		poise = max(0.0, poise - max_poise * 0.25 * delta)
	var target: Node2D = world.nearest_player(global_position)
	match state:
		"idle":
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			if active and target and target.global_position.distance_to(global_position) < cfg.aggro:
				state = "chase"
				if not is_boss:
					world.bcast("enemy_alert", [idx])
		"chase":
			if target == null or not active:
				state = "idle"
			else:
				_chase(target, delta)
		"busy":
			velocity = velocity.lerp(lunge, 0.35)
			lunge = lunge.lerp(Vector2.ZERO, clamp(delta * 6.0, 0.0, 1.0))
		"stagger":
			stagger_t -= delta
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			if stagger_t <= 0.0:
				state = "chase"
	move_and_slide()

func _chase(target: Node2D, delta: float) -> void:
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := Vector2.ZERO
	match type:
		"acolito":
			if d < 80.0:
				want = -to.normalized()
			elif d > 130.0:
				want = to.normalized()
			else:
				want = to.normalized().orthogonal() * (1.0 if (idx % 2) == 0 else -1.0) * 0.6
			if cooldown <= 0.0 and d < cfg.range:
				var act := "blink" if d < 55.0 and randf() < 0.6 else "fan"
				_trigger(act, target.global_position)
				return
		_:
			if d > cfg.range * 0.8:
				want = to.normalized()
			if cooldown <= 0.0 and d < cfg.range:
				_trigger(_choose_attack(d), target.global_position)
				return
	# separación entre enemigos
	for e in world.enemies_alive():
		if e != self and e.global_position.distance_to(global_position) < body_radius * 2.2:
			want += (global_position - e.global_position).normalized() * 0.6
	velocity = velocity.lerp(want.limit_length(1.0) * cfg.speed, clamp(delta * 6.0, 0.0, 1.0))

func _choose_attack(d: float) -> String:
	match type:
		"hueco":
			return "slash"
		"bestia":
			return "charge" if d > 40.0 else "bite"
		"carcelero":
			if phase == 2 and randf() < 0.4:
				return "triple"
			return "sweep" if d < 50.0 else "slam"
	return "slash"

func _trigger(act: String, tpos: Vector2) -> void:
	state = "busy"
	velocity = Vector2.ZERO
	world.bcast("enemy_action", [idx, act, tpos, randi()])

# ====================================================================== ataques (todos los clientes)
func perform(act: String, tpos: Vector2, seed: int) -> void:
	if state == "dead":
		return
	_attack_id += 1
	var my_id := _attack_id
	state = "busy"
	var to := tpos - global_position
	facing = 1 if to.x >= 0.0 else -1
	var dir := to.normalized() if to.length() > 0.1 else Vector2.RIGHT
	match act:
		"slash":
			_play("attack", 0)
			_tell(0.45)
			if not await _wait(0.45, my_id): return
			_play("attack", 1)
			Audio.sfx("swing", -4.0)
			if multiplayer.is_server():
				lunge = dir * 190.0
			Fx.slash(global_position + Vector2(0, -8) + dir * 6, dir.angle(), 20.0, 120.0, Color(1, 0.45, 0.3, 0.85), 8.0, 0.18)
			if not await _wait(0.08, my_id): return
			_hit_arc(global_position + Vector2(0, -6), dir.angle(), 30.0, 130.0, cfg.dmg)
			if not await _wait(0.55, my_id): return
		"bite":
			_play("attack", 0)
			_tell(0.35)
			if not await _wait(0.35, my_id): return
			if multiplayer.is_server():
				lunge = dir * 220.0
			Audio.sfx("swing", -4.0)
			if not await _wait(0.1, my_id): return
			_hit_arc(global_position, dir.angle(), 26.0, 100.0, cfg.dmg * 0.8)
			if not await _wait(0.5, my_id): return
		"charge":
			_play("attack", 0)
			Fx.telegraph_line(global_position, dir.angle(), 170.0, 18.0, 0.65)
			_tell(0.65)
			if not await _wait(0.65, my_id): return
			Audio.sfx("dash", 0.0)
			var hit_done := false
			var t := 0.0
			while t < 0.55:
				if multiplayer.is_server():
					velocity = dir * 310.0
					lunge = dir * 310.0
				if randf() < 0.6:
					Fx.burst(global_position, Color(1, 0.6, 0.3, 0.7), 2, 40.0, 0.4, "fx_soft", 40.0, -dir, 0.3, false)
				if not hit_done:
					hit_done = _hit_circle(global_position, body_radius + 8.0, cfg.dmg, dir)
				if not await _wait(0.016, my_id): return
				t += 0.016
			if multiplayer.is_server():
				lunge = Vector2.ZERO
			if not await _wait(0.8, my_id): return
		"fan":
			_play("attack", 0)
			Fx.light_flash(global_position + Vector2(0, -12), Color(0.7, 0.4, 1), 1.0, 0.6, 0.6)
			_tell(0.6, Color(0.8, 0.5, 1))
			if not await _wait(0.6, my_id): return
			_play("attack", 2)
			Audio.sfx("enemy_shot")
			var n := 3 if phase == 1 else 5
			for i in n:
				var a := dir.angle() + (i - (n - 1) / 2.0) * 0.26
				world.spawn_projectile_local(global_position + Vector2(0, -12), Vector2.from_angle(a) * 125.0, cfg.dmg, "orb", "enemy", 1, 5.0, 3.0, 0)
			if not await _wait(0.6, my_id): return
		"blink":
			Fx.burst(global_position + Vector2(0, -10), Color(0.7, 0.4, 1), 16, 60.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4)
			Audio.sfx("dash", -4.0)
			visible = false
			if not await _wait(0.35, my_id): return
			if multiplayer.is_server():
				var rng := RandomNumberGenerator.new()
				rng.seed = seed
				for tries in 8:
					var p := tpos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(100.0, 140.0)
					if not world.is_wall_at(p) and not world.is_wall_at(p + Vector2(0, -8)):
						position = p
						_net_pos = p
						break
			visible = true
			Fx.burst(global_position + Vector2(0, -10), Color(0.7, 0.4, 1), 16, 60.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4)
			if not await _wait(0.4, my_id): return
		"slam":
			_play("attack", 0)
			Fx.telegraph_circle(tpos, 40.0, 0.85)
			_tell(0.85)
			if not await _wait(0.85, my_id): return
			_play("attack", 1)
			_slam_at(tpos, 40.0, cfg.dmg * 1.15)
			if not await _wait(0.8, my_id): return
		"sweep":
			_play("attack", 0)
			Fx.telegraph_circle(global_position, 60.0, 0.6, Color(1, 0.4, 0.2))
			_tell(0.6)
			if not await _wait(0.6, my_id): return
			_play("attack", 1)
			Audio.sfx("swing_heavy")
			Fx.slash(global_position + Vector2(0, -10), dir.angle(), 46.0, 240.0, Color(1, 0.6, 0.35, 0.9), 16.0, 0.3)
			_hit_circle(global_position, 60.0, cfg.dmg * 0.85, dir)
			if not await _wait(0.7, my_id): return
		"triple":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = seed
			var spots := [tpos, tpos + Vector2(rng2.randf_range(-50, 50), rng2.randf_range(-40, 40)), tpos + Vector2(rng2.randf_range(-60, 60), rng2.randf_range(-50, 50))]
			for i in 3:
				Fx.telegraph_circle(spots[i], 34.0, 0.7 + i * 0.35)
			_tell(0.7)
			for i in 3:
				if not await _wait(0.7 if i == 0 else 0.35, my_id): return
				_play("attack", 1)
				_slam_at(spots[i], 34.0, cfg.dmg)
			if not await _wait(0.9, my_id): return
	_end_attack(my_id)

func _end_attack(my_id: int) -> void:
	if my_id != _attack_id or state == "dead":
		return
	if state == "busy":
		state = "chase"
	cooldown = cfg.cd * (0.7 if phase == 2 else 1.0) * randf_range(0.8, 1.25)
	anim = "walk"

func _slam_at(p: Vector2, r: float, dmg: float) -> void:
	Audio.sfx("slam")
	G.shake(5.0, 0.3)
	G.shockwave(p, 0.9, 0.45)
	Fx.scorch(p, r * 0.7)
	Fx.ring(p, 6.0, r * 1.2, Color(1, 0.6, 0.3), 0.4, 6.0)
	Fx.burst(p, Color(1, 0.55, 0.25), 22, 130.0, 0.6, "fx_px", 180.0)
	Fx.burst(p, Color(0.5, 0.45, 0.5, 0.8), 10, 60.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.6, false)
	Fx.light_flash(p, Color(1, 0.6, 0.3), 1.6, 1.0, 0.35)
	_hit_circle(p, r, dmg, Vector2.ZERO)

func _wait(t: float, my_id: int) -> bool:
	await get_tree().create_timer(t, false).timeout
	return is_inside_tree() and my_id == _attack_id and state != "dead"

func _tell(dur: float, color := Color(1, 0.3, 0.2)) -> void:
	## Destello de aviso antes del golpe (telegráfico).
	_flash(0.75, color)
	var tw := create_tween()
	tw.tween_method(_set_flash, 0.75, 0.15, dur)
	var mark := Label.new()
	mark.text = "!"
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = color
	ls.outline_size = 3
	ls.outline_color = Color.BLACK
	mark.label_settings = ls
	mark.position = Vector2(-3, cfg.off * 2 - 14)
	add_child(mark)
	var tw2 := mark.create_tween()
	tw2.tween_property(mark, "position:y", mark.position.y - 4, dur * 0.5).set_trans(Tween.TRANS_BACK)
	tw2.tween_interval(dur * 0.5)
	tw2.tween_callback(mark.queue_free)

func _hit_arc(origin: Vector2, ang: float, rng: float, arc_deg: float, dmg: float) -> bool:
	var any := false
	for p in world.local_players():
		if not p.is_alive():
			continue
		var to: Vector2 = p.global_position + Vector2(0, -6) - origin
		if to.length() > rng + 6.0:
			continue
		if abs(wrapf(to.angle() - ang, -PI, PI)) > deg_to_rad(arc_deg / 2.0) and to.length() > 10.0:
			continue
		p.take_hit(dmg, to.normalized(), idx)
		any = true
	return any

func _hit_circle(center: Vector2, r: float, dmg: float, dir: Vector2) -> bool:
	var any := false
	for p in world.local_players():
		if p.is_alive() and p.global_position.distance_to(center) < r + 5.0:
			var d = dir if dir != Vector2.ZERO else (p.global_position - center).normalized()
			p.take_hit(dmg, d, idx)
			any = true
	return any

# ====================================================================== daño (servidor)
func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if state == "dead" or (is_boss and not active):
		return {}
	hp -= dmg
	last_hit_t = 0.0
	var broke := false
	if state != "stagger":
		poise += poise_dmg
		if poise >= max_poise:
			poise = 0.0
			broke = true
	if not is_boss or state != "busy":
		velocity += dir * (90.0 if not is_boss else 20.0)
	return {"hp": hp, "broke": broke, "dead": hp <= 0.0}

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	hp = new_hp
	_flash(1.0, Color(1, 1, 1))
	Fx.number(global_position + Vector2(0, cfg.off), dmg, Color(1, 0.85, 0.3) if crit else Color(1, 1, 1), crit)
	Fx.burst(global_position + Vector2(0, cfg.off * 0.6), Color(1, 0.9, 0.7), 8 if not crit else 16, 110.0, 0.35, "fx_px", 50.0, dir)
	Fx.burst(global_position + Vector2(0, cfg.off * 0.6), Color(1, 0.5, 0.2), 4, 60.0, 0.5, "fx_soft", 70.0, dir, 0.3)
	Fx.sparks(global_position + Vector2(0, cfg.off * 0.6), dir if dir != Vector2.ZERO else Vector2.UP, Color(1, 0.7, 0.35), 5 if not crit else 12, 140.0, 90.0)
	sprite.scale = Vector2(1.2, 0.85)
	if _hp_bar:
		_hp_bar.visible = true
		_hp_bar.ratio = hp / max_hp
		_hp_bar.queue_redraw()
	if broke:
		_start_stagger()

func _start_stagger() -> void:
	_attack_id += 1
	state = "stagger"
	stagger_t = 1.6 if not is_boss else 2.2
	Fx.text(global_position + Vector2(0, cfg.off), G.T("broken"), Color(1, 0.7, 0.3), 9)
	Fx.ring(global_position + Vector2(0, cfg.off * 0.6), 4.0, 26.0, Color(1, 0.8, 0.3), 0.3, 3.0)
	Audio.sfx("parry", -6.0)

func on_parried() -> void:
	if state == "dead":
		return
	if is_boss:
		poise += max_poise * 0.35
		if poise >= max_poise:
			poise = 0.0
			_start_stagger()
		else:
			_attack_id += 1
			state = "chase"
			cooldown = 1.0
	else:
		_start_stagger()

func die() -> void:
	if state == "dead":
		return
	if is_boss:
		G.shockwave(global_position + Vector2(0, cfg.off), 2.0, 1.0)
		G.chroma(2.0, 1.0)
	state = "dead"
	_attack_id += 1
	velocity = Vector2.ZERO
	anim = "dead"
	if _hp_bar:
		_hp_bar.visible = false
	Audio.sfx("die")
	Fx.burst(global_position + Vector2(0, cfg.off * 0.5), Color(1, 0.6, 0.3), 24, 100.0, 0.8, "fx_px", 180.0, Vector2.UP)
	Fx.burst(global_position + Vector2(0, cfg.off * 0.5), Color(0.6, 0.85, 1.0), 10, 50.0, 1.2, "fx_soft", 180.0, Vector2.UP, 0.4, true, Vector2(0, -30))
	var row: Array = cfg.anims.dead
	sprite.region_rect = Rect2(row[1] * cfg.fw, row[0] * cfg.fh, cfg.fw, cfg.fh)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_method(_set_dissolve, 0.0, 1.0, 0.9)
	tw.tween_callback(hide)

# ====================================================================== visual
func _play(a: String, frame := -1) -> void:
	anim = a
	if frame >= 0:
		_frame = frame
		var key := a if not (phase == 2 and cfg.anims.has(a + "2")) else a + "2"
		var row: Array = cfg.anims.get(key, cfg.anims.idle)
		sprite.region_rect = Rect2(frame * cfg.fw, row[0] * cfg.fh, cfg.fw, cfg.fh)

func _animate(delta: float) -> void:
	if state == "dead":
		return
	if state != "busy":
		if state == "stagger":
			anim = "idle"
		else:
			anim = "walk" if velocity.length() > 12.0 or (not multiplayer.is_server() and position.distance_to(_net_pos) > 1.0) else "idle"
	var key := anim
	if phase == 2 and cfg.anims.has(anim + "2"):
		key = anim + "2"
	var row: Array = cfg.anims.get(key, cfg.anims.idle)
	if state != "busy" or anim != "attack":
		_frame += delta * row[2]
		var f := int(_frame) % int(row[1])
		sprite.region_rect = Rect2(f * cfg.fw, row[0] * cfg.fh, cfg.fw, cfg.fh)
	sprite.flip_h = facing < 0
	sprite.scale = sprite.scale.lerp(Vector2.ONE, clamp(delta * 10.0, 0.0, 1.0))
	if state == "stagger":
		sprite.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.08
		sprite.modulate = Color(1.0, 0.85, 0.6)
	else:
		sprite.rotation = 0.0
		sprite.modulate = Color.WHITE
	var fl: float = _flash_mat.get_shader_parameter("flash")
	if fl > 0.0 and state != "busy":
		_flash_mat.set_shader_parameter("flash", max(0.0, fl - delta * 7.0))

func _set_flash(v: float) -> void:
	_flash_mat.set_shader_parameter("flash", v)

func _set_dissolve(v: float) -> void:
	_flash_mat.set_shader_parameter("dissolve", v)

func _flash(a: float, c: Color) -> void:
	_flash_mat.set_shader_parameter("flash", a)
	_flash_mat.set_shader_parameter("flash_color", c)

func net_update(pos: Vector2, fc: int, st: String) -> void:
	_net_pos = pos
	facing = fc
	if state != "dead" and st != "busy" and state != "busy":
		state = st

class HpBar extends Node2D:
	var ratio := 1.0
	func _draw() -> void:
		draw_rect(Rect2(-10, 0, 20, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-9.5, 0.5, 19.0 * ratio, 2), Color(0.9, 0.2, 0.25))

class_name Player
extends CharacterBody2D
## Desplumado jugable. Solo el dueño (autoridad) simula su entrada; el resto interpola.

const FW := 32
const FH := 32
const ROWS := {"idle": [0, 4, 6.0], "run": [1, 6, 12.0], "attack": [2, 3, 14.0], "hurt": [3, 1, 1.0], "dead": [3, 1, 1.0]}

var peer_id := 1
var variant := 1
var world: Node

# estado
var state := "move"
var hp := 100.0
var stamina := 100.0
var light := 60.0
var wrath := 0.0
var flasks := 3
var aim := Vector2.RIGHT
var facing := 1
var iframes := 0.0
var dash_t := 0.0
var dash_dir := Vector2.ZERO
var dash_charges := 1
var dash_recharge := 0.0
var dash_start_ms := 0
var parry_t := 0.0
var parry_window := 0.0
var combo := 0
var combo_window := 0.0
var attack_t := 0.0
var attack_len := 0.3
var queued := ""
var heavy_charge := 0.0
var stam_delay := 0.0
var hurt_t := 0.0
var heal_t := 0.0
var downed_t := 0.0
var revive_progress := 0.0
var crit_next := false
var last_breath_used := false
var cutscene := false
var sitting := false
var _buff_fx_t := 0.0
var fire_trail_t := 0.0
var orbit_angle := 0.0
var _orbit_hit := {}
var _dash_hit := {}

# visual
var sprite: Sprite2D
var weapon_pivot: Node2D
var weapon_spr: Sprite2D
var plight: PointLight2D
var _anim := "idle"
var _frame := 0.0
var _afterimage_t := 0.0
var _flash_mat: ShaderMaterial
var _orbit_nodes: Array[Sprite2D] = []
var _weapon_rest := 0.0
var _swing_tween: Tween
var _sync_t := 0.0
var _net_pos := Vector2.ZERO
var _net_hp_ratio := 1.0
var _step_t := 0.0
var name_label: Label

var look := {}
var feathers_shown := 10

func set_look(l: Dictionary, feathers: int) -> void:
	look = Look.sane(l)
	feathers_shown = feathers
	if sprite:
		sprite.texture = Look.texture(look, feathers_shown)

func refresh_look() -> void:
	set_look(G.look if peer_id == Net.my_id() else look, Prog.wing_feathers if peer_id == Net.my_id() else feathers_shown)

func setup(p_peer: int, p_variant: int, p_world: Node) -> void:
	peer_id = p_peer
	variant = p_variant
	world = p_world
	name = "P%d" % peer_id
	set_multiplayer_authority(peer_id)

func is_local() -> bool:
	return peer_id == Net.my_id()

func is_alive() -> bool:
	return state != "dead" and state != "downed"

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	cs.shape = c
	add_child(cs)
	# sombra
	var sh := Sprite2D.new()
	sh.texture = Fx.tex("fx_soft")
	sh.modulate = Color(0, 0, 0, 0.55)
	sh.scale = Vector2(1.0, 0.45)
	sh.z_index = -1
	add_child(sh)
	sprite = Sprite2D.new()
	if look.is_empty():
		if peer_id == Net.my_id():
			if G.look.is_empty():
				G.look = Look.defaults_p2() if variant == 2 else Look.sane({})
			look = Look.sane(G.look)
		else:
			look = Look.defaults_p2() if variant == 2 else Look.sane({})
	if peer_id == Net.my_id():
		feathers_shown = Prog.wing_feathers
	sprite.texture = Look.texture(look, feathers_shown)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, FW, FH)
	sprite.offset = Vector2(0, -14)
	_flash_mat = Fx.flash_material()
	sprite.material = _flash_mat
	add_child(sprite)
	weapon_pivot = Node2D.new()
	weapon_pivot.position = Vector2(0, -10)
	add_child(weapon_pivot)
	weapon_spr = Sprite2D.new()
	weapon_spr.offset = Vector2(14, 0)
	weapon_pivot.add_child(weapon_spr)
	plight = PointLight2D.new()
	plight.texture = Fx.tex("light")
	plight.texture_scale = 2.0
	plight.energy = 0.7
	plight.color = Color(1.0, 0.9, 0.75) if variant == 1 else Color(0.7, 0.95, 1.0)
	add_child(plight)
	if Net.is_online():
		name_label = Label.new()
		name_label.text = "P1" if variant == 1 else "P2"
		var ls := LabelSettings.new()
		ls.font_size = 7
		ls.outline_size = 2
		ls.outline_color = Color.BLACK
		ls.font_color = Color(1, 0.9, 0.6) if variant == 1 else Color(0.6, 0.95, 1)
		name_label.label_settings = ls
		name_label.position = Vector2(-6, -42)
		add_child(name_label)
	refresh_stats(true)
	_update_weapon_sprite()
	_net_pos = position
	Prog.changed.connect(_on_prog_changed)

func _on_prog_changed() -> void:
	if is_local():
		_update_weapon_sprite()
		_update_orbit()

func refresh_stats(full := false) -> void:
	if not is_local():
		return
	if full:
		hp = Prog.max_hp()
		stamina = Prog.max_stamina()
		light = Prog.max_light()
		flasks = Prog.flask_count()
		last_breath_used = false
	_update_orbit()

func _update_weapon_sprite() -> void:
	var wid: String = Prog.equipped if is_local() else _remote_weapon
	weapon_spr.texture = Fx.tex("weapon_" + Prog.WEAPONS[wid].sprite)

var _remote_weapon := "sword"

func _update_orbit() -> void:
	var want := 3 if (is_local() and Prog.has_skill("k1")) else 0
	while _orbit_nodes.size() < want:
		var s := Sprite2D.new()
		s.texture = Fx.tex("proj_sword")
		s.material = Fx.add_material()
		s.modulate = Color(1, 0.9, 0.8, 0.9)
		add_child(s)
		_orbit_nodes.append(s)
	while _orbit_nodes.size() > want:
		_orbit_nodes.pop_back().queue_free()

# ====================================================================== bucle
func _physics_process(delta: float) -> void:
	if is_local():
		_local_update(delta)
		_sync_t -= delta
		if _sync_t <= 0.0 and Net.is_online():
			_sync_t = 0.05
			for pid in world.joined_peers:
				_net_state.rpc_id(pid, position, velocity, aim.angle(), state, _anim, int(_frame), hp / Prog.max_hp(), facing, Prog.equipped)
	else:
		position = position.lerp(_net_pos, clamp(delta * 14.0, 0.0, 1.0))
		if position.distance_to(_net_pos) > 120.0:
			position = _net_pos
	_animate(delta)
	_update_weapon_visual(delta)
	_update_orbit_visual(delta)

func _local_update(delta: float) -> void:
	if cutscene or world.is_menu_open():
		velocity = velocity.lerp(Vector2.ZERO, 0.3)
		move_and_slide()
		return
	_update_aim()
	# recursos
	stam_delay -= delta
	if stam_delay <= 0.0 and state != "dash":
		stamina = min(Prog.max_stamina(), stamina + (42.0 + Prog.attr.aguante * 1.5) * Prog.stamina_regen_mult() * delta)
	_buff_fx_t -= delta
	if _buff_fx_t <= 0.0 and not Prog.buffs.is_empty():
		_buff_fx_t = 0.12
		if Prog.buffs.has("incense"):
			Fx.burst(global_position + Vector2(randf_range(-8, 8), randf_range(-16, 0)), Color(1, 0.75, 0.3), 1, 25.0, 0.7, "fx_soft", 30.0, Vector2.UP, 0.25)
		if Prog.buffs.has("ointment"):
			Fx.burst(global_position + Vector2(randf_range(-8, 8), randf_range(-16, 0)), Color(0.4, 0.9, 1.0), 1, 20.0, 0.7, "fx_px", 30.0, Vector2.UP, 1.0)
	light = min(Prog.max_light(), light + 3.5 * (1.4 if Prog.has_skill("l3") else 1.0) * delta)
	if Prog.has_skill("c5") and Net.is_online():
		for p in world.players_list():
			if p != self and p.is_alive() and p.global_position.distance_to(global_position) < 60.0:
				hp = min(Prog.max_hp(), hp + 1.5 * delta)
	iframes = max(0.0, iframes - delta)
	if dash_recharge > 0.0:
		dash_recharge -= delta
		if dash_recharge <= 0.0:
			dash_charges = 2 if Prog.has_skill("a2") else 1
	combo_window = max(0.0, combo_window - delta)
	if combo_window <= 0.0 and state == "move":
		combo = 0

	var input := Input.get_vector("left", "right", "up", "down")
	match state:
		"move":
			var spd := Prog.move_speed()
			velocity = velocity.lerp(input * spd, clamp(delta * 14.0, 0.0, 1.0))
			_read_actions()
			if input.length() > 0.1:
				_step_t -= delta
				if _step_t <= 0.0:
					_step_t = 0.28
					Fx.burst(global_position + Vector2(0, 1), Color(0.6, 0.55, 0.6, 0.6), 3, 20.0, 0.35, "fx_px", 60.0, -input, 0.8, false)
		"attack":
			attack_t += delta
			velocity = velocity.lerp(Vector2.ZERO, clamp(delta * 9.0, 0.0, 1.0))
			if Input.is_action_just_pressed("attack"):
				queued = "attack"
			elif Input.is_action_just_pressed("dash"):
				queued = "dash"
			if attack_t >= attack_len:
				state = "move"
				combo_window = 0.35
				if queued == "attack":
					queued = ""
					_start_attack()
				elif queued == "dash":
					queued = ""
					_start_dash(input)
			elif queued == "dash" and attack_t > attack_len * 0.55:
				queued = ""
				_start_dash(input)
		"charge":
			velocity = velocity.lerp(input * Prog.move_speed() * 0.35, clamp(delta * 10.0, 0.0, 1.0))
			var rate := 1.35 if Prog.has_skill("f3") else 1.0
			var prev := int(heavy_charge / 0.4)
			heavy_charge = min(1.2, heavy_charge + delta * rate)
			var lvl := int(heavy_charge / 0.4)
			if lvl > prev:
				Audio.sfx("charge", 0.0, 0.0)
				Fx.ring(global_position + Vector2(0, -8), 18.0, 4.0, Color(1, 0.8, 0.4), 0.25, 2.0)
				_flash(0.6, Color(1, 0.85, 0.5))
			if randf() < 0.5:
				Fx.burst(global_position + Vector2(randf_range(-10, 10), randf_range(-14, 2)), Color(1, 0.8, 0.4), 1, 30.0, 0.4, "fx_px", 30.0, Vector2.UP)
			if not Input.is_action_pressed("heavy"):
				_release_heavy()
		"heavy":
			attack_t += delta
			velocity = velocity.lerp(Vector2.ZERO, clamp(delta * 7.0, 0.0, 1.0))
			if attack_t >= attack_len:
				state = "move"
		"dash":
			dash_t -= delta
			velocity = dash_dir * 360.0 * (0.6 + 0.4 * dash_t / 0.17)
			_afterimage_t -= delta
			if _afterimage_t <= 0.0:
				_afterimage_t = 0.025
				Fx.afterimage(sprite, sprite.global_position, Color(1, 0.85, 0.5, 0.6) if variant == 1 else Color(0.5, 0.9, 1, 0.6))
			if Prog.has_skill("a4"):
				_dash_damage()
			if Prog.has_skill("a6") or Prog.synergy("ash_wing"):
				fire_trail_t -= delta
				if fire_trail_t <= 0.0:
					fire_trail_t = 0.05
					world.spawn_fire(global_position, Net.my_id())
			if dash_t <= 0.0:
				state = "move"
				velocity = dash_dir * 80.0
				_squash(Vector2(1.25, 0.8))
		"parry":
			parry_t -= delta
			parry_window -= delta
			velocity = velocity.lerp(Vector2.ZERO, 0.3)
			if parry_t <= 0.0:
				state = "move"
		"hurt":
			hurt_t -= delta
			velocity = velocity.lerp(Vector2.ZERO, clamp(delta * 8.0, 0.0, 1.0))
			if hurt_t <= 0.0:
				state = "move"
		"heal":
			heal_t -= delta
			velocity = velocity.lerp(input * Prog.move_speed() * 0.3, 0.2)
			if heal_t <= 0.0:
				var before := hp
				hp = min(Prog.max_hp(), hp + Prog.max_hp() * Prog.heal_ratio())
				Audio.sfx("heal", -2.0)
				_heal_fx(hp - before)
				state = "move"
		"downed":
			velocity = Vector2.ZERO
			downed_t -= delta
			if downed_t <= 0.0:
				_die_for_real()
		"dead":
			velocity = Vector2.ZERO
	move_and_slide()

func _read_actions() -> void:
	var input := Input.get_vector("left", "right", "up", "down")
	if Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_pressed("heavy"):
		if stamina > 5.0:
			state = "charge"
			heavy_charge = 0.0
	elif Input.is_action_just_pressed("dash"):
		_start_dash(input)
	elif Input.is_action_just_pressed("parry"):
		_start_parry()
	elif Input.is_action_just_pressed("spell1"):
		_cast_lance()
	elif Input.is_action_just_pressed("spell2"):
		_cast_nova()
	elif Input.is_action_just_pressed("wrath"):
		_cast_wrath()
	elif Input.is_action_just_pressed("heal"):
		if flasks > 0 and hp < Prog.max_hp():
			flasks -= 1
			state = "heal"
			heal_t = 0.55
			_squash(Vector2(0.9, 1.1))
	elif Input.is_action_just_pressed("interact"):
		world.try_interact(self)
	elif Input.is_action_just_pressed("item"):
		_use_quick_item()

func _update_aim() -> void:
	var joy := Input.get_vector("left", "right", "up", "down")
	var rs := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if rs.length() > 0.35:
		aim = rs.normalized()
	elif Input.get_connected_joypads().size() > 0 and joy.length() > 0.3 and Input.get_last_mouse_velocity().length() < 1.0:
		aim = joy.normalized()
	else:
		var m := get_global_mouse_position() - (global_position + Vector2(0, -8))
		if m.length() > 2.0:
			aim = m.normalized()
	if state == "move" or state == "charge":
		facing = 1 if aim.x >= 0.0 else -1

func _use_quick_item() -> void:
	var id := Prog.quick_item
	if Prog.item_count(id) <= 0:
		for k in ["bomb", "incense", "ointment", "vial_luz", "vial_aliento"]:
			if Prog.item_count(k) > 0:
				id = k
				Prog.quick_item = k
				break
	if Prog.item_count(id) <= 0:
		return
	match id:
		"bomb":
			Prog.remove_item("bomb")
			var m := get_global_mouse_position() - global_position
			var dist: float = clamp(m.length(), 30.0, 120.0)
			world.throw_bomb(global_position + Vector2(0, -12), global_position + aim * dist, Net.my_id())
			_swing(80.0, 0.1, true)
		"vial_luz", "vial_aliento":
			if Prog.use_item(id):
				var vc := Color(0.45, 0.8, 1.0) if id == "vial_luz" else Color(1, 0.8, 0.3)
				if id == "vial_luz":
					light = min(Prog.max_light(), light + 30.0)
				else:
					stamina = Prog.max_stamina()
				Audio.sfx("heal", -4.0)
				Fx.ring(global_position + Vector2(0, -8), 3.0, 30.0, vc, 0.45, 3.0)
				for i in 10:
					Fx.burst(global_position + Vector2(randf_range(-8, 8), -4), vc, 1, 14.0, 0.8, "fx_px", 20.0, Vector2.UP, 0.5, false, Vector2(0, -45))
		"incense", "ointment":
			if Prog.use_item(id):
				var c := Color(1, 0.75, 0.3) if id == "incense" else Color(0.4, 0.9, 1.0)
				Audio.sfx("heal", -2.0)
				Fx.ring(global_position + Vector2(0, -8), 4.0, 36.0, c, 0.5, 4.0)
				Fx.burst(global_position + Vector2(0, -8), c, 24, 70.0, 0.8, "fx_soft", 180.0, Vector2.UP, 0.35)
				Fx.text(global_position, G.L(Prog.ITEMS[id].name), c, 9)
	_squash(Vector2(0.9, 1.15))

func spend_stamina(n: float) -> bool:
	if stamina <= 0.0:
		return false
	stamina -= n
	stam_delay = 0.55
	return true

# ====================================================================== combate
func _start_attack() -> void:
	var w := Prog.weapon_data()
	if not spend_stamina(w.stam):
		return
	var max_combo: int = w.combo + (1 if Prog.has_skill("f2") else 0)
	if combo_window <= 0.0 and state == "move" and combo >= max_combo:
		combo = 0
	combo = (combo % max_combo) + 1
	var final := combo == max_combo
	state = "attack"
	attack_t = 0.0
	attack_len = (0.30 if not final else 0.42) / w.speed
	facing = 1 if aim.x >= 0.0 else -1
	velocity = aim * (95.0 if not final else 150.0)
	# cada golpe del combo es distinto: barrido, revés, tajo descendente y un remate propio de cada arma
	var style = ["sweep", "backhand", "overhead", "sweep"][(combo - 1) % 4]
	if final:
		style = {"sword": "spin", "spear": "burst", "scythe": "reap", "hammer": "quake", "seravel": "spin", "choir": "spin"}.get(w.sprite, "spin")
	var dmg := Prog.weapon_damage() * (1.0 if not final else 1.7)
	var arc: float = w.arc * (1.0 if not final else 1.25)
	var rng: float = w.range * (1.0 if not final else 1.15)
	match style:
		"backhand":
			arc *= 0.9; dmg *= 1.05
		"overhead":
			arc *= 0.55; rng *= 1.25; dmg *= 1.2
		"spin":
			arc = 360.0; rng *= 0.95
		"burst":
			arc *= 0.5; rng *= 1.5
		"reap":
			arc = 300.0
		"quake":
			arc = 360.0; rng *= 1.1
	Audio.sfx("swing" if not final else "swing_heavy", 0.0, 0.12)
	var cw = style != "backhand"
	_swing(arc if arc < 300.0 else 300.0, 0.09 / w.speed + 0.04, cw)
	_combo_fx(style, rng, w)
	var col := Color(1, 0.95, 0.85, 0.85) if variant == 1 else Color(0.7, 0.95, 1, 0.85)
	if w.sprite == "seravel":
		col = Color(1, 0.6, 0.65, 0.9)
	var inf := Prog.infusion()
	if inf != "":
		col = Color(Prog.INFUSIONS[inf].color, 0.92)
	var thrust: bool = w.sprite == "spear"
	if thrust:
		_thrust_fx(rng, col)
	else:
		Fx.slash(global_position + Vector2(0, -8), aim.angle(), rng * 0.8, arc, col, 9.0 if not final else 14.0, 0.2, cw)
	if Net.is_online():
		world.peer_rpc(self, "_net_fx", ["slash", [aim.angle(), rng, arc, final, cw, thrust]])
	_squash(Vector2(1.15, 0.9))
	get_tree().create_timer(0.06 / w.speed).timeout.connect(_hit_check.bind(dmg, rng, arc, w.poise * (1.0 if not final else 1.8), final))
	if final and w.get("wave", false):
		world.bcast("spawn_projectile", [global_position + Vector2(0, -6) + aim * 12, aim * 260.0, Prog.spell_damage(16.0), "wave", "player", Net.my_id(), 12.0, 0.7, 4])
	if final and w.get("notes", false):
		for a in [-0.35, 0.0, 0.35]:
			world.bcast("spawn_projectile", [global_position + Vector2(0, -6) + aim * 10, aim.rotated(a) * 230.0, Prog.spell_damage(9.0), "note", "player", Net.my_id(), 6.0, 0.9, 3])

func _heal_fx(amount: float) -> void:
	## Curación: espiral de luz que sube, anillo cálido y la cifra recuperada
	var p := global_position
	Fx.ring(p + Vector2(0, -2), 4.0, 26.0, Color(1, 0.55, 0.5), 0.45, 3.0)
	Fx.ring(p + Vector2(0, -2), 2.0, 16.0, Color(1, 0.95, 0.85), 0.35, 2.0)
	for i in 14:
		var a := TAU * i / 14.0
		Fx.burst(p + Vector2(cos(a) * 10.0, sin(a) * 4.0), Color(1, 0.55, 0.6) if i % 2 else Color(1, 0.92, 0.8), 1, 16.0, 0.9, "fx_px", 20.0, Vector2.UP, 0.5, false, Vector2(0, -50))
	Fx.burst(p + Vector2(0, -10), Color(1, 0.7, 0.7), 10, 40.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.35)
	Fx.light_flash(p, Color(1, 0.6, 0.55), 1.4, 1.1, 0.6)
	if amount > 0.5:
		Fx.text(p + Vector2(0, -26), "+%d" % int(round(amount)), Color(1, 0.6, 0.65), 10)
	_flash(0.6, Color(1, 0.8, 0.8))

func _combo_fx(style: String, rng: float, w: Dictionary) -> void:
	var p := global_position + Vector2(0, -8)
	match style:
		"overhead":
			_squash(Vector2(0.85, 1.25))
			get_tree().create_timer(0.07).timeout.connect(func():
				Fx.ring(p + aim * rng * 0.9, 3.0, 16.0, Color(1, 0.85, 0.55), 0.25, 3.0)
				Fx.sparks(p + aim * rng * 0.9, Vector2.UP, Color(1, 0.8, 0.45), 6, 90.0, 120.0)
				G.shake(1.5, 0.08))
		"spin":
			Fx.slash(p, aim.angle() + PI, rng * 0.75, 200.0, Color(1, 1, 1, 0.55), 10.0, 0.22, false)
			Fx.ring(global_position, 4.0, rng, Color(1, 0.9, 0.7), 0.3, 3.0)
		"reap":
			Fx.slash(p, aim.angle() + PI * 0.5, rng * 0.8, 180.0, Color(0.85, 0.7, 1.0, 0.8), 12.0, 0.25, true)
		"quake":
			get_tree().create_timer(0.08).timeout.connect(func():
				Fx.ring(global_position, 6.0, rng * 1.3, Color(1, 0.6, 0.3), 0.4, 6.0)
				Fx.scorch(global_position + aim * 10.0, 14.0)
				G.shockwave(global_position, 0.8, 0.35)
				G.shake(3.5, 0.15))
		"burst":
			for i in 3:
				Fx.burst(p + aim * (rng * (0.4 + i * 0.3)), Color(1, 0.95, 0.8), 3, 30.0, 0.25, "fx_soft", 30.0, aim, 0.4)

func _thrust_fx(rng: float, col: Color) -> void:
	var p := global_position + Vector2(0, -8)
	for i in 6:
		Fx.burst(p + aim * (rng * i / 6.0), col, 1, 10.0, 0.18, "fx_soft", 10.0, aim, 0.35)
	Fx.slash(p + aim * rng * 0.5, aim.angle(), rng * 0.5, 30.0, col, 6.0, 0.15)

func _hit_check(dmg: float, rng: float, arc: float, poise: float, final: bool) -> void:
	if not is_inside_tree() or state == "dead":
		return
	var origin := global_position + Vector2(0, -6)
	var hits := 0
	for e in world.enemies_alive():
		var to: Vector2 = e.global_position + Vector2(0, -6) - origin
		var dist = to.length() - e.body_radius
		if dist > rng:
			continue
		var ang: float = abs(wrapf(to.angle() - aim.angle(), -PI, PI))
		if ang > deg_to_rad(arc / 2.0 + 15.0) and to.length() > e.body_radius + 6.0:
			continue
		hits += 1
		var crit := crit_next or randf() < Prog.crit_chance()
		var d := dmg * (1.8 if crit else 1.0) * Prog.weapon_memory_mult(e.type)
		if crit and _hawk:
			d *= 1.45
		if crit and Prog.synergy("eye_choir"):
			light = min(Prog.max_light(), light + 4.0)
		if e.is_staggered():
			d *= 1.6 if Prog.has_skill("f5") else 1.3
			crit = true
		var inf := Prog.infusion()
		world.request_damage_enemy(e, d, to.normalized(), poise * (1.4 if inf == "escarcha" else 1.0) * (1.4 if Prog.oath == "carcelero" else 1.0), crit)
		_on_hit_landed(d, final or crit)
		var hp_pos: Vector2 = e.global_position + Vector2(0, -8)
		if inf != "":
			_infusion_hit(e, d, inf, hp_pos)
		Fx.impact(hp_pos, Color(1, 0.85, 0.5) if not crit else Color(1, 0.4, 0.3), 14.0 if not (final or crit) else 22.0)
		Fx.sparks(hp_pos, to.normalized(), Color(1, 0.8, 0.4), 6 if not final else 12, 170.0, 80.0)
		if Prog.has_amulet("amulet_ash") and randf() < 0.25:
			world.request_damage_enemy(e, d * 0.35, Vector2.ZERO, 0.0, false)
			Fx.burst(hp_pos, Color(1, 0.5, 0.15), 10, 60.0, 0.6, "fx_soft", 180.0, Vector2.UP, 0.35)
		var bleed: bool = Prog.weapon_data().get("bleed", false)
		if bleed and randf() < 0.35:
			world.request_damage_enemy(e, d * 0.4, to.normalized(), 0.0, false)
	if hits > 0:
		crit_next = false
		_hawk = false
		if world.hud and world.hud.has_method("combo_hit"):
			world.hud.combo_hit(hits)
		G.hitstop(0.075 if final else 0.045)
		G.shake(3.0 if final else 1.6, 0.12)
		if final:
			G.punch(0.035)
			G.chroma(0.6, 0.2)

var _blood_n := 0
var _hawk := false

func _infusion_hit(e: Enemy, d: float, inf: String, pos: Vector2) -> void:
	var c: Color = Prog.INFUSIONS[inf].color
	match inf:
		"brasa":
			world.request_damage_enemy(e, d * 0.2 + 2.0, Vector2.ZERO, 0.0, false)
			Fx.burst(pos, c, 10, 70.0, 0.55, "fx_soft", 160.0, Vector2.UP, 0.35)
			Fx.scorch(e.global_position, 9.0)
		"escarcha":
			world.request_status(e, "slow", 1.8)
			Fx.sparks(pos, Vector2.UP, c, 8, 120.0, 40.0)
		"nimbo":
			light = min(Prog.max_light(), light + 3.5)
			Fx.souls(pos, self, 2)
		"sangre":
			_blood_n += 1
			if _blood_n % 3 == 0:
				var extra: float = min(e.max_hp * 0.06, 35.0 + Prog.weapon_damage() * 0.8)
				world.request_damage_enemy(e, extra, Vector2.ZERO, 0.0, true)
				Fx.burst(pos, c, 18, 110.0, 0.6, "fx_px", 180.0, Vector2.UP, 0.5)
				Fx.text(pos + Vector2(0, -10), G.L(["SANGRÍA", "BLOODLETTING"]), c, 8)
				Audio.sfx("hit_heavy", -4.0)

func _on_hit_landed(d: float, big: bool) -> void:
	wrath = min(100.0, wrath + d * 0.45 * (1.4 if Prog.has_skill("f6") else 1.0))
	if Prog.has_skill("f4"):
		hp = min(Prog.max_hp(), hp + d * 0.03)
	if Prog.has_skill("l5"):
		light = min(Prog.max_light(), light + 2.5)
	Audio.sfx("hit_heavy" if big else "hit")

func _release_heavy() -> void:
	var w := Prog.weapon_data()
	var lvl := int(heavy_charge / 0.4)
	if not spend_stamina(w.stam * 1.6):
		state = "move"
		return
	state = "heavy"
	attack_t = 0.0
	attack_len = 0.5 / w.speed
	facing = 1 if aim.x >= 0.0 else -1
	velocity = aim * (170.0 + 50.0 * lvl)
	var mult := (1.5 + 0.55 * lvl) * (1.25 if Prog.has_skill("f3") else 1.0)
	var arc: float = min(300.0, w.arc * 1.5 + 40.0 * lvl)
	var rng: float = w.range * (1.2 + 0.15 * lvl)
	Audio.sfx("swing_heavy")
	_swing(arc, 0.12, true)
	Fx.slash(global_position + Vector2(0, -8), aim.angle(), rng * 0.85, arc, Color(1, 0.8, 0.45, 0.95), 16.0 + 4.0 * lvl, 0.28, true)
	if lvl >= 2:
		Fx.ring(global_position, 6.0, rng * 1.2, Color(1, 0.8, 0.45), 0.35, 5.0)
		G.shockwave(global_position + aim * 20.0, 1.0, 0.45)
		G.punch(0.05)
	if Net.is_online():
		world.peer_rpc(self, "_net_fx", ["heavy", [aim.angle(), rng, arc, lvl]])
	_squash(Vector2(1.3, 0.75))
	get_tree().create_timer(0.08).timeout.connect(_hit_check.bind(Prog.weapon_damage() * mult, rng, arc, w.poise * (2.2 + lvl), true))

func _start_dash(input: Vector2) -> void:
	if dash_charges <= 0:
		return
	var cost := 22.0 * (0.75 if Prog.has_skill("a1") else 1.0)
	if not spend_stamina(cost):
		return
	dash_charges -= 1
	dash_recharge = 0.45
	state = "dash"
	dash_t = 0.17
	dash_dir = input.normalized() if input.length() > 0.1 else aim
	iframes = 0.18
	dash_start_ms = Time.get_ticks_msec()
	_dash_hit.clear()
	Audio.sfx("dash")
	world.note_dash(peer_id, global_position, dash_dir)
	_squash(Vector2(1.3, 0.75))
	Fx.burst(global_position, Color(0.8, 0.8, 0.9, 0.7), 8, 60.0, 0.4, "fx_soft", 40.0, -dash_dir, 0.35, false)
	Fx.burst(global_position + Vector2(0, -10), Color(1, 1, 1), 4, 70.0, 0.6, "fx_feather", 90.0, -dash_dir, 1.0, false, Vector2(0, 40))
	if Net.is_online():
		world.peer_rpc(self, "_net_fx", ["dash", [dash_dir]])

func _dash_damage() -> void:
	for e in world.enemies_alive():
		if not _dash_hit.has(e) and e.global_position.distance_to(global_position) < e.body_radius + 10.0:
			_dash_hit[e] = true
			world.request_damage_enemy(e, Prog.weapon_damage() * 0.6, dash_dir, 4.0, false)
			Fx.slash(e.global_position + Vector2(0, -6), dash_dir.angle(), 12.0, 90.0, Color(0.7, 0.9, 1), 6.0, 0.15)

func _start_parry() -> void:
	if not spend_stamina(10.0):
		return
	state = "parry"
	parry_t = 0.38
	parry_window = 0.15 * (1.5 if Prog.has_skill("c1") else 1.0)
	_swing(40.0, 0.05, false)
	Fx.ring(global_position + Vector2(0, -8), 4.0, 16.0, Color(0.8, 0.9, 1.0), 0.15, 2.0)
	if Net.is_online():
		world.peer_rpc(self, "_net_fx", ["parry", []])

func _cast_lance() -> void:
	var lc := 15.0 * Prog.spell_cost_mult()
	if not Prog.ability("lance"):
		_locked_hint()
		return
	if light < lc or state != "move":
		return
	light -= lc
	var dmg := Prog.spell_damage(22.0)
	var dirs := [0.0]
	if Prog.has_skill("l4"):
		dirs = [-0.2, 0.0, 0.2]
	for a in dirs:
		var d := aim.rotated(a)
		world.bcast("spawn_projectile", [global_position + Vector2(0, -8) + d * 10, d * 340.0, dmg, "lance", "player", Net.my_id(), 5.0, 1.2, 1])
	Audio.sfx("lance")
	Fx.light_flash(global_position + aim * 12, Color(1, 0.9, 0.6), 1.2, 0.7, 0.2)
	_swing(60.0, 0.08, true)
	velocity = -aim * 40.0

func _cast_nova() -> void:
	var nc := 28.0 * Prog.spell_cost_mult()
	if not Prog.ability("nova"):
		_locked_hint()
		return
	if light < nc or state != "move":
		return
	light -= nc
	var big := Prog.has_skill("l6")
	var r := 80.0 if big else 54.0
	world.bcast("cast_nova", [global_position, r, Prog.spell_damage(30.0 if not big else 38.0), Net.my_id(), big])

var _lock_t := 0

func _locked_hint() -> void:
	if Time.get_ticks_msec() - _lock_t > 1500:
		_lock_t = Time.get_ticks_msec()
		Audio.sfx("ui_move", -10.0)
		G.toast(G.L(["Aún no dominas esa habilidad.", "You haven't mastered that ability yet."]), Color(0.75, 0.7, 0.8))

func _cast_wrath() -> void:
	if not Prog.ability("wrath"):
		_locked_hint()
		return
	if wrath < 100.0 or state != "move":
		return
	wrath = 0.0
	iframes = 0.9
	state = "heavy"
	attack_t = 0.0
	attack_len = 0.6
	world.bcast("cast_wrath", [global_position, Prog.weapon_damage() * 4.0 + Prog.spell_damage(30.0), Net.my_id()])

# ====================================================================== recibir daño
## Devuelve "hit", "dodge", "perfect", "parry", "block" o "immune". Solo se llama en el dueño.
func take_hit(dmg: float, dir: Vector2, enemy_idx: int) -> String:
	if not is_alive() or cutscene:
		return "immune"
	if state == "dash" or iframes > 0.0:
		var since := Time.get_ticks_msec() - dash_start_ms
		var win := 120 if Prog.has_skill("a3") else 80
		if state == "dash" and since < win:
			_perfect_dodge()
			return "perfect"
		return "dodge"
	if state == "parry":
		if parry_window > 0.0:
			_parry_success(enemy_idx)
			return "parry"
		dmg *= 0.5
		stamina -= 15.0
	dmg *= Prog.damage_taken_mult()
	hp -= dmg
	if world.hud and world.hud.has_method("hurt_from"):
		world.hud.hurt_from(-dir)
		world.hud.combo_break()
	Audio.sfx("hurt")
	G.chroma(0.8, 0.25)
	G.shake(4.0, 0.2)
	G.flash(Color(1, 0.1, 0.1, 0.25), 0.15)
	_flash(1.0, Color(1, 0.3, 0.3))
	Fx.number(global_position, dmg, Color(1, 0.35, 0.35))
	Fx.burst(global_position + Vector2(0, -8), Color(1, 0.95, 0.9), 6, 80.0, 0.5, "fx_feather", 120.0, dir, 1.0, false, Vector2(0, 60))
	velocity = dir * 160.0
	if hp <= 0.0:
		if Prog.has_skill("c6") and not last_breath_used:
			last_breath_used = true
			hp = 1.0
			G.toast(G.L(Prog.SKILLS.c6.name), Color(1, 0.7, 0.4))
			iframes = 1.0
		else:
			hp = 0.0
			_on_zero_hp()
			return "hit"
	if state != "heal":
		state = "hurt"
		hurt_t = 0.22
	iframes = 0.35
	return "hit"

func _perfect_dodge() -> void:
	G.chroma(1.0, 0.5)
	Fx.text(global_position, G.T("perfect"), Color(0.6, 0.9, 1.0), 9)
	var oath_g := Prog.oath == "seravel"
	G.slowmo("instant", 0.3, (0.55 if Prog.has_skill("a3") else 0.4) * (2.0 if oath_g else 1.0))
	G.flash(Color(0.4, 0.7, 1.0, 0.18), 0.3)
	wrath = min(100.0, wrath + (30.0 if oath_g else 15.0))
	crit_next = true
	if Prog.synergy("wing_eye"):
		_hawk = true
	Audio.sfx("parry", -8.0)

func _parry_success(enemy_idx: int) -> void:
	Audio.sfx("parry")
	Fx.text(global_position, G.T("parry"), Color(1, 0.95, 0.6), 10)
	Fx.burst(global_position + aim * 10 + Vector2(0, -8), Color(1, 0.95, 0.7), 20, 140.0, 0.4, "fx_px", 60.0, aim)
	Fx.ring(global_position + Vector2(0, -8), 6.0, 30.0, Color(1, 0.95, 0.7), 0.25, 3.0)
	Fx.light_flash(global_position, Color(1, 0.95, 0.7), 2.0, 1.2, 0.3)
	G.hitstop(0.18, 0.02)
	G.flash(Color(1, 1, 1, 0.35), 0.1)
	G.shockwave(global_position + Vector2(0, -8), 1.3, 0.45)
	G.chroma(1.6, 0.35)
	Fx.impact(global_position + aim * 10 + Vector2(0, -8), Color(1, 0.95, 0.6), 30.0, 8)
	Fx.sparks(global_position + aim * 10 + Vector2(0, -8), aim, Color(1, 0.9, 0.5), 20, 220.0, 100.0)
	G.shake(3.0, 0.15)
	wrath = min(100.0, wrath + 20.0)
	crit_next = true
	parry_t = 0.0
	state = "move"
	iframes = 0.3
	if enemy_idx >= 0:
		world.request_parry_enemy(enemy_idx)
	if Prog.has_skill("c4"):
		world.bcast("cast_nova", [global_position, 48.0, Prog.spell_damage(20.0), Net.my_id(), false])

func _on_zero_hp() -> void:
	if Prog.item_count("phoenix") > 0:
		Prog.remove_item("phoenix")
		revive(0.5)
		G.flash(Color(1, 0.6, 0.2, 0.6), 0.6)
		G.shockwave(global_position, 2.0, 0.7)
		G.chroma(2.0, 0.6)
		Fx.burst(global_position + Vector2(0, -10), Color(1, 0.55, 0.15), 50, 160.0, 1.2, "fx_feather", 180.0, Vector2.UP, 1.4, false, Vector2(0, -40))
		Fx.text(global_position, G.L(["¡RENACER!", "REBORN!"]), Color(1, 0.7, 0.3), 12)
		return
	var partner_alive := false
	for p in world.players_list():
		if p != self and p.is_alive():
			partner_alive = true
	if Net.is_online() and partner_alive:
		state = "downed"
		downed_t = 25.0
		revive_progress = 0.0
		G.toast(G.T("downed"), Color(1, 0.5, 0.5))
	else:
		_die_for_real()

func _die_for_real() -> void:
	state = "dead"
	world.on_local_player_died(self)

func revive(ratio := 0.4) -> void:
	state = "move"
	hp = Prog.max_hp() * ratio
	iframes = 1.5
	Fx.burst(global_position, Color(1, 0.9, 0.5), 24, 90.0, 0.8, "fx_soft", 180.0, Vector2.UP, 0.5)
	Audio.sfx("heal")

func respawn_at(pos: Vector2) -> void:
	position = pos
	_net_pos = pos
	state = "move"
	velocity = Vector2.ZERO
	refresh_stats(true)
	sprite.rotation = 0.0
	modulate = Color.WHITE

# ====================================================================== visual
func _swing(arc: float, dur: float, cw: bool) -> void:
	var base := aim.angle()
	var a0 := base - deg_to_rad(arc / 2.0) * (1 if cw else -1)
	var a1 := base + deg_to_rad(arc / 2.0) * (1 if cw else -1)
	weapon_pivot.rotation = a0
	if _swing_tween:
		_swing_tween.kill()
	_swing_tween = create_tween()
	_swing_tween.tween_property(weapon_pivot, "rotation", a1, dur).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_interval(0.1)
	_weapon_rest = 0.25

func _update_weapon_visual(delta: float) -> void:
	_weapon_rest -= delta
	var swinging := _weapon_rest > 0.0 or state in ["attack", "heavy"]
	if state == "charge":
		var target := aim.angle() - PI * 0.75 * facing
		weapon_pivot.rotation = lerp_angle(weapon_pivot.rotation, target, clamp(delta * 12.0, 0.0, 1.0))
		weapon_spr.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.3, 0.8), heavy_charge)
	elif not swinging:
		var rest := aim.angle() + 1.1 * facing
		weapon_pivot.rotation = lerp_angle(weapon_pivot.rotation, rest, clamp(delta * 10.0, 0.0, 1.0))
		weapon_spr.modulate = Color.WHITE
	weapon_spr.flip_v = cos(weapon_pivot.rotation) < 0.0
	weapon_pivot.z_index = -1 if sin(weapon_pivot.rotation) < -0.3 else 1
	weapon_pivot.visible = state != "dead" and state != "downed"

func _update_orbit_visual(delta: float) -> void:
	if _orbit_nodes.is_empty():
		return
	orbit_angle += delta * 4.2
	for i in _orbit_nodes.size():
		var a := orbit_angle + i * TAU / _orbit_nodes.size()
		var s := _orbit_nodes[i]
		s.position = Vector2(cos(a), sin(a) * 0.6) * 24.0 + Vector2(0, -8)
		s.rotation = a + PI / 2.0
		if is_local() and is_alive():
			var gp := s.global_position
			for e in world.enemies_alive():
				var key := str(e.get_instance_id()) + "_" + str(i)
				if _orbit_hit.get(key, 0) > Time.get_ticks_msec():
					continue
				if e.global_position.distance_to(gp + Vector2(0, 6)) < e.body_radius + 6.0:
					_orbit_hit[key] = Time.get_ticks_msec() + 450
					world.request_damage_enemy(e, Prog.spell_damage(7.0), (e.global_position - global_position).normalized(), 2.0, false)
					Fx.burst(gp, Color(1, 0.6, 0.6), 4, 50.0, 0.3)

func _animate(delta: float) -> void:
	var want := "idle"
	match state:
		"move", "heal":
			want = "run" if velocity.length() > 20.0 else "idle"
		"attack", "heavy", "parry", "charge":
			want = "attack"
		"dash":
			want = "run"
		"hurt":
			want = "hurt"
		"downed", "dead":
			want = "dead"
	if not is_local():
		want = _anim
	if want != _anim:
		_anim = want
		_frame = 0.0
	var row: Array = ROWS[_anim]
	_frame += delta * row[2]
	var f := int(_frame) % int(row[1])
	if _anim == "attack":
		f = min(int(_frame), row[1] - 1)
	if _anim == "dead":
		f = 1
	sprite.region_rect = Rect2(f * FW, row[0] * FH, FW, FH)
	sprite.flip_h = facing < 0
	sprite.offset.y = -11.0 if sitting else -14.0
	if sitting:
		sprite.region_rect = Rect2(0, 0, FW, FH)
	# respiración y estiramiento suave
	sprite.scale = sprite.scale.lerp(Vector2.ONE, clamp(delta * 10.0, 0.0, 1.0))
	if state == "heal":
		sprite.modulate = Color(1.2, 1.0, 0.9)
	elif state == "downed":
		sprite.modulate = Color(0.7, 0.6, 0.7, 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.01))
	elif iframes > 0.0 and state != "dash" and int(Time.get_ticks_msec() / 60) % 2 == 0:
		sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		sprite.modulate = Color.WHITE
	var fl: float = _flash_mat.get_shader_parameter("flash")
	if fl > 0.0:
		_flash_mat.set_shader_parameter("flash", max(0.0, fl - delta * 6.0))

func _squash(s: Vector2) -> void:
	sprite.scale = s

func _flash(amount: float, color := Color.WHITE) -> void:
	_flash_mat.set_shader_parameter("flash", amount)
	_flash_mat.set_shader_parameter("flash_color", color)

# ====================================================================== red
@rpc("authority", "call_remote", "unreliable_ordered")
func _net_state(pos: Vector2, vel: Vector2, aim_a: float, st: String, anim: String, _fr: int, hp_ratio: float, fc: int, wid: String) -> void:
	_net_pos = pos
	velocity = vel
	aim = Vector2.from_angle(aim_a)
	state = st
	_anim = anim
	_net_hp_ratio = hp_ratio
	facing = fc
	if wid != _remote_weapon and Prog.WEAPONS.has(wid):
		_remote_weapon = wid
		_update_weapon_sprite()

@rpc("authority", "call_remote", "reliable")
func _net_fx(kind: String, args: Array) -> void:
	var col := Color(1, 0.95, 0.85, 0.85) if variant == 1 else Color(0.7, 0.95, 1, 0.85)
	match kind:
		"slash":
			aim = Vector2.from_angle(args[0])
			_swing(args[2], 0.1, args[4])
			if args[5]:
				_thrust_fx(args[1], col)
			else:
				Fx.slash(global_position + Vector2(0, -8), args[0], args[1] * 0.8, args[2], col, 14.0 if args[3] else 9.0, 0.2, args[4])
			Audio.sfx("swing", -6.0)
		"heavy":
			aim = Vector2.from_angle(args[0])
			_swing(args[2], 0.12, true)
			Fx.slash(global_position + Vector2(0, -8), args[0], args[1] * 0.85, args[2], Color(1, 0.8, 0.45, 0.95), 16.0, 0.28, true)
			Audio.sfx("swing_heavy", -6.0)
		"dash":
			world.note_dash(peer_id, global_position, args[0])
			Fx.burst(global_position, Color(0.8, 0.8, 0.9, 0.7), 8, 60.0, 0.4, "fx_soft", 40.0, -args[0], 0.35, false)
			for i in 5:
				get_tree().create_timer(i * 0.03).timeout.connect(_remote_afterimage.bind(Color(col.r, col.g, col.b, 0.5)))
			Audio.sfx("dash", -6.0)
		"parry":
			Fx.ring(global_position + Vector2(0, -8), 4.0, 16.0, Color(0.8, 0.9, 1.0), 0.15, 2.0)

func _remote_afterimage(c: Color) -> void:
	if is_inside_tree():
		Fx.afterimage(sprite, sprite.global_position, c)

func hp_ratio() -> float:
	return hp / Prog.max_hp() if is_local() else _net_hp_ratio

@rpc("any_peer", "call_remote", "reliable")
func _net_revive() -> void:
	if is_local() and state == "downed":
		revive(0.4)

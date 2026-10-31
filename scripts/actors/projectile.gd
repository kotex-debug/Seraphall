class_name Projectile
extends Node2D
## Proyectil simulado en todos los clientes. Los impactos los decide quien "posee" el objetivo:
## - proyectiles enemigos: cada cliente comprueba solo su jugador local.
## - proyectiles de jugador: solo el cliente que lo lanzó comprueba enemigos.

var team := "enemy"          # "enemy" | "player"
var owner_peer := 1
var vel := Vector2.ZERO
var accel := 0.0
var damage := 10.0
var radius := 5.0
var life := 3.0
var pierce := 0
var poise := 6.0
var kind := "orb"            # orb | red | lance | sword | wave
var delay := 0.0             # tiempo quieto antes de moverse (espadas del jefe)
var target_pos := Vector2.INF  # si delay > 0, al terminar apunta aquí
var speed_after := 0.0
var _hit := {}
var _spr: Sprite2D
var _light: PointLight2D
var _t := 0.0
var _trail: Array[Vector2] = []
var _col := Color.WHITE

func _ready() -> void:
	z_index = 12
	_spr = Sprite2D.new()
	var col := Color.WHITE
	match kind:
		"lance":
			_spr.texture = Fx.tex("proj_lance"); col = Color(1, 0.9, 0.55)
		"sword":
			_spr.texture = Fx.tex("proj_sword"); col = Color(1, 0.4, 0.45)
		"red":
			_spr.texture = Fx.tex("proj_red"); col = Color(1, 0.3, 0.3)
		"wave":
			_spr.texture = Fx.tex("fx_soft"); col = Color(1, 0.95, 0.7); _spr.scale = Vector2(1.6, 2.6)
			_spr.material = Fx.add_material()
		_:
			_spr.texture = Fx.tex("proj_orb"); col = Color(0.75, 0.4, 1)
	add_child(_spr)
	_light = PointLight2D.new()
	_light.texture = Fx.tex("light")
	_light.texture_scale = 0.35
	_light.energy = 0.9
	_light.color = col
	add_child(_light)
	_col = col
	rotation = vel.angle()
	material = Fx.add_material()

func _physics_process(delta: float) -> void:
	_t += delta
	if delay > 0.0:
		delay -= delta
		_spr.modulate.a = 0.5 + 0.5 * sin(_t * 30.0)
		if delay <= 0.0:
			_spr.modulate.a = 1.0
			if target_pos != Vector2.INF:
				vel = (target_pos - global_position).normalized() * speed_after
				rotation = vel.angle()
			Audio.sfx("enemy_shot", -6.0)
		return
	if accel != 0.0:
		vel += vel.normalized() * accel * delta
	position += vel * delta
	_trail.push_front(global_position)
	if _trail.size() > (10 if kind == "lance" else 6):
		_trail.pop_back()
	queue_redraw()
	life -= delta
	if life <= 0.0:
		_die(false)
		return
	if kind == "wave":
		_spr.modulate.a = clamp(life * 3.0, 0.0, 1.0)
	_check_hits()
	_check_walls()

func _check_walls() -> void:
	var w := get_tree().root.get_node_or_null("Main/World")
	if w and kind != "wave" and w.is_wall_at(global_position):
		_die(true)

func _check_hits() -> void:
	var w := get_tree().root.get_node_or_null("Main/World")
	if w == null:
		return
	if team == "enemy":
		for p in w.local_players():
			if p.is_alive() and not _hit.has(p) and p.global_position.distance_to(global_position + Vector2(0, 0)) < radius + 7.0:
				_hit[p] = true
				var res: String = p.take_hit(damage, vel.normalized(), -1)
				if res == "parry":
					vel = -vel * 1.3
					team = "player"
					owner_peer = Net.my_id()
					_hit.clear()
					return
				if res != "dodge":
					_die(true)
					return
	else:
		if owner_peer != Net.my_id():
			return
		for e in w.enemies_alive():
			if not _hit.has(e) and e.global_position.distance_to(global_position) < radius + e.body_radius:
				_hit[e] = true
				w.request_damage_enemy(e, damage, vel.normalized(), poise, false)
				Fx.burst(global_position, Color(1, 0.9, 0.6), 8, 70.0)
				if pierce <= 0:
					_die(true)
					return
				pierce -= 1

func _draw() -> void:
	if kind == "wave":
		return
	var n := _trail.size()
	for i in range(1, n):
		var a := 1.0 - float(i) / n
		var p1 := to_local(_trail[i - 1])
		var p2 := to_local(_trail[i])
		draw_line(p1, p2, Color(_col, a * 0.8), (3.5 if kind == "lance" else 2.5) * a + 0.5)
	if n > 1:
		draw_line(Vector2.ZERO, to_local(_trail[min(2, n - 1)]), Color(1, 1, 1, 0.8), 1.0)

func _die(hit: bool) -> void:
	if hit:
		var c := _light.color
		Fx.burst(global_position, c, 10, 60.0, 0.35)
		Fx.impact(global_position, c, 12.0, 6)
		Fx.sparks(global_position, -vel.normalized(), c, 8, 120.0, 120.0)
	queue_free()

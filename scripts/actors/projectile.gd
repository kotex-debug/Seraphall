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
var homing := 0.0
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
		"gfeather":
			_spr.texture = Fx.tex("proj_gfeather"); col = Color(1, 0.82, 0.4)
			_spr.scale = Vector2(1.1, 1.1)
		"sword":
			_spr.texture = Fx.tex("proj_sword"); col = Color(1, 0.4, 0.45)
		"red":
			_spr.texture = Fx.tex("proj_red"); col = Color(1, 0.3, 0.3)
		"feather":
			_spr.texture = Fx.tex("fx_feather"); col = Color(1, 0.95, 0.9); _spr.scale = Vector2(1.5, 1.5)
		"note":
			_spr.texture = Fx.tex("proj_note"); col = Color(0.75, 0.55, 1.0)
		"dawn":
			_spr.texture = Fx.tex("proj_orb"); col = Color(1, 0.85, 0.45)
			_spr.modulate = Color(1.0, 0.9, 0.5)
			_spr.material = Fx.add_material()
		"wave":
			_spr.texture = Fx.tex("fx_soft"); col = Color(1, 0.95, 0.7); _spr.scale = Vector2(1.6, 2.6)
			_spr.material = Fx.add_material()
		"halo":
			_spr.texture = Fx.tex("fx_soft"); col = Color(1, 0.55, 0.2); _spr.scale = Vector2(1.5, 1.5)
			_spr.modulate = Color(1, 0.6, 0.25)
			_spr.material = Fx.add_material()
		"verdict":
			_spr.texture = Fx.tex("fx_soft"); col = Color(1, 0.25, 0.35); _spr.scale = Vector2(1.8, 3.0)
			_spr.modulate = Color(1, 0.3, 0.4)
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
	if has_meta("boomerang") and not has_meta("returning") and vel.length() < 30.0:
		# las aureolas de Vulkaris se frenan y vuelven hacia él
		set_meta("returning", true)
		accel = 0.0
		var home: Vector2 = get_meta("boomerang")
		vel = (home - global_position).normalized() * 250.0
		_hit.clear()
	if kind == "gfeather":
		_gfeather_tick(delta)
		if not is_inside_tree() or _dead:
			return
	if accel != 0.0:
		vel += vel.normalized() * accel * delta
	if homing > 0.0 and team == "enemy":
		var w := get_tree().root.get_node_or_null("Main/World")
		if w:
			var lp: Node2D = w.local_player()
			if lp:
				var want := (lp.global_position + Vector2(0, -6) - global_position).angle()
				vel = vel.rotated(clamp(wrapf(want - vel.angle(), -PI, PI), -homing * delta, homing * delta))
				rotation = vel.angle()
	position += vel * delta
	_trail.push_front(global_position)
	if _trail.size() > (14 if kind == "gfeather" else (10 if kind == "lance" else 6)):
		_trail.pop_back()
	queue_redraw()
	life -= delta
	if life <= 0.0:
		_die(false)
		return
	if kind == "wave" or kind == "verdict":
		_spr.modulate.a = clamp(life * 3.0, 0.0, 1.0)
	_check_hits()
	_check_walls()

func _check_walls() -> void:
	var w := get_tree().root.get_node_or_null("Main/World")
	if w and kind != "wave" and w.is_wall_at(global_position) and not w.is_pit_at(global_position):
		if kind == "gfeather":
			# la Pluma Dorada no se rompe contra los muros: vuelve a tu mano
			if not _returning:
				_returning = true
				_hit.clear()
				Fx.sparks(global_position, -vel.normalized(), Color(1, 0.85, 0.4), 8, 120.0, 80.0)
			return
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
					# devolver la luz enemiga: vuelve más rápida y el doble de fuerte hacia el enemigo más cercano
					var tgt: Node2D = null
					var bd := 400.0
					for e in w.enemies_alive():
						var dd: float = e.global_position.distance_to(global_position)
						if dd < bd:
							bd = dd
							tgt = e
					var spd := vel.length() * 1.6
					vel = ((tgt.global_position + Vector2(0, -8) - global_position).normalized() * spd) if tgt else -vel * 1.6
					damage *= 2.2
					team = "player"
					owner_peer = Net.my_id()
					life = max(life, 1.5)
					_hit.clear()
					Fx.text(global_position, G.T("reflect"), Color(1, 0.95, 0.6), 9)
					Fx.ring(global_position, 3.0, 22.0, Color(1, 0.95, 0.7), 0.25, 3.0)
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
				if kind == "gfeather":
					_gfeather_hit(w, e)
					continue
				if pierce <= 0:
					_die(true)
					return
				pierce -= 1

func _draw() -> void:
	if kind == "wave":
		return
	if kind == "halo":
		# anillo al rojo que gira
		draw_set_transform(Vector2.ZERO, -rotation + _t * 9.0, Vector2(1.0, 0.55))
		draw_arc(Vector2.ZERO, 7.0, 0, TAU, 18, Color(0.6, 0.15, 0.05), 4.0)
		draw_arc(Vector2.ZERO, 7.0, 0, TAU, 18, Color(1, 0.6, 0.2), 2.0)
		draw_arc(Vector2.ZERO, 7.0, 0.3, 1.4, 6, Color(1, 0.95, 0.7), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var n := _trail.size()
	for i in range(1, n):
		var a := 1.0 - float(i) / n
		var p1 := to_local(_trail[i - 1])
		var p2 := to_local(_trail[i])
		draw_line(p1, p2, Color(_col, a * 0.8), (3.5 if kind == "lance" else 2.5) * a + 0.5)
	if n > 1:
		draw_line(Vector2.ZERO, to_local(_trail[min(2, n - 1)]), Color(1, 1, 1, 0.8), 1.0)

# ------------------------------------------------------------------ Pluma Dorada
var _returning := false
var _dead := false

func _gfeather_tick(delta: float) -> void:
	var w := get_tree().root.get_node_or_null("Main/World")
	if w == null:
		return
	if randf() < 0.45:
		Fx.burst(global_position, Color(1, 0.85, 0.45), 1, 16.0, 0.5, "fx_feather", 180.0, -vel.normalized(), 0.6, false, Vector2(0, 20))
	var own: Node2D = w.players.get(owner_peer)
	if not _returning:
		# busca un poco al enemigo que tenga delante
		var best: Node2D = null
		var bd := 130.0
		for e in w.enemies_alive():
			if _hit.has(e):
				continue
			var to: Vector2 = e.global_position + Vector2(0, -6) - global_position
			if to.length() < bd and vel.normalized().dot(to.normalized()) > 0.4:
				bd = to.length()
				best = e
		if best:
			var turn := 7.0 if Prog.has_skill("l7") and owner_peer == Net.my_id() else 3.5
			var want := (best.global_position + Vector2(0, -6) - global_position).angle()
			vel = vel.rotated(clampf(wrapf(want - vel.angle(), -PI, PI), -turn * delta, turn * delta))
		if _t > 0.55:
			_returning = true
			_hit.clear()
		rotation = vel.angle()
	else:
		if own == null or not is_instance_valid(own):
			_die(false)
			_dead = true
			return
		var back: Vector2 = own.global_position + Vector2(0, -8) - global_position
		if back.length() < 14.0:
			if owner_peer == Net.my_id():
				own.light = minf(Prog.max_light(), own.light + 3.0)
				Audio.sfx("pickup", -10.0, 0.2)
			Fx.ring(global_position, 2.0, 12.0, Color(1, 0.85, 0.45), 0.2, 2.0)
			_dead = true
			queue_free()
			return
		vel = vel.lerp(back.normalized() * 470.0, clampf(delta * 8.0, 0.0, 1.0))
		rotation += delta * 18.0
		life = maxf(life, 0.5)

func _gfeather_hit(w: Node, e: Node2D) -> void:
	## Se clava y estalla en esquirlas de oro
	Audio.sfx("hit_heavy", -8.0, 0.2)
	Fx.light_flash(global_position, Color(1, 0.85, 0.45), 1.3, 0.8, 0.2)
	Fx.burst(global_position, Color(1, 0.85, 0.45), 10, 110.0, 0.5, "fx_feather", 180.0, Vector2.UP, 0.9, false, Vector2(0, 50))
	if Prog.has_skill("k3"):
		w.request_status(e, "slow", 2.5)
	for k in 3:
		var a: float = vel.angle() + (k - 1) * 0.7
		w.spawn_projectile_local(global_position, Vector2.from_angle(a) * 240.0, damage * 0.25, "feather", "player", owner_peer, 4.0, 0.35, 0)
	pierce -= 1
	if pierce <= 0 and not _returning:
		_returning = true
		_hit.clear()

func _die(hit: bool) -> void:
	if hit:
		var c := _light.color
		Fx.burst(global_position, c, 10, 60.0, 0.35)
		Fx.impact(global_position, c, 12.0, 6)
		Fx.sparks(global_position, -vel.normalized(), c, 8, 120.0, 120.0)
	queue_free()

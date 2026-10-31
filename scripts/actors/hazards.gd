class_name Haz
extends RefCounted
## Peligros de jefes que se simulan en todos los clientes; cada cliente solo comprueba su jugador local.

static func world() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Main/World")

static func _add(n: Node) -> void:
	var w := world()
	if w:
		w.get_node("FX").add_child(n)

## Anillo expansivo: hay que atravesarlo con el dash.
static func ring_wave(pos: Vector2, r0: float, r1: float, dur: float, dmg: float, color := Color(1, 0.5, 0.3), thick := 9.0, enemy_idx := -1) -> void:
	var r := RingWave.new()
	r.position = pos
	r.r0 = r0
	r.r1 = r1
	r.duration = dur
	r.dmg = dmg
	r.color = color
	r.thick = thick
	r.enemy_idx = enemy_idx
	_add(r)

## Rayos que giran alrededor de un nodo (aureola de Seravel, armonía del Coro)
static func beams(follow: Node2D, count: int, length: float, ang_speed: float, warn: float, active: float, dmg: float, color: Color, start_angle := 0.0, offset := Vector2.ZERO, enemy_idx := -1) -> Node2D:
	var b := BeamFx.new()
	b.follow = follow
	b.count = count
	b.length = length
	b.ang_speed = ang_speed
	b.warn = warn
	b.active = active
	b.dmg = dmg
	b.color = color
	b.angle = start_angle
	b.offset = offset
	b.enemy_idx = enemy_idx
	_add(b)
	return b

## Línea que estalla tras un aviso (cruces del Juicio)
static func line_blast(a: Vector2, b: Vector2, width: float, warn: float, dmg: float, color := Color(1, 0.85, 0.4), enemy_idx := -1) -> void:
	var l := LineBlast.new()
	l.a = a
	l.b = b
	l.width = width
	l.warn = warn
	l.dmg = dmg
	l.color = color
	l.enemy_idx = enemy_idx
	_add(l)

## Haz entre dos nodos (dos cantores del Coro)
static func link_beam(n1: Node2D, n2: Node2D, dur: float, dmg: float, color: Color, enemy_idx := -1) -> void:
	var l := LinkBeam.new()
	l.n1 = n1
	l.n2 = n2
	l.duration = dur
	l.dmg = dmg
	l.color = color
	l.enemy_idx = enemy_idx
	_add(l)

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = clamp((p - a).dot(ab) / max(0.001, ab.length_squared()), 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func hit_local(pos_check: Callable, dmg: float, from: Vector2, enemy_idx: int, cooldowns: Dictionary, cd := 0.45) -> void:
	var w := world()
	if w == null:
		return
	for p in w.local_players():
		if not p.is_alive():
			continue
		if cooldowns.get(p, 0) > Time.get_ticks_msec():
			continue
		if pos_check.call(p.global_position + Vector2(0, -6)):
			cooldowns[p] = Time.get_ticks_msec() + int(cd * 1000.0)
			p.take_hit(dmg, (p.global_position - from).normalized(), enemy_idx)


class RingWave extends Node2D:
	var r0 := 10.0
	var r1 := 160.0
	var duration := 1.2
	var dmg := 15.0
	var color := Color(1, 0.5, 0.3)
	var thick := 9.0
	var enemy_idx := -1
	var t := 0.0
	var _cd := {}
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 13
	func _process(delta: float) -> void:
		t += delta
		if t >= duration:
			queue_free()
			return
		var r := lerpf(r0, r1, t / duration)
		Haz.hit_local(func(p): return absf(p.distance_to(global_position) - r) < thick * 0.5 + 4.0, dmg, global_position, enemy_idx, _cd, 99.0)
		queue_redraw()
	func _draw() -> void:
		var k := t / duration
		var r := lerpf(r0, r1, k)
		var a := 1.0 - k * 0.6
		draw_arc(Vector2.ZERO, r, 0, TAU, 72, Color(color, 0.35 * a), thick + 6.0)
		draw_arc(Vector2.ZERO, r, 0, TAU, 72, Color(color, a), thick * 0.6)
		draw_arc(Vector2.ZERO, r, 0, TAU, 72, Color(1, 1, 1, a), 1.5)

class BeamFx extends Node2D:
	var follow: Node2D
	var count := 2
	var length := 220.0
	var ang_speed := 1.2
	var warn := 0.8
	var active := 3.0
	var dmg := 12.0
	var color := Color(1, 0.85, 0.4)
	var angle := 0.0
	var offset := Vector2.ZERO
	var enemy_idx := -1
	var t := 0.0
	var _cd := {}
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 14
	func _process(delta: float) -> void:
		t += delta
		if follow == null or not is_instance_valid(follow) or t > warn + active:
			queue_free()
			return
		global_position = follow.global_position + offset
		if t > warn:
			angle += ang_speed * delta
			for i in count:
				var a := angle + TAU * i / count
				var e := global_position + Vector2.from_angle(a) * length
				var s := global_position
				Haz.hit_local(func(p): return Haz.seg_dist(p, s, e) < 7.0, dmg, global_position, enemy_idx, _cd)
		queue_redraw()
	func _draw() -> void:
		for i in count:
			var a := angle + TAU * i / count
			var d := Vector2.from_angle(a)
			if t < warn:
				var c := Color(1, 0.2, 0.2, 0.3 + 0.3 * sin(t * 30.0))
				draw_line(Vector2.ZERO, d * length, c, 1.0)
			else:
				var fl := 0.8 + 0.2 * sin(t * 40.0 + i)
				draw_line(Vector2.ZERO, d * length, Color(color, 0.35 * fl), 14.0)
				draw_line(Vector2.ZERO, d * length, Color(color, fl), 6.0)
				draw_line(Vector2.ZERO, d * length, Color(1, 1, 1, fl), 2.0)
				draw_circle(d * length, 5.0, Color(color, fl))

class LineBlast extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var width := 18.0
	var warn := 0.9
	var dmg := 20.0
	var color := Color(1, 0.85, 0.4)
	var enemy_idx := -1
	var t := 0.0
	var _done := false
	var _cd := {}
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 12
	func _process(delta: float) -> void:
		t += delta
		if t >= warn and not _done:
			_done = true
			var aa := a
			var bb := b
			Haz.hit_local(func(p): return Haz.seg_dist(p, aa, bb) < width * 0.5 + 4.0, dmg, (a + b) / 2.0, enemy_idx, _cd)
			Audio.sfx("hit_heavy", -8.0)
			G.shake(2.0, 0.12)
			for k in 6:
				Fx.burst(a.lerp(b, k / 5.0), color, 4, 70.0, 0.4, "fx_px", 180.0)
		if t > warn + 0.35:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		if t < warn:
			var c := Color(1, 0.25, 0.2, 0.15 + 0.1 * sin(t * 25.0))
			var d := (b - a).normalized().orthogonal() * width * 0.5
			draw_colored_polygon(PackedVector2Array([a + d, b + d, b - d, a - d]), c)
			var p := a.lerp(b, t / warn)
			draw_line(a, p, Color(1, 0.4, 0.3, 0.8), 1.0)
		else:
			var k := (t - warn) / 0.35
			var d2 := (b - a).normalized().orthogonal() * width * 0.5 * (1.0 - k)
			draw_colored_polygon(PackedVector2Array([a + d2, b + d2, b - d2, a - d2]), Color(color, 1.0 - k))
			draw_line(a, b, Color(1, 1, 1, 1.0 - k), 2.0)

class LinkBeam extends Node2D:
	var n1: Node2D
	var n2: Node2D
	var duration := 2.0
	var dmg := 12.0
	var color := Color(0.8, 0.6, 1.0)
	var enemy_idx := -1
	var t := 0.0
	var _cd := {}
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 14
	func _process(delta: float) -> void:
		t += delta
		if t > duration or n1 == null or n2 == null or not is_instance_valid(n1) or not is_instance_valid(n2):
			queue_free()
			return
		if t > 0.5:
			var a := n1.global_position
			var b := n2.global_position
			Haz.hit_local(func(p): return Haz.seg_dist(p, a, b) < 7.0, dmg, (a + b) / 2.0, enemy_idx, _cd)
		queue_redraw()
	func _draw() -> void:
		if n1 == null or not is_instance_valid(n1) or not is_instance_valid(n2):
			return
		var a := n1.global_position - global_position
		var b := n2.global_position - global_position
		if t < 0.5:
			draw_line(a, b, Color(1, 0.3, 0.3, 0.4 + 0.3 * sin(t * 30.0)), 1.0)
		else:
			var fl := 0.8 + 0.2 * sin(t * 35.0)
			draw_line(a, b, Color(color, 0.35 * fl), 12.0)
			draw_line(a, b, Color(color, fl), 5.0)
			draw_line(a, b, Color(1, 1, 1, fl), 1.5)

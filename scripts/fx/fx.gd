class_name Fx
extends RefCounted
## Efectos visuales reutilizables: partículas, arcos de corte, números de daño, estelas, luces.

static var _tex := {}
static var _flash_shader: Shader
static var _add_mat: CanvasItemMaterial

static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://assets/sprites/%s.png" % name)
	return _tex[name]

static func add_material() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat

static func flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec4 c = COLOR;
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	if (dissolve > 0.0) {
		float n = h(floor(UV * 64.0));
		if (n < dissolve) { c.a = 0.0; }
		else if (n < dissolve + 0.08) { c.rgb = vec3(1.0, 0.7, 0.3); }
	}
	COLOR = c;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _flash_shader
	m.set_shader_parameter("flash", 0.0)
	m.set_shader_parameter("dissolve", 0.0)
	m.set_shader_parameter("flash_color", Color.WHITE)
	return m

static func world() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var w := tree.root.get_node_or_null("Main/World")
	return w.get_node("FX") if w else tree.root

## Explosión de partículas
static func burst(pos: Vector2, color: Color, amount := 14, speed := 90.0, life := 0.45, texture := "fx_px", spread := 180.0, dir := Vector2.RIGHT, scale := 1.0, additive := true, gravity := Vector2.ZERO) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.texture = tex(texture)
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.6
	p.gravity = gravity
	p.scale_amount_min = scale * 0.6
	p.scale_amount_max = scale * 1.3
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color.r, color.g * 0.6, color.b * 0.4, 0.0))
	p.color_ramp = g
	if additive:
		p.material = add_material()
	p.z_index = 20
	world().add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

## Arco de corte fluido (media luna que barre y se desvanece)
static func slash(pos: Vector2, angle: float, radius: float, arc_deg: float, color: Color, width := 10.0, dur := 0.18, clockwise := true) -> Node2D:
	var s := SlashArc.new()
	s.position = pos
	s.rotation = angle
	s.radius = radius
	s.arc = deg_to_rad(arc_deg)
	s.color = color
	s.width = width
	s.duration = dur
	s.clockwise = clockwise
	world().add_child(s)
	return s

## Anillo expansivo (ondas, novas, aterrizajes)
static func ring(pos: Vector2, from_r: float, to_r: float, color: Color, dur := 0.35, thick := 4.0) -> void:
	var r := RingFx.new()
	r.position = pos
	r.r0 = from_r
	r.r1 = to_r
	r.color = color
	r.duration = dur
	r.thick = thick
	world().add_child(r)

## Número de daño flotante
static func number(pos: Vector2, value: float, color := Color.WHITE, big := false) -> void:
	var l := Label.new()
	l.text = str(int(round(value)))
	var ls := LabelSettings.new()
	ls.font_size = 12 if big else 9
	ls.font_color = color
	ls.outline_size = 3
	ls.outline_color = Color(0.05, 0.02, 0.06)
	l.label_settings = ls
	l.position = pos + Vector2(randf_range(-6, 6) - 8, -22)
	l.z_index = 50
	world().add_child(l)
	l.pivot_offset = Vector2(8, 6)
	l.scale = Vector2(1.6, 1.6) if big else Vector2(1.25, 1.25)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(l, "position:y", l.position.y - 18, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)

static func text(pos: Vector2, t: String, color := Color(1, 0.9, 0.5), size := 10) -> void:
	var l := Label.new()
	l.text = t
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 4
	ls.outline_color = Color(0.05, 0.02, 0.06)
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(120, 16)
	l.position = pos + Vector2(-60, -40)
	l.z_index = 51
	world().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 14, 0.9).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.tween_callback(l.queue_free)

## Estrella de impacto: destello con púas afiladas (1-3 frames de "impact frame")
static func impact(pos: Vector2, color: Color, size := 18.0, spikes := 6) -> void:
	var s := ImpactStar.new()
	s.position = pos
	s.color = color
	s.size = size
	s.spikes = spikes
	s.rotation = randf() * TAU
	world().add_child(s)

## Chispas direccionales dibujadas como trazos (con arrastre y gravedad)
static func sparks(pos: Vector2, dir: Vector2, color: Color, count := 10, speed := 160.0, spread_deg := 70.0, gravity := 220.0) -> void:
	var s := SparkFx.new()
	s.position = pos
	s.color = color
	s.gravity = gravity
	for i in count:
		var a := dir.angle() + deg_to_rad(randf_range(-spread_deg, spread_deg) * 0.5)
		s.parts.append([Vector2.ZERO, Vector2.from_angle(a) * speed * randf_range(0.4, 1.0), randf_range(0.25, 0.5)])
	world().add_child(s)

## Almas/ecos que vuelan hacia el jugador
static func souls(pos: Vector2, target: Node2D, count := 5) -> void:
	if target == null:
		return
	for i in count:
		var o := SoulOrb.new()
		o.position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		o.target = target
		o.vel = Vector2.from_angle(randf() * TAU) * randf_range(60, 140) + Vector2(0, -60)
		o.delay = i * 0.04 + 0.15
		world().add_child(o)

## Mancha de quemado en el suelo que se desvanece
static func scorch(pos: Vector2, radius: float) -> void:
	var s := ScorchFx.new()
	s.position = pos
	s.radius = radius
	world().add_child(s)

## Imagen residual (estela del dash)
static func afterimage(sprite: Sprite2D, global_pos: Vector2, color: Color, dur := 0.25) -> void:
	if sprite == null or sprite.texture == null:
		return
	var s := Sprite2D.new()
	s.texture = sprite.texture
	s.region_enabled = sprite.region_enabled
	s.region_rect = sprite.region_rect
	s.flip_h = sprite.flip_h
	s.offset = sprite.offset
	s.global_position = global_pos
	s.scale = sprite.global_scale
	s.modulate = color
	s.material = add_material()
	s.z_index = -1
	world().add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, dur)
	tw.tween_callback(s.queue_free)

## Destello de luz breve
static func light_flash(pos: Vector2, color: Color, energy := 1.4, scale := 1.2, dur := 0.25) -> void:
	var l := PointLight2D.new()
	l.texture = tex("light")
	l.color = color
	l.energy = energy
	l.texture_scale = scale
	l.position = pos
	world().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, dur)
	tw.tween_callback(l.queue_free)

## Marca de aviso en el suelo (telegráfico)
static func telegraph_circle(pos: Vector2, radius: float, dur: float, color := Color(1, 0.2, 0.2)) -> Node2D:
	var t := TelegraphFx.new()
	t.position = pos
	t.radius = radius
	t.duration = dur
	t.color = color
	world().add_child(t)
	return t

static func telegraph_line(pos: Vector2, angle: float, length: float, width: float, dur: float, color := Color(1, 0.2, 0.2)) -> Node2D:
	var t := TelegraphFx.new()
	t.position = pos
	t.rotation = angle
	t.line_len = length
	t.line_w = width
	t.duration = dur
	t.color = color
	world().add_child(t)
	return t


# ====================================================================== clases internas
class SlashArc extends Node2D:
	var radius := 30.0
	var arc := PI * 0.6
	var color := Color.WHITE
	var width := 10.0
	var duration := 0.18
	var clockwise := true
	var t := 0.0

	func _ready() -> void:
		material = Fx.add_material()
		z_index = 15

	func _process(delta: float) -> void:
		t += delta
		if t >= duration:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var p: float = clamp(t / duration, 0.0, 1.0)
		var sweep: float = clamp(p * 2.2, 0.0, 1.0)  # el barrido avanza rápido
		var fade: float = 1.0 - clamp((p - 0.35) / 0.65, 0.0, 1.0)
		var steps := 18
		var a0 := -arc / 2.0
		var dirm := 1.0 if clockwise else -1.0
		var head := a0 + arc * sweep
		var tail: float = a0 + arc * clamp(sweep - 0.75, 0.0, 1.0) + arc * p * 0.25
		if head <= tail:
			return
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in steps + 1:
			var k := float(i) / steps
			var a := lerpf(tail, head, k) * dirm
			var w := maxf(0.3, width * sin(k * PI) * (0.4 + 0.6 * k) * fade)
			outer.append(Vector2(cos(a), sin(a)) * (radius + w * 0.3))
			inner.append(Vector2(cos(a), sin(a)) * (radius - w))
		var c := color
		c.a *= fade
		# capa de resplandor exterior
		var gc := Color(color.r, color.g * 0.8, color.b * 0.6, 0.28 * fade)
		for i in steps:
			var o1 := outer[i] * 1.12
			var o2 := outer[i + 1] * 1.12
			draw_colored_polygon(PackedVector2Array([o1, o2, inner[i + 1] * 0.92, inner[i] * 0.92]), gc)
		for i in steps:
			draw_colored_polygon(PackedVector2Array([outer[i], outer[i + 1], inner[i + 1], inner[i]]), c)
		# núcleo blanco caliente
		var hot := Color(1, 1, 1, 0.75 * fade)
		for i in steps:
			var m1 := outer[i].lerp(inner[i], 0.25)
			var m2 := outer[i + 1].lerp(inner[i + 1], 0.25)
			draw_colored_polygon(PackedVector2Array([outer[i], outer[i + 1], m2, m1]), hot)
		# filo brillante
		var c2 := Color(1, 1, 1, 0.9 * fade)
		draw_polyline(outer, c2, 1.0)

class RingFx extends Node2D:
	var r0 := 4.0
	var r1 := 40.0
	var color := Color.WHITE
	var duration := 0.35
	var thick := 4.0
	var t := 0.0

	func _ready() -> void:
		material = Fx.add_material()
		z_index = 14

	func _process(delta: float) -> void:
		t += delta
		if t >= duration:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var p: float = clamp(t / duration, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - p, 3.0)
		var r := lerpf(r0, r1, e)
		var c := color
		c.a *= 1.0 - p
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, c, max(1.0, thick * (1.0 - p)))
		c.a *= 0.1
		draw_circle(Vector2.ZERO, r, c)

class TelegraphFx extends Node2D:
	var radius := 0.0
	var line_len := 0.0
	var line_w := 0.0
	var duration := 0.6
	var color := Color(1, 0.2, 0.2)
	var t := 0.0

	func _ready() -> void:
		z_index = -5

	func _process(delta: float) -> void:
		t += delta
		if t >= duration:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var p: float = clamp(t / duration, 0.0, 1.0)
		var boost = G.tele_boost or (G.has_meta("lightwing") and G.get_meta("lightwing"))
		var c := color
		c.a = (0.18 + 0.12 * sin(t * 30.0)) * (1.8 if boost else 1.0)
		var edge := color
		edge.a = 0.8
		var ew := 3.0 if boost else 1.0
		if radius > 0.0:
			draw_circle(Vector2.ZERO, radius, c)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 40, edge, ew)
			if boost:
				draw_arc(Vector2.ZERO, radius + 3.0, 0, TAU, 40, Color(1, 1, 1, 0.6 + 0.3 * sin(t * 20.0)), 1.0)
			var fill := color
			fill.a = 0.35
			draw_circle(Vector2.ZERO, radius * p, fill)
		else:
			draw_rect(Rect2(0, -line_w / 2, line_len, line_w), c)
			draw_rect(Rect2(0, -line_w / 2, line_len, line_w), edge, false, ew)
			var fill2 := color
			fill2.a = 0.35
			draw_rect(Rect2(0, -line_w / 2, line_len * p, line_w), fill2)


class ImpactStar extends Node2D:
	var color := Color.WHITE
	var size := 18.0
	var spikes := 6
	var t := 0.0
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 25
	func _process(delta: float) -> void:
		t += delta
		if t > 0.16:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / 0.16
		var r := size * (0.6 + 0.6 * k)
		var a := 1.0 - k
		for i in spikes:
			var ang := TAU * i / spikes
			var l := r * (1.0 if i % 2 == 0 else 0.55)
			var d := Vector2.from_angle(ang)
			var p := d.orthogonal() * (2.5 * (1.0 - k) + 0.5)
			draw_colored_polygon(PackedVector2Array([p, d * l, -p]), Color(1, 1, 1, a))
			draw_colored_polygon(PackedVector2Array([p * 2.0, d * l * 1.15, -p * 2.0]), Color(color, a * 0.45))
		draw_circle(Vector2.ZERO, size * 0.35 * (1.0 - k), Color(1, 1, 1, a))

class SparkFx extends Node2D:
	var parts := []   # [pos, vel, life]
	var color := Color.WHITE
	var gravity := 220.0
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 24
	func _process(delta: float) -> void:
		var alive := false
		for p in parts:
			if p[2] > 0.0:
				alive = true
				p[2] -= delta
				p[1] *= pow(0.02, delta)
				p[1].y += gravity * delta
				p[0] += p[1] * delta
		if not alive:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		for p in parts:
			if p[2] <= 0.0:
				continue
			var v: Vector2 = p[1]
			var tail: Vector2 = p[0] - v * 0.035
			var a: float = clamp(p[2] * 3.0, 0.0, 1.0)
			draw_line(tail, p[0], Color(color, a), 1.5)
			draw_rect(Rect2(p[0] - Vector2(0.5, 0.5), Vector2(1.5, 1.5)), Color(1, 1, 1, a))

class SoulOrb extends Node2D:
	var target: Node2D
	var vel := Vector2.ZERO
	var delay := 0.0
	var t := 0.0
	var trail: Array[Vector2] = []
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 26
	func _process(delta: float) -> void:
		t += delta
		if target == null or not is_instance_valid(target):
			queue_free()
			return
		var goal := target.global_position + Vector2(0, -10)
		if t > delay:
			var to := goal - global_position
			vel = vel.lerp(to.normalized() * (180.0 + t * 260.0), clamp(delta * (3.0 + t * 6.0), 0.0, 1.0))
		else:
			vel *= 0.92
		position += vel * delta
		trail.push_front(position)
		if trail.size() > 8:
			trail.pop_back()
		if t > delay and global_position.distance_to(goal) < 8.0:
			Fx.burst(goal, Color(0.6, 0.9, 1.0), 3, 30.0, 0.3, "fx_soft", 180.0, Vector2.UP, 0.25)
			Audio.sfx("pickup", -16.0, 0.3)
			queue_free()
		if t > 3.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		for i in trail.size():
			var p := trail[i] - position
			var a := 1.0 - float(i) / trail.size()
			draw_circle(p, 2.2 * a + 0.5, Color(0.55, 0.85, 1.0, 0.6 * a))
		draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.95))

class ScorchFx extends Node2D:
	var radius := 24.0
	var t := 0.0
	func _ready() -> void:
		z_index = -8
	func _process(delta: float) -> void:
		t += delta
		if t > 4.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a: float = clamp(1.0 - (t - 2.5) / 1.5, 0.0, 1.0) * 0.55
		draw_circle(Vector2.ZERO, radius, Color(0.05, 0.02, 0.03, a * 0.7))
		draw_circle(Vector2.ZERO, radius * 0.6, Color(0.08, 0.02, 0.02, a))
		var glow: float = clamp(1.0 - t / 1.5, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius * 0.8, 0, TAU, 24, Color(1, 0.4, 0.1, glow * 0.5), 2.0)

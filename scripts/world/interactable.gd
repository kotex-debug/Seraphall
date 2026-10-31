class_name Interactable
extends Node2D
## Objeto con el que se interactúa: Brasa, PNJ, cofre, recogible, puerta, ecos caídos.

var kind := "chest"      # brasa | npc | chest | pickup | ecos
var id := ""
var data := {}
var used := false
var radius := 22.0
var spr: Sprite2D
var light: PointLight2D
var _t := 0.0
var _frames := 1
var _fw := 16
var _particles: CPUParticles2D

func setup(p_kind: String, p_id: String, pos: Vector2, p_data := {}) -> Interactable:
	kind = p_kind
	id = p_id
	position = pos
	data = p_data
	name = "I_" + p_id
	return self

func _ready() -> void:
	var sh := Sprite2D.new()
	sh.texture = Fx.tex("fx_soft")
	sh.modulate = Color(0, 0, 0, 0.5)
	sh.scale = Vector2(1.2, 0.45)
	sh.z_index = -1
	add_child(sh)
	spr = Sprite2D.new()
	add_child(spr)
	match kind:
		"brasa":
			spr.texture = Fx.tex("brasa")
			spr.region_enabled = true
			_fw = 18
			_frames = 7
			spr.region_rect = Rect2(0, 0, 18, 26)
			spr.offset = Vector2(0, -11)
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = Color(1.0, 0.62, 0.3)
			light.texture_scale = 3.2
			light.energy = 0.0
			light.position = Vector2(0, -8)
			add_child(light)
			_particles = CPUParticles2D.new()
			_particles.amount = 18
			_particles.lifetime = 1.6
			_particles.texture = Fx.tex("fx_px")
			_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			_particles.emission_sphere_radius = 4.0
			_particles.direction = Vector2.UP
			_particles.spread = 25.0
			_particles.gravity = Vector2(0, -20)
			_particles.initial_velocity_min = 8.0
			_particles.initial_velocity_max = 22.0
			_particles.position = Vector2(0, -6)
			var g := Gradient.new()
			g.set_color(0, Color(1, 0.8, 0.4))
			g.set_color(1, Color(1, 0.3, 0.1, 0))
			_particles.color_ramp = g
			_particles.material = Fx.add_material()
			_particles.emitting = false
			add_child(_particles)
			radius = 26.0
		"npc":
			spr.texture = Fx.tex(data.get("sheet", "npc_brenna"))
			spr.region_enabled = true
			_fw = 24
			_frames = 4
			spr.region_rect = Rect2(0, 0, 24, 26)
			spr.offset = Vector2(0, -11)
			spr.flip_h = data.get("flip", false)
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = data.get("light", Color(1, 0.7, 0.4))
			light.texture_scale = 1.4
			light.energy = 0.7
			add_child(light)
			radius = 26.0
		"chest":
			spr.texture = Fx.tex("chest")
			spr.region_enabled = true
			spr.region_rect = Rect2(0, 0, 16, 14)
			spr.offset = Vector2(0, -6)
		"pickup":
			spr.texture = Fx.tex("icon_" + data.get("icon", "feather"))
			spr.offset = Vector2(0, -8)
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = Color(0.9, 0.9, 1.0)
			light.texture_scale = 0.6
			light.energy = 0.9
			add_child(light)
			radius = 14.0
		"ecos":
			spr.texture = Fx.tex("icon_eco")
			spr.offset = Vector2(0, -8)
			spr.material = Fx.add_material()
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = Color(0.5, 0.8, 1.0)
			light.texture_scale = 0.9
			light.energy = 1.2
			add_child(light)
			radius = 16.0

func set_lit(lit: bool, instant := false) -> void:
	if kind != "brasa":
		return
	used = lit
	_particles.emitting = lit
	if instant:
		light.energy = 1.25 if lit else 0.0
	else:
		var tw := create_tween()
		tw.tween_property(light, "energy", 1.25 if lit else 0.0, 1.2)

func set_opened() -> void:
	used = true
	if kind == "chest":
		spr.region_rect = Rect2(16, 0, 16, 14)
	elif kind == "pickup" or kind == "ecos":
		queue_free()

func prompt() -> String:
	match kind:
		"brasa":
			return G.T("interact") % (G.T("rest") if used else G.T("light_brasa"))
		"npc":
			return G.T("interact") % (G.T("talk") + " — " + G.L(data.get("name", ["", ""])))
		"chest":
			return "" if used else G.T("interact") % G.T("open")
	return ""

func _process(delta: float) -> void:
	_t += delta
	match kind:
		"brasa":
			if used:
				var f := 1 + int(_t * 9.0) % 6
				spr.region_rect = Rect2(f * _fw, 0, _fw, 26)
				light.energy = 1.15 + 0.12 * sin(_t * 11.0) + 0.06 * sin(_t * 23.0)
			else:
				spr.region_rect = Rect2(0, 0, _fw, 26)
		"npc":
			var f2 := int(_t * 4.0) % _frames
			spr.region_rect = Rect2(f2 * _fw, 0, _fw, 26)
		"pickup", "ecos":
			spr.position.y = sin(_t * 3.0) * 2.0
			if randf() < 0.08:
				Fx.burst(global_position + Vector2(randf_range(-4, 4), -8), Color(0.8, 0.9, 1), 1, 15.0, 0.8, "fx_px", 40.0, Vector2.UP)

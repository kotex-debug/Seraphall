class_name Interactable
extends Node2D
## Objeto con el que se interactúa: Brasa, PNJ, cofre, recogible, puerta, ecos caídos.

var kind := "chest"      # brasa | npc | chest | pickup | ecos | bell | lore
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
			_fw = 32
			_frames = 4
			spr.region_rect = Rect2(0, 0, 32, 32)
			spr.offset = Vector2(0, -14)
			spr.flip_h = data.get("flip", false)
			var cast := Depth3D.CastShadow.new()
			cast.src = spr
			add_child(cast)
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = data.get("light", Color(1, 0.7, 0.4))
			light.texture_scale = 1.4
			light.energy = 0.7
			add_child(light)
			radius = 26.0
		"bench":
			spr.texture = Fx.tex("bench")
			spr.offset = Vector2(0, -6)
			radius = 24.0
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
		"bell":
			spr.texture = Fx.tex("bells")
			spr.region_enabled = true
			var n: int = data.get("note", 0)
			spr.region_rect = Rect2(72, 0, 24, 32)
			spr.offset = Vector2(0, -14)
			_bell = Sprite2D.new()
			_bell.texture = spr.texture
			_bell.region_enabled = true
			_bell.region_rect = Rect2(n * 24, 0, 24, 32)
			_bell.position = Vector2(0, -24)
			_bell.offset = Vector2(0, 10)
			add_child(_bell)
			radius = 22.0
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = Color(0.7, 0.55, 1.0)
			light.texture_scale = 0.9
			light.energy = 0.35
			light.position = Vector2(0, -14)
			add_child(light)
		"lore":
			spr.texture = Fx.tex("stele")
			spr.region_enabled = true
			spr.region_rect = Rect2(0, 0, 16, 26)
			spr.offset = Vector2(0, -11)
			radius = 22.0
			light = PointLight2D.new()
			light.texture = Fx.tex("light")
			light.color = Color(0.6, 0.85, 1.0)
			light.texture_scale = 0.7
			light.energy = 0.5
			light.position = Vector2(0, -12)
			add_child(light)
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
			if not used and id != "sanct":
				return G.T("interact") % (G.T("offer_feather") + " (%d)" % Prog.wing_feathers)
			return G.T("interact") % (G.T("rest") if used else G.T("light_brasa"))
		"npc":
			return G.T("interact") % (G.T("talk") + " - " + G.L(data.get("name", ["", ""])))
		"chest":
			return "" if used else G.T("interact") % G.T("open")
		"bench":
			return G.T("interact") % G.T("contemplate")
		"bell":
			return G.T("interact") % G.T("ring_bell")
		"lore":
			return G.T("interact") % G.T("read")
	return ""

## PNJ que recorre un camino en bucle (Sael sube la Escalinata, se desvanece arriba y reaparece abajo)
var _walk_k := 0.0
var _walk_wait := 2.0
var _walk_fade := 1.0
var _walk_phase := "up"
func _walk_tick(delta: float) -> void:
	var a: Vector2 = data.walk[0]
	var b: Vector2 = data.walk[1]
	var w := get_tree().get_first_node_in_group("world")
	var lp: Node2D = w.local_player() if w else null
	var near := lp != null and lp.global_position.distance_to(global_position) < 46.0
	var talking: bool = w != null and w.dialog.is_open() and near
	if near or talking:
		# se detiene y te mira
		if lp:
			spr.flip_h = lp.global_position.x < global_position.x
		_walk_fade = move_toward(_walk_fade, 1.0, delta * 2.0)
		spr.modulate.a = _walk_fade
		return
	match _walk_phase:
		"up":
			_walk_k = minf(1.0, _walk_k + delta * 7.0 / maxf(a.distance_to(b), 1.0))
			global_position = a.lerp(b, _walk_k) + Vector2(0, -absf(sin(_t * 7.0)) * 1.0)
			spr.flip_h = b.x < a.x
			if _walk_k >= 1.0:
				_walk_phase = "fade"
				_walk_wait = 2.5
		"fade":
			_walk_wait -= delta
			if _walk_wait <= 0.0:
				_walk_fade = move_toward(_walk_fade, 0.0, delta * 0.8)
				if _walk_fade <= 0.0:
					_walk_k = 0.0
					global_position = a
					_walk_phase = "appear"
		"appear":
			_walk_fade = move_toward(_walk_fade, 1.0, delta * 0.8)
			if _walk_fade >= 1.0:
				_walk_phase = "up"
	spr.modulate.a = _walk_fade
	if light:
		light.energy = 0.7 * _walk_fade

var _ring_t := 0.0
var _bark_t := 6.0
var _bark := ""
var _bark_a := 0.0
const BARKS := {
	"brenna": [["¡Clang! ¡Clang!", "Clang! Clang!"], ["Este acero no se templa solo...", "This steel won't temper itself..."], ["¿Otra vez rota?", "Broken again?"]],
	"carto": [["...trescientos doce pasos...", "...three hundred and twelve steps..."], ["Huelo a ceniza nueva.", "I smell fresh ash."]],
	"ozias": [["Las runas susurran...", "The runes whisper..."], ["Escarcha... no, Brasa.", "Frost... no, Ember."]],
	"ilse": [["Shhh... duerme, pequeña llama.", "Shhh... sleep, little flame."], ["Una puntada más.", "One more stitch."]],
	"nyx": [["Psst. Género nuevo.", "Psst. New stock."], ["Todo tiene un precio.", "Everything has a price."]],
	"velaria": [["Los ecos no descansan.", "Echoes never rest."], ["¿Te atreves?", "Do you dare?"]],
	"preso": [["...no contestes...", "...don't answer..."], ["Las cadenas pesan menos hoy.", "The chains weigh less today."]],
	"peregrina": [["...cuatrocientos uno, cuatrocientos dos...", "...four hundred and one, four hundred and two..."], ["Sube. O baja. Da igual.", "Go up. Or down. It's all the same."]],
}
var _bell: Sprite2D
func ring() -> void:
	_ring_t = 1.0
	if light:
		light.energy = 1.4

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
			spr.region_rect = Rect2(f2 * _fw, 0, _fw, 32)
			if data.has("walk"):
				_walk_tick(delta)
			# comentarios sueltos cuando pasas cerca
			_bark_t -= delta
			_bark_a = move_toward(_bark_a, 1.0 if _bark_t > 2.2 else 0.0, delta * 3.0)
			if _bark_t <= 0.0:
				_bark_t = randf_range(9.0, 15.0)
				var w := get_tree().get_first_node_in_group("world") if is_inside_tree() else null
				var lp: Node2D = w.local_player() if w and w.has_method("local_player") else null
				if lp and lp.global_position.distance_to(global_position) < 110.0 and BARKS.has(id) and not (w.dialog.is_open()):
					var pool: Array = BARKS[id]
					_bark = G.L(pool[randi() % pool.size()])
					_bark_t = 4.5 + randf_range(5.0, 9.0)
				else:
					_bark = ""
			queue_redraw()
		"bell":
			_ring_t = max(0.0, _ring_t - delta * 0.8)
			_bell.rotation = sin(_t * 14.0) * 0.35 * _ring_t
			if light:
				light.energy = lerpf(light.energy, 0.35, delta * 2.0)
		"lore":
			spr.region_rect = Rect2(16 if int(_t * 1.5) % 4 == 0 else 0, 0, 16, 26)
			if light:
				light.energy = 0.45 + 0.15 * sin(_t * 2.0)
		"pickup", "ecos":
			spr.position.y = sin(_t * 3.0) * 2.0
			if randf() < 0.08:
				Fx.burst(global_position + Vector2(randf_range(-4, 4), -8), Color(0.8, 0.9, 1), 1, 15.0, 0.8, "fx_px", 40.0, Vector2.UP)


func _draw() -> void:
	if kind != "npc" or _bark == "" or _bark_a <= 0.01:
		return
	var f := UIKit.font("title")
	var w := f.get_string_size(_bark, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var r := Rect2(Vector2(-w / 2.0 - 5, -50), Vector2(w + 10, 14))
	draw_rect(r.grow(1), Color(UIKit.INK, 0.85 * _bark_a))
	draw_rect(r, Color(0.95, 0.92, 0.86, 0.92 * _bark_a))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -36), Vector2(3, -36), Vector2(0, -32)]), Color(0.95, 0.92, 0.86, 0.92 * _bark_a))
	f.draw_string(get_canvas_item(), Vector2(-w / 2.0, -40), _bark, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.15, 0.08, 0.15, _bark_a))

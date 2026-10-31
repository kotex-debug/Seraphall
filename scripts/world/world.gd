extends Node2D
## Mundo del Estrato I: construye el mapa, gestiona entidades, red, jefes, misiones y escenas.

const TS := 16
const MAPW := 96
const MAPH := 96

const ROOMS := [
	{"id": "circle", "c": Vector2i(49, 14), "r": 13},
	{"id": "gatehall", "rect": Rect2i(48, 26, 3, 7)},
	{"id": "yard", "rect": Rect2i(38, 32, 23, 14)},
	{"id": "alcove", "rect": Rect2i(29, 36, 8, 7)},
	{"id": "alc_link", "rect": Rect2i(36, 38, 3, 3)},
	{"id": "hall2", "rect": Rect2i(47, 45, 4, 10)},
	{"id": "chains", "rect": Rect2i(35, 54, 28, 16)},
	{"id": "east", "rect": Rect2i(62, 59, 11, 4)},
	{"id": "gallery", "rect": Rect2i(72, 48, 20, 24)},
	{"id": "hall1", "rect": Rect2i(47, 69, 4, 12)},
	{"id": "sanct", "rect": Rect2i(40, 80, 18, 13)},
]
const AREAS := {"sanct": "area_sanct", "hall1": "area_sanct", "chains": "area_chains", "hall2": "area_chains", "east": "area_gallery",
	"gallery": "area_gallery", "yard": "area_yard", "alcove": "area_yard", "alc_link": "area_yard", "gatehall": "area_yard", "circle": "area_circle"}

var main: Node
var grid := PackedByteArray()
var room_of := PackedInt32Array()
var entities: Node2D
var fx_layer: Node2D
var floor_layer: TileMapLayer
var wall_layer: TileMapLayer
var camera: Camera2D
var hud: Node
var menu: Node
var dialog: Node
var canvas_mod: CanvasModulate
var players := {}          # peer_id -> Player
var enemies: Array = []    # índice = idx
var interactables := {}    # id -> Interactable
var joined_peers: Array[int] = []
var active_boss: Enemy = null
var gate_body: StaticBody2D
var gate_spr: Sprite2D
var gate_open := false
var wflags := {}           # banderas de mundo (del anfitrión)
var _esync_t := 0.0
var _area := ""
var _area_t := 0.0
var _shake := 0.0
var _shake_t := 0.0
var _cam_focus: Variant = null
var _boss_started := false
var _interact_hold := 0.0
var _game_mode := "new"

# ====================================================================== construcción
func setup(p_main: Node, mode: String) -> void:
	main = p_main
	_game_mode = mode
	name = "World"

func _ready() -> void:
	y_sort_enabled = false
	_build_map()
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	fx_layer = Node2D.new()
	fx_layer.name = "FX"
	fx_layer.z_index = 5
	add_child(fx_layer)
	canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color(0.5, 0.46, 0.58)
	add_child(canvas_mod)
	_build_props()
	_spawn_enemies()
	_spawn_interactables()
	_build_gate()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	_build_ambient()
	hud = preload("res://scripts/ui/hud.gd").new()
	hud.world = self
	add_child(hud)
	menu = preload("res://scripts/ui/menu.gd").new()
	menu.world = self
	add_child(menu)
	dialog = preload("res://scripts/ui/dialog.gd").new()
	add_child(dialog)
	G.shake_requested.connect(_on_shake)
	Net.peer_left.connect(_on_peer_left)
	Net.host_closed.connect(_on_host_closed)
	Net.peer_joined.connect(_on_peer_joined_net)
	if multiplayer.is_server():
		wflags = Prog.flags
		_spawn_player(Net.my_id(), 1)
		_apply_world_flags(true)
		Audio.play_music("explore")
		if _game_mode == "new":
			Prog.start_quest("main1")
			_play_intro()
		else:
			_after_load()
	else:
		_req_join.rpc_id(1, Prog.equipped)

func _rect_of(r: Dictionary) -> Rect2i:
	if r.has("rect"):
		return r.rect
	return Rect2i(r.c.x - r.r, r.c.y - r.r, r.r * 2 + 1, r.r * 2 + 1)

func _build_map() -> void:
	grid.resize(MAPW * MAPH)
	grid.fill(0)
	room_of.resize(MAPW * MAPH)
	room_of.fill(-1)
	for i in ROOMS.size():
		var r: Dictionary = ROOMS[i]
		var rect := _rect_of(r)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if r.has("c") and Vector2(x - r.c.x, y - r.c.y).length() > r.r + 0.3:
					continue
				grid[y * MAPW + x] = 1
				if room_of[y * MAPW + x] == -1 or not r.id.begins_with("hall"):
					room_of[y * MAPW + x] = i
	# paredes
	for y in MAPH:
		for x in MAPW:
			if grid[y * MAPW + x] != 0:
				continue
			for dy in range(-1, 3):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and ny >= 0 and nx < MAPW and ny < MAPH and grid[ny * MAPW + nx] == 1:
						grid[y * MAPW + x] = 2
	var ts := _build_tileset()
	floor_layer = TileMapLayer.new()
	floor_layer.tile_set = ts
	floor_layer.z_index = -10
	add_child(floor_layer)
	wall_layer = TileMapLayer.new()
	wall_layer.tile_set = ts
	wall_layer.z_index = -9
	add_child(wall_layer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for y in MAPH:
		for x in MAPW:
			var g := grid[y * MAPW + x]
			var c := Vector2i(x, y)
			if g == 1:
				var room := room_of[y * MAPW + x]
				var rid: String = ROOMS[room].id if room >= 0 else ""
				var t := rng.randi_range(0, 3)
				if rid == "gallery":
					t = 13 + rng.randi_range(0, 1)
				elif rid == "circle":
					t = 15 if rng.randf() < 0.7 else rng.randi_range(0, 3)
				if rng.randf() < 0.1 and rid != "gallery":
					t = 4 + rng.randi_range(0, 1)
				if rid == "sanct" and x >= 48 and x <= 50 and y >= 81:
					t = 10
				if rid == "chains" and rng.randf() < 0.04:
					t = 11
				floor_layer.set_cell(c, 0, Vector2i(t, 0))
			elif g == 2:
				var below := y + 1 < MAPH and grid[(y + 1) * MAPW + x] == 1
				if below:
					wall_layer.set_cell(c, 0, Vector2i(7 + rng.randi_range(0, 2), 0))
				else:
					wall_layer.set_cell(c, 0, Vector2i(6, 0))

func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TS, TS)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = Fx.tex("tiles")
	src.texture_region_size = Vector2i(TS, TS)
	ts.add_source(src, 0)
	for i in 16:
		src.create_tile(Vector2i(i, 0))
	for i in [6, 7, 8, 9, 12]:
		var td := src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	return ts

func tile_pos(tx: float, ty: float) -> Vector2:
	return Vector2(tx * TS + TS / 2.0, ty * TS + TS / 2.0)

func is_wall_at(p: Vector2) -> bool:
	var x := int(floor(p.x / TS))
	var y := int(floor(p.y / TS))
	if x < 0 or y < 0 or x >= MAPW or y >= MAPH:
		return true
	if not gate_open and gate_body and Rect2(48 * TS, 31 * TS, 3 * TS, TS).has_point(p):
		return true
	return grid[y * MAPW + x] != 1

func room_at(p: Vector2) -> String:
	var x := int(p.x / TS)
	var y := int(p.y / TS)
	if x < 0 or y < 0 or x >= MAPW or y >= MAPH:
		return ""
	var r := room_of[y * MAPW + x]
	return ROOMS[r].id if r >= 0 else ""

func _prop(tex: String, pos: Vector2, frames := 1, frame := 0, collide := 0.0, light_col := Color(0, 0, 0, 0), light_scale := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Fx.tex(tex)
	if frames > 1:
		s.region_enabled = true
		var fw := s.texture.get_width() / frames
		s.region_rect = Rect2(frame * fw, 0, fw, s.texture.get_height())
	s.position = pos
	s.offset = Vector2(0, -s.texture.get_height() / 2.0 + 2)
	entities.add_child(s)
	if collide > 0.0:
		var b := StaticBody2D.new()
		b.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = collide
		cs.shape = sh
		b.add_child(cs)
		s.add_child(b)
	if light_col.a > 0.0:
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = light_col
		l.texture_scale = light_scale
		l.energy = 0.9
		l.position = Vector2(0, -10)
		s.add_child(l)
		s.set_meta("flicker", l)
	return s

func _build_props() -> void:
	# Santuario
	_prop("statue", tile_pos(41.5, 82)); _prop("statue", tile_pos(56.5, 82)).flip_h = true
	for p in [Vector2(46, 81), Vector2(52, 81), Vector2(44, 90), Vector2(54, 90), Vector2(41, 87), Vector2(57, 87)]:
		_prop("candle", tile_pos(p.x, p.y), 4, int(p.x) % 4, 0.0, Color(1, 0.7, 0.35), 0.8)
	_prop("rubble", tile_pos(42, 91), 3, 0)
	# forja de Brenna
	_prop("rubble", tile_pos(44.5, 83.5), 3, 2, 0.0, Color(1, 0.45, 0.2), 1.3)
	# pasillos
	for y in [72, 76]:
		_prop("candle", tile_pos(47, y), 4, y % 4, 0.0, Color(1, 0.7, 0.35), 0.8)
		_prop("candle", tile_pos(50, y + 2), 4, (y + 1) % 4, 0.0, Color(1, 0.7, 0.35), 0.8)
	# Pasillo de las Cadenas
	for p in [Vector2(38, 57), Vector2(60, 57), Vector2(38, 66), Vector2(60, 66), Vector2(44, 61), Vector2(54, 61)]:
		_prop("pillar", tile_pos(p.x, p.y), 2, 1 if int(p.x + p.y) % 3 == 0 else 0, 5.0)
	for x in [37, 41, 45, 53, 57, 61]:
		var c := Sprite2D.new()
		c.texture = Fx.tex("chains")
		c.position = tile_pos(x, 53) + Vector2(0, 6)
		c.z_index = -8
		add_child(c)
	for p in [Vector2(36, 55), Vector2(62, 68), Vector2(48, 68)]:
		_prop("candle", tile_pos(p.x, p.y), 4, 1, 0.0, Color(1, 0.6, 0.3), 1.0)
	_prop("rubble", tile_pos(50, 64), 3, 1); _prop("rubble", tile_pos(40, 63), 3, 2)
	# Galería Rota (luz fría)
	for p in [Vector2(75, 51), Vector2(89, 53), Vector2(80, 60), Vector2(86, 62), Vector2(76, 68), Vector2(90, 68)]:
		_prop("pillar", tile_pos(p.x, p.y), 2, 1, 5.0)
	for p in [Vector2(73, 49), Vector2(90, 49), Vector2(73, 70), Vector2(82, 55)]:
		_prop("candle", tile_pos(p.x, p.y), 4, 2, 0.0, Color(0.55, 0.65, 1.0), 1.4)
	_prop("statue", tile_pos(82, 50))
	_prop("rubble", tile_pos(78, 64), 3, 0); _prop("rubble", tile_pos(87, 58), 3, 1)
	# Patio del Carcelero
	for p in [Vector2(39, 33), Vector2(59, 33), Vector2(39, 44), Vector2(59, 44)]:
		_prop("pillar", tile_pos(p.x, p.y), 2, 0, 5.0)
		_prop("candle", tile_pos(p.x + (1 if p.x < 49 else -1), p.y), 4, 3, 0.0, Color(1, 0.5, 0.25), 1.2)
	# Círculo de la Guardiana: anillo dorado y braseros
	var ring := ArenaRing.new()
	ring.position = tile_pos(49, 14)
	ring.z_index = -8
	add_child(ring)
	for i in 8:
		var a := TAU * i / 8.0
		var p := tile_pos(49, 14) + Vector2(cos(a), sin(a)) * 160.0
		_prop("candle", p, 4, i % 4, 0.0, Color(1, 0.8, 0.45), 1.6)
	_prop("statue", tile_pos(40, 5)); _prop("statue", tile_pos(58, 5)).flip_h = true

func _build_gate() -> void:
	gate_spr = Sprite2D.new()
	gate_spr.texture = Fx.tex("gate")
	gate_spr.region_enabled = true
	gate_spr.region_rect = Rect2(0, 0, 48, 40)
	gate_spr.position = Vector2(49.5 * TS, 32 * TS - 20)
	gate_spr.z_index = -8
	add_child(gate_spr)
	var gl := PointLight2D.new()
	gl.texture = Fx.tex("light")
	gl.color = Color(1, 0.8, 0.4)
	gl.texture_scale = 0.8
	gl.position = Vector2(0, -2)
	gate_spr.add_child(gl)
	gate_body = StaticBody2D.new()
	gate_body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(3 * TS, TS)
	cs.shape = sh
	gate_body.add_child(cs)
	gate_body.position = Vector2(49.5 * TS, 31.5 * TS)
	add_child(gate_body)

func set_gate(open: bool, instant := false) -> void:
	if open == gate_open and not instant:
		return
	gate_open = open
	gate_spr.region_rect = Rect2(48 if open else 0, 0, 48, 40)
	gate_body.get_child(0).set_deferred("disabled", open)
	if not instant:
		Audio.sfx("gate")
		G.shake(3.0, 0.6)
		Fx.burst(gate_spr.global_position + Vector2(0, 16), Color(0.6, 0.55, 0.6, 0.8), 20, 60.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.6, false)

func _build_ambient() -> void:
	var ash := CPUParticles2D.new()
	ash.name = "Ash"
	ash.amount = 70
	ash.lifetime = 7.0
	ash.preprocess = 7.0
	ash.texture = Fx.tex("fx_px")
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(360, 220)
	ash.direction = Vector2(0.3, 1)
	ash.spread = 20.0
	ash.gravity = Vector2(4, 8)
	ash.initial_velocity_min = 4.0
	ash.initial_velocity_max = 14.0
	ash.scale_amount_min = 0.3
	ash.scale_amount_max = 0.8
	var g := Gradient.new()
	g.set_color(0, Color(0.8, 0.75, 0.8, 0.0))
	g.add_point(0.2, Color(0.8, 0.75, 0.8, 0.5))
	g.set_color(g.get_point_count() - 1, Color(0.8, 0.75, 0.8, 0.0))
	ash.color_ramp = g
	ash.z_index = 30
	camera.add_child(ash)
	var embers := ash.duplicate()
	embers.amount = 18
	embers.direction = Vector2(0, -1)
	embers.gravity = Vector2(0, -6)
	var g2 := Gradient.new()
	g2.set_color(0, Color(1, 0.6, 0.2, 0.0))
	g2.add_point(0.3, Color(1, 0.6, 0.2, 0.9))
	g2.set_color(g2.get_point_count() - 1, Color(1, 0.3, 0.1, 0.0))
	embers.color_ramp = g2
	embers.material = Fx.add_material()
	camera.add_child(embers)

func _spawn_enemies() -> void:
	var list := [
		["hueco", 40, 58], ["hueco", 45, 64], ["hueco", 53, 57], ["hueco", 58, 63], ["hueco", 42, 67], ["hueco", 56, 67],
		["hueco", 49, 49],
		["acolito", 78, 52], ["acolito", 87, 56], ["acolito", 82, 67],
		["bestia", 76, 60], ["bestia", 88, 64], ["hueco", 84, 70], ["hueco", 74, 55],
		["carcelero", 49, 38],
		["seravel", 49, 10],
	]
	for e in list:
		_add_enemy(e[0], tile_pos(e[1], e[2]), false)

func _add_enemy(type: String, pos: Vector2, extra: bool) -> Enemy:
	var e: Enemy
	if type == "seravel":
		e = preload("res://scripts/actors/boss_seravel.gd").new()
	else:
		e = Enemy.new()
	e.setup(enemies.size(), type, pos, self)
	e.set_meta("extra", extra)
	if extra:
		e.active = true
	enemies.append(e)
	entities.add_child(e)
	return e

func _spawn_interactables() -> void:
	_add_inter("brasa", "sanct", tile_pos(49, 86))
	_add_inter("brasa", "gate", tile_pos(32, 39))
	_add_inter("npc", "brenna", tile_pos(43.5, 84), {"sheet": "npc_brenna", "name": ["Brenna, la herrera", "Brenna, the smith"], "light": Color(1, 0.5, 0.25)})
	_add_inter("npc", "carto", tile_pos(55, 84), {"sheet": "npc_carto", "name": ["El Cartógrafo Ciego", "The Blind Cartographer"], "flip": true, "light": Color(0.6, 0.7, 1.0)})
	_add_inter("chest", "chest_chains", tile_pos(61, 55), {"feathers": 2, "ecos": 120})
	_add_inter("chest", "chest_gallery", tile_pos(90, 50), {"weapon": "spear"})
	_add_inter("chest", "chest_yard", tile_pos(59, 34), {"feathers": 1, "ecos": 250})
	_add_inter("pickup", "f1", tile_pos(36, 68), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "f2", tile_pos(62, 68), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "f3", tile_pos(74, 70), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "f4", tile_pos(85, 49), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "map", tile_pos(90, 70), {"icon": "quest", "quest": "map"})

func _add_inter(kind: String, id: String, pos: Vector2, data := {}) -> Interactable:
	var it := Interactable.new().setup(kind, id, pos, data)
	interactables[id] = it
	entities.add_child(it)
	return it

func _apply_world_flags(instant: bool) -> void:
	for id in interactables:
		var it: Interactable = interactables[id]
		if it.kind == "brasa":
			it.set_lit(wflags.get("brasa_" + id, false), instant)
		elif wflags.get("used_" + id, false):
			it.set_opened()
	set_gate(wflags.get("carcelero_dead", false) and not _boss_started, true)
	for e in enemies:
		if e.type == "carcelero" and wflags.get("carcelero_dead", false):
			e.die(); e.visible = false
		if e.type == "seravel" and wflags.get("seravel_dead", false):
			e.die(); e.visible = false
	if Prog.dropped_ecos.has("amount") and Prog.dropped_ecos.amount > 0:
		_spawn_ecos_drop()

func _spawn_ecos_drop() -> void:
	if interactables.has("ecosdrop"):
		interactables["ecosdrop"].queue_free()
		interactables.erase("ecosdrop")
	var p: Array = Prog.dropped_ecos.pos
	_add_inter("ecos", "ecosdrop", Vector2(p[0], p[1]), {"amount": Prog.dropped_ecos.amount})

func _after_load() -> void:
	var p := local_player()
	if p:
		p.respawn_at(_brasa_spawn(Prog.last_brasa))
	hud.show_area(G.T("stratum1"), G.T("area_sanct"))

# ====================================================================== jugadores
func _spawn_player(peer: int, variant: int) -> Player:
	if players.has(peer):
		return players[peer]
	var p := Player.new()
	p.setup(peer, variant, self)
	p.position = _brasa_spawn(Prog.last_brasa if peer == Net.my_id() else "sanct") + Vector2(18 * (variant - 1), 0)
	players[peer] = p
	entities.add_child(p)
	return p

func _brasa_spawn(id: String) -> Vector2:
	var it: Interactable = interactables.get(id, interactables["sanct"])
	return it.position + Vector2(0, 22)

func local_player() -> Player:
	return players.get(Net.my_id(), null)

func local_players() -> Array:
	var p := local_player()
	return [p] if p else []

func players_list() -> Array:
	return players.values()

func nearest_player(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var bd := INF
	for p in players.values():
		if p.is_alive() and not p.cutscene:
			var d := pos.distance_to(p.global_position)
			if d < bd:
				bd = d
				best = p
	return best

func enemies_alive() -> Array:
	var out := []
	for e in enemies:
		if e.is_alive() and e.visible and (e.active or not e.is_boss):
			out.append(e)
	return out

func is_menu_open() -> bool:
	return menu.visible or dialog.is_open()

# ====================================================================== bucle
func _process(delta: float) -> void:
	var lp := local_player()
	if lp:
		var target: Vector2 = lp.global_position + Vector2(0, -10) + lp.aim * 22.0
		if active_boss and active_boss.is_alive() and active_boss.active:
			target = target.lerp(active_boss.global_position + Vector2(0, -20), 0.28)
		if _cam_focus != null:
			target = _cam_focus
		camera.position = camera.position.lerp(target, clamp(delta * 6.0, 0.0, 1.0))
		_area_t -= delta
		if _area_t <= 0.0:
			_area_t = 0.4
			_check_area(lp)
		_check_interact_hold(lp, delta)
	if _shake_t > 0.0:
		_shake_t -= delta
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * (_shake_t / max(0.01, _shake_t + 0.05))
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO, 0.3)
	for c in entities.get_children():
		if c.has_meta("flicker"):
			var l: PointLight2D = c.get_meta("flicker")
			l.energy = 0.85 + 0.12 * sin(Time.get_ticks_msec() * 0.011 + c.position.x) + 0.05 * sin(Time.get_ticks_msec() * 0.031)
	if multiplayer.is_server() and Net.is_online() and not joined_peers.is_empty():
		_esync_t -= delta
		if _esync_t <= 0.0:
			_esync_t = 0.066
			var arr := PackedFloat32Array()
			for e in enemies:
				if e.is_alive():
					arr.append_array([e.idx, e.position.x, e.position.y, e.facing, _state_code(e.state)])
			for pid in joined_peers:
				_esync.rpc_id(pid, arr)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and not dialog.is_open():
		menu.toggle("char")
	elif event.is_action_pressed("pause") and not dialog.is_open():
		if menu.visible:
			menu.close()
		else:
			menu.toggle("options")

func _on_shake(amount: float, duration: float) -> void:
	_shake = max(_shake if _shake_t > 0.0 else 0.0, amount)
	_shake_t = max(_shake_t, duration)

func _check_area(lp: Player) -> void:
	var r := room_at(lp.global_position)
	if r == "" or not AREAS.has(r):
		return
	var a: String = AREAS[r]
	if a != _area:
		var first := _area == ""
		_area = a
		if not first:
			hud.show_area("", G.T(a))
		var target := Color(0.42, 0.45, 0.6) if a == "area_gallery" else (Color(0.55, 0.45, 0.5) if a == "area_circle" else Color(0.5, 0.46, 0.58))
		create_tween().tween_property(canvas_mod, "color", target, 1.5)
	if r == "circle" and not wflags.get("seravel_dead", false) and not _boss_started and lp.is_alive():
		if multiplayer.is_server():
			_server_start_boss()
		else:
			_boss_started = true  # evita repetir la petición
			_request_boss.rpc_id(1)

func _check_interact_hold(lp: Player, delta: float) -> void:
	## Revivir al compañero manteniendo F.
	var target: Player = null
	for p in players.values():
		if p != lp and p.state == "downed" and p.global_position.distance_to(lp.global_position) < 26.0:
			target = p
	if target and Input.is_action_pressed("interact") and lp.is_alive():
		_interact_hold += delta * (2.0 if Prog.has_skill("c5") else 1.0)
		hud.set_progress(_interact_hold / 2.0, G.T("revive"))
		if _interact_hold >= 2.0:
			_interact_hold = 0.0
			target._net_revive.rpc_id(target.peer_id)
	else:
		_interact_hold = 0.0
		hud.set_progress(-1.0, "")
	if target and not Input.is_action_pressed("interact"):
		hud.set_progress(0.0, G.T("revive"))

func nearest_interactable(p: Player) -> Interactable:
	var best: Interactable = null
	var bd := INF
	for it in interactables.values():
		if not is_instance_valid(it):
			continue
		if it.kind == "chest" and it.used:
			continue
		var d: float = it.global_position.distance_to(p.global_position)
		if d < it.radius and d < bd:
			bd = d
			best = it
	return best

func try_interact(p: Player) -> void:
	var it := nearest_interactable(p)
	if it == null:
		return
	match it.kind:
		"brasa":
			if not it.used:
				bcast("_light_brasa", [it.id])
			else:
				_rest_at(it.id)
		"npc":
			_talk(it.id)
		"chest":
			bcast("_open_chest", [it.id])

func _physics_process(_delta: float) -> void:
	var lp := local_player()
	if lp == null or not lp.is_alive():
		return
	for it in interactables.values():
		if not is_instance_valid(it) or it.used:
			continue
		if (it.kind == "pickup" or it.kind == "ecos") and it.global_position.distance_to(lp.global_position) < it.radius:
			if it.kind == "ecos":
				Prog.ecos += int(it.data.amount)
				Prog.dropped_ecos = {}
				Prog.changed.emit()
				Audio.sfx("levelup", -6.0)
				Fx.burst(it.global_position, Color(0.6, 0.85, 1), 24, 80.0, 0.8, "fx_soft", 180.0, Vector2.UP, 0.4)
				it.set_opened()
				interactables.erase("ecosdrop")
				return
			bcast("_pickup", [it.id])

# ====================================================================== red: utilidades
func bcast(method: String, args: Array) -> void:
	## Ejecuta localmente y lo envía a los pares unidos.
	callv(method, args)
	for pid in joined_peers:
		callv("rpc_id", [pid, method] + args)

func peer_rpc(node: Node, method: String, args: Array) -> void:
	for pid in joined_peers:
		node.callv("rpc_id", [pid, method] + args)

func _state_code(s: String) -> int:
	return ["idle", "chase", "busy", "stagger", "dead"].find(s)

@rpc("any_peer", "call_remote", "reliable")
func _req_join(_weapon: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	_spawn_player(sender, 2)
	if not joined_peers.has(sender):
		joined_peers.append(sender)
	var estates := []
	for e in enemies:
		estates.append([e.type, e.position, e.hp, e.is_alive(), e.get_meta("extra", false)])
	_welcome.rpc_id(sender, wflags, estates, local_player().position)
	G.toast(G.T("partner_joined"), Color(0.6, 1, 0.8))
	Audio.sfx("quest")

@rpc("authority", "call_remote", "reliable")
func _welcome(flags: Dictionary, estates: Array, host_pos: Vector2) -> void:
	wflags = flags
	joined_peers = [1]
	for i in estates.size():
		var s: Array = estates[i]
		var e: Enemy
		if i < enemies.size():
			e = enemies[i]
		else:
			e = _add_enemy(s[0], s[1], s[4])
		e.position = s[1]
		e._net_pos = s[1]
		e.hp = s[2]
		if not s[3]:
			e.die()
			e.visible = false
	_apply_world_flags(true)
	var host := _spawn_player(1, 1)
	host.position = host_pos
	var me := _spawn_player(Net.my_id(), 2)
	me.position = host_pos + Vector2(20, 6)
	Audio.play_music("explore")
	hud.show_area(G.T("stratum1"), G.T("area_sanct"))
	if not Prog.quest_active("main1") and not Prog.quest_done("main1"):
		Prog.start_quest("main1")

func _on_peer_joined_net(_id: int) -> void:
	pass  # el jugador se crea al recibir _req_join

func _on_peer_left(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	joined_peers.erase(id)
	G.toast(G.T("partner_left"), Color(1, 0.6, 0.5))

func _on_host_closed() -> void:
	main.back_to_title(G.T("host_left"))

@rpc("authority", "call_remote", "unreliable_ordered")
func _esync(arr: PackedFloat32Array) -> void:
	var states := ["idle", "chase", "busy", "stagger", "dead"]
	var i := 0
	while i + 4 < arr.size():
		var idx := int(arr[i])
		if idx < enemies.size():
			enemies[idx].net_update(Vector2(arr[i + 1], arr[i + 2]), int(arr[i + 3]), states[clamp(int(arr[i + 4]), 0, 4)])
		i += 5

# ====================================================================== red: combate
@rpc("any_peer", "call_remote", "reliable")
func enemy_action(idx: int, act: String, tpos: Vector2, seed: int) -> void:
	if idx < enemies.size():
		enemies[idx].perform(act, tpos, seed)

func _rpc_targets() -> void:
	pass

@rpc("any_peer", "call_remote", "reliable")
func enemy_alert(idx: int) -> void:
	if idx < enemies.size() and enemies[idx].type == "carcelero":
		active_boss = enemies[idx]
		hud.show_boss(enemies[idx])
		Audio.play_music("boss1")

func request_damage_enemy(e: Enemy, dmg: float, dir: Vector2, poise: float, crit: bool) -> void:
	if multiplayer.is_server():
		_server_damage(e.idx, dmg, dir, poise, crit)
	else:
		_rpc_damage.rpc_id(1, e.idx, dmg, dir, poise, crit)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_damage(idx: int, dmg: float, dir: Vector2, poise: float, crit: bool) -> void:
	if multiplayer.is_server():
		_server_damage(idx, dmg, dir, poise, crit)

func _server_damage(idx: int, dmg: float, dir: Vector2, poise: float, crit: bool) -> void:
	if idx >= enemies.size():
		return
	var e: Enemy = enemies[idx]
	var res := e.server_apply_damage(dmg, dir, poise)
	if res.is_empty():
		return
	if e.state == "idle":
		e.state = "chase"
	bcast("_enemy_hurt", [idx, res.hp, dmg, dir, crit, res.broke])
	if res.dead:
		bcast("_enemy_die", [idx])

@rpc("any_peer", "call_remote", "reliable")
func _enemy_hurt(idx: int, hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	if idx < enemies.size():
		enemies[idx].on_hurt(hp, dmg, dir, crit, broke)
		if enemies[idx].type == "carcelero" and hp < enemies[idx].max_hp * 0.5:
			enemies[idx].phase = 2

func request_parry_enemy(idx: int) -> void:
	if multiplayer.is_server():
		bcast("_enemy_parried", [idx])
	else:
		_rpc_parry.rpc_id(1, idx)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_parry(idx: int) -> void:
	if multiplayer.is_server():
		bcast("_enemy_parried", [idx])

@rpc("any_peer", "call_remote", "reliable")
func _enemy_parried(idx: int) -> void:
	if idx < enemies.size():
		enemies[idx].on_parried()

@rpc("any_peer", "call_remote", "reliable")
func _enemy_die(idx: int) -> void:
	if idx >= enemies.size():
		return
	var e: Enemy = enemies[idx]
	if not e.is_alive():
		return
	e.die()
	Prog.add_ecos(e.cfg.ecos)
	Fx.text(e.global_position + Vector2(0, 26), "+%d %s" % [int(e.cfg.ecos * Prog.ecos_mult()), G.T("ecos")], Color(0.6, 0.85, 1.0), 8)
	match e.type:
		"hueco":
			Prog.quest_progress("husks")
		"carcelero":
			_on_carcelero_dead(e)
		"seravel":
			_on_seravel_dead(e)

func spawn_extra_enemy(type: String, pos: Vector2) -> void:
	if multiplayer.is_server():
		bcast("_spawn_extra", [type, pos])

@rpc("any_peer", "call_remote", "reliable")
func _spawn_extra(type: String, pos: Vector2) -> void:
	var e := _add_enemy(type, pos, true)
	e.state = "chase"
	Fx.burst(pos, Color(1, 0.3, 0.3), 20, 70.0, 0.6, "fx_soft", 180.0, Vector2.UP, 0.5)

@rpc("any_peer", "call_remote", "reliable")
func spawn_projectile(pos: Vector2, vel: Vector2, dmg: float, kind: String, team: String, owner: int, radius: float, life: float, pierce: int) -> void:
	spawn_projectile_local(pos, vel, dmg, kind, team, owner, radius, life, pierce)

func spawn_projectile_local(pos: Vector2, vel: Vector2, dmg: float, kind: String, team: String, owner: int, radius: float, life: float, pierce: int) -> Projectile:
	var p := Projectile.new()
	p.position = pos
	p.vel = vel
	p.damage = dmg
	p.kind = kind
	p.team = team
	p.owner_peer = owner
	p.radius = radius
	p.life = life
	p.pierce = pierce
	fx_layer.add_child(p)
	return p

@rpc("any_peer", "call_remote", "reliable")
func cast_nova(pos: Vector2, r: float, dmg: float, owner: int, big: bool) -> void:
	Audio.sfx("nova")
	G.shake(4.0 if big else 2.5, 0.25)
	Fx.ring(pos + Vector2(0, -6), 6.0, r, Color(1, 0.6, 0.25), 0.4, 8.0)
	Fx.ring(pos + Vector2(0, -6), 2.0, r * 0.7, Color(1, 0.9, 0.5), 0.3, 4.0)
	Fx.burst(pos, Color(1, 0.6, 0.25), 40 if big else 26, r * 2.5, 0.6, "fx_soft", 180.0, Vector2.RIGHT, 0.4)
	Fx.light_flash(pos, Color(1, 0.6, 0.3), 2.0, r / 40.0, 0.4)
	if owner == Net.my_id():
		for e in enemies_alive():
			if e.global_position.distance_to(pos) < r + e.body_radius:
				request_damage_enemy(e, dmg, (e.global_position - pos).normalized(), 18.0, false)
				if big:
					request_damage_enemy(e, dmg * 0.3, Vector2.ZERO, 0.0, false)

@rpc("any_peer", "call_remote", "reliable")
func cast_wrath(pos: Vector2, dmg: float, owner: int) -> void:
	Audio.sfx("roar", -6.0)
	Audio.sfx("nova")
	G.shake(7.0, 0.5)
	G.flash(Color(1, 0.95, 0.7, 0.28), 0.3)
	G.slowmo("wrath", 0.25, 0.35)
	for i in 4:
		Fx.slash(pos + Vector2(0, -8), i * PI / 2.0, 52.0, 200.0, Color(1, 0.9, 0.55, 0.95), 18.0, 0.4, i % 2 == 0)
	Fx.ring(pos + Vector2(0, -8), 8.0, 95.0, Color(1, 0.9, 0.6), 0.5, 10.0)
	Fx.burst(pos + Vector2(0, -8), Color(1, 0.95, 0.7), 60, 220.0, 0.9, "fx_feather", 180.0, Vector2.UP, 1.4, false, Vector2(0, 30))
	Fx.light_flash(pos, Color(1, 0.9, 0.6), 3.0, 3.0, 0.8)
	var pillar := Sprite2D.new()
	pillar.texture = Fx.tex("fx_soft")
	pillar.material = Fx.add_material()
	pillar.scale = Vector2(2.0, 14.0)
	pillar.position = pos + Vector2(0, -80)
	pillar.modulate = Color(1, 0.95, 0.7, 0.9)
	fx_layer.add_child(pillar)
	var tw := pillar.create_tween()
	tw.tween_property(pillar, "scale:x", 5.0, 0.15)
	tw.tween_property(pillar, "modulate:a", 0.0, 0.5)
	tw.tween_callback(pillar.queue_free)
	if owner == Net.my_id():
		for e in enemies_alive():
			if e.global_position.distance_to(pos) < 90.0 + e.body_radius:
				request_damage_enemy(e, dmg, (e.global_position - pos).normalized(), 80.0, true)
		for i in 8:
			var d := Vector2.from_angle(TAU * i / 8.0)
			spawn_projectile_local(pos + Vector2(0, -8) + d * 12, d * 300.0, Prog.spell_damage(14.0), "lance", "player", owner, 5.0, 0.9, 2)

func spawn_fire(pos: Vector2, owner: int) -> void:
	bcast("_fire", [pos, owner])

@rpc("any_peer", "call_remote", "unreliable")
func _fire(pos: Vector2, owner: int) -> void:
	var f := FirePatch.new()
	f.position = pos
	f.owner_peer = owner
	f.world = self
	fx_layer.add_child(f)

# ====================================================================== interacción
@rpc("any_peer", "call_remote", "reliable")
func _light_brasa(id: String) -> void:
	var it: Interactable = interactables.get(id)
	if it == null or it.used:
		return
	it.set_lit(true)
	wflags["brasa_" + id] = true
	Prog.flags["brasa_" + id] = true
	Audio.sfx("levelup")
	G.flash(Color(1, 0.7, 0.3, 0.35), 0.4)
	Fx.ring(it.global_position + Vector2(0, -8), 6.0, 70.0, Color(1, 0.7, 0.3), 0.7, 5.0)
	Fx.burst(it.global_position + Vector2(0, -8), Color(1, 0.7, 0.3), 40, 120.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.4)
	hud.big_message(G.T("brasa_lit"), Color(1, 0.75, 0.4), 2.2)
	Prog.last_brasa = id
	if id == "sanct":
		Prog.quest_step("main1", "brasa")
	var lp := local_player()
	if lp:
		lp.refresh_stats(true)
	if multiplayer.is_server():
		Prog.save_game()

func _rest_at(id: String) -> void:
	var lp := local_player()
	Prog.last_brasa = id
	lp.refresh_stats(true)
	Audio.sfx("heal")
	Fx.burst(lp.global_position + Vector2(0, -8), Color(1, 0.7, 0.4), 20, 60.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.4)
	if multiplayer.is_server():
		bcast("_reset_enemies", [])
	Prog.save_game()
	G.toast(G.T("game_saved"), Color(0.8, 0.8, 0.8))
	menu.open("char", {"brasa": true})

@rpc("any_peer", "call_remote", "reliable")
func _reset_enemies() -> void:
	for e in enemies.duplicate():
		if e.get_meta("extra", false):
			enemies.erase(e)
			e.queue_free()
			continue
		if e.type == "carcelero" and wflags.get("carcelero_dead", false):
			continue
		if e.type == "seravel" and wflags.get("seravel_dead", false):
			continue
		e.reset_state()
		if e.is_boss:
			e.active = e.type == "carcelero"
	for i in enemies.size():
		enemies[i].idx = i
	if active_boss and active_boss.type == "seravel" and not wflags.get("seravel_dead", false):
		_boss_started = false
		set_gate(wflags.get("carcelero_dead", false), true)
	active_boss = null
	hud.hide_boss()
	Audio.play_music("explore")

@rpc("any_peer", "call_remote", "reliable")
func _open_chest(id: String) -> void:
	var it: Interactable = interactables.get(id)
	if it == null or it.used:
		return
	it.set_opened()
	wflags["used_" + id] = true
	Prog.flags["used_" + id] = true
	Audio.sfx("pickup")
	Audio.sfx("levelup", -8.0)
	Fx.burst(it.global_position + Vector2(0, -8), Color(1, 0.85, 0.4), 30, 90.0, 0.8, "fx_px", 70.0, Vector2.UP)
	Fx.light_flash(it.global_position, Color(1, 0.85, 0.5), 1.5, 1.0, 0.5)
	_grant(it.data)

@rpc("any_peer", "call_remote", "reliable")
func _pickup(id: String) -> void:
	var it: Interactable = interactables.get(id)
	if it == null or it.used:
		return
	wflags["used_" + id] = true
	Prog.flags["used_" + id] = true
	Audio.sfx("pickup")
	Fx.burst(it.global_position + Vector2(0, -8), Color(0.9, 0.9, 1), 16, 60.0, 0.6, "fx_soft", 180.0, Vector2.UP, 0.3)
	_grant(it.data)
	it.set_opened()
	interactables.erase(id)

func _grant(d: Dictionary) -> void:
	if d.has("feathers"):
		Prog.add_feathers(d.feathers)
		G.toast("+%d %s" % [d.feathers, G.T("feathers")], Color(0.9, 0.9, 1))
	if d.has("ecos"):
		Prog.add_ecos(d.ecos)
		G.toast("+%d %s" % [d.ecos, G.T("ecos")], Color(0.6, 0.85, 1))
	if d.has("weapon"):
		Prog.add_weapon(d.weapon)
	if d.has("quest"):
		if not Prog.quests.has(d.quest):
			Prog.start_quest(d.quest)
		Prog.quest_progress(d.quest)

func _talk(id: String) -> void:
	var lines := []
	match id:
		"brenna":
			if not Prog.quests.has("feathers"):
				lines = [
					["Brenna", ["¿Otra pluma caída? Hacía años que la Brasa no despertaba a nadie.", "Another fallen feather? It's been years since the Ember woke anyone."]],
					["Brenna", ["Soy Brenna. Forjo lo que la Espiral escupe: acero, hueso... y alguna que otra plegaria.", "I'm Brenna. I forge whatever the Spiral spits out: steel, bone... the odd prayer."]],
					["Brenna", ["Tráeme Fragmentos de Pluma y haré que tu arma cante. Y si te ves con valor...", "Bring me Feather Shards and I'll make your weapon sing. And if you feel brave..."]],
					["Brenna", ["...el Carcelero guarda la llave de la puerta. Tráeme su cabeza, o al menos su llave.", "...the Jailer holds the gate key. Bring me his head, or at least the key."]],
				]
				var done := func():
					Prog.start_quest("feathers")
					Prog.start_quest("jailer_hunt")
					Prog.quest_step("main1", "talk_brenna")
					menu.open("weapons", {"forge": true})
				dialog.play(lines, done)
			else:
				Prog.quest_step("main1", "talk_brenna")
				var opts := [["Brenna", ["Acércame esa hoja. A ver qué puedo hacer.", "Hand me that blade. Let's see what I can do."]]]
				if wflags.get("seravel_dead", false):
					opts = [["Brenna", ["Seravel... Yo forjé su primera espada, ¿sabes? Antes de que todo esto empezara.", "Seravel... I forged her first sword, you know. Before all this began."]]]
				dialog.play(opts, _open_forge)
		"carto":
			if not Prog.quests.has("husks"):
				lines = [
					["El Cartógrafo", ["No veo, pero escucho. Y la Espiral nunca deja de hablar.", "I cannot see, but I listen. And the Spiral never stops talking."]],
					["El Cartógrafo", ["Los Huecos del pasillo arrastran sus cadenas día y noche. Eran como tú, ¿sabes?", "The Husks in the hall drag their chains day and night. They were like you, you know."]],
					["El Cartógrafo", ["Libéralos. Y si pasas por la Galería Rota... allí perdí mi mapa del Vestíbulo.", "Free them. And if you pass the Broken Gallery... I lost my map of the Vestibule there."]],
				]
				var done2 := func():
					Prog.start_quest("husks")
					Prog.start_quest("map")
				dialog.play(lines, done2)
			else:
				var lore := [
					[["Los Arcontes no nacieron monstruos. Eran los mejores de nosotros.", "The Archons weren't born monsters. They were the best of us."]],
					[["Cien círculos hacia abajo. Nadie ha vuelto a subir. Nadie que yo haya oído.", "A hundred circles down. No one has ever climbed back up. No one I've heard."]],
					[["La Voz que te despertó... ¿te dijo su nombre? A mí tampoco.", "The Voice that woke you... did it tell you its name? It never told me either."]],
				]
				var pick: Array = lore[int(Prog.playtime) % lore.size()]
				dialog.play([["El Cartógrafo", pick[0]]], Callable())

func _open_forge() -> void:
	menu.open("weapons", {"forge": true})

# ====================================================================== jefes
@rpc("any_peer", "call_remote", "reliable")
func _request_boss() -> void:
	if multiplayer.is_server():
		_server_start_boss()

func _server_start_boss() -> void:
	if _boss_started or wflags.get("seravel_dead", false):
		return
	for e in enemies:
		if e.type == "seravel":
			bcast("_boss_intro", [e.idx])
			return

@rpc("any_peer", "call_remote", "reliable")
func _boss_intro(idx: int) -> void:
	_boss_started = true
	var boss: Enemy = enemies[idx]
	active_boss = boss
	set_gate(false)
	Prog.quest_step("main1", "enter_circle")
	var lp := local_player()
	if lp:
		lp.cutscene = true
		if lp.global_position.y > 27 * TS:
			lp.respawn_at(tile_pos(49, 24))
	Audio.stop_music(1.5)
	hud.letterbox(true)
	_cam_focus = boss.global_position + Vector2(0, -24)
	await get_tree().create_timer(1.4).timeout
	Audio.sfx("roar")
	G.shake(4.0, 0.8)
	hud.title_card(G.T("boss_seravel"), ["Arconte del Primer Estrato", "Archon of the First Stratum"])
	await get_tree().create_timer(1.2).timeout
	var lines := [
		["Seravel", ["Otro Desplumado... ¿Cuántos más enviará la Voz antes de entender?", "Another Featherless... How many more will the Voice send before you understand?"]],
		["Seravel", ["Nadie cruza estas puertas. Ni hacia abajo... ni hacia arriba.", "No one passes these gates. Not downward... nor upward."]],
		["Seravel", ["Te concederé lo que todos piden al final. Descanso.", "I will grant you what they all beg for in the end. Rest."]],
	]
	var done := func():
		_cam_focus = null
		hud.letterbox(false)
		if lp:
			lp.cutscene = false
		boss.active = true
		boss.state = "chase"
		boss.cooldown = 0.8
		hud.show_boss(boss)
		Audio.play_music("boss1", 0.3)
	dialog.play(lines, done, true)

func show_boss_line(line: Array) -> void:
	hud.subtitle("Seravel", G.L(line), 3.0)

func _on_carcelero_dead(e: Enemy) -> void:
	wflags["carcelero_dead"] = true
	Prog.flags["carcelero_dead"] = true
	Prog.quest_step("main1", "kill_carcelero")
	Prog.quest_progress("jailer_hunt")
	Prog.add_weapon("hammer")
	hud.hide_boss()
	active_boss = null
	hud.big_message(G.T("enemy_felled"), Color(1, 0.8, 0.45), 3.0)
	Audio.play_music("victory", 0.2)
	G.slowmo("kill", 0.25, 0.8)
	await get_tree().create_timer(2.5).timeout
	G.toast(G.T("key_got"), Color(1, 0.85, 0.4))
	set_gate(true)
	Audio.play_music("explore", 3.0)
	if multiplayer.is_server():
		Prog.save_game()

func _on_seravel_dead(e: Enemy) -> void:
	wflags["seravel_dead"] = true
	Prog.flags["seravel_dead"] = true
	hud.hide_boss()
	active_boss = null
	G.slowmo("kill", 0.2, 1.5)
	G.flash(Color(1, 1, 1, 0.8), 0.8)
	G.shake(10.0, 1.5)
	Audio.stop_music(0.3)
	Fx.burst(e.global_position + Vector2(0, -24), Color(1, 0.9, 0.6), 80, 240.0, 1.6, "fx_feather", 180.0, Vector2.UP, 1.5, false, Vector2(0, 30))
	Fx.ring(e.global_position + Vector2(0, -24), 10.0, 220.0, Color(1, 0.9, 0.6), 1.2, 10.0)
	await get_tree().create_timer(1.2).timeout
	Audio.play_music("victory", 0.1)
	hud.big_message(G.T("archon_defeated"), Color(1, 0.85, 0.45), 4.0)
	Prog.add_ecos(0)
	Prog.add_weapon("seravel")
	Prog.flasks_max += 1
	G.toast(G.T("flask_up"), Color(1, 0.6, 0.5))
	G.toast(G.T("new_spell") % G.L(Prog.SKILLS.k1.name), Color(1, 0.5, 0.55))
	Prog.quest_step("main1", "kill_seravel")
	set_gate(true)
	var lp := local_player()
	if lp:
		lp.refresh_stats(true)
	await get_tree().create_timer(4.2).timeout
	var lines := [
		["Seravel", ["Él... no es Dios. Nunca lo fue...", "He... is not God. He never was..."]],
		["Seravel", ["Busca a Azrahel... en el fondo. Él recuerda... lo que nos quitaron.", "Find Azrahel... at the bottom. He remembers... what they took from us."]],
		["", ["Un recuerdo regresa: un cielo abierto, sin cadenas. Y una voz que no era la de la Voz.", "A memory returns: an open sky, without chains. And a voice that was not the Voice's."]],
	]
	var done := func():
		hud.end_card(G.T("demo_end_title"), G.T("demo_end_body"))
		Audio.play_music("theme", 2.0)
		if multiplayer.is_server():
			Prog.save_game()
	dialog.play(lines, done, true)

# ====================================================================== muerte
func on_local_player_died(p: Player) -> void:
	Audio.sfx("die")
	hud.big_message(G.T("you_died"), Color(0.85, 0.15, 0.15), 3.0, true)
	G.slowmo("death", 0.3, 1.2)
	if Prog.ecos > 0:
		Prog.dropped_ecos = {"amount": Prog.ecos, "pos": [p.global_position.x, p.global_position.y]}
		Prog.ecos = 0
		Prog.changed.emit()
	await get_tree().create_timer(3.2).timeout
	if not is_inside_tree():
		return
	var any_alive := false
	for q in players.values():
		if q != p and q.is_alive():
			any_alive = true
	p.respawn_at(_brasa_spawn(Prog.last_brasa))
	if Prog.dropped_ecos.has("amount"):
		_spawn_ecos_drop()
	if not any_alive:
		if multiplayer.is_server():
			bcast("_reset_enemies", [])
		else:
			_rpc_reset_request.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_reset_request() -> void:
	if not multiplayer.is_server():
		return
	for q in players.values():
		if q.is_alive():
			return
	bcast("_reset_enemies", [])

# ====================================================================== intro
func _play_intro() -> void:
	var lp := local_player()
	lp.cutscene = true
	lp.state = "downed"
	hud.letterbox(true)
	hud.fade_from_black(3.0)
	_cam_focus = lp.global_position + Vector2(0, -10)
	var lines := [
		["???", ["Despierta, Desplumado.", "Wake, Featherless one."]],
		["???", ["Cayeron mil alas. Mil voces se apagaron en la Espiral.", "A thousand wings fell. A thousand voices went silent in the Spiral."]],
		["???", ["Tú aún ardes. Desciende los cien círculos...", "You still burn. Descend the hundred circles..."]],
		["???", ["...y mata al Rey del Abismo. Esa es tu penitencia. Tu única salida.", "...and slay the King of the Abyss. That is your penance. Your only way out."]],
	]
	if G.autotest != "":
		lines = []
	await get_tree().create_timer(0.8 if G.autotest == "" else 0.05).timeout
	var done := func():
		lp.state = "move"
		lp.cutscene = false
		_cam_focus = null
		hud.letterbox(false)
		lp.revive(1.0)
		hud.show_area(G.T("stratum1"), G.T("area_sanct"))
		G.toast(G.T("controls"), Color(0.85, 0.85, 0.9))
	dialog.play(lines, done, true)

class ArenaRing extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var gold := Color(0.85, 0.65, 0.3, 0.55)
		draw_arc(Vector2.ZERO, 150.0, 0, TAU, 96, gold, 2.0)
		draw_arc(Vector2.ZERO, 140.0, 0, TAU, 96, Color(gold, 0.3), 1.0)
		draw_arc(Vector2.ZERO, 60.0, 0, TAU, 64, Color(gold, 0.4), 1.0)
		for i in 12:
			var a := TAU * i / 12.0 + t * 0.05
			draw_line(Vector2.from_angle(a) * 62.0, Vector2.from_angle(a) * 138.0, Color(gold, 0.18), 1.0)
		for i in 6:
			var a2 := TAU * i / 6.0 - t * 0.1
			var p := Vector2.from_angle(a2) * 145.0
			draw_circle(p, 3.0, Color(1, 0.8, 0.4, 0.5))

class FirePatch extends Node2D:
	var owner_peer := 1
	var world: Node
	var life := 1.6
	var _hit := {}
	func _ready() -> void:
		Fx.burst(position, Color(1, 0.5, 0.15), 6, 30.0, 0.6, "fx_soft", 40.0, Vector2.UP, 0.4)
	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if randf() < 0.3:
			Fx.burst(position + Vector2(randf_range(-4, 4), 0), Color(1, 0.55, 0.2), 1, 25.0, 0.5, "fx_soft", 30.0, Vector2.UP, 0.3)
		if owner_peer == Net.my_id():
			for e in world.enemies_alive():
				if not _hit.has(e) and e.global_position.distance_to(position) < e.body_radius + 8.0:
					_hit[e] = true
					world.request_damage_enemy(e, Prog.spell_damage(6.0), Vector2.ZERO, 2.0, false)

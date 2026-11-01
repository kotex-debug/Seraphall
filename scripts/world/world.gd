extends Node2D
## Mundo del Estrato I: construye el mapa, gestiona entidades, red, jefes, misiones y escenas.

const TS := 16
const MAPW := 96
const MAPH := 96

const ROOMS := [
	{"id": "circle", "c": Vector2i(49, 14), "r": 13},
	{"id": "yard", "rect": Rect2i(38, 32, 23, 14)},
	{"id": "alcove", "rect": Rect2i(29, 36, 8, 7)},
	{"id": "alc_link", "rect": Rect2i(36, 38, 3, 3)},
	{"id": "hall2", "rect": Rect2i(47, 45, 4, 10)},
	{"id": "chains", "rect": Rect2i(35, 54, 28, 16)},
	{"id": "east", "rect": Rect2i(62, 59, 11, 4)},
	{"id": "gallery", "rect": Rect2i(72, 57, 20, 15)},
	{"id": "hall1", "rect": Rect2i(47, 69, 4, 12)},
	{"id": "sanct", "rect": Rect2i(40, 80, 18, 13)},
	{"id": "mir_link", "rect": Rect2i(38, 85, 3, 3)},
	{"id": "mirador", "rect": Rect2i(29, 82, 10, 8)},
	{"id": "nim_link", "rect": Rect2i(57, 85, 3, 3)},
	{"id": "nimbo", "c": Vector2i(66, 86), "r": 7},
	{"id": "choir_link", "rect": Rect2i(81, 45, 3, 4)},
	{"id": "choir", "c": Vector2i(82, 37), "r": 8},
	# v0.7: salas previas a cada jefe
	{"id": "celdas", "rect": Rect2i(16, 46, 20, 7)},
	{"id": "cel_link", "rect": Rect2i(34, 52, 3, 3)},
	{"id": "cel_up", "rect": Rect2i(31, 42, 3, 5)},
	{"id": "atrio", "rect": Rect2i(73, 48, 18, 6)},
	{"id": "atr_link", "rect": Rect2i(81, 53, 3, 5)},
	{"id": "esc_link", "rect": Rect2i(57, 29, 3, 4)},
	{"id": "escala", "rect": Rect2i(58, 27, 16, 3)},
	{"id": "antesala", "rect": Rect2i(65, 6, 9, 22)},
	{"id": "jui_link", "rect": Rect2i(61, 12, 5, 3)},
]
const AREAS := {"sanct": "area_sanct", "hall1": "area_sanct", "chains": "area_chains", "hall2": "area_chains", "east": "area_gallery",
	"gallery": "area_gallery", "yard": "area_yard", "alcove": "area_yard", "alc_link": "area_yard", "circle": "area_circle", "mirador": "area_mirador", "mir_link": "area_sanct",
	"nimbo": "area_nimbo", "nim_link": "area_nimbo", "choir": "area_choir", "choir_link": "area_atrio",
	"celdas": "area_celdas", "cel_link": "area_celdas", "cel_up": "area_celdas", "atrio": "area_atrio", "atr_link": "area_atrio",
	"esc_link": "area_juicio", "escala": "area_juicio", "antesala": "area_juicio", "jui_link": "area_juicio"}
const PEACE_AREAS := ["area_sanct", "area_mirador", "area_nimbo"]

var main: Node
var leaner: Depth3D.Leaner
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
var world_difficulty := 2
var asc_fight := {}

# ====================================================================== construcción
func setup(p_main: Node, mode: String) -> void:
	main = p_main
	_game_mode = mode
	name = "World"

func _ready() -> void:
	y_sort_enabled = false
	_build_map()
	leaner = Depth3D.Leaner.new()
	add_child(leaner)
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
	_scatter_decor()
	_spawn_enemies()
	_spawn_interactables()
	_build_gate()
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	_build_ambient()
	_build_background()
	_build_post()
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
		world_difficulty = Prog.difficulty
		G.set_meta("lightwing", world_difficulty == 0)
		for e in enemies:
			e.reset_state()
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

func diff() -> Dictionary:
	return Prog.DIFFICULTIES[clampi(world_difficulty, 0, Prog.DIFFICULTIES.size() - 1)]

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
	# pozos con profundidad (5): agujeros en el suelo por los que se ve el abismo, con falsa perspectiva 3D
	for pit in PITS:
		var pr: Rect2i = pit[0]
		for y in range(pr.position.y, pr.end.y):
			for x in range(pr.position.x, pr.end.x):
				grid[y * MAPW + x] = 5
	# paredes al norte (2), bordes de acantilado (3) y faldón del acantilado (4)
	for y in MAPH:
		for x in MAPW:
			if grid[y * MAPW + x] != 0:
				continue
			if _floor_at(x, y + 1) or _floor_at(x, y + 2):
				grid[y * MAPW + x] = 2
				continue
			var near := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if _floor_at(x + dx, y + dy):
						near = true
			if near:
				grid[y * MAPW + x] = 3
	for y in MAPH:
		for x in MAPW:
			if grid[y * MAPW + x] == 0 and y > 0 and grid[(y - 1) * MAPW + x] == 3 and _floor_at(x, y - 2):
				grid[y * MAPW + x] = 4
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
				elif rid == "atrio" or rid == "atr_link":
					t = 22 + rng.randi_range(0, 1)
				elif rid == "antesala" or rid == "escala" or rid == "jui_link":
					t = 24 + rng.randi_range(0, 1)
				elif rid == "celdas" or rid == "cel_link" or rid == "cel_up":
					t = 20 + rng.randi_range(0, 1)
					if rng.randf() < 0.05:
						t = 27
				elif rid == "circle":
					t = 15 if rng.randf() < 0.7 else rng.randi_range(0, 3)
				if rng.randf() < 0.1 and rid != "gallery":
					t = 4 + rng.randi_range(0, 1)
				if rid == "sanct" and x >= 48 and x <= 50 and y >= 81:
					t = 10
				if (rid == "chains" or rid == "celdas") and rng.randf() < 0.05:
					t = 11
				if rid == "escala" and y == 28:
					t = 26
				if rid == "antesala" and (x == 69) and y >= 7:
					t = 26
				if rid == "mirador" or rid == "alcove":
					t = 19 if rng.randf() < 0.6 else t
				floor_layer.set_cell(c, 0, Vector2i(t, 0))
			elif g == 2:
				var below := y + 1 < MAPH and grid[(y + 1) * MAPW + x] == 1
				if below:
					var wt := 7 + rng.randi_range(0, 2)
					var br: int = room_of[(y + 1) * MAPW + x]
					var brid: String = ROOMS[br].id if br >= 0 else ""
					if brid in ["celdas", "cel_link", "cel_up"]:
						wt = 28 + rng.randi_range(0, 1)
					elif brid in ["antesala", "escala", "jui_link"]:
						wt = 30 + rng.randi_range(0, 1)
					elif brid in ["atrio", "atr_link"] and rng.randf() < 0.5:
						wt = 32 + rng.randi_range(0, 1)
					wall_layer.set_cell(c, 0, Vector2i(wt, 0))
				else:
					wall_layer.set_cell(c, 0, Vector2i(6, 0))
			elif g == 3:
				wall_layer.set_cell(c, 0, Vector2i(16 if _floor_at(x, y - 1) else 18, 0))
			elif g == 4:
				floor_layer.set_cell(c, 0, Vector2i(17, 0))
			elif g == 5:
				wall_layer.set_cell(c, 0, Vector2i(18, 0))
	for pit in PITS:
		var dp := DepthPit.new()
		var pr2: Rect2i = pit[0]
		dp.position = Vector2(pr2.position) * TS
		dp.size = Vector2(pr2.size) * TS
		dp.style = pit[1]
		dp.z_index = -9
		add_child(dp)
	var decals := FloorDecals.new()
	decals.world = self
	decals.z_index = -9
	add_child(decals)
	var rim := EdgeRim.new()
	rim.world = self
	rim.z_index = -9
	add_child(rim)
	# v0.7: profundidad 3D (abismo con capas y faldones de roca en perspectiva)
	var aby := Depth3D.Abyss.new()
	aby.world = self
	add_child(aby)
	var cd := Depth3D.CliffDepth.new()
	cd.world = self
	add_child(cd)
	var near := Depth3D.NearLayer.new()
	near.world = self
	add_child(near)

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
	var ntiles: int = src.texture.get_width() / TS
	for i in ntiles:
		src.create_tile(Vector2i(i, 0))
	for i in [6, 7, 8, 9, 12, 16, 18, 28, 29, 30, 31, 32, 33]:
		if i >= ntiles:
			continue
		var td := src.get_tile_data(Vector2i(i, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	return ts

func _scatter_decor() -> void:
	## Escombros, huesos y plumas repartidos por las salas (decoración sin colisión)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var skip := ["yard", "circle", "choir", "nimbo", "escala", "antesala"]
	for r in ROOMS:
		if r.id in skip:
			continue
		var rect := _rect_of(r)
		var n := int(rect.size.x * rect.size.y / 40)
		for k in n:
			var x := rng.randi_range(rect.position.x + 1, rect.end.x - 2)
			var y := rng.randi_range(rect.position.y + 1, rect.end.y - 2)
			if not _floor_at(x, y):
				continue
			var p := tile_pos(x + rng.randf_range(-0.3, 0.3), y + rng.randf_range(-0.3, 0.3))
			var kind := rng.randi_range(0, 5)
			if kind <= 2:
				_prop("rubble", p, 3, rng.randi_range(0, 2))
			elif kind <= 4:
				_prop("bones", p, 3, rng.randi_range(0, 2))
			else:
				var c := _prop("candle", p, 4, rng.randi_range(0, 3), 0.0, Color(1, 0.65, 0.3), 0.7)
				c.set_meta("anim", 4)

const PITS := [[Rect2i(37, 61, 4, 4), "ember"], [Rect2i(52, 60, 5, 4), "ember"], [Rect2i(79, 58, 6, 5), "void"],
	[Rect2i(24, 48, 4, 3), "chains"], [Rect2i(65, 16, 2, 6), "light"], [Rect2i(72, 16, 2, 6), "light"], [Rect2i(75, 49, 2, 3), "void"]]

func is_pit_at(p: Vector2) -> bool:
	var x := int(floor(p.x / TS))
	var y := int(floor(p.y / TS))
	return x >= 0 and y >= 0 and x < MAPW and y < MAPH and grid[y * MAPW + x] == 5

func _floor_at(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < MAPW and y < MAPH and grid[y * MAPW + x] == 1

func tile_pos(tx: float, ty: float) -> Vector2:
	return Vector2(tx * TS + TS / 2.0, ty * TS + TS / 2.0)

func is_wall_at(p: Vector2) -> bool:
	var x := int(floor(p.x / TS))
	var y := int(floor(p.y / TS))
	if x < 0 or y < 0 or x >= MAPW or y >= MAPH:
		return true
	if not gate_open and gate_body and Rect2(57 * TS, 31 * TS, 3 * TS, TS).has_point(p):
		return true
	return grid[y * MAPW + x] != 1

# ====================================================================== cartografía (mapa y minimapa)
const AREA_COLORS := {"area_sanct": Color(1, 0.7, 0.4), "area_chains": Color(0.75, 0.6, 0.85), "area_gallery": Color(0.45, 0.6, 1.0),
	"area_yard": Color(1, 0.5, 0.4), "area_circle": Color(1, 0.3, 0.4), "area_mirador": Color(0.6, 0.9, 1.0),
	"area_nimbo": Color(1, 0.88, 0.5), "area_choir": Color(0.78, 0.55, 1.0), "area_celdas": Color(0.85, 0.45, 0.35),
	"area_atrio": Color(0.6, 0.5, 0.95), "area_juicio": Color(1, 0.85, 0.55)}
var _map_tex: ImageTexture
var _map_seen := -1

func current_area() -> String:
	return _area

func _room_corner(id: String) -> Vector2:
	for r in ROOMS:
		if r.id == id:
			return Vector2(_rect_of(r).position) + Vector2(1.6, 1.4)
	return Vector2.ZERO

func _room_center(id: String) -> Vector2:
	for r in ROOMS:
		if r.id == id:
			var rc := _rect_of(r)
			return Vector2(rc.position) + Vector2(rc.size) / 2.0
	return Vector2.ZERO

func map_texture() -> ImageTexture:
	var n := 0
	for r in ROOMS:
		if Prog.flags.get("seen_" + r.id, false):
			n += 1
	if _map_tex and n == _map_seen:
		return _map_tex
	_map_seen = n
	var img := Image.create(MAPW, MAPH, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in MAPH:
		for x in MAPW:
			var i := y * MAPW + x
			# muros (caras norte) de las salas vistas: dan grosor al mapa
			if grid[i] == 2:
				for dy in [1, 2]:
					if y + dy < MAPH and grid[(y + dy) * MAPW + x] == 1 and room_of[(y + dy) * MAPW + x] >= 0:
						var wr: String = ROOMS[room_of[(y + dy) * MAPW + x]].id
						if Prog.flags.get("seen_" + wr, false):
							var wc: Color = AREA_COLORS.get(AREAS.get(wr, ""), Color.WHITE)
							img.set_pixel(x, y, wc.darkened(0.78 if dy == 1 else 0.68))
							break
				continue
			# pozos: agujero oscuro con brasa o vacío en el fondo
			if grid[i] == 5 and room_of[i] >= 0 and Prog.flags.get("seen_" + ROOMS[room_of[i]].id, false):
				var core := false
				for pit in PITS:
					var pr: Rect2i = pit[0]
					if pr.has_point(Vector2i(x, y)) and absf(x - pr.get_center().x + 0.5) <= 1.0 and absf(y - pr.get_center().y + 0.5) <= 1.0:
						core = true
				img.set_pixel(x, y, Color(1, 0.55, 0.25) if core else Color(0.05, 0.02, 0.06))
				continue
			if grid[i] != 1 or room_of[i] < 0:
				continue
			var rid: String = ROOMS[room_of[i]].id
			if not Prog.flags.get("seen_" + rid, false):
				continue
			var c: Color = AREA_COLORS.get(AREAS.get(rid, ""), Color.WHITE)
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= MAPW or ny >= MAPH or grid[ny * MAPW + nx] != 1:
					edge = true
			var checker := 0.06 if (x + y) % 2 == 0 else 0.0
			img.set_pixel(x, y, c.lightened(0.3) if edge else Color(c.darkened(0.55 - checker), 0.92))
	_map_tex = ImageTexture.create_from_image(img)
	return _map_tex

func map_markers() -> Array:
	## [tipo, posición en casillas, color, etiqueta]
	var out := []
	for id in interactables:
		var it: Interactable = interactables[id]
		if not is_instance_valid(it) or not Prog.flags.get("seen_" + room_at(it.position), false):
			continue
		var tp: Vector2 = it.position / TS
		match it.kind:
			"brasa":
				out.append(["brasa", tp, UIKit.GOLD if it.used else Color(0.5, 0.4, 0.3), ""])
			"npc":
				out.append(["npc", tp, UIKit.CYAN, G.L(it.data.get("name", ["", ""])).get_slice(",", 0)])
			"chest":
				if not it.used and Prog.item_count("map_carto") > 0:
					out.append(["chest", tp, UIKit.GOLD, ""])
			"ecos":
				out.append(["ecos", tp, Color(0.5, 0.85, 1.0), ""])
			"bench":
				out.append(["bench", tp, Color(0.7, 0.9, 1.0), ""])
			"lore":
				out.append(["lore", tp, Color(0.6, 0.85, 1.0), ""])
	# pruebas de las antesalas, cierres e inscripciones
	for tid in ["celdas", "atrio", "umbral"]:
		var room: String = TRIALS[tid].room if TRIALS.has(tid) else "atrio"
		if Prog.flags.get("seen_" + room, false):
			out.append(["trial_done" if trial_done(tid) else "trial", _room_corner(room), UIKit.GOLD if trial_done(tid) else UIKit.RED, ""])
	for L in LOCKS:
		var lr: Rect2i = L[1]
		if not trial_done(L[0]) and Prog.flags.get("seen_" + room_at(tile_pos(lr.position.x, lr.position.y + 1)), false) or (not trial_done(L[0]) and Prog.flags.get("seen_" + room_at(tile_pos(lr.position.x, lr.position.y - 1)), false)):
			out.append(["lock", Vector2(lr.get_center()), Color(0.75, 0.7, 0.8), ""])
	for e in enemies:
		if e.is_boss and Prog.flags.get("seen_" + room_at(e.spawn_pos), false):
			var dead: bool = wflags.get(Prog.BOSS_INFO.get(e.type, {}).get("flag", "-"), false)
			out.append(["boss_dead" if dead else "boss", e.spawn_pos / TS, UIKit.RED, G.T(e.cfg.get("title", "boss_carcelero"))])
	for pid in players:
		var q: Player = players[pid]
		if pid != Net.my_id():
			out.append(["ally", q.global_position / TS, Color(0.5, 0.8, 1.0) if q.variant == 2 else UIKit.PINK, "P%d" % q.variant])
	return out

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
	if tex in ["pillar", "statue", "organ"]:
		leaner.add(s, 1.5 if tex != "organ" else 1.1)
	if collide > 0.0:
		var b := StaticBody2D.new()
		b.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = collide
		cs.shape = sh
		b.add_child(cs)
		b.position = pos
		entities.add_child(b)
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
	for p in [Vector2(75, 59), Vector2(89, 59), Vector2(77, 65), Vector2(87, 64), Vector2(76, 68), Vector2(90, 68)]:
		_prop("pillar", tile_pos(p.x, p.y), 2, 1, 5.0)
	for p in [Vector2(73, 58), Vector2(90, 58), Vector2(73, 70), Vector2(82, 70)]:
		_prop("candle", tile_pos(p.x, p.y), 4, 2, 0.0, Color(0.55, 0.65, 1.0), 1.4)
	_prop("statue", tile_pos(90, 63))
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
	# Mirador del Ala Rota: lugar de paz
	_prop("broken_wing", tile_pos(30.5, 84.5))
	_prop("candle", tile_pos(37, 83), 4, 1, 0.0, Color(0.7, 0.85, 1.0), 1.2)
	_prop("candle", tile_pos(31, 88.5), 4, 2, 0.0, Color(0.7, 0.85, 1.0), 1.2)
	for fp in [[Vector2(32, 87), 14, Color(0.85, 0.92, 1.0)], [Vector2(36, 88.5), 10, Color(0.7, 0.8, 1.0)], [Vector2(34.5, 83.5), 8, Color(1.0, 0.85, 0.95)],
			[Vector2(30, 86.5), 9, Color(0.85, 0.92, 1.0)], [Vector2(31, 39.5), 10, Color(1.0, 0.8, 0.5)], [Vector2(35, 41.5), 8, Color(1.0, 0.75, 0.55)],
			[Vector2(42.5, 91.5), 7, Color(0.85, 0.92, 1.0)], [Vector2(55.5, 91.5), 7, Color(0.85, 0.92, 1.0)]]:
		var f := FlowerPatch.new()
		f.position = tile_pos(fp[0].x, fp[0].y)
		f.count = fp[1]
		f.petal = fp[2]
		entities.add_child(f)
	for zone in [Rect2(29 * TS, 82 * TS, 10 * TS, 8 * TS), Rect2(29 * TS, 36 * TS, 8 * TS, 7 * TS), Rect2(40 * TS, 80 * TS, 18 * TS, 13 * TS), Rect2(59 * TS, 79 * TS, 14 * TS, 14 * TS)]:
		_fireflies(zone)
	_build_arena_decor()
	_build_antechambers()

var arena_lights: Array[PointLight2D] = []

func _build_arena_decor() -> void:
	# --- Sala del Nimbo (centro: mesa redonda)
	var table := RoundTable.new()
	table.position = tile_pos(66, 86)
	entities.add_child(table)
	for b in [Vector2(61.5, 80.5), Vector2(70.5, 80.5)]:
		var bn := _prop("banner", tile_pos(b.x, b.y), 2, 1)
		bn.z_index = 0
	for b2 in [Vector2(60, 86), Vector2(72, 86)]:
		var br := _prop("brazier", tile_pos(b2.x, b2.y), 4, int(b2.x) % 4, 4.0, Color(1, 0.6, 0.3), 1.6)
		br.set_meta("anim", 4)
	# --- Patio del Carcelero: jaulas colgantes, braseros, huesos
	for c in [Vector2(42, 34.5), Vector2(46, 34.2), Vector2(53, 34.6), Vector2(57, 34.3)]:
		var cg := _prop("cage", tile_pos(c.x, c.y), 2, 0)
		cg.set_meta("sway", randf() * TAU)
	for b3 in [Vector2(41, 39), Vector2(57, 39), Vector2(41, 43), Vector2(57, 43)]:
		var br2 := _prop("brazier", tile_pos(b3.x, b3.y), 4, int(b3.y) % 4, 4.0, Color(1, 0.45, 0.2), 1.8)
		br2.set_meta("anim", 4)
		arena_lights.append(br2.get_meta("flicker"))
	for k in 6:
		_prop("bones", tile_pos(40 + k * 3.3, 36 + (k % 3) * 3.0), 3, k % 3)
	# --- Círculo de la Guardiana: pilares rotos en anillo, estandartes, haces de luz
	for i in 10:
		var a := TAU * i / 10.0 + 0.3
		var p := tile_pos(49, 14) + Vector2(cos(a) * 176.0, sin(a) * 150.0)
		if p.y > tile_pos(49, 24).y:
			continue
		_prop("pillar", p, 2, 1 if i % 3 == 0 else 0, 5.0)
	for bp in [Vector2(43, 3.5), Vector2(55, 3.5)]:
		_prop("banner", tile_pos(bp.x, bp.y), 2, 0)
	var shafts := LightShafts.new()
	shafts.position = tile_pos(49, 14)
	shafts.col = Color(1, 0.85, 0.55)
	add_child(shafts)
	# --- Nave del Coro: órganos, velas azules, vitrales
	for o in [Vector2(78, 31), Vector2(86, 31)]:
		_prop("organ", tile_pos(o.x, o.y), 1, 0, 8.0)
	for cv in [Vector2(76, 34), Vector2(88, 34), Vector2(76, 41), Vector2(88, 41), Vector2(82, 30.5)]:
		_prop("candle", tile_pos(cv.x, cv.y), 4, int(cv.x) % 4, 0.0, Color(0.6, 0.5, 1.0), 1.5)
	for bc in [Vector2(80, 30), Vector2(84, 30)]:
		_prop("banner", tile_pos(bc.x, bc.y), 2, 1)
	var glass := LightShafts.new()
	glass.position = tile_pos(82, 37)
	glass.col = Color(0.75, 0.55, 1.0)
	glass.stained = true
	add_child(glass)

func arena_fx(kind: String) -> void:
	match kind:
		"seravel_p3":
			create_tween().tween_property(canvas_mod, "color", Color(0.75, 0.62, 0.55), 1.5)
		"carcelero_p2":
			for l in arena_lights:
				if is_instance_valid(l):
					l.color = Color(1, 0.25, 0.1)
					l.texture_scale = 2.4

func _fireflies(r: Rect2) -> void:
	var p := CPUParticles2D.new()
	p.position = r.get_center()
	p.amount = int(r.size.x * r.size.y / 900.0)
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.texture = Fx.tex("fx_soft")
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = r.size / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, -2)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.orbit_velocity_min = -0.05
	p.orbit_velocity_max = 0.05
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.22
	var g := Gradient.new()
	g.set_color(0, Color(0.8, 1.0, 0.6, 0.0))
	g.add_point(0.3, Color(0.85, 1.0, 0.55, 1.0))
	g.add_point(0.5, Color(0.85, 1.0, 0.55, 0.3))
	g.add_point(0.7, Color(0.85, 1.0, 0.55, 1.0))
	g.set_color(g.get_point_count() - 1, Color(0.8, 1.0, 0.6, 0.0))
	p.color_ramp = g
	p.material = Fx.add_material()
	p.z_index = 20
	add_child(p)

func _build_gate() -> void:
	gate_spr = Sprite2D.new()
	gate_spr.texture = Fx.tex("gate")
	gate_spr.region_enabled = true
	gate_spr.region_rect = Rect2(0, 0, 48, 40)
	gate_spr.position = Vector2(58.5 * TS, 32 * TS - 20)
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
	gate_body.position = Vector2(58.5 * TS, 31.5 * TS)
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

var bg_rect: ColorRect
var post_rect: ColorRect
var _waves: Array = []   # [pos_mundo, t, dur, fuerza]
var _chroma := 0.0
var _desat := 0.0
var _calm := 0.0

func _build_background() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	cl.name = "Background"
	add_child(cl)
	bg_rect = ColorRect.new()
	bg_rect.size = Vector2(640, 360)
	bg_rect.material = UIKit.mat("abyss")
	cl.add_child(bg_rect)

func _build_post() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 2
	cl.name = "PostFX"
	add_child(cl)
	post_rect = ColorRect.new()
	post_rect.size = Vector2(640, 360)
	post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_rect.material = UIKit.mat("post_fx")
	cl.add_child(post_rect)
	G.shockwave_requested.connect(_on_shockwave)
	G.chroma_requested.connect(_on_chroma)
	G.punch_requested.connect(_on_punch)

func _on_shockwave(pos: Vector2, strength: float, dur: float) -> void:
	_waves.append([pos, 0.0, dur, strength])
	if _waves.size() > 4:
		_waves.pop_front()

func _on_chroma(amount: float, dur: float) -> void:
	_chroma = max(_chroma, amount)
	var tw := create_tween()
	tw.tween_property(self, "_chroma", 0.0, dur)

func _on_punch(amount: float) -> void:
	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2.ONE * (1.0 + amount), 0.04)
	tw.tween_property(camera, "zoom", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC)

func _update_post(delta: float) -> void:
	if bg_rect:
		var bm: ShaderMaterial = bg_rect.material
		bm.set_shader_parameter("cam", camera.position)
		bm.set_shader_parameter("calm", _calm)
	if post_rect == null:
		return
	var pm: ShaderMaterial = post_rect.material
	var vt := get_viewport().get_canvas_transform()
	var vs := get_viewport().get_visible_rect().size
	for i in 4:
		var key := "w%d" % i
		if i < _waves.size():
			var w: Array = _waves[i]
			w[1] += delta
			var k: float = clamp(w[1] / w[2], 0.0, 1.0)
			var sp: Vector2 = (vt * w[0]) / vs
			pm.set_shader_parameter(key, Vector4(sp.x, sp.y, lerpf(0.0, 0.45, k), w[3] * (1.0 - k)))
		else:
			pm.set_shader_parameter(key, Vector4.ZERO)
	for i in range(_waves.size() - 1, -1, -1):
		if _waves[i][1] >= _waves[i][2]:
			_waves.remove_at(i)
	var slow := Engine.time_scale < 0.6 and Engine.time_scale > 0.1
	_desat = lerpf(_desat, 0.55 if slow else 0.0, clamp(delta * 10.0 / max(Engine.time_scale, 0.05), 0.0, 1.0))
	pm.set_shader_parameter("desat", _desat)
	pm.set_shader_parameter("tint", Color(0.55, 0.75, 1.0, _desat * 0.5))
	pm.set_shader_parameter("chroma", _chroma)
	var lp := local_player()
	var danger := 0.0
	if lp and lp.is_alive():
		danger = clamp(1.0 - lp.hp / Prog.max_hp() / 0.3, 0.0, 1.0)
	pm.set_shader_parameter("danger", danger)

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
		["acolito", 78, 52], ["acolito", 87, 60], ["acolito", 82, 67],
		["bestia", 76, 61], ["bestia", 88, 66], ["hueco", 84, 70], ["hueco", 74, 59],
		["acolito", 70, 28], ["hueco", 63, 28], ["hueco", 35, 54],
		["carcelero", 49, 38],
		["choir", 82, 35],
		["seravel", 49, 10],
	]
	for e in list:
		_add_enemy(e[0], tile_pos(e[1], e[2]), false)

func _add_enemy(type: String, pos: Vector2, extra: bool) -> Enemy:
	var e: Enemy
	match type:
		"seravel":
			e = preload("res://scripts/actors/boss_seravel.gd").new()
		"carcelero":
			e = preload("res://scripts/actors/boss_carcelero.gd").new()
		"choir":
			e = preload("res://scripts/actors/boss_choir.gd").new()
		_:
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
	_add_inter("brasa", "nimbo", tile_pos(66, 91.6))
	_add_inter("npc", "brenna", tile_pos(43.5, 84), {"sheet": "npc_brenna", "name": ["Brenna, la herrera", "Brenna, the smith"], "light": Color(1, 0.5, 0.25)})
	_add_inter("npc", "carto", tile_pos(55, 84), {"sheet": "npc_carto", "name": ["El Cartógrafo Ciego", "The Blind Cartographer"], "flip": true, "light": Color(0.6, 0.7, 1.0)})
	_add_inter("chest", "chest_chains", tile_pos(61, 55), {"feathers": 2, "ecos": 120, "items": {"bomb": 2}})
	_add_inter("chest", "chest_gallery", tile_pos(90, 59), {"weapon": "spear", "items": {"amulet_wing": 1, "ointment": 1}})
	_add_inter("chest", "chest_yard", tile_pos(59, 34), {"feathers": 1, "ecos": 250, "items": {"iron": 1, "incense": 1}})
	_add_inter("chest", "chest_mirador", tile_pos(37.5, 88.5), {"items": {"amulet_eye": 1}, "ecos": 150})
	_add_inter("bench", "bench_mirador", tile_pos(34, 85.5), {"memory": "m1"})
	_add_inter("npc", "ozias", tile_pos(62.5, 83), {"sheet": "npc_ozias", "name": ["Ozias, el Grabador", "Ozias, the Engraver"], "light": Color(0.4, 0.9, 1.0)})
	_add_inter("npc", "ilse", tile_pos(69.5, 83), {"sheet": "npc_ilse", "name": ["Madre Ilse", "Mother Ilse"], "flip": true, "light": Color(0.6, 0.75, 1.0)})
	_add_inter("npc", "nyx", tile_pos(62.5, 89.5), {"sheet": "npc_nyx", "name": ["Nyx, de Plumas Negras", "Nyx of the Black Feathers"], "light": Color(1, 0.8, 0.4)})
	_add_inter("npc", "velaria", tile_pos(69.5, 89.5), {"sheet": "npc_velaria", "name": ["Sor Velaria", "Sister Velaria"], "flip": true, "light": Color(1, 0.4, 0.4)})
	_add_inter("chest", "chest_choir", tile_pos(82, 30.8), {"ecos": 400, "items": {"iron": 1}})
	_add_inter("pickup", "f1", tile_pos(36, 68), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "f2", tile_pos(62, 68), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "f3", tile_pos(74, 70), {"icon": "feather", "feathers": 1})
	_add_inter("pickup", "f4", tile_pos(89.5, 49.3), {"icon": "feather", "feathers": 1})
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
	_refresh_locks(instant)
	for e in enemies:
		if e.type == "carcelero" and wflags.get("carcelero_dead", false):
			e.die(); e.visible = false
		if e.type == "seravel" and wflags.get("seravel_dead", false):
			e.die(); e.visible = false
		if e.type == "choir" and wflags.get("choir_dead", false):
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
	if not Prog.shadow.is_empty():
		get_tree().create_timer(1.0).timeout.connect(_request_shadow)
	if Prog.ng > 0:
		get_tree().create_timer(2.5).timeout.connect(hud.big_message.bind(G.T("ng_plus") + " " + str(Prog.ng), Color(1, 0.4, 0.5), 3.0, false))

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
	_update_post(delta)
	var lp := local_player()
	if G.photo_mode:
		_photo_tick()
		return
	_v04_tick(delta, lp)
	_trial_tick(delta)
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
	var now := Time.get_ticks_msec() * 0.001
	for c in entities.get_children():
		if c.has_meta("sway"):
			c.rotation = sin(now * 1.3 + float(c.get_meta("sway"))) * 0.06
		if c.has_meta("anim"):
			var fr: int = int(now * 10.0 + c.position.x) % 4
			c.region_rect.position.x = fr * c.region_rect.size.x
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
	if event.is_action_pressed("photo") and not menu.visible and not dialog.is_open():
		_toggle_photo()
		return
	if G.photo_mode:
		if event.is_action_pressed("pause"):
			_toggle_photo()
		elif event.is_action_pressed("shot"):
			_screenshot()
		return
	if event.is_action_pressed("map") and not dialog.is_open():
		if menu.visible and menu.tab == "map":
			menu.close()
		elif not menu.visible:
			menu.open("map", {})
	elif event.is_action_pressed("menu") and not dialog.is_open():
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
	if not Prog.flags.get("seen_" + r, false):
		Prog.flags["seen_" + r] = true
	var a: String = AREAS[r]
	if a != _area:
		var first := _area == ""
		_area = a
		if not first:
			hud.show_area("", G.T(a))
		var target := Color(0.42, 0.45, 0.6) if a == "area_gallery" else (Color(0.55, 0.45, 0.5) if a == "area_circle" else Color(0.5, 0.46, 0.58))
		if a == "area_mirador":
			target = Color(0.62, 0.62, 0.75)
		elif a == "area_nimbo":
			target = Color(0.64, 0.56, 0.56)
		elif a == "area_choir" or a == "area_atrio":
			target = Color(0.46, 0.42, 0.64)
		elif a == "area_celdas":
			target = Color(0.52, 0.42, 0.46)
		elif a == "area_juicio":
			target = Color(0.62, 0.55, 0.52)
		create_tween().tween_property(canvas_mod, "color", target, 1.5)
		var peaceful := a in PEACE_AREAS
		create_tween().tween_property(self, "_calm", 1.0 if peaceful else 0.0, 2.0)
		if active_boss == null and not _contemplating:
			Audio.play_music("peace" if peaceful else "explore", 2.5)
	if r == "yard" and not wflags.get("carcelero_intro", false) and not wflags.get("carcelero_dead", false) and lp.is_alive() and lp.global_position.y < 43 * TS:
		if multiplayer.is_server():
			_server_start_carcelero()
		else:
			_request_carcelero.rpc_id(1)
	if r == "choir" and not wflags.get("choir_intro", false) and not wflags.get("choir_dead", false) and lp.is_alive() and asc_fight.is_empty():
		if multiplayer.is_server():
			_server_start_choir()
		else:
			_request_choir.rpc_id(1)
	_check_trials(lp, r)
	if r == "atrio" and not Prog.flags.get("atrio_echo", false) and not trial_done("atrio"):
		_atrio_echo()
	if r == "circle" and not wflags.get("seravel_dead", false) and not _boss_started and lp.is_alive() and asc_fight.is_empty():
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
	if _spare_target and is_instance_valid(_spare_target) and _spare_target.is_alive():
		bcast("_spare_boss", [_spare_target.idx])
		_spare_target = null
		return
	var it := nearest_interactable(p)
	if it == null:
		return
	match it.kind:
		"brasa":
			if not it.used:
				if it.id != "sanct":
					if Prog.wing_feathers <= 0:
						G.toast(G.T("no_feathers"), UIKit.PINK)
						return
					Prog.lose_wing_feather()
					send_look()
					Fx.burst(p.global_position + Vector2(0, -12), Look.color_of(G.look, "wing"), 10, 60.0, 1.0, "fx_feather", 60.0, (it.global_position - p.global_position).normalized(), 1.0, false, Vector2(0, 10))
				bcast("_light_brasa", [it.id])
			else:
				_rest_at(it.id)
		"npc":
			_talk(it.id)
		"chest":
			bcast("_open_chest", [it.id])
		"bench":
			_contemplate(it)
		"bell":
			bcast("_ring_bell", [it.id])
		"lore":
			var ll := []
			for l in it.data.lines:
				ll.append([G.T(l[0]), l[1]])
			dialog.play(ll, Callable())

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
				Prog.unrecovered = 0
				Prog.changed.emit()
				Audio.sfx("levelup", -6.0)
				Fx.burst(it.global_position, Color(0.6, 0.85, 1), 24, 80.0, 0.8, "fx_soft", 180.0, Vector2.UP, 0.4)
				it.set_opened()
				interactables.erase("ecosdrop")
				return
			if it.data.get("local", false):
				_pickup(it.id)
			else:
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
	_welcome.rpc_id(sender, wflags, estates, local_player().position, world_difficulty)
	_player_look.rpc_id(sender, Net.my_id(), G.look, Prog.wing_feathers)
	G.toast(G.T("partner_joined"), Color(0.6, 1, 0.8))
	Audio.sfx("quest")

@rpc("authority", "call_remote", "reliable")
func _welcome(flags: Dictionary, estates: Array, host_pos: Vector2, host_diff: int) -> void:
	wflags = flags
	world_difficulty = host_diff
	G.set_meta("lightwing", world_difficulty == 0)
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
	send_look()
	Audio.play_music("explore")
	hud.show_area(G.T("stratum1"), G.T("area_sanct"))
	if not Prog.quest_active("main1") and not Prog.quest_done("main1"):
		Prog.start_quest("main1")

func send_look() -> void:
	var lp := local_player()
	if lp:
		lp.refresh_look()
	for pid in joined_peers:
		_player_look.rpc_id(pid, Net.my_id(), G.look, Prog.wing_feathers)

@rpc("any_peer", "call_remote", "reliable")
func _player_look(peer: int, l: Dictionary, feathers: int) -> void:
	if players.has(peer):
		players[peer].set_look(l, feathers)

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
		Audio.play_music("boss_carcelero")
		seal_for("carcelero")

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
	var lpk := local_player()
	if lpk and lpk.is_alive() and lpk.global_position.distance_to(e.global_position) < 280.0:
		Prog.record_kill(e.type)
	if e.type == "sombra":
		if int(e.get_meta("owner", -1)) == Net.my_id():
			Prog.ecos += int(e.get_meta("amount", 0))
			Prog.shadow = {}
			Prog.unrecovered = 0
			Prog.changed.emit()
			hud.big_message(G.L(["SOMBRA DISIPADA", "SHADOW DISPELLED"]), Color(0.75, 0.55, 1.0), 2.5)
			Audio.play_music("explore", 2.5)
			Fx.souls(e.global_position + Vector2(0, -8), lpk, 16)
		return
	if e.is_boss and asc_fight.is_empty() and not wflags.get(Prog.BOSS_INFO.get(e.type, {}).get("flag", "-"), false):
		var back := 0
		for k in 2:
			if Prog.regrow_wing_feather():
				back += 1
		if back > 0:
			get_tree().create_timer(2.5).timeout.connect(_feathers_back.bind(back))
	Prog.add_ecos(e.cfg.ecos)
	Fx.text(e.global_position + Vector2(0, 26), "+%d %s" % [int(e.cfg.ecos * Prog.ecos_mult()), G.T("ecos")], Color(0.6, 0.85, 1.0), 8)
	Fx.souls(e.global_position + Vector2(0, -8), local_player(), 5 if not e.is_boss else 24)
	if e.is_boss and not asc_fight.is_empty() and asc_fight.boss == e.type:
		_end_ascension(true)
		return
	_drop_loot(e)
	match e.type:
		"hueco":
			Prog.quest_progress("husks")
		"carcelero":
			_on_carcelero_dead(e)
		"choir":
			_on_choir_dead(e)
		"seravel":
			_on_seravel_dead(e)

const LOOT := {"hueco": [["bomb", 0.14], ["incense", 0.05]], "acolito": [["incense", 0.14], ["bomb", 0.08]],
	"bestia": [["ointment", 0.16], ["bomb", 0.1]], "carcelero": [["key_vestibule", 1.0], ["amulet_ash", 1.0], ["iron", 1.0]],
	"seravel": [["phoenix", 1.0], ["iron", 1.0], ["tear", 1.0]], "choir": [["choir_heart", 1.0], ["tear", 1.0]]}

func _drop_loot(e: Enemy) -> void:
	## Cada jugador tira su propio botín (determinista por enemigo para no duplicar en red)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(e.idx) + str(Prog.playtime).substr(0, 3) + str(Net.my_id()))
	for l in LOOT.get(e.type, []):
		if rng.randf() < l[1] * (1.6 if event != "" else 1.0):
			if l[0] == "key_vestibule" and Prog.item_count("key_vestibule") > 0:
				continue
			var it := _add_inter("pickup", "loot_%d_%s_%d" % [e.idx, l[0], Time.get_ticks_msec()], e.global_position + Vector2(rng.randf_range(-10, 10), rng.randf_range(-6, 6)),
				{"icon": Prog.ITEMS[l[0]].icon, "items": {l[0]: 1}, "local": true})
			it.set_meta("loot", true)

func throw_bomb(from: Vector2, to: Vector2, owner: int) -> void:
	bcast("_bomb", [from, to, owner])

@rpc("any_peer", "call_remote", "reliable")
func _bomb(from: Vector2, to: Vector2, owner: int) -> void:
	var b := Sprite2D.new()
	b.texture = Fx.tex("icon_bomb")
	b.position = from
	fx_layer.add_child(b)
	Audio.sfx("swing", -4.0)
	var tw := b.create_tween()
	tw.set_parallel(true)
	tw.tween_property(b, "position:x", to.x, 0.5)
	tw.tween_method(func(k: float): b.position.y = lerpf(from.y, to.y, k) - sin(k * PI) * 46.0, 0.0, 1.0, 0.5)
	tw.tween_property(b, "rotation", TAU * 2.0, 0.5)
	tw.chain().tween_callback(_bomb_explode.bind(b, to, owner))

func _bomb_explode(b: Node, pos: Vector2, owner: int) -> void:
	b.queue_free()
	Audio.sfx("nova")
	Audio.sfx("slam", -4.0)
	G.shake(6.0, 0.35)
	G.shockwave(pos, 1.4, 0.6)
	G.chroma(1.2, 0.3)
	Fx.impact(pos, Color(1, 0.6, 0.2), 30.0)
	Fx.ring(pos, 4.0, 58.0, Color(1, 0.55, 0.2), 0.45, 8.0)
	Fx.burst(pos, Color(1, 0.55, 0.15), 40, 160.0, 0.8, "fx_soft", 180.0, Vector2.UP, 0.5)
	Fx.sparks(pos, Vector2.UP, Color(1, 0.8, 0.3), 24, 180.0, 360.0)
	Fx.scorch(pos, 30.0)
	Fx.light_flash(pos, Color(1, 0.55, 0.2), 2.5, 2.0, 0.5)
	if owner == Net.my_id():
		for e in enemies_alive():
			if e.global_position.distance_to(pos) < 52.0 + e.body_radius:
				request_damage_enemy(e, Prog.spell_damage(42.0), (e.global_position - pos).normalized(), 40.0, true)

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
	G.shockwave(pos, 1.2 if big else 0.8, 0.45)
	Fx.scorch(pos, r * 0.5)
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
	G.shockwave(pos, 2.0, 0.7)
	G.chroma(2.2, 0.6)
	G.punch(0.08)
	Fx.impact(pos + Vector2(0, -8), Color(1, 0.9, 0.5), 48.0, 10)
	Fx.sparks(pos + Vector2(0, -8), Vector2.UP, Color(1, 0.9, 0.5), 40, 260.0, 360.0, 120.0)
	for i in 2:
		Fx.slash(pos + Vector2(0, -8), i * PI + 0.4, 56.0, 150.0, Color(1, 0.85, 0.45, 0.6), 12.0, 0.4, i % 2 == 0)
	Fx.ring(pos + Vector2(0, -8), 8.0, 95.0, Color(1, 0.9, 0.6), 0.5, 10.0)
	Fx.burst(pos + Vector2(0, -8), Color(1, 0.95, 0.7), 60, 220.0, 0.9, "fx_feather", 180.0, Vector2.UP, 1.4, false, Vector2(0, 30))
	Fx.light_flash(pos, Color(1, 0.9, 0.6), 1.4, 2.2, 0.6)
	var pillar := Sprite2D.new()
	pillar.texture = Fx.tex("fx_soft")
	pillar.material = Fx.add_material()
	pillar.scale = Vector2(2.0, 14.0)
	pillar.position = pos + Vector2(0, -80)
	pillar.modulate = Color(1, 0.95, 0.7, 0.55)
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
		get_tree().create_timer(1.6).timeout.connect(Prog.grant_ability.bind("lance"))
	if not Prog.spark:
		Prog.spark = true
		get_tree().create_timer(2.4).timeout.connect(_spark_joins)
	var lp := local_player()
	if lp:
		lp.refresh_stats(true)
	if multiplayer.is_server():
		Prog.save_game()

func _rest_at(id: String) -> void:
	var lp := local_player()
	Prog.last_brasa = id
	if diff().get("regrow", false) and Prog.regrow_wing_feather():
		G.toast(G.L(["La Brasa te devuelve una pluma.", "The Ember returns a feather."]), Color(1, 0.9, 0.7))
		send_look()
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
	unseal_arena()
	_trial_reset()
	_bell_seq.clear()
	for e in enemies.duplicate():
		if e.get_meta("extra", false):
			enemies.erase(e)
			e.queue_free()
			continue
		if e.type == "carcelero" and wflags.get("carcelero_dead", false):
			continue
		if e.type == "seravel" and wflags.get("seravel_dead", false):
			continue
		if e.type == "choir" and wflags.get("choir_dead", false):
			continue
		e.asc = 0
		e.reset_state()
		if e.is_boss:
			e.active = (e.type == "carcelero" and wflags.get("carcelero_intro", false)) or (e.type == "choir" and wflags.get("choir_intro", false))
	for i in enemies.size():
		enemies[i].idx = i
	if active_boss and active_boss.type == "seravel" and not wflags.get("seravel_dead", false):
		_boss_started = false
		set_gate(wflags.get("carcelero_dead", false), true)
	active_boss = null
	hud.hide_boss()
	Audio.play_music("explore")
	if not Prog.shadow.is_empty():
		get_tree().create_timer(0.3).timeout.connect(_request_shadow)

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
	if not it.data.get("local", false):
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
	if d.has("items"):
		for k in d.items:
			Prog.add_item(k, d.items[k])
	if d.has("quest"):
		if not Prog.quests.has(d.quest):
			Prog.start_quest(d.quest)
		Prog.quest_progress(d.quest)

func _talk(id: String) -> void:
	var lines := []
	match id:
		"preso":
			var lp0 := [
				["Tobías", ["¿Eres de carne? Hace tanto que solo me hablan las cadenas...", "Are you flesh? It's been so long since anything but the chains spoke to me..."]],
				["Tobías", ["No abras las celdas. Por favor. Él nos metió aquí para que estuviéramos a salvo, no para castigarnos.", "Don't open the cells. Please. He put us here to keep us safe, not to punish us."]],
				["Tobías", ["Cuando la Voz habla, los de las celdas se vuelven... huecos. Escúchame: si oyes que te llaman por tu nombre, no contestes.", "When the Voice speaks, those in the cells turn... hollow. Listen: if you hear your name being called, don't answer."]],
			]
			if Prog.flags.get("met_preso", false):
				lp0 = Lore.stage_lines("preso", wflags)
				if lp0.is_empty() and trial_done("celdas") and not Prog.flags.get("preso_after", false):
					Prog.flags["preso_after"] = true
					lp0 = [["Tobías", ["Han salido todos. Ya no queda nadie a quien proteger... salvo tú. Ten cuidado con la llave.", "They're all out now. There's no one left to protect... except you. Be careful with that key."]],
						["Tobías", ["Madre Ilse... ¿sigue viva? Dile que no se preocupe por mí. Que aquí abajo se está... tranquilo.", "Mother Ilse... is she still alive? Tell her not to worry about me. That it's... quiet down here."]]]
				if lp0.is_empty():
					lp0 = Lore.idle_line("preso")
			Prog.flags["met_preso"] = true
			dialog.play(lp0, Callable())
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
				var opts := Lore.stage_lines("brenna", wflags)
				if opts.is_empty():
					if Prog.is_desplumado():
						opts = [["Brenna", ["Por la Brasa... ¿dónde has dejado las plumas? Pareces un pollo de feria. Uno muy peligroso, eso sí.", "By the Ember... where did you leave your feathers? You look like a fairground chicken. A very dangerous one, mind."]]]
					elif Prog.deaths >= 3 and randf() < 0.4:
						opts = [["Brenna", ["%d veces has vuelto de la muerte. A este ritmo te voy a cobrar las reparaciones." % Prog.deaths, "%d times you've come back from death. At this rate I'll start charging for repairs." % Prog.deaths]]]
					else:
						opts = Lore.idle_line("brenna")
				dialog.play(opts, _open_forge)
		"ozias":
			var l1 := [["Ozias", ["Las runas no mienten. El acero sí. Déjame enseñarle a tu arma a recordar el fuego... o el frío.", "Runes do not lie. Steel does. Let me teach your weapon to remember fire... or frost."]]]
			if Prog.flags.get("met_ozias", false):
				l1 = Lore.lines_for("ozias", wflags)
			Prog.flags["met_ozias"] = true
			dialog.play(l1, _open_service.bind("ozias"))
		"ilse":
			var l2 := [["Madre Ilse", ["Siéntate, criatura. Tus Lágrimas están turbias. Puedo aclararlas... si me traes las de otros.", "Sit, child. Your Tears are cloudy. I can clear them... if you bring me the tears of others."]]]
			if Prog.flags.get("met_ilse", false):
				l2 = Lore.lines_for("ilse", wflags)
			Prog.flags["met_ilse"] = true
			dialog.play(l2, _open_service.bind("ilse"))
		"nyx":
			var l3 := Lore.stage_lines("nyx", wflags)
			if l3.is_empty():
				l3 = Lore.idle_line("nyx")
			if Prog.is_desplumado() and randf() < 0.5:
				l3 = [["Nyx", ["Vaya, vaya. Si sigues soltando plumas te compro el resto para un cojín.", "Well, well. Keep shedding feathers and I'll buy the rest for a cushion."]]]
			elif not Prog.shadow.is_empty():
				l3 = [["Nyx", ["Tu sombra anda suelta por ahí con tus Ecos. Yo de ti iría a por ella antes de que aprenda a regatear.", "Your shadow's loose out there with your Echoes. I'd fetch it before it learns to haggle."]]]
			dialog.play(l3, _open_service.bind("nyx"))
		"velaria":
			var l4 := [["Sor Velaria", ["Los Arcontes caídos dejan ecos. Puedo despertarlos, más fuertes, más crueles. Si sobrevives, el Nimbo te recompensará.", "Fallen Archons leave echoes. I can awaken them, stronger, crueler. Survive, and the Nimbus will reward you."]]]
			if Prog.flags.get("met_velaria", false):
				l4 = Lore.lines_for("velaria", wflags)
			Prog.flags["met_velaria"] = true
			if not Prog.quests.has("choir"):
				l4.append(["Sor Velaria", ["Y escucha: en la Galería Rota alguien sigue cantando. Haz que calle.", "And listen: in the Broken Gallery someone is still singing. Make it stop."]])
			var cb := func():
				if not Prog.quests.has("choir"):
					Prog.start_quest("choir")
				_open_service("velaria")
			dialog.play(l4, cb)
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
				dialog.play(Lore.lines_for("carto", wflags), Callable())

func _open_service(npc: String) -> void:
	menu.open("service", {"npc": npc})

func request_status(e: Enemy, status: String, dur: float) -> void:
	if multiplayer.is_server():
		bcast("_status", [e.idx, status, dur])
	else:
		_rpc_status.rpc_id(1, e.idx, status, dur)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_status(idx: int, status: String, dur: float) -> void:
	if multiplayer.is_server():
		bcast("_status", [idx, status, dur])

@rpc("any_peer", "call_remote", "reliable")
func _status(idx: int, status: String, dur: float) -> void:
	if idx < enemies.size() and status == "slow":
		enemies[idx].slow_t = dur
		Fx.burst(enemies[idx].global_position + Vector2(0, -10), Color(0.6, 0.9, 1.0), 8, 50.0, 0.6, "fx_px", 180.0)

# ====================================================================== Ascensión (revanchas de jefes)
func start_ascension(boss_type: String, level: int) -> void:
	if not multiplayer.is_server():
		return
	bcast("_ascension_start", [boss_type, level])

@rpc("any_peer", "call_remote", "reliable")
func _ascension_start(boss_type: String, level: int) -> void:
	var e: Enemy = null
	for en in enemies:
		if en.type == boss_type:
			e = en
	if e == null:
		return
	asc_fight = {"boss": boss_type, "lvl": level}
	var spots := {"carcelero": tile_pos(49, 43), "choir": tile_pos(82, 43), "seravel": tile_pos(49, 22)}
	var lp := local_player()
	hud.fade_to(1.0, 0.4)
	await get_tree().create_timer(0.45).timeout
	if lp:
		lp.respawn_at(spots[boss_type] + Vector2(16 * (lp.variant - 1), 0))
	e.asc = level
	e.reset_state()
	e.visible = true
	e.active = false
	if boss_type == "seravel":
		set_gate(false, true)
	if lp:
		lp.cutscene = true
	hud.fade_to(0.0, 0.4)
	hud.big_message(G.T("ascension") + " " + ["I", "II", "III"][level - 1], Color(1, 0.4, 0.5), 1.6, true)
	Audio.sfx("roar")
	await get_tree().create_timer(2.2).timeout
	if lp:
		lp.cutscene = false
	e.active = true
	e.state = "chase"
	e.cooldown = 0.8
	active_boss = e
	hud.show_boss(e)
	Audio.play_music({"carcelero": "boss_carcelero", "choir": "boss_choir", "seravel": "boss_seravel3" if level >= 2 else "boss_seravel"}[boss_type], 0.3)
	seal_for(boss_type)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_start_ascension(b: String, lvl: int) -> void:
	if multiplayer.is_server():
		start_ascension(b, lvl)

func _end_ascension(won: bool) -> void:
	unseal_arena()
	var info := asc_fight.duplicate()
	asc_fight = {}
	hud.hide_boss()
	active_boss = null
	if won:
		Prog.grant_ascension(info.boss, info.lvl)
		hud.big_message(G.T("asc_won"), Color(1, 0.85, 0.4), 3.0)
		Audio.play_music("victory", 0.2)
		G.slowmo("kill", 0.25, 0.8)
	else:
		hud.big_message(G.T("asc_failed"), Color(0.8, 0.2, 0.25), 2.5, true)
		for e in enemies:
			if e.type == info.boss and e.is_alive():
				e.die()
	await get_tree().create_timer(4.0).timeout
	if info.boss == "seravel":
		set_gate(true)
	var lp := local_player()
	if lp and lp.is_alive():
		hud.fade_to(1.0, 0.4)
		await get_tree().create_timer(0.45).timeout
		lp.respawn_at(tile_pos(66, 88))
		hud.fade_to(0.0, 0.5)
	Audio.play_music("peace", 2.0)
	if multiplayer.is_server():
		Prog.save_game()

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
		lp.cutscene = true
	await _play_cinematic("seravel")
	if lp:
		lp.cutscene = false
	boss.active = true
	boss.state = "chase"
	boss.cooldown = 0.8
	hud.show_boss(boss)
	Audio.play_music("boss_seravel", 0.3)
	seal_for("seravel")
	G.shockwave(boss.global_position + Vector2(0, -20), 1.5, 0.6)

func _play_cinematic(kind: String) -> void:
	var cine := preload("res://scripts/ui/boss_cinematic.gd").new()
	var lp := local_player()
	cine.setup(kind, lp.variant if lp else 1)
	add_child(cine)
	await cine.finished

@rpc("any_peer", "call_remote", "reliable")
func _carcelero_intro(idx: int) -> void:
	if wflags.get("carcelero_intro", false):
		return
	wflags["carcelero_intro"] = true
	var e: Enemy = enemies[idx]
	var lp := local_player()
	if lp:
		lp.cutscene = true
	await _play_cinematic("carcelero")
	if lp:
		lp.cutscene = false
	e.active = true
	e.state = "chase"
	e.cooldown = 1.0
	active_boss = e
	hud.show_boss(e)
	Audio.play_music("boss_carcelero", 0.3)
	seal_for("carcelero")

@rpc("any_peer", "call_remote", "reliable")
func _request_choir() -> void:
	if multiplayer.is_server():
		_server_start_choir()

func _server_start_choir() -> void:
	if wflags.get("choir_intro", false) or wflags.get("choir_dead", false):
		return
	for e in enemies:
		if e.type == "choir" and e.is_alive():
			bcast("_choir_intro", [e.idx])
			return

@rpc("any_peer", "call_remote", "reliable")
func _choir_intro(idx: int) -> void:
	if wflags.get("choir_intro", false):
		return
	wflags["choir_intro"] = true
	var e: Enemy = enemies[idx]
	var lp := local_player()
	if lp:
		lp.cutscene = true
	await _play_cinematic("choir")
	if lp:
		lp.cutscene = false
	e.active = true
	e.state = "chase"
	e.cooldown = 1.0
	active_boss = e
	hud.show_boss(e)
	Audio.play_music("boss_choir", 0.3)
	seal_for("choir")
	if not Prog.quests.has("choir"):
		Prog.start_quest("choir")

func _on_choir_dead(e: Enemy) -> void:
	unseal_arena()
	wflags["choir_dead"] = true
	Prog.flags["choir_dead"] = true
	Prog.quest_progress("choir")
	Prog.add_weapon("choir")
	hud.hide_boss()
	active_boss = null
	hud.big_message(G.L(["CORO SILENCIADO", "CHOIR SILENCED"]), Color(0.8, 0.6, 1.0), 3.0)
	# segundo giro: el canto mantenía dormida a la Voz
	if G.autotest == "":
		get_tree().create_timer(3.5).timeout.connect(dialog.play.bind([
			["El Coro", ["Cantábamos su nombre al revés... para que siguiera dormido.", "We sang his name backwards... to keep him asleep."]],
			["El Coro", ["Ahora que callamos, ¿no oyes cómo respira la Voz?", "Now that we are silent, can't you hear the Voice breathing?"]],
			["???", ["Un coro menos. Bien hecho.", "One choir fewer. Well done."], ["Ya casi puedo verte.", "I can almost see you now."]]], Callable(), true))
	Audio.play_music("victory", 0.2)
	G.slowmo("kill", 0.25, 0.8)
	await get_tree().create_timer(5.0).timeout
	Audio.play_music("explore", 3.0)
	if multiplayer.is_server():
		Prog.save_game()

@rpc("any_peer", "call_remote", "reliable")
func _request_carcelero() -> void:
	if multiplayer.is_server():
		_server_start_carcelero()

func _server_start_carcelero() -> void:
	if wflags.get("carcelero_intro", false) or wflags.get("carcelero_dead", false):
		return
	for e in enemies:
		if e.type == "carcelero" and e.is_alive():
			bcast("_carcelero_intro", [e.idx])
			return

func show_boss_line(line: Array) -> void:
	hud.subtitle("Seravel", G.L(line), 3.0)

func _on_carcelero_dead(e: Enemy) -> void:
	unseal_arena()
	get_tree().create_timer(3.0).timeout.connect(Prog.grant_ability.bind("wrath"))
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
	# primer giro: las celdas no eran para encerrar a nadie
	var tw1 := [["El Carcelero", ["Las celdas... nunca fueron para encerraros a vosotros.", "The cells... were never meant to keep you in."]],
		["El Carcelero", ["Eran para que ÉL no pudiera entrar. Y tú acabas de abrirle la puerta.", "They were to keep HIM out. And you've just opened the door for him."]],
		["???", ["No le escuches. Sigue bajando, Desplumado.", "Don't listen to him. Keep descending, Featherless."], ["Gracias por la llave.", "Thank you for the key."]]]
	if e.get_meta("spared", false):
		tw1[1] = ["El Carcelero", ["¿Me perdonas? Entonces escucha: la llave no abre ninguna puerta. Abre un recuerdo. El tuyo.", "You spare me? Then listen: the key opens no door. It opens a memory. Yours."]]
	if G.autotest == "":
		dialog.play(tw1, Callable(), true)
	if multiplayer.is_server():
		Prog.save_game()

func _on_seravel_dead(e: Enemy) -> void:
	unseal_arena()
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
	if e.get_meta("spared", false):
		lines = [
			["Seravel", ["¿Bajas la espada? Nadie... en mil años... me había perdonado.", "You lower your blade? No one... in a thousand years... has ever spared me."]],
			["Seravel", ["Entonces escucha: Él no es Dios. Busca a Azrahel en el fondo... y no confíes en la Voz.", "Then listen: He is not God. Find Azrahel at the bottom... and do not trust the Voice."]],
			["Seravel", ["Te esperaré en las Puertas. Esta vez... del mismo lado.", "I will wait for you at the Gates. This time... on the same side."]],
		]
	var done := func():
		# tercer giro: el recuerdo de la Primera Pluma
		Prog.unlock_memory("m3")
		await hud.memory_sequence(G.L(Prog.MEMORIES.m3.title), Prog.MEMORIES.m3.lines.map(func(l): return G.L(l)))
		hud.end_card(G.T("demo_end_title"), G.T("demo_end_body") % Prog.route_name())
		Audio.play_music("theme", 2.0)
		if multiplayer.is_server():
			Prog.save_game()
	dialog.play(lines, done, true)

# ====================================================================== muerte
func on_local_player_died(p: Player) -> void:
	if not asc_fight.is_empty():
		var any_alive := false
		for q in players.values():
			if q != p and q.is_alive():
				any_alive = true
		if not any_alive:
			_end_ascension(false)
	Audio.sfx("die")
	Audio.sfx("feather_tear", -2.0, 0.0)
	Audio.play_music("gameover", 0.4)
	hud.big_message(G.T("you_died"), Color(0.85, 0.15, 0.15), 3.0, true)
	G.slowmo("death", 0.3, 1.2)
	Prog.deaths += 1
	if active_boss and is_instance_valid(active_boss):
		Prog.boss_deaths[active_boss.type] = int(Prog.boss_deaths.get(active_boss.type, 0)) + 1
	# la muerte arranca una pluma (y se ve en tus alas)
	var wc := Look.color_of(G.look, "wing")
	Fx.burst(p.global_position + Vector2(0, -12), wc, 28, 160.0, 1.8, "fx_feather", 180.0, Vector2.UP, 1.3, false, Vector2(0, 45))
	var had := Prog.wing_feathers
	Prog.lose_wing_feather()
	if had > 0:
		get_tree().create_timer(1.5).timeout.connect(_feather_torn_msg)
	# Ecos: si ya había Ecos sin recuperar, se convierten en tu Sombra
	var shadow_new := false
	if Prog.dropped_ecos.has("amount") and int(Prog.dropped_ecos.amount) > 0:
		if Prog.shadow.is_empty():
			Prog.shadow = {"amount": int(Prog.dropped_ecos.amount), "pos": Prog.dropped_ecos.pos}
		else:
			Prog.shadow.amount = int(Prog.shadow.amount) + int(Prog.dropped_ecos.amount)
		Prog.dropped_ecos = {}
		Prog.shadow["new"] = true
		shadow_new = true
		if interactables.has("ecosdrop"):
			interactables["ecosdrop"].queue_free()
			interactables.erase("ecosdrop")
	if Prog.ecos > 0:
		var keep := int(Prog.ecos * diff().keep)
		if Prog.ecos - keep > 0:
			Prog.dropped_ecos = {"amount": Prog.ecos - keep, "pos": [p.global_position.x, p.global_position.y]}
			Prog.unrecovered += 1
		Prog.ecos = keep
	Prog.changed.emit()
	if Prog.deaths == 1 and G.autotest == "":
		get_tree().create_timer(2.6).timeout.connect(_first_death_scene)
	await get_tree().create_timer(3.2).timeout
	if not is_inside_tree():
		return
	var any_alive := false
	for q in players.values():
		if q != p and q.is_alive():
			any_alive = true
	p.respawn_at(_brasa_spawn(Prog.last_brasa))
	send_look()
	_area = ""
	Audio.play_music("peace" if AREAS.get(room_at(p.global_position), "") in PEACE_AREAS else "explore", 2.0)
	if Prog.dropped_ecos.has("amount"):
		_spawn_ecos_drop()
	if shadow_new and any_alive:
		_request_shadow(true)
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
		["???", ["...y mata al Rey del Abismo. Esa es tu penitencia. Tu única salida.", "...and slay the King of the Abyss. That is your penance. Your only way out."],
			["...y LIBÉRAME. Esa es tu condena. No hay salida.", "...and FREE ME. That is your sentence. There is no way out."]],
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
		if G.get_meta("prologue", false):
			G.set_meta("prologue", false)
			var pr := preload("res://scripts/world/prologue.gd").new()
			pr.world = self
			add_child(pr)
		else:
			get_tree().create_timer(4.5).timeout.connect(G.toast.bind(G.controls_text(), Color(0.85, 0.85, 0.9)))
	dialog.play(lines, done, true)

var _contemplating := false

func _contemplate(it: Interactable) -> void:
	if _contemplating:
		return
	var lp := local_player()
	_contemplating = true
	lp.cutscene = true
	lp.velocity = Vector2.ZERO
	lp.position = it.position + Vector2(0, 2)
	lp.facing = -1
	lp.sitting = true
	hud.letterbox(true)
	Audio.play_music("memory", 2.5)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "zoom", Vector2(0.72, 0.72), 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(canvas_mod, "color", Color(0.75, 0.75, 0.9), 4.0)
	_cam_focus = it.position + Vector2(-90, 30)
	var mem_id: String = it.data.get("memory", "m1")
	var mem: Dictionary = Prog.MEMORIES[mem_id]
	var lines: Array = []
	for l in mem.lines:
		lines.append(G.L(l))
	await hud.memory_sequence(G.L(mem.title), lines)
	var partner: Player = null
	for q in players.values():
		if q != lp and q.global_position.distance_to(lp.global_position) < 90.0:
			partner = q
	if partner:
		var me := Look.display_name(G.look)
		var other := Look.display_name(partner.look)
		var duo := [[other, ["¿Tú también lo recuerdas? El jardín...", "Do you remember it too? The garden..."]],
			[me, ["A veces creo que lo soñé. Que nunca tuvimos alas.", "Sometimes I think I dreamed it. That we never had wings."]],
			[other, ["Las tuvimos. Y si caímos juntos... subiremos juntos.", "We had them. And if we fell together... we'll rise together."]],
			[me, ["Entonces no me sueltes en el Abismo.", "Then don't let go of me in the Abyss."]]]
		var w8 := [false]
		var dd := func(): w8[0] = true
		dialog.play(duo, dd, true)
		while not w8[0] and is_inside_tree():
			await get_tree().process_frame
		Prog.flags["duo_bench"] = true
	if Prog.unlock_memory(mem_id):
		hud.big_message(G.T("memory_got"), Color(0.75, 0.9, 1.0), 2.5)
		Audio.sfx("levelup", -6.0)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(camera, "zoom", Vector2.ONE, 1.5).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(canvas_mod, "color", Color(0.62, 0.62, 0.75), 1.5)
	_cam_focus = null
	hud.letterbox(false)
	lp.sitting = false
	lp.cutscene = false
	_contemplating = false
	Audio.play_music("peace", 3.0)

class RoundTable extends Node2D:
	## Mesa redonda de piedra con velas y el emblema del Nimbo roto
	var t := 0.0
	func _ready() -> void:
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = Color(1, 0.75, 0.45)
		l.texture_scale = 2.2
		l.energy = 0.45
		l.position = Vector2(0, -6)
		add_child(l)
		var b := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 26.0
		cs.shape = sh
		b.add_child(cs)
		add_child(b)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var stone := Color(0.26, 0.23, 0.3)
		# pie de la mesa
		draw_rect(Rect2(Vector2(-30, -2), Vector2(60, 12)), Color(0.12, 0.09, 0.14))
		draw_rect(Rect2(Vector2(-28, 0), Vector2(56, 9)), stone.darkened(0.3))
		draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2(0, 14), 42.0, Color(0, 0, 0, 0.35))
		draw_circle(Vector2.ZERO, 38.0, Color(0.08, 0.05, 0.1))
		draw_circle(Vector2.ZERO, 36.0, stone)
		draw_circle(Vector2.ZERO, 31.0, stone.darkened(0.12))
		draw_arc(Vector2.ZERO, 36.0, PI, TAU, 40, stone.lightened(0.25), 2.0)
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 40, Color(0.5, 0.42, 0.3, 0.6), 1.0)
		# emblema: aureola rota
		for i in 24:
			var a := TAU * i / 24.0 + t * 0.2
			if i % 6 == 0:
				continue
			draw_rect(Rect2(Vector2(cos(a), sin(a)) * 16.0 - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.8, 0.35, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# velas sobre la mesa
		for i in 8:
			var a2 := TAU * i / 8.0
			var p := Vector2(cos(a2) * 30.0, sin(a2) * 18.0 - 4.0).round()
			draw_rect(Rect2(p - Vector2(1, 4), Vector2(2, 4)), Color(0.9, 0.86, 0.75))
			var fl := 1.0 + sin(t * 9.0 + i) * 0.5
			draw_rect(Rect2(p - Vector2(1, 6 + fl), Vector2(2, 2)), Color(1, 0.75, 0.3))

class LightShafts extends Node2D:
	## Haces de luz que caen sobre las arenas (vitrales en la nave del Coro)
	var col := Color(1, 0.85, 0.55)
	var stained := false
	var t := 0.0
	func _ready() -> void:
		material = Fx.add_material()
		z_index = 4
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		for i in 5:
			var x := -100.0 + i * 50.0 + sin(t * 0.4 + i) * 8.0
			var w := 14.0 + (i % 2) * 8.0
			var c := col
			if stained:
				c = [Color(0.8, 0.4, 1.0), Color(0.4, 0.6, 1.0), Color(1.0, 0.5, 0.7), Color(0.5, 0.9, 1.0), Color(1, 0.8, 0.4)][i]
			c.a = 0.07 + 0.03 * sin(t * 1.3 + i * 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x, -170), Vector2(x + w, -170), Vector2(x + w * 2.6 + 30, 90), Vector2(x + 30, 90)]), c)

class EdgeRim extends Node2D:
	## Bordes iluminados del suelo que da al vacío
	var world: Node
	func _draw() -> void:
		var W: int = world.MAPW
		for y in world.MAPH:
			for x in W:
				if not world._floor_at(x, y):
					continue
				var p := Vector2(x * 16, y * 16)
				var gl: int = world.grid[y * W + x - 1] if x > 0 else 0
				var gr: int = world.grid[y * W + x + 1] if x < W - 1 else 0
				var gd: int = world.grid[(y + 1) * W + x] if y < world.MAPH - 1 else 0
				if gl == 3:
					draw_rect(Rect2(p, Vector2(1, 16)), Color(0.75, 0.68, 0.85, 0.55))
					draw_rect(Rect2(p + Vector2(1, 0), Vector2(2, 16)), Color(0, 0, 0, 0.25))
				if gr == 3:
					draw_rect(Rect2(p + Vector2(15, 0), Vector2(1, 16)), Color(0.75, 0.68, 0.85, 0.55))
					draw_rect(Rect2(p + Vector2(13, 0), Vector2(2, 16)), Color(0, 0, 0, 0.25))
				if gd == 3:
					draw_rect(Rect2(p + Vector2(0, 14), Vector2(16, 2)), Color(0, 0, 0, 0.3))

class FlowerPatch extends Node2D:
	## Flores que se mecen con el viento y brillan suavemente
	var count := 10
	var petal := Color(0.85, 0.92, 1.0)
	var t := 0.0
	var _seeds := []
	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(position.x * 7 + position.y * 13)
		for i in count:
			_seeds.append([Vector2(rng.randf_range(-18, 18), rng.randf_range(-8, 8)), rng.randf_range(5, 10), rng.randf() * TAU, rng.randi() % 3])
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = petal
		l.texture_scale = 0.9
		l.energy = 0.55
		l.position = Vector2(0, -4)
		add_child(l)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		for s in _seeds:
			var base: Vector2 = s[0]
			var h: float = s[1]
			var sway := sin(t * 1.6 + s[2] + base.x * 0.1) * 1.6
			var top := (base + Vector2(sway, -h)).round()
			draw_line(base, top, Color(0.32, 0.42, 0.36), 1.0)
			draw_line(base + Vector2(0, -h * 0.4), base + Vector2(-2 + sway * 0.4, -h * 0.6), Color(0.32, 0.42, 0.36), 1.0)
			var c := petal
			match int(s[3]):
				0:
					draw_rect(Rect2(top - Vector2(1, 1), Vector2(3, 3)), c)
					draw_rect(Rect2(top, Vector2(1, 1)), Color(1, 0.9, 0.5))
				1:
					draw_rect(Rect2(top - Vector2(2, 0), Vector2(5, 1)), c)
					draw_rect(Rect2(top - Vector2(0, 2), Vector2(1, 4)), c)
				_:
					draw_rect(Rect2(top - Vector2(1, 2), Vector2(2, 3)), c.darkened(0.1))

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


# ====================================================================== v0.4: plumas, sombra, eventos, perdón, cooperativo
var event := ""
var event_t := 0.0
var _event_cd := 360.0
var _event_fx: Node2D
var _spare_target: Enemy = null
var _dashes := {}
var _cross_cd := 0
var _spark: Node2D
var _photo_lbl: Control

func event_mult() -> float:
	return 1.25 if event != "" else 1.0

func _v04_tick(delta: float, lp: Player) -> void:
	# eventos del mundo (los decide el anfitrión)
	if multiplayer.is_server() and G.autotest == "":
		if event == "":
			if active_boss == null and asc_fight.is_empty() and not (_area in PEACE_AREAS) and _area != "":
				_event_cd -= delta
				if _event_cd <= 0.0:
					_event_cd = randf_range(420.0, 600.0)
					bcast("_world_event", [["ash", "eclipse"][randi() % 2], 75.0])
		else:
			event_t -= delta
			if event_t <= 0.0:
				bcast("_world_event_end", [])
	# perdonar a un Arconte con la postura rota al borde de la muerte
	_spare_target = null
	if lp and lp.is_alive() and active_boss and is_instance_valid(active_boss) and active_boss.is_alive() and asc_fight.is_empty():
		var b := active_boss
		if b.type in ["carcelero", "choir", "seravel"] and b.is_staggered() and b.hp / b.max_hp < 0.2 and lp.global_position.distance_to(b.global_position) < 80.0:
			_spare_target = b
	# plumas de reanimación
	for q in players.values():
		if q.state == "downed" and not q.has_meta("rfeather"):
			var f := ReviveFeather.new()
			f.world = self
			f.owner_p = q
			q.set_meta("rfeather", true)
			fx_layer.add_child(f)
	# Chispa
	if Prog.spark and (_spark == null or not is_instance_valid(_spark)) and lp:
		_spark = Spark.new()
		_spark.world = self
		_spark.position = lp.global_position + Vector2(-14, -24)
		entities.add_child(_spark)

func _spark_joins() -> void:
	hud.big_message(G.L(["CHISPA SE UNE A TI", "SPARK JOINS YOU"]), Color(1, 0.75, 0.35), 2.2)
	G.toast(G.L(["Una brasa viva te seguirá: ilumina y presiente secretos.", "A living ember follows you: it lights the way and senses secrets."]), Color(1, 0.8, 0.5))

func _feather_torn_msg() -> void:
	G.toast(G.T("feather_torn") + "  %d/%d" % [Prog.wing_feathers, Prog.WING_MAX], Look.color_of(G.look, "wing"))
	if Prog.is_desplumado():
		G.toast(G.T("desplumado_mode") + ": " + G.L(["más daño y velocidad, menos vida.", "more damage and speed, less health."]), UIKit.PINK)

func _feathers_back(n: int) -> void:
	G.toast(G.L(["El Arconte te devuelve %d plumas.", "The Archon returns %d feathers."]) % n, Color(1, 0.95, 0.8))
	send_look()

func _first_death_scene() -> void:
	## La primera muerte enseña el gancho: te arrancan una pluma... y la Voz miente.
	var lines := [["???", ["Una pluma menos. Es el precio de cada caída.", "One feather less. That is the price of every fall."]],
		["???", ["Levántate. Cada pluma perdida te acerca a la redención.", "Rise. Every lost feather brings you closer to redemption."],
			["Cada pluma perdida te acerca a MÍ.", "Every lost feather brings you closer to ME."]]]
	dialog.play(lines, Callable(), true)

# ---------------------------------------------------------------------- sombra
func _request_shadow(announce := false) -> void:
	if Prog.shadow.is_empty() or not Prog.shadow.has("pos"):
		return
	var sp: Array = Prog.shadow.pos
	var args := [Net.my_id(), Vector2(sp[0], sp[1]), int(Prog.shadow.amount), G.look, Prog.wing_feathers, announce or bool(Prog.shadow.get("new", false))]
	Prog.shadow.erase("new")
	if multiplayer.is_server():
		bcast("_spawn_shadow", args)
	else:
		_rpc_shadow.rpc_id(1, args)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_shadow(args: Array) -> void:
	if multiplayer.is_server():
		bcast("_spawn_shadow", args)

@rpc("any_peer", "call_remote", "reliable")
func _spawn_shadow(owner: int, pos: Vector2, amount: int, l: Dictionary, feathers: int, announce: bool) -> void:
	for e0 in enemies:
		if e0.type == "sombra" and e0.is_alive() and int(e0.get_meta("owner", -1)) == owner:
			e0.set_meta("amount", amount)
			return
	var e := _add_enemy("sombra", pos, true)
	e.set_meta("owner", owner)
	e.set_meta("amount", amount)
	e.apply_shadow_look(l, feathers)
	e.state = "idle"
	Fx.burst(pos + Vector2(0, -10), Color(0.5, 0.25, 0.8), 30, 90.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.6)
	if owner == Net.my_id() and announce:
		hud.big_message(G.T("shadow_rises"), Color(0.7, 0.45, 1.0), 2.5, true)
		Audio.sfx("shadow_rise", 0.0, 0.0)
		Audio.play_music("shadow", 1.0)

# ---------------------------------------------------------------------- eventos del mundo
@rpc("any_peer", "call_remote", "reliable")
func _world_event(kind: String, dur: float) -> void:
	event = kind
	event_t = dur
	Prog.event_ecos = 1.5 if kind == "ash" else 2.0
	var col := Color(1, 0.55, 0.3) if kind == "ash" else Color(0.7, 0.45, 1.0)
	hud.big_message(G.T("ev_" + kind), col, 3.0, true)
	G.toast(G.T("ev_" + kind + "_d"), col)
	Audio.sfx("event", 0.0, 0.0)
	G.chroma(1.0, 0.6)
	if _event_fx:
		_event_fx.queue_free()
	_event_fx = EventFx.new()
	_event_fx.kind = kind
	camera.add_child(_event_fx)
	create_tween().tween_property(canvas_mod, "color", Color(0.62, 0.42, 0.38) if kind == "ash" else Color(0.32, 0.26, 0.48), 2.0)

@rpc("any_peer", "call_remote", "reliable")
func _world_event_end() -> void:
	if event == "":
		return
	event = ""
	Prog.event_ecos = 1.0
	G.toast(G.T("ev_end"), Color(0.8, 0.85, 0.95))
	if _event_fx:
		_event_fx.fade()
		_event_fx = null
	_area = ""

# ---------------------------------------------------------------------- perdón
@rpc("any_peer", "call_remote", "reliable")
func _spare_boss(idx: int) -> void:
	if idx >= enemies.size() or not enemies[idx].is_alive():
		return
	var e: Enemy = enemies[idx]
	e.set_meta("spared", true)
	Prog.spared[e.type] = true
	Prog.skill_points += 1
	G.flash(Color(1, 0.95, 0.75, 0.7), 0.6)
	G.slowmo("spare", 0.3, 1.0)
	Fx.ring(e.global_position + Vector2(0, -16), 8.0, 160.0, Color(1, 0.9, 0.6), 1.0, 6.0)
	Fx.burst(e.global_position + Vector2(0, -16), Color(1, 0.95, 0.8), 50, 140.0, 1.6, "fx_feather", 180.0, Vector2.UP, 1.2, false, Vector2(0, -20))
	hud.big_message(G.T("spared"), Color(1, 0.95, 0.75), 3.0, true)
	G.toast(G.L(["+1 Punto de Habilidad. El Arconte recordará tu piedad.", "+1 Skill Point. The Archon will remember your mercy."]), UIKit.GOLD)
	_enemy_die(idx)

# ---------------------------------------------------------------------- Alas Cruzadas
func note_dash(peer: int, pos: Vector2, dir: Vector2) -> void:
	var now := Time.get_ticks_msec()
	_dashes[peer] = [now, pos, dir]
	if not Net.is_online() or peer != Net.my_id() or now < _cross_cd:
		return
	for pid in _dashes:
		if pid == peer:
			continue
		var d: Array = _dashes[pid]
		var dp: Vector2 = d[1]
		var dd: Vector2 = d[2]
		if now - int(d[0]) < 420 and dp.distance_to(pos) < 72.0 and absf(dd.normalized().dot(dir.normalized())) < 0.75:
			_cross_cd = now + 1500
			bcast("_cross_slash", [(pos + dp) / 2.0, Net.my_id()])
			return

@rpc("any_peer", "call_remote", "reliable")
func _cross_slash(mid: Vector2, by: int) -> void:
	_cross_cd = Time.get_ticks_msec() + 1500
	var c := mid + Vector2(0, -8)
	Fx.slash(c, PI * 0.25, 46.0, 70.0, Color(1, 0.9, 0.55, 0.95), 18.0, 0.35, true)
	Fx.slash(c, -PI * 0.25, 46.0, 70.0, Color(0.6, 0.9, 1, 0.95), 18.0, 0.35, false)
	Fx.slash(c, PI * 1.25, 46.0, 70.0, Color(1, 0.9, 0.55, 0.95), 18.0, 0.35, true)
	Fx.slash(c, PI * 0.75, 46.0, 70.0, Color(0.6, 0.9, 1, 0.95), 18.0, 0.35, false)
	Fx.ring(c, 8.0, 90.0, Color(1, 1, 1), 0.5, 6.0)
	Fx.impact(c, Color(1, 0.95, 0.8), 40.0, 10)
	Fx.text(c + Vector2(0, -18), G.T("cross_wings"), Color(1, 0.9, 0.6), 12)
	G.shockwave(c, 1.6, 0.5)
	G.chroma(1.4, 0.4)
	G.shake(5.0, 0.25)
	G.flash(Color(1, 1, 1, 0.3), 0.12)
	Audio.sfx("hit_heavy")
	Audio.sfx("parry", -4.0)
	if by == Net.my_id():
		for e in enemies_alive():
			if e.global_position.distance_to(mid) < 86.0 + e.body_radius:
				request_damage_enemy(e, Prog.weapon_damage() * 3.2, (e.global_position - mid).normalized(), 60.0, true)

# ---------------------------------------------------------------------- modo foto
func _toggle_photo() -> void:
	G.photo_mode = not G.photo_mode
	hud.visible = not G.photo_mode
	if G.photo_mode:
		if not Net.is_online():
			Engine.time_scale = 0.0
		_photo_lbl = UIKit.label(G.T("photo") + "   [WASD] " + G.L(["mover", "move"]) + "   [Q/E] zoom   [F12] " + G.L(["captura", "capture"]) + "   [P/Esc] " + G.L(["salir", "exit"]), 8, UIKit.WHITE, "head", 3)
		_photo_lbl.position = Vector2(10, 346)
		var cl := CanvasLayer.new()
		cl.layer = 30
		cl.add_child(_photo_lbl)
		add_child(cl)
		_photo_lbl.set_meta("layer", cl)
	else:
		Engine.time_scale = 1.0
		if _photo_lbl:
			_photo_lbl.get_meta("layer").queue_free()
			_photo_lbl = null
		camera.zoom = Vector2.ONE

var _photo_last := 0

func _photo_tick() -> void:
	var now := Time.get_ticks_usec()
	var dt := clampf((now - _photo_last) / 1000000.0, 0.0, 0.05) if _photo_last > 0 else 0.016
	_photo_last = now
	var mv := Input.get_vector("left", "right", "up", "down")
	camera.position += mv * 220.0 * dt / camera.zoom.x
	if Input.is_action_pressed("spell1"):
		camera.zoom = (camera.zoom * (1.0 - dt)).clamp(Vector2(0.5, 0.5), Vector2(3, 3))
	if Input.is_action_pressed("spell2"):
		camera.zoom = (camera.zoom * (1.0 + dt)).clamp(Vector2(0.5, 0.5), Vector2(3, 3))

func _screenshot() -> void:
	DirAccess.make_dir_recursive_absolute("user://capturas")
	var img := get_viewport().get_texture().get_image()
	var path := "user://capturas/seraphall_%d.png" % Time.get_unix_time_from_system()
	img.save_png(path)
	if _photo_lbl:
		_photo_lbl.text = G.L(["Captura guardada: ", "Screenshot saved: "]) + ProjectSettings.globalize_path(path)

# ---------------------------------------------------------------------- piezas
class ReviveFeather extends Node2D:
	## Al caer en cooperativo, sale volando una pluma: tu compañero debe atraparla antes de que se apague.
	var world: Node
	var owner_p: Player
	var t := 0.0
	var life := 12.0
	var origin := Vector2.ZERO
	func _ready() -> void:
		origin = owner_p.global_position + Vector2(0, -14)
		material = Fx.add_material()
		z_index = 30
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = Look.color_of(owner_p.look, "wing")
		l.texture_scale = 0.8
		l.energy = 1.0
		add_child(l)
	func _process(delta: float) -> void:
		t += delta
		if not is_instance_valid(owner_p) or owner_p.state != "downed":
			if is_instance_valid(owner_p):
				owner_p.remove_meta("rfeather")
			queue_free()
			return
		var k := minf(t / 1.2, 1.0)
		var path := Vector2(sin(t * 1.3) * 54.0, sin(t * 2.1) * 26.0 - 10.0)
		position = origin + path * k
		if t > life:
			# se apaga y renace al poco: siempre queda una oportunidad
			t = 0.0
			Fx.burst(position, Color(0.6, 0.6, 0.7), 8, 30.0, 0.5, "fx_px", 180.0)
		var lp: Player = world.local_player()
		if lp and lp != owner_p and lp.is_alive() and lp.global_position.distance_to(position + Vector2(0, 12)) < 18.0:
			Fx.burst(position, Color(1, 0.95, 0.8), 24, 100.0, 0.8, "fx_feather", 180.0, Vector2.UP, 1.0)
			Fx.text(position + Vector2(0, -10), G.L(["¡ATRAPADA!", "CAUGHT!"]), Color(1, 0.95, 0.7), 10)
			Audio.sfx("levelup", -4.0)
			owner_p._net_revive.rpc_id(owner_p.peer_id)
			owner_p.remove_meta("rfeather")
			queue_free()
			return
		modulate.a = 1.0 if t < life - 3.0 else (0.4 + 0.6 * absf(sin(t * 10.0)))
		queue_redraw()
	func _draw() -> void:
		var c := Look.color_of(owner_p.look, "wing")
		var a := sin(t * 3.0) * 0.5
		draw_set_transform(Vector2.ZERO, a, Vector2.ONE)
		draw_line(Vector2(0, 6), Vector2(0, -6), UIKit.INK, 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(3, -2), Vector2(2, 5), Vector2(0, 6), Vector2(-2, 5), Vector2(-3, -2)]), c)
		draw_line(Vector2(0, 7), Vector2(0, -5), Color(1, 1, 1, 0.8), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var lp: Player = world.local_player()
		if lp and lp != owner_p:
			var f := UIKit.font("title")
			f.draw_string_outline(get_canvas_item(), Vector2(-30, -12), G.T("catch_feather"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, UIKit.INK)
			f.draw_string(get_canvas_item(), Vector2(-30, -12), G.T("catch_feather"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.WHITE)

class Spark extends Node2D:
	## Chispa: una brasa viva que te sigue, ilumina y presiente cofres, Ecos perdidos y sombras.
	var world: Node
	var t := 0.0
	var light: PointLight2D
	var target := Vector2.ZERO
	var _chime := 0.0
	var _sense := 0.0
	func _ready() -> void:
		z_index = 20
		light = PointLight2D.new()
		light.texture = Fx.tex("light")
		light.color = Color(1, 0.7, 0.35)
		light.texture_scale = 1.3
		light.energy = 0.9
		add_child(light)
		material = Fx.add_material()
	func _process(delta: float) -> void:
		t += delta
		var lp: Player = world.local_player()
		if lp == null:
			return
		var home := lp.global_position + Vector2(-14 * lp.facing, -24 + sin(t * 2.5) * 3.0)
		var secret := Vector2.INF
		var best := 150.0
		for it in world.interactables.values():
			if is_instance_valid(it) and not it.used and it.kind in ["chest", "ecos"]:
				var d: float = it.global_position.distance_to(lp.global_position)
				if d < best:
					best = d
					secret = it.global_position
		for e in world.enemies:
			if e.type == "sombra" and e.is_alive() and e.global_position.distance_to(lp.global_position) < 220.0:
				secret = e.global_position
		if secret != Vector2.INF:
			_sense = move_toward(_sense, 1.0, delta * 2.0)
			home = home.lerp(secret + Vector2(0, -16), 0.45)
			_chime -= delta
			if _chime <= 0.0:
				_chime = 2.6
				Audio.sfx("ui_move", -14.0, 0.0)
				Fx.burst(global_position, Color(1, 0.85, 0.5), 6, 40.0, 0.5, "fx_px", 180.0)
		else:
			_sense = move_toward(_sense, 0.0, delta * 2.0)
		position = position.lerp(home, clampf(delta * 4.0, 0.0, 1.0))
		var dark: bool = world.current_area() in ["area_gallery", "area_choir"]
		light.texture_scale = (1.8 if dark else 1.2) + _sense * 0.6 + sin(t * 9.0) * 0.08
		light.energy = 0.85 + _sense * 0.4
		if randf() < 0.25:
			Fx.burst(global_position + Vector2(randf_range(-2, 2), 0), Color(1, 0.6, 0.25), 1, 12.0, 0.5, "fx_px", 40.0, Vector2.UP, 0.25, false, Vector2(0, -20))
		queue_redraw()
	func _draw() -> void:
		var p := 1.0 + _sense * 0.5 * absf(sin(t * 6.0))
		draw_circle(Vector2.ZERO, 5.0 * p, Color(1, 0.45, 0.15, 0.35))
		draw_circle(Vector2.ZERO, 3.0 * p, Color(1, 0.7, 0.3, 0.9))
		draw_rect(Rect2(Vector2(-1, -1 - roundf(sin(t * 12.0))), Vector2(2, 2)), Color(1, 1, 0.85))
		# ojitos
		draw_rect(Rect2(Vector2(-2, 0), Vector2(1, 1)), UIKit.INK)
		draw_rect(Rect2(Vector2(1, 0), Vector2(1, 1)), UIKit.INK)

class EventFx extends Node2D:
	## Partículas que cubren la pantalla durante un evento del mundo
	var kind := "ash"
	var parts: CPUParticles2D
	func _ready() -> void:
		z_index = 60
		parts = CPUParticles2D.new()
		parts.position = Vector2(0, -200)
		parts.amount = 90
		parts.lifetime = 4.0
		parts.preprocess = 4.0
		parts.texture = Fx.tex("fx_px")
		parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		parts.emission_rect_extents = Vector2(360, 10)
		parts.direction = Vector2(0.3, 1)
		parts.spread = 15.0
		parts.gravity = Vector2(10, 30)
		parts.initial_velocity_min = 30.0
		parts.initial_velocity_max = 70.0
		parts.scale_amount_min = 1.0
		parts.scale_amount_max = 2.0
		if kind == "ash":
			parts.color = Color(0.85, 0.6, 0.45, 0.8)
		else:
			parts.position = Vector2(0, 200)
			parts.direction = Vector2(0, -1)
			parts.gravity = Vector2(0, -20)
			parts.color = Color(0.6, 0.4, 1.0, 0.7)
		add_child(parts)
	func fade() -> void:
		parts.emitting = false
		var tw := create_tween()
		tw.tween_interval(4.0)
		tw.tween_callback(queue_free)


# ====================================================================== salas de jefe selladas
const ARENAS := {"carcelero": ["yard", "celda"], "choir": ["choir", "coro"], "seravel": ["circle", "luz"]}
var _seals: Array[Node2D] = []

func seal_for(boss_type: String) -> void:
	if ARENAS.has(boss_type):
		seal_arena(ARENAS[boss_type][0], ARENAS[boss_type][1])

func seal_arena(room_id: String, style: String) -> void:
	## Al empezar el combate, las entradas de la sala se cierran (celdas, tubos de órgano o un muro de luz)
	unseal_arena()
	var ri := -1
	for i in ROOMS.size():
		if ROOMS[i].id == room_id:
			ri = i
	if ri < 0:
		return
	var rect := _rect_of(ROOMS[ri]).grow(2)
	var inner := Vector2.ZERO
	for y in range(max(0, rect.position.y), min(MAPH, rect.end.y)):
		for x in range(max(0, rect.position.x), min(MAPW, rect.end.x)):
			var i := y * MAPW + x
			if grid[i] != 1 or room_of[i] == ri:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= MAPW or ny >= MAPH:
					continue
				var ni := ny * MAPW + nx
				if grid[ni] == 1 and room_of[ni] == ri:
					var sl := ArenaSeal.new()
					sl.style = style
					sl.position = tile_pos(x, y)
					entities.add_child(sl)
					_seals.append(sl)
					inner = tile_pos(nx, ny)
					break
	if _seals.is_empty():
		return
	Audio.sfx("gate", 0.0, 0.0)
	Audio.sfx("slam", -4.0, 0.0)
	G.shake(4.0, 0.3)
	# quien se haya quedado fuera entra en la sala (cooperativo)
	var lp := local_player()
	if lp and lp.is_alive() and room_at(lp.global_position) != room_id and inner != Vector2.ZERO:
		lp.respawn_at(inner)

func unseal_arena() -> void:
	for sl in _seals:
		if is_instance_valid(sl):
			sl.open_and_free()
	_seals.clear()

class ArenaSeal extends Node2D:
	## Barrera de la entrada: "celda" (barrotes que caen), "coro" (tubos de órgano) o "luz" (plumas doradas)
	var style := "celda"
	var t := 0.0
	var k := 0.0
	var body: StaticBody2D
	var _closing := true
	var instant := false
	func _ready() -> void:
		z_index = 2
		if instant:
			k = 1.0
		body = StaticBody2D.new()
		body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(16, 16)
		cs.shape = sh
		body.add_child(cs)
		add_child(body)
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = {"celda": Color(1, 0.5, 0.25), "coro": Color(0.7, 0.45, 1.0), "luz": Color(1, 0.85, 0.5)}[style]
		l.texture_scale = 0.6
		l.energy = 0.7
		add_child(l)
		if not instant:
			Fx.burst(global_position + Vector2(0, 4), Color(0.6, 0.55, 0.6), 8, 50.0, 0.6, "fx_soft", 180.0, Vector2.UP, 0.4)
	func open_and_free() -> void:
		_closing = false
		if body:
			body.queue_free()
			body = null
	func _process(delta: float) -> void:
		t += delta
		k = move_toward(k, 1.0 if _closing else 0.0, delta * (6.0 if _closing else 2.5))
		if not _closing and k <= 0.0:
			queue_free()
			return
		queue_redraw()
	func _draw() -> void:
		var h := 26.0
		match style:
			"celda":
				var drop := (1.0 - k) * -30.0
				draw_rect(Rect2(Vector2(-9, -h + drop), Vector2(18, 3)), Color(0.25, 0.22, 0.26))
				for i in 5:
					var x := -8.0 + i * 4.0
					draw_rect(Rect2(Vector2(x - 1, -h + drop), Vector2(3, h + 6)), Color(0.07, 0.05, 0.08))
					draw_rect(Rect2(Vector2(x, -h + drop), Vector2(1, h + 5)), Color(0.55, 0.5, 0.55))
					draw_rect(Rect2(Vector2(x, 4 + drop), Vector2(1, 3)), Color(0.75, 0.7, 0.72))
				draw_rect(Rect2(Vector2(-9, -8 + drop), Vector2(18, 2)), Color(0.35, 0.3, 0.35))
				draw_rect(Rect2(Vector2(-6, -8 + drop), Vector2(1, 1)), Color(1, 0.55, 0.25))
			"coro":
				for i in 4:
					var x2 := -7.0 + i * 4.5
					var ph := (h - 4 + (i % 2) * 6) * k
					draw_rect(Rect2(Vector2(x2 - 1, 8 - ph), Vector2(4, ph)), Color(0.12, 0.06, 0.18))
					draw_rect(Rect2(Vector2(x2, 8 - ph), Vector2(2, ph)), Color(0.55, 0.38, 0.8))
					draw_rect(Rect2(Vector2(x2, 8 - ph), Vector2(1, ph)), Color(0.85, 0.7, 1.0, 0.8))
				if int(t * 3.0) % 2 == 0:
					draw_rect(Rect2(Vector2(sin(t * 2.0) * 6.0, -h + 4), Vector2(2, 2)), Color(0.9, 0.75, 1.0))
			"luz":
				var a := 0.35 + 0.15 * sin(t * 5.0)
				draw_rect(Rect2(Vector2(-8, -h * k + 8), Vector2(16, h * k)), Color(1, 0.85, 0.5, a * k))
				for i in 3:
					var fy := 8.0 - fmod(t * 14.0 + i * 9.0, h)
					var fx := -5.0 + i * 5.0
					draw_colored_polygon(PackedVector2Array([Vector2(fx, fy - 4), Vector2(fx + 2, fy), Vector2(fx, fy + 3), Vector2(fx - 2, fy)]), Color(1, 0.95, 0.8, k))


class DepthPit extends Control:
	## Pozo en el suelo con falsa perspectiva (como en Bloody Hell): las paredes interiores y el fondo
	## se proyectan hacia el centro de la cámara, así que al moverte el agujero "gira" y parece hondo.
	var style := "ember"
	var t := 0.0
	var motes := []
	const DEPTH := 0.78
	func _ready() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = {"ember": Color(1, 0.5, 0.2), "chains": Color(1, 0.4, 0.15), "light": Color(1, 0.85, 0.5)}.get(style, Color(0.6, 0.35, 1.0))
		l.texture_scale = 1.6
		l.energy = 0.9
		l.position = size / 2.0
		get_parent().add_child.call_deferred(l)
		l.set_deferred("global_position", global_position + size / 2.0)
		for i in 26:
			motes.append([randf(), randf(), randf_range(0.0, 1.0), randf_range(0.3, 1.0)])
	func _process(delta: float) -> void:
		t += delta
		for m in motes:
			m[2] += delta * 0.18 * m[3]
			if m[2] > 1.0:
				m[2] = 0.0; m[0] = randf(); m[1] = randf()
		queue_redraw()
	func _proj(p: Vector2, cam: Vector2, k: float) -> Vector2:
		return cam + (p - cam) * k
	func _draw() -> void:
		var vp := get_viewport()
		var cam: Vector2 = (vp.get_camera_2d().get_screen_center_position() - global_position) if vp.get_camera_2d() else size / 2.0
		var warm := style == "ember" or style == "chains"
		var hot := Color(1, 0.55, 0.15) if warm else Color(0.65, 0.35, 1.0)
		var deep := Color(0.05, 0.015, 0.02) if warm else Color(0.03, 0.01, 0.07)
		var wall := Color(0.2, 0.09, 0.08) if warm else Color(0.12, 0.08, 0.2)
		if style == "light":
			hot = Color(1, 0.88, 0.55)
			deep = Color(0.16, 0.11, 0.05)
			wall = Color(0.42, 0.34, 0.24)
		draw_rect(Rect2(Vector2.ZERO, size), deep)
		var tl := Vector2.ZERO
		var tr := Vector2(size.x, 0)
		var br := size
		var bl := Vector2(0, size.y)
		# fondo: núcleo que brilla, con rayos que giran, a la profundidad máxima
		var bc := _proj(size / 2.0, cam, DEPTH)
		for k in 10:
			var a := TAU * k / 10.0 + t * 0.4
			var r1 := 10.0 + 4.0 * sin(t * 3.0 + k)
			Depth3D.poly(self, PackedVector2Array([bc + Vector2.from_angle(a - 0.12) * 4.0, bc + Vector2.from_angle(a) * (r1 + 26.0), bc + Vector2.from_angle(a + 0.12) * 4.0]), Color(hot, 0.22))
		for k2 in 4:
			draw_circle(bc, 16.0 - k2 * 3.5 + sin(t * 4.0) * 1.0, Color(hot.lerp(Color(1, 1, 0.8), k2 * 0.25), 0.25 + k2 * 0.18))
		# chispas que suben desde el fondo hacia la boca (cada una a su profundidad)
		for m in motes:
			var depth := lerpf(DEPTH, 1.0, m[2])
			var p := _proj(Vector2(m[0] * size.x, m[1] * size.y), cam, depth)
			draw_rect(Rect2(p.round(), Vector2(1, 1) * (1 + int(m[2] * 2.0))), Color(hot.lerp(Color(1, 0.95, 0.7), m[3]), 1.0 - m[2] * 0.7))
		# paredes interiores (cuatro trapecios hacia el fondo) con estratos de profundidad
		var walls := [[tl, tr, 1.0], [tr, br, 0.7], [br, bl, 0.45], [bl, tl, 0.8]]
		for w in walls:
			var a2: Vector2 = w[0]
			var b2: Vector2 = w[1]
			var shade: float = w[2]
			var q := PackedVector2Array([a2, b2, _proj(b2, cam, DEPTH), _proj(a2, cam, DEPTH)])
			Depth3D.poly(self, q, wall.lerp(Color.BLACK, 1.0 - shade))
			for s in 4:
				var kk := 1.0 - (1.0 - DEPTH) * (s + 1) / 5.0
				draw_line(_proj(a2, cam, kk), _proj(b2, cam, kk), Color(hot, 0.08 + 0.05 * (3 - s)), 1.0)
			draw_line(_proj(a2, cam, DEPTH), _proj(b2, cam, DEPTH), Color(hot, 0.35), 1.0)
		# cadenas que bajan desde el borde hasta el fondo (cada eslabón a su profundidad)
		if style == "chains":
			for ci in 3:
				var top := Vector2(size.x * (0.25 + ci * 0.25), 0.0)
				var sway := sin(t * 1.3 + ci) * 3.0
				for li in 9:
					var kk2 := 1.0 - (1.0 - DEPTH) * li / 8.0
					var lp2 := _proj(top + Vector2(sway * li / 8.0, size.y * 0.45 * li / 8.0), cam, kk2)
					var lc := Color(0.55, 0.5, 0.55).lerp(Color(0.2, 0.1, 0.08), li / 9.0)
					draw_rect(Rect2(lp2 - Vector2(1, 1), Vector2(2 + (li % 2), 3)), lc)
		# haces de luz que suben desde el fondo
		if style == "light":
			for ri in 4:
				var rx := size.x * (0.2 + ri * 0.2)
				var a3 := 0.12 + 0.08 * sin(t * 2.0 + ri)
				Depth3D.poly(self, PackedVector2Array([_proj(Vector2(rx - 2, size.y * 0.5), cam, DEPTH), _proj(Vector2(rx + 2, size.y * 0.5), cam, DEPTH), Vector2(rx + 4, 0), Vector2(rx - 4, 0)]), Color(hot, a3))
		# niebla del fondo y borde de la boca con "dientes" de roca que cuelgan
		draw_rect(Rect2(Vector2.ZERO, size), Color(deep, 0.25))
		var rimc := Color(0.32, 0.27, 0.36)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), rimc.lightened(0.25))
		draw_rect(Rect2(Vector2(0, size.y - 2), Vector2(size.x, 2)), rimc.darkened(0.3))
		draw_rect(Rect2(Vector2.ZERO, Vector2(2, size.y)), rimc)
		draw_rect(Rect2(Vector2(size.x - 2, 0), Vector2(2, size.y)), rimc.darkened(0.15))
		var x := 3.0
		var i := 0
		while x < size.x - 3:
			var h := 3.0 + float((i * 7) % 5)
			Depth3D.poly(self, PackedVector2Array([Vector2(x - 2, 2), Vector2(x + 2, 2), Vector2(x, 2 + h)]), rimc.darkened(0.2))
			x += 5.0
			i += 1


class FloorDecals extends Node2D:
	## Manchas de ceniza, brasas apagadas, icor seco, plumas sueltas y runas gastadas sobre el suelo
	var world: Node
	var decals := []
	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 777
		for k in 420:
			var x := rng.randi_range(0, world.MAPW - 1)
			var y := rng.randi_range(0, world.MAPH - 1)
			if not world._floor_at(x, y):
				continue
			var rid: String = world.ROOMS[world.room_of[y * world.MAPW + x]].id if world.room_of[y * world.MAPW + x] >= 0 else ""
			if rid in ["nimbo", "mirador"] and rng.randf() < 0.8:
				continue
			decals.append([Vector2(x * 16 + rng.randf_range(0, 16), y * 16 + rng.randf_range(0, 16)), rng.randi_range(0, 4), rng.randf_range(0.6, 1.4), rng.randi()])
		queue_redraw()
	func _draw() -> void:
		for d in decals:
			var p: Vector2 = d[0]
			var s: float = d[2]
			var r := RandomNumberGenerator.new()
			r.seed = d[3]
			match d[1]:
				0:  # ceniza
					for i in 6:
						draw_circle(p + Vector2(r.randf_range(-6, 6), r.randf_range(-3, 3)) * s, r.randf_range(1.5, 3.5) * s, Color(0.55, 0.5, 0.52, 0.18))
				1:  # icor seco
					draw_circle(p, 4.0 * s, Color(0.32, 0.04, 0.08, 0.35))
					for i in 5:
						var a := r.randf() * TAU
						draw_circle(p + Vector2.from_angle(a) * r.randf_range(4, 9) * s, r.randf_range(0.8, 2.0) * s, Color(0.35, 0.05, 0.1, 0.4))
				2:  # brasa apagada
					draw_circle(p, 3.0 * s, Color(0.1, 0.06, 0.06, 0.4))
					draw_rect(Rect2(p.round(), Vector2(1, 1)), Color(1, 0.45, 0.15, 0.8))
				3:  # pluma suelta
					var a2 := r.randf() * TAU
					var dir := Vector2.from_angle(a2)
					draw_line(p - dir * 3.0, p + dir * 3.0, Color(0.9, 0.88, 0.95, 0.75), 2.0)
					draw_line(p - dir * 3.0, p + dir * 3.0, Color(0.6, 0.55, 0.7, 0.75), 1.0)
				4:  # runa gastada
					draw_arc(p, 5.0 * s, 0, TAU, 12, Color(0.85, 0.7, 0.35, 0.12), 1.0)
					draw_line(p + Vector2(0, -3), p + Vector2(0, 3), Color(0.85, 0.7, 0.35, 0.12), 1.0)


# ====================================================================== v0.7: antesalas de los jefes
## Antes de cada jefe hay una sala con su propia prueba: oleadas que salen de las celdas, un puzle de
## campanas que hay que tañer como lo cantaba el Coro (al revés) y el Custodio del Umbral.
const TRIALS := {
	"celdas": {"room": "celdas", "seal": "celda", "title": "trial_celdas",
		"waves": [[["hueco", 18.5, 47.3], ["hueco", 22.5, 47.3], ["hueco", 26.5, 47.3]],
			[["hueco", 18.5, 47.3], ["acolito", 31, 51], ["hueco", 30.5, 47.3], ["hueco", 22.5, 47.3]],
			[["bestia", 22.5, 47.3], ["hueco", 18.5, 47.3], ["acolito", 33, 50], ["hueco", 26.5, 47.3]]],
		"reward": {"feathers": 1, "ecos": 300, "items": {"tear": 1}}, "chest": Vector2(19.5, 51.3)},
	"umbral": {"room": "antesala", "seal": "luz", "title": "trial_umbral",
		"waves": [[["acolito", 67, 9], ["acolito", 71, 9], ["hueco", 69, 13]],
			[["custodio", 69, 10]]],
		"reward": {"feathers": 2, "ecos": 600, "items": {"iron": 1}}, "chest": Vector2(69, 7.4)},
}
## Cierres que siguen puestos hasta superar la prueba: [prueba, casillas, estilo]
const LOCKS := [["celdas", Rect2i(47, 46, 4, 1), "celda"], ["atrio", Rect2i(81, 47, 3, 1), "coro"], ["umbral", Rect2i(64, 12, 1, 3), "luz"]]
const BELL_ORDER := [0, 1, 2]       # orden correcto (aguda, media, grave): el himno escrito era grave-media-aguda
const CELL_DOORS := [18.5, 22.5, 26.5, 30.5]
var _trial := ""
var _trial_wave := -1
var _trial_wait := 0.0
var _locks := {}
var _bell_seq: Array = []
var _cell_doors: Array = []

func trial_done(id: String) -> bool:
	return wflags.get("trial_" + id, false)

func _refresh_locks(instant: bool) -> void:
	for L in LOCKS:
		var id: String = L[0]
		if trial_done(id):
			if _locks.has(id):
				for sl in _locks[id]:
					if is_instance_valid(sl):
						sl.open_and_free()
				_locks.erase(id)
		elif not _locks.has(id):
			var arr := []
			var r: Rect2i = L[1]
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var sl := ArenaSeal.new()
					sl.style = L[2]
					sl.instant = instant
					sl.position = tile_pos(x, y)
					entities.add_child(sl)
					arr.append(sl)
			_locks[id] = arr
	for id2 in TRIALS:
		if trial_done(id2):
			_ensure_trial_chest(id2, false)

func _ensure_trial_chest(id: String, fx: bool) -> void:
	var cid := "chest_trial_" + id
	if interactables.has(cid):
		return
	var it := _add_inter("chest", cid, tile_pos(TRIALS[id].chest.x, TRIALS[id].chest.y), TRIALS[id].reward)
	if wflags.get("used_" + cid, false):
		it.set_opened()
	elif fx:
		Fx.burst(it.global_position + Vector2(0, -6), Color(1, 0.85, 0.4), 30, 90.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.4)
		Fx.ring(it.global_position, 4.0, 40.0, Color(1, 0.85, 0.4), 0.6, 3.0)

func _build_antechambers() -> void:
	# --- Las Celdas de Espera: puertas de celda en el muro norte, cadenas, el preso Tobías y el pozo de castigo
	for x in CELL_DOORS:
		var dsp := Sprite2D.new()
		dsp.texture = Fx.tex("celldoor")
		dsp.region_enabled = true
		dsp.region_rect = Rect2(0, 0, 24, 30)
		dsp.position = Vector2(x * TS, 46 * TS - 13)
		dsp.z_index = -8
		add_child(dsp)
		_cell_doors.append(dsp)
		var dl := PointLight2D.new()
		dl.texture = Fx.tex("light")
		dl.color = Color(1, 0.4, 0.2)
		dl.energy = 0.0
		dl.texture_scale = 0.8
		dl.position = Vector2(0, 6)
		dsp.add_child(dl)
	for x in [20, 28, 34]:
		var c := Sprite2D.new()
		c.texture = Fx.tex("chains")
		c.position = tile_pos(x, 45) + Vector2(0, 6)
		c.z_index = -8
		add_child(c)
	for p in [Vector2(17, 47), Vector2(35, 47), Vector2(17, 52), Vector2(29, 52)]:
		_prop("candle", tile_pos(p.x, p.y), 4, int(p.x) % 4, 0.0, Color(1, 0.55, 0.25), 1.0)
	for k in 5:
		_prop("bones", tile_pos(19 + k * 3.4, 49 + (k % 2) * 2.5), 3, k % 3)
	for c2 in [Vector2(21, 46.8), Vector2(32, 46.6)]:
		var cg := _prop("cage", tile_pos(c2.x, c2.y), 2, k_frame(c2))
		cg.set_meta("sway", c2.x)
	_add_inter("npc", "preso", tile_pos(16.6, 49.2), {"sheet": "npc_preso", "name": ["Tobías, el último preso", "Tobias, the last prisoner"], "light": Color(1, 0.6, 0.35)})
	var bars := _prop("cellbars", tile_pos(17.2, 49.9), 1, 0)
	bars.z_index = 1
	_add_inter("lore", "lore_celdas", tile_pos(34.5, 51.6), {"lines": [["lore_title", ["«Aquí esperan los que no deben salir. Que nadie abra las celdas. Que nadie escuche lo que llama desde fuera.»", "\"Here wait those who must not leave. Let no one open the cells. Let no one heed what calls from outside.\""]]]})
	for st in Lore.STELAE:
		var sl := []
		for ln in st[2]:
			sl.append(["lore_title", ln])
		_add_inter("lore", st[0], tile_pos(st[1].x, st[1].y), {"lines": sl})
	# --- Atrio de las Voces: tres campanas y la inscripción del himno
	# 0 = aguda (pequeña), 1 = media, 2 = grave (grande). De izquierda a derecha suenan grave-media-aguda:
	# el himno tal y como está escrito... que es justo lo que NO hay que hacer.
	var bell_pos := [Vector2(85.5, 50.2), Vector2(82.0, 51.6), Vector2(78.5, 50.2)]
	for i in 3:
		_add_inter("bell", "bell_%d" % i, tile_pos(bell_pos[i].x, bell_pos[i].y), {"note": i})
	_add_inter("lore", "lore_atrio", tile_pos(88.5, 52.6), {"lines": [["lore_title", ["«El Himno de la Vigilia: la voz grave, la voz media, la voz aguda.»", "\"The Hymn of the Vigil: the low voice, the middle voice, the high voice.\""]],
		["lore_title", ["Debajo, alguien ha rayado con las uñas: «EL CORO LO CANTA AL REVÉS».", "Below, someone has scratched with their nails: \"THE CHOIR SINGS IT BACKWARDS\"."]]]})
	for p2 in [Vector2(74, 48.6), Vector2(90, 48.6)]:
		_prop("organ", tile_pos(p2.x, p2.y), 1, 0, 8.0)
	for p3 in [Vector2(77, 53), Vector2(87, 53), Vector2(80, 48.5), Vector2(84, 48.5)]:
		_prop("candle", tile_pos(p3.x, p3.y), 4, int(p3.x) % 4, 0.0, Color(0.6, 0.5, 1.0), 1.2)
	# --- Escalinata del Juicio: estatuas arrodilladas, alfombra y la Brasa del Umbral
	for x2 in [60, 64, 68, 72]:
		_prop("statue", tile_pos(x2, 27.2))
	for x3 in [62, 66, 70]:
		_prop("candle", tile_pos(x3, 29.4), 4, x3 % 4, 0.0, Color(1, 0.8, 0.45), 1.1)
	_add_inter("brasa", "umbral", tile_pos(59.5, 28.4))
	_add_inter("lore", "lore_juicio", tile_pos(73, 28.6), {"lines": [["lore_title", ["«Quien suba esta escalera será pesado en la balanza. Las plumas que te queden hablarán por ti.»", "\"Whoever climbs these stairs shall be weighed on the scales. Your remaining feathers will speak for you.\""]]]})
	# --- antorchas de pared (celdas, escalinata, antesala, pasillo)
	for tp in [Vector2(20.5, 45.7), Vector2(24.5, 45.7), Vector2(28.5, 45.7), Vector2(34.5, 45.7),
			Vector2(59.5, 26.7), Vector2(62.5, 26.7), Vector2(66, 5.7), Vector2(72, 5.7),
			Vector2(39, 53.7), Vector2(59, 53.7), Vector2(44, 53.7), Vector2(54, 53.7)]:
		var wt := WallTorch.new()
		wt.position = tile_pos(tp.x, tp.y)
		if tp.y < 27.0:
			wt.col = Color(1, 0.8, 0.45)
		entities.add_child(wt)
	# --- vitrales del Atrio
	var glass2 := LightShafts.new()
	glass2.position = tile_pos(82, 52)
	glass2.stained = true
	add_child(glass2)
	# --- Antesala del Juicio: estandartes y luz que cae
	for b in [Vector2(66.5, 5.5), Vector2(71.5, 5.5)]:
		_prop("banner", tile_pos(b.x, b.y), 2, 0)
	var shafts := LightShafts.new()
	shafts.position = tile_pos(69, 15)
	shafts.col = Color(1, 0.9, 0.6)
	add_child(shafts)

func k_frame(v: Vector2) -> int:
	return int(v.x) % 2

func _check_trials(lp: Player, r: String) -> void:
	if _trial != "" or lp == null or not lp.is_alive() or active_boss != null or not asc_fight.is_empty():
		return
	for id in TRIALS:
		if TRIALS[id].room == r and not trial_done(id):
			if multiplayer.is_server():
				_server_start_trial(id)
			else:
				_request_trial.rpc_id(1, id)
			return

@rpc("any_peer", "call_remote", "reliable")
func _request_trial(id: String) -> void:
	if multiplayer.is_server():
		_server_start_trial(id)

func _server_start_trial(id: String) -> void:
	if _trial != "" or trial_done(id):
		return
	bcast("_trial_begin", [id])
	_trial_wave = -1
	_trial_wait = 1.8

@rpc("any_peer", "call_remote", "reliable")
func _trial_begin(id: String) -> void:
	_trial = id
	var T: Dictionary = TRIALS[id]
	seal_arena(T.room, T.seal)
	hud.big_message(G.T(T.title), Color(1, 0.55, 0.4), 2.4)
	hud.show_trial(G.T(T.title), 0, T.waves.size())
	Audio.play_music("trial", 0.6)
	if id == "celdas":
		# la Voz susurra desde las celdas
		Audio.sfx("glitch", -8.0)
		hud.subtitle("???", G.L(["Ábrelas... ábrelas todas. Déjalos salir.", "Open them... open them all. Let them out."]), 2.6)

func _trial_tick(delta: float) -> void:
	if _trial == "" or not multiplayer.is_server():
		return
	var T: Dictionary = TRIALS[_trial]
	if _trial_wait > 0.0:
		_trial_wait -= delta
		if _trial_wait <= 0.0:
			_trial_wave += 1
			if _trial_wave >= T.waves.size():
				bcast("_trial_complete", [_trial])
				return
			bcast("_trial_wave_fx", [_trial, _trial_wave])
			for w in T.waves[_trial_wave]:
				bcast("_spawn_trial_enemy", [w[0], tile_pos(w[1], w[2])])
		return
	var alive := 0
	for e in enemies:
		if e.is_alive() and e.get_meta("trial", false):
			alive += 1
	if alive == 0:
		_trial_wait = 1.5

@rpc("any_peer", "call_remote", "reliable")
func _trial_wave_fx(id: String, n: int) -> void:
	var T: Dictionary = TRIALS[id]
	hud.show_trial(G.T(T.title), n + 1, T.waves.size())
	if n > 0:
		hud.big_message(G.T("trial_wave") % [n + 1, T.waves.size()], Color(1, 0.75, 0.5), 1.4)
	if id == "celdas":
		Audio.sfx("gate", -2.0)
		G.shake(2.5, 0.4)
		for d in _cell_doors:
			_open_cell_door(d)
	if id == "umbral" and n == T.waves.size() - 1:
		hud.big_message(G.T("custodio_title"), Color(1, 0.85, 0.5), 2.6, true)
		Audio.sfx("slam", -2.0)
		G.flash(Color(1, 0.9, 0.6, 0.35), 0.4)

func _open_cell_door(d: Sprite2D) -> void:
	d.region_rect = Rect2(24, 0, 24, 30)
	var l: PointLight2D = d.get_child(0)
	var tw := d.create_tween()
	tw.tween_property(l, "energy", 1.2, 0.2)
	tw.tween_interval(1.6)
	tw.tween_property(l, "energy", 0.0, 0.8)
	tw.tween_callback(func(): d.region_rect = Rect2(0, 0, 24, 30))
	Fx.burst(d.global_position + Vector2(0, 10), Color(0.3, 0.25, 0.3, 0.8), 10, 50.0, 0.8, "fx_soft", 120.0, Vector2.DOWN, 0.5, false)

@rpc("any_peer", "call_remote", "reliable")
func _spawn_trial_enemy(type: String, pos: Vector2) -> void:
	var e := _add_enemy(type, pos, true)
	e.set_meta("trial", true)
	e.state = "chase"
	if e.cfg.get("elite", false):
		hud.show_boss(e)
	var col := Color(1, 0.85, 0.5) if type == "custodio" else Color(0.9, 0.3, 0.3)
	Fx.burst(pos + Vector2(0, -8), col, 22, 70.0, 0.7, "fx_soft", 180.0, Vector2.UP, 0.5)
	Fx.ring(pos, 4.0, 30.0, col, 0.4, 2.0)
	if type == "custodio":
		G.shake(6.0, 0.6)
		Fx.light_flash(pos, Color(1, 0.85, 0.5), 3.0, 1.6, 0.8)

@rpc("any_peer", "call_remote", "reliable")
func _trial_complete(id: String) -> void:
	_trial = ""
	_trial_wave = -1
	wflags["trial_" + id] = true
	Prog.flags["trial_" + id] = true
	unseal_arena()
	_refresh_locks(false)
	_ensure_trial_chest(id, true)
	hud.hide_trial()
	hud.big_message(G.T("trial_done"), Color(1, 0.85, 0.4), 2.6)
	Audio.sfx("levelup")
	Audio.play_music("explore", 2.0)
	Prog.quest_step("main1", "trial_" + id)
	if id == "celdas":
		get_tree().create_timer(2.8).timeout.connect(G.toast.bind(G.T("shortcut_open"), Color(0.9, 0.8, 0.7)))
		get_tree().create_timer(1.2).timeout.connect(hud.subtitle.bind("Tobías", G.L(["¡No...! ¿Qué has hecho? Ahora ya no hay nada entre él y nosotros...", "No...! What have you done? Now there's nothing between him and us..."]), 3.2))
	if id == "umbral":
		get_tree().create_timer(2.8).timeout.connect(_custodio_vision)
	if multiplayer.is_server():
		Prog.save_game()

func _trial_reset() -> void:
	_trial = ""
	_trial_wave = -1
	_trial_wait = 0.0
	if hud:
		hud.hide_trial()

# ---------------------------------------------------------------- campanas del Atrio
@rpc("any_peer", "call_remote", "reliable")
func _ring_bell(id: String) -> void:
	var it: Interactable = interactables.get(id)
	if it == null or trial_done("atrio"):
		return
	var n: int = it.data.note
	it.ring()
	Audio.sfx("bell_%d" % n, -3.0, 0.0)
	Fx.ring(it.global_position + Vector2(0, -14), 4.0, 46.0 + n * 10.0, Color(0.75, 0.6, 1.0), 0.7, 2.0)
	_bell_seq.append(n)
	if not multiplayer.is_server() or _bell_seq.size() < 3:
		return
	if _bell_seq == BELL_ORDER:
		bcast("_atrio_solved", [])
	else:
		bcast("_atrio_fail", [])
		for k in 2:
			spawn_extra_enemy("acolito", tile_pos(76 + k * 12, 50))

@rpc("any_peer", "call_remote", "reliable")
func _atrio_solved() -> void:
	_bell_seq.clear()
	wflags["trial_atrio"] = true
	Prog.flags["trial_atrio"] = true
	_refresh_locks(false)
	hud.big_message(G.T("atrio_solved"), Color(0.8, 0.65, 1.0), 2.6)
	Audio.sfx("levelup")
	for i in 3:
		var it: Interactable = interactables.get("bell_%d" % i)
		if it:
			get_tree().create_timer(0.25 * i).timeout.connect(func(): Audio.sfx("bell_%d" % (2 - i), -6.0, 0.0))
	Prog.quest_step("main1", "trial_atrio")
	if multiplayer.is_server():
		Prog.save_game()

@rpc("any_peer", "call_remote", "reliable")
func _atrio_fail() -> void:
	_bell_seq.clear()
	hud.big_message(G.T("atrio_fail"), Color(1, 0.4, 0.5), 1.8)
	Audio.sfx("glitch", -4.0)
	G.shake(3.0, 0.3)


# ---------------------------------------------------------------- escenas cortas (v0.8)
func _custodio_vision() -> void:
	## El Custodio, al caer, reconoce al protagonista. La Voz intenta tapar lo que dice.
	G.flash(Color(1, 0.92, 0.7, 0.45), 0.5)
	Audio.sfx("bell_2", -6.0, 0.0)
	var lines := [
		["El Custodio", ["Mil años... guardando esta puerta. Hasta que volviera el verdugo.", "A thousand years... guarding this door. Until the executioner returned."]],
		["El Custodio", ["Has vuelto. Y ni siquiera recuerdas lo que hiciste.", "You've returned. And you don't even remember what you did."]],
		["???", ["No le escuches. Es solo piedra. Sigue bajando.", "Don't listen to it. It's only stone. Keep going down."], ["Sigue bajando. Ya casi soy libre.", "Keep going down. I'm almost free."]],
	]
	dialog.play(lines, func(): G.toast(G.T("judgement_open"), Color(1, 0.9, 0.6)), true)

func _atrio_echo() -> void:
	## Al entrar por primera vez en el Atrio, el eco del Coro canta su nombre del revés
	Prog.flags["atrio_echo"] = true
	Audio.sfx("bell_2", -10.0, 0.0)
	get_tree().create_timer(0.5).timeout.connect(Audio.sfx.bind("bell_1", -10.0, 0.0))
	get_tree().create_timer(1.0).timeout.connect(Audio.sfx.bind("bell_0", -10.0, 0.0))
	hud.subtitle(G.L(["El Coro (eco)", "The Choir (echo)"]), G.L(["...emreud, emreud, ojab yum ed odatse ah euq le...", "...peels, peels, woleb raf morf emac ohw eh..."]), 3.4)
	get_tree().create_timer(3.8).timeout.connect(hud.subtitle.bind("", G.L(["(Lo cantan al revés. Como si no quisieran despertar a alguien.)", "(They sing it backwards. As if trying not to wake someone.)"]), 3.0))

class WallTorch extends Node2D:
	## Antorcha de pared: soporte de hierro, llama en capas que parpadea, chispas y luz cálida
	var t := 0.0
	var col := Color(1, 0.55, 0.2)
	var _l: PointLight2D
	func _ready() -> void:
		t = randf() * 10.0
		_l = PointLight2D.new()
		_l.texture = Fx.tex("light")
		_l.color = col
		_l.texture_scale = 1.3
		_l.energy = 0.95
		_l.position = Vector2(0, -12)
		add_child(_l)
	func _process(delta: float) -> void:
		t += delta
		_l.energy = 0.9 + 0.12 * sin(t * 13.0) + 0.06 * sin(t * 31.0)
		if randf() < 0.04:
			Fx.burst(global_position + Vector2(0, -16), col.lerp(Color(1, 0.9, 0.6), 0.5), 1, 18.0, 0.7, "fx_px", 30.0, Vector2.UP, 0.4)
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2(-3, -6), Vector2(6, 2)), Color(0.12, 0.1, 0.14))
		draw_rect(Rect2(Vector2(-1, -8), Vector2(2, 8)), Color(0.32, 0.28, 0.34))
		draw_rect(Rect2(Vector2(-3, -10), Vector2(6, 3)), Color(0.24, 0.2, 0.26))
		var f := sin(t * 11.0) * 1.5
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -10), Vector2(-1, -16 - f), Vector2(0, -20 - f), Vector2(2, -15), Vector2(3, -10)]), col)
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -10), Vector2(0, -16 + f * 0.5), Vector2(2, -10)]), col.lerp(Color(1, 0.9, 0.5), 0.6))
		draw_rect(Rect2(Vector2(-1, -12), Vector2(1, 2)), Color(1, 0.98, 0.85))

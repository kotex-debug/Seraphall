extends Node2D
## Mundo del Estrato I: construye el mapa, gestiona entidades, red, jefes, misiones y escenas.

const TS := 16
const MAPW := 384   # cuatro estratos en franjas de 96 casillas
const MAPH := 96

const ROOMS_I := [
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
	# v0.8: capilla secreta bajo la Galería Rota (tras un muro agrietado)
	{"id": "cap_link", "rect": Rect2i(83, 71, 3, 6)},
	{"id": "capilla", "rect": Rect2i(79, 76, 11, 7)},
	# v0.8: batallas secretas. El Cadalso (bajo la Capilla) y la Cornisa del Coloso (tras el Mirador)
	{"id": "cad_link", "rect": Rect2i(83, 83, 3, 3)},
	{"id": "cadalso", "rect": Rect2i(77, 86, 15, 9)},
	{"id": "cor_link", "rect": Rect2i(31, 77, 3, 5)},
	{"id": "cornisa", "rect": Rect2i(13, 63, 21, 14)},
	# La Cuna de Ceniza: sala de entrenamiento del prólogo, sin salida al resto del mapa
	{"id": "prologo", "rect": Rect2i(6, 8, 22, 16)},
]
const AREAS_I := {"sanct": "area_sanct", "hall1": "area_sanct", "chains": "area_chains", "hall2": "area_chains", "east": "area_gallery",
	"gallery": "area_gallery", "yard": "area_yard", "alcove": "area_yard", "alc_link": "area_yard", "circle": "area_circle", "mirador": "area_mirador", "mir_link": "area_sanct",
	"nimbo": "area_nimbo", "nim_link": "area_nimbo", "choir": "area_choir", "choir_link": "area_atrio",
	"celdas": "area_celdas", "cel_link": "area_celdas", "cel_up": "area_celdas", "atrio": "area_atrio", "atr_link": "area_atrio",
	"esc_link": "area_juicio", "escala": "area_juicio", "antesala": "area_juicio", "jui_link": "area_juicio",
	"cap_link": "area_capilla", "capilla": "area_capilla", "cad_link": "area_cadalso", "cadalso": "area_cadalso",
	"cor_link": "area_cornisa", "cornisa": "area_cornisa", "prologo": "area_prologo"}
const PEACE_AREAS_I := ["area_sanct", "area_mirador", "area_nimbo", "area_capilla"]
var ROOMS: Array = ROOMS_I + Strata.ROOMS
var AREAS: Dictionary = AREAS_I.merged(Strata.AREAS)
var PEACE_AREAS: Array = PEACE_AREAS_I + Strata.PEACE
var AREA_COLORS: Dictionary = AREA_COLORS_I.merged(Strata.AREA_COLORS)
var PITS: Array = PITS_I + [[Rect2i(229, 57, 3, 3), "ember"], [Rect2i(249, 59, 3, 3), "ember"], [Rect2i(134, 37, 3, 3), "void"], [Rect2i(326, 61, 3, 3), "void"]]
var TRIALS: Dictionary = TRIALS_I.merged(Strata.TRIALS)
var ARENAS: Dictionary = ARENAS_I.merged({"orrun": ["b_arena", "luz"], "vulkaris": ["f_arena", "celda"], "azrahel": ["t_arena", "luz"], "verdugo": ["cadalso", "luz"], "coloso": ["cornisa", "luz"]})

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
var _join_wait := -1.0
var _prologue: Node = null

# ====================================================================== construcción
func setup(p_main: Node, mode: String) -> void:
	main = p_main
	_game_mode = mode
	name = "World"

func _ready() -> void:
	y_sort_enabled = false
	add_to_group("world")
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
	_build_strata()
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
		# al cargar, los jefes esperan a que entres en su sala y las salas vuelven a estar pobladas
		wflags.erase("carcelero_intro")
		wflags.erase("choir_intro")
		for k in wflags.keys():
			if str(k).begins_with("clear_"):
				wflags.erase(k)
		world_difficulty = Prog.difficulty
		G.set_meta("lightwing", world_difficulty == 0)
		for e in enemies:
			e.reset_state()
		_spawn_player(Net.my_id(), 1)
		_apply_world_flags(true)
		Audio.play_music("explore")
		if _game_mode == "new":
			if not G.get_meta("prologue", false):
				Prog.start_quest("main1")
			_play_intro()
		else:
			_after_load()
	else:
		# hasta recibir _welcome la pantalla queda en negro; se reintenta por si el mensaje se perdiera
		hud.fade_rect.color = Color(0, 0, 0, 1)
		_req_join.rpc_id(1, Prog.equipped)
		_join_wait = 0.0

func _join_tick(delta: float) -> void:
	## Cliente: nunca te quedas colgado esperando al anfitrión
	if _join_wait < 0.0:
		return
	_join_wait += delta
	if _join_wait > 20.0:
		_join_wait = -1.0
		main.back_to_title(G.T("conn_timeout"))
	elif int(_join_wait) % 4 == 3 and int(_join_wait - delta) % 4 != 3:
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
				if rid == "mirador" or rid == "alcove" or rid == "cornisa" or rid == "cor_link":
					t = 19 if rng.randf() < 0.6 else t
				if rid == "cadalso" or rid == "cad_link":
					t = 20 + rng.randi_range(0, 1)
				var stn := Strata.stratum_of_room(rid)
				if stn > 1:
					var fl: Array = Strata.FLOORS[stn]
					var rr := rng.randf()
					t = fl[0] if rr < 0.6 else (fl[2] if rr < 0.8 else (fl[3] if rr < 0.92 else fl[1]))
					if (rid == "t_escalera" and absf(x - 335.5) < 1.6) or rid == "t_link5" or (rid == "t_link4" and absf(x - 335.5) < 1.6):
						t = Strata.CARPET
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
					var wst := Strata.stratum_of_room(brid)
					if wst > 1:
						wt = Strata.WALLS[wst][0 if rng.randf() < 0.7 else 1]
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
	aby.name = "Abyss"
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
	for i in [6, 7, 8, 9, 12, 16, 18, 28, 29, 30, 31, 32, 33, 38, 39, 44, 45, 50, 51]:
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
	var skip := ["yard", "circle", "choir", "nimbo", "escala", "antesala", "capilla", "cap_link"]
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

const PITS_I := [[Rect2i(37, 61, 4, 4), "ember"], [Rect2i(52, 60, 5, 4), "ember"], [Rect2i(79, 58, 6, 5), "void"],
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
const AREA_COLORS_I := {"area_sanct": Color(1, 0.7, 0.4), "area_chains": Color(0.75, 0.6, 0.85), "area_gallery": Color(0.45, 0.6, 1.0),
	"area_yard": Color(1, 0.5, 0.4), "area_circle": Color(1, 0.3, 0.4), "area_mirador": Color(0.6, 0.9, 1.0),
	"area_nimbo": Color(1, 0.88, 0.5), "area_choir": Color(0.78, 0.55, 1.0), "area_celdas": Color(0.85, 0.45, 0.35),
	"area_atrio": Color(0.6, 0.5, 0.95), "area_juicio": Color(1, 0.85, 0.55), "area_capilla": Color(0.7, 1.0, 0.85),
	"area_cadalso": Color(1, 0.35, 0.4), "area_cornisa": Color(0.55, 0.95, 1.0), "area_prologo": Color(1, 0.85, 0.55)}
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

## Mapa detallado: 3 píxeles por casilla, con losas, borde iluminado, muros con ladrillo y pozos que brillan.
var _map_hd: ImageTexture
var _map_hd_seen := -1
func areas_of_stratum(st: int) -> Array:
	var out := []
	for r in ROOMS:
		if Strata.stratum_of_room(r.id) != st:
			continue
		var a: String = AREAS.get(r.id, "")
		if a != "" and not a in out and r.id != "prologo":
			out.append(a)
	return out

func map_seen(rid: String) -> bool:
	## sala vista y del estrato en el que estás (el mapa solo muestra tu estrato)
	return Prog.flags.get("seen_" + rid, false) and Strata.stratum_of_room(rid) == cur_stratum()

func map_texture_hd() -> ImageTexture:
	var n := cur_stratum() * 1000
	for r in ROOMS:
		if map_seen(r.id):
			n += 1
	if _map_hd and n == _map_hd_seen:
		return _map_hd
	_map_hd_seen = n
	const K := 3
	var img := Image.create(MAPW * K, MAPH * K, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in MAPH:
		for x in MAPW:
			var i := y * MAPW + x
			var g := grid[i]
			if g == 2:
				# cara de muro de una sala vista: ladrillo oscuro con filo de luz arriba
				for dy in [1, 2]:
					if y + dy < MAPH and grid[(y + dy) * MAPW + x] == 1 and room_of[(y + dy) * MAPW + x] >= 0:
						var wr: String = ROOMS[room_of[(y + dy) * MAPW + x]].id
						if map_seen(wr):
							var wc: Color = AREA_COLORS.get(AREAS.get(wr, ""), Color.WHITE)
							for py in K:
								for px in K:
									var cc := wc.darkened(0.72 if dy == 1 else 0.62)
									if py == 0 and dy == 2:
										cc = wc.darkened(0.35)
									elif (py == 1 and (px + x) % 3 == 0) or (py == 2 and (px + x) % 3 == 1):
										cc = cc.darkened(0.3)
									img.set_pixel(x * K + px, y * K + py, cc)
							break
				continue
			if room_of[i] < 0 or not map_seen(ROOMS[room_of[i]].id):
				continue
			var rid: String = ROOMS[room_of[i]].id
			var c: Color = AREA_COLORS.get(AREAS.get(rid, ""), Color.WHITE)
			if g == 5:
				# pozo: vacío con resplandor en el centro
				var core := false
				for pit in PITS:
					var pr: Rect2i = pit[0]
					if pr.has_point(Vector2i(x, y)) and absf(x - pr.get_center().x + 0.5) <= 1.0 and absf(y - pr.get_center().y + 0.5) <= 1.0:
						core = true
				for py in K:
					for px in K:
						var pc := Color(0.04, 0.01, 0.05)
						if core:
							pc = Color(1, 0.55, 0.25) if (px == 1 and py == 1) else Color(0.55, 0.22, 0.12)
						img.set_pixel(x * K + px, y * K + py, pc)
				continue
			if g != 1:
				continue
			var base := c.darkened(0.52)
			var hsh := (x * 73 + y * 151) % 7
			var sides := []
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				sides.append(nx < 0 or ny < 0 or nx >= MAPW or ny >= MAPH or (grid[ny * MAPW + nx] != 1 and grid[ny * MAPW + nx] != 5))
			for py in K:
				for px in K:
					var pc2 := base
					if (x + y) % 2 == 0:
						pc2 = pc2.lightened(0.04)
					if px == 0 and py == 0:
						pc2 = base.darkened(0.25)              # junta de las losas
					elif px == 1 and py == 1 and hsh == 0:
						pc2 = base.lightened(0.12)             # brillo suelto
					var rim = (sides[0] and px == K - 1) or (sides[1] and px == 0) or (sides[2] and py == K - 1) or (sides[3] and py == 0)
					if rim:
						pc2 = c.lightened(0.3)
					img.set_pixel(x * K + px, y * K + py, pc2)
	_map_hd = ImageTexture.create_from_image(img)
	return _map_hd

## Dónde está el siguiente paso de la misión principal (en casillas), o INF si no se sabe
const OBJECTIVE_ROOMS := {"brasa": Vector2(49, 86), "talk_brenna": Vector2(46, 84), "trial_celdas": "celdas", "kill_carcelero": "yard",
	"trial_umbral": "antesala", "enter_circle": Vector2(63.5, 13.5), "kill_seravel": "circle",
	"talk_oso": Vector2(113.5, 57.6), "enter_ciervo": "b_arena", "kill_orrun": "b_arena",
	"talk_archivero": Vector2(201.5, 50.8), "enter_yunque": "f_arena", "kill_vulkaris": "f_arena",
	"talk_lirio": Vector2(323, 57.4), "enter_trono": "t_arena", "kill_azrahel": "t_arena"}
func objective_pos() -> Vector2:
	var mq := ""
	var cs := cur_stratum()
	var qid := "main%d" % cs
	if Prog.quest_active(qid):
		mq = qid
	if mq == "":
		# sin misión en este estrato: señala la grieta al siguiente si ya está abierta
		for boss in Strata.RIFTS:
			var rd: Array = Strata.RIFTS[boss]
			if int(rd[1]) == cs + 1 and wflags.get(boss + "_dead", false):
				return rd[0]
		return Vector2.INF
	var steps: Array = Prog.QUESTS[mq].steps
	var st: int = Prog.quests[mq].step
	if st >= steps.size():
		return Vector2.INF
	var where = OBJECTIVE_ROOMS.get(steps[st].id, null)
	# puertas de Arconte: el objetivo es la primera prueba que falte
	for gid in Strata.GATES:
		if Strata.GATES[gid].step[1] == steps[st].id:
			for tid: String in Strata.GATES[gid].trials:
				if not trial_done(tid):
					where = TRIALS[tid].room
					break
	if where == null:
		return Vector2.INF
	if where is Vector2:
		return where
	for r in ROOMS:
		if r.id == where:
			return Vector2(_rect_of(r).get_center())
	return Vector2.INF

func map_markers() -> Array:
	## [tipo, posición en casillas, color, etiqueta]
	var out := []
	for id in interactables:
		var it: Interactable = interactables[id]
		if not is_instance_valid(it) or not map_seen(room_at(it.position)):
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
			"rift":
				out.append(["objective", tp, Color(0.7, 0.45, 1.0), ""])
	# pruebas de las antesalas, cierres e inscripciones
	for tid in TRIALS.keys() + ["atrio"]:
		var room: String = TRIALS[tid].room if TRIALS.has(tid) else "atrio"
		if map_seen(room):
			out.append(["trial_done" if trial_done(tid) else "trial", _room_corner(room), UIKit.GOLD if trial_done(tid) else UIKit.RED, ""])
	for L in LOCKS:
		var lr: Rect2i = L[1]
		if not trial_done(L[0]) and map_seen(room_at(tile_pos(lr.position.x, lr.position.y + 1))) or (not trial_done(L[0]) and map_seen(room_at(tile_pos(lr.position.x, lr.position.y - 1)))):
			out.append(["lock", Vector2(lr.get_center()), Color(0.75, 0.7, 0.8), ""])
	for e in enemies:
		if e.is_boss and not e.type in ["verdugo", "coloso"] and map_seen(room_at(e.spawn_pos)):
			var dead: bool = wflags.get(Prog.BOSS_INFO.get(e.type, {}).get("flag", e.type + "_dead"), false)
			out.append(["boss_dead" if dead else "boss", e.spawn_pos / TS, UIKit.RED, G.T(e.cfg.get("title", "boss_carcelero"))])
	var obj := objective_pos()
	if obj != Vector2.INF:
		out.append(["objective", obj, UIKit.GOLD, ""])
	for c in entities.get_children():
		if c is GhostEcho and Prog.flags.get("echo_" + c.id, false) and cur_stratum() == 1:
			out.append(["echo", c.position / TS, Color(0.6, 0.85, 1.0), ""])
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
	if tex in ["pillar", "statue", "organ", "tree_dead", "throne"]:
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
		var yc := Depth3D.Column.new()
		yc.position = tile_pos(p.x, p.y)
		yc.height = 66.0
		yc.radius = 6.0
		yc.stone = Color(0.5, 0.44, 0.46)
		yc.gold = Color(0.55, 0.32, 0.2)
		yc.broken = p.y > 40
		entities.add_child(yc)
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
	_place_urns()
	_place_npc_life()
	_place_webs()
	_place_fallen()
	_place_ghost_echoes()
	_collect_shadow_lights()

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
		var col := Depth3D.Column.new()
		col.position = p
		col.height = 78.0
		col.broken = i % 3 == 0
		col.ivy = i % 4 == 1
		entities.add_child(col)
	for bp in [Vector2(43, 3.5), Vector2(55, 3.5)]:
		_prop("banner", tile_pos(bp.x, bp.y), 2, 0)
	var shafts := LightShafts.new()
	shafts.position = tile_pos(49, 14)
	shafts.col = Color(1, 0.85, 0.55)
	add_child(shafts)
	# --- Nave del Coro: órganos, velas azules, vitrales
	for o in [Vector2(78, 31), Vector2(86, 31)]:
		_prop("organ", tile_pos(o.x, o.y), 1, 0, 8.0)
	# tubos de órgano gigantes alrededor de la nave (columnas en perspectiva)
	for i in 6:
		var a := PI + PI * i / 5.0
		var pc := Depth3D.Column.new()
		pc.position = tile_pos(82, 37) + Vector2(cos(a) * 112.0, sin(a) * 96.0 + 30.0)
		pc.height = 84.0 + (i % 2) * 18.0
		pc.radius = 4.0
		pc.stone = Color(0.55, 0.45, 0.72)
		pc.gold = Color(0.85, 0.85, 0.95)
		entities.add_child(pc)
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
		"azrahel_p3":
			create_tween().tween_property(canvas_mod, "color", Color(0.36, 0.26, 0.5), 1.8)
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
		["acolito", 78, 52], ["acolito", 87, 60], ["acolito", 82, 67], ["planidera", 79, 63], ["planidera", 88, 69], ["planidera", 55, 60],
		["bestia", 76, 61], ["bestia", 88, 66], ["hueco", 84, 70], ["hueco", 74, 59],
		["acolito", 70, 28], ["guardia", 63, 28], ["hueco", 35, 54], ["guardia", 49, 57], ["penitente", 44, 61], ["penitente", 70, 61],
		["carcelero", 49, 38],
		["choir", 82, 35],
		["seravel", 49, 10],
	]
	for e in list:
		_add_enemy(e[0], tile_pos(e[1], e[2]), false)
	# jefes secretos: ocultos hasta que se les invoca
	_add_enemy("verdugo", tile_pos(84.5, 90.5), false)
	_add_enemy("coloso", BossColoso.ANCHOR, false)
	# Estratos II-IV y sus Arcontes
	for e2 in Strata.ENEMIES:
		_add_enemy(e2[0], tile_pos(e2[1], e2[2]), false)
	_add_enemy("orrun", tile_pos(141, 9), false)
	_add_enemy("vulkaris", tile_pos(240, 9), false)
	_add_enemy("azrahel", tile_pos(336, 8), false)

func _add_enemy(type: String, pos: Vector2, extra: bool) -> Enemy:
	var e: Enemy
	match type:
		"seravel":
			e = preload("res://scripts/actors/boss_seravel.gd").new()
		"carcelero":
			e = preload("res://scripts/actors/boss_carcelero.gd").new()
		"choir":
			e = preload("res://scripts/actors/boss_choir.gd").new()
		"verdugo":
			e = preload("res://scripts/actors/boss_verdugo.gd").new()
		"coloso":
			e = preload("res://scripts/actors/boss_coloso.gd").new()
		"orrun":
			e = preload("res://scripts/actors/boss_orrun.gd").new()
		"vulkaris":
			e = preload("res://scripts/actors/boss_vulkaris.gd").new()
		"azrahel":
			e = preload("res://scripts/actors/boss_azrahel.gd").new()
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
	_add_inter("chest", "chest_reaper", tile_pos(72.5, 25.4), {"weapon": "reaper", "ecos": 200})
	_add_inter("chest", "chest_yard", tile_pos(59, 34), {"feathers": 1, "ecos": 250, "items": {"iron": 1, "incense": 1}})
	_add_inter("chest", "chest_mirador", tile_pos(37.5, 88.5), {"items": {"amulet_eye": 1}, "ecos": 150, "weapon": "bow"})
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
	for bw in breakables.values():
		if wflags.get("broken_" + bw.id, false):
			bw.set_broken(true)
	# Tobías sale de su celda cuando cae el Carcelero
	if wflags.get("carcelero_dead", false) and interactables.has("preso"):
		interactables["preso"].position = tile_pos(21.5, 50.8)
	for e in enemies:
		if e.type == "carcelero" and wflags.get("carcelero_dead", false):
			e.die(); e.visible = false
		if e.type == "seravel" and wflags.get("seravel_dead", false):
			e.die(); e.visible = false
		if e.type == "choir" and wflags.get("choir_dead", false):
			e.die(); e.visible = false
		if e.type in Strata.ARCHONS and wflags.get(e.type + "_dead", false):
			e.die(); e.visible = false
	_refresh_rifts()
	if Prog.dropped_ecos.has("amount") and (int(Prog.dropped_ecos.amount) > 0 or int(Prog.dropped_ecos.get("feather", 0)) > 0):
		_spawn_ecos_drop()

func _spawn_ecos_drop() -> void:
	if interactables.has("ecosdrop"):
		interactables["ecosdrop"].queue_free()
		interactables.erase("ecosdrop")
	var p: Array = Prog.dropped_ecos.pos
	_add_inter("ecos", "ecosdrop", Vector2(p[0], p[1]), {"amount": Prog.dropped_ecos.amount, "feather": int(Prog.dropped_ecos.get("feather", 0))})

func _after_load() -> void:
	var p := local_player()
	if p:
		p.respawn_at(_brasa_spawn(Prog.last_brasa))
	var st: int = int(Strata.BRASA_STRATUM.get(Prog.last_brasa, 1))
	hud.show_area(G.L(Strata.STRATUM_NAMES[st]), G.T(AREAS.get(room_at(p.global_position), "area_sanct")) if p else "")
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

func nearest_player_in(rid: String, pos: Vector2) -> Node2D:
	## Como nearest_player, pero solo cuenta a quien está en esa sala
	var best: Node2D = null
	var bd := INF
	for p in players.values():
		if p.is_alive() and not p.cutscene and room_at(p.global_position) == rid:
			var d := pos.distance_to(p.global_position)
			if d < bd:
				bd = d
				best = p
	return best

func room_ramp(rid: String) -> Array:
	var tier: int = int(Strata.ROOM_TIER.get(rid, 3))
	if int(diff().skulls) >= 3:
		tier = mini(3, tier + 2)  # Serafín Caído apenas perdona al principio
	return Strata.TIER_MULT[tier]

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
	_join_tick(delta)
	_title_tick(delta)
	_room_lock_tick(delta)
	var lp := local_player()
	if G.photo_mode:
		_photo_tick()
		return
	_v04_tick(delta, lp)
	_trial_tick(delta)
	if lp:
		var target: Vector2 = lp.global_position + Vector2(0, -10) + lp.aim * (70.0 if G.combat_mode == 2 else 22.0)
		var want_mouse := Input.MOUSE_MODE_VISIBLE
		if G.combat_mode == 2 and G.autotest == "" and not is_menu_open() and not G.photo_mode and lp.is_alive():
			want_mouse = Input.MOUSE_MODE_CAPTURED
		if Input.mouse_mode != want_mouse:
			Input.mouse_mode = want_mouse
		if active_boss and active_boss.is_alive() and active_boss.active:
			if active_boss.has_method("cam_point"):
				target = target.lerp(active_boss.cam_point(), 0.42)
			else:
				target = target.lerp(active_boss.global_position + Vector2(0, -20), 0.28)
		_track_fight()
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
			# solo lo que un jugador puede ver: el paquete cabe en un datagrama y no se pierde troceado
			var arr := PackedFloat32Array()
			for e in enemies:
				if e.is_alive() and arr.size() < 200 and _near_any_player(e.global_position, 520.0):
					arr.append_array([e.idx, e.position.x, e.position.y, e.facing, _state_code(e.state)])
			for pid in joined_peers:
				_esync.rpc_id(pid, arr)

func _near_any_player(pos: Vector2, r: float) -> bool:
	for p in players.values():
		if p.global_position.distance_to(pos) < r:
			return true
	return false

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
	elif event.is_action_pressed("ping") and not menu.visible and not dialog.is_open():
		var lp := local_player()
		if lp and lp.is_alive():
			bcast("_ping", [Net.my_id(), get_global_mouse_position() if G.combat_mode == 0 else lp.global_position + lp.aim * 120.0])
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
	if r == "" or not AREAS.has(r) or r == "prologo":
		return
	if not Prog.flags.get("seen_" + r, false):
		Prog.flags["seen_" + r] = true
		if Strata.QUEST_ON_ROOM.has(r):
			Prog.start_quest(Strata.QUEST_ON_ROOM[r])
		var seen := 0
		for rr in ROOMS:
			if Prog.flags.get("seen_" + rr.id, false):
				seen += 1
		Ach.set_goal("cartographer", ROOMS.size() - 1)  # la Cuna del prólogo no cuenta
		Ach.set_max("rooms", seen)
	var a: String = AREAS[r]
	if a != _area:
		var first := _area == ""
		_area = a
		if not first:
			if a == "area_nimbo" and not Prog.flags.get("nimbo_intro", false) and active_boss == null:
				_nimbo_intro()
			else:
				_title_pending = a
				_title_pending_t = 0.0
			if Lore.AREA_THOUGHTS.has(a) and not Prog.flags.get("thought_" + a, false):
				_area_thoughts(a)
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
		elif Strata.AMBIENT.has(a):
			target = Strata.AMBIENT[a]
		create_tween().tween_property(canvas_mod, "color", target, 1.5)
		var peaceful := a in PEACE_AREAS
		create_tween().tween_property(self, "_calm", 1.0 if peaceful else 0.0, 2.0)
		if active_boss == null and not _contemplating:
			var st := Strata.stratum_of_room(r)
			var mus: String = "chapel" if a == "area_capilla" else ("peace" if peaceful else Strata.MUSIC.get(st, "explore"))
			if not ResourceLoader.exists("res://assets/audio/music_%s.ogg" % mus):
				mus = "explore"
			Audio.play_music(mus, 2.5)
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
	_check_archons(lp, r)
	if r == "atrio" and not Prog.flags.get("atrio_echo", false) and not trial_done("atrio"):
		_atrio_echo()
	if r == "escala" and not Prog.flags.get("escala_seen", false):
		_escala_pan()
	if r == "circle" and not wflags.get("seravel_dead", false) and not _boss_started and lp.is_alive() and asc_fight.is_empty():
		if multiplayer.is_server():
			_server_start_boss()
		else:
			_boss_started = true  # evita repetir la petición
			_request_boss.rpc_id(1)

# ---------------------------------------------------------------------- títulos de zona
var _title_pending := ""
var _title_pending_t := 0.0
var _title_cd := 0.0
var _title_last := {}

func _title_tick(delta: float) -> void:
	## Evita que los títulos se pisen al ir y venir entre salas: espera a que te quedes,
	## deja un respiro entre títulos y no repite el mismo enseguida.
	_title_cd = maxf(0.0, _title_cd - delta)
	if _title_pending == "":
		return
	_title_pending_t += delta
	if _title_pending != _area:
		_title_pending = ""
		return
	if _title_pending_t < 0.7 or _title_cd > 0.0:
		return
	var now := Time.get_ticks_msec()
	if now - int(_title_last.get(_title_pending, -60000)) >= 45000:
		hud.show_area("", G.T(_title_pending))
		_title_last[_title_pending] = now
		_title_cd = 6.0
	_title_pending = ""

# ---------------------------------------------------------------------- salas cerradas
## Al entrar en una sala con enemigos, las salidas se cierran hasta acabar con todos.
## Los enemigos despiertan por tandas: menos a la vez en las primeras salas.
var room_lock := ""
var _lock_check_t := 0.0
var _lock_idle := 0.0
var _lock_away := 0.0
var _lock_wake_t := 0.0
var _lock_total := 0

func _room_enemies(rid: String) -> Array:
	var out := []
	for e in enemies:
		if e.home_room == rid and e.is_alive() and not e.is_boss and not e.get_meta("extra", false):
			out.append(e)
	return out

func _lock_blocked() -> bool:
	return active_boss != null or _trial != "" or secret_fight != "" or not asc_fight.is_empty() or _prologue != null

func _room_lock_tick(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if room_lock == "":
		_lock_check_t -= delta
		if _lock_check_t > 0.0 or _lock_blocked():
			return
		_lock_check_t = 0.12
		for p in players.values():
			if not p.is_alive() or p.cutscene:
				continue
			var r := room_at(p.global_position)
			if r == "" or AREAS.get(r, "") in PEACE_AREAS:
				continue
			var list := _room_enemies(r)
			if not list.is_empty():
				_start_room_lock(r, list)
				return
		return
	var left := _room_enemies(room_lock)
	if left.is_empty():
		bcast("_room_unlock", [room_lock, true])
		return
	# seguridad: nunca te quedas encerrado (enemigo inalcanzable, o ya no hay nadie dentro)
	_lock_idle += delta
	_lock_away = 0.0 if _any_player_in(room_lock) else _lock_away + delta
	if _lock_idle > 120.0 or _lock_away > 1.5:
		bcast("_room_unlock", [room_lock, false])
		return
	bcast_lock_count(left.size())
	var awake := 0
	var next: Enemy = null
	for e in left:
		if e.active:
			awake += 1
		elif next == null:
			next = e
	_lock_wake_t -= delta
	if next and awake < _lock_cap(room_lock) and _lock_wake_t <= 0.0:
		_lock_wake_t = 0.7
		next.active = true
		bcast("_enemy_wake", [next.idx])

func _any_player_in(rid: String) -> bool:
	for p in players.values():
		if p.is_alive() and room_at(p.global_position) == rid:
			return true
	return false

func _lock_cap(rid: String) -> int:
	return int(room_ramp(rid)[3]) + (1 if joined_peers.size() > 0 else 0)

func _start_room_lock(rid: String, list: Array) -> void:
	# los más débiles primero
	list.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.max_hp < b.max_hp)
	var cap := _lock_cap(rid)
	var sleeping := []
	for i in list.size():
		var e: Enemy = list[i]
		e.active = i < cap
		if i >= cap:
			sleeping.append(e.idx)
	_lock_idle = 0.0
	_lock_away = 0.0
	_lock_wake_t = 0.7
	bcast("_room_lock", [rid, list.size(), sleeping])

@rpc("any_peer", "call_remote", "reliable")
func _room_lock(rid: String, total: int, sleeping: Array) -> void:
	room_lock = rid
	_lock_total = total
	for i: int in sleeping:
		if i < enemies.size():
			enemies[i].modulate = Color(0.45, 0.42, 0.55)
	seal_arena(rid, "coro" if rid in ["atrio", "atr_link", "choir_link"] else ("luz" if Strata.stratum_of_room(rid) % 2 == 0 else "celda"), false)
	hud.show_trial(G.L(["SALA CERRADA", "ROOM SEALED"]), 0, total, true)
	if not Prog.flags.get("seen_room_lock", false):
		Prog.flags["seen_room_lock"] = true
		G.toast(G.L(["Las salidas se cierran: acaba con todos para seguir.", "The exits seal shut: defeat them all to go on."]), Color(1, 0.75, 0.55))

var _lock_shown := -1
func bcast_lock_count(n: int) -> void:
	if n != _lock_shown:
		_lock_shown = n
		bcast("_room_lock_count", [n])

@rpc("any_peer", "call_remote", "reliable")
func _room_lock_count(n: int) -> void:
	if room_lock != "":
		hud.show_trial(G.L(["SALA CERRADA", "ROOM SEALED"]), _lock_total - n, _lock_total, true)

@rpc("any_peer", "call_remote", "reliable")
func _enemy_wake(i: int) -> void:
	if i >= enemies.size():
		return
	var e: Enemy = enemies[i]
	e.create_tween().tween_property(e, "modulate", Color.WHITE, 0.35)
	Fx.burst(e.global_position + Vector2(0, -8), Color(0.9, 0.35, 0.3), 12, 60.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4)
	Fx.ring(e.global_position, 3.0, 20.0, Color(1, 0.45, 0.35), 0.3, 2.0)
	Audio.sfx("charge", -10.0, 0.2)

@rpc("any_peer", "call_remote", "reliable")
func _room_unlock(rid: String, cleared: bool) -> void:
	if room_lock != rid:
		return
	room_lock = ""
	_lock_shown = -1
	unseal_arena()
	hud.hide_trial()
	for e in _room_enemies(rid):
		e.active = true
		e.modulate = Color.WHITE
	if cleared:
		wflags["clear_" + rid] = true
		Audio.sfx("gate", -2.0, 0.0)
		# la primera vez paga; repetir la sala tras descansar ya no da bonus y sus bajas valen mucho menos
		if not Prog.flags.get("once_" + rid, false):
			Prog.flags["once_" + rid] = true
			var bonus := 10 * _lock_total * Strata.stratum_of_room(rid)
			Prog.add_ecos_flat(bonus)
			G.pickup("icon_eco", G.L(["Sala liberada  +%d", "Room cleared  +%d"]) % bonus, Color(0.7, 1.0, 0.75))
		else:
			G.pickup("icon_eco", G.L(["Sala liberada", "Room cleared"]), Color(0.7, 1.0, 0.75))

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
	if exec_target and is_instance_valid(exec_target) and exec_target.is_alive() and exec_target.is_staggered():
		_execute(p, exec_target)
		return
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
				_pay_brasa(p, it)
				if Prog.has_skill("p7"):
					Prog.add_ecos_flat(400)
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
		"altar":
			_altar(it)
		"rift":
			if it.id == "prologue_rift" and _prologue:
				_prologue.finish()
			else:
				_rift(it)
		"lore":
			Prog.flags["read_" + it.id] = true
			_count_lore()
			var ll := []
			for l in it.data.lines:
				ll.append([G.T(l[0]), l[1]])
			dialog.play(ll, Callable())

func _pay_brasa(p: Player, it: Interactable) -> void:
	## Encender una Brasa cuesta una pluma: la arrancas tú y la echas al fuego (sin plumas, la Brasa se apiada)
	Fx.burst(it.global_position + Vector2(0, -10), Color(1, 0.7, 0.35), 14, 70.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.6)
	if Prog.wing_feathers <= 0:
		return
	Prog.lose_wing_feather()
	send_look()
	Audio.sfx("feather_tear", -4.0, 0.0)
	var wc := Look.color_of(G.look, "wing")
	Fx.burst(p.global_position + Vector2(0, -12), wc, 14, 90.0, 1.2, "fx_feather", 180.0, (it.global_position - p.global_position).normalized(), 1.2, false, Vector2(0, 30))
	Fx.text(p.global_position + Vector2(0, -26), G.L(["-1 PLUMA", "-1 FEATHER"]), Color(1, 0.75, 0.5), 10)
	if Prog.wing_feathers <= 3:
		Prog.achieve("featherless")

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
				var fb := int(Prog.dropped_ecos.get("feather", 0))
				Prog.dropped_ecos = {}
				if fb > 0 and Prog.regrow_wing_feather():
					_feather_recovered(1, it.global_position)
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
	if _join_wait < 0.0:
		return  # respuesta repetida de un reintento
	_join_wait = -1.0
	hud.fade_to(0.0, 0.8)
	Ach.unlock("coop_join")
	wflags = flags
	world_difficulty = host_diff
	G.set_meta("lightwing", world_difficulty == 0)
	joined_peers = [1]
	for i in estates.size():
		var s: Array = estates[i]
		var e: Enemy
		if i < enemies.size():
			e = enemies[i]
			# la dificultad es la del anfitrión, no la de tu partida
			e.reset_state()
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
	Ach.unlock("coop_join")
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

func request_parry_enemy(idx: int, perfect := true) -> void:
	if multiplayer.is_server():
		bcast("_enemy_parried", [idx, perfect])
	else:
		_rpc_parry.rpc_id(1, idx, perfect)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_parry(idx: int, perfect: bool) -> void:
	if multiplayer.is_server():
		bcast("_enemy_parried", [idx, perfect])

@rpc("any_peer", "call_remote", "reliable")
func _enemy_parried(idx: int, perfect: bool) -> void:
	if idx < enemies.size():
		enemies[idx].on_parried(perfect)

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
		if Prog.has_skill("l10"):
			lpk.light = minf(Prog.max_light(), lpk.light + 6.0)
	if e.type == "sombra":
		if int(e.get_meta("owner", -1)) == Net.my_id():
			Prog.ecos += int(e.get_meta("amount", 0))
			var sfb := int(Prog.shadow.get("feathers", 0))
			Prog.shadow = {}
			var got := 0
			for _k in sfb:
				if Prog.regrow_wing_feather():
					got += 1
			if got > 0:
				_feather_recovered(got, e.global_position)
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
	# volver a cazar una sala ya limpiada rinde poco: evita subir de nivel solo a base de repetirla
	var farmed: bool = Prog.flags.get("once_" + e.home_room, false)
	var reward: int = int(e.cfg.ecos * (0.3 if farmed else 1.0))
	Prog.add_ecos(reward)
	var res_txt: String = "  x%.2f" % Prog.resonance_mult() if Prog.resonance > 0 else ""
	Fx.text(e.global_position + Vector2(0, 26), "+%d%s" % [int(reward * Prog.ecos_mult()), res_txt], Color(0.6, 0.9, 1.0) if Prog.resonance == 0 else UIKit.GOLD, 9)
	Fx.souls(e.global_position + Vector2(0, -8), local_player(), clampi(int(e.cfg.ecos) / 12, 4, 10) if not e.is_boss else 30)
	if e.is_boss:
		_boss_feats(e)
	if e.is_boss and not asc_fight.is_empty() and asc_fight.boss == e.type:
		if _pantheon_on and not _pantheon_left.is_empty():
			_pantheon_step()
		elif _pantheon_on:
			_end_ascension(true)
			_pantheon_victory()
		else:
			_end_ascension(true)
		return
	if not farmed:
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
		"verdugo", "coloso":
			_on_secret_dead(e)
		"orrun", "vulkaris":
			_on_archon_dead(e)
		"azrahel":
			_on_azrahel_dead(e)

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
	if type == "sombra":
		e.apply_shadow_look(G.look, Prog.wing_feathers)
	Fx.burst(pos, Color(1, 0.3, 0.3), 20, 70.0, 0.6, "fx_soft", 180.0, Vector2.UP, 0.5)

@rpc("any_peer", "call_remote", "reliable")
func spawn_heal_zone(pos: Vector2, dur: float, radius: float, amount: float) -> void:
	## Círculo de curación del Báculo: cada máquina cura a su propio jugador si está dentro
	var hz := HealZone.new()
	hz.position = pos
	hz.dur = dur
	hz.radius = radius
	hz.amount = amount
	hz.world = self
	hz.partner = multiplayer.get_remote_sender_id() != 0
	entities.add_child(hz)

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
	Prog.achieve("first_brasa")
	var lit := 0
	for b in interactables.values():
		if is_instance_valid(b) and b.kind == "brasa" and b.used:
			lit += 1
	Ach.set_goal("brasas", _count_kind("brasa"))
	Ach.set_max("brasas", lit)
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
	Prog.flags.erase("golden_used")
	if diff().get("regrow", false) and Prog.regrow_wing_feather():
		G.toast(G.L(["La Brasa te devuelve una pluma.", "The Ember returns a feather."]), Color(1, 0.9, 0.7))
		send_look()
	lp.refresh_stats(true)
	Audio.sfx("heal")
	Fx.burst(lp.global_position + Vector2(0, -8), Color(1, 0.7, 0.4), 20, 60.0, 1.0, "fx_soft", 180.0, Vector2.UP, 0.4)
	if multiplayer.is_server():
		bcast("_reset_enemies", [true])
	Prog.save_game()
	G.toast(G.T("game_saved"), Color(0.8, 0.8, 0.8))
	menu.open("char", {"brasa": true})

## full = true al descansar (reaparecen todos). Al morir, las salas que ya limpiaste siguen limpias.
@rpc("any_peer", "call_remote", "reliable")
func _reset_enemies(full: bool) -> void:
	unseal_arena()
	secret_fight = ""
	room_lock = ""
	_lock_shown = -1
	_trial_reset()
	_bell_seq.clear()
	_reset_urns()
	if full:
		for k in wflags.keys():
			if str(k).begins_with("clear_"):
				wflags.erase(k)
	# los jefes vuelven a dormir: al entrar otra vez de su sala arranca el combate (sin repetir la cinemática)
	wflags.erase("carcelero_intro")
	wflags.erase("choir_intro")
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
		if e.type in Strata.ARCHONS and wflags.get(e.type + "_dead", false):
			continue
		if not e.is_boss and wflags.get("clear_" + e.home_room, false):
			continue
		e.asc = 0
		e.reset_state()
		e.active = not e.is_boss
		e.modulate = Color.WHITE
	for i in enemies.size():
		enemies[i].idx = i
	_archon_started.clear()
	if not wflags.get("seravel_dead", false):
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
	_count_chests()
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
		G.pickup("icon_feather", "+%d %s" % [d.feathers, G.T("feathers")], Color(0.9, 0.9, 1))
	if d.has("ecos"):
		Prog.add_ecos_flat(int(d.ecos))
		G.pickup("icon_eco", "+%d %s" % [d.ecos, G.T("ecos")], Color(0.6, 0.85, 1))
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
	Prog.flags["known_" + id] = true
	var lines := []
	if id in Strata.ERRANDS:
		_talk_strata(id)
		return
	match id:
		"peregrina":
			if not Prog.flags.get("met_peregrina", false):
				Prog.flags["met_peregrina"] = true
				var lpg := [
					["Sael", ["¿Subes o bajas? En la Espiral es lo mismo: el Juicio te espera en las dos direcciones.", "Going up or down? In the Spiral it's all the same: Judgement awaits you either way."]],
					["Sael", ["Llevo trescientos años en esta escalera. Cada vez que llego arriba, despierto abajo.", "I've been on these stairs for three hundred years. Every time I reach the top, I wake up at the bottom."]],
					["Sael", ["Toma. Una Lágrima no se le niega a nadie que vaya a enfrentarse a ella.", "Here. A Tear is never denied to anyone about to face her."]],
				]
				dialog.play(lpg, func(): Prog.add_item("tear", 1))
			else:
				dialog.play(Lore.lines_for("peregrina", wflags), Callable())
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
						["Tobías", ["Madre Ilse... ¿sigue viva? Dile que no se preocupe por mí. Que aquí abajo se está... tranquilo.", "Mother Ilse... is she still alive? Tell her not to worry about me. That it's... quiet down here."]],
						["Tobías", ["Toma. Eran los guanteletes del penitente de la celda siete. Pegaba a las paredes hasta que dejó de oír a la Voz.", "Here. These were the gauntlets of the penitent in cell seven. He punched the walls until he stopped hearing the Voice."]]]
					dialog.play(lp0, func(): Prog.add_weapon("fists"))
					return
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
					Prog.grant_ability("art")
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
			var l2 := [["Madre Ilse", ["Siéntate, criatura. Tus Lágrimas están turbias. Puedo aclararlas... si me traes las de otros.", "Sit, child. Your Tears are cloudy. I can clear them... if you bring me the tears of others."]],
				["Madre Ilse", ["Y llévate esto. Un báculo no corta, pero cura. Ahí abajo hará falta alguien que cure... aunque sea a sí mismo.", "And take this. A staff doesn't cut, but it heals. Down there someone will need to heal... even if only themselves."]]]
			if Prog.flags.get("met_ilse", false):
				l2 = Lore.lines_for("ilse", wflags)
			elif not Prog.weapons.has("staff"):
				Prog.add_weapon("staff")
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
		hud.big_message(G.T("asc_failed") if not _pantheon_on else G.L(["EL PANTEÓN TE VENCE", "THE PANTHEON DEFEATS YOU"]), Color(0.8, 0.2, 0.25), 2.5, true)
		_pantheon_on = false
		_pantheon_left = []
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
	await _cine_once("seravel")
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

func _cine_once(kind: String) -> void:
	## La presentación del jefe solo se ve una vez: al reintentar se pasa directo a la pelea (con su barra)
	if Prog.flags.get("cine_" + kind, false):
		Audio.sfx("roar", -6.0)
		G.shake(3.0, 0.3)
		await get_tree().create_timer(0.3).timeout
		return
	Prog.flags["cine_" + kind] = true
	await _play_cinematic(kind)

@rpc("any_peer", "call_remote", "reliable")
func _carcelero_intro(idx: int) -> void:
	if wflags.get("carcelero_intro", false):
		return
	wflags["carcelero_intro"] = true
	var e: Enemy = enemies[idx]
	var lp := local_player()
	if lp:
		lp.cutscene = true
	await _cine_once("carcelero")
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
	await _cine_once("choir")
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

const BOSS_SPEAKERS := {"carcelero": ["El Carcelero", "The Jailer"], "choir": ["El Coro", "The Choir"], "seravel": ["Seravel", "Seravel"],
	"custodio": ["El Custodio", "The Warden"]}

## Furia final: al borde de la muerte los jefes principales se desatan, en cualquier dificultad
const FURY_LINES := {
	"carcelero": ["¡Ninguna celda te retendrá! ¡Esta será tu tumba!", "No cell will hold you! This will be your grave!"],
	"choir": ["¡CANTAD! ¡Cantad hasta que se rompa el mundo!", "SING! Sing until the world breaks!"],
	"seravel": ["¡Las Puertas no se abrirán! ¡Antes las arranco con mis manos!", "The Gates will not open! I'll tear them out with my own hands first!"],
	"orrun": ["¡Por cada cría! ¡POR CADA NIDO VACÍO!", "For every chick! FOR EVERY EMPTY NEST!"],
	"vulkaris": ["¡Que arda el yunque! ¡Que se funda todo!", "Let the anvil burn! Let everything melt!"],
	"azrahel": ["¡Nadie se sentará aquí después de mí! ¡NADIE!", "No one will sit here after me! NO ONE!"],
}

@rpc("any_peer", "call_remote", "reliable")
func _boss_fury(idx: int) -> void:
	if idx >= enemies.size():
		return
	var e: Enemy = enemies[idx]
	e.start_fury()
	show_boss_line(FURY_LINES.get(e.type, ["", ""]), e.type)
	hud.big_message(G.L(["FURIA FINAL", "FINAL FURY"]), e.fury_color(), 1.8, true)
	Audio.sfx("roar", 2.0, 0.0)
	Audio.sfx("thunder", -2.0, 0.0)
	G.shake(9.0, 1.0)
	G.flash(Color(e.fury_color(), 0.5), 0.4)
	G.chroma(2.0, 0.8)
	G.shockwave(e.global_position + Vector2(0, -20), 2.0, 0.8)
	Fx.ring(e.global_position + Vector2(0, -20), 10.0, 200.0, e.fury_color(), 1.0, 8.0)
	Fx.burst(e.global_position + Vector2(0, -24), e.fury_color(), 70, 220.0, 1.3, "fx_feather", 180.0, Vector2.UP, 1.5, false, Vector2(0, 40))

@rpc("any_peer", "call_remote", "reliable")
func _boss_cataclysm(idx: int, tpos: Vector2, seed: int) -> void:
	if idx < enemies.size():
		enemies[idx].play_cataclysm(tpos, seed)

func show_boss_line(line: Array, who := "") -> void:
	if who == "" and active_boss != null and is_instance_valid(active_boss):
		who = active_boss.type
	var sp: String = G.L(BOSS_SPEAKERS[who]) if BOSS_SPEAKERS.has(who) else ""
	hud.subtitle(sp, G.L(line), 3.0, Color(1, 0.86, 0.8))

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
		_refresh_rifts()
		hud.end_card(G.T("demo_end_title"), G.T("demo_end_body") % Prog.route_name(), false)
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
	hud.death_screen(Prog.wing_feathers)
	G.slowmo("death", 0.3, 1.2)
	Prog.deaths += 1
	if active_boss and is_instance_valid(active_boss):
		Prog.boss_deaths[active_boss.type] = int(Prog.boss_deaths.get(active_boss.type, 0)) + 1
	# la muerte arranca una pluma (y se ve en tus alas)
	var wc := Look.color_of(G.look, "wing")
	Fx.burst(p.global_position + Vector2(0, -12), wc, 28, 160.0, 1.8, "fx_feather", 180.0, Vector2.UP, 1.3, false, Vector2(0, 45))
	var had := Prog.wing_feathers
	if Prog.flags.get("golden_feather", false) and not Prog.flags.get("golden_used", false):
		# Pluma Áurea (Panteón): la primera caída tras descansar no arranca ninguna pluma
		Prog.flags["golden_used"] = true
		had = 0
		get_tree().create_timer(1.5).timeout.connect(G.toast.bind(G.L(["La Pluma Áurea te protege: no pierdes ninguna pluma.", "The Golden Feather shields you: no feather is lost."]), UIKit.GOLD))
	else:
		Prog.lose_wing_feather()
	if Prog.wing_feathers <= 3:
		Prog.achieve("featherless")
	if had > 0:
		get_tree().create_timer(1.5).timeout.connect(_feather_torn_msg)
	# Ecos: si ya había Ecos sin recuperar, se convierten en tu Sombra
	var shadow_new := false
	if Prog.dropped_ecos.has("amount") and (int(Prog.dropped_ecos.amount) > 0 or int(Prog.dropped_ecos.get("feather", 0)) > 0):
		if Prog.shadow.is_empty():
			Prog.shadow = {"amount": int(Prog.dropped_ecos.amount), "pos": Prog.dropped_ecos.pos}
		else:
			Prog.shadow.amount = int(Prog.shadow.amount) + int(Prog.dropped_ecos.amount)
		Prog.shadow["feathers"] = int(Prog.shadow.get("feathers", 0)) + int(Prog.dropped_ecos.get("feather", 0))
		Prog.dropped_ecos = {}
		Prog.shadow["new"] = true
		shadow_new = true
		if interactables.has("ecosdrop"):
			interactables["ecosdrop"].queue_free()
			interactables.erase("ecosdrop")
	# la pluma arrancada cae junto a tus Ecos: recógelos y la recuperas
	var torn := 1 if had > 0 else 0
	var keep := int(Prog.ecos * diff().keep)
	if Prog.ecos - keep > 0 or torn > 0:
		Prog.dropped_ecos = {"amount": Prog.ecos - keep, "pos": [p.global_position.x, p.global_position.y], "feather": torn}
		if Prog.ecos - keep > 0:
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
			bcast("_reset_enemies", [false])
		else:
			_rpc_reset_request.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_reset_request() -> void:
	if not multiplayer.is_server():
		return
	for q in players.values():
		if q.is_alive():
			return
	bcast("_reset_enemies", [false])

# ====================================================================== intro
func _play_intro() -> void:
	var lp := local_player()
	var with_prologue: bool = G.get_meta("prologue", false)
	if with_prologue:
		lp.respawn_at(tile_pos(17, 19))
		camera.position = lp.global_position
		Prog.flags["seen_prologo"] = true
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
		if with_prologue:
			G.set_meta("prologue", false)
			hud.show_area(G.L(["PRÓLOGO", "PROLOGUE"]), G.T("area_prologo"))
			var pr := preload("res://scripts/world/prologue.gd").new()
			pr.world = self
			_prologue = pr
			add_child(pr)
		else:
			hud.show_area(G.T("stratum1"), G.T("area_sanct"))
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


# ====================================================================== logros: contadores del mundo
var _fight_boss: Enemy = null
var _fight_hits := 0
var _fight_flasks := 0

func _track_fight() -> void:
	if active_boss != _fight_boss:
		_fight_boss = active_boss
		_fight_hits = 0
		_fight_flasks = 0

func note_player_hit() -> void:
	if active_boss:
		_fight_hits += 1

func note_flask() -> void:
	if active_boss:
		_fight_flasks += 1

func _count_kind(kind: String) -> int:
	var n := 0
	for it in interactables.values():
		if is_instance_valid(it) and it.kind == kind:
			n += 1
	return n

func _count_chests() -> void:
	var tot := 0
	var got := 0
	for it in interactables.values():
		if is_instance_valid(it) and it.kind == "chest":
			tot += 1
			if it.used:
				got += 1
	Ach.set_goal("chests", tot + (TRIALS.size() - _count_trial_chests()))
	Ach.set_max("chests", got)

func _count_trial_chests() -> int:
	var n := 0
	for id in TRIALS:
		if interactables.has("chest_trial_" + id):
			n += 1
	return n

func _count_lore() -> void:
	var tot := 0
	var got := 0
	for it in interactables.values():
		if is_instance_valid(it) and it.kind == "lore":
			tot += 1
			if Prog.flags.get("read_" + it.id, false):
				got += 1
	Ach.set_goal("lore", tot)
	Ach.set_max("lore", got)

func _boss_feats(e: Enemy) -> void:
	## logros al caer un jefe: sin golpes, sin Lágrimas, alas intactas, dificultad máxima, cooperativo...
	var lp := local_player()
	if lp == null or lp.global_position.distance_to(e.global_position) > 520.0:
		return
	var main := e.type in ["carcelero", "choir", "seravel", "orrun", "vulkaris", "azrahel"]
	var secret := e.type in ["verdugo", "coloso"]
	if _fight_boss == e and _fight_hits == 0 and lp.is_alive():
		if main:
			Prog.achieve("untouched")
	if not main:
		return
	var n := 0
	var hard := 0
	if world_difficulty >= 3:
		Prog.flags["hard_" + e.type] = true
	for b in ["carcelero", "choir", "seravel"]:
		if b == e.type or wflags.get(b + "_dead", false):
			n += 1
	for b3 in ["seravel", "orrun", "vulkaris", "azrahel"]:
		if Prog.flags.get("hard_" + b3, false):
			hard += 1
	var big := 0
	for b4 in ["seravel", "orrun", "vulkaris", "azrahel"]:
		if b4 == e.type or wflags.get(b4 + "_dead", false):
			big += 1
	Ach.set_max("great_archons", big)
	Ach.set_max("archons", n)
	Ach.set_max("hard_archons", hard)
	Ach.set_max("spared", Prog.spared.size())
	if Net.is_online() and players.size() >= 2:
		Prog.achieve("coop_boss")
	if e.type == "seravel" and asc_fight.is_empty() and Prog.deaths == 0:
		Prog.achieve("deathless1")

# ====================================================================== batallas secretas
const SECRET_ARENAS := {"verdugo": ["cadalso", "luz"], "coloso": ["cornisa", "luz"]}
var secret_fight := ""
var _pantheon_on := false
var _pantheon_left: Array = []

func _enemy_of(type: String) -> Enemy:
	for e in enemies:
		if e.type == type:
			return e
	return null

@rpc("any_peer", "call_remote", "reliable")
func _open_cadalso(fx: bool) -> void:
	## los cuatro ecos del pasado abren la reja de luz bajo la Capilla
	if wflags.get("trial_cadalso", false):
		return
	wflags["trial_cadalso"] = true
	Prog.flags["trial_cadalso"] = true
	_refresh_locks(not fx)
	if fx:
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			hud.big_message(G.L(["ALGO SE ABRE BAJO LA CAPILLA", "SOMETHING OPENS BENEATH THE CHAPEL"]), Color(1, 0.4, 0.45), 3.0)
			Audio.sfx("gate", -4.0))

func _build_secret_rooms() -> void:
	# --- El Cadalso: tajo, hoja clavada, velas rojas y cadenas
	_add_inter("altar", "altar_cadalso", tile_pos(84.5, 88.6), {"style": "block"})
	for cp in [Vector2(79, 87), Vector2(90, 87), Vector2(79, 93.5), Vector2(90, 93.5), Vector2(82, 87), Vector2(87, 87)]:
		_prop("candle", tile_pos(cp.x, cp.y), 4, int(cp.x) % 4, 0.0, Color(1, 0.35, 0.4), 1.0)
	for hp in [Vector2(80, 89), Vector2(89, 89), Vector2(84.5, 92)]:
		var hc := Depth3D.HangingChain.new()
		hc.position = tile_pos(hp.x, hp.y)
		hc.low_h = 34.0 + fmod(hp.x * 5.0, 20.0)
		add_child(hc)
	var amb := RoomAmbience.new()
	amb.rect = Rect2(77 * TS, 86 * TS, 15 * TS, 9 * TS)
	amb.kind = "spores"
	add_child(amb)
	# --- La Cornisa del Coloso: tras un muro agrietado al norte del Mirador
	var bw := BreakableWall.new()
	bw.id = "cornisa"
	bw.world = self
	bw.position = tile_pos(32, 80)
	entities.add_child(bw)
	breakables["cornisa"] = bw
	_add_inter("altar", "altar_cornisa", tile_pos(23, 64.6), {"style": "horn"})
	_add_inter("lore", "lore_cornisa", tile_pos(30.5, 64.4), {"lines": [["lore_title", ["«No es una estatua. Nunca lo fue. Sostuvo la Espiral sobre los hombros hasta que el Arquitecto le dio la orden de dormir.»", "\"It is no statue. It never was. It held the Spiral upon its shoulders until the Architect ordered it to sleep.\""]],
		["lore_title", ["«Solo despertará con el cuerno, y solo para quien haya cruzado las Puertas.»", "\"It wakes only to the horn, and only for one who has passed the Gates.\""]]]})
	for rp in [Vector2(15, 66), Vector2(30, 74), Vector2(17, 74.5), Vector2(27, 66.5)]:
		_prop("rubble", tile_pos(rp.x, rp.y), 3, int(rp.x) % 3)
	for cp in [Vector2(14.5, 64.5), Vector2(32.5, 64.5), Vector2(32.5, 75.5)]:
		var col := Depth3D.Column.new()
		col.position = tile_pos(cp.x, cp.y)
		col.height = 40.0 + fmod(cp.y * 7.0, 24.0)
		col.radius = 5.0
		entities.add_child(col)
	_prop("broken_wing", tile_pos(20, 73.5))
	_prop("statue", tile_pos(28.5, 63.6)).flip_h = true
	var stars2 := ShootingStars.new()
	stars2.position = tile_pos(6, 66)
	add_child(stars2)
	var amb2 := RoomAmbience.new()
	amb2.rect = Rect2(13 * TS, 63 * TS, 21 * TS, 14 * TS)
	amb2.kind = "mist"
	add_child(amb2)
	for tp in [Vector2(16, 62.7), Vector2(31, 62.7)]:
		var wt := WallTorch.new()
		wt.position = tile_pos(tp.x, tp.y)
		wt.col = Color(0.55, 0.9, 1.0)
		entities.add_child(wt)

func _altar(it: Interactable) -> void:
	var lp := local_player()
	if lp == null or active_boss != null or secret_fight != "":
		return
	match str(it.data.get("style", "")):
		"block":
			var lines := []
			if not Prog.flags.get("sb_verdugo", false):
				lines = [["", ["Un tajo de madera negra. La hoja clavada en él lleva un nombre grabado... el tuyo.", "A block of black wood. The blade driven into it bears a name... yours."]],
					[G.L(["El Verdugo", "The Executioner"]), ["Mil años esperando a que bajaras. Pediste olvidar y te lo concedieron.", "A thousand years waiting for you to come down. You asked to forget, and it was granted."]],
					[G.L(["El Verdugo", "The Executioner"]), ["Yo no olvidé. Levántate y mírame: esto es lo que fuiste.", "I did not forget. Rise and look at me: this is what you were."]]]
			else:
				lines = [["", ["La hoja vuelve a estar clavada en el tajo. Él te espera de rodillas.", "The blade is driven into the block once more. He waits for you on his knees."]],
					[G.L(["El Verdugo", "The Executioner"]), ["¿Otra vez? Bien. Nunca te cansaste de esto.", "Again? Good. You never tired of this."]]]
			dialog.play(lines, _request_secret.bind("verdugo"))
		"horn":
			if not wflags.get("seravel_dead", false):
				dialog.play([["", ["Un cuerno de hueso, más grande que tú, encadenado a la roca. Está frío.", "A bone horn, larger than you, chained to the rock. It is cold."]],
					["", ["Algo en el Círculo de las Puertas aún retiene su eco. No responderá todavía.", "Something in the Circle of the Gates still holds its echo. It will not answer yet."]]], Callable())
				return
			var l2 := [["", ["El cuerno vibra contra tu pecho. Al otro lado de la cornisa, algo enorme respira.", "The horn hums against your chest. Beyond the ledge, something enormous breathes."]]]
			if Prog.flags.get("sb_coloso", false):
				l2 = [["", ["El cuerno guarda aún el eco del Coloso. ¿Despertarlo otra vez?", "The horn still holds the Colossus's echo. Wake it once more?"]]]
			dialog.play(l2, _request_secret.bind("coloso"))

func _request_secret(kind: String) -> void:
	if multiplayer.is_server():
		_server_secret(kind)
	else:
		_rpc_request_secret.rpc_id(1, kind)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_secret(kind: String) -> void:
	if multiplayer.is_server():
		_server_secret(kind)

func _server_secret(kind: String) -> void:
	if active_boss != null or secret_fight != "" or not asc_fight.is_empty():
		return
	bcast("_secret_start", [kind])

@rpc("any_peer", "call_remote", "reliable")
func _secret_start(kind: String) -> void:
	var e := _enemy_of(kind)
	if e == null:
		return
	secret_fight = kind
	e.asc = 0
	e.reset_state()
	e.call("summon")
	var lp := local_player()
	seal_arena(SECRET_ARENAS[kind][0], SECRET_ARENAS[kind][1])
	var retry: bool = Prog.flags.get("cine_" + kind, false)
	Prog.flags["cine_" + kind] = true
	if lp:
		lp.cutscene = true
	hud.letterbox(true)
	# la barra del jefe se ve desde el principio, también en cada reintento
	hud.show_boss(e)
	Audio.play_music("shadow" if kind == "verdugo" else "boss2", 0.6)
	if kind == "verdugo":
		_cam_focus = e.global_position + Vector2(0, -16)
		Fx.burst(e.global_position + Vector2(0, -10), Color(1, 0.35, 0.4), 40, 120.0, 1.2, "fx_feather", 180.0, Vector2.UP, 1.2, false, Vector2(0, 30))
		G.flash(Color(1, 0.3, 0.35, 0.35), 0.4)
		Audio.sfx("shadow_rise", 0.0, 0.0)
		if not retry:
			await get_tree().create_timer(1.4).timeout
			show_boss_line(["Empuña lo que fuiste... o vuelve a olvidarlo.", "Wield what you were... or forget it again."], "verdugo")
			await get_tree().create_timer(1.6).timeout
		else:
			await get_tree().create_timer(0.4).timeout
	else:
		_cam_focus = Vector2(BossColoso.ARENA.position.x + 40.0, BossColoso.ANCHOR.y - 80.0)
		e.perform("rise", e.global_position, 0)
		await get_tree().create_timer(4.6).timeout
	_cam_focus = null
	hud.letterbox(false)
	if lp:
		lp.cutscene = false
	if not is_instance_valid(e) or not e.is_alive() or secret_fight != kind:
		return
	e.active = true
	e.state = "chase"
	e.cooldown = 1.0
	active_boss = e
	hud.show_boss(e)
	G.shockwave(e.global_position + Vector2(0, -20), 1.4, 0.5)

func _on_secret_dead(e: Enemy) -> void:
	unseal_arena()
	secret_fight = ""
	active_boss = null
	hud.hide_boss()
	G.slowmo("kill", 0.3, 1.2)
	Audio.play_music("victory", 0.4)
	wflags["sb_" + e.type] = true
	var first = not Prog.flags.get("sb_reward_" + e.type, false)
	Prog.flags["sb_" + e.type] = true
	Prog.flags["sb_reward_" + e.type] = true
	Prog.achieve("sb_" + e.type)
	var lp := local_player()
	if _fight_boss == e and _fight_hits == 0 and lp and lp.is_alive():
		Prog.achieve("sb_legend")
	hud.big_message(G.L(["BATALLA SECRETA SUPERADA", "SECRET BATTLE WON"]), UIKit.GOLD, 3.2, true)
	if first:
		get_tree().create_timer(3.0).timeout.connect(_secret_reward.bind(e.type))
	if multiplayer.is_server():
		Prog.save_game()

func _secret_reward(type: String) -> void:
	match type:
		"verdugo":
			Prog.add_weapon("verdugo")
			dialog.play([[G.L(["El Verdugo", "The Executioner"]), ["Concedido. Llévala. Y esta vez... recuerda por qué la empuñas.", "Granted. Take it. And this time... remember why you wield it."]]], Callable())
		"coloso":
			Prog.flags["storm_wing"] = true
			Prog.flags["colossus_heart"] = true
			Prog.flasks_max += 1
			G.pickup("icon_quest", G.L(["HABILIDAD: ALA DE TORMENTA", "ABILITY: STORM WING"]), Color(0.6, 0.95, 1.0))
			get_tree().create_timer(1.6).timeout.connect(G.pickup.bind("icon_quest", G.L(["MEJORA: CORAZÓN DEL COLOSO (+15% vida, +1 Lágrima)", "UPGRADE: COLOSSUS HEART (+15% health, +1 Tear)"]), Color(0.6, 0.95, 1.0)))
			get_tree().create_timer(3.2).timeout.connect(G.toast.bind(G.L(["Ala de Tormenta: tu esquiva invoca rayos que hieren a los enemigos.", "Storm Wing: your dash calls down lightning that strikes enemies."]), Color(0.6, 0.95, 1.0)))
			var lp := local_player()
			if lp:
				lp.refresh_stats(true)
	Prog.changed.emit()
	if multiplayer.is_server():
		Prog.save_game()

# ---------------------------------------------------------------------- Panteón de los Arcontes (Sor Velaria)
func pantheon_open() -> bool:
	for b in ["carcelero", "choir", "seravel"]:
		if not Prog.flags.get(b + "_dead", false):
			return false
	return not Prog.ascension.is_empty()

func start_pantheon() -> void:
	if multiplayer.is_server():
		if active_boss == null and asc_fight.is_empty() and secret_fight == "":
			bcast("_pantheon_begin", [])
	else:
		_rpc_pantheon.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_pantheon() -> void:
	start_pantheon()

@rpc("any_peer", "call_remote", "reliable")
func _pantheon_begin() -> void:
	_pantheon_on = true
	_pantheon_left = ["carcelero", "choir", "seravel"]
	hud.big_message(G.L(["PANTEÓN DE LOS ARCONTES", "PANTHEON OF THE ARCHONS"]), UIKit.GOLD, 2.6, true)
	Audio.sfx("roar", -6.0)
	await get_tree().create_timer(2.2).timeout
	_pantheon_next()

func _pantheon_next() -> void:
	if _pantheon_left.is_empty():
		return
	var b: String = _pantheon_left.pop_front()
	_ascension_start(b, 2)

func _pantheon_step() -> void:
	unseal_arena()
	hud.hide_boss()
	active_boss = null
	asc_fight = {}
	var left := _pantheon_left.size()
	hud.big_message(G.L(["PRUEBA SUPERADA  ·  QUEDAN %d", "TRIAL CLEARED  ·  %d LEFT"]) % left, UIKit.GOLD, 2.4)
	var lp := local_player()
	if lp and lp.is_alive():
		lp.flasks = mini(lp.flasks + 1, Prog.flask_count())
		G.toast(G.L(["El Panteón te concede una Lágrima.", "The Pantheon grants you a Tear."]), Color(1, 0.6, 0.5))
	await get_tree().create_timer(3.4).timeout
	if _pantheon_on:
		_pantheon_next()

func _pantheon_victory() -> void:
	_pantheon_on = false
	var first = not Prog.flags.get("pantheon_won", false)
	Prog.flags["pantheon_won"] = true
	Prog.achieve("sb_panteon")
	hud.big_message(G.L(["EL PANTEÓN SE INCLINA ANTE TI", "THE PANTHEON BOWS TO YOU"]), UIKit.GOLD, 3.4, true)
	if first:
		Prog.flags["golden_feather"] = true
		Prog.add_ecos(6000)
		get_tree().create_timer(2.0).timeout.connect(G.pickup.bind("icon_quest", G.L(["MEJORA: PLUMA ÁUREA", "UPGRADE: GOLDEN FEATHER"]), UIKit.GOLD))
		get_tree().create_timer(3.6).timeout.connect(G.toast.bind(G.L(["Pluma Áurea: la primera caída tras cada descanso no te arranca ninguna pluma.", "Golden Feather: the first fall after each rest tears no feather."]), UIKit.GOLD))


# ====================================================================== cooperativo: compañero, marcas y viaje
func partner() -> Player:
	for pid in players:
		if pid != Net.my_id() and is_instance_valid(players[pid]):
			return players[pid]
	return null

var pings := {}   # peer -> PingMarker

@rpc("any_peer", "call_remote", "reliable")
func _ping(by: int, pos: Vector2) -> void:
	## Marca para el compañero (tecla G): sobre un enemigo, un objeto o el suelo
	var kind := "go"
	var label := G.L(["¡POR AQUÍ!", "THIS WAY!"])
	for e in enemies_alive():
		if e.global_position.distance_to(pos) < 26.0 + e.body_radius:
			kind = "enemy"
			label = G.L(["¡ENEMIGO!", "ENEMY!"])
			pos = e.global_position
			break
	if kind == "go":
		for it in interactables.values():
			if is_instance_valid(it) and not it.used and it.global_position.distance_to(pos) < 26.0:
				kind = "item"
				label = G.L(["¡MIRA ESTO!", "LOOK HERE!"])
				pos = it.global_position
				break
	if pings.has(by) and is_instance_valid(pings[by]):
		pings[by].queue_free()
	var pm := PingMarker.new()
	pm.position = pos
	pm.kind = kind
	pm.label = label
	var who: Player = players.get(by)
	pm.col = Color(1, 0.85, 0.4) if who == null or who.variant == 1 else Color(0.5, 0.9, 1.0)
	pm.mine = by == Net.my_id()
	fx_layer.add_child(pm)
	pings[by] = pm
	Audio.sfx("ui_ok", -2.0, 0.0)
	Audio.sfx("bell_0" if kind != "enemy" else "enemy_shot", -10.0, 0.0)
	if by == Net.my_id() and Net.is_online():
		Ach.add("pings")

func travel_to_partner() -> void:
	var mate := partner()
	var lp := local_player()
	if mate == null or lp == null or not mate.is_alive():
		return
	hud.fade_to(1.0, 0.35)
	await get_tree().create_timer(0.4).timeout
	lp.respawn_at(mate.global_position + Vector2(-16, 6))
	hud.fade_to(0.0, 0.5)
	Fx.burst(lp.global_position + Vector2(0, -10), Color(1, 0.8, 0.5), 30, 90.0, 0.9, "fx_feather", 180.0, Vector2.UP, 1.0, false, Vector2(0, -20))
	Fx.ring(lp.global_position + Vector2(0, -6), 4.0, 40.0, Color(1, 0.85, 0.5), 0.5, 3.0)
	Audio.sfx("heal")
	G.toast(G.L(["Las Brasas te llevan junto a tu compañero.", "The Embers carry you to your partner."]), Color(1, 0.8, 0.5))

func on_partner_revived(by_me: bool) -> void:
	## Alas Unidas: al revivir, los dos ganan +20% de daño durante 10 s
	Prog.buffs["united"] = 10.0
	Prog.changed.emit()
	var lp := local_player()
	if lp:
		Fx.ring(lp.global_position + Vector2(0, -8), 4.0, 50.0, Color(1, 0.9, 0.6), 0.6, 4.0)
		Fx.text(lp.global_position + Vector2(0, -26), G.L(["ALAS UNIDAS", "UNITED WINGS"]), Color(1, 0.9, 0.6), 10)
	if by_me:
		G.toast(G.L(["Alas Unidas: +20% de daño para los dos durante 10 s.", "United Wings: +20% damage for both for 10 s."]), Color(1, 0.9, 0.6))

class PingMarker extends Node2D:
	## Baliza de una marca: columna de luz, rombo que flota, anillos y un rótulo
	var kind := "go"
	var label := ""
	var col := Color(1, 0.85, 0.4)
	var mine := false
	var t := 0.0
	func _ready() -> void:
		z_index = 40
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = col
		l.texture_scale = 0.8
		l.energy = 0.9
		add_child(l)
	func _process(delta: float) -> void:
		t += delta
		if t > 7.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := clampf(7.0 - t, 0.0, 1.0)
		var c := col if kind != "enemy" else Color(1, 0.35, 0.35)
		# columna de luz
		draw_rect(Rect2(Vector2(-2, -70), Vector2(4, 70)), Color(c, 0.18 * a))
		draw_rect(Rect2(Vector2(-1, -70), Vector2(2, 70)), Color(c, 0.35 * a))
		# anillos en el suelo
		for i in 2:
			var k := fmod(t * 0.9 + i * 0.5, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 4.0 + k * 22.0, 0, TAU, 24, Color(c, (1.0 - k) * a), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# rombo que flota
		var y := -26.0 + sin(t * 4.0) * 3.0
		UIKit.diamond(self, Vector2(0, y), 7.0, Color(UIKit.INK, a))
		UIKit.diamond(self, Vector2(0, y), 5.0, Color(c, a))
		if kind == "enemy":
			draw_line(Vector2(-3, y - 3), Vector2(3, y + 3), Color(UIKit.INK, a), 1.5)
			draw_line(Vector2(3, y - 3), Vector2(-3, y + 3), Color(UIKit.INK, a), 1.5)
		else:
			draw_rect(Rect2(Vector2(-1, y - 2), Vector2(2, 2)), Color(UIKit.INK, a))
		var f := UIKit.font("head")
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		f.draw_string_outline(get_canvas_item(), Vector2(-w / 2.0, y - 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(UIKit.INK, a))
		f.draw_string(get_canvas_item(), Vector2(-w / 2.0, y - 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(c, a))


# ====================================================================== Estratos II-IV (juego base completo)
var _archon_started := {}

func cur_stratum() -> int:
	var lp := local_player()
	if lp == null:
		return 1
	return Strata.stratum_of_room(room_at(lp.global_position))

func _build_cradle() -> void:
	## La Cuna de Ceniza: sala de entrenamiento del prólogo
	for bp in [Vector2(8, 11), Vector2(25, 11), Vector2(8, 21), Vector2(25, 21)]:
		_prop("brazier", tile_pos(bp.x, bp.y), 4, 0, 6.0, Color(1, 0.65, 0.3), 1.6).set_meta("anim", true)
	for sp in [Vector2(12, 9.2), Vector2(22, 9.2)]:
		_prop("statue", tile_pos(sp.x, sp.y), 1, 0, 5.0)
	for tp in [Vector2(9, 7.7), Vector2(16, 7.7), Vector2(18, 7.7), Vector2(25, 7.7)]:
		var wt := WallTorch.new()
		wt.position = tile_pos(tp.x, tp.y)
		wt.col = Color(1, 0.75, 0.4)
		entities.add_child(wt)

func _build_strata() -> void:
	_build_cradle()
	for b in Strata.BRASAS:
		_add_inter("brasa", b[0], tile_pos(b[1].x, b[1].y))
	for c in Strata.CHESTS:
		_add_inter("chest", c[0], tile_pos(c[1].x, c[1].y), c[2])
	for l in Strata.LORE:
		var ll := []
		for ln in l[2]:
			ll.append(["lore_title", ln])
		_add_inter("lore", l[0], tile_pos(l[1].x, l[1].y), {"lines": ll})
	for n in Strata.NPCS:
		_add_inter("npc", n[0], tile_pos(n[1].x, n[1].y), n[2])
	for e in Strata.ERRAND_ITEMS:
		_add_inter("pickup", e[0], tile_pos(e[1].x, e[1].y), {"icon": e[3], "quest": e[2]})
	_build_strata_decor()

func _build_strata_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	# --- Bosque: árboles muertos llenos de plumas, nidos, niebla y esporas
	for r in ROOMS:
		var st := Strata.stratum_of_room(r.id)
		if st == 1 or str(r.id).contains("link") or str(r.id).ends_with("arena"):
			continue
		var rc := _rect_of(r)
		var n := int(rc.size.x * rc.size.y / 70)
		for k in n:
			var x := rng.randi_range(rc.position.x + 1, rc.end.x - 2)
			var y := rng.randi_range(rc.position.y + 1, rc.end.y - 2)
			if not (_floor_at(x, y) and _floor_at(x, y + 1)):
				continue
			var p := tile_pos(x + rng.randf_range(-0.3, 0.3), y + 0.5)
			match st:
				2:
					if rng.randf() < 0.55:
						_prop("tree_dead", p, 1, 0, 5.0).flip_h = rng.randf() < 0.5
					else:
						_prop("nest", p)
				3:
					var roll := rng.randf()
					if roll < 0.35:
						_prop("crucible", p, 2, 1, 6.0, Color(1, 0.5, 0.2), 1.3)
					elif roll < 0.6:
						_prop("anvil", p, 1, 0, 6.0)
					elif roll < 0.8:
						_prop("halo_mold", p, 1, 0, 0.0, Color(1, 0.6, 0.2), 0.8)
					else:
						_prop("brazier", p, 4, rng.randi_range(0, 3), 6.0, Color(1, 0.55, 0.2), 1.6).set_meta("anim", true)
				4:
					var roll2 := rng.randf()
					if roll2 < 0.4:
						_prop("rosebush", p)
					elif roll2 < 0.65:
						_prop("pillar", p, 1, 0, 6.0)
					elif roll2 < 0.85:
						_prop("statue", p, 1, 0, 5.0).flip_h = rng.randf() < 0.5
					else:
						_prop("banner", p, 2, rng.randi_range(0, 1))
	for spec in [["b_raices", "spores"], ["b_charca", "mist"], ["b_copas", "spores"], ["b_colmena", "gold"], ["f_escoria", "embers"], ["f_hornos", "embers"], ["f_cadena", "embers"], ["f_tesoro", "gold"],
			["t_mazmorra", "mist"], ["t_cripta", "mist"], ["t_oratorio", "gold"], ["t_tesoreria", "gold"], ["v_osario", "mist"], ["v_archivo", "gold"],
			["b_sendero", "spores"], ["b_arboleda", "mist"], ["b_cienaga", "mist"], ["b_nidos", "gold"], ["b_arena", "spores"],
			["f_crisoles", "embers"], ["f_fragua", "embers"], ["f_moldes", "embers"], ["f_arena", "embers"], ["f_biblio", "gold"],
			["t_jardin", "gold"], ["t_corte", "gold"], ["t_galeria", "notes"], ["t_escalera", "gold"], ["t_arena", "spores"]]:
		for r2 in ROOMS:
			if r2.id == spec[0]:
				var amb := RoomAmbience.new()
				amb.rect = Rect2(Vector2(_rect_of(r2).position) * TS, Vector2(_rect_of(r2).size) * TS)
				amb.kind = spec[1]
				add_child(amb)
	for sp in [Vector2(110.5, 58), Vector2(204.5, 52), Vector2(336, 58)]:
		var ls := LightShafts.new()
		ls.position = tile_pos(sp.x, sp.y)
		ls.col = Color(1, 0.9, 0.65)
		add_child(ls)
	for cp in [Vector2(302, 54), Vector2(371, 55), Vector2(336.5, 35), Vector2(204.5, 54)]:
		var ch := Depth3D.Chandelier.new()
		ch.position = tile_pos(cp.x, cp.y)
		add_child(ch)
	for tp in [Vector2(226, 51.7), Vector2(234, 51.7), Vector2(246, 51.7), Vector2(254, 51.7), Vector2(228, 25.7), Vector2(252, 25.7), Vector2(236, 77.7), Vector2(244, 77.7)]:
		var wt := WallTorch.new()
		wt.position = tile_pos(tp.x, tp.y)
		wt.col = Color(1, 0.55, 0.2)
		entities.add_child(wt)
	for tp2 in [Vector2(325, 29.7), Vector2(347, 29.7), Vector2(298, 43.7), Vector2(306, 43.7), Vector2(366, 45.7), Vector2(376, 45.7), Vector2(332, 79.7), Vector2(340, 79.7)]:
		var wt2 := WallTorch.new()
		wt2.position = tile_pos(tp2.x, tp2.y)
		wt2.col = Color(0.8, 0.55, 1.0)
		entities.add_child(wt2)
	# el Trono Vacío al fondo de la sala del Rey
	_prop("throne", tile_pos(336, 3.2), 1, 0, 14.0, Color(0.7, 0.45, 1.0), 2.0)
	for cp2 in [Vector2(328, 5), Vector2(344, 5), Vector2(328, 17), Vector2(344, 17)]:
		var col := Depth3D.Column.new()
		col.position = tile_pos(cp2.x, cp2.y)
		col.height = 80.0
		col.radius = 6.0
		entities.add_child(col)
	for fp in [Vector2(108, 58), Vector2(114, 64), Vector2(326, 60), Vector2(346, 64), Vector2(320, 65)]:
		var fpc := FlowerPatch.new()
		fpc.position = tile_pos(fp.x, fp.y)
		fpc.count = 10
		fpc.petal = Color(0.95, 0.9, 1.0) if fp.x < 200 else Color(1, 0.85, 0.35)
		entities.add_child(fpc)
	_fireflies(Rect2(104 * TS, 54 * TS, 14 * TS, 14 * TS))
	_fireflies(Rect2(318 * TS, 54 * TS, 36 * TS, 14 * TS))

func _refresh_rifts() -> void:
	for boss in Strata.RIFTS:
		var id: String = "rift_" + boss
		if wflags.get(boss + "_dead", false) and not interactables.has(id):
			var rd: Array = Strata.RIFTS[boss]
			_add_inter("rift", id, tile_pos(rd[0].x, rd[0].y), {"to": rd[1]})

func _rift(it: Interactable) -> void:
	var to: int = int(it.data.get("to", 2))
	var lines := [["", [("Una grieta en la Espiral, abierta hacia abajo. Del otro lado llega un aire que huele a %s." % ["", "", "plumas mojadas", "hierro fundido", "rosas sin olor"][to]),
		("A rift in the Spiral, opening downwards. From beyond comes air that smells of %s." % ["", "", "wet feathers", "molten iron", "scentless roses"][to])]]]
	dialog.play(lines, _request_descend.bind(to))

func _request_descend(to: int) -> void:
	if multiplayer.is_server():
		bcast("_descend", [to])
	else:
		_rpc_descend.rpc_id(1, to)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_descend(to: int) -> void:
	if multiplayer.is_server():
		bcast("_descend", [to])

@rpc("any_peer", "call_remote", "reliable")
func _descend(to: int) -> void:
	var lp := local_player()
	if lp == null:
		return
	lp.cutscene = true
	Audio.sfx("shadow_rise", -2.0, 0.0)
	G.flash(Color(0.6, 0.4, 1.0, 0.4), 0.4)
	hud.fade_to(1.0, 0.9)
	await get_tree().create_timer(1.0).timeout
	var arr: Vector2 = Strata.ARRIVAL[to]
	lp.respawn_at(tile_pos(arr.x + (0.0 if lp.variant == 1 else 1.2), arr.y))
	camera.position = lp.global_position
	_area = ""
	var bid: String = Strata.ARRIVAL_BRASA[to]
	if not wflags.get("brasa_" + bid, false):
		_light_brasa(bid)
	Prog.last_brasa = bid
	var q := "main%d" % to
	if Prog.QUESTS.has(q) and not Prog.quests.has(q):
		Prog.start_quest(q)
	Prog.achieve("s%d_enter" % to)
	await get_tree().create_timer(0.4).timeout
	hud.fade_to(0.0, 1.2)
	hud.show_area(G.L(Strata.STRATUM_NAMES[to]), G.T(AREAS.get(room_at(lp.global_position), "")))
	lp.cutscene = false
	if multiplayer.is_server():
		Prog.save_game()

func travel_to_brasa(id: String) -> void:
	var lp := local_player()
	if lp == null or not interactables.has(id):
		return
	hud.fade_to(1.0, 0.4)
	await get_tree().create_timer(0.45).timeout
	lp.respawn_at(_brasa_spawn(id))
	camera.position = lp.global_position
	Prog.last_brasa = id
	_area = ""
	hud.fade_to(0.0, 0.6)
	Fx.burst(lp.global_position + Vector2(0, -10), Color(1, 0.75, 0.4), 30, 90.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.5)
	Audio.sfx("heal")

func lit_brasas() -> Array:
	var out := []
	for id in Strata.BRASA_NAMES:
		if interactables.has(id) and interactables[id].used:
			out.append(id)
	return out

func _check_archons(lp: Player, r: String) -> void:
	if lp == null or not lp.is_alive() or active_boss != null or not asc_fight.is_empty() or secret_fight != "":
		return
	for aid in Strata.ARCHONS:
		var A: Dictionary = Strata.ARCHONS[aid]
		if r == A.room and not wflags.get(aid + "_dead", false) and not _archon_started.has(aid):
			_archon_started[aid] = true
			if multiplayer.is_server():
				bcast("_archon_intro", [aid])
			else:
				_rpc_archon.rpc_id(1, aid)
			return

@rpc("any_peer", "call_remote", "reliable")
func _rpc_archon(aid: String) -> void:
	if multiplayer.is_server() and active_boss == null:
		bcast("_archon_intro", [aid])

@rpc("any_peer", "call_remote", "reliable")
func _archon_intro(aid: String) -> void:
	_archon_started[aid] = true
	var e := _enemy_of(aid)
	if e == null or not e.is_alive():
		return
	var A: Dictionary = Strata.ARCHONS[aid]
	active_boss = e
	e.visible = true
	seal_for(aid)
	var steps: Array = Prog.QUESTS.get(A.quest, {}).get("steps", [])
	if steps.size() >= 2:
		Prog.quest_step(A.quest, steps[steps.size() - 2].id)
	var lp := local_player()
	if Prog.flags.get("cine_" + aid, false):
		# reintento: sin presentación, directo a la pelea
		Audio.sfx("roar", -6.0)
		G.shake(3.0, 0.3)
		e.active = true
		e.state = "chase"
		e.cooldown = 1.0
		hud.show_boss(e)
		Audio.play_music(str(A.music), 0.3)
		return
	Prog.flags["cine_" + aid] = true
	if lp:
		lp.cutscene = true
	hud.letterbox(true)
	_cam_focus = e.global_position + Vector2(0, -30)
	Audio.stop_music(0.6)
	Audio.sfx("roar", 0.0)
	G.shake(5.0, 0.8)
	Fx.light_flash(e.global_position, Strata.AREA_COLORS.get(AREAS.get(A.room, ""), Color.WHITE), 3.0, 2.0, 0.8)
	hud.big_message(G.T("boss_" + aid), Strata.AREA_COLORS.get(AREAS.get(A.room, ""), UIKit.GOLD), 2.6, true)
	await get_tree().create_timer(1.6).timeout
	var lines := []
	for l in A.intro:
		lines.append([l[0], l[1]])
	var go := func() -> void:
		_cam_focus = null
		hud.letterbox(false)
		if lp:
			lp.cutscene = false
		if not is_instance_valid(e) or not e.is_alive():
			return
		e.active = true
		e.state = "chase"
		e.cooldown = 1.0
		hud.show_boss(e)
		Audio.play_music(str(A.music), 0.3)
		G.shockwave(e.global_position + Vector2(0, -20), 1.5, 0.6)
	dialog.play(lines, go, true)

func _on_archon_dead(e: Enemy) -> void:
	var aid := e.type
	var A: Dictionary = Strata.ARCHONS[aid]
	unseal_arena()
	wflags[aid + "_dead"] = true
	Prog.flags[aid + "_dead"] = true
	hud.hide_boss()
	active_boss = null
	G.slowmo("kill", 0.2, 1.5)
	G.flash(Color(1, 1, 1, 0.75), 0.8)
	G.shake(10.0, 1.4)
	Audio.stop_music(0.3)
	Fx.burst(e.global_position + Vector2(0, -24), Strata.AREA_COLORS.get(AREAS.get(A.room, ""), Color.WHITE), 80, 240.0, 1.6, "fx_feather", 180.0, Vector2.UP, 1.5, false, Vector2(0, 30))
	Fx.ring(e.global_position + Vector2(0, -24), 10.0, 220.0, Color(1, 0.9, 0.6), 1.2, 10.0)
	Prog.achieve(aid)
	await get_tree().create_timer(1.2).timeout
	Audio.play_music("victory", 0.1)
	hud.big_message(G.T("archon_defeated"), Color(1, 0.85, 0.45), 4.0)
	Prog.flasks_max += 1
	Prog.skill_points += 1
	G.toast(G.T("flask_up"), Color(1, 0.6, 0.5))
	G.toast(G.L(["+1 Punto de Habilidad", "+1 Skill Point"]), UIKit.GOLD)
	Prog.quest_step(A.quest, "kill_" + aid)
	Prog.add_weapon({"orrun": "astas", "vulkaris": "yunque"}[aid])
	_check_gates(false)
	var lp := local_player()
	if lp:
		lp.refresh_stats(true)
	if multiplayer.is_server():
		Prog.save_game()
	await get_tree().create_timer(3.0).timeout
	var lines := []
	if e.get_meta("spared", false):
		lines.append([str(A.death[0][0]), ["¿Me perdonas? Entonces aún queda algo en ti que el Arquitecto no ha fundido.", "You spare me? Then there's still something in you the Architect hasn't melted down."]])
	for l in A.death:
		lines.append([l[0], l[1]])
	var st: int = int(A.stratum)
	var mem: String = {"orrun": "m5", "vulkaris": "m6"}[aid]
	var done := func() -> void:
		if Prog.unlock_memory(mem):
			await hud.memory_sequence(G.L(Prog.MEMORIES[mem].title), Prog.MEMORIES[mem].lines.map(func(l): return G.L(l)))
		_refresh_rifts()
		hud.end_card(G.L(["ESTRATO %s SUPERADO", "STRATUM %s CLEARED"]) % ["II", "III"][st - 2],
			G.L(["Una grieta se ha abierto donde cayó el Arconte.\nEl descenso continúa: %s.\nTu destino se inclina hacia: %s", "A rift has opened where the Archon fell.\nThe descent continues: %s.\nYour fate leans towards: %s"]) % [G.T(["", "", "area_bosque", "area_fundicion", "area_trono_vacio"][st + 1]), Prog.route_name()], false)
		Audio.play_music("theme", 2.0)
		if multiplayer.is_server():
			Prog.save_game()
	dialog.play(lines, done, true)

# ---------------------------------------------------------------------- final del juego base
func _on_azrahel_dead(e: Enemy) -> void:
	unseal_arena()
	wflags["azrahel_dead"] = true
	Prog.flags["azrahel_dead"] = true
	hud.hide_boss()
	active_boss = null
	var lp := local_player()
	if lp:
		lp.cutscene = true
	G.slowmo("kill", 0.15, 2.5)
	G.flash(Color(0.8, 0.6, 1.0, 0.9), 1.2)
	G.shake(14.0, 3.0)
	G.chroma(2.5, 2.0)
	Audio.stop_music(0.2)
	Fx.burst(e.global_position + Vector2(0, -24), Color(0.75, 0.5, 1.0), 120, 280.0, 2.0, "fx_feather", 180.0, Vector2.UP, 1.8, false, Vector2(0, 30))
	Fx.ring(e.global_position + Vector2(0, -24), 10.0, 300.0, Color(0.8, 0.6, 1.0), 1.6, 12.0)
	Prog.achieve("azrahel")
	Prog.quest_step("main4", "kill_azrahel")
	Prog.flags["base_complete"] = true
	Prog.add_weapon("corona")
	if multiplayer.is_server():
		Prog.save_game()
	await get_tree().create_timer(2.5).timeout
	if Prog.unlock_memory("m7"):
		await hud.memory_sequence(G.L(Prog.MEMORIES.m7.title), Prog.MEMORIES.m7.lines.map(func(l): return G.L(l)))
	hud.letterbox(true)
	var wings := Prog.route_score() >= 0
	var lines := [
		["Azrahel", ["Así que... era verdad. Un Desplumado bajando hasta el fondo.", "So... it was true. A Featherless descending to the very bottom."]],
		["Azrahel", ["Yo fui el primero que se negó. Me sentaron aquí para que todos lo vieran... y nadie lo escuchara.", "I was the first to refuse. They sat me here so all would see it... and none would hear it."]],
		["Azrahel", ["La orden que llevas grabada... «mata al Rey del Abismo». ¿Nunca te preguntaste quién la escribió?", "The order burned into you... \"slay the King of the Abyss\". Did you never wonder who wrote it?"]],
		["???", ["Bien hecho. Muy bien hecho. Ahora siéntate en el trono. Es tuyo.", "Well done. Very well done. Now sit upon the throne. It is yours."]],
		["???", ["Siempre fue tuyo. Yo te guié hasta aquí, pluma a pluma.", "It was always yours. I guided you here, feather by feather."]],
		["", ["La Voz deja de fallar. Por primera vez se oye entera, sin interferencias... y la reconoces.", "The Voice stops glitching. For the first time you hear it whole, without interference... and you recognise it."]],
		["El Arquitecto", ["Yo construí la Espiral. Yo os encerré. Yo os di la orden. Y tú la has cumplido.", "I built the Spiral. I locked you in. I gave you the order. And you have carried it out."]],
		["Azrahel", ["No le escuches... la Espiral no se sostiene con tronos. Se sostiene con... los que obedecen.", "Don't listen to him... the Spiral isn't held up by thrones. It's held up by... those who obey."]],
	]
	if wings:
		lines.append(["", ["No te sientas. Le das la espalda al trono. Y algo cruje, muy arriba y muy abajo a la vez.", "You do not sit. You turn your back on the throne. And something cracks, far above and far below at once."]])
	else:
		lines.append(["", ["Tocas el trono. Está frío. Y en el instante en que lo tocas, algo cruje, muy arriba y muy abajo a la vez.", "You touch the throne. It is cold. And the instant you touch it, something cracks, far above and far below at once."]])
	lines.append(["El Arquitecto", ["¿Qué has...? ¡No! ¡La Espiral...!", "What have you...? No! The Spiral...!"]])
	dialog.play(lines, _ending_sequence.bind(wings), true)

func _ending_sequence(wings: bool) -> void:
	# la Espiral se agrieta en dos direcciones: arriba, los Cielos Rotos; abajo, el Abismo Sin Nombre
	Audio.sfx("thunder", 2.0, 0.0)
	Audio.sfx("gate", 0.0, 0.0)
	for k in 6:
		G.shake(12.0, 0.6)
		G.flash(Color(1, 1, 1, 0.35 + k * 0.08), 0.25)
		var abyss: Node = get_node_or_null("Abyss")
		if abyss and abyss.has_method("_make_bolt"):
			abyss.call("_make_bolt")
		await get_tree().create_timer(0.5).timeout
	Prog.achieve("ending")
	Prog.achieve("route_wings" if wings else "route_throne")
	if Prog.deaths == 0:
		Prog.achieve("deathless")
	if Prog.playtime < 3.0 * 3600.0:
		Prog.achieve("speedrun")
	if _fight_flasks == 0:
		Prog.achieve("dry")
	if Prog.wing_feathers >= Prog.WING_MAX:
		Prog.achieve("full_wings")
	hud.end_card(G.L(["LA ESPIRAL SE ROMPE", "THE SPIRAL BREAKS"]),
		G.L(["Arriba, una grieta hacia los Cielos Rotos. Abajo, otra hacia el Abismo Sin Nombre.\nTu destino: %s.  Continuará...", "Above, a rift to the Broken Heavens. Below, another to the Nameless Abyss.\nYour fate: %s.  To be continued..."]) % Prog.route_name(), true)
	Audio.play_music("theme", 1.0)
	if multiplayer.is_server():
		Prog.save_game()
	await get_tree().create_timer(12.5 if G.autotest == "" else 2.0).timeout
	var cr := preload("res://scripts/ui/credits.gd").new()
	cr.wings = wings
	add_child(cr)
	await cr.finished
	hud.letterbox(false)
	var lp := local_player()
	if lp:
		lp.cutscene = false
		lp.respawn_at(_brasa_spawn("jardin" if interactables.has("jardin") else "sanct"))
	G.toast(G.L(["Juego base completado. Puedes seguir explorando, buscar los secretos o empezar un Segundo Descenso.", "Base game complete. You can keep exploring, hunt the secrets or begin a Second Descent."]), UIKit.GOLD)

# ---------------------------------------------------------------------- PNJ de los Estratos II-IV
func _talk_strata(id: String) -> void:
	var errand: Array = Strata.ERRANDS[id]
	var q: String = errand[0]
	var main_q: Array = {"oso": ["main2", "talk_oso"], "archivero": ["main3", "talk_archivero"], "lirio": ["main4", "talk_lirio"]}.get(id, ["", ""])
	var lines: Array
	if not Prog.flags.get("met_" + id, false):
		Prog.flags["met_" + id] = true
		lines = Strata.DIALOGUE[id]
		var start := func() -> void:
			if not Prog.quests.has(q):
				Prog.start_quest(q)
			Prog.quest_step(main_q[0], main_q[1])
		dialog.play(lines, start)
		return
	Prog.quest_step(main_q[0], main_q[1])
	if Prog.quest_done(q) and not Prog.flags.get("errand_thanks_" + id, false):
		Prog.flags["errand_thanks_" + id] = true
		dialog.play(Strata.DIALOGUE[id + "_done"], Callable())
		return
	dialog.play(Strata.DIALOGUE[id + "_again"], Callable())

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
	# ejecuciones: enemigo normal (o élite) con la postura rota al alcance
	exec_target = null
	if lp and lp.is_alive() and not lp.cutscene:
		var bd := 46.0
		for e in enemies_alive():
			if not e.is_boss and e.is_staggered():
				var dd: float = e.global_position.distance_to(lp.global_position)
				if dd < bd:
					bd = dd
					exec_target = e
	# perdonar a un Arconte con la postura rota al borde de la muerte
	_spare_target = null
	if lp and lp.is_alive() and active_boss and is_instance_valid(active_boss) and active_boss.is_alive() and asc_fight.is_empty():
		var b := active_boss
		if b.type in ["carcelero", "choir", "seravel", "orrun", "vulkaris"] and b.is_staggered() and b.hp / b.max_hp < 0.2 and lp.global_position.distance_to(b.global_position) < 80.0:
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
	Prog.achieve("spark")
	hud.big_message(G.L(["CHISPA SE UNE A TI", "SPARK JOINS YOU"]), Color(1, 0.75, 0.35), 2.2)
	G.toast(G.L(["Una brasa viva te seguirá: ilumina y presiente secretos.", "A living ember follows you: it lights the way and senses secrets."]), Color(1, 0.8, 0.5))

func _feather_torn_msg() -> void:
	G.toast(G.T("feather_torn") + "  %d/%d" % [Prog.wing_feathers, Prog.WING_MAX], Look.color_of(G.look, "wing"))
	if Prog.is_desplumado():
		G.toast(G.T("desplumado_mode") + ": " + G.L(["más daño y velocidad, menos vida.", "more damage and speed, less health."]), UIKit.PINK)

func _feather_recovered(n: int, at: Vector2) -> void:
	Fx.burst(at + Vector2(0, -10), Look.color_of(G.look, "wing"), 18, 90.0, 1.2, "fx_feather", 180.0, Vector2.UP, 1.0, false, Vector2(0, 20))
	G.toast(G.L(["Recuperas tu pluma arrancada", "You recover your torn feather"]) + ("" if n == 1 else " x%d" % n) + "  %d/%d" % [Prog.wing_feathers, Prog.WING_MAX], Look.color_of(G.look, "wing"))
	Audio.sfx("heal", -3.0)
	send_look()
	Ach.add("feathers_recovered", float(n))

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
	Prog.achieve("spare")
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
	Ach.add("cross")
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
			Ach.add("revives")
			world.on_partner_revived(true)
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
const ARENAS_I := {"carcelero": ["yard", "celda"], "choir": ["choir", "coro"], "seravel": ["circle", "luz"]}
var _seals: Array[Node2D] = []

func seal_for(boss_type: String) -> void:
	if ARENAS.has(boss_type):
		seal_arena(ARENAS[boss_type][0], ARENAS[boss_type][1])

func seal_arena(room_id: String, style: String, pull_far := true) -> void:
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
	# quien se haya quedado fuera entra en la sala (cooperativo); sin curarse gratis por el camino
	var lp := local_player()
	if lp and lp.is_alive() and room_at(lp.global_position) != room_id and inner != Vector2.ZERO and (pull_far or (lp.global_position.distance_to(inner) < 420.0 and not is_menu_open())):
		lp.position = inner
		lp._net_pos = inner

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
		# los barrotes son altos: se inclinan con la perspectiva de la cámara
		var dd := (global_position - Depth3D.cam_center(self)) / Depth3D.CAM_H
		draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, clampf(1.0 - dd.y * 0.9, 0.85, 1.15)), asin(clampf(dd.x, -0.4, 0.4)), Vector2.ZERO))
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
const TRIALS_I := {
	"celdas": {"room": "celdas", "seal": "celda", "title": "trial_celdas",
		"waves": [[["hueco", 18.5, 47.3], ["hueco", 22.5, 47.3], ["hueco", 26.5, 47.3]],
			[["hueco", 18.5, 47.3], ["acolito", 31, 51], ["hueco", 30.5, 47.3], ["hueco", 22.5, 47.3]],
			[["bestia", 22.5, 47.3], ["guardia", 18.5, 47.3], ["acolito", 33, 50], ["guardia", 26.5, 47.3]]],
		"reward": {"feathers": 1, "ecos": 300, "items": {"tear": 1}}, "chest": Vector2(19.5, 51.3)},
	"umbral": {"room": "antesala", "seal": "luz", "title": "trial_umbral",
		"waves": [[["acolito", 67, 9], ["planidera", 71, 9], ["hueco", 69, 13]],
			[["custodio", 69, 10]]],
		"reward": {"feathers": 2, "ecos": 600, "items": {"iron": 1}}, "chest": Vector2(69, 7.4)},
}
## Cierres que siguen puestos hasta superar la prueba: [prueba, casillas, estilo]
const LOCKS := [["celdas", Rect2i(47, 46, 4, 1), "celda"], ["atrio", Rect2i(81, 47, 3, 1), "coro"], ["umbral", Rect2i(64, 12, 1, 3), "luz"],
	["cadalso", Rect2i(83, 84, 3, 1), "luz"],
	["b_puerta", Rect2i(139, 29, 4, 1), "luz"], ["f_puerta", Rect2i(238, 25, 4, 1), "celda"], ["t_puerta", Rect2i(334, 29, 4, 1), "luz"]]
const BELL_ORDER := [0, 1, 2]       # orden correcto (aguda, media, grave): el himno escrito era grave-media-aguda
const CELL_DOORS := [18.5, 22.5, 26.5, 30.5]
var _trial := ""
var _trial_wave := -1
var _trial_wait := 0.0
var _locks := {}
var _bell_seq: Array = []
var _cell_doors: Array = []
var breakables := {}
var exec_target: Enemy = null

func _execute(p: Player, e: Enemy) -> void:
	## Remate cinematográfico: te lanzas contra el enemigo aturdido y lo atraviesas
	var dir: Vector2 = (e.global_position - p.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	exec_target = null
	p.aim = dir
	p.global_position = e.global_position - dir * 16.0
	p.state = "move"
	p._start_attack()
	G.slowmo("exec", 0.15, 0.45)
	G.flash(Color(1, 0.95, 0.85, 0.5), 0.15)
	hud.letterbox(true)
	get_tree().create_timer(0.6, true, false, true).timeout.connect(hud.letterbox.bind(false))
	var c := e.global_position + Vector2(0, -10)
	Fx.slash(c, dir.angle() + 0.8, 26.0, 140.0, Color(1, 0.95, 0.8), 12.0, 0.3)
	Fx.slash(c, dir.angle() - 0.8, 26.0, 140.0, Color(1, 0.6, 0.3), 12.0, 0.3, false)
	Fx.impact(c, Color(1, 0.9, 0.6), 30.0, 10)
	Fx.sparks(c, dir, Color(1, 0.8, 0.4), 18, 220.0, 120.0)
	Fx.text(c + Vector2(0, -6), G.T("executed"), Color(1, 0.85, 0.4), 12)
	Audio.sfx("hit_heavy", 0.0, 0.0)
	Audio.sfx("slam", -6.0)
	G.shake(6.0, 0.35)
	var dmg: float = e.max_hp * (0.35 if e.cfg.get("elite", false) else 1.2) + Prog.weapon_damage() * 2.0
	request_damage_enemy(e, dmg, dir, 0.0, true)
	p.hp = min(Prog.max_hp(), p.hp + Prog.max_hp() * 0.06)
	p.wrath = min(100.0, p.wrath + 18.0)
	Prog.flags["executions"] = int(Prog.flags.get("executions", 0)) + 1
	Ach.add("executions")
	if Prog.weapon_data().get("sentence", false):
		p.hp = min(Prog.max_hp(), p.hp + Prog.max_hp() * 0.2)
		Fx.burst(p.global_position + Vector2(0, -10), Color(1, 0.3, 0.4), 16, 60.0, 0.6, "fx_soft", 180.0, Vector2.UP, 0.4)

var urns: Array = []

func hit_breakables(origin: Vector2, rng: float) -> void:
	for bw in breakables.values():
		if not bw.broken and bw.global_position.distance_to(origin) < rng + 14.0:
			bcast("_hit_breakable", [bw.id])
	for i in urns.size():
		var u: Urn = urns[i]
		if is_instance_valid(u) and not u.broken and u.global_position.distance_to(origin) < rng + 6.0:
			u.smash(true)
			Ach.add("urns")
			bcast("_urn_broken", [i])

@rpc("any_peer", "call_remote", "reliable")
func _urn_broken(i: int) -> void:
	if i >= 0 and i < urns.size() and is_instance_valid(urns[i]):
		urns[i].smash(false)

func _area_thoughts(a: String) -> void:
	## Monólogo interior al pisar una zona por primera vez (se interrumpe si empieza un combate o una escena)
	await get_tree().create_timer(2.6).timeout
	var guard := 0
	while local_player() != null and local_player().cutscene and guard < 40:
		await get_tree().create_timer(0.5).timeout
		guard += 1
	if guard > 0:
		await get_tree().create_timer(1.0).timeout
	for ln in Lore.AREA_THOUGHTS[a]:
		if not is_inside_tree() or active_boss != null or _trial != "" or _contemplating or dialog.is_open() or _area != a:
			return
		Prog.flags["thought_" + a] = true
		var txt := G.L(ln[1])
		var dur := clampf(txt.length() * 0.055, 2.4, 5.0)
		if ln[0] == "???":
			Audio.sfx("glitch", -12.0)
			hud.subtitle("???", txt, dur, Color(1, 0.62, 0.6))
		else:
			hud.subtitle("", "( " + txt + " )", dur, Color(0.84, 0.82, 0.96))
		await get_tree().create_timer(dur + 0.9).timeout

var shadow_lights: Array = []

func _collect_shadow_lights() -> void:
	## Antorchas, braseros y Brasas: las luces que proyectan sombras de los personajes
	shadow_lights.clear()
	var brazier := Fx.tex("brazier")
	for c in entities.get_children():
		var lp := Vector2.INF
		if c is WallTorch:
			lp = (c as Node2D).global_position + Vector2(0, 10)
		elif c is Sprite2D and (c as Sprite2D).texture == brazier:
			lp = (c as Node2D).global_position
		if lp != Vector2.INF:
			shadow_lights.append([lp, room_at(lp)])
	for k in interactables:
		var it: Node2D = interactables[k]
		if it.get("kind") == "brasa":
			shadow_lights.append([it.global_position, room_at(it.global_position)])

func _place_ghost_echoes() -> void:
	## Fantasmas que reviven un recuerdo del Estrato al acercarte
	var specs := [
		["galeria", Vector2(67.5, 61.4), [["enemy_acolito", Rect2(0, 0, 32, 32), Vector2(-12, 0), false], ["enemy_acolito", Rect2(32, 0, 32, 32), Vector2(12, 0), true]]],
		["patio", Vector2(49.5, 44.2), [["boss_seravel", Rect2(0, 0, 52, 56), Vector2(-16, 0), false], ["enemy_carcelero", Rect2(0, 0, 40, 40), Vector2(18, 0), true]]],
		["nimbo", Vector2(66, 82.6), [["boss_seravel", Rect2(0, 0, 52, 56), Vector2(-15, 0), false], ["player", Rect2(0, 0, 32, 32), Vector2(14, 0), true]]],
		["capilla", Vector2(84, 77.2), [["player", Rect2(0, 96, 32, 32), Vector2(0, 0), false]]],
	]
	for sp in specs:
		var g := GhostEcho.new()
		g.world = self
		g.id = sp[0]
		g.figures = sp[2]
		g.position = tile_pos(sp[1].x, sp[1].y)
		entities.add_child(g)

func _place_fallen() -> void:
	## Ángeles caídos hace siglos: esqueletos con las alas abiertas, algunos con su espada clavada
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	for rid in ["chains", "gallery", "east", "hall1", "celdas", "escala", "mirador", "alcove", "hall2", "cornisa"]:
		for r in ROOMS:
			if r.id != rid:
				continue
			var rc := _rect_of(r)
			var placed := 0
			for tries in 20:
				if placed >= (2 if rc.size.x * rc.size.y > 120 else 1):
					break
				var x := rng.randi_range(rc.position.x + 1, rc.end.x - 2)
				var y := rng.randi_range(rc.position.y + 1, rc.end.y - 2)
				if _floor_at(x, y) and _floor_at(x - 1, y) and _floor_at(x + 1, y) and _floor_at(x, y + 1):
					var fa := FallenAngel.new()
					fa.position = tile_pos(x + 0.5, y + 0.5)
					fa.seed_v = rng.randi()
					fa.z_index = -2
					entities.add_child(fa)
					placed += 1

func _place_npc_life() -> void:
	## Cada PNJ hace algo propio: Brenna forja en su yunque, Ozias graba runas, Nyx cuenta monedas, Velaria vela,
	## el Cartógrafo dibuja, Ilse cose... pequeños gestos que dan vida al Santuario y al Nimbo
	for id in ["brenna", "carto", "ozias", "ilse", "nyx", "velaria"]:
		if not interactables.has(id):
			continue
		var it: Node2D = interactables[id]
		var nl := NpcLife.new()
		nl.kind = id
		nl.world = self
		nl.position = it.position
		entities.add_child(nl)

func _place_webs() -> void:
	## Telarañas en las esquinas de las salas: detalle que da edad a la Espiral
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for r in ROOMS:
		if not r.has("rect"):
			continue
		var rc: Rect2i = r.rect
		if rc.size.x < 5 or rc.size.y < 4:
			continue
		for side in [0, 1]:
			if rng.randf() > 0.65:
				continue
			var tx := rc.position.x if side == 0 else rc.end.x - 1
			var ty := rc.position.y
			if not _floor_at(tx, ty):
				continue
			var wb := CornerWeb.new()
			wb.position = Vector2((tx + (0 if side == 0 else 1)) * TS, ty * TS)
			wb.dir = 1.0 if side == 0 else -1.0
			wb.radius = rng.randf_range(11.0, 19.0)
			wb.z_index = -1
			entities.add_child(wb)

func _place_urns() -> void:
	## Urnas funerarias junto a los muros de las salas tranquilas: se rompen y sueltan Ecos o una pluma
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for rid in ["sanct", "chains", "gallery", "alcove", "celdas", "atrio", "escala", "mirador", "capilla", "east"]:
		for r in ROOMS:
			if r.id != rid:
				continue
			var rc := _rect_of(r)
			for k in 3:
				for tries in 10:
					var x := rng.randi_range(rc.position.x + 1, rc.end.x - 2)
					var y := rc.position.y + (0 if rng.randf() < 0.7 else rc.size.y - 1)
					if _floor_at(x, y) and _floor_at(x, y + 1):
						var u := Urn.new()
						u.world = self
						u.position = tile_pos(x + rng.randf_range(-0.2, 0.2), y + 0.2)
						u.variant = rng.randi_range(0, 2)
						entities.add_child(u)
						urns.append(u)
						break

func _reset_urns() -> void:
	for u in urns:
		if is_instance_valid(u):
			u.restore()

@rpc("any_peer", "call_remote", "reliable")
func _hit_breakable(id: String) -> void:
	var bw = breakables.get(id)
	if bw == null or bw.broken:
		return
	bw.hp -= 1
	bw.shake = 0.2
	Audio.sfx("hit_heavy", -6.0)
	G.shake(2.0, 0.12)
	Fx.burst(bw.global_position + Vector2(0, -8), Color(0.55, 0.5, 0.6), 8, 50.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4, false)
	if bw.hp <= 0:
		wflags["broken_" + id] = true
		Prog.flags["broken_" + id] = true
		if id == "capilla":
			Prog.achieve("secret")
		bw.set_broken(false)
		hud.big_message(G.L(["PASADIZO SECRETO", "SECRET PASSAGE"]), Color(0.7, 1.0, 0.85) if id == "capilla" else Color(0.6, 0.9, 1.0), 2.2)
		if multiplayer.is_server():
			Prog.save_game()

func trial_done(id: String) -> bool:
	return wflags.get("trial_" + id, false)

func _check_gates(announce: bool) -> void:
	## La puerta de cada Arconte se abre al superar sus dos pruebas
	for gid in Strata.GATES:
		if trial_done(gid):
			continue
		var g: Dictionary = Strata.GATES[gid]
		if wflags.get(g.boss + "_dead", false) or (trial_done(g.trials[0]) and trial_done(g.trials[1])):
			wflags["trial_" + gid] = true
			Prog.flags["trial_" + gid] = true
			Prog.quest_step(g.step[0], g.step[1])
			if announce:
				get_tree().create_timer(3.2).timeout.connect(G.toast.bind(G.T("gates_open"), UIKit.GOLD))

func _refresh_locks(instant: bool) -> void:
	_check_gates(false)
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
	_add_inter("npc", "peregrina", tile_pos(62.0, 27.9), {"sheet": "npc_peregrina", "name": ["Sael, la Peregrina", "Sael, the Pilgrim"], "flip": true, "light": Color(1, 0.85, 0.55),
		"walk": [tile_pos(62.0, 27.9), tile_pos(72.5, 27.9)]})
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
	# --- Capilla Olvidada (secreta): recuerdo IV, cofre, inscripción y una página del himno
	var bw := BreakableWall.new()
	bw.id = "capilla"
	bw.world = self
	bw.position = tile_pos(84, 72)
	entities.add_child(bw)
	breakables["capilla"] = bw
	_add_inter("bench", "bench_capilla", tile_pos(84, 79.6), {"memory": "m4"})
	_add_inter("chest", "chest_capilla", tile_pos(88, 77.4), {"ecos": 350, "items": {"phoenix": 1, "tear": 1}})
	_add_inter("lore", "lore_capilla", tile_pos(80.4, 77.4), {"lines": [["lore_title", ["«Aquí rezaba el verdugo. No pedía perdón: pedía olvidar.»", "\"Here the executioner prayed. Not for forgiveness: to forget.\""]],
		["lore_title", ["«Se lo concedieron.»", "\"It was granted.\""]]]})
	_add_inter("pickup", "page_3", tile_pos(87.5, 81.5), {"icon": "page", "quest": "hymns"})
	_add_inter("pickup", "page_1", tile_pos(17.6, 52.4), {"icon": "page", "quest": "hymns"})
	_add_inter("pickup", "page_2", tile_pos(74.2, 52.6), {"icon": "page", "quest": "hymns"})
	for cp in [Vector2(81, 81), Vector2(87, 81), Vector2(82, 76.6), Vector2(86, 76.6)]:
		_prop("candle", tile_pos(cp.x, cp.y), 4, int(cp.x) % 4, 0.0, Color(0.7, 1.0, 0.85), 1.0)
	var fpc := FlowerPatch.new()
	fpc.position = tile_pos(84, 81.5)
	fpc.count = 14
	fpc.petal = Color(0.75, 1.0, 0.85)
	entities.add_child(fpc)
	_fireflies(Rect2(79 * TS, 76 * TS, 11 * TS, 7 * TS))
	# --- Santuario y Sala del Nimbo: antorchas y luz que cae sobre la Brasa
	for tp2 in [Vector2(42.5, 79.7), Vector2(45, 79.7), Vector2(53, 79.7), Vector2(55.5, 79.7), Vector2(63, 78.7), Vector2(69, 78.7)]:
		var wt2 := WallTorch.new()
		wt2.position = tile_pos(tp2.x, tp2.y)
		entities.add_child(wt2)
	for cpos in [Vector2(66, 86), Vector2(49, 82.5), Vector2(84.5, 78.5), Vector2(69.5, 12.5), Vector2(69.5, 21.5)]:
		var ch := Depth3D.Chandelier.new()
		ch.position = tile_pos(cpos.x, cpos.y)
		add_child(ch)
	var sanct_rays := LightShafts.new()
	sanct_rays.position = tile_pos(49, 85)
	sanct_rays.col = Color(1, 0.8, 0.55)
	add_child(sanct_rays)
	# --- ambiente propio de cada sala (goteo, notas, polvo dorado, niebla fría)
	for spec in [["celdas", "drip"], ["chains", "drip"], ["atrio", "notes"], ["choir", "notes"], ["antesala", "gold"], ["escala", "gold"], ["gallery", "mist"], ["capilla", "spores"]]:
		for r in ROOMS:
			if r.id == spec[0]:
				var amb := RoomAmbience.new()
				amb.rect = Rect2(Vector2(_rect_of(r).position) * TS, Vector2(_rect_of(r).size) * TS)
				amb.kind = spec[1]
				add_child(amb)
	# --- Mirador: estrellas fugaces sobre el abismo
	var stars := ShootingStars.new()
	stars.position = tile_pos(24, 84)
	add_child(stars)
	# --- vitrales del Atrio
	var glass2 := LightShafts.new()
	glass2.position = tile_pos(82, 52)
	glass2.stained = true
	add_child(glass2)
	# --- Antesala del Juicio: estandartes y luz que cae
	for b in [Vector2(66.5, 5.5), Vector2(71.5, 5.5)]:
		_prop("banner", tile_pos(b.x, b.y), 2, 0)
	for cp in [Vector2(66.2, 9), Vector2(71.8, 9), Vector2(66.2, 24), Vector2(71.8, 24)]:
		var col2 := Depth3D.Column.new()
		col2.position = tile_pos(cp.x, cp.y)
		col2.height = 70.0
		col2.radius = 6.0
		entities.add_child(col2)
	# cadenas que bajan desde lo alto (Pasillo de las Cadenas y Celdas)
	for hp in [Vector2(42, 58), Vector2(56, 58), Vector2(47, 65), Vector2(39, 63), Vector2(59, 63), Vector2(21, 49), Vector2(31, 49.5)]:
		var hc := Depth3D.HangingChain.new()
		hc.position = tile_pos(hp.x, hp.y)
		hc.low_h = 30.0 + fmod(hp.x * 7.0, 26.0)
		add_child(hc)
	var shafts := LightShafts.new()
	shafts.position = tile_pos(69, 15)
	shafts.col = Color(1, 0.9, 0.6)
	add_child(shafts)
	_build_secret_rooms()

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
	e.home_room = TRIALS[_trial].room if _trial != "" else e.home_room  # oleadas que asoman por la puerta siguen dentro
	if e.cfg.get("elite", false):
		hud.show_boss(e)
	var col := Color(1, 0.85, 0.5) if type == "custodio" else Color(0.9, 0.3, 0.3)
	Fx.burst(pos + Vector2(0, -8), col, 22, 70.0, 0.7, "fx_soft", 180.0, Vector2.UP, 0.5)
	Fx.ring(pos, 4.0, 30.0, col, 0.4, 2.0)
	if type == "custodio":
		G.shake(6.0, 0.6)
		Fx.light_flash(pos, Color(1, 0.85, 0.5), 3.0, 1.6, 0.8)
		_cam_focus = pos + Vector2(0, -20)
		hud.letterbox(true)
		get_tree().create_timer(1.8 if G.autotest == "" else 0.3).timeout.connect(func():
			_cam_focus = null
			hud.letterbox(false))

@rpc("any_peer", "call_remote", "reliable")
func _trial_complete(id: String) -> void:
	_trial = ""
	_trial_wave = -1
	wflags["trial_" + id] = true
	Prog.flags["trial_" + id] = true
	if trial_done("celdas") and trial_done("atrio") and trial_done("umbral"):
		Prog.achieve("trials")
	var mb := 0
	for t3 in ["cienaga", "moldes", "galeria"]:
		if trial_done(t3):
			mb += 1
	Ach.set_max("minibosses", mb)
	unseal_arena()
	_refresh_locks(false)
	_ensure_trial_chest(id, true)
	hud.hide_trial()
	hud.big_message(G.T("trial_done"), Color(1, 0.85, 0.4), 2.6)
	Audio.sfx("levelup")
	var stm := Strata.stratum_of_room(TRIALS[id].room)
	Audio.play_music(Strata.MUSIC.get(stm, "explore") if ResourceLoader.exists("res://assets/audio/music_%s.ogg" % Strata.MUSIC.get(stm, "explore")) else "explore", 2.0)
	Prog.quest_step("main1", "trial_" + id)
	_check_gates(true)
	_refresh_locks(false)
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
	Fx.text(it.global_position + Vector2(0, -22), G.L([["Aguda", "High"], ["Media", "Middle"], ["Grave", "Low"]][n]), Color(0.85, 0.75, 1.0), 9)
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
	Prog.achieve("bells")
	if trial_done("celdas") and trial_done("umbral"):
		Prog.achieve("trials")
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


class BreakableWall extends Node2D:
	## Muro agrietado que se derrumba a golpes (3) y deja ver un pasadizo
	var id := ""
	var world: Node
	var hp := 3
	var broken := false
	var shake := 0.0
	var _spr: Sprite2D
	var _body: StaticBody2D
	func _ready() -> void:
		_spr = Sprite2D.new()
		_spr.texture = Fx.tex("cracked_wall")
		_spr.region_enabled = true
		_spr.region_rect = Rect2(0, 0, 48, 24)
		_spr.offset = Vector2(0, -6)
		add_child(_spr)
		_body = StaticBody2D.new()
		_body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(48, 16)
		cs.shape = sh
		_body.add_child(cs)
		add_child(_body)
	func set_broken(instant: bool) -> void:
		if broken:
			return
		broken = true
		_spr.region_rect = Rect2(48, 0, 48, 24)
		_body.queue_free()
		if not instant:
			Audio.sfx("slam", -2.0)
			G.shake(5.0, 0.4)
			world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position, 16, Color(0.4, 0.36, 0.45), 1.2))
			Fx.burst(global_position, Color(0.6, 0.55, 0.65), 30, 90.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.6, false)
	func _process(delta: float) -> void:
		shake = max(0.0, shake - delta)
		_spr.position = Vector2(randf_range(-2, 2), 0) * (shake / 0.2)


@rpc("any_peer", "call_remote", "reliable")
func _enemy_blocked(idx: int) -> void:
	if idx >= enemies.size():
		return
	var e: Enemy = enemies[idx]
	Audio.sfx("parry", -6.0)
	Fx.sparks(e.global_position + Vector2(float(e.facing) * 8.0, -12), Vector2(float(e.facing), -0.4), Color(1, 0.85, 0.5), 10, 160.0, 70.0)
	Fx.text(e.global_position + Vector2(0, -6), G.L(["¡BLOQUEADO!", "BLOCKED!"]), Color(0.85, 0.85, 0.95), 9)


func _nimbo_intro() -> void:
	Prog.achieve("nimbo")
	## Primera vez en la Sala del Nimbo: la cámara presenta a los cuatro que viven junto a la mesa redonda
	Prog.flags["nimbo_intro"] = true
	var lp := local_player()
	if lp == null:
		return
	lp.cutscene = true
	lp.velocity = Vector2.ZERO
	hud.letterbox(true)
	hud.show_area(G.T("stratum1"), G.T("area_nimbo"))
	await get_tree().create_timer(2.2 if G.autotest == "" else 0.3).timeout
	var cast := [["ozias", ["El Grabador de runas", "The Rune Engraver"], ["Ozias", "Ozias"]],
		["ilse", ["La que cose plumas", "She who sews feathers"], ["Madre Ilse", "Mother Ilse"]],
		["nyx", ["Mercader de Plumas Negras", "Black-Feathered Merchant"], ["Nyx", "Nyx"]],
		["velaria", ["Guardiana de los ecos", "Keeper of Echoes"], ["Sor Velaria", "Sister Velaria"]]]
	for c in cast:
		if not interactables.has(c[0]):
			continue
		var it: Node2D = interactables[c[0]]
		_cam_focus = it.global_position + Vector2(0, -10)
		Prog.flags["known_" + c[0]] = true
		await get_tree().create_timer(0.5 if G.autotest == "" else 0.1).timeout
		hud.show_area(G.L(c[1]), G.L(c[2]))
		Audio.voice(G.L(c[2]))
		await get_tree().create_timer(1.9 if G.autotest == "" else 0.3).timeout
	_cam_focus = null
	hud.letterbox(false)
	if is_instance_valid(lp):
		lp.cutscene = false

func _escala_pan() -> void:
	## Primera vez en la Escalinata: la cámara sube hasta la Antesala y vuelve
	Prog.flags["escala_seen"] = true
	var lp := local_player()
	if lp == null:
		return
	lp.cutscene = true
	hud.letterbox(true)
	_cam_focus = tile_pos(69, 12)
	hud.subtitle("", G.L(["La Escalinata del Juicio. Arriba, alguien lleva mil años esperando.", "The Stairway of Judgement. Above, someone has waited a thousand years."]), 2.6)
	await get_tree().create_timer(2.8 if G.autotest == "" else 0.4).timeout
	_cam_focus = null
	hud.letterbox(false)
	if is_instance_valid(lp):
		lp.cutscene = false


class ShootingStars extends Node2D:
	## Estrellas fugaces (plumas encendidas) que cruzan el cielo frente al Mirador
	var t := 0.0
	var trails: Array = []
	func _ready() -> void:
		z_index = -12
		material = Fx.add_material()
	func _process(delta: float) -> void:
		t += delta
		if randf() < delta * 0.5:
			trails.append([Vector2(randf_range(-160, 120), randf_range(-120, 0)), Vector2(randf_range(60, 120), randf_range(30, 60)), 0.0])
		for tr in trails:
			tr[2] += delta
		trails = trails.filter(func(tr): return tr[2] < 1.4)
		queue_redraw()
	func _draw() -> void:
		for i in 30:
			var sp := Vector2(fmod(i * 73.0, 280.0) - 160.0, fmod(i * 41.0, 160.0) - 130.0)
			draw_rect(Rect2(sp, Vector2(1, 1)), Color(1, 1, 1, 0.3 + 0.3 * sin(t * 2.0 + i)))
		for tr in trails:
			var k: float = tr[2] / 1.4
			var p: Vector2 = tr[0] + tr[1] * tr[2]
			var a := sin(k * PI)
			draw_line(p, p - tr[1].normalized() * 26.0, Color(1, 0.9, 0.7, 0.6 * a), 1.5)
			draw_circle(p, 1.5, Color(1, 1, 0.9, a))


class RoomAmbience extends Node2D:
	## Partículas de ambiente de una sala: gotas que caen y salpican, notas que flotan,
	## polvo dorado que baja en haces, niebla fría a ras de suelo o esporas que brillan
	var rect := Rect2()
	var kind := "drip"
	var parts: Array = []
	var t := 0.0
	func _ready() -> void:
		z_index = 3 if kind != "mist" else -7
		if kind in ["gold", "notes", "spores", "embers"]:
			material = Fx.add_material()
	func _process(delta: float) -> void:
		t += delta
		var cam := Depth3D.cam_center(self)
		if not rect.grow(200).has_point(cam):
			if not parts.is_empty():
				parts.clear()
				queue_redraw()
			return
		var rate: float = {"drip": 3.0, "notes": 2.0, "gold": 7.0, "mist": 2.5, "spores": 3.0, "embers": 9.0}[kind]
		if randf() < delta * rate:
			var p := Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))
			parts.append([p, 0.0, randf_range(0.7, 1.3)])
		for pp in parts:
			pp[1] += delta
		parts = parts.filter(func(pp): return pp[1] < 3.0)
		queue_redraw()
	func _draw() -> void:
		for pp in parts:
			var p: Vector2 = pp[0]
			var k: float = pp[1]
			match kind:
				"drip":
					if k < 0.5:
						var fall := Vector2(0, -60.0 * (1.0 - k / 0.5))
						draw_rect(Rect2(p + fall, Vector2(1, 3)), Color(0.6, 0.7, 0.9, 0.7))
					elif k < 1.0:
						var r := (k - 0.5) * 16.0
						draw_set_transform(p, 0.0, Vector2(1.0, 0.4))
						draw_arc(Vector2.ZERO, r, 0, TAU, 12, Color(0.6, 0.7, 0.9, 0.6 * (1.0 - (k - 0.5) * 2.0)), 1.0)
						draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"notes":
					var q := p + Vector2(sin(k * 2.0 + p.x) * 8.0, -k * 18.0)
					var a := sin(k / 3.0 * PI) * 0.8
					draw_circle(q, 1.6, Color(0.8, 0.65, 1.0, a))
					draw_line(q + Vector2(1.4, 0), q + Vector2(1.4, -6), Color(0.8, 0.65, 1.0, a), 1.0)
				"gold":
					var q2 := p + Vector2(sin(k * 1.5 + p.y) * 6.0, k * 14.0)
					draw_rect(Rect2(q2, Vector2(1, 1)), Color(1, 0.88, 0.55, sin(k / 3.0 * PI) * 0.9))
				"mist":
					var a2 := sin(k / 3.0 * PI) * 0.12
					draw_set_transform(p + Vector2(k * 10.0, 0), 0.0, Vector2(1.0, 0.35))
					draw_circle(Vector2.ZERO, 22.0 * pp[2], Color(0.7, 0.8, 1.0, a2))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"spores":
					var q3 := p + Vector2(sin(k * 3.0 + p.x) * 5.0, -k * 8.0)
					draw_circle(q3, 1.2, Color(0.7, 1.0, 0.85, sin(k / 3.0 * PI) * 0.9))
				"embers":
					var q4 := p + Vector2(sin(k * 4.0 + p.x) * 4.0, -k * 26.0)
					var ea := sin(k / 3.0 * PI)
					draw_rect(Rect2(q4, Vector2(1, 1)), Color(1, 0.6 + 0.3 * ea, 0.2, ea))


class Urn extends Node2D:
	## Urna funeraria: se rompe de un golpe en trozos con altura y suelta Ecos (o, a veces, una pluma)
	var world: Node
	var variant := 0
	var broken := false
	var _body: StaticBody2D
	func _ready() -> void:
		_body = StaticBody2D.new()
		_body.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = 4.0
		cs.shape = sh
		_body.add_child(cs)
		add_child(_body)
	func smash(loot: bool) -> void:
		if broken:
			return
		broken = true
		_body.collision_layer = 0
		Audio.sfx("hit", -6.0)
		Audio.sfx("shatter", -10.0)
		world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position + Vector2(0, -4), 7, [Color(0.55, 0.42, 0.36), Color(0.5, 0.5, 0.58), Color(0.6, 0.5, 0.3)][variant], 0.6))
		Fx.burst(global_position + Vector2(0, -6), Color(0.6, 0.55, 0.6), 6, 40.0, 0.4, "fx_soft", 180.0, Vector2.UP, 0.3, false)
		queue_redraw()
		if not loot:
			return
		var roll := randf()
		if roll < 0.08:
			Prog.add_feathers(1)
			G.pickup("icon_feather", "+1 " + G.T("feathers"), Color(0.9, 0.9, 1))
		elif roll < 0.75:
			var n := randi_range(6, 18)
			Prog.add_ecos(n)
			G.pickup("icon_eco", "+%d %s" % [n, G.T("ecos")], Color(0.6, 0.85, 1))
		queue_redraw()
	func restore() -> void:
		if not broken:
			return
		broken = false
		_body.collision_layer = 1
		queue_redraw()
	func _draw() -> void:
		var cols := [[Color(0.55, 0.42, 0.36), Color(0.72, 0.58, 0.48)], [Color(0.42, 0.42, 0.5), Color(0.6, 0.6, 0.7)], [Color(0.55, 0.45, 0.25), Color(0.8, 0.66, 0.35)]]
		var c: Array = cols[variant]
		draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if broken:
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(-3, -3), Vector2(0, -1), Vector2(3, -4), Vector2(5, 0)]), (c[0] as Color).darkened(0.3))
			return
		var ink := Color(0.08, 0.04, 0.08)
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -2), Vector2(-5, -9), Vector2(-3, -12), Vector2(3, -12), Vector2(5, -9), Vector2(6, -2), Vector2(4, 1), Vector2(-4, 1)]), ink)
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -2), Vector2(-4, -9), Vector2(-2, -11), Vector2(2, -11), Vector2(4, -9), Vector2(5, -2), Vector2(3, 0), Vector2(-3, 0)]), c[0])
		draw_line(Vector2(-3, -9), Vector2(-3, -2), c[1], 1.0)
		draw_rect(Rect2(Vector2(-3, -14), Vector2(6, 3)), ink)
		draw_rect(Rect2(Vector2(-2, -13), Vector2(4, 2)), c[1])
		draw_line(Vector2(-4, -6), Vector2(4, -6), (c[0] as Color).darkened(0.35), 1.0)


class GhostEcho extends Node2D:
	## Eco del pasado: figuras translúcidas que repiten una conversación de hace mil años
	var world: Node
	var id := ""
	var figures: Array = []
	var played := false
	var _sprs: Array = []
	var _base: Array = []
	var _t := 0.0
	var _alpha := 0.0
	var _target := 0.1
	var _aborted := false
	var _gen := 0
	var _light: PointLight2D
	func _ready() -> void:
		z_index = 0
		played = Prog.flags.get("echo_" + id, false)
		_target = 0.0 if played else 0.12
		for f in figures:
			var sp := Sprite2D.new()
			var r: Rect2 = f[1]
			if str(f[0]) == "player":
				var lp: Player = world.local_player()
				sp.texture = Look.texture(lp.look, 10) if lp else Fx.tex("player_p1")
			else:
				sp.texture = Fx.tex(f[0])
			sp.region_enabled = true
			sp.region_rect = r
			sp.position = f[2]
			sp.offset = Vector2(0, -r.size.y * 0.42)
			sp.flip_h = f[3]
			sp.material = Fx.add_material()
			sp.modulate = Color(0.45, 0.7, 1.0, 0.0)
			add_child(sp)
			_sprs.append(sp)
			_base.append(sp.position)
		_light = PointLight2D.new()
		_light.texture = Fx.tex("light")
		_light.color = Color(0.5, 0.75, 1.0)
		_light.texture_scale = 1.6
		_light.energy = 0.0
		_light.position = Vector2(0, -14)
		add_child(_light)
	func _process(delta: float) -> void:
		_t += delta
		if not played:
			var lp: Player = world.local_player()
			var calm: bool = world.active_boss == null and world._trial == ""
			if not calm:
				_target = 0.0
			elif _alpha <= 0.13:
				_aborted = false
				_target = 0.12
			if lp and lp.is_alive() and calm and not _aborted and lp.global_position.distance_to(global_position) < 52.0:
				_play()
			elif randf() < delta * 2.5:
				Fx.burst(global_position + Vector2(randf_range(-18, 18), randf_range(-24, 0)), Color(0.55, 0.8, 1.0), 1, 8.0, 0.9, "fx_soft", 40.0, Vector2.UP, 0.25, true)
		elif _target > 0.0 and not _aborted and (world.active_boss != null or world._trial != ""):
			# empieza un combate: el eco se desvanece y podrá verse más tarde
			_aborted = true
			_target = 0.0
			played = false
			Prog.flags["echo_" + id] = false
		_alpha = move_toward(_alpha, _target, delta * (3.0 if _aborted else 0.9))
		for i in _sprs.size():
			var sp: Sprite2D = _sprs[i]
			sp.modulate.a = _alpha * (0.82 + 0.18 * sin(_t * 9.0 + i * 2.1))
			sp.position = _base[i] + Vector2(sin(_t * 1.3 + i) * 0.6, sin(_t * 1.7 + i * 1.4) * 1.2)
		_light.energy = _alpha * 0.9
		if played and _alpha <= 0.0 and _target <= 0.0:
			set_process(false)
	func _play() -> void:
		_gen += 1
		var my_gen := _gen
		played = true
		Prog.flags["echo_" + id] = true
		Audio.sfx("glitch", -14.0)
		Audio.sfx("bell_1", -16.0)
		_target = 0.7
		var lines: Array = Lore.GHOST_ECHOES[id]
		await get_tree().create_timer(0.8).timeout
		if _aborted or my_gen != _gen:
			return
		for ln in lines:
			if not is_inside_tree():
				return
			if _aborted or my_gen != _gen:
				return
			var txt := G.L(ln[1])
			var dur := clampf(txt.length() * 0.055, 2.4, 5.0)
			world.hud.subtitle(G.L(ln[0]), txt, dur, Color(0.68, 0.86, 1.0))
			await get_tree().create_timer(dur + 0.7).timeout
		if _aborted or my_gen != _gen:
			return
		_target = 0.0
		for sp in _sprs:
			Fx.burst((sp as Sprite2D).global_position + Vector2(0, -14), Color(0.55, 0.8, 1.0), 10, 30.0, 1.0, "fx_soft", 60.0, Vector2.UP, 0.5, true)
		Prog.add_ecos(25)
		G.pickup("icon_memory", G.L(["Eco del pasado", "Echo of the past"]) + "  +25", Color(0.68, 0.86, 1.0))
		var seen_e := 0
		for k in Lore.GHOST_ECHOES.keys():
			if Prog.flags.get("echo_" + k, false):
				seen_e += 1
		Ach.set_max("echoes", seen_e)
		if _all_echoes():
			Prog.achieve("echoes")
			world.bcast("_open_cadalso", [true])
	func _all_echoes() -> bool:
		for k in Lore.GHOST_ECHOES.keys():
			if not Prog.flags.get("echo_" + k, false):
				return false
		return true


class CornerWeb extends Node2D:
	## Telaraña de esquina: hilos radiales y arcos que se mecen con la corriente
	var dir := 1.0
	var radius := 14.0
	var _t := 0.0
	func _ready() -> void:
		_t = randf() * 10.0
	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0:
			queue_redraw()
	func _draw() -> void:
		var col := Color(0.86, 0.84, 0.92, 0.22)
		var n := 5
		var sway := sin(_t * 1.3) * 0.8
		var ends: Array = []
		for i in n:
			var a := lerpf(0.05, PI / 2.0 - 0.05, float(i) / float(n - 1))
			var e := Vector2(cos(a) * dir, sin(a)) * radius
			ends.append(e)
			draw_line(Vector2.ZERO, e, col, 1.0)
		for ring in [0.35, 0.6, 0.85]:
			for i in n - 1:
				var p0: Vector2 = ends[i] * ring
				var p1: Vector2 = ends[i + 1] * ring
				var mid := (p0 + p1) * 0.5 * 0.88 + Vector2(0, sway * ring)
				draw_line(p0, mid, col, 1.0)
				draw_line(mid, p1, col, 1.0)
		draw_circle(ends[2] * 0.55 + Vector2(0, sway * 0.6 + 2.0), 1.2, Color(0.1, 0.06, 0.1, 0.8))


class FallenAngel extends Node2D:
	## Esqueleto de ángel tendido en el suelo con las alas abiertas y plumas sueltas
	var seed_v := 0
	func _draw() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = seed_v
		var flip := 1.0 if r.randf() < 0.5 else -1.0
		var bone := Color(0.66, 0.62, 0.58)
		var bone_d := Color(0.44, 0.4, 0.4)
		var ink := Color(0.08, 0.04, 0.08, 0.9)
		var feather := Color(0.72, 0.7, 0.76) if r.randf() < 0.7 else Color(0.3, 0.26, 0.34)
		# mancha y sombra bajo el cuerpo
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 15.0, Color(0, 0, 0, 0.22))
		# tendido en el suelo: girado 90º y aplastado por la perspectiva
		var m := Transform2D(Vector2(0, 0.62 * flip), Vector2(-flip, 0), Vector2.ZERO)
		draw_set_transform_matrix(m)
		# alas abiertas: huesos y plumas
		for side in [-1.0, 1.0]:
			var root := Vector2(side * 2.0, -1.0)
			var tip := root + Vector2(side * r.randf_range(13, 17), r.randf_range(-7, -3))
			var mid := root.lerp(tip, 0.5) + Vector2(0, -3)
			for k in 6:
				var q := root.lerp(tip, 0.25 + k * 0.13) + Vector2(0, -1)
				var fl := Vector2(side * 2.0, r.randf_range(4.0, 7.0))
				draw_colored_polygon(PackedVector2Array([q, q + fl + Vector2(side * 1.5, 0), q + fl * 0.6 + Vector2(-side * 1.5, 1)]), feather.darkened(0.15 * (k % 2)))
			draw_line(root, mid, ink, 2.6)
			draw_line(mid, tip, ink, 2.2)
			draw_line(root, mid, bone_d, 1.4)
			draw_line(mid, tip, bone_d, 1.2)
		# cuerpo: columna, costillas, brazos y piernas
		draw_line(Vector2(0, -3), Vector2(0, 6), bone, 1.5)
		for k in 3:
			var y := -1.0 + k * 1.8
			draw_line(Vector2(-3, y), Vector2(3, y), bone_d, 1.0)
		draw_line(Vector2(-1, 6), Vector2(-3 * flip, 11), bone, 1.2)
		draw_line(Vector2(1, 6), Vector2(4 * flip, 10), bone, 1.2)
		draw_line(Vector2(-3, -2), Vector2(-7, 2 + r.randf_range(-1, 2)), bone, 1.0)
		draw_line(Vector2(3, -2), Vector2(8, r.randf_range(-1, 3)), bone, 1.0)
		# cráneo con aureola apagada
		var sk := Vector2(flip * 0.5, -6)
		draw_circle(sk, 3.2, ink)
		draw_circle(sk, 2.5, bone)
		draw_rect(Rect2(sk + Vector2(-1.5, -0.5), Vector2(1, 1)), ink)
		draw_rect(Rect2(sk + Vector2(0.5, -0.5), Vector2(1, 1)), ink)
		if r.randf() < 0.6:
			draw_arc(sk + Vector2(0, -4), 4.0, 0.0, TAU, 14, Color(0.7, 0.6, 0.3, 0.6), 1.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# plumas sueltas alrededor
		for k in 5:
			var fp := Vector2(r.randf_range(-20, 20), r.randf_range(-8, 12))
			var fa := r.randf() * TAU
			var dv := Vector2(cos(fa), sin(fa))
			draw_line(fp - dv * 2.0, fp + dv * 2.0, feather.darkened(0.2), 1.0)
		# espada clavada (a veces)
		if r.randf() < 0.45:
			var sp := Vector2(flip * r.randf_range(9, 13), r.randf_range(4, 9))
			draw_line(sp + Vector2(1, 1), sp + Vector2(1, -13), Color(0, 0, 0, 0.3), 1.0)
			draw_line(sp, sp + Vector2(0, -12), Color(0.7, 0.72, 0.8), 1.5)
			draw_line(sp + Vector2(-3, -9), sp + Vector2(3, -9), Color(0.6, 0.48, 0.3), 1.5)
			draw_line(sp + Vector2(0, -9), sp + Vector2(0, -13), Color(0.45, 0.3, 0.25), 1.5)


class NpcLife extends Node2D:
	## Gesto propio de cada PNJ (y el objeto con el que trabaja)
	var kind := ""
	var world: Node
	var _t := 0.0
	var _next := 1.0
	func _ready() -> void:
		_t = randf() * 3.0
	func _process(delta: float) -> void:
		_t += delta
		_next -= delta
		if _next <= 0.0:
			_act()
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()
	func _near() -> bool:
		var lp: Node2D = world.local_player() if world else null
		return lp != null and lp.global_position.distance_to(global_position) < 140.0
	func _act() -> void:
		match kind:
			"brenna":
				_next = randf_range(1.3, 2.0)
				Fx.burst(global_position + Vector2(9, 0), Color(1, 0.7, 0.3), 7, 70.0, 0.35, "fx_px", 70.0, Vector2.UP, 0.8, true, Vector2(0, 140))
				if _near():
					Audio.sfx("parry", -26.0, 0.2)
			"ozias":
				_next = randf_range(2.0, 3.2)
				Fx.burst(global_position + Vector2(10, -8), Color(0.4, 1.0, 1.0), 3, 14.0, 1.2, "fx_soft", 30.0, Vector2.UP, 0.35, true)
			"nyx":
				_next = randf_range(2.5, 4.0)
				Fx.burst(global_position + Vector2(10, -2), Color(1, 0.85, 0.3), 2, 30.0, 0.5, "fx_px", 40.0, Vector2.UP, 0.8, true, Vector2(0, 160))
			"velaria":
				_next = randf_range(3.0, 4.5)
				Fx.burst(global_position + Vector2(-11, -14), Color(1, 0.5, 0.35), 2, 10.0, 1.0, "fx_soft", 20.0, Vector2.UP, 0.3, true)
			"carto", "ilse":
				_next = randf_range(3.0, 5.0)
	func _draw() -> void:
		var ink := Color(0.08, 0.04, 0.08)
		match kind:
			"brenna":
				# yunque con la pieza al rojo
				var a := Vector2(9, 10)
				draw_set_transform(a + Vector2(0, 2), 0.0, Vector2(1.0, 0.45))
				draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.3))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_rect(Rect2(a + Vector2(-3, -4), Vector2(6, 5)), ink)
				draw_rect(Rect2(a + Vector2(-2, -4), Vector2(4, 4)), Color(0.32, 0.3, 0.36))
				draw_colored_polygon(PackedVector2Array([a + Vector2(-8, -9), a + Vector2(7, -9), a + Vector2(9, -7), a + Vector2(5, -5), a + Vector2(-5, -5), a + Vector2(-8, -7)]), ink)
				draw_colored_polygon(PackedVector2Array([a + Vector2(-7, -8), a + Vector2(6, -8), a + Vector2(7, -7), a + Vector2(4, -6), a + Vector2(-4, -6), a + Vector2(-7, -7)]), Color(0.42, 0.4, 0.48))
				draw_line(a + Vector2(-6, -8), a + Vector2(5, -8), Color(0.62, 0.6, 0.7), 1.0)
				var glow := 0.6 + 0.4 * sin(_t * 3.0)
				draw_rect(Rect2(a + Vector2(-2, -10), Vector2(5, 2)), Color(1, 0.45 + 0.2 * glow, 0.15))
			"carto":
				# mesa con el mapa a medio dibujar
				var m := Vector2(-15, -2)
				draw_rect(Rect2(m + Vector2(-7, -6), Vector2(14, 9)), ink)
				draw_rect(Rect2(m + Vector2(-6, -5), Vector2(12, 7)), Color(0.85, 0.78, 0.6))
				for k in 4:
					draw_line(m + Vector2(-5 + k * 3, -4 + (k % 2) * 2), m + Vector2(-3 + k * 3, -2 - (k % 2)), Color(0.45, 0.32, 0.22), 1.0)
				var tip := m + Vector2(2 + sin(_t * 2.0) * 2.0, -3 + cos(_t * 2.6) * 1.0)
				draw_line(tip, tip + Vector2(3, -5), Color(0.95, 0.95, 1.0), 1.0)
			"ozias":
				# runas que flotan sobre su mano
				for k in 3:
					var ph := _t * 0.8 + k * 2.1
					var rp := Vector2(10 + sin(ph) * 4.0, -16 - fmod(ph * 6.0, 14.0))
					var al := 1.0 - fmod(ph * 6.0, 14.0) / 14.0
					draw_rect(Rect2(rp, Vector2(3, 1)), Color(0.4, 1.0, 1.0, al))
					draw_rect(Rect2(rp + Vector2(1, -1), Vector2(1, 3)), Color(0.4, 1.0, 1.0, al))
			"nyx":
				# pila de monedas y una que gira
				var cpos := Vector2(11, 0)
				for k in 3:
					draw_rect(Rect2(cpos + Vector2(-3, -1 - k * 2), Vector2(6, 2)), ink)
					draw_rect(Rect2(cpos + Vector2(-2, -1 - k * 2), Vector2(4, 1)), Color(1, 0.8, 0.3))
				var w := absf(cos(_t * 4.0)) * 3.0
				draw_rect(Rect2(cpos + Vector2(-w / 2.0, -12 - absf(sin(_t * 2.0)) * 3.0), Vector2(maxf(w, 1.0), 3)), Color(1, 0.88, 0.4))
			"velaria":
				# vela votiva
				var v := Vector2(-11, -2)
				draw_rect(Rect2(v + Vector2(-2, -8), Vector2(4, 8)), ink)
				draw_rect(Rect2(v + Vector2(-1, -8), Vector2(2, 7)), Color(0.9, 0.86, 0.8))
				var fl := sin(_t * 11.0) * 0.6
				draw_circle(v + Vector2(fl, -11), 2.0, Color(1, 0.55, 0.25))
				draw_circle(v + Vector2(fl, -11), 1.0, Color(1, 0.95, 0.7))
				draw_circle(v + Vector2(0, -11), 7.0, Color(1, 0.5, 0.25, 0.08))
			"ilse":
				# ovillo de hilo dorado y aguja que va y viene
				var y := Vector2(-12, 0)
				draw_circle(y, 3.0, ink)
				draw_circle(y, 2.2, Color(1, 0.85, 0.4))
				var np := y + Vector2(3 + sin(_t * 3.0) * 4.0, -6 + cos(_t * 3.0) * 2.0)
				draw_line(y + Vector2(1, -1), np, Color(1, 0.85, 0.4, 0.8), 1.0)
				draw_line(np, np + Vector2(2, -2), Color(0.9, 0.9, 1.0), 1.0)


class HealZone extends Node2D:
	## Anillo de luz en el suelo que cura poco a poco a los jugadores que estén dentro
	var dur := 3.0
	var radius := 36.0
	var amount := 10.0
	var world: Node
	var partner := false
	var _t := 0.0
	var _tick := 0.0
	func _ready() -> void:
		z_index = -3
		var l := PointLight2D.new()
		l.texture = Fx.tex("light")
		l.color = Color(1, 0.85, 0.5)
		l.texture_scale = radius / 40.0
		l.energy = 0.8
		add_child(l)
		Fx.ring(global_position, 4.0, radius, Color(1, 0.9, 0.5), 0.4, 3.0)
	func _process(delta: float) -> void:
		_t += delta
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.5 if dur > 1.0 else 99.0
			var share := amount / maxf(1.0, dur / 0.5) if dur > 1.0 else amount
			for p in world.local_players():
				if p.is_alive() and p.global_position.distance_to(global_position) < radius:
					var before: float = p.hp
					p.hp = min(Prog.max_hp(), p.hp + share)
					Fx.burst(p.global_position + Vector2(0, -6), Color(1, 0.9, 0.5), 4, 30.0, 0.6, "fx_soft", 60.0, Vector2.UP, 0.35, true)
					if p.hp - before >= 1.0:
						Fx.text(p.global_position + Vector2(0, -20), "+%d" % int(p.hp - before), Color(0.6, 1.0, 0.6), 8)
						if partner:
							Ach.add("coop_heal", p.hp - before)
		if _t > dur:
			modulate.a -= delta * 3.0
			if modulate.a <= 0.0:
				queue_free()
		queue_redraw()
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, radius, Color(1, 0.85, 0.45, 0.12))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1, 0.9, 0.55, 0.8), 2.0)
		draw_arc(Vector2.ZERO, radius * 0.7, _t * 1.5, _t * 1.5 + PI * 1.4, 30, Color(1, 0.95, 0.7, 0.5), 1.0)
		for k in 6:
			var a := _t * 0.8 + TAU * k / 6.0
			draw_circle(Vector2.from_angle(a) * radius * 0.85, 2.0, Color(1, 0.95, 0.7, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k in 4:
			var fy := -fmod(_t * 20.0 + k * 9.0, 30.0)
			draw_rect(Rect2(Vector2(sin(_t + k * 1.7) * radius * 0.5, fy), Vector2(1, 3)), Color(1, 0.95, 0.7, 0.6 * (1.0 + fy / 30.0)))

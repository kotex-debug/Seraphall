class_name Enemy
extends CharacterBody2D
## Enemigo genérico. La IA corre en el anfitrión; los ataques (perform) se reproducen en todos
## los clientes y cada cliente comprueba los golpes solo contra su propio jugador.

const TYPES := {
	"hueco": {"sheet": "enemy_hueco", "fw": 32, "fh": 32, "hp": 48.0, "speed": 64.0, "radius": 7.0, "dmg": 14.0, "poise": 32.0,
		"ecos": 28, "aggro": 150.0, "range": 30.0, "cd": 1.1, "off": -14.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"acolito": {"sheet": "enemy_acolito", "fw": 32, "fh": 32, "hp": 36.0, "speed": 52.0, "radius": 7.0, "dmg": 12.0, "poise": 14.0,
		"ecos": 38, "aggro": 190.0, "range": 160.0, "cd": 2.0, "off": -14.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [0, 4, 7.0], "attack": [1, 3, 6.0], "dead": [2, 1]}},
	"planidera": {"sheet": "enemy_planidera", "fw": 32, "fh": 32, "hp": 44.0, "speed": 42.0, "radius": 7.0, "dmg": 14.0, "poise": 18.0,
		"ecos": 46, "aggro": 200.0, "range": 175.0, "cd": 2.8, "off": -16.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"penitente": {"sheet": "enemy_penitente", "fw": 32, "fh": 32, "hp": 70.0, "speed": 46.0, "radius": 8.0, "dmg": 20.0, "poise": 34.0,
		"ecos": 58, "aggro": 190.0, "range": 120.0, "cd": 2.4, "off": -14.0,
		"anims": {"idle": [0, 4, 4.0], "walk": [1, 4, 7.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"bestia": {"sheet": "enemy_bestia", "fw": 38, "fh": 28, "hp": 78.0, "speed": 78.0, "radius": 10.0, "dmg": 20.0, "poise": 36.0,
		"ecos": 48, "aggro": 170.0, "range": 140.0, "cd": 2.2, "off": -12.0,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 10.0], "attack": [2, 2, 10.0], "dead": [3, 1]}},
	"guardia": {"sheet": "enemy_guardia", "fw": 32, "fh": 32, "hp": 95.0, "speed": 50.0, "radius": 8.0, "dmg": 18.0, "poise": 55.0,
		"ecos": 62, "aggro": 160.0, "range": 120.0, "cd": 1.5, "off": -14.0, "shield": true,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"custodio": {"sheet": "enemy_custodio", "fw": 48, "fh": 48, "hp": 560.0, "speed": 60.0, "radius": 12.0, "dmg": 24.0, "poise": 120.0,
		"ecos": 650, "aggro": 260.0, "range": 150.0, "cd": 1.25, "off": -20.0, "elite": true, "title": "custodio_title",
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 7.0], "attack": [2, 3, 7.0], "dead": [3, 1]}},
	"carcelero": {"sheet": "enemy_carcelero", "fw": 40, "fh": 40, "hp": 680.0, "speed": 46.0, "radius": 14.0, "dmg": 28.0, "poise": 130.0,
		"ecos": 650, "aggro": 170.0, "range": 70.0, "cd": 1.4, "off": -18.0, "boss": true, "title": "boss_carcelero",
		"anims": {"idle": [0, 4, 4.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"choir": {"sheet": "boss_singer", "fw": 26, "fh": 36, "hp": 1150.0, "speed": 42.0, "radius": 42.0, "dmg": 20.0, "poise": 170.0,
		"ecos": 1800, "aggro": 320.0, "range": 260.0, "cd": 1.3, "off": -20.0, "boss": true, "title": "boss_choir",
		"anims": {"idle": [0, 4, 6.0], "walk": [0, 4, 6.0], "attack": [0, 4, 8.0], "dead": [0, 0]}},
	"sombra": {"sheet": "fx_soft", "fw": 32, "fh": 32, "hp": 240.0, "speed": 96.0, "radius": 7.0, "dmg": 22.0, "poise": 70.0,
		"ecos": 0, "aggro": 230.0, "range": 150.0, "cd": 0.95, "off": -14.0,
		"anims": {"idle": [0, 4, 6.0], "walk": [1, 6, 11.0], "attack": [2, 3, 10.0], "dead": [3, 1]}},
	# v0.8: batallas secretas
	"verdugo": {"sheet": "fx_soft", "fw": 32, "fh": 32, "hp": 1500.0, "speed": 95.0, "radius": 8.0, "dmg": 24.0, "poise": 190.0,
		"ecos": 3500, "aggro": 400.0, "range": 160.0, "cd": 0.85, "off": -14.0, "boss": true, "title": "boss_verdugo",
		"anims": {"idle": [0, 4, 6.0], "walk": [1, 6, 11.0], "attack": [2, 3, 10.0], "dead": [3, 1]}},
	"coloso": {"sheet": "fx_soft", "fw": 32, "fh": 32, "hp": 2600.0, "speed": 0.0, "radius": 22.0, "dmg": 30.0, "poise": 99999.0,
		"ecos": 5000, "aggro": 900.0, "range": 900.0, "cd": 1.35, "off": -10.0, "boss": true, "title": "boss_coloso",
		"anims": {"idle": [0, 1, 1.0], "walk": [0, 1, 1.0], "attack": [0, 1, 1.0], "dead": [0, 1]}},
	# ---- Estrato II: Bosque de Plumas Muertas
	"musgoso": {"sheet": "enemy_musgoso", "ai": "hueco", "fw": 32, "fh": 32, "hp": 72.0, "speed": 66.0, "radius": 7.0, "dmg": 18.0, "poise": 40.0,
		"ecos": 62, "aggro": 160.0, "range": 30.0, "cd": 1.0, "off": -14.0, "light": Color(0.6, 1.0, 0.85),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"nidal": {"sheet": "enemy_nidal", "ai": "acolito", "proj": "feather", "fw": 32, "fh": 32, "hp": 58.0, "speed": 54.0, "radius": 7.0, "dmg": 16.0, "poise": 18.0,
		"ecos": 72, "aggro": 200.0, "range": 165.0, "cd": 1.8, "off": -14.0, "light": Color(0.85, 1.0, 0.7),
		"anims": {"idle": [0, 4, 5.0], "walk": [0, 4, 7.0], "attack": [1, 3, 6.0], "dead": [2, 1]}},
	"espino": {"sheet": "enemy_espino", "ai": "planidera", "fw": 32, "fh": 32, "hp": 64.0, "speed": 44.0, "radius": 7.0, "dmg": 18.0, "poise": 22.0,
		"ecos": 80, "aggro": 200.0, "range": 175.0, "cd": 2.5, "off": -16.0, "light": Color(0.85, 1.0, 0.5), "tear": Color(0.75, 1.0, 0.5),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"garza": {"sheet": "enemy_garza", "ai": "bestia", "fw": 38, "fh": 28, "hp": 108.0, "speed": 86.0, "radius": 10.0, "dmg": 24.0, "poise": 44.0,
		"ecos": 86, "aggro": 180.0, "range": 150.0, "cd": 2.0, "off": -12.0, "light": Color(0.6, 1.0, 0.95),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 10.0], "attack": [2, 2, 10.0], "dead": [3, 1]}},
	"lacrima": {"sheet": "enemy_lacrima", "ai": "planidera", "fw": 32, "fh": 32, "hp": 950.0, "speed": 48.0, "radius": 12.0, "dmg": 22.0, "poise": 120.0,
		"ecos": 1300, "aggro": 300.0, "range": 230.0, "cd": 1.2, "off": -16.0, "elite": true, "title": "lacrima_title", "scale": 1.7, "tears": 6,
		"light": Color(0.7, 1.0, 1.0), "tear": Color(0.8, 1.0, 1.0),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	# ---- Estrato III: Fundición de Halos
	"ascua": {"sheet": "enemy_ascua", "ai": "hueco", "fw": 32, "fh": 32, "hp": 96.0, "speed": 70.0, "radius": 7.0, "dmg": 24.0, "poise": 46.0,
		"ecos": 92, "aggro": 170.0, "range": 30.0, "cd": 0.95, "off": -14.0, "light": Color(1, 0.55, 0.2),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"fundidor": {"sheet": "enemy_fundidor", "ai": "guardia", "fw": 32, "fh": 32, "hp": 160.0, "speed": 52.0, "radius": 8.0, "dmg": 28.0, "poise": 70.0,
		"ecos": 122, "aggro": 170.0, "range": 120.0, "cd": 1.4, "off": -14.0, "shield": true, "light": Color(1, 0.6, 0.25),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"chispero": {"sheet": "enemy_chispero", "ai": "penitente", "fw": 32, "fh": 32, "hp": 112.0, "speed": 50.0, "radius": 8.0, "dmg": 30.0, "poise": 44.0,
		"ecos": 116, "aggro": 200.0, "range": 125.0, "cd": 2.1, "off": -14.0, "light": Color(1, 0.7, 0.3),
		"anims": {"idle": [0, 4, 4.0], "walk": [1, 4, 7.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"forjador": {"sheet": "enemy_forjador", "ai": "acolito", "proj": "dawn", "fw": 32, "fh": 32, "hp": 84.0, "speed": 54.0, "radius": 7.0, "dmg": 24.0, "poise": 22.0,
		"ecos": 106, "aggro": 210.0, "range": 170.0, "cd": 1.7, "off": -14.0, "light": Color(1, 0.5, 0.2),
		"anims": {"idle": [0, 4, 5.0], "walk": [0, 4, 7.0], "attack": [1, 3, 6.0], "dead": [2, 1]}},
	"kronagh": {"sheet": "enemy_kronagh", "ai": "custodio", "fw": 48, "fh": 48, "hp": 1400.0, "speed": 64.0, "radius": 12.0, "dmg": 32.0, "poise": 150.0,
		"ecos": 1900, "aggro": 280.0, "range": 150.0, "cd": 1.1, "off": -20.0, "elite": true, "title": "kronagh_title", "light": Color(1, 0.85, 0.45),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 7.0], "attack": [2, 3, 7.0], "dead": [3, 1]}},
	# ---- Estrato IV: El Trono Vacío
	"cortesano": {"sheet": "enemy_cortesano", "ai": "acolito", "proj": "red", "fw": 32, "fh": 32, "hp": 112.0, "speed": 56.0, "radius": 7.0, "dmg": 30.0, "poise": 26.0,
		"ecos": 142, "aggro": 210.0, "range": 170.0, "cd": 1.6, "off": -14.0, "light": Color(1, 0.85, 0.4),
		"anims": {"idle": [0, 4, 5.0], "walk": [0, 4, 7.0], "attack": [1, 3, 6.0], "dead": [2, 1]}},
	"caballero": {"sheet": "enemy_caballero", "ai": "guardia", "fw": 32, "fh": 32, "hp": 215.0, "speed": 56.0, "radius": 8.0, "dmg": 36.0, "poise": 90.0,
		"ecos": 172, "aggro": 180.0, "range": 125.0, "cd": 1.3, "off": -14.0, "shield": true, "light": Color(0.8, 0.55, 1.0),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 8.0], "dead": [3, 1]}},
	"doncella": {"sheet": "enemy_doncella", "ai": "planidera", "fw": 32, "fh": 32, "hp": 124.0, "speed": 46.0, "radius": 7.0, "dmg": 32.0, "poise": 30.0,
		"ecos": 162, "aggro": 210.0, "range": 180.0, "cd": 2.2, "off": -16.0, "light": Color(1, 0.75, 0.5), "tear": Color(1, 0.8, 0.4), "tears": 4,
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"sabueso": {"sheet": "enemy_sabueso", "ai": "bestia", "fw": 38, "fh": 28, "hp": 172.0, "speed": 94.0, "radius": 10.0, "dmg": 34.0, "poise": 50.0,
		"ecos": 162, "aggro": 190.0, "range": 150.0, "cd": 1.8, "off": -12.0, "light": Color(1, 0.8, 0.3),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 10.0], "attack": [2, 2, 10.0], "dead": [3, 1]}},
	"ysolde": {"sheet": "enemy_ysolde", "ai": "custodio", "fw": 48, "fh": 48, "hp": 2000.0, "speed": 70.0, "radius": 12.0, "dmg": 40.0, "poise": 170.0,
		"ecos": 2700, "aggro": 300.0, "range": 160.0, "cd": 0.95, "off": -20.0, "elite": true, "title": "ysolde_title", "light": Color(0.85, 0.6, 1.0),
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 7.0], "attack": [2, 3, 7.0], "dead": [3, 1]}},
	# ---- Arcontes de los Estratos II-IV
	"orrun": {"sheet": "enemy_orrun", "fw": 64, "fh": 64, "hp": 2500.0, "speed": 82.0, "radius": 18.0, "dmg": 30.0, "poise": 280.0,
		"ecos": 6000, "aggro": 400.0, "range": 220.0, "cd": 1.15, "off": -28.0, "boss": true, "title": "boss_orrun",
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 8.0], "attack": [2, 3, 7.0], "dead": [3, 1]}},
	"vulkaris": {"sheet": "enemy_vulkaris", "fw": 64, "fh": 64, "hp": 3500.0, "speed": 54.0, "radius": 18.0, "dmg": 38.0, "poise": 340.0,
		"ecos": 9000, "aggro": 400.0, "range": 240.0, "cd": 1.2, "off": -28.0, "boss": true, "title": "boss_vulkaris",
		"anims": {"idle": [0, 4, 5.0], "walk": [1, 4, 6.0], "attack": [2, 3, 6.0], "dead": [3, 1]}},
	"azrahel": {"sheet": "boss_seravel", "fw": 52, "fh": 56, "hp": 5400.0, "speed": 80.0, "radius": 13.0, "dmg": 44.0, "poise": 320.0,
		"ecos": 15000, "aggro": 500.0, "range": 220.0, "cd": 1.05, "off": -26.0, "boss": true, "title": "boss_azrahel",
		"anims": {"idle": [0, 6, 7.0], "walk": [0, 6, 9.0], "attack": [1, 3, 8.0], "idle2": [2, 6, 9.0], "attack2": [3, 3, 9.0], "dead": [4, 0]}},
	"seravel": {"sheet": "boss_seravel", "fw": 52, "fh": 56, "hp": 1500.0, "speed": 70.0, "radius": 13.0, "dmg": 24.0, "poise": 200.0,
		"ecos": 3000, "aggro": 400.0, "range": 200.0, "cd": 1.2, "off": -26.0, "boss": true, "title": "boss_seravel",
		"anims": {"idle": [0, 6, 7.0], "walk": [0, 6, 9.0], "attack": [1, 3, 8.0], "idle2": [2, 6, 9.0], "attack2": [3, 3, 9.0], "dead": [4, 0]}},
}

var idx := -1
var type := "hueco"
var ai := "hueco"          # conducta (los enemigos de los Estratos II-IV reutilizan la de uno del I)
var base_sc := 1.0
var cfg: Dictionary
var world: Node
var spawn_pos := Vector2.ZERO
var hp := 10.0
var max_hp := 10.0
var poise := 0.0
var max_poise := 10.0
var body_radius := 7.0
var state := "idle"   # idle | chase | busy | stagger | dead
var anim := "idle"
var facing := 1
var cooldown := 0.0
var stagger_t := 0.0
var last_hit_t := 0.0
var phase := 1
var is_boss := false
var active := true    # los jefes se activan con su escena
var lunge := Vector2.ZERO
var asc := 0              # nivel de Ascensión (revancha)
var dmg_mult := 1.0
var cd_mult := 1.0
var slow_t := 0.0
var rank := 0
var _attack_id := 0
var _net_pos := Vector2.ZERO
var _frame := 0.0
var home_room := ""       # sala de la que nunca sale (los jefes viven en su arena sellada)
var _last_ok := Vector2.ZERO
var scripted := false     # lo mueve un guion (jefe del prólogo): sin IA
var hp_floor := 0.0       # guion: no baja de esta vida hasta que el tutorial lo permita
var sprite: Sprite2D
var shadow: Sprite2D
var _flash_mat: ShaderMaterial
var _hp_bar: Node2D

func setup(p_idx: int, p_type: String, pos: Vector2, p_world: Node) -> void:
	idx = p_idx
	type = p_type
	cfg = TYPES[type]
	ai = str(cfg.get("ai", type))
	base_sc = float(cfg.get("scale", 1.0))
	world = p_world
	spawn_pos = pos
	position = pos
	_net_pos = pos
	name = "E%d" % idx
	is_boss = cfg.get("boss", false)
	active = not is_boss
	rank = Prog.BOSS_INFO.get(type, {}).get("rank", 0)

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	body_radius = cfg.radius
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = body_radius * 0.7
	cs.shape = c
	add_child(cs)
	shadow = Sprite2D.new()
	shadow.texture = Fx.tex("fx_soft")
	shadow.modulate = Color(0, 0, 0, 0.55)
	shadow.scale = Vector2(body_radius / 6.0, body_radius / 14.0)
	shadow.z_index = -1
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.texture = Fx.tex(cfg.sheet)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, cfg.fw, cfg.fh)
	sprite.offset = Vector2(0, cfg.off)
	_flash_mat = Fx.flash_material()
	sprite.material = _flash_mat
	sprite.scale = Vector2.ONE * base_sc
	add_child(sprite)
	shadow.scale *= base_sc
	var cast := Depth3D.CastShadow.new()
	cast.src = sprite
	cast.world = world
	add_child(cast)
	move_child(cast, 0)
	if not is_boss:
		var el := PointLight2D.new()
		el.texture = Fx.tex("light")
		el.color = Color(1, 0.45, 0.3) if ai != "acolito" else Color(0.7, 0.45, 1)
		if cfg.has("light"):
			el.color = cfg.light
		if type == "planidera":
			el.color = Color(0.5, 0.8, 1.0)
		if type == "custodio":
			el.color = Color(1, 0.85, 0.5)
			el.texture_scale = 1.4
		el.texture_scale = 0.5
		el.energy = 0.5
		el.position = Vector2(0, cfg.off)
		add_child(el)
		if not cfg.get("elite", false):
			_hp_bar = HpBar.new()
			_hp_bar.position = Vector2(0, cfg.off * 2 - 6)
			_hp_bar.visible = false
			add_child(_hp_bar)
	reset_state()

func reset_state() -> void:
	var d: Dictionary = world.diff() if world else Prog.diff()
	max_hp = cfg.hp * (1.35 if Net.is_online() else 1.0) * d.hp * (1.0 + 0.35 * asc) * (1.0 + 0.5 * Prog.ng)
	dmg_mult = d.dmg * (1.0 + 0.25 * asc) * (1.0 + 0.3 * Prog.ng)
	cd_mult = d.cd * (1.0 - 0.1 * asc)
	slow_t = 0.0
	hp = max_hp
	max_poise = cfg.poise
	poise = 0.0
	state = "idle"
	phase = 1
	position = spawn_pos
	_net_pos = spawn_pos
	visible = true
	sprite.rotation = 0.0
	_flash_mat.set_shader_parameter("dissolve", 0.0)
	_attack_id += 1
	if _hp_bar:
		_hp_bar.visible = false
	set_physics_process(true)

func is_alive() -> bool:
	return state != "dead"

func is_staggered() -> bool:
	return state == "stagger"

# ====================================================================== bucle
func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	if scripted:
		velocity = velocity.lerp(Vector2.ZERO, 0.2)
		move_and_slide()
		_animate(delta)
		return
	if multiplayer.is_server():
		_server_tick(delta)
	else:
		position = position.lerp(_net_pos, clamp(delta * 12.0, 0.0, 1.0))
	_animate(delta)

func _server_tick(delta: float) -> void:
	cooldown -= delta * (0.6 if slow_t > 0.0 else 1.0)
	slow_t = max(0.0, slow_t - delta)
	last_hit_t += delta
	if last_hit_t > 2.0 and poise > 0.0:
		poise = max(0.0, poise - max_poise * 0.25 * delta)
	# los enemigos solo pelean dentro de su sala: ni te siguen ni aparecen en otra
	var target: Node2D = world.nearest_player_in(home_room, global_position) if home_room != "" else world.nearest_player(global_position)
	match state:
		"idle":
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			if home_room != "" and target == null and global_position.distance_to(spawn_pos) > 10.0:
				velocity = (spawn_pos - global_position).normalized() * cfg.speed * 0.8
			if active and target and (target.global_position.distance_to(global_position) < cfg.aggro or world.room_lock == home_room):
				state = "chase"
				if not is_boss:
					world.bcast("enemy_alert", [idx])
		"chase":
			if target == null or not active:
				state = "idle"
			else:
				_chase(target, delta)
		"busy":
			velocity = velocity.lerp(lunge, 0.35)
			lunge = lunge.lerp(Vector2.ZERO, clamp(delta * 6.0, 0.0, 1.0))
		"stagger":
			stagger_t -= delta
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			if stagger_t <= 0.0:
				state = "chase"
	move_and_slide()
	if home_room != "":
		if world.room_at(global_position) == home_room:
			_last_ok = global_position
		else:
			global_position = _last_ok
			velocity = Vector2.ZERO
			lunge = Vector2.ZERO

func _chase(target: Node2D, delta: float) -> void:
	var to := target.global_position - global_position
	var d := to.length()
	facing = 1 if to.x >= 0.0 else -1
	var want := Vector2.ZERO
	match ai:
		"planidera":
			# flota a media distancia y llora sobre ti
			if d < 90.0:
				want = -to.normalized()
			elif d > 150.0:
				want = to.normalized()
			else:
				want = to.normalized().orthogonal() * (1.0 if (idx % 2) == 0 else -1.0) * 0.4
			if cooldown <= 0.0 and d < cfg.range:
				_trigger("tears", target.global_position)
				return
		"acolito":
			if d < 80.0:
				want = -to.normalized()
			elif d > 130.0:
				want = to.normalized()
			else:
				want = to.normalized().orthogonal() * (1.0 if (idx % 2) == 0 else -1.0) * 0.6
			if cooldown <= 0.0 and d < cfg.range:
				var act := "blink" if d < 55.0 and randf() < 0.6 else "fan"
				_trigger(act, target.global_position)
				return
		_:
			if d > cfg.range * 0.8:
				want = to.normalized()
			if cooldown <= 0.0 and d < cfg.range:
				_trigger(_choose_attack(d), target.global_position)
				return
	# separación entre enemigos
	for e in world.enemies_alive():
		if e != self and e.global_position.distance_to(global_position) < body_radius * 2.2:
			want += (global_position - e.global_position).normalized() * 0.6
	velocity = velocity.lerp(want.limit_length(1.0) * cfg.speed * (0.55 if slow_t > 0.0 else 1.0), clamp(delta * 6.0, 0.0, 1.0))

func _choose_attack(d: float) -> String:
	match ai:
		"hueco":
			return "slash"
		"bestia":
			return "charge" if d > 40.0 else "bite"
		"sombra":
			if d > 70.0 and randf() < 0.45:
				return "dark_lance"
			return "shadow_dash"
		"carcelero":
			if phase == 2 and randf() < 0.4:
				return "triple"
			return "sweep" if d < 50.0 else "slam"
		"guardia":
			return "charge" if d > 45.0 else "slash"
		"penitente":
			return "leap" if d > 38.0 else "slash"
		"custodio":
			if d < 55.0:
				return "sweep" if randf() < 0.6 else "slam"
			var r := randf()
			if r < 0.4:
				return "charge"
			return "fan" if r < 0.7 else "slam"
	return "slash"

func _trigger(act: String, tpos: Vector2) -> void:
	state = "busy"
	velocity = Vector2.ZERO
	world.bcast("enemy_action", [idx, act, tpos, randi()])

# ====================================================================== ataques (todos los clientes)
func perform(act: String, tpos: Vector2, seed: int) -> void:
	if state == "dead":
		return
	_attack_id += 1
	var my_id := _attack_id
	state = "busy"
	var to := tpos - global_position
	facing = 1 if to.x >= 0.0 else -1
	var dir := to.normalized() if to.length() > 0.1 else Vector2.RIGHT
	match act:
		"slash":
			_play("attack", 0)
			_tell(0.45)
			if not await _wait(0.45, my_id): return
			_play("attack", 1)
			Audio.sfx("swing", -4.0)
			if multiplayer.is_server():
				lunge = dir * 190.0
			Fx.slash(global_position + Vector2(0, -8) + dir * 6, dir.angle(), 20.0, 120.0, Color(1, 0.45, 0.3, 0.85), 8.0, 0.18)
			if not await _wait(0.08, my_id): return
			_hit_arc(global_position + Vector2(0, -6), dir.angle(), 30.0, 130.0, cfg.dmg)
			if not await _wait(0.55, my_id): return
		"bite":
			_play("attack", 0)
			_tell(0.35)
			if not await _wait(0.35, my_id): return
			if multiplayer.is_server():
				lunge = dir * 220.0
			Audio.sfx("swing", -4.0)
			if not await _wait(0.1, my_id): return
			_hit_arc(global_position, dir.angle(), 26.0, 100.0, cfg.dmg * 0.8)
			if not await _wait(0.5, my_id): return
		"charge":
			_play("attack", 0)
			Fx.telegraph_line(global_position, dir.angle(), 170.0, 18.0, 0.65)
			_tell(0.65)
			if not await _wait(0.65, my_id): return
			Audio.sfx("dash", 0.0)
			var hit_done := false
			var t := 0.0
			while t < 0.55:
				if multiplayer.is_server():
					velocity = dir * 310.0
					lunge = dir * 310.0
				if randf() < 0.6:
					Fx.burst(global_position, Color(1, 0.6, 0.3, 0.7), 2, 40.0, 0.4, "fx_soft", 40.0, -dir, 0.3, false)
				if not hit_done:
					hit_done = _hit_circle(global_position, body_radius + 8.0, cfg.dmg, dir)
				if not await _wait(0.016, my_id): return
				t += 0.016
			if multiplayer.is_server():
				lunge = Vector2.ZERO
			if not await _wait(0.8, my_id): return
		"fan":
			_play("attack", 0)
			Fx.light_flash(global_position + Vector2(0, -12), Color(0.7, 0.4, 1), 1.0, 0.6, 0.6)
			_tell(0.6, Color(0.8, 0.5, 1))
			if not await _wait(0.6, my_id): return
			_play("attack", 2)
			Audio.sfx("enemy_shot")
			var n := 5 if ai == "custodio" else (3 if phase == 1 else 5)
			if cfg.get("elite", false):
				n += 2
			for i in n:
				var a := dir.angle() + (i - (n - 1) / 2.0) * 0.26
				world.spawn_projectile_local(global_position + Vector2(0, -12), Vector2.from_angle(a) * 125.0, cfg.dmg, str(cfg.get("proj", "orb")), "enemy", 1, 5.0, 3.0, 0)
			if not await _wait(0.6, my_id): return
		"leap":
			# se agacha y salta hacia ti: sube hacia la cámara (crece y se separa de su sombra) y cae con fuerza
			_play("attack", 0)
			_tell(0.5, Color(1, 0.55, 0.3))
			if not await _wait(0.5, my_id): return
			_play("attack", 1)
			Audio.sfx("dash", -6.0, 0.15)
			var dest: Vector2 = global_position + (tpos - global_position).limit_length(115.0)
			var dur := 0.55
			var lt := 0.0
			while lt < dur:
				var k := lt / dur
				sprite.position.y = -sin(k * PI) * 40.0
				sprite.scale = Vector2.ONE * (1.0 + sin(k * PI) * 0.28) * base_sc
				shadow.modulate.a = 0.55 - sin(k * PI) * 0.3
				if multiplayer.is_server():
					lunge = ((dest - global_position) / maxf(dur - lt, 0.06)).limit_length(320.0)
					velocity = lunge
				if not await _wait(0.016, my_id):
					sprite.position.y = 0.0
					return
				lt += 0.016
			sprite.position.y = 0.0
			sprite.scale = Vector2(1.3, 0.75) * base_sc
			shadow.modulate.a = 0.55
			if multiplayer.is_server():
				lunge = Vector2.ZERO
			_play("attack", 2)
			Audio.sfx("slam", -5.0, 0.1)
			G.shake(3.0, 0.2)
			Fx.ring(global_position, 6.0, 30.0, Color(1, 0.6, 0.3), 0.35, 4.0)
			Fx.burst(global_position, Color(0.55, 0.45, 0.45, 0.8), 10, 60.0, 0.7, "fx_soft", 180.0, Vector2.UP, 0.5, false)
			world.get_node("FX").add_child(Depth3D.Debris.new().setup(global_position, 5, Color(0.42, 0.34, 0.38), 0.6))
			_hit_circle(global_position, 22.0, cfg.dmg, Vector2.ZERO)
			if not await _wait(0.75, my_id): return
		"tears":
			# alza el vial y tres lágrimas enormes caen desde lo alto sobre ti (sombra de aviso en el suelo)
			_play("attack", 0)
			Audio.sfx("wail", -9.0, 0.12)
			Fx.light_flash(global_position + Vector2(0, -20), Color(0.5, 0.85, 1.0), 1.0, 0.6, 0.7)
			_tell(0.55, Color(0.55, 0.85, 1.0))
			if not await _wait(0.4, my_id): return
			_play("attack", 1)
			Audio.sfx("charge", -10.0)
			if not await _wait(0.25, my_id): return
			_play("attack", 2)
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = seed
			for i in int(cfg.get("tears", 3)):
				var tp: Vector2 = tpos + (Vector2.ZERO if i == 0 else Vector2.from_angle(rng2.randf() * TAU) * rng2.randf_range(18.0, 34.0 + i * 6.0))
				_drop_tear(tp, 0.55 + i * 0.18)
			if not await _wait(1.0, my_id): return
		"blink":
			Fx.burst(global_position + Vector2(0, -10), Color(0.7, 0.4, 1), 16, 60.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4)
			Audio.sfx("dash", -4.0)
			visible = false
			if not await _wait(0.35, my_id): return
			if multiplayer.is_server():
				var rng := RandomNumberGenerator.new()
				rng.seed = seed
				for tries in 8:
					var p := tpos + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(100.0, 140.0)
					if not world.is_wall_at(p) and not world.is_wall_at(p + Vector2(0, -8)):
						position = p
						_net_pos = p
						break
			visible = true
			Fx.burst(global_position + Vector2(0, -10), Color(0.7, 0.4, 1), 16, 60.0, 0.5, "fx_soft", 180.0, Vector2.UP, 0.4)
			if not await _wait(0.4, my_id): return
		"slam":
			_play("attack", 0)
			Fx.telegraph_circle(tpos, 40.0, 0.85)
			_tell(0.85)
			if not await _wait(0.85, my_id): return
			_play("attack", 1)
			_slam_at(tpos, 40.0, cfg.dmg * 1.15)
			if not await _wait(0.8, my_id): return
		"sweep":
			_play("attack", 0)
			Fx.telegraph_circle(global_position, 60.0, 0.6, Color(1, 0.4, 0.2))
			_tell(0.6)
			if not await _wait(0.6, my_id): return
			_play("attack", 1)
			Audio.sfx("swing_heavy")
			Fx.slash(global_position + Vector2(0, -10), dir.angle(), 46.0, 240.0, Color(1, 0.6, 0.35, 0.9), 16.0, 0.3)
			_hit_circle(global_position, 60.0, cfg.dmg * 0.85, dir)
			if not await _wait(0.7, my_id): return
		"shadow_dash":
			_play("attack", 0)
			Fx.telegraph_line(global_position, dir.angle(), 120.0, 14.0, 0.42, Color(0.7, 0.3, 1.0))
			_tell(0.42, Color(0.7, 0.4, 1.0))
			if not await _wait(0.42, my_id): return
			Audio.sfx("dash", -2.0)
			var hit2 := false
			var t2 := 0.0
			while t2 < 0.22:
				if multiplayer.is_server():
					velocity = dir * 420.0
					lunge = dir * 420.0
				Fx.afterimage(sprite, sprite.global_position, Color(0.5, 0.2, 0.8, 0.6))
				if not hit2:
					hit2 = _hit_circle(global_position, body_radius + 7.0, cfg.dmg * 0.7, dir)
				if not await _wait(0.016, my_id): return
				t2 += 0.016
			if multiplayer.is_server():
				lunge = Vector2.ZERO
				velocity = Vector2.ZERO
			_play("attack", 1)
			Audio.sfx("swing", -2.0)
			Fx.slash(global_position + Vector2(0, -8), dir.angle(), 24.0, 150.0, Color(0.6, 0.3, 1.0, 0.9), 10.0, 0.2)
			_hit_arc(global_position + Vector2(0, -6), dir.angle(), 32.0, 150.0, cfg.dmg)
			if not await _wait(0.5, my_id): return
		"dark_lance":
			_play("attack", 0)
			Fx.light_flash(global_position + Vector2(0, -10), Color(0.6, 0.3, 1.0), 1.0, 0.6, 0.4)
			_tell(0.45, Color(0.7, 0.4, 1.0))
			if not await _wait(0.45, my_id): return
			_play("attack", 2)
			Audio.sfx("lance", -2.0)
			for a in [-0.15, 0.0, 0.15]:
				world.spawn_projectile_local(global_position + Vector2(0, -10), dir.rotated(a) * 230.0, cfg.dmg * 0.8, "orb", "enemy", 1, 5.0, 2.0, 0)
			if not await _wait(0.6, my_id): return
		"triple":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = seed
			var spots := [tpos, tpos + Vector2(rng2.randf_range(-50, 50), rng2.randf_range(-40, 40)), tpos + Vector2(rng2.randf_range(-60, 60), rng2.randf_range(-50, 50))]
			for i in 3:
				Fx.telegraph_circle(spots[i], 34.0, 0.7 + i * 0.35)
			_tell(0.7)
			for i in 3:
				if not await _wait(0.7 if i == 0 else 0.35, my_id): return
				_play("attack", 1)
				_slam_at(spots[i], 34.0, cfg.dmg)
			if not await _wait(0.9, my_id): return
	_end_attack(my_id)

func _end_attack(my_id: int) -> void:
	if my_id != _attack_id or state == "dead":
		return
	if state == "busy":
		state = "chase"
	cooldown = cfg.cd * (0.7 if phase >= 2 else 1.0) * (0.8 if phase >= 3 else 1.0) * cd_mult * randf_range(0.8, 1.25)
	anim = "walk"

func _slam_at(p: Vector2, r: float, dmg: float) -> void:
	Audio.sfx("slam")
	G.shake(5.0, 0.3)
	G.shockwave(p, 0.9, 0.45)
	Fx.scorch(p, r * 0.7)
	Fx.ring(p, 6.0, r * 1.2, Color(1, 0.6, 0.3), 0.4, 6.0)
	Fx.burst(p, Color(1, 0.55, 0.25), 22, 130.0, 0.6, "fx_px", 180.0)
	Fx.burst(p, Color(0.5, 0.45, 0.5, 0.8), 10, 60.0, 0.9, "fx_soft", 180.0, Vector2.UP, 0.6, false)
	Fx.light_flash(p, Color(1, 0.6, 0.3), 1.6, 1.0, 0.35)
	world.get_node("FX").add_child(Depth3D.Debris.new().setup(p, 10 if is_boss else 6, Color(0.42, 0.34, 0.38), 1.0 if is_boss else 0.7))
	_hit_circle(p, r, dmg, Vector2.ZERO)

func _drop_tear(p: Vector2, dur: float) -> void:
	var f := Depth3D.Faller.new()
	f.tex = Fx.tex("proj_orb")
	f.height = 170.0
	f.dur = dur
	f.linger = 0.05
	f.additive = true
	f.modulate = cfg.get("tear", Color(0.55, 0.9, 1.0))
	f.position = p
	f.on_land = _tear_splash.bind(p)
	world.get_node("FX").add_child(f)

func _tear_splash(p: Vector2) -> void:
	Audio.sfx("hit", -12.0, 0.3)
	Fx.ring(p, 4.0, 22.0, Color(0.55, 0.9, 1.0), 0.35, 3.0)
	Fx.burst(p, Color(0.6, 0.9, 1.0), 12, 70.0, 0.5, "fx_px", 180.0, Vector2.UP, 1.0, true, Vector2(0, 120))
	Fx.light_flash(p, Color(0.5, 0.85, 1.0), 1.0, 0.7, 0.3)
	if state != "dead":
		_hit_circle(p, 14.0, cfg.dmg, Vector2.ZERO)

func _wait(t: float, my_id: int) -> bool:
	await get_tree().create_timer(t, false).timeout
	return is_inside_tree() and my_id == _attack_id and state != "dead"

func _tell(dur: float, color := Color(1, 0.3, 0.2)) -> void:
	## Destello de aviso antes del golpe (telegráfico).
	_flash(0.75, color)
	var tw := create_tween()
	tw.tween_method(_set_flash, 0.75, 0.15, dur)
	var mark := Label.new()
	mark.text = "!"
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = color
	ls.outline_size = 3
	ls.outline_color = Color.BLACK
	mark.label_settings = ls
	mark.position = Vector2(-3, cfg.off * 2 - 14)
	add_child(mark)
	var tw2 := mark.create_tween()
	tw2.tween_property(mark, "position:y", mark.position.y - 4, dur * 0.5).set_trans(Tween.TRANS_BACK)
	tw2.tween_interval(dur * 0.5)
	tw2.tween_callback(mark.queue_free)

func _hit_arc(origin: Vector2, ang: float, rng: float, arc_deg: float, dmg: float) -> bool:
	var any := false
	for p in world.local_players():
		if not p.is_alive():
			continue
		var to: Vector2 = p.global_position + Vector2(0, -6) - origin
		if to.length() > rng + 6.0:
			continue
		if abs(wrapf(to.angle() - ang, -PI, PI)) > deg_to_rad(arc_deg / 2.0) and to.length() > 10.0:
			continue
		p.take_hit(dmg * dmg_mult * world.event_mult(), to.normalized(), idx)
		any = true
	return any

func _hit_circle(center: Vector2, r: float, dmg: float, dir: Vector2) -> bool:
	var any := false
	for p in world.local_players():
		if p.is_alive() and p.global_position.distance_to(center) < r + 5.0:
			var d = dir if dir != Vector2.ZERO else (p.global_position - center).normalized()
			p.take_hit(dmg * dmg_mult * world.event_mult(), d, idx)
			any = true
	return any

# ====================================================================== daño (servidor)
func server_apply_damage(dmg: float, dir: Vector2, poise_dmg: float) -> Dictionary:
	if state == "dead" or (is_boss and not active):
		return {}
	# escudo: los golpes de frente rebotan (salvo con la postura rota o por la espalda)
	if cfg.get("shield", false) and state != "stagger" and dir != Vector2.ZERO and dir.x * float(facing) < -0.25:
		dmg *= 0.2
		poise_dmg *= 1.6
		world.bcast("_enemy_blocked", [idx])
	hp = maxf(hp - dmg, hp_floor)
	last_hit_t = 0.0
	if not active and not is_boss:
		active = true  # un enemigo en espera despierta si le golpeas
	var broke := false
	if state != "stagger":
		poise += poise_dmg
		if poise >= max_poise:
			poise = 0.0
			broke = true
	if not is_boss or state != "busy":
		velocity += dir * (90.0 if not is_boss else 20.0)
	return {"hp": hp, "broke": broke, "dead": hp <= 0.0}

func on_hurt(new_hp: float, dmg: float, dir: Vector2, crit: bool, broke: bool) -> void:
	hp = new_hp
	_flash(1.0, Color(1, 1, 1))
	Fx.number(global_position + Vector2(0, cfg.off), dmg, Color(1, 0.85, 0.3) if crit else Color(1, 1, 1), crit)
	Fx.burst(global_position + Vector2(0, cfg.off * 0.6), Color(1, 0.9, 0.7), 8 if not crit else 16, 110.0, 0.35, "fx_px", 50.0, dir)
	Fx.burst(global_position + Vector2(0, cfg.off * 0.6), Color(1, 0.5, 0.2), 4, 60.0, 0.5, "fx_soft", 70.0, dir, 0.3)
	Fx.sparks(global_position + Vector2(0, cfg.off * 0.6), dir if dir != Vector2.ZERO else Vector2.UP, Color(1, 0.7, 0.35), 5 if not crit else 12, 140.0, 90.0)
	sprite.scale = Vector2(1.2, 0.85) * base_sc
	if _hp_bar:
		_hp_bar.visible = true
		_hp_bar.ratio = hp / max_hp
		_hp_bar.queue_redraw()
	if broke:
		_start_stagger()

func _start_stagger() -> void:
	_attack_id += 1
	state = "stagger"
	stagger_t = 1.6 if not is_boss else 2.2
	Fx.text(global_position + Vector2(0, cfg.off), G.T("broken"), Color(1, 0.7, 0.3), 9)
	Fx.ring(global_position + Vector2(0, cfg.off * 0.6), 4.0, 26.0, Color(1, 0.8, 0.3), 0.3, 3.0)
	Audio.sfx("parry", -6.0)

func on_parried() -> void:
	if state == "dead":
		return
	if is_boss:
		poise += max_poise * 0.35
		if poise >= max_poise:
			poise = 0.0
			_start_stagger()
		else:
			_attack_id += 1
			state = "chase"
			cooldown = 1.0
	else:
		_start_stagger()

func apply_shadow_look(l: Dictionary, feathers: int) -> void:
	## La Sombra lleva tu aspecto, tu arma y tus hechizos
	sprite.texture = Look.texture(l, feathers)
	sprite.self_modulate = Color(0.32, 0.12, 0.5)
	var el := PointLight2D.new()
	el.texture = Fx.tex("light")
	el.color = Color(0.6, 0.3, 1.0)
	el.texture_scale = 0.9
	el.energy = 0.8
	el.position = Vector2(0, -10)
	add_child(el)
	set_meta("shadow", true)

func die() -> void:
	if state == "dead":
		return
	if is_boss:
		G.shockwave(global_position + Vector2(0, cfg.off), 2.0, 1.0)
		G.chroma(2.0, 1.0)
	state = "dead"
	_attack_id += 1
	velocity = Vector2.ZERO
	anim = "dead"
	Prog.flags["killed_" + type] = true
	if world and world.local_player() and G.autotest != "flow":
		if not is_boss:
			Prog.achieve("first_blood")
		elif type == "carcelero":
			Prog.achieve("jailer")
		elif type == "choir":
			Prog.achieve("choir")
		elif type == "seravel":
			Prog.achieve("seravel")
	if _hp_bar:
		_hp_bar.visible = false
	Audio.sfx("die")
	Fx.burst(global_position + Vector2(0, cfg.off * 0.5), Color(1, 0.6, 0.3), 24, 100.0, 0.8, "fx_px", 180.0, Vector2.UP)
	Fx.burst(global_position + Vector2(0, cfg.off * 0.5), Color(0.6, 0.85, 1.0), 10, 50.0, 1.2, "fx_soft", 180.0, Vector2.UP, 0.4, true, Vector2(0, -30))
	var row: Array = cfg.anims.dead
	sprite.region_rect = Rect2(row[1] * cfg.fw, row[0] * cfg.fh, cfg.fw, cfg.fh)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_method(_set_dissolve, 0.0, 1.0, 0.9)
	tw.tween_callback(hide)
	# el alma sube hacia la cámara
	if world and not is_boss:
		var soul := Depth3D.Soul.new()
		soul.position = global_position + Vector2(0, -4)
		soul.col = Color(0.6, 0.85, 1.0) if ai != "custodio" else Color(1, 0.9, 0.6)
		world.get_node("FX").add_child(soul)

# ====================================================================== visual
func _play(a: String, frame := -1) -> void:
	anim = a
	if frame >= 0:
		_frame = frame
		var key := a if not (phase == 2 and cfg.anims.has(a + "2")) else a + "2"
		var row: Array = cfg.anims.get(key, cfg.anims.idle)
		sprite.region_rect = Rect2(frame * cfg.fw, row[0] * cfg.fh, cfg.fw, cfg.fh)

func _animate(delta: float) -> void:
	if state == "dead":
		return
	if state != "busy":
		if state == "stagger":
			anim = "idle"
		else:
			anim = "walk" if velocity.length() > 12.0 or (not multiplayer.is_server() and position.distance_to(_net_pos) > 1.0) else "idle"
	var key := anim
	if phase == 2 and cfg.anims.has(anim + "2"):
		key = anim + "2"
	var row: Array = cfg.anims.get(key, cfg.anims.idle)
	if state != "busy" or anim != "attack":
		_frame += delta * row[2]
		var f := int(_frame) % int(row[1])
		sprite.region_rect = Rect2(f * cfg.fw, row[0] * cfg.fh, cfg.fw, cfg.fh)
	sprite.flip_h = facing < 0
	sprite.scale = sprite.scale.lerp(Vector2.ONE * base_sc, clamp(delta * 10.0, 0.0, 1.0))
	if state == "stagger":
		sprite.rotation = sin(Time.get_ticks_msec() * 0.03) * 0.08
		sprite.modulate = Color(1.0, 0.85, 0.6)
	else:
		sprite.rotation = 0.0
		sprite.modulate = Color(0.7, 0.9, 1.3) if slow_t > 0.0 else Color.WHITE
	var fl: float = _flash_mat.get_shader_parameter("flash")
	if fl > 0.0 and state != "busy":
		_flash_mat.set_shader_parameter("flash", max(0.0, fl - delta * 7.0))

func _set_flash(v: float) -> void:
	_flash_mat.set_shader_parameter("flash", v)

func _set_dissolve(v: float) -> void:
	_flash_mat.set_shader_parameter("dissolve", v)

func _flash(a: float, c: Color) -> void:
	_flash_mat.set_shader_parameter("flash", a)
	_flash_mat.set_shader_parameter("flash_color", c)

func net_update(pos: Vector2, fc: int, st: String) -> void:
	_net_pos = pos
	facing = fc
	if state != "dead" and st != "busy" and state != "busy":
		state = st

class HpBar extends Node2D:
	var ratio := 1.0
	func _draw() -> void:
		draw_rect(Rect2(-10, 0, 20, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-9.5, 0.5, 19.0 * ratio, 2), Color(0.9, 0.2, 0.25))

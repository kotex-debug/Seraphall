extends RefCounted
## Rodaje del tráiler con el propio juego: un bot pulsa las mismas teclas que un jugador y cada toma
## queda marcada en el registro ("TAKE|nombre|fotograma inicial|fotograma final"). El montaje lo hace
## tools/make_trailer.sh. Dos formatos:
##   --autotest=trailer   vertical 1080x1920 (TikTok), con textos
##   --autotest=trailerh  panorámico 1920x1080, sin textos (para la película de introducción y la web)
## No se exporta con el juego. Solo se ejecuta con esas dos pruebas.

const SETUP_SPEED := 4.0
const VIEW := Vector2(360, 640)
const T1 := ["hueco", "acolito", "penitente", "guardia", "bestia"]
const T2 := ["musgoso", "nidal", "espino", "garza", "musgoso"]
const T3 := ["ascua", "fundidor", "chispero", "forjador", "ascua"]
const T4 := ["cortesano", "caballero", "doncella", "sabueso", "cortesano"]
const P1 := Vector2(46, 62)
const P2 := Vector2(140, 62)
const P3 := Vector2(240, 60)
const P4 := Vector2(336, 61)

var main: Node
var w
var lp: Player
var portrait := true
var over: CanvasLayer
var immortal := true
var bot := false
var boss: Enemy
var boss_floor := 0.0
var mate: Player
var mate_on := false
var _taps: Array[String] = []
var _atk := 0.0
var _dash := 1.0
var _mate_t := 0.0
var _flip := false
var _dlg := 0.0
var _fill: ColorRect
var _take := ""
var _t0 := 0

func _t(s: float) -> void:
	await main.get_tree().create_timer(s).timeout

# ---------------------------------------------------------------------- control por fotograma
func _tick() -> void:
	var dt: float = main.get_process_delta_time()
	for a in _taps:
		Input.action_release(a)
	_taps.clear()
	if immortal:
		lp.iframes = 9999.0
		lp.hp = Prog.max_hp()
	lp.stamina = 100.0
	lp.light = 100.0
	w.hud.visible = false
	Ach._layer.visible = false
	_dlg -= dt
	if _dlg <= 0.0 and w.dialog.is_open():
		w.dialog._advance()
		_dlg = 0.1
	if boss and is_instance_valid(boss):
		if boss_floor > 0.0:
			boss.hp = maxf(boss.hp, boss.max_hp * boss_floor)
		if _fill:
			_fill.size.x = 300.0 * clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	if bot:
		_play(dt)
	if mate_on:
		_mate_step(dt)

func _tap(a: String) -> void:
	Input.action_press(a)
	_taps.append(a)

func _axis(mv: Vector2) -> void:
	for a in ["left", "right", "up", "down"]:
		Input.action_release(a)
	if mv.x < -0.05:
		Input.action_press("left", -mv.x)
	elif mv.x > 0.05:
		Input.action_press("right", mv.x)
	if mv.y < -0.05:
		Input.action_press("up", -mv.y)
	elif mv.y > 0.05:
		Input.action_press("down", mv.y)

func _target() -> Node2D:
	if boss and is_instance_valid(boss) and boss.is_alive():
		return boss
	var best: Node2D = null
	var bd := 230.0
	for e in w.enemies_alive():
		if e.is_boss:
			continue
		var d: float = e.global_position.distance_to(lp.global_position)
		if d < bd:
			bd = d
			best = e
	return best

## Juega como un jugador: se acerca, rodea, golpea y esquiva
func _play(dt: float) -> void:
	var tgt := _target()
	if tgt == null:
		_axis(Vector2.ZERO)
		return
	var to: Vector2 = tgt.global_position - lp.global_position
	var d := to.length()
	var wpn: Dictionary = Prog.WEAPONS[Prog.equipped]
	var near: float = 90.0 if wpn.get("ranged", false) else float(wpn.range) * 0.85
	if boss and tgt == boss:
		near += 16.0
	var mv := Vector2.ZERO
	if d > near:
		mv = to.normalized()
	elif d < near * 0.5:
		mv = -to.normalized()
	else:
		mv = to.normalized().rotated(PI * 0.5) * 0.55
	_axis(mv)
	_atk -= dt
	if _atk <= 0.0 and d < near + 30.0:
		_tap("attack")
		_atk = 0.15
	_dash -= dt
	if _dash <= 0.0:
		_tap("dash")
		_dash = randf_range(1.3, 2.3)

## El compañero: en una partida real estos datos llegarían por red
func _mate_step(dt: float) -> void:
	var tgt := _target()
	var goal: Vector2 = lp.position + Vector2(-46, 16)
	if tgt:
		goal = tgt.global_position + (tgt.global_position - lp.global_position).normalized().rotated(PI * 0.5) * 40.0
	var np: Vector2 = mate.position.move_toward(goal, 120.0 * dt)
	var vel: Vector2 = (np - mate.position) / maxf(dt, 0.001)
	var aim_to: Vector2 = (tgt.global_position - np) if tgt else Vector2.RIGHT
	mate._net_state(np, vel, aim_to.angle(), "move", "run" if vel.length() > 20.0 else "idle", 0, 0.8, 1 if aim_to.x >= 0.0 else -1, "hammer")
	_mate_t -= dt
	if _mate_t <= 0.0 and tgt and aim_to.length() < 70.0:
		_flip = not _flip
		mate._net_fx("slash", [aim_to.angle(), 36.0, 130.0, false, _flip, false])
		if tgt is Enemy and not (tgt as Enemy).is_boss:
			w.request_damage_enemy(tgt, 40.0, aim_to.normalized(), 1.0, false)
		_mate_t = 0.34

# ---------------------------------------------------------------------- tomas
func _begin(nm: String) -> void:
	Engine.time_scale = 1.0
	_take = nm
	_t0 = Engine.get_frames_drawn()

func _end() -> void:
	print("TAKE|%s|%d|%d" % [_take, _t0, Engine.get_frames_drawn()])
	for c in over.get_children():
		c.queue_free()
	_fill = null
	bot = false
	_axis(Vector2.ZERO)
	Engine.time_scale = SETUP_SPEED

func _setup(pos: Vector2, types: Array, weapon: String, radius := 56.0) -> void:
	w._reset_enemies(true)
	w._trial_reset()
	lp.respawn_at(w.tile_pos(pos.x, pos.y))
	lp.state = "move"
	lp.cutscene = false
	await _t(0.4)
	Prog.equipped = weapon
	lp._update_weapon_sprite()
	for i in types.size():
		w._spawn_trial_enemy(types[i], lp.global_position + Vector2.from_angle(TAU * i / types.size() + 0.5) * radius)
	await _t(0.35)

func _combat(nm: String, pos: Vector2, types: Array, weapon: String, big: String, band: String, secs := 2.8) -> void:
	await _setup(pos, types, weapon)
	_begin(nm)
	_cap(big, band)
	bot = true
	await _t(secs)
	_end()

func _art(pos: Vector2, types: Array, weapon: String, label: String) -> void:
	await _setup(pos, types, weapon, 48.0)
	_begin("art_" + weapon)
	_cap("15 ARMAS", label)
	await _t(0.12)
	lp.art_cd = 0.0
	lp.state = "move"
	lp._cast_art()
	await _t(0.9)
	bot = true
	await _t(1.2)
	_end()

func _wait_boss(tp: String) -> Enemy:
	var be: Enemy = w._enemy_of(tp)
	var waited := 0.0
	while waited < 40.0 and not (be.active and not lp.cutscene and not w.dialog.is_open()):
		await _t(0.25)
		waited += 0.25
	await _t(1.0)
	return be

func _fight(be: Enemy, nm: String, secs: float, floor_ratio: float, title: String, sub: String) -> void:
	boss = be
	boss_floor = floor_ratio
	lp.state = "move"
	lp.cutscene = false
	_begin(nm)
	_name_card(title, sub)
	bot = true
	await _t(secs)
	_end()

func _kill(be: Enemy) -> void:
	boss = null
	boss_floor = 0.0
	w._server_damage(be.idx, be.max_hp * 2.0, Vector2.RIGHT, 0.0, false)
	await _t(4.5)
	await _t(3.0)

func _cine(kind: String) -> void:
	var cine: Node = preload("res://scripts/ui/boss_cinematic.gd").new()
	cine.setup(kind, 1)
	w.add_child(cine)
	await main.get_tree().process_frame
	if portrait:
		cine.scale = Vector2.ONE * (640.0 / 360.0)
		cine.offset = Vector2((VIEW.x - 640.0 * 640.0 / 360.0) / 2.0, 0.0)
		cine.sub.visible = false
	var ended := [false]
	cine.finished.connect(func() -> void: ended[0] = true)
	_begin("cine_" + kind)
	var waited := 0.0
	while not ended[0] and waited < 16.0:
		await _t(0.1)
		waited += 0.1
	_end()
	Prog.flags["cine_" + kind] = true
	await _t(0.5)

# ---------------------------------------------------------------------- guion de rodaje
func run(p_main: Node, p_world, p_portrait: bool) -> void:
	main = p_main
	w = p_world
	portrait = p_portrait
	lp = w.local_player()
	G.music_volume = 0.0
	Audio.refresh_volume()
	G.combat_mode = 1
	if portrait:
		w.bg_rect.size = VIEW
		w.post_rect.size = VIEW
	over = CanvasLayer.new()
	over.layer = 100
	main.add_child(over)
	Prog.level = 40
	Prog.attr.vigor = 20
	lp.refresh_stats(true)
	for fl in ["ab_lance", "ab_wrath", "ab_art", "ab_nova"]:
		Prog.flags[fl] = true
	for wid in Prog.WEAPONS:
		Prog.weapons[wid] = 5
	w.wflags["seravel_dead"] = true
	main.get_tree().process_frame.connect(_tick)
	Engine.time_scale = SETUP_SPEED
	await _t(1.0)

	# Estrato I
	await _combat("st1", P1, T1, "sword", "VESTÍBULO DE CENIZA", "ESTRATO I")
	await _art(P1, T1, "mangual", "MANGUAL DEL CARCELERO")
	await _art(P1, T1, "reaper", "GUADAÑA DEL SEGADOR")
	await _art(P1, T1, "verdugo", "HOJA DEL VERDUGO")
	# parry de verdad contra el enemigo más cercano
	await _setup(P1, T1, "sword", 34.0)
	_begin("parry")
	_cap("PARRY PERFECTO", "DESVÍA · ATURDE · REPLICA")
	for k in 4:
		await _t(0.45)
		var en := _target()
		if en:
			lp.state = "move"
			lp.stamina = 100.0
			lp.iframes = 0.0
			lp._start_parry()
			lp.take_hit(5.0, (en.global_position - lp.global_position).normalized(), (en as Enemy).idx)
		await _t(0.3)
		_tap("attack")
	await _t(0.4)
	_end()
	await _setup(P1, T1, "seravel", 42.0)
	_begin("wrath")
	_cap("IRA SERÁFICA", "TU PODER DEFINITIVO")
	await _t(0.15)
	lp.wrath = 100.0
	lp.state = "move"
	lp._cast_wrath()
	await _t(2.6)
	_end()
	await _setup(P1, T1, "sword", 70.0)
	_begin("feather")
	_cap("PLUMA DORADA", "ATRAVIESA Y VUELVE A TU MANO")
	for k2 in 3:
		await _t(0.2)
		lp.state = "move"
		lp.light = 100.0
		lp._cast_lance()
		await _t(0.55)
	_end()
	for kind in ["carcelero", "choir", "seravel"]:
		await _cine(kind)

	var ca: Enemy = w._enemy_of("carcelero")
	w._reset_enemies(true)
	w._trial_reset()
	lp.respawn_at(w.tile_pos(49, 40))
	var waited := 0.0
	while w.active_boss != ca and waited < 30.0:
		await _t(0.25)
		waited += 0.25
	await _t(1.2)
	await _fight(ca, "carcelero", 5.0, 0.55, "EL CARCELERO", "GUARDIÁN DE LA LLAVE")
	boss_floor = 0.0
	w._server_damage(ca.idx, ca.max_hp * 0.8, Vector2.RIGHT, 0.0, false)
	await _t(0.5)
	ca.state = "chase"
	ca._cat_t = 0.0
	boss = ca
	boss_floor = 0.03
	_begin("cataclismo")
	_cap("CATACLISMO", "EN CUALQUIER DIFICULTAD")
	bot = true
	await _t(7.0)
	_end()
	await _kill(ca)

	Prog.flags["carcelero_dead"] = true
	w.wflags["carcelero_dead"] = true
	w.set_gate(true)
	w.wflags["choir_dead"] = true
	Prog.flags["choir_dead"] = true
	lp.respawn_at(w.tile_pos(49, 22))
	var se: Enemy = await _wait_boss("seravel")
	await _fight(se, "seravel", 6.0, 0.55, "SERAVEL", "GUARDIANA DE LAS PUERTAS")
	boss_floor = 0.0
	w._server_damage(se.idx, se.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
	await _t(1.6)
	await _fight(se, "seravel2", 8.0, 0.18, "SERAVEL", "JUICIO DEL NIMBO")
	await _kill(se)

	# Estrato II
	w._descend(2)
	await _t(3.0)
	await _combat("st2", P2, T2, "astas", "BOSQUE DE PLUMAS MUERTAS", "ESTRATO II")
	await _art(P2, T2, "astas", "ASTAS DE ORRUN")
	await _art(P2, T2, "bow", "ARCO DE PLUMA")
	await _art(P2, T2, "scythe", "GUADAÑAS GEMELAS")
	await _art(P2, T2, "staff", "BÁCULO DEL ALBA")
	w._reset_enemies(true)
	w._trial_reset()
	lp.respawn_at(w.tile_pos(141, 16))
	var orr: Enemy = await _wait_boss("orrun")
	await _fight(orr, "orrun", 6.0, 0.55, "ORRUN", "EL CIERVO HUECO")
	boss_floor = 0.0
	w._server_damage(orr.idx, orr.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
	await _t(1.6)
	await _fight(orr, "orrun2", 7.0, 0.15, "ORRUN", "EL CIERVO HUECO")
	await _kill(orr)

	# Estrato III y cooperativo
	w._descend(3)
	await _t(3.0)
	await _combat("st3", P3, T3, "yunque", "FUNDICIÓN DE HALOS", "ESTRATO III")
	await _art(P3, T3, "yunque", "MAZA DEL GRAN YUNQUE")
	await _art(P3, T3, "hammer", "MARTILLO DEL JURAMENTO")
	await _art(P3, T3, "fists", "PUÑOS DEL PENITENTE")
	mate = w._spawn_player(77, 2)
	mate.set_look(Look.defaults_p2(), 7)
	mate.iframes = 99999.0
	await _setup(P3, T3, "reaper")
	mate.position = lp.position + Vector2(-40, 18)
	mate_on = true
	_begin("coop")
	_cap("COOPERATIVO", "2 JUGADORES · LAN Y ONLINE")
	bot = true
	await _t(4.0)
	_end()
	await _setup(P3, T3, "sword", 44.0)
	_begin("coop_cross")
	_cap("ALAS CRUZADAS", "DASH CRUZADO: TAJO EN X")
	bot = true
	await _t(0.5)
	w._cross_slash((lp.global_position + mate.global_position) / 2.0, Net.my_id())
	await _t(1.4)
	w._cross_slash((lp.global_position + mate.global_position) / 2.0, Net.my_id())
	await _t(1.2)
	_end()
	mate_on = false
	await _setup(P3, [], "sword")
	mate.position = lp.position + Vector2(34, 6)
	mate._net_state(mate.position, Vector2.ZERO, 0.0, "downed", "idle", 0, 0.0, 1, "hammer")
	await _t(0.3)
	_begin("coop_revive")
	_cap("ATRAPA SU PLUMA", "Y REVÍVELO")
	await _t(1.0)
	mate._net_state(mate.position, Vector2.ZERO, 0.0, "move", "idle", 0, 0.5, 1, "hammer")
	w.on_partner_revived(true)
	await _t(1.8)
	_end()
	mate_on = true
	w._reset_enemies(true)
	w._trial_reset()
	lp.respawn_at(w.tile_pos(240, 16))
	var vu: Enemy = await _wait_boss("vulkaris")
	mate.position = lp.position + Vector2(-40, 14)
	await _fight(vu, "vulkaris", 6.0, 0.55, "VULKARIS", "HERRERO DE AUREOLAS")
	boss_floor = 0.0
	w._server_damage(vu.idx, vu.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
	await _t(1.6)
	await _fight(vu, "vulkaris2", 7.0, 0.15, "VULKARIS", "HERRERO DE AUREOLAS")
	await _kill(vu)
	mate_on = false
	mate.position = lp.position + Vector2(9000, 9000)
	mate._net_state(mate.position, Vector2.ZERO, 0.0, "move", "idle", 0, 0.8, 1, "hammer")

	# Estrato IV
	w._descend(4)
	await _t(3.0)
	await _combat("st4", P4, T4, "corona", "EL TRONO VACÍO", "ESTRATO IV")
	await _art(P4, T4, "corona", "CETRO DEL REY VACÍO")
	await _art(P4, T4, "seravel", "HOJA DE SERAVEL")
	await _art(P4, T4, "choir", "DIAPASÓN DEL CORO")
	if portrait:
		await _title_takes()
	w._reset_enemies(true)
	w._trial_reset()
	lp.respawn_at(w.tile_pos(336, 18))
	var az: Enemy = await _wait_boss("azrahel")
	Prog.equipped = "seravel"
	lp._update_weapon_sprite()
	await _fight(az, "azrahel", 6.0, 0.55, "AZRAHEL", "REY DEL ABISMO")
	boss_floor = 0.0
	w._server_damage(az.idx, az.max_hp * 0.52, Vector2.RIGHT, 0.0, false)
	await _t(1.6)
	await _fight(az, "azrahel2", 7.0, 0.3, "AZRAHEL", "REY DEL ABISMO")
	boss_floor = 0.0
	w._server_damage(az.idx, az.max_hp * 0.25, Vector2.RIGHT, 0.0, false)
	await _t(1.8)
	boss = az
	boss_floor = 0.12
	_begin("hook1")
	bot = true
	_cap_lines(["CADA VEZ", "QUE MUERES..."], UIKit.WHITE)
	await _t(11.0)
	_end()
	# muerte de verdad: la pluma se arranca
	boss_floor = 0.5
	immortal = false
	_begin("hook2")
	bot = false
	_cap_lines(["...TE ARRANCA", "UNA PLUMA."], UIKit.GOLD)
	_feather_row()
	await _t(0.5)
	lp.iframes = 0.0
	lp._die_for_real()
	_rip_feather()
	G.shake(5.0, 0.4)
	await _t(3.5)
	_end()
	print("AUTOTEST_TRAILER_OK")
	main.get_tree().quit()

# ---------------------------------------------------------------------- portada y cierre (solo vertical)
func _cover() -> TextureRect:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://docs/img/portada.webp"))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var ww := VIEW.y * 16.0 / 9.0
	tr.size = Vector2(ww, VIEW.y)
	tr.position = Vector2((VIEW.x - ww) / 2.0, 0.0)
	tr.pivot_offset = Vector2(ww, VIEW.y) / 2.0
	over.add_child(tr)
	tr.create_tween().tween_property(tr, "scale", Vector2.ONE * 1.1, 8.0)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.02, 0.07, 0.35)
	shade.size = VIEW
	over.add_child(shade)
	var feathers := CPUParticles2D.new()
	feathers.texture = load("res://assets/sprites/fx_feather.png")
	feathers.position = Vector2(180, -12)
	feathers.amount = 26
	feathers.lifetime = 7.0
	feathers.preprocess = 7.0
	feathers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	feathers.emission_rect_extents = Vector2(200, 4)
	feathers.direction = Vector2.DOWN
	feathers.spread = 30.0
	feathers.gravity = Vector2(0, 16)
	feathers.initial_velocity_min = 30.0
	feathers.initial_velocity_max = 70.0
	feathers.angular_velocity_min = -160.0
	feathers.angular_velocity_max = 160.0
	over.add_child(feathers)
	return tr

func _logo(y: float) -> Control:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://docs/img/logo.png"))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var ww := 360.0
	var hh := ww * img.get_height() / float(img.get_width())
	tr.size = Vector2(ww, hh)
	tr.position = Vector2(0, y)
	tr.pivot_offset = tr.size / 2.0
	over.add_child(tr)
	_slam(tr, 1.8)
	_flash(0.9, 0.25)
	G.shake(5.0, 0.3)
	return tr

func _title_takes() -> void:
	_begin("logo")
	_cover()
	await _t(0.05)
	_logo(190.0)
	await _t(0.7)
	_band("ALFA FINAL · YA DISPONIBLE", 300.0)
	await _t(2.2)
	_end()
	await _t(0.3)
	_begin("final")
	_cover()
	await _t(0.05)
	_logo(92.0)
	await _t(0.71)
	_band("ALFA FINAL", 200.0)
	await _t(0.71)
	_line("YA DISPONIBLE", 56, 226.0, UIKit.GOLD)
	_flash(0.6, 0.2)
	await _t(0.71)
	_line("GRATIS · WINDOWS · COOP", 24, 292.0, UIKit.WHITE)
	await _t(0.71)
	_line("kotex-debug.github.io/Seraphall", 18, 334.0, UIKit.GOLD_HOT, "body")
	await _t(5.0)
	_end()
	await _t(0.3)

# ---------------------------------------------------------------------- textos (solo vertical)
func _fit(txt: String, size: int, kind: String, room := 336.0) -> int:
	var f := UIKit.font(kind)
	var s := size
	while s > 8 and f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + 12.0 > room:
		s -= 2
	return s

func _line(txt: String, size: int, y: float, col: Color, kind := "title", slam := true) -> UIKit.PixelText:
	var s := _fit(txt, size, kind)
	var p := UIKit.pixel_text(txt, s, kind, col)
	p.align = 1
	p.position = Vector2(0, y)
	p.size = Vector2(VIEW.x, s + 8)
	p.outline = 4
	p.extrude = 3
	p.wave = 0.0
	p.pivot_offset = p.size / 2.0
	over.add_child(p)
	if slam:
		_slam(p, 1.7)
	return p

func _slam(node: Control, from: float) -> void:
	node.scale = Vector2.ONE * from
	node.modulate.a = 0.0
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, 0.06)

func _flash(a: float, dur: float, col := Color.WHITE) -> void:
	var r := ColorRect.new()
	r.color = Color(col, a)
	r.size = VIEW
	over.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, dur)
	tw.tween_callback(r.queue_free)

func _band(txt: String, y: float) -> void:
	var f := UIKit.font("head")
	var s := _fit(txt, 16, "head", 320.0)
	var ww := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + 34.0
	var x := (VIEW.x - ww) / 2.0
	var h := s + 12.0
	var poly := Polygon2D.new()
	poly.color = UIKit.RED
	poly.polygon = PackedVector2Array([Vector2(x + 8, y), Vector2(x + ww + 8, y), Vector2(x + ww - 8, y + h), Vector2(x - 8, y + h)])
	over.add_child(poly)
	var hi := Polygon2D.new()
	hi.color = UIKit.PINK
	hi.polygon = PackedVector2Array([Vector2(x + 8, y), Vector2(x + ww + 8, y), Vector2(x + ww + 6, y + 2), Vector2(x + 6, y + 2)])
	over.add_child(hi)
	var p := UIKit.pixel_text(txt, s, "head", UIKit.WHITE)
	p.align = 1
	p.position = Vector2(0, y + 5)
	p.size = Vector2(VIEW.x, s + 6)
	p.outline = 2
	p.extrude = 0
	p.wave = 0.0
	over.add_child(p)

func _cap(big: String, band: String) -> void:
	if not portrait:
		return
	_line(big, 54, 84.0, UIKit.GOLD)
	if band != "":
		_band(band, 146.0)

func _cap_lines(lines: Array, col: Color) -> void:
	if not portrait:
		return
	for i in lines.size():
		_line(lines[i], 64, 84.0 + i * 58.0, col)

func _name_card(title: String, sub: String) -> void:
	if not portrait:
		return
	_line(title, 56, 418.0, UIKit.WHITE, "title", false)
	_band(sub, 472.0)
	var back := ColorRect.new()
	back.color = Color(0.05, 0.02, 0.07, 0.9)
	back.position = Vector2(30, 503)
	back.size = Vector2(300, 8)
	over.add_child(back)
	_fill = ColorRect.new()
	_fill.color = UIKit.RED
	_fill.position = back.position
	_fill.size = back.size
	over.add_child(_fill)

var _row: Array[TextureRect] = []

func _feather_row() -> void:
	if not portrait:
		return
	var tex: Texture2D = load("res://assets/sprites/icon_feather.png")
	for i in 10:
		var r := TextureRect.new()
		r.texture = tex
		r.size = Vector2(32, 32)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.position = Vector2(20.0 + i * 32.0, 210.0)
		r.pivot_offset = Vector2(16, 16)
		over.add_child(r)
		_row.append(r)

func _rip_feather() -> void:
	if _row.is_empty():
		return
	var r: TextureRect = _row[9]
	r.modulate = Color(1.0, 0.45, 0.45)
	var tw := r.create_tween().set_parallel(true)
	tw.tween_property(r, "position", r.position + Vector2(-40, 280), 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(r, "rotation", 5.0, 1.3)
	tw.tween_property(r, "modulate:a", 0.0, 1.3)
	_flash(0.55, 0.3, UIKit.RED)

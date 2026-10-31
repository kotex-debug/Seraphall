extends CanvasLayer
## Presentación cinematográfica de jefe en VISTA FRONTAL (formato panorámico 2.39:1).
## Plano 1: detrás del jugador, el jefe en penumbra. Plano 2: primer plano, despierta.
## Plano 3: se alza (alas / golpe), nombre en grande. Se puede saltar con Espacio/Esc.

signal finished

var kind := "seravel"
var stage: Node2D
var layers := []           # [Node2D, factor]
var cam_pos := Vector2.ZERO
var zoom := 1.0
var shake := 0.0
var sky: ColorRect
var boss: Node2D
var body: Sprite2D
var eyes: Sprite2D
var halo: Sprite2D
var wing_l: Sprite2D
var wing_r: Sprite2D
var sword: Sprite2D
var ball: Sprite2D
var glow: Sprite2D
var player_back: Sprite2D
var lb_top: ColorRect
var lb_bot: ColorRect
var flash: ColorRect
var sub: Label
var card: Control
var _t := 0.0
var _done := false
var _skippable := false
var _variant := 1
var _cam_tw: Tween

func setup(p_kind: String, p_variant: int) -> void:
	kind = p_kind
	_variant = p_variant

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.03)
	bg.size = Vector2(640, 360)
	add_child(bg)
	sky = ColorRect.new()
	sky.size = Vector2(640, 360)
	var sm := UIKit.mat("title_sky")
	sm.set_shader_parameter("halo_y", 0.22)
	sm.set_shader_parameter("intensity", 0.15)
	sky.material = sm
	add_child(sky)
	stage = Node2D.new()
	add_child(stage)
	_build_stage()
	lb_top = ColorRect.new(); lb_top.color = Color.BLACK; lb_top.size = Vector2(640, 0); add_child(lb_top)
	lb_bot = ColorRect.new(); lb_bot.color = Color.BLACK; lb_bot.size = Vector2(640, 0); lb_bot.position = Vector2(0, 360); add_child(lb_bot)
	sub = UIKit.label("", 15, UIKit.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(600, 18)
	sub.position = Vector2(20, 322)
	sub.modulate.a = 0.0
	add_child(sub)
	flash = ColorRect.new()
	flash.size = Vector2(640, 360)
	flash.color = Color(1, 1, 1, 1)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	_run()

# ====================================================================== escenario
func _layer(factor: float) -> Node2D:
	var n := Node2D.new()
	stage.add_child(n)
	layers.append([n, factor])
	return n

func _spr(path: String, parent: Node, pos := Vector2.ZERO, sc := 2.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.position = pos
	s.scale = Vector2(sc, sc)
	parent.add_child(s)
	return s

func _build_stage() -> void:
	var far := _layer(0.3)
	var fd := StageDeco.new()
	fd.kind = "far_" + kind
	far.add_child(fd)
	var floor_l := _layer(0.8)
	var fl := StageDeco.new()
	fl.kind = "floor_" + kind
	floor_l.add_child(fl)
	var bl := _layer(1.0)
	boss = Node2D.new()
	bl.add_child(boss)
	glow = Sprite2D.new()
	glow.texture = Fx.tex("light")
	glow.material = Fx.add_material()
	glow.scale = Vector2(3.5, 3.5)
	glow.position = Vector2(0, -60)
	glow.modulate = Color(1, 0.8, 0.5, 0.0) if kind == "seravel" else Color(1, 0.4, 0.15, 0.0)
	boss.add_child(glow)
	if kind == "seravel":
		boss.position = Vector2(0, 0)
		wing_l = Sprite2D.new()
		wing_l.texture = load("res://assets/sprites/cinematic/seravel_wing.png")
		wing_l.centered = false
		wing_l.offset = Vector2(-88, -28)
		wing_l.position = Vector2(-14, -54)
		wing_l.scale = Vector2(2, 2)
		boss.add_child(wing_l)
		wing_r = Sprite2D.new()
		wing_r.texture = wing_l.texture
		wing_r.centered = false
		wing_r.flip_h = true
		wing_r.offset = Vector2(-8, -28)
		wing_r.position = Vector2(14, -54)
		wing_r.scale = Vector2(2, 2)
		boss.add_child(wing_r)
		body = _spr("res://assets/sprites/cinematic/seravel_body.png", boss, Vector2(0, 0))
		sword = Sprite2D.new()
		sword.texture = load("res://assets/sprites/cinematic/seravel_sword.png")
		sword.offset = Vector2(0, -36)
		sword.position = Vector2(32, 0)
		sword.scale = Vector2(2, 2)
		sword.rotation = PI
		boss.add_child(sword)
		eyes = _spr("res://assets/sprites/cinematic/seravel_eyes.png", boss, Vector2(0, 0))
		halo = _spr("res://assets/sprites/cinematic/seravel_halo.png", boss, Vector2(0, -102))
		_set_wings(0.0)
	else:
		boss.position = Vector2(0, 6)
		body = _spr("res://assets/sprites/cinematic/carcelero_body.png", boss, Vector2(0, 0))
		ball = Sprite2D.new()
		ball.texture = load("res://assets/sprites/cinematic/carcelero_ball.png")
		ball.offset = Vector2(0, 30)
		ball.position = Vector2(74, -26)
		ball.scale = Vector2(2, 2)
		ball.rotation = 0.3
		boss.add_child(ball)
		eyes = _spr("res://assets/sprites/cinematic/carcelero_eyes.png", boss, Vector2(0, 0))
		halo = Sprite2D.new()
		boss.add_child(halo)
	eyes.material = Fx.add_material()
	eyes.modulate.a = 0.0
	if halo.texture:
		halo.material = Fx.add_material()
		halo.modulate.a = 0.0
	body.modulate = Color(0.22, 0.18, 0.28)
	if wing_l:
		wing_l.modulate = body.modulate
		wing_r.modulate = body.modulate
	if ball:
		ball.modulate = body.modulate
	# partículas: plumas o ceniza
	var pl := _layer(1.2)
	var parts := CPUParticles2D.new()
	parts.position = Vector2(0, -220)
	parts.amount = 30
	parts.lifetime = 7.0
	parts.preprocess = 7.0
	parts.texture = Fx.tex("fx_feather" if kind == "seravel" else "fx_px")
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	parts.emission_rect_extents = Vector2(380, 10)
	parts.direction = Vector2(0.2, 1)
	parts.gravity = Vector2(4, 18)
	parts.initial_velocity_min = 10.0
	parts.initial_velocity_max = 30.0
	parts.angular_velocity_min = -90.0
	parts.angular_velocity_max = 90.0
	parts.scale_amount_min = 1.0
	parts.scale_amount_max = 2.0
	parts.color = Color(1, 1, 1, 0.8) if kind == "seravel" else Color(1, 0.55, 0.25, 0.9)
	pl.add_child(parts)
	var front := _layer(1.7)
	player_back = _spr("res://assets/sprites/cinematic/player_back_p%d.png" % _variant, front, Vector2(-150, 150), 4.0)

func _set_wings(open: float) -> void:
	if wing_l == null:
		return
	wing_l.rotation = lerpf(1.1, 0.0, open)
	wing_r.rotation = -wing_l.rotation
	var s := lerpf(1.2, 2.0, open)
	wing_l.scale = Vector2(s, s)
	wing_r.scale = Vector2(s, s)

func _process(delta: float) -> void:
	_t += delta
	shake = max(0.0, shake - delta * 2.0)
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 8.0
	for l in layers:
		var n: Node2D = l[0]
		var f: float = l[1]
		var z := 1.0 + (zoom - 1.0) * f
		n.scale = Vector2(z, z)
		n.position = (Vector2(320, 180) - cam_pos * f * z + sh * f).round()
	if kind == "seravel" and halo:
		halo.rotation = sin(_t * 0.8) * 0.03
	if ball and _t < 6.0:
		ball.rotation = 0.3 + sin(_t * 1.6) * 0.12

func _unhandled_input(event: InputEvent) -> void:
	if _skippable and not _done and (event.is_action_pressed("dash") or event.is_action_pressed("pause") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_finish()

# ====================================================================== secuencia
func _wait(t: float) -> bool:
	var fast := G.autotest in ["shots", "flow", "host", "join"]
	await get_tree().create_timer(t * (0.15 if fast else 1.0), true, false, true).timeout
	return not _done

func _subtitle(text: String) -> void:
	sub.text = text
	sub.modulate.a = 0.0
	var tw := sub.create_tween()
	tw.tween_property(sub, "modulate:a", 1.0, 0.3)

func _cam_tween() -> Tween:
	if _cam_tw and _cam_tw.is_valid():
		_cam_tw.kill()
	_cam_tw = create_tween().set_parallel(true)
	return _cam_tw

func _cut() -> void:
	flash.color = Color(1, 1, 1, 0.85)
	create_tween().tween_property(flash, "color:a", 0.0, 0.25)
	Audio.sfx("hit_heavy", -10.0, 0.0)

func _run() -> void:
	Audio.stop_music(0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(flash, "color:a", 0.0, 0.5)
	tw.tween_property(lb_top, "size:y", 46.0, 0.8).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lb_bot, "size:y", 46.0, 0.8).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lb_bot, "position:y", 314.0, 0.8).set_trans(Tween.TRANS_CUBIC)
	sub.position.y = 326
	var lines := _lines()
	# ---------------------------------------------------------- plano 1: detrás del jugador
	cam_pos = Vector2(0, 30)
	zoom = 1.0
	var t1 := _cam_tween()
	t1.tween_property(self, "cam_pos", Vector2(0, 0), 3.2).set_trans(Tween.TRANS_SINE)
	t1.tween_property(self, "zoom", 1.15, 3.2).set_trans(Tween.TRANS_SINE)
	Audio.sfx("gate", -8.0, 0.0)
	_skippable = true
	if not await _wait(0.6): return
	_subtitle(lines[0])
	if not await _wait(2.6): return
	# ---------------------------------------------------------- plano 2: primer plano, despierta
	_cut()
	if _cam_tw:
		_cam_tw.kill()
	player_back.visible = false
	var face_y := -82.0 if kind == "seravel" else -88.0
	cam_pos = Vector2(0, face_y)
	zoom = 3.0
	var t2 := _cam_tween()
	t2.tween_property(self, "zoom", 3.4, 3.0).set_trans(Tween.TRANS_SINE)
	t2.tween_property(body, "modulate", Color(0.75, 0.7, 0.8), 1.2)
	if not await _wait(0.8): return
	# ojos
	var te := create_tween()
	te.tween_property(eyes, "modulate:a", 1.0, 0.08)
	te.tween_property(eyes, "modulate:a", 0.6, 0.3)
	te.tween_property(eyes, "modulate:a", 1.0, 0.2)
	Audio.sfx("parry", -4.0, 0.0)
	shake = 0.4
	var gt := create_tween()
	gt.tween_property(glow, "modulate:a", 0.5, 0.4)
	_subtitle(lines[1])
	if not await _wait(0.8): return
	if halo.texture:
		var th := create_tween()
		th.tween_property(halo, "modulate:a", 1.0, 0.15)
		th.tween_property(halo, "scale", Vector2(2.4, 2.4), 0.1)
		th.tween_property(halo, "scale", Vector2(2.0, 2.0), 0.4).set_trans(Tween.TRANS_ELASTIC)
		Audio.sfx("levelup", -8.0, 0.0)
		(sky.material as ShaderMaterial).set_shader_parameter("intensity", 0.6)
	if not await _wait(1.4): return
	# ---------------------------------------------------------- plano 3: se alza
	_cut()
	if _cam_tw:
		_cam_tw.kill()
	cam_pos = Vector2(0, -10)
	zoom = 0.92
	body.modulate = Color.WHITE
	var tb := _cam_tween()
	tb.tween_property(self, "zoom", 1.0, 3.0).set_trans(Tween.TRANS_SINE)
	tb.tween_property(glow, "modulate:a", 0.9, 0.5)
	tb.tween_property(sky.material, "shader_parameter/intensity", 1.2, 1.0)
	if kind == "seravel":
		wing_l.modulate = Color.WHITE
		wing_r.modulate = Color.WHITE
		Audio.sfx("roar", 0.0, 0.0)
		shake = 1.0
		var tw2 := create_tween()
		tw2.tween_method(_set_wings, 0.0, 1.0, 0.9).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_feather_burst()
		var tr := create_tween().set_parallel(true)
		tr.tween_property(boss, "position:y", -18.0, 2.0).set_trans(Tween.TRANS_SINE)
		tr.tween_property(sword, "rotation", -0.35, 0.8).set_delay(0.7).set_trans(Tween.TRANS_BACK)
		tr.tween_property(sword, "position", Vector2(40, -40), 0.8).set_delay(0.7).set_trans(Tween.TRANS_BACK)
	else:
		ball.modulate = Color.WHITE
		Audio.sfx("roar", -2.0, 0.0)
		var tw3 := create_tween()
		tw3.tween_property(ball, "rotation", -2.6, 0.5).set_trans(Tween.TRANS_CUBIC)
		tw3.tween_property(ball, "rotation", 0.6, 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw3.tween_callback(_slam)
	_subtitle(lines[2])
	if not await _wait(1.0): return
	_name_card()
	if not await _wait(3.2): return
	_finish()

func _feather_burst() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(0, -60)
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 60
	p.lifetime = 2.5
	p.texture = Fx.tex("fx_feather")
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 260.0
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.gravity = Vector2(0, 40)
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = Color(1, 0.98, 0.95)
	boss.add_child(p)
	p.emitting = true
	flash.color = Color(1, 0.95, 0.85, 0.6)
	create_tween().tween_property(flash, "color:a", 0.0, 0.5)

func _slam() -> void:
	Audio.sfx("slam", 0.0, 0.0)
	shake = 1.4
	flash.color = Color(1, 0.6, 0.3, 0.35)
	create_tween().tween_property(flash, "color:a", 0.0, 0.3)
	var r := StageDeco.new()
	r.kind = "slam"
	r.position = Vector2(80, 70)
	boss.add_child(r)

func _name_card() -> void:
	card = Control.new()
	card.size = Vector2(640, 360)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var names := {"seravel": ["SERAVEL", G.L(["GUARDIANA DE LAS PUERTAS", "WARDEN OF THE GATES"])],
		"carcelero": [G.L(["EL CARCELERO", "THE JAILER"]), G.L(["GUARDIÁN DE LA LLAVE", "KEEPER OF THE KEY"])]}
	var n: Array = names[kind]
	var title := UIKit.pixel_text(n[0], 56, "logo", UIKit.WHITE)
	title.align = 1
	title.size = Vector2(640, 60)
	title.position = Vector2(0, 222)
	title.appear = 0.0
	title.outline = 8
	title.extrude = 5
	title.extrude_color = UIKit.RED if kind == "seravel" else Color(0.7, 0.3, 0.1)
	title.wave = 1.0
	card.add_child(title)
	var st := UIKit.label(n[1], 8, UIKit.GOLD, "head", 4)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.size = Vector2(640, 12)
	st.position = Vector2(0, 210)
	st.modulate.a = 0.0
	card.add_child(st)
	var line := StageDeco.new()
	line.kind = "nameline"
	line.position = Vector2(320, 284)
	card.add_child(line)
	var tw := create_tween()
	tw.tween_property(title, "appear", float(n[0].length()) + 1.0, 0.5)
	tw.tween_callback(_card_impact.bind(title))
	tw.tween_property(st, "modulate:a", 1.0, 0.4)
	tw.tween_property(title, "shake", 0.0, 0.4)

func _card_impact(title: UIKit.PixelText) -> void:
	title.flash = 1.0
	title.shake = 2.5
	shake = 0.6
	Audio.sfx("hit_heavy", -2.0, 0.0)

func _finish() -> void:
	if _done:
		return
	_done = true
	flash.color = Color(1, 1, 1, 0.0)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 1.0, 0.18)
	tw.tween_callback(_emit_and_free)

func _emit_and_free() -> void:
	set_process(false)
	layers.clear()
	finished.emit()
	var tw := create_tween()
	for c in get_children():
		if c != flash:
			c.queue_free()
	tw.tween_property(flash, "color:a", 0.0, 0.35)
	tw.tween_callback(queue_free)

func _lines() -> Array:
	if kind == "seravel":
		return [G.L(["Otro Desplumado... ¿Cuántos más enviará la Voz antes de entender?", "Another Featherless... How many more will the Voice send before you understand?"]),
			G.L(["Nadie cruza estas puertas. Ni hacia abajo... ni hacia arriba.", "No one passes these gates. Not downward... nor upward."]),
			G.L(["Te concederé lo que todos piden al final. Descanso.", "I will grant you what they all beg for in the end. Rest."])]
	return [G.L(["¿Otra pluma que se cree libre? Aquí todo tiene cadena.", "Another feather that thinks it's free? Here, everything has a chain."]),
		G.L(["La llave es mía. Tus alas... también lo serán.", "The key is mine. Your wings... will be too."]),
		G.L(["¡AL SUELO!", "KNEEL!"])]

class StageDeco extends Node2D:
	var kind := ""
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		match kind:
			"far_seravel", "far_carcelero":
				var col := Color(0.07, 0.03, 0.1)
				# columnas y arcos lejanos
				for i in 9:
					var x := -420.0 + i * 105.0
					if absf(x) < 90:
						continue
					var h := 150.0 + (i % 3) * 20.0
					draw_rect(Rect2(Vector2(x - 9, 60 - h), Vector2(18, h + 60)), col)
					draw_rect(Rect2(Vector2(x - 13, 60 - h), Vector2(26, 8)), col)
				draw_arc(Vector2(-210, -60), 70.0, PI, TAU, 24, col, 10.0)
				draw_arc(Vector2(210, -60), 70.0, PI, TAU, 24, col, 10.0)
				if kind == "far_carcelero":
					for i in 14:
						var cx := -330.0 + i * 50.0
						for j in 10:
							draw_arc(Vector2(cx + sin(t + i) * 2.0, -180 + j * 9), 3.0, 0, TAU, 6, Color(0.25, 0.2, 0.28), 1.5)
			"floor_seravel", "floor_carcelero":
				var hz := 70.0
				var fc := Color(0.12, 0.07, 0.14) if kind == "floor_seravel" else Color(0.14, 0.07, 0.07)
				draw_colored_polygon(PackedVector2Array([Vector2(-500, hz), Vector2(500, hz), Vector2(900, 300), Vector2(-900, 300)]), fc)
				for i in range(-10, 11):
					draw_line(Vector2(i * 40, hz), Vector2(i * 140, 300), Color(1, 1, 1, 0.05), 1.0)
				var y := hz
				var step := 6.0
				while y < 300:
					draw_line(Vector2(-900, y), Vector2(900, y), Color(1, 1, 1, 0.05), 1.0)
					step *= 1.35
					y += step
				var gold := Color(1, 0.75, 0.35, 0.55 + 0.15 * sin(t * 2.0)) if kind == "floor_seravel" else Color(1, 0.4, 0.15, 0.45)
				var c := Vector2(0, 110)
				var pts := PackedVector2Array()
				for k in 65:
					var a := TAU * k / 64.0
					pts.append(c + Vector2(cos(a) * 230.0, sin(a) * 40.0))
				draw_polyline(pts, gold, 2.0)
				var pts2 := PackedVector2Array()
				for k in 65:
					var a2 := TAU * k / 64.0
					pts2.append(c + Vector2(cos(a2) * 150.0, sin(a2) * 26.0))
				draw_polyline(pts2, Color(gold, gold.a * 0.6), 1.0)
				# niebla baja
				for k in 6:
					var fx := fmod(t * 12.0 + k * 140.0, 900.0) - 450.0
					draw_rect(Rect2(Vector2(fx, 90 + k * 6), Vector2(220, 10)), Color(0.6, 0.5, 0.7, 0.04))
			"slam":
				var k2: float = clamp(t / 0.8, 0.0, 1.0)
				draw_arc(Vector2.ZERO, 10.0 + k2 * 220.0, PI, TAU, 40, Color(1, 0.6, 0.3, 1.0 - k2), 4.0)
				draw_arc(Vector2.ZERO, 6.0 + k2 * 140.0, PI, TAU, 40, Color(1, 1, 1, 1.0 - k2), 2.0)
				for i in 16:
					var a3 := PI + PI * i / 15.0
					var d := Vector2.from_angle(a3) * (20.0 + k2 * 120.0)
					draw_rect(Rect2(d.round(), Vector2(3, 3)), Color(0.7, 0.6, 0.6, 1.0 - k2))
			"nameline":
				var g: float = clamp(t * 1.5, 0.0, 1.0)
				var w := 200.0 * g
				draw_rect(Rect2(Vector2(-w, 0), Vector2(w * 2, 2)), UIKit.GOLD)
				UIKit.diamond(self, Vector2(0, 1), 4.0, UIKit.GOLD)
				UIKit.diamond(self, Vector2(-w - 5, 1), 2.0, UIKit.GOLD)
				UIKit.diamond(self, Vector2(w + 5, 1), 2.0, UIKit.GOLD)

class_name Depth3D
extends RefCounted
## Falsa perspectiva 3D al estilo Bloody Hell.
## La cámara "mira desde arriba": lo que es alto se inclina alejándose del centro de la pantalla y lo
## que está hondo (pozos, el abismo) se encoge hacia él. Al moverte, el mundo parece tener volumen.

const CAM_H := 1100.0     # "altura" de la cámara en píxeles: cuanto menor, más exagerada la perspectiva

static func cam_center(n: Node) -> Vector2:
	var vp := n.get_viewport()
	if vp == null:
		return Vector2.ZERO
	var c := vp.get_camera_2d()
	return c.get_screen_center_position() if c else Vector2.ZERO

## Dibuja un polígono solo si es válido (la perspectiva puede retorcer quads muy estrechos).
static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if Geometry2D.triangulate_polygon(pts).is_empty():
		return
	ci.draw_colored_polygon(pts, col)

## Inclina un nodo alto (su origen es la base) según su posición respecto a la cámara.
static func lean(node: Node2D, base: Vector2, cam: Vector2, strength := 1.0) -> void:
	var d := (base - cam) / CAM_H * strength
	node.skew = asin(clampf(d.x, -0.4, 0.4))
	node.scale.y = clampf(1.0 - d.y * 0.9, 0.82, 1.18) * signf(node.scale.y if node.scale.y != 0.0 else 1.0)

## Desplazamiento de un punto a una altura h (positivo = hacia la cámara).
static func lift(base: Vector2, h: float, cam: Vector2) -> Vector2:
	return base + (base - cam) * (h / CAM_H) - Vector2(0, h)

## Inclina el "rig" de un jefe: todo lo que está a la altura del rig se desplaza en perspectiva.
static func lean_rig(rig: Node2D, owner_pos: Vector2, cam: Vector2, height: float, strength := 1.0) -> void:
	var d := (owner_pos - cam) / CAM_H * strength
	rig.skew = asin(clampf(d.x, -0.35, 0.35))
	rig.position.x = d.x * height


class Leaner extends Node:
	## Recorre los objetos altos registrados (pilares, estatuas, órganos) y los inclina cada fotograma.
	var items: Array = []    # [Node2D, fuerza]
	func add(n: Node2D, strength := 1.0) -> void:
		items.append([n, strength])
	func _process(_delta: float) -> void:
		var cam := Depth3D.cam_center(self)
		var half := Vector2(420, 260)
		for it in items:
			var n: Node2D = it[0]
			if not is_instance_valid(n):
				continue
			var p := n.global_position
			if absf(p.x - cam.x) > half.x or absf(p.y - cam.y) > half.y:
				continue
			Depth3D.lean(n, p, cam, it[1])


class Debris extends Node2D:
	## Trozos de roca que saltan con altura real (z), sombra en el suelo y rebote.
	var chunks: Array = []   # [pos, vel, z, vz, rot, vrot, tam, color, vida]
	func setup(pos: Vector2, n: int, col: Color, power := 1.0) -> Debris:
		position = pos
		for i in n:
			var a := randf() * TAU
			var sp := randf_range(30.0, 110.0) * power
			chunks.append([Vector2.ZERO, Vector2(cos(a), sin(a) * 0.6) * sp, 0.0, randf_range(90.0, 220.0) * power, randf() * TAU,
				randf_range(-12.0, 12.0), randf_range(2.0, 4.5), col.darkened(randf_range(0.0, 0.4)), randf_range(1.0, 1.8)])
		return self
	func _process(delta: float) -> void:
		var alive := false
		for c in chunks:
			c[8] -= delta
			if c[8] <= 0.0:
				continue
			alive = true
			c[3] -= 520.0 * delta
			c[2] += c[3] * delta
			if c[2] <= 0.0:
				c[2] = 0.0
				c[3] = -c[3] * 0.35
				c[1] *= 0.55
				c[5] *= 0.5
			c[0] += c[1] * delta
			c[4] += c[5] * delta
		if not alive:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var cam := Depth3D.cam_center(self) - global_position
		for c in chunks:
			if c[8] <= 0.0:
				continue
			var a: float = clampf(c[8] / 0.4, 0.0, 1.0)
			var p: Vector2 = c[0]
			var z: float = c[2]
			# sombra en el suelo (más pequeña cuanto más alto)
			var ss: float = c[6] * clampf(1.0 - z / 160.0, 0.35, 1.0)
			draw_circle(p + Vector2(0, 1), ss, Color(0, 0, 0, 0.35 * a))
			# la roca en el aire, desplazada en perspectiva y algo más grande al acercarse a la cámara
			var q: Vector2 = p + (p - cam) * (z / Depth3D.CAM_H) - Vector2(0, z)
			var sz: float = c[6] * (1.0 + z / 260.0)
			draw_set_transform(q, c[4], Vector2.ONE)
			draw_rect(Rect2(Vector2(-sz / 2, -sz / 2), Vector2(sz, sz)), Color(0.08, 0.05, 0.08, a))
			draw_rect(Rect2(Vector2(-sz / 2 + 1, -sz / 2 + 1), Vector2(sz - 2, sz - 2)), Color(c[7], a))
			draw_rect(Rect2(Vector2(-sz / 2 + 1, -sz / 2 + 1), Vector2(sz - 2, 1)), Color(c[7].lightened(0.35), a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Faller extends Node2D:
	## Algo que cae desde lo alto hacia el suelo con perspectiva: empieza grande y desplazado hacia
	## fuera de la pantalla, y su sombra crece en el punto de impacto hasta que llega.
	var tex: Texture2D
	var region := Rect2()
	var offset := Vector2.ZERO
	var rot := 0.0
	var height := 160.0
	var dur := 0.25
	var t := 0.0
	var additive := false
	var on_land: Callable
	var linger := 1.0
	var _spr: Sprite2D
	var _landed := false
	func _ready() -> void:
		_spr = Sprite2D.new()
		_spr.texture = tex
		if region.size != Vector2.ZERO:
			_spr.region_enabled = true
			_spr.region_rect = region
		_spr.offset = offset
		_spr.rotation = rot
		if additive:
			_spr.material = Fx.add_material()
		add_child(_spr)
		_place()
	func _process(delta: float) -> void:
		t += delta
		if not _landed and t >= dur:
			_landed = true
			if on_land.is_valid():
				on_land.call()
		if _landed and t > dur + linger:
			modulate.a -= delta * 2.5
			if modulate.a <= 0.0:
				queue_free()
		_place()
		queue_redraw()
	func _place() -> void:
		var k := clampf(t / dur, 0.0, 1.0)
		var h := height * (1.0 - k * k)
		var cam := Depth3D.cam_center(self)
		_spr.position = (global_position - cam) * (h / Depth3D.CAM_H) - Vector2(0, h)
		_spr.scale = Vector2.ONE * (1.0 + h / 220.0)
	func _draw() -> void:
		if _landed:
			return
		var k := clampf(t / dur, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 3.0 + 9.0 * k, Color(0, 0, 0, 0.18 + 0.35 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Abyss extends Node2D:
	## Capas del abismo bajo las plataformas: rocas flotantes, columnas rotas, cadenas y restos de alas,
	## cada capa a una profundidad distinta (paralaje real con la cámara) y teñida por la niebla.
	var world: Node
	var layers: Array = []   # [factor, items]
	func _ready() -> void:
		z_index = -14
		var rng := RandomNumberGenerator.new()
		rng.seed = 909
		var W: float = world.MAPW * 16.0
		var H: float = world.MAPH * 16.0
		for li in 3:
			var f: float = [0.86, 0.72, 0.56][li]
			var items := []
			var n: int = [70, 55, 40][li]
			for i in n:
				var p := Vector2(rng.randf_range(-200, W + 200), rng.randf_range(-200, H + 200))
				var kind := rng.randi_range(0, 10)
				items.append([p, kind, rng.randf_range(0.7, 1.4), rng.randi(), rng.randf() * TAU])
			layers.append([f, items])
	func _process(_delta: float) -> void:
		queue_redraw()
	func _giant(cam: Vector2, t: float) -> void:
		## Cada ~45 s un ángel enorme cae muy lejos, por detrás de todo, perdiendo plumas
		var cycle := fmod(t, 45.0)
		if cycle > 14.0:
			return
		var k := cycle / 14.0
		var seed: float = floor(t / 45.0)
		var x := cam.x + sin(seed * 12.9) * 220.0
		var p := Vector2(x + k * 60.0, cam.y - 220.0 + k * 460.0)
		var a := sin(k * PI) * 0.35
		var col := Color(0.12, 0.04, 0.1, a)
		draw_set_transform(p, PI + sin(t * 0.4) * 0.3, Vector2(2.6, 2.6))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -2), Vector2(-16, -10), Vector2(-11, 2), Vector2(-2, 3)]), col)
		draw_colored_polygon(PackedVector2Array([Vector2(2, -2), Vector2(16, -10), Vector2(11, 2), Vector2(2, 3)]), col)
		draw_rect(Rect2(-2, -4, 4, 11), col)
		draw_circle(Vector2(0, -7), 2.6, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for q in 5:
			var fk := fmod(k * 3.0 + q * 0.2, 1.0)
			draw_line(p + Vector2((q - 2) * 14.0, -fk * 60.0), p + Vector2((q - 2) * 14.0 + 3, -fk * 60.0 + 6), Color(0.6, 0.5, 0.55, a * (1.0 - fk)), 2.0)
	func _draw() -> void:
		var cam := Depth3D.cam_center(self)
		var t := Time.get_ticks_msec() / 1000.0
		_giant(cam, t)
		for L in layers:
			var f: float = L[0]
			var fog := 1.0 - f            # cuanto más hondo, más niebla
			for it in L[1]:
				var base: Vector2 = it[0]
				var bob := sin(t * 0.5 + it[4]) * 3.0
				var p: Vector2 = cam + (base - cam) * f + Vector2(0, bob)
				if absf(p.x - cam.x) > 400.0 or absf(p.y - cam.y) > 260.0:
					continue
				var s: float = it[2] * f
				var r := RandomNumberGenerator.new()
				r.seed = it[3]
				var rock := Color(0.2, 0.13, 0.2).lerp(Color(0.32, 0.12, 0.2), fog * 1.4)
				var rim := Color(0.62, 0.4, 0.5).lerp(Color(0.5, 0.2, 0.3), fog)
				var alpha := 1.0 - fog * 1.1
				match it[1]:
					0, 1, 2, 3, 4:
						# roca flotante: cara superior iluminada y raíz que cuelga
						var w := r.randf_range(14, 40) * s
						var h := r.randf_range(6, 14) * s
						var pts := PackedVector2Array()
						for k in 7:
							var a := PI + PI * k / 6.0
							pts.append(p + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.35))
						pts.append(p + Vector2(w * 0.3, h * 0.6))
						pts.append(p + Vector2(0, h * 1.6))
						pts.append(p + Vector2(-w * 0.35, h * 0.5))
						Depth3D.poly(self, pts, Color(rock, alpha))
						draw_line(p + Vector2(-w * 0.45, -h * 0.05), p + Vector2(w * 0.45, -h * 0.05), Color(rim, alpha * 0.8), 1.0)
					5, 6:
						# columna rota flotando
						var ch := r.randf_range(18, 34) * s
						var cw := 6.0 * s
						draw_rect(Rect2(p - Vector2(cw / 2, ch), Vector2(cw, ch)), Color(rock.lightened(0.1), alpha))
						draw_rect(Rect2(p - Vector2(cw / 2, ch), Vector2(1, ch)), Color(rim, alpha * 0.7))
						draw_rect(Rect2(p - Vector2(cw / 2 + 2, 2), Vector2(cw + 4, 3)), Color(rock, alpha))
					7:
						# cadena colgando hacia lo más hondo
						var cl := r.randf_range(30, 70) * s
						var sway := sin(t * 0.7 + it[4]) * 4.0 * s
						for k2 in int(cl / 4.0):
							var q := p + Vector2(sway * k2 / (cl / 4.0), k2 * 4.0)
							draw_rect(Rect2(q, Vector2(2, 3)), Color(rock.lightened(0.25), alpha * (1.0 - k2 / (cl / 4.0) * 0.6)))
					8:
						# ala rota (huesos de un ángel caído)
						var ww := 22.0 * s
						for k3 in 5:
							var a2 := -0.9 + k3 * 0.32
							draw_line(p, p + Vector2.from_angle(a2) * ww * (1.0 - k3 * 0.1), Color(0.75, 0.68, 0.72, alpha * 0.7), 1.0)
					9:
						# ascua lejana
						draw_circle(p, 2.0 * s, Color(1, 0.5, 0.25, alpha * (0.5 + 0.5 * sin(t * 2.0 + it[4]))))
					10:
						# puente roto: tablones colgando de dos cadenas
						var bw := 60.0 * s
						var sag := 10.0 * s
						var prev := p
						for k4 in 9:
							var u := k4 / 8.0
							var q2 := p + Vector2(bw * u, sin(u * PI) * sag + sin(t * 0.6 + it[4]) * 2.0 * u)
							if k4 > 0:
								draw_line(prev, q2, Color(rock.lightened(0.2), alpha * 0.8), 1.0)
							if k4 % 2 == 0 and k4 != 4:
								draw_rect(Rect2(q2 - Vector2(3, 0) * s, Vector2(6, 2) * s), Color(0.32, 0.22, 0.2, alpha))
							prev = q2


class CliffDepth extends Node2D:
	## Faldón de roca bajo los bordes sur de las plataformas, con estratos que se encogen hacia el centro
	## de la cámara (están más hondos), raíces y estalactitas. Da el volumen de isla flotante.
	var world: Node
	var runs: Array = []    # [x0, x1, y] en píxeles: tramos del borde inferior
	const LEVELS := [16.0, 30.0, 48.0, 70.0]
	func _ready() -> void:
		z_index = -11
		var W: int = world.MAPW
		for y in world.MAPH:
			var x := 0
			while x < W:
				if _edge(x, y):
					var x0 := x
					while x < W and _edge(x, y):
						x += 1
					runs.append([x0 * 16.0, x * 16.0, (y + 1) * 16.0 + 16.0])
				x += 1
	func _edge(x: int, y: int) -> bool:
		# casilla de suelo (o pozo) cuya fila de abajo es el faldón (4) o vacío
		var g: int = world.grid[y * world.MAPW + x]
		if g != 1 and g != 5:
			return false
		if y + 2 >= world.MAPH:
			return false
		var below: int = world.grid[(y + 1) * world.MAPW + x]
		var below2: int = world.grid[(y + 2) * world.MAPW + x]
		return below == 3 and (below2 == 4 or below2 == 0)
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var cam := Depth3D.cam_center(self)
		for r in runs:
			var x0: float = r[0]
			var x1: float = r[1]
			var y: float = r[2]
			if x1 < cam.x - 380.0 or x0 > cam.x + 380.0 or absf(y - cam.y) > 260.0:
				continue
			for li in LEVELS.size() - 1:
				var d0: float = LEVELS[li]
				var d1: float = LEVELS[li + 1]
				var k0 := 1.0 - d0 / 260.0
				var k1 := 1.0 - d1 / 260.0
				var a := _p(Vector2(x0, y + d0), cam, k0)
				var b := _p(Vector2(x1, y + d0), cam, k0)
				var ins := minf(6.0 * (li + 1), (x1 - x0) * 0.3)
				var c := _p(Vector2(x1 - ins, y + d1), cam, k1)
				var d := _p(Vector2(x0 + ins, y + d1), cam, k1)
				var shade := Color(0.2, 0.13, 0.17).lerp(Color(0.1, 0.04, 0.08), li / 3.0)
				Depth3D.poly(self, PackedVector2Array([a, b, c, d]), Color(shade, 1.0 - li * 0.22))
				draw_line(a, b, Color(0.42, 0.3, 0.36, 0.5 - li * 0.12), 1.0)
			# estalactitas y raíces del fondo
			var xx := x0 + 5.0
			var i := 0
			while xx < x1 - 4.0:
				var h := 8.0 + float((int(xx) * 7) % 13)
				var top := _p(Vector2(xx, y + LEVELS[3]), cam, 1.0 - LEVELS[3] / 260.0)
				var tip := _p(Vector2(xx, y + LEVELS[3] + h), cam, 1.0 - (LEVELS[3] + h) / 260.0)
				Depth3D.poly(self, PackedVector2Array([top + Vector2(-3, 0), top + Vector2(3, 0), tip]), Color(0.1, 0.05, 0.08, 0.5))
				if i % 3 == 0:
					draw_line(top, tip + Vector2(2, 6), Color(0.35, 0.22, 0.2, 0.35), 1.0)
				xx += 9.0 + float((int(xx) * 3) % 7)
				i += 1
	func _p(p: Vector2, cam: Vector2, k: float) -> Vector2:
		return cam + (p - cam) * k


class NearLayer extends Node2D:
	## Polvo y ceniza fuera de foco MUY cerca de la cámara: se mueve más que el mundo (paralaje > 1)
	## y da sensación de profundidad por delante de la escena.
	var world: Node
	var motes: Array = []
	const PAR := 1.45
	func _ready() -> void:
		z_index = 60
		var rng := RandomNumberGenerator.new()
		rng.seed = 31
		for i in 70:
			motes.append([Vector2(rng.randf_range(-200, world.MAPW * 16 + 200), rng.randf_range(-200, world.MAPH * 16 + 200)), rng.randf_range(3.0, 9.0), rng.randf() * TAU])
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var cam := Depth3D.cam_center(self)
		var t := Time.get_ticks_msec() / 1000.0
		var a: String = world.current_area()
		var warm: bool = a in ["area_sanct", "area_chains", "area_yard", "area_celdas"]
		var tint := Color(1, 0.6, 0.35) if warm else Color(0.75, 0.7, 0.95)
		if a == "area_juicio" or a == "area_circle":
			tint = Color(1, 0.9, 0.65)
		for m in motes:
			var base: Vector2 = m[0] + Vector2(sin(t * 0.3 + m[2]) * 20.0, -fmod(t * 6.0 + m[2] * 40.0, 80.0))
			var p := cam + (base - cam) * PAR
			if absf(p.x - cam.x) > 340.0 or absf(p.y - cam.y) > 200.0:
				continue
			var r: float = m[1]
			for k in 3:
				draw_circle(p, r * (1.0 - k * 0.3), Color(tint, 0.025 + k * 0.015))


class Column extends Node2D:
	## Columna alta dibujada en perspectiva: la base está en el suelo y el capitel se proyecta hacia la
	## cámara según su altura, así que al moverte la columna "gira" y se ve su volumen.
	var height := 64.0
	var radius := 7.0
	var stone := Color(0.78, 0.72, 0.66)
	var gold := Color(0.85, 0.66, 0.3)
	var broken := false
	var ivy := false
	func _ready() -> void:
		var b := StaticBody2D.new()
		b.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = radius
		cs.shape = sh
		b.add_child(cs)
		add_child(b)
	func _process(_delta: float) -> void:
		var cam := Depth3D.cam_center(self)
		if absf(global_position.x - cam.x) < 380.0 and absf(global_position.y - cam.y) < 260.0:
			queue_redraw()
	func _draw() -> void:
		var cam := Depth3D.cam_center(self) - global_position
		var h := height * (0.62 if broken else 1.0)
		var top := Depth3D.lift(Vector2.ZERO, h, cam)
		var r := radius
		# sombra en el suelo, alargada en dirección contraria a la cámara
		var away := (-cam).normalized() * 6.0 if cam.length() > 1.0 else Vector2.ZERO
		draw_set_transform(away * 0.5, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, r * 1.6, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# basa
		_ell(Vector2(0, 1), r + 3.0, stone.darkened(0.45))
		_ell(Vector2.ZERO, r + 3.0, stone.darkened(0.15))
		# fuste: bandas verticales con luz a la izquierda y sombra a la derecha
		var bands := 5
		for i in bands:
			var t0 := -1.0 + 2.0 * i / bands
			var t1 := -1.0 + 2.0 * (i + 1) / bands
			var lit := 1.15 - absf(t0 + 0.4) * 0.45
			var col := stone * Color(lit, lit, lit)
			col.a = 1.0
			var pts := PackedVector2Array([Vector2(t0 * r, 0), Vector2(t1 * r, 0), top + Vector2(t1 * r * 0.9, 0), top + Vector2(t0 * r * 0.9, 0)])
			Depth3D.poly(self, pts, col)
		draw_line(Vector2(-r, 0), top + Vector2(-r * 0.9, 0), stone.lightened(0.3), 1.0)
		draw_line(Vector2(r, 0), top + Vector2(r * 0.9, 0), stone.darkened(0.5), 1.0)
		# anillos dorados a media altura
		for k in [0.35, 0.7]:
			if broken and k > 0.6:
				continue
			var p := Vector2.ZERO.lerp(top, k)
			draw_line(p + Vector2(-r * 0.95, 0), p + Vector2(r * 0.95, 0), gold, 2.0)
		if ivy:
			for k2 in 6:
				var q := Vector2.ZERO.lerp(top, k2 / 6.0) + Vector2(sin(k2 * 1.7) * r * 0.7, 0)
				draw_circle(q, 1.6, Color(0.3, 0.5, 0.32))
		# capitel (o rotura)
		if broken:
			var pts2 := PackedVector2Array([top + Vector2(-r * 0.9, 0), top + Vector2(-r * 0.3, -4), top + Vector2(r * 0.2, 1), top + Vector2(r * 0.9, -3), top + Vector2(r * 0.9, 2), top + Vector2(-r * 0.9, 2)])
			Depth3D.poly(self, pts2, stone.darkened(0.25))
		else:
			_ell(top + Vector2(0, 1), r + 4.0, stone.darkened(0.3))
			_ell(top, r + 4.0, stone.lightened(0.15))
			_ell(top + Vector2(0, -2), r + 2.0, gold)
	func _ell(c: Vector2, rx: float, col: Color) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, 0.38))
		draw_circle(Vector2.ZERO, rx, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class HangingChain extends Node2D:
	## Cadena que cuelga desde muy alto (desde "la cámara") hasta poco por encima del suelo.
	## El extremo de arriba se proyecta con mucha altura, así que parece bajar hacia la escena.
	var top_h := 260.0
	var low_h := 34.0
	var t := 0.0
	var hook := true
	func _ready() -> void:
		z_index = 20
		t = randf() * 10.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var cam := Depth3D.cam_center(self) - global_position
		var sway := Vector2(sin(t * 0.8) * 4.0, 0)
		var n := 18
		for i in n:
			var k := float(i) / (n - 1)
			var h := lerpf(top_h, low_h, k)
			var p := Depth3D.lift(sway * k, h, cam)
			var sc := 1.0 + h / 300.0
			var dark := clampf(h / top_h, 0.0, 1.0)
			var col := Color(0.45, 0.42, 0.5).lerp(Color(0.12, 0.1, 0.14), dark * 0.6)
			if i % 2 == 0:
				draw_rect(Rect2(p - Vector2(1.5, 3) * sc, Vector2(3, 6) * sc), col)
			else:
				draw_rect(Rect2(p - Vector2(2.5, 1) * sc, Vector2(5, 2) * sc), col.lightened(0.15))
		if hook:
			var e := Depth3D.lift(sway, low_h, cam)
			draw_arc(e + Vector2(0, 4), 4.0, 0.0, PI, 8, Color(0.55, 0.5, 0.58), 2.0)
		# sombra en el suelo
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.25))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)



class Soul extends Node2D:
	## Alma que abandona al enemigo caído: sube con perspectiva hacia la cámara, crece y se desvanece
	var col := Color(0.6, 0.85, 1.0)
	var t := 0.0
	const DUR := 1.4
	func _ready() -> void:
		z_index = 30
		material = Fx.add_material()
	func _process(delta: float) -> void:
		t += delta
		if t >= DUR:
			queue_free()
			return
		queue_redraw()
	func _draw() -> void:
		var k := t / DUR
		var cam := Depth3D.cam_center(self) - global_position
		var h := 10.0 + 150.0 * k * k
		var p := Depth3D.lift(Vector2(sin(t * 6.0) * 4.0, 0), h, cam)
		var s := 1.0 + h / 160.0
		var a := (1.0 - k) * 0.9
		for i in 4:
			var q := Depth3D.lift(Vector2(sin((t - i * 0.06) * 6.0) * 4.0, 0), maxf(0.0, h - i * 10.0), cam)
			draw_circle(q, (3.0 - i * 0.5) * s, Color(col, a * (0.35 - i * 0.07)))
		draw_circle(p, 3.5 * s, Color(col, a * 0.5))
		draw_circle(p, 1.8 * s, Color(1, 1, 1, a))


class CastShadow extends Sprite2D:
	## Sombra proyectada por la antorcha o el brasero más cercano: una silueta aplastada que gira y se
	## alarga al moverte alrededor de la luz, como en Bloody Hell.
	const RANGE := 150.0
	var src: Sprite2D
	var size_mul := 1.0
	var world: Node
	func _ready() -> void:
		z_index = -1
		show_behind_parent = true
		modulate = Color(0, 0, 0, 0)
	func _process(_delta: float) -> void:
		if world == null:
			world = get_tree().get_first_node_in_group("world")
		if src == null or not is_instance_valid(src) or not src.visible or world == null:
			visible = false
			return
		var p: Vector2 = get_parent().global_position
		var best := Vector2.ZERO
		var bd := RANGE
		var room: String = world.room_at(p)
		for l in world.shadow_lights:
			var lp: Vector2 = l[0]
			var dd := p.distance_to(lp)
			if dd < bd and (room == "" or l[1] == "" or l[1] == room):
				bd = dd
				best = lp
		if bd >= RANGE or bd < 3.0:
			visible = false
			return
		visible = true
		var dir := (p - best) / bd
		var k := bd / RANGE
		var len := lerpf(0.55, 1.3, k)
		var a := clampf((1.0 - k) * 1.8, 0.0, 1.0) * 0.5
		texture = src.texture
		region_enabled = src.region_enabled
		region_rect = src.region_rect
		flip_h = src.flip_h
		var sc := src.scale.abs() * size_mul
		var hh := region_rect.size.y if region_enabled else float(texture.get_height())
		offset = Vector2(0, -hh * 0.5 + 2.0 / maxf(sc.y, 0.01))
		transform = Transform2D(Vector2(dir.y, -dir.x) * 0.9 * sc.x, -dir * len * sc.y, Vector2(0, 1))
		modulate = Color(0, 0, 0, a)


class Chandelier extends Node2D:
	## Lámpara de araña colgada muy alto: el aro de velas está "cerca de la cámara", así que se desplaza y
	## crece con la perspectiva al moverte por debajo. Cadenas que suben hasta perderse.
	var ring_h := 86.0
	var radius := 22.0
	var candles := 8
	var t := 0.0
	var _light: PointLight2D
	func _ready() -> void:
		z_index = 22
		t = randf() * 10.0
		_light = PointLight2D.new()
		_light.texture = Fx.tex("light")
		_light.color = Color(1, 0.78, 0.45)
		_light.texture_scale = 3.2
		_light.energy = 0.55
		add_child(_light)
	func _process(delta: float) -> void:
		t += delta
		_light.energy = 0.5 + sin(t * 7.0) * 0.03 + sin(t * 13.0) * 0.02
		queue_redraw()
	func _ring_pt(a: float, h: float, cam: Vector2, sway: Vector2) -> Vector2:
		return Depth3D.lift(Vector2(cos(a) * radius, sin(a) * radius * 0.5) + sway, h, cam)
	func _draw() -> void:
		var cam := Depth3D.cam_center(self) - global_position
		var sway := Vector2(sin(t * 0.7) * 2.0, cos(t * 0.5) * 1.0)
		var iron := Color(0.34, 0.26, 0.2)
		var iron_hi := Color(0.86, 0.66, 0.36)
		# charco de luz y sombra del aro en el suelo
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, radius * 1.9, Color(1, 0.75, 0.4, 0.06))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(0, 0, 0, 0.18), 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var hub_h := ring_h + 64.0
		var hub := Depth3D.lift(sway * 0.5, hub_h, cam)
		# cadenas: aro -> nudo -> techo
		for k in 3:
			var a := PI * 0.5 + k * TAU / 3.0
			var p0 := _ring_pt(a, ring_h, cam, sway)
			draw_line(p0, hub, Color(0.08, 0.05, 0.08), 3.0)
			draw_line(p0, hub, iron_hi.darkened(0.25), 1.0)
		var n := 10
		for i in n:
			var kk := float(i) / (n - 1)
			var h := lerpf(hub_h, 340.0, kk)
			var p := Depth3D.lift(sway * 0.5 * (1.0 - kk), h, cam)
			var sc := 1.0 + h / 260.0
			if i % 2 == 0:
				draw_rect(Rect2(p - Vector2(1.5, 3) * sc, Vector2(3, 6) * sc), Color(0.45, 0.4, 0.42).lerp(Color(0.08, 0.05, 0.09), kk * 0.7))
			else:
				draw_rect(Rect2(p - Vector2(2.5, 1) * sc, Vector2(5, 2) * sc), Color(0.62, 0.56, 0.58).lerp(Color(0.08, 0.05, 0.09), kk * 0.7))
		draw_circle(hub, 4.0, Color(0.08, 0.05, 0.08))
		draw_circle(hub, 3.0, iron_hi)
		draw_circle(hub + Vector2(0, 4), 2.0, iron_hi.darkened(0.3))
		# aro: mitad trasera, velas, mitad delantera
		var seg := 28
		var sc2 := 1.0 + ring_h / 260.0
		for half in [0, 1]:
			var pts := PackedVector2Array()
			for i in seg + 1:
				var a2 := PI * float(half) + PI * float(i) / seg
				pts.append(_ring_pt(a2, ring_h, cam, sway))
			draw_polyline(pts, Color(0.08, 0.05, 0.08), 5.0 * sc2)
			draw_polyline(pts, iron, 3.0 * sc2)
			draw_polyline(pts, iron_hi, 1.0)
			for c in candles:
				var ac := TAU * float(c) / candles + 0.2
				var back := sin(ac) < 0.0
				if (half == 0) != back:
					continue
				var cp := _ring_pt(ac, ring_h, cam, sway)
				draw_rect(Rect2(cp + Vector2(-1.5, -6) * sc2, Vector2(3, 6) * sc2), Color(0.92, 0.88, 0.8))
				var fl := cp + Vector2(0, -8) * sc2 + Vector2(sin(t * 9.0 + c) * 0.6, 0)
				draw_circle(fl, 5.0 * sc2, Color(1, 0.6, 0.2, 0.12))
				draw_circle(fl, 1.8 * sc2, Color(1, 0.75, 0.3))
				draw_circle(fl + Vector2(0, 0.6), 0.9 * sc2, Color(1, 1, 0.85))

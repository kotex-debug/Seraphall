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
				var kind := rng.randi_range(0, 9)
				items.append([p, kind, rng.randf_range(0.7, 1.4), rng.randi(), rng.randf() * TAU])
			layers.append([f, items])
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var cam := Depth3D.cam_center(self)
		var t := Time.get_ticks_msec() / 1000.0
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

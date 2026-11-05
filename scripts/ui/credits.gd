extends CanvasLayer
## Créditos finales del juego base: la Espiral rota al fondo, plumas que caen y los nombres que suben.
## Se pueden saltar (cualquier tecla, tras unos segundos). Al terminar emite «finished».

signal finished

var wings := true
var root: Control
var t := 0.0
var _scroll: Control
var _done := false
var _bg: CreditsBg

const LINES := [
	["logo", "SERAPHALL"],
	["sub", ["La Caída del Serafín", "The Fall of the Seraph"]],
	["gap"],
	["head", ["UN JUEGO DE", "A GAME BY"]],
	["body", ["El equipo de SERAPHALL", "The SERAPHALL team"]],
	["gap"],
	["head", ["DISEÑO, GUION Y MUNDO", "DESIGN, STORY AND WORLD"]],
	["body", ["La Espiral, sus cuatro estratos y todo lo que cayó en ella", "The Spiral, its four strata and everything that fell into it"]],
	["gap"],
	["head", ["ARTE, MÚSICA Y SONIDO", "ART, MUSIC AND SOUND"]],
	["body", ["Pixel art, banda sonora y efectos generados a medida", "Pixel art, soundtrack and effects made to measure"]],
	["gap"],
	["head", ["LOS ARCONTES", "THE ARCHONS"]],
	["body", ["Seravel, Guardiana de las Puertas", "Seravel, Warden of the Gates"]],
	["body", ["Orrun, el Ciervo Hueco", "Orrun, the Hollow Stag"]],
	["body", ["Vulkaris, Herrero de Aureolas", "Vulkaris, the Halo Smith"]],
	["body", ["Azrahel, Rey del Abismo", "Azrahel, King of the Abyss"]],
	["gap"],
	["head", ["QUIENES TE ESPERARON", "THOSE WHO WAITED FOR YOU"]],
	["body", ["Brenna · Madre Ilse · Ozias · Nyx · Sor Velaria · El Cartógrafo", "Brenna · Mother Ilse · Ozias · Nyx · Sister Velaria · The Cartographer"]],
	["body", ["Tobías · Sael · Hermano Oso · El Archivero · Lirio", "Tobias · Sael · Brother Bear · The Archivist · Lirio"]],
	["gap"],
	["head", ["HECHO CON", "MADE WITH"]],
	["body", ["Godot Engine 4.7", "Godot Engine 4.7"]],
	["body", ["Fuentes: Jersey 10/15, Silkscreen y Pixelify Sans (SIL OFL)", "Fonts: Jersey 10/15, Silkscreen and Pixelify Sans (SIL OFL)"]],
	["gap"],
	["head", ["INSPIRADO EN", "INSPIRED BY"]],
	["body", ["Bloody Hell · Emberville · Dimraeth · Elden Ring", "Bloody Hell · Emberville · Dimraeth · Elden Ring"]],
	["gap"],
	["gap"],
	["route"],
	["gap"],
	["body", ["Arriba esperan los Cielos Rotos. Abajo, el Abismo Sin Nombre.", "Above await the Broken Heavens. Below, the Nameless Abyss."]],
	["gap"],
	["logo2", ["CONTINUARÁ...", "TO BE CONTINUED..."]],
	["gap"],
	["sub", ["Gracias por jugar.", "Thank you for playing."]],
]

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(640, 360)
	add_child(root)
	_bg = CreditsBg.new()
	_bg.size = Vector2(640, 360)
	_bg.wings = wings
	root.add_child(_bg)
	_scroll = Control.new()
	_scroll.position = Vector2(0, 380)
	root.add_child(_scroll)
	var y := 0.0
	for l in LINES:
		match l[0]:
			"gap":
				y += 22.0
			"logo":
				var p := UIKit.pixel_text(str(l[1]), 48, "logo", UIKit.GOLD)
				p.align = 1
				p.size = Vector2(640, 52)
				p.position = Vector2(0, y)
				p.extrude = 4
				p.extrude_color = UIKit.RED
				_scroll.add_child(p)
				y += 56.0
			"logo2":
				var p2 := UIKit.pixel_text(G.L(l[1]), 32, "logo", Color(0.85, 0.7, 1.0))
				p2.align = 1
				p2.size = Vector2(640, 36)
				p2.position = Vector2(0, y)
				p2.extrude = 3
				p2.extrude_color = Color(0.3, 0.1, 0.45)
				_scroll.add_child(p2)
				y += 40.0
			"route":
				var txt := G.L(["Le diste la espalda al trono. Las Alas siguen abiertas.", "You turned your back on the throne. The Wings remain open."]) if wings else G.L(["Tocaste el trono. Ahora es tuyo... o tú eres suyo.", "You touched the throne. Now it is yours... or you are its."])
				_line(txt, y, 15, Color(0.85, 0.75, 1.0) if not wings else Color(1, 0.9, 0.65), "body")
				y += 22.0
			"head":
				_line(G.L(l[1]), y, 8, UIKit.GOLD, "head")
				y += 14.0
			"sub":
				_line(G.L(l[1]), y, 15, Color(0.85, 0.8, 0.9), "body")
				y += 20.0
			_:
				_line(G.L(l[1]), y, 15, UIKit.WHITE, "body")
				y += 18.0
	_scroll.size = Vector2(640, y)

func _line(text: String, y: float, size: int, col: Color, kind: String) -> void:
	var l := UIKit.label(text, size, col, kind, 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(640, size + 4)
	_scroll.add_child(l)

func _process(delta: float) -> void:
	t += delta
	_scroll.position.y -= delta * (24.0 if G.autotest == "" else 400.0)
	root.modulate.a = minf(1.0, t / 1.2)
	if _scroll.position.y + _scroll.size.y < 120.0 and not _done:
		_finish()

func _input(event: InputEvent) -> void:
	if t > 3.0 and not _done and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		_finish()

func _finish() -> void:
	_done = true
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 1.4)
	tw.tween_callback(func() -> void:
		finished.emit()
		queue_free())

class CreditsBg extends Control:
	## Fondo: la Espiral partida en dos (grieta arriba y abajo) y plumas que caen despacio
	var wings := true
	var t := 0.0
	var parts: Array = []
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 40:
			parts.append([Vector2(randf() * 640, randf() * 360), randf_range(8, 20), randf() * TAU])
	func _process(delta: float) -> void:
		t += delta
		for p in parts:
			p[0].y += p[1] * delta
			p[0].x += sin(t + p[2]) * 6.0 * delta
			p[2] += delta
			if p[0].y > 370:
				p[0] = Vector2(randf() * 640, -10)
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.02, 0.06))
		var c := Vector2(320, 180)
		# la espiral: anillos concéntricos que giran
		for i in 12:
			var r := 24.0 + i * 15.0
			var a0 := t * (0.15 + i * 0.02) * (1.0 if i % 2 == 0 else -1.0)
			var col := Color(0.4, 0.25, 0.55, 0.22 - i * 0.012)
			draw_arc(c, r, a0, a0 + PI * 1.6, 40, col, 2.0)
		# la grieta: arriba hacia los Cielos Rotos (oro), abajo hacia el Abismo (violeta)
		var up := PackedVector2Array([c])
		var dn := PackedVector2Array([c])
		var p1 := c
		var p2 := c
		for k in 9:
			p1 += Vector2(sin(k * 1.7) * 9.0, -20.0)
			p2 += Vector2(sin(k * 2.3 + 1.0) * 9.0, 20.0)
			up.append(p1)
			dn.append(p2)
		var g := 0.7 + 0.3 * sin(t * 2.0)
		draw_polyline(up, Color(1, 0.85, 0.5, 0.35 * g), 6.0)
		draw_polyline(up, Color(1, 0.95, 0.75, g), 2.0)
		draw_polyline(dn, Color(0.6, 0.35, 1.0, 0.35 * g), 6.0)
		draw_polyline(dn, Color(0.8, 0.6, 1.0, g), 2.0)
		draw_circle(c, 5.0 + g * 2.0, Color(1, 1, 1, 0.8))
		for p in parts:
			var pc: Color = Color(1, 0.95, 0.85, 0.5) if wings else Color(0.75, 0.6, 1.0, 0.5)
			draw_set_transform(p[0], sin(p[2]) * 0.8, Vector2.ONE)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -4), Vector2(1.5, 0), Vector2(0, 4), Vector2(-1.5, 0)]), pc)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# viñeta
		draw_rect(Rect2(0, 0, 640, 40), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(0, 320, 640, 40), Color(0, 0, 0, 0.5))

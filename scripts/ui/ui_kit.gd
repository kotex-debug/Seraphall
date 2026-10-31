class_name UIKit
extends RefCounted
## Kit visual de SERAPHALL (estilo pixel art enérgico): fuentes gruesas y nítidas, paleta intensa,
## marcos pixelados con sombra dura, texto animado y botones con rebote.

const RED := Color(1.0, 0.18, 0.3)
const RED_DARK := Color(0.54, 0.06, 0.16)
const PINK := Color(1.0, 0.48, 0.58)
const GOLD := Color(1.0, 0.82, 0.25)
const GOLD_DARK := Color(0.77, 0.48, 0.07)
const GOLD_HOT := Color(1.0, 0.96, 0.78)
const WHITE := Color(1.0, 0.965, 0.92)
const CYAN := Color(0.3, 0.88, 1.0)
const CYAN_DARK := Color(0.08, 0.42, 0.62)
const INK := Color(0.078, 0.031, 0.11)
const PURPLE := Color(0.23, 0.1, 0.32)
const PANEL := Color(0.12, 0.05, 0.165, 0.95)
const TEXT := Color(1.0, 0.965, 0.92)
const TEXT_DIM := Color(0.72, 0.64, 0.76)
const GOLD_DIM := Color(0.77, 0.48, 0.07)

static var _fonts := {}
static var _shaders := {}

static func font(kind := "body") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path := "res://assets/fonts/Jersey15-Regular.ttf"
	match kind:
		"logo", "title":
			path = "res://assets/fonts/Jersey10-Regular.ttf"
		"head", "head_wide", "num", "title_b":
			path = "res://assets/fonts/Silkscreen-Bold.ttf"
		"small":
			path = "res://assets/fonts/Silkscreen-Regular.ttf"
		"bold":
			path = "res://assets/fonts/PixelifySans.ttf"
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	var out: Font = f
	if kind == "bold":
		var v := FontVariation.new()
		v.base_font = f
		v.variation_opentype = {"wght": 700}
		out = v
	elif kind == "head_wide":
		var v2 := FontVariation.new()
		v2.base_font = f
		v2.spacing_glyph = 2
		out = v2
	_fonts[kind] = out
	return out

static func shader(name: String) -> Shader:
	if not _shaders.has(name):
		_shaders[name] = load("res://shaders/%s.gdshader" % name)
	return _shaders[name]

static func mat(name: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(name)
	return m

## Etiqueta con contorno grueso y sombra dura
static func label(text: String, size: int, color := TEXT, kind := "body", outline := 4) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = font(kind)
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = INK
	ls.shadow_size = 1
	ls.shadow_color = Color(0, 0, 0, 0.7)
	ls.shadow_offset = Vector2(1, 2)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func gold_label(text: String, size: int, kind := "head") -> Label:
	return label(text, size, GOLD, kind, 5)

## Tema de botones pixel: borde grueso, sombra dura, rojo al pasar
static func button_theme(font_size := 8) -> Theme:
	var th := Theme.new()
	th.default_font = font("head")
	th.default_font_size = font_size
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.17, 0.07, 0.23)
	n.border_color = Color(0.45, 0.25, 0.55)
	n.set_border_width_all(2)
	n.content_margin_left = 10; n.content_margin_right = 10; n.content_margin_top = 4; n.content_margin_bottom = 4
	n.shadow_color = Color(0, 0, 0, 0.6)
	n.shadow_offset = Vector2(2, 2)
	n.shadow_size = 0
	n.anti_aliasing = false
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = RED
	h.border_color = WHITE
	h.shadow_color = RED_DARK
	h.shadow_offset = Vector2(2, 3)
	var p := h.duplicate() as StyleBoxFlat
	p.bg_color = WHITE
	p.shadow_offset = Vector2(1, 1)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(0.1, 0.06, 0.12)
	d.border_color = Color(0.25, 0.18, 0.28)
	th.set_stylebox("normal", "Button", n)
	th.set_stylebox("hover", "Button", h)
	th.set_stylebox("focus", "Button", h)
	th.set_stylebox("pressed", "Button", p)
	th.set_stylebox("hover_pressed", "Button", p)
	th.set_stylebox("disabled", "Button", d)
	th.set_color("font_color", "Button", WHITE)
	th.set_color("font_hover_color", "Button", WHITE)
	th.set_color("font_focus_color", "Button", WHITE)
	th.set_color("font_pressed_color", "Button", RED)
	th.set_color("font_hover_pressed_color", "Button", RED)
	th.set_color("font_disabled_color", "Button", Color(0.4, 0.34, 0.42))
	th.set_color("font_outline_color", "Button", INK)
	th.set_constant("outline_size", "Button", 4)
	th.set_font("font", "Label", font("body"))
	th.set_font_size("font_size", "Label", 10)
	th.set_color("font_color", "Label", TEXT)
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD
	var sl := StyleBoxFlat.new()
	sl.bg_color = INK
	sl.border_color = PURPLE
	sl.set_border_width_all(2)
	sl.content_margin_top = 3; sl.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = RED
	th.set_stylebox("slider", "HSlider", sl)
	th.set_stylebox("grabber_area", "HSlider", fill)
	th.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var le := StyleBoxFlat.new()
	le.bg_color = INK
	le.border_color = RED
	le.set_border_width_all(2)
	le.content_margin_left = 8
	le.shadow_color = RED_DARK
	le.shadow_offset = Vector2(2, 2)
	th.set_stylebox("normal", "LineEdit", le)
	th.set_stylebox("focus", "LineEdit", le)
	th.set_font("font", "LineEdit", font("head"))
	th.set_font_size("font_size", "LineEdit", 16)
	th.set_color("font_color", "LineEdit", GOLD)
	th.set_color("caret_color", "LineEdit", WHITE)
	return th

## Rebote al pasar por encima / enfocar / pulsar
static func juicy(b: Control) -> void:
	b.pivot_offset = b.size / 2.0
	b.resized.connect(_fix_pivot.bind(b))
	b.mouse_entered.connect(_hover_in.bind(b))
	b.focus_entered.connect(_hover_in.bind(b))
	b.mouse_exited.connect(_hover_out.bind(b))
	b.focus_exited.connect(_hover_out.bind(b))
	if b is BaseButton:
		b.button_down.connect(_press.bind(b))

static func _fix_pivot(b: Control) -> void:
	b.pivot_offset = b.size / 2.0

static func _hover_in(b: Control) -> void:
	if not is_instance_valid(b) or (b is BaseButton and b.disabled):
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.12, 0.9), 0.05)
	tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Audio.sfx("ui_move", -12.0, 0.06)

static func _hover_out(b: Control) -> void:
	if not is_instance_valid(b):
		return
	b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

static func _press(b: Control) -> void:
	if not is_instance_valid(b):
		return
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(0.88, 1.12), 0.05)
	tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- dibujo pixelado
static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color, filled := true) -> void:
	c = c.round()
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	if filled:
		ci.draw_colored_polygon(pts, col)
	else:
		pts.append(pts[0])
		ci.draw_polyline(pts, col, 1.0)

## Marco pixel con esquinas recortadas, contorno oscuro, borde de color, sombra dura y brillo que recorre el borde
static func frame(ci: CanvasItem, r: Rect2, col := PURPLE, fill := PANEL, corner := 3.0, t := -1.0) -> void:
	r = Rect2(r.position.round(), r.size.round())
	var cut := corner
	# sombra dura
	_notched(ci, Rect2(r.position + Vector2(3, 3), r.size), cut, Color(0, 0, 0, 0.55))
	# contorno tinta
	_notched(ci, r.grow(1), cut + 1, INK)
	# borde de color
	_notched(ci, r, cut, col)
	# relleno
	_notched(ci, r.grow(-2), max(0.0, cut - 1), fill)
	# brillo superior
	ci.draw_rect(Rect2(r.position + Vector2(cut + 1, 2), Vector2(r.size.x - cut * 2 - 2, 1)), Color(1, 1, 1, 0.08))
	if t >= 0.0:
		var per := (r.size.x + r.size.y) * 2.0
		for k in 2:
			var d := fmod(t * 80.0 + k * per * 0.5, per)
			var p := _perimeter_point(r, d)
			ci.draw_rect(Rect2(p - Vector2(2, 1), Vector2(5, 2)), Color(col.lightened(0.6), 0.9))

static func _notched(ci: CanvasItem, r: Rect2, cut: float, col: Color) -> void:
	var p := r.position
	var s := r.size
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(cut, 0), p + Vector2(s.x - cut, 0), p + Vector2(s.x, cut), p + Vector2(s.x, s.y - cut),
		p + Vector2(s.x - cut, s.y), p + Vector2(cut, s.y), p + Vector2(0, s.y - cut), p + Vector2(0, cut)]), col)

static func _perimeter_point(r: Rect2, d: float) -> Vector2:
	var w := r.size.x
	var h := r.size.y
	if d < w:
		return r.position + Vector2(d, 0)
	d -= w
	if d < h:
		return r.position + Vector2(w, d)
	d -= h
	if d < w:
		return r.position + Vector2(w - d, h)
	d -= w
	return r.position + Vector2(0, h - d)

## Franja inclinada (cintas de títulos, selección)
static func slash_band(ci: CanvasItem, r: Rect2, col: Color, skew := 6.0) -> void:
	var p := r.position
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(skew, 0), p + Vector2(r.size.x, 0), p + Vector2(r.size.x - skew, r.size.y), p + Vector2(0, r.size.y)]), col)

## Línea decorativa con rombos
static func flourish(ci: CanvasItem, center: Vector2, half_w: float, col: Color, grow := 1.0) -> void:
	var w := half_w * grow
	ci.draw_rect(Rect2(center + Vector2(-w, -1), Vector2(w * 2, 2)), Color(col, col.a * 0.6))
	diamond(ci, center, 4.0, col)
	diamond(ci, center + Vector2(-w - 4, 0), 2.0, col)
	diamond(ci, center + Vector2(w + 4, 0), 2.0, col)

## Ala pixelada (para logo y adornos). side = 1 derecha, -1 izquierda
static func wing(ci: CanvasItem, root: Vector2, side: float, size: float, col: Color, open := 1.0) -> void:
	var n := 6
	for i in n:
		var k := float(i) / (n - 1)
		var ang := deg_to_rad(lerpf(-8.0, -58.0, k) * open)
		var length := size * (1.0 - k * 0.4)
		var dir := Vector2(cos(ang) * side, sin(ang))
		var steps := int(length / 3.0)
		for s in steps:
			var p := (root + dir * s * 3.0).round()
			var th := 3.0 if s < steps - 2 else 2.0
			ci.draw_rect(Rect2(p, Vector2(3, th)), col if i % 2 == 0 else col.darkened(0.15))
		ci.draw_rect(Rect2((root + dir * length).round(), Vector2(2, 2)), WHITE)


## ====================================================================== texto animado
## Texto dibujado letra a letra: ondula, rebota al aparecer, tiembla, degradado y sombra extruida.
class PixelText extends Control:
	var text := "":
		set(v):
			text = v
			_measure()
	var font_kind := "head"
	var font_size := 16
	var color := WHITE
	var color2 := Color(0, 0, 0, 0)     # si a > 0, degradado por letra
	var outline := 4
	var outline_color := INK
	var extrude := 2                    # sombra extruida en píxeles
	var extrude_color := RED_DARK
	var wave := 1.5
	var wave_speed := 4.0
	var shake := 0.0
	var appear := 999.0                 # letras visibles (animable)
	var align := 0                      # 0 izq, 1 centro
	var flash := 0.0
	var _t := 0.0
	var _w := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_measure()

	func _measure() -> void:
		var f := UIKit.font(font_kind)
		_w = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		custom_minimum_size = Vector2(_w, font_size)
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		flash = max(0.0, flash - delta * 3.0)
		queue_redraw()

	func _draw() -> void:
		var f := UIKit.font(font_kind)
		var x := 0.0
		if align == 1:
			x = (size.x - _w) / 2.0
		var asc := f.get_ascent(font_size)
		var n := text.length()
		for i in n:
			var ch := text[i]
			var cw := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var vis := clampf(appear - i, 0.0, 1.0)
			if vis > 0.0:
				var drop := (1.0 - _ease_out_back(vis)) * -font_size * 0.8
				var y := asc + sin(_t * wave_speed + i * 0.55) * wave + drop
				var sx := 0.0
				if shake > 0.0:
					sx = randf_range(-shake, shake)
					y += randf_range(-shake, shake)
				var pos := Vector2(round(x + sx), round(y))
				var c := color
				if color2.a > 0.0:
					c = color.lerp(color2, 0.5 + 0.5 * sin(_t * 2.0 + i * 0.7))
				c = c.lerp(WHITE, flash)
				c.a *= vis
				for e in range(extrude, 0, -1):
					f.draw_char_outline(get_canvas_item(), pos + Vector2(0, e), ch.unicode_at(0), font_size, outline, Color(outline_color, c.a))
					f.draw_char(get_canvas_item(), pos + Vector2(0, e), ch.unicode_at(0), font_size, Color(extrude_color, c.a))
				f.draw_char_outline(get_canvas_item(), pos, ch.unicode_at(0), font_size, outline, Color(outline_color, c.a))
				f.draw_char(get_canvas_item(), pos, ch.unicode_at(0), font_size, c)
			x += cw

	static func _ease_out_back(t: float) -> float:
		var c1 := 1.70158
		var c3 := c1 + 1.0
		return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)

static func pixel_text(text: String, size: int, kind := "head", color := WHITE) -> PixelText:
	var p := PixelText.new()
	p.font_kind = kind
	p.font_size = size
	p.color = color
	p.text = text
	return p

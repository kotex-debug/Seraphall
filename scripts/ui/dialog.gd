extends CanvasLayer
## Cuadro de diálogo con efecto máquina de escribir. Líneas: [hablante, [es, en]].

var panel: Panel
var name_l: Label
var text_l: Label
var hint: Label
var _lines: Array = []
var _i := 0
var _done: Callable
var _open := false
var _tw: Tween
var _auto_t := 0.0
var _cinematic := false

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = Panel.new()
	panel.position = Vector2(70, 276)
	panel.size = Vector2(500, 62)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.08, 0.92)
	sb.border_color = Color(0.75, 0.6, 0.35, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	name_l = _mk(9, Color(1, 0.8, 0.45))
	name_l.position = Vector2(10, 5)
	panel.add_child(name_l)
	text_l = _mk(9, Color(0.95, 0.93, 0.9))
	text_l.position = Vector2(10, 19)
	text_l.size = Vector2(480, 36)
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(text_l)
	hint = _mk(7, Color(0.7, 0.65, 0.6))
	hint.text = "▼"
	hint.position = Vector2(486, 50)
	panel.add_child(hint)
	panel.visible = false

func _mk(size: int, color: Color) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 2
	ls.outline_color = Color(0, 0, 0, 0.8)
	l.label_settings = ls
	return l

func is_open() -> bool:
	return _open

func play(lines: Array, on_done: Callable, cinematic := false) -> void:
	_lines = lines
	_i = 0
	_done = on_done
	_cinematic = cinematic
	if lines.is_empty():
		_open = false
		if on_done.is_valid():
			on_done.call_deferred()
		return
	_open = true
	panel.visible = true
	_show_line()

func _show_line() -> void:
	var ln: Array = _lines[_i]
	name_l.text = ln[0]
	text_l.text = G.L(ln[1])
	text_l.visible_ratio = 0.0
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(text_l, "visible_ratio", 1.0, text_l.text.length() * 0.022)
	_auto_t = 2.2 + text_l.text.length() * 0.045
	Audio.sfx("ui_move", -10.0)

func _advance() -> void:
	if text_l.visible_ratio < 1.0:
		if _tw:
			_tw.kill()
		text_l.visible_ratio = 1.0
		return
	_i += 1
	if _i >= _lines.size():
		_open = false
		panel.visible = false
		if _done.is_valid():
			_done.call()
		return
	_show_line()

func _process(delta: float) -> void:
	if not _open:
		return
	hint.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	if G.autotest != "":
		_auto_t = min(_auto_t, 0.05)
	if _cinematic or G.autotest != "":
		_auto_t -= delta
		if _auto_t <= 0.0:
			text_l.visible_ratio = 1.0
			_advance()

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("dash") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

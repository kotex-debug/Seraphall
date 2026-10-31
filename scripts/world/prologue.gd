extends CanvasLayer
## Prólogo opcional: enseña la interfaz y el combate paso a paso en el Santuario, antes del Carcelero.

var world: Node
var step := -1
var _count := 0
var _dist := 0.0
var _last := Vector2.ZERO
var _t := 0.0
var _pop := 0.0
var _dummy: Enemy
var _done_t := 0.0
var box: PrologueBox

const STEPS := [
	{"id": "move", "need": 1, "keys": ["up", "left", "down", "right"], "title": ["MOVERSE", "MOVE"],
		"text": ["Usa %s para caminar. Apunta con el ratón: tu personaje siempre mira hacia el cursor.", "Use %s to walk. Aim with the mouse: your character always faces the cursor."]},
	{"id": "dash", "need": 2, "keys": ["dash"], "title": ["ESQUIVAR", "DASH"],
		"text": ["Pulsa %s para esquivar. Mientras esquivas eres invulnerable, y si lo haces justo antes de un golpe el tiempo se frena: es el Instante.", "Press %s to dash. You can't be hurt while dashing, and if you do it right before a hit, time slows down: that's the Instant."]},
	{"id": "attack", "need": 4, "keys": ["attack"], "title": ["ATACAR", "ATTACK"],
		"text": ["Pulsa %s para atacar al Hueco de prácticas. Encadena golpes: cada uno es distinto y el último remata.", "Press %s to attack the training Husk. Chain your hits: each one is different and the last one finishes."]},
	{"id": "heavy", "need": 1, "keys": ["heavy"], "title": ["ATAQUE CARGADO", "HEAVY ATTACK"],
		"text": ["Mantén %s para cargar y suéltalo para descargar un golpe que rompe la postura del enemigo.", "Hold %s to charge, then release for a blow that breaks the enemy's posture."]},
	{"id": "parry", "need": 2, "keys": ["parry"], "title": ["BLOQUEAR (PARRY)", "PARRY"],
		"text": ["Pulsa %s justo cuando te vayan a golpear para desviar el ataque. Un parry perfecto aturde al enemigo y devuelve los proyectiles.", "Press %s right as a blow lands to deflect it. A perfect parry stuns the enemy and sends projectiles back."]},
	{"id": "heal", "need": 1, "keys": ["heal"], "title": ["CURARSE", "HEAL"],
		"text": ["Pulsa %s para beber una Lágrima. Tienes pocas, pero se rellenan cada vez que descansas en una Brasa.", "Press %s to drink a Tear. You have few, but they refill whenever you rest at an Ember."]},
	{"id": "brasa", "need": 1, "keys": ["interact"], "title": ["LA BRASA", "THE EMBER"],
		"text": ["Acércate a la Brasa del centro y pulsa %s. Las Brasas guardan la partida, te curan y son donde vuelves al morir.", "Walk to the Ember in the centre and press %s. Embers save your game, heal you, and are where you return after dying."]},
	{"id": "menu", "need": 1, "keys": ["menu"], "title": ["EL MENÚ", "THE MENU"],
		"text": ["Pulsa %s para abrir el menú: personaje, habilidades, inventario, armas, misiones y controles.", "Press %s to open the menu: character, skills, inventory, weapons, quests and controls."]},
	{"id": "map", "need": 1, "keys": ["map"], "title": ["EL MAPA", "THE MAP"],
		"text": ["Pulsa %s para ver el mapa. Arriba a la derecha tienes también el minimapa.", "Press %s to see the map. There is also a minimap in the top right corner."]},
	{"id": "done", "need": 1, "keys": [], "title": ["PRÓLOGO COMPLETADO", "PROLOGUE COMPLETE"],
		"text": ["Recuerda: cada muerte te arranca una pluma. Con pocas plumas golpeas más fuerte, pero aguantas menos. Habla con Brenna y busca al Carcelero.", "Remember: every death tears away a feather. With few feathers you hit harder, but you last less. Talk to Brenna and find the Jailer."]},
]

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	box = PrologueBox.new()
	box.owner_p = self
	box.position = Vector2(150, 62)
	box.size = Vector2(340, 74)
	add_child(box)
	_next()

func _next() -> void:
	step += 1
	_count = 0
	_dist = 0.0
	_pop = 1.0
	if step >= STEPS.size():
		queue_free()
		return
	Audio.sfx("quest", -6.0)
	var id: String = STEPS[step].id
	if id == "attack" and (_dummy == null or not is_instance_valid(_dummy)):
		var lp: Player = world.local_player()
		if lp:
			world._spawn_extra("hueco", lp.global_position + Vector2(60, 0))
			_dummy = world.enemies[-1]
			_dummy.dmg_mult = 0.25
			_dummy.max_hp = 400.0
			_dummy.hp = 400.0
	if id == "brasa" and Prog.flags.get("brasa_sanct", false):
		call_deferred("_next")
	if id == "done":
		Prog.flags["prologue_done"] = true
		if _dummy and is_instance_valid(_dummy) and _dummy.is_alive():
			world._enemy_die(_dummy.idx)

func text() -> String:
	var s: Dictionary = STEPS[step]
	var keys := []
	for k in s.keys:
		keys.append("[" + G.key_label(k) + "]")
	var t := G.L(s.text)
	if t.contains("%s"):
		t = t % ("".join(keys) if s.id == "move" else " / ".join(keys))
	return t

func _input(event: InputEvent) -> void:
	if step < 0 or step >= STEPS.size():
		return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_BACKSPACE:
		Prog.flags["prologue_done"] = true
		queue_free()
		return
	var id: String = STEPS[step].id
	if id in ["dash", "attack", "parry", "heal"] and event.is_action_pressed(STEPS[step].keys[0]):
		_count += 1
	elif id == "heavy" and event.is_action_released("heavy"):
		_count += 1

func _process(delta: float) -> void:
	_t += delta
	_pop = max(0.0, _pop - delta * 3.0)
	if step < 0 or step >= STEPS.size():
		return
	var lp: Player = world.local_player()
	var s: Dictionary = STEPS[step]
	var ok := false
	match s.id:
		"move":
			if lp:
				if _last != Vector2.ZERO:
					_dist += lp.global_position.distance_to(_last)
				_last = lp.global_position
			ok = _dist > 90.0
		"brasa":
			ok = Prog.flags.get("brasa_sanct", false)
		"menu":
			ok = world.menu.visible
		"map":
			ok = world.menu.visible and world.menu.tab == "map"
		"done":
			_done_t += delta
			ok = _done_t > 8.0
		_:
			ok = _count >= int(s.need)
	if ok:
		if s.id != "done":
			Fx.text(lp.global_position + Vector2(0, -30), G.L(["¡BIEN!", "NICE!"]), Color(0.6, 1, 0.7), 10) if lp else null
		_next()

class PrologueBox extends Control:
	var owner_p: Node
	var t := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var p = owner_p
		if p.step < 0 or p.step >= p.STEPS.size():
			return
		var s: Dictionary = p.STEPS[p.step]
		var o := Vector2(0, -p._pop * 6.0).round()
		UIKit.frame(self, Rect2(o, size), UIKit.GOLD, Color(0.07, 0.03, 0.1, 0.92), 4.0, t)
		var hf := UIKit.font("head")
		var head := G.L(["PRÓLOGO  %d/%d  -  ", "PROLOGUE  %d/%d  -  "]) % [p.step + 1, p.STEPS.size()] + G.L(s.title)
		hf.draw_string_outline(get_canvas_item(), Vector2(12, 16) + o, head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, UIKit.INK)
		hf.draw_string(get_canvas_item(), Vector2(12, 16) + o, head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)
		var bf := UIKit.font("body")
		bf.draw_multiline_string_outline(get_canvas_item(), Vector2(12, 32) + o, p.text(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, 3, 3, UIKit.INK)
		bf.draw_multiline_string(get_canvas_item(), Vector2(12, 32) + o, p.text(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 15, 3, UIKit.WHITE)
		var tf := UIKit.font("title")
		var skip := G.L(["[Retroceso] saltar prólogo", "[Backspace] skip prologue"])
		tf.draw_string(get_canvas_item(), Vector2(size.x - 128, size.y - 6) + o, skip, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UIKit.TEXT_DIM)
		for i in p.STEPS.size():
			var c := UIKit.GOLD if i < p.step else (UIKit.WHITE if i == p.step else Color(0.3, 0.22, 0.35))
			draw_rect(Rect2(Vector2(12 + i * 9, size.y - 10) + o, Vector2(6, 3)), c)

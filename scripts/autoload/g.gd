extends Node
## Global: idioma, textos, ajustes, efectos globales (hit-stop, cámara lenta, temblor).

signal language_changed
signal shake_requested(amount: float, duration: float)
signal flash_requested(color: Color, duration: float)
signal toast_requested(text: String, color: Color)
signal shockwave_requested(pos: Vector2, strength: float, duration: float)
signal chroma_requested(amount: float, duration: float)
signal punch_requested(amount: float)

var lang := "es"  # "es" | "en"
var music_volume := 0.8
var sfx_volume := 0.9
var autotest := ""  # modo de prueba automática (línea de comandos)

const SETTINGS_PATH := "user://settings.cfg"

var _slow_until := {}  # id -> [escala, fin_ms]

# ------------------------------------------------------------------ textos
const TXT := {
	"title_sub": ["La Caída del Serafín", "The Fall of the Seraph"],
	"new_game": ["Nueva partida", "New game"],
	"continue": ["Continuar", "Continue"],
	"host": ["Crear partida cooperativa", "Host co-op game"],
	"join": ["Unirse con código", "Join with code"],
	"language": ["Idioma: Español", "Language: English"],
	"quit": ["Salir", "Quit"],
	"back": ["Volver", "Back"],
	"enter_code": ["Introduce el código de partida", "Enter the game code"],
	"connect": ["Conectar", "Connect"],
	"connecting": ["Conectando...", "Connecting..."],
	"conn_failed": ["No se pudo conectar. Revisa el código.", "Could not connect. Check the code."],
	"host_wait": ["Esperando a tu compañero... Comparte este código:", "Waiting for your partner... Share this code:"],
	"code_online": ["Código online", "Online code"],
	"code_lan": ["Código red local", "LAN code"],
	"upnp_ok": ["Puerto abierto automáticamente (UPnP).", "Port opened automatically (UPnP)."],
	"upnp_fail": ["UPnP no disponible: el código online puede necesitar abrir el puerto 24680 UDP.", "UPnP unavailable: online code may require opening UDP port 24680."],
	"start_alone": ["Empezar (tu compañero puede unirse luego)", "Start (your partner can join later)"],
	"partner_joined": ["¡Tu compañero se ha unido!", "Your partner has joined!"],
	"partner_left": ["Tu compañero se ha ido.", "Your partner has left."],
	"host_left": ["El anfitrión cerró la partida.", "The host closed the game."],
	"press_any": ["Pulsa cualquier tecla", "Press any key"],
	"controls": ["WASD mover · Ratón apuntar · Clic izq. ataque · Clic der. pesado (mantén) · Espacio dash · Shift parry · Q/E hechizos · R Ira · C curar · X objeto · F interactuar · Tab menú · M mapa",
		"WASD move · Mouse aim · LMB attack · RMB heavy (hold) · Space dash · Shift parry · Q/E spells · R Wrath · C heal · X item · F interact · Tab menu · M map"],
	"interact": ["[F] %s", "[F] %s"],
	"rest": ["Descansar", "Rest"],
	"light_brasa": ["Encender la Brasa", "Kindle the Ember"],
	"talk": ["Hablar", "Talk"],
	"open": ["Abrir", "Open"],
	"revive": ["Mantén F para revivir", "Hold F to revive"],
	"brasa_lit": ["BRASA ENCENDIDA", "EMBER KINDLED"],
	"you_died": ["HAS CAÍDO", "YOU HAVE FALLEN"],
	"downed": ["Caído - tu compañero puede revivirte", "Downed - your partner can revive you"],
	"archon_defeated": ["ARCONTE DERROTADO", "ARCHON DEFEATED"],
	"enemy_felled": ["ENEMIGO ABATIDO", "ENEMY FELLED"],
	"level_up": ["¡Subes de nivel!", "Level up!"],
	"ecos": ["Ecos", "Echoes"],
	"feathers": ["Fragmentos de Pluma", "Feather Shards"],
	"level": ["Nivel", "Level"],
	"skill_points": ["Puntos de habilidad", "Skill points"],
	"attr_points": ["Puntos de atributo", "Attribute points"],
	"tab_char": ["Personaje", "Character"],
	"tab_skills": ["Habilidades", "Skills"],
	"tab_weapons": ["Armas", "Weapons"],
	"tab_quests": ["Misiones", "Quests"],
	"tab_options": ["Opciones", "Options"],
	"vigor": ["Vigor", "Vigor"], "aguante": ["Aguante", "Endurance"], "fuerza": ["Fuerza", "Strength"],
	"destreza": ["Destreza", "Dexterity"], "fe": ["Fe", "Faith"], "arcano": ["Arcano", "Arcane"],
	"vigor_d": ["Aumenta la vida máxima.", "Increases max health."],
	"aguante_d": ["Aumenta el aguante y su recuperación.", "Increases stamina and its recovery."],
	"fuerza_d": ["Daño con armas pesadas y postura.", "Heavy weapon damage and poise."],
	"destreza_d": ["Daño con armas ágiles y críticos.", "Agile weapon damage and crits."],
	"fe_d": ["Daño de hechizos y Luz máxima.", "Spell damage and max Light."],
	"arcano_d": ["Estados alterados y Ecos obtenidos.", "Status effects and Echoes gained."],
	"buy_level": ["Subir nivel (%d Ecos)", "Level up (%d Echoes)"],
	"only_at_brasa": ["Solo puedes subir de nivel descansando en una Brasa.", "You can only level up while resting at an Ember."],
	"unlock": ["Desbloquear", "Unlock"],
	"unlocked": ["Desbloqueado", "Unlocked"],
	"locked_req": ["Requiere nodos anteriores", "Requires previous nodes"],
	"locked_archon": ["Requiere derrotar a Seravel", "Requires defeating Seravel"],
	"cost": ["Coste: %d", "Cost: %d"],
	"equip": ["Equipar", "Equip"],
	"equipped": ["Equipada", "Equipped"],
	"upgrade": ["Mejorar", "Upgrade"],
	"upgrade_cost": ["Mejorar a +%d: %d Ecos, %d Fragmentos", "Upgrade to +%d: %d Echoes, %d Shards"],
	"upgrade_at_forge": ["Las mejoras se hacen en la forja de Brenna.", "Upgrades are done at Brenna's forge."],
	"max_level": ["Nivel máximo", "Max level"],
	"damage": ["Daño", "Damage"], "speed": ["Velocidad", "Speed"], "reach": ["Alcance", "Reach"], "combo": ["Combo", "Combo"],
	"scaling": ["Escalado", "Scaling"],
	"active_quests": ["Misiones activas", "Active quests"],
	"done_quests": ["Completadas", "Completed"],
	"quest_new": ["NUEVA MISIÓN", "NEW QUEST"],
	"quest_done": ["MISIÓN COMPLETADA", "QUEST COMPLETE"],
	"reward": ["Recompensa", "Reward"],
	"music_vol": ["Volumen música", "Music volume"],
	"sfx_vol": ["Volumen efectos", "SFX volume"],
	"save_quit": ["Guardar y salir al menú", "Save and quit to menu"],
	"close": ["Cerrar [Tab]", "Close [Tab]"],
	"not_enough": ["No tienes suficientes recursos.", "Not enough resources."],
	"game_saved": ["Partida guardada", "Game saved"],
	"new_weapon": ["Nueva arma: %s", "New weapon: %s"],
	"new_spell": ["Nuevo poder: %s", "New power: %s"],
	"flask_up": ["+1 Lágrima", "+1 Tear Flask"],
	"demo_end_title": ["FIN DE LA DEMO", "END OF DEMO"],
	"demo_end_body": ["El Estrato 2, el Bosque de Plumas Muertas, te espera...", "Stratum 2, the Forest of Dead Feathers, awaits..."],
	"area_sanct": ["Santuario de la Última Brasa", "Sanctuary of the Last Ember"],
	"area_chains": ["Pasillo de las Cadenas", "Hall of Chains"],
	"area_gallery": ["Galería Rota", "Broken Gallery"],
	"area_yard": ["Patio del Carcelero", "Jailer's Yard"],
	"area_circle": ["Círculo de la Guardiana", "Circle of the Warden"],
	"area_mirador": ["Mirador del Ala Rota", "Broken Wing Overlook"],
	"contemplate": ["Contemplar", "Contemplate"],
	"memory_got": ["RECUERDO RECUPERADO", "MEMORY RECOVERED"],
	"tab_inventory": ["Inventario", "Inventory"],
	"tab_map": ["Mapa", "Map"],
	"use": ["Usar", "Use"],
	"quick_slot": ["Asignar a [X]", "Assign to [X]"],
	"consumables": ["Consumibles", "Consumables"],
	"amulets": ["Amuletos", "Amulets"],
	"key_items": ["Objetos clave", "Key items"],
	"materials": ["Materiales", "Materials"],
	"memories": ["Recuerdos", "Memories"],
	"unequip": ["Quitar", "Remove"],
	"item_got": ["Obtienes: %s", "Obtained: %s"],
	"you_are_here": ["Estás aquí", "You are here"],
	"unexplored": ["Zona sin explorar", "Unexplored area"],
	"stratum1": ["ESTRATO I - VESTÍBULO DE CENIZA", "STRATUM I - ASH VESTIBULE"],
	"gate_locked": ["La puerta está sellada. El Carcelero guarda la llave.", "The gate is sealed. The Jailer holds the key."],
	"key_got": ["Obtienes la Llave del Vestíbulo", "You obtain the Vestibule Key"],
	"skip": ["[Espacio] saltar", "[Space] skip"],
	"resume": ["Continuar", "Resume"],
	"lance": ["Lanza de Luz", "Lance of Light"], "nova": ["Nova de Ceniza", "Ash Nova"], "orbit": ["Espadas Orbitantes", "Orbiting Blades"],
	"wrath": ["Ira Seráfica", "Seraphic Wrath"],
	"boss_seravel": ["SERAVEL, GUARDIANA DE LAS PUERTAS", "SERAVEL, WARDEN OF THE GATES"],
	"boss_carcelero": ["EL CARCELERO", "THE JAILER"],
	"hueco": ["Hueco", "Husk"], "acolito": ["Acólito", "Acolyte"], "bestia": ["Bestia de Ceniza", "Ash Beast"],
	"execute": ["¡EJECUCIÓN!", "EXECUTION!"],
	"parry": ["¡PARRY!", "PARRY!"],
	"perfect": ["INSTANTE", "INSTANT"],
	"broken": ["¡POSTURA ROTA!", "POSTURE BROKEN!"],
}

func T(key: String) -> String:
	if not TXT.has(key):
		return key
	return TXT[key][0 if lang == "es" else 1]

func L(pair) -> String:
	## Devuelve el texto según idioma desde un Array [es, en] o un String.
	if pair is Array:
		return pair[0 if lang == "es" else 1]
	return str(pair)

func toggle_language() -> void:
	lang = "en" if lang == "es" else "es"
	save_settings()
	language_changed.emit()

# ------------------------------------------------------------------ ajustes
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest="):
			autotest = a.substr(11)
	_setup_input()

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		lang = cf.get_value("general", "lang", "es")
		music_volume = cf.get_value("audio", "music", 0.8)
		sfx_volume = cf.get_value("audio", "sfx", 0.9)
	else:
		lang = "es"

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("general", "lang", lang)
	cf.set_value("audio", "music", music_volume)
	cf.set_value("audio", "sfx", sfx_volume)
	cf.save(SETTINGS_PATH)

func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"dash": [KEY_SPACE], "parry": [KEY_SHIFT], "spell1": [KEY_Q], "spell2": [KEY_E], "wrath": [KEY_R],
		"heal": [KEY_C], "interact": [KEY_F], "menu": [KEY_TAB, KEY_I], "pause": [KEY_ESCAPE], "item": [KEY_X],
		"map": [KEY_M],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var mouse := {"attack": MOUSE_BUTTON_LEFT, "heavy": MOUSE_BUTTON_RIGHT}
	for action in mouse:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var mb := InputEventMouseButton.new()
		mb.button_index = mouse[action]
		InputMap.action_add_event(action, mb)
	# mando
	var pad := {"dash": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "heavy": JOY_BUTTON_Y, "parry": JOY_BUTTON_LEFT_SHOULDER,
		"spell1": JOY_BUTTON_RIGHT_SHOULDER, "interact": JOY_BUTTON_B, "menu": JOY_BUTTON_BACK, "pause": JOY_BUTTON_START,
		"heal": JOY_BUTTON_DPAD_UP, "wrath": JOY_BUTTON_RIGHT_STICK, "spell2": JOY_BUTTON_DPAD_RIGHT, "item": JOY_BUTTON_DPAD_DOWN}
	for action in pad:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pad[action]
		InputMap.action_add_event(action, jb)
	var axes := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0]
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)

# ------------------------------------------------------------------ "juice" global
func hitstop(duration := 0.06, scale := 0.03) -> void:
	slowmo("hitstop", scale, duration)

func slowmo(id: String, scale: float, duration: float) -> void:
	if Net.is_online():
		return  # en cooperativo no alteramos el tiempo global
	_slow_until[id] = [scale, Time.get_ticks_msec() + int(duration * 1000.0)]

func shake(amount := 3.0, duration := 0.2) -> void:
	shake_requested.emit(amount, duration)

func flash(color := Color(1, 1, 1, 0.5), duration := 0.12) -> void:
	flash_requested.emit(color, duration)

func shockwave(pos: Vector2, strength := 1.0, duration := 0.5) -> void:
	shockwave_requested.emit(pos, strength, duration)

func chroma(amount := 1.0, duration := 0.3) -> void:
	chroma_requested.emit(amount, duration)

func punch(amount := 0.05) -> void:
	punch_requested.emit(amount)

func toast(text: String, color := Color(1, 0.9, 0.6)) -> void:
	toast_requested.emit(text, color)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var s := 1.0
	for id in _slow_until.keys():
		var v = _slow_until[id]
		if now >= v[1]:
			_slow_until.erase(id)
		else:
			s = min(s, v[0])
	Engine.time_scale = s

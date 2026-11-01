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
var look := {}          # aspecto del personaje (creador)
# accesibilidad
var shake_mult := 1.0
var flash_mult := 1.0
var tele_boost := false   # telegráficos más gruesos y visibles
var photo_mode := false
var bindings := {}        # acción -> "k:<keycode>" | "m:<botón>" (personalizadas por el jugador)
const REBINDABLE := ["up", "down", "left", "right", "attack", "heavy", "dash", "parry", "spell1", "spell2", "wrath",
	"heal", "item", "interact", "menu", "map", "photo"]

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
	"enter_code": ["Introduce el código de partida (o la IP del anfitrión)", "Enter the game code (or the host's IP)"],
	"connect": ["Conectar", "Connect"],
	"connecting": ["Conectando...", "Connecting..."],
	"conn_failed": ["No se pudo conectar. Revisa el código.", "Could not connect. Check the code."],
	"host_wait": ["Esperando a tu compañero... Comparte este código:", "Waiting for your partner... Share this code:"],
	"code_online": ["Código online", "Online code"],
	"code_lan": ["Código de red local", "LAN code"],
	"upnp_ok": ["Puerto abierto automáticamente (UPnP).", "Port opened automatically (UPnP)."],
	"upnp_fail": ["UPnP no disponible: puede que tengas que abrir el puerto UDP 24680 para usar el código online.", "UPnP unavailable: online code may require opening UDP port 24680."],
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
	"revive": ["Mantén F para reanimar", "Hold F to revive"],
	"brasa_lit": ["BRASA ENCENDIDA", "EMBER KINDLED"],
	"you_died": ["HAS CAÍDO", "YOU HAVE FALLEN"],
	"downed": ["Has caído: tu compañero puede reanimarte", "Downed - your partner can revive you"],
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
	"vigor_d": ["Más vida máxima.", "Increases max health."],
	"aguante_d": ["Más aguante, y se recupera antes.", "Increases stamina and its recovery."],
	"fuerza_d": ["Más daño con armas pesadas y más castigo a la postura.", "Heavy weapon damage and poise."],
	"destreza_d": ["Más daño con armas ágiles y más críticos.", "Agile weapon damage and crits."],
	"fe_d": ["Hechizos más fuertes y más Luz máxima.", "Spell damage and max Light."],
	"arcano_d": ["Efectos de estado más potentes y más Ecos al vencer.", "Status effects and Echoes gained."],
	"buy_level": ["Subir nivel (%d Ecos)", "Level up (%d Echoes)"],
	"only_at_brasa": ["Solo puedes subir de nivel mientras descansas en una Brasa.", "You can only level up while resting at an Ember."],
	"unlock": ["Desbloquear", "Unlock"],
	"unlocked": ["Desbloqueado", "Unlocked"],
	"locked_req": ["Requiere los nodos anteriores", "Requires previous nodes"],
	"locked_archon": ["Requiere derrotar a Seravel", "Requires defeating Seravel"],
	"cost": ["Coste: %d", "Cost: %d"],
	"equip": ["Equipar", "Equip"],
	"equipped": ["Equipada", "Equipped"],
	"upgrade": ["Mejorar", "Upgrade"],
	"upgrade_cost": ["Mejorar a +%d: %d Ecos y %d Fragmentos", "Upgrade to +%d: %d Echoes, %d Shards"],
	"upgrade_at_forge": ["Las mejoras se hacen en la fragua de Brenna.", "Upgrades are done at Brenna's forge."],
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
	"not_enough": ["No tienes recursos suficientes.", "Not enough resources."],
	"game_saved": ["Partida guardada", "Game saved"],
	"new_weapon": ["Nueva arma: %s", "New weapon: %s"],
	"new_spell": ["Nuevo poder: %s", "New power: %s"],
	"flask_up": ["+1 Lágrima", "+1 Tear Flask"],
	"demo_end_title": ["FIN DEL ESTRATO I", "END OF STRATUM I"],
	"demo_end_body": ["El descenso continúa en el Estrato II, el Bosque de Plumas Muertas.\nTu destino se inclina hacia: %s", "The descent continues in Stratum II, the Forest of Dead Feathers.\nYour fate leans towards: %s"],
	"destiny": ["DESTINO", "FATE"],
	"route_wings": ["ALAS ABIERTAS", "OPEN WINGS"], "route_throne": ["EL TRONO VACÍO", "THE EMPTY THRONE"],
	"route_wings_d": ["Romper la Espiral y liberar a los caídos.", "Break the Spiral and free the fallen."],
	"route_throne_d": ["Ocupar el trono del Arquitecto y reinar sobre la Espiral.", "Take the Architect's throne and rule the Spiral."],
	"route_hint": ["Perdonar, recordar y conservar tus plumas te acerca a las Alas. Ejecutar, jurar y perder plumas, al Trono.", "Sparing, remembering and keeping your feathers lean towards the Wings. Executing, swearing oaths and losing feathers, towards the Throne."],
	"area_sanct": ["Santuario de la Última Brasa", "Sanctuary of the Last Ember"],
	"area_chains": ["Pasillo de las Cadenas", "Hall of Chains"],
	"area_gallery": ["Galería Rota", "Broken Gallery"],
	"area_yard": ["Patio del Carcelero", "Jailer's Yard"],
	"area_circle": ["Círculo de la Guardiana", "Circle of the Warden"],
	"area_mirador": ["Mirador del Ala Rota", "Broken Wing Overlook"],
	"area_celdas": ["Las Celdas de Espera", "The Waiting Cells"],
	"area_atrio": ["Atrio de las Voces", "Atrium of Voices"],
	"area_juicio": ["Antesala del Juicio", "Antechamber of Judgement"],
	"trial_celdas": ["LAS CELDAS SE ABREN", "THE CELLS OPEN"],
	"trial_umbral": ["EL UMBRAL DEL JUICIO", "THE THRESHOLD OF JUDGEMENT"],
	"trial_label": ["PRUEBA", "TRIAL"],
	"trial_wave": ["OLEADA %d / %d", "WAVE %d / %d"],
	"trial_done": ["PRUEBA SUPERADA", "TRIAL CLEARED"],
	"custodio_title": ["EL CUSTODIO DEL UMBRAL", "THE THRESHOLD WARDEN"],
	"shortcut_open": ["Se oye una reja abrirse a lo lejos: ya hay atajo al Pasillo de las Cadenas.", "A gate grinds open in the distance: there's now a shortcut to the Hall of Chains."],
	"judgement_open": ["La luz se aparta. El Círculo de la Guardiana te espera.", "The light parts. The Warden's Circle awaits."],
	"atrio_solved": ["EL CORO TE DEJA PASAR", "THE CHOIR LETS YOU PASS"],
	"atrio_fail": ["DISONANCIA", "DISSONANCE"],
	"ring_bell": ["Tañer la campana", "Ring the bell"],
	"read": ["Leer", "Read"],
	"lore_title": ["Inscripción", "Inscription"],
	"boss_phase": ["FASE %s", "PHASE %s"],
	"sub_carcelero": ["Guardián de la Llave", "Keeper of the Key"],
	"sub_choir": ["Tres voces, una sola alma", "Three voices, one soul"],
	"sub_seravel": ["Arconte del Estrato I · La primera en caer", "Archon of Stratum I · The first to fall"],
	"sub_custodio": ["Estatua que aún recuerda su juramento", "A statue that still remembers its oath"],
	"sealed_hint": ["Algo cierra el paso. Quizá haya otra forma de abrirlo.", "Something bars the way. Perhaps there's another way to open it."],
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
	"boss_choir": ["EL CORO HUECO", "THE HOLLOW CHOIR"],
	"area_nimbo": ["Sala del Nimbo", "Hall of the Nimbus"],
	"area_choir": ["Nave del Coro", "Choir Nave"],
	"difficulty": ["Dificultad", "Difficulty"],
	"tab_controls": ["Controles", "Controls"],
	"choose_diff": ["ELIGE TU CAMINO", "CHOOSE YOUR PATH"],
	"rank": ["RANGO", "RANK"],
	"ascension": ["ASCENSIÓN", "ASCENSION"],
	"asc_won": ["ASCENSIÓN SUPERADA", "ASCENSION CLEARED"],
	"asc_failed": ["ASCENSIÓN FALLIDA", "ASCENSION FAILED"],
	"combo_hits": ["GOLPES", "HITS"],
	"buy": ["Comprar", "Buy"],
	"sold_out": ["Agotado", "Sold out"],
	"engrave": ["Grabar", "Engrave"],
	"svc_ozias": ["OZIAS - GRABADOS", "OZIAS - ENGRAVINGS"], "svc_ilse": ["MADRE ILSE - LÁGRIMAS", "MOTHER ILSE - TEARS"],
	"svc_nyx": ["NYX - TIENDA", "NYX - SHOP"], "svc_velaria": ["SOR VELARIA - ASCENSIÓN", "SISTER VELARIA - ASCENSION"],
	"feather_torn": ["TE HAN ARRANCADO UNA PLUMA", "A FEATHER HAS BEEN TORN AWAY"],
	"desplumado_mode": ["DESPLUMADO", "FEATHERLESS"],
	"offer_feather": ["Encender (cuesta una pluma)", "Offer a feather and kindle"],
	"no_feathers": ["No te quedan plumas que ofrecer.", "You have no feathers left to offer."],
	"shadow_rises": ["TU SOMBRA SE ALZA", "YOUR SHADOW RISES"],
	"shadow_name": ["Sombra del Desplumado", "Shade of the Featherless"],
	"spare": ["Perdonar", "Spare"], "spared": ["ARCONTE PERDONADO", "ARCHON SPARED"],
	"cross_wings": ["¡ALAS CRUZADAS!", "CROSSED WINGS!"],
	"catch_feather": ["¡Atrapa su pluma!", "Catch their feather!"],
	"ev_ash": ["LLUVIA DE CENIZA", "ASHFALL"], "ev_eclipse": ["ECLIPSE DEL NIMBO", "NIMBUS ECLIPSE"],
	"ev_ash_d": ["Los enemigos arden con más fuerza. Mejor botín.", "Enemies burn fiercer. Better loot."],
	"ev_eclipse_d": ["La luz se apaga: enemigos más fuertes, el doble de Ecos.", "The light dies: stronger enemies, double Echoes."],
	"ev_end": ["El cielo se calma.", "The sky calms."],
	"reflect": ["¡DEVUELTO!", "REFLECTED!"],
	"photo": ["MODO FOTO", "PHOTO MODE"],
	"ng_plus": ["SEGUNDO DESCENSO", "SECOND DESCENT"],
	"create_char": ["CREA TU DESPLUMADO", "CREATE YOUR FEATHERLESS"],
	"begin_descent": ["COMENZAR EL DESCENSO", "BEGIN THE DESCENT"],
	"randomize": ["ALEATORIO", "RANDOM"],
	"body": ["Cuerpo", "Body"], "girl": ["Chica", "Girl"], "boy": ["Chico", "Boy"], "hairstyle": ["Peinado", "Hairstyle"],
	"hair_col": ["Pelo", "Hair"], "skin": ["Piel", "Skin"], "eye": ["Ojos", "Eyes"], "cloak": ["Capa", "Cloak"],
	"armor": ["Armadura", "Armor"], "wing": ["Alas", "Wings"], "halo": ["Aureola", "Halo"], "char_name": ["Nombre", "Name"],
	"access": ["Accesibilidad", "Accessibility"], "shake_opt": ["Temblor de pantalla", "Screen shake"],
	"flash_opt": ["Destellos", "Flashes"], "tele_opt": ["Avisos de ataque más visibles", "Bold telegraphs"],
	"on": ["SÍ", "ON"], "off": ["NO", "OFF"],
	"stock": ["Quedan %d", "%d left"],
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
		look = cf.get_value("player", "look", {})
		shake_mult = cf.get_value("access", "shake", 1.0)
		flash_mult = cf.get_value("access", "flash", 1.0)
		tele_boost = cf.get_value("access", "tele", false)
		bindings = cf.get_value("controls", "bindings", {})
	else:
		lang = "es"

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("general", "lang", lang)
	cf.set_value("audio", "music", music_volume)
	cf.set_value("audio", "sfx", sfx_volume)
	cf.set_value("player", "look", look)
	cf.set_value("access", "shake", shake_mult)
	cf.set_value("access", "flash", flash_mult)
	cf.set_value("access", "tele", tele_boost)
	cf.set_value("controls", "bindings", bindings)
	cf.save(SETTINGS_PATH)

func _setup_input() -> void:
	var keys := {
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"dash": [KEY_SHIFT], "heavy": [KEY_SPACE], "spell1": [KEY_Q], "spell2": [KEY_E], "wrath": [KEY_R],
		"heal": [KEY_C], "interact": [KEY_F], "menu": [KEY_TAB, KEY_I], "pause": [KEY_ESCAPE], "item": [KEY_X],
		"map": [KEY_M], "photo": [KEY_P], "shot": [KEY_F12],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var mouse := {"attack": MOUSE_BUTTON_LEFT, "parry": MOUSE_BUTTON_RIGHT}
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
	apply_bindings()
	var axes := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0]
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)

# ------------------------------------------------------------------ controles
func _event_from(code: String) -> InputEvent:
	if code.begins_with("m:"):
		var mb := InputEventMouseButton.new()
		mb.button_index = int(code.substr(2))
		return mb
	var ev := InputEventKey.new()
	ev.physical_keycode = int(code.substr(2))
	return ev

func apply_bindings() -> void:
	## Sustituye teclado/ratón de cada acción personalizada (el mando se conserva)
	for action in bindings:
		if not InputMap.has_action(action):
			continue
		for e in InputMap.action_get_events(action):
			if e is InputEventKey or e is InputEventMouseButton:
				InputMap.action_erase_event(action, e)
		InputMap.action_add_event(action, _event_from(bindings[action]))

func rebind(action: String, ev: InputEvent) -> void:
	var code := ""
	if ev is InputEventKey:
		code = "k:%d" % (ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
	elif ev is InputEventMouseButton:
		code = "m:%d" % ev.button_index
	else:
		return
	# si otra acción ya usaba esa tecla, se intercambian
	var old := key_code(action)
	for other in REBINDABLE:
		if other != action and key_code(other) == code:
			bindings[other] = old
	bindings[action] = code
	apply_bindings()
	save_settings()

func reset_bindings() -> void:
	bindings = {}
	for action in REBINDABLE:
		InputMap.action_erase_events(action)
	_setup_input()
	save_settings()

func key_code(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return "k:%d" % (e.physical_keycode if e.physical_keycode != 0 else e.keycode)
		if e is InputEventMouseButton:
			return "m:%d" % e.button_index
	return ""

func controls_text() -> String:
	var parts := []
	for pair in [["up", ["mover", "move"]], ["attack", ["atacar", "attack"]], ["heavy", ["ataque cargado (mantén)", "heavy attack (hold)"]],
			["dash", ["esquivar", "dash"]], ["parry", ["desviar", "parry"]], ["heal", ["curarte", "heal"]], ["interact", ["interactuar", "interact"]],
			["menu", ["menú", "menu"]], ["map", ["mapa", "map"]]]:
		var k := key_label(pair[0])
		if pair[0] == "up":
			k = key_label("up") + key_label("left") + key_label("down") + key_label("right")
		parts.append(k + " " + L(pair[1]))
	return " · ".join(parts)

func key_label(action: String) -> String:
	var c := key_code(action)
	if c == "":
		return "-"
	if c.begins_with("m:"):
		var b := int(c.substr(2))
		return L(["CLIC IZQ", "LMB"]) if b == MOUSE_BUTTON_LEFT else (L(["CLIC DER", "RMB"]) if b == MOUSE_BUTTON_RIGHT else (L(["RUEDA", "MMB"]) if b == MOUSE_BUTTON_MIDDLE else "M%d" % b))
	var k := int(c.substr(2))
	var s := OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(k) if k > 0 else k)
	return s.to_upper().replace("SPACE", L(["ESPACIO", "SPACE"])).replace("ESCAPE", "ESC")

# ------------------------------------------------------------------ "juice" global
func hitstop(duration := 0.06, scale := 0.03) -> void:
	slowmo("hitstop", scale, duration)

func slowmo(id: String, scale: float, duration: float) -> void:
	if Net.is_online():
		return  # en cooperativo no alteramos el tiempo global
	_slow_until[id] = [scale, Time.get_ticks_msec() + int(duration * 1000.0)]

func shake(amount := 3.0, duration := 0.2) -> void:
	if shake_mult > 0.01:
		shake_requested.emit(amount * shake_mult, duration)

func flash(color := Color(1, 1, 1, 0.5), duration := 0.12) -> void:
	if flash_mult > 0.01:
		flash_requested.emit(Color(color, color.a * flash_mult), duration)

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

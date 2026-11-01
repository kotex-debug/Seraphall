extends Node
## LOGROS (estilo consola / Play Juegos).
## - Son de tu perfil, no de una partida: valen para todas las partidas y se guardan en user://logros.json.
## - Cada logro da XP. El % de compleción se calcula por XP: el juego base reparte el 100 % y cada DLC
##   añade un 10 % extra (con los dos DLC se puede llegar al 120 %).
## - Hay logros progresivos (con barra: n/meta), ocultos (no se ven hasta conseguirlos) y desafíos de verdad.
## - Al conseguir uno salta un aviso animado (medallón, rayos, plumas y fanfarria).

signal unlocked(id: String)
signal changed

const PATH := "user://logros.json"
const PATH_TEST := "user://logros_test.json"

const PACKS := {
	"base": {"name": ["SERAPHALL", "SERAPHALL"], "share": 100.0},
	"dlc1": {"name": ["DLC I · Los Cielos Rotos", "DLC I · The Broken Heavens"], "share": 10.0},
	"dlc2": {"name": ["DLC II · El Abismo Sin Nombre", "DLC II · The Nameless Abyss"], "share": 10.0},
}
## qué DLC están instalados (todavía ninguno: sus logros se ven, pero bloqueados)
var owned := {"base": true, "dlc1": false, "dlc2": false}

const CATS := {
	"story": {"n": ["Historia", "Story"], "col": Color(1.0, 0.78, 0.4)},
	"explore": {"n": ["Exploración", "Exploration"], "col": Color(0.45, 0.85, 1.0)},
	"combat": {"n": ["Combate", "Combat"], "col": Color(1.0, 0.45, 0.4)},
	"fate": {"n": ["Destino", "Fate"], "col": Color(0.85, 0.65, 1.0)},
	"challenge": {"n": ["Desafío", "Challenge"], "col": Color(1.0, 0.3, 0.45)},
	"secret": {"n": ["Batalla secreta", "Secret battle"], "col": Color(1.0, 0.9, 0.55)},
	"coop": {"n": ["Cooperativo", "Co-op"], "col": Color(0.55, 1.0, 0.7)},
	"dlc": {"n": ["Contenido descargable", "Downloadable content"], "col": Color(0.7, 0.75, 0.85)},
}

## id -> {n: nombre, d: descripción, c: categoría, xp, i: icono, h: oculto, g: meta, s: contador, p: paquete}
const LIST := {
	# ---------------------------------------------------------------- historia (se consiguen jugando)
	"awaken": {"n": ["Despertar", "Awakening"], "d": ["Despierta en el Santuario de la Espiral.", "Wake up in the Sanctuary of the Spiral."], "c": "story", "xp": 5, "i": "feather"},
	"first_brasa": {"n": ["La Primera Llama", "The First Flame"], "d": ["Enciende tu primera Brasa.", "Kindle your first Ember."], "c": "story", "xp": 5, "i": "flame"},
	"brasas": {"n": ["Guardián de las Llamas", "Keeper of the Flames"], "d": ["Enciende todas las Brasas del Estrato I.", "Kindle every Ember of Stratum I."], "c": "story", "xp": 15, "i": "flame", "g": 4, "s": "brasas"},
	"nimbo": {"n": ["Refugio", "Refuge"], "d": ["Llega a la Sala del Nimbo.", "Reach the Nimbus Hall."], "c": "story", "xp": 5, "i": "halo"},
	"jailer": {"n": ["Sin Llave", "Keyless"], "d": ["Derrota al Carcelero.", "Defeat the Jailer."], "c": "story", "xp": 10, "i": "key"},
	"choir": {"n": ["Silencio", "Silence"], "d": ["Haz callar al Coro Hueco.", "Silence the Hollow Choir."], "c": "story", "xp": 15, "i": "bell"},
	"seravel": {"n": ["Las Puertas", "The Gates"], "d": ["Derrota a Seravel, Guardiana de las Puertas.", "Defeat Seravel, Warden of the Gates."], "c": "story", "xp": 25, "i": "wings"},
	"archons": {"n": ["Arcontes del Vestíbulo", "Archons of the Vestibule"], "d": ["Derrota a los tres Arcontes del Estrato I.", "Defeat the three Archons of Stratum I."], "c": "story", "xp": 25, "i": "crown", "g": 3, "s": "archons"},
	"descent": {"n": ["El Primer Descenso", "The First Descent"], "d": ["Completa la misión principal del Estrato I.", "Complete the main quest of Stratum I."], "c": "story", "xp": 25, "i": "book", "g": 7, "s": "main_steps"},
	"memories": {"n": ["Lo Que Fui", "What I Was"], "d": ["Recupera 4 recuerdos contemplando.", "Recover 4 memories by contemplating."], "c": "story", "xp": 15, "i": "eye", "g": 4, "s": "memories"},
	"hymn": {"n": ["El Himno Completo", "The Whole Hymn"], "d": ["Reúne las tres páginas del Himno de la Vigilia.", "Gather all three pages of the Hymn of the Vigil."], "c": "story", "xp": 10, "i": "book", "g": 3, "s": "pages"},
	"echoes": {"n": ["Mil Años Atrás", "A Thousand Years Ago"], "d": ["Presencia todos los ecos del pasado (uno está bien escondido).", "Witness every echo of the past (one is well hidden)."], "c": "story", "xp": 25, "i": "ghost", "g": 4, "s": "echoes"},
	# ---------------------------------------------------------------- exploración
	"secret": {"n": ["Lo que se oculta", "What Lies Hidden"], "d": ["Descubre la Capilla Olvidada.", "Discover the Forgotten Chapel."], "c": "explore", "xp": 15, "i": "door", "h": true},
	"chests": {"n": ["Saqueador de Tumbas", "Tomb Raider"], "d": ["Abre todos los cofres del Estrato I.", "Open every chest in Stratum I."], "c": "explore", "xp": 15, "i": "chest", "g": 9, "s": "chests"},
	"urns": {"n": ["Rompevasijas", "Urn Breaker"], "d": ["Rompe 40 urnas funerarias.", "Break 40 funeral urns."], "c": "explore", "xp": 10, "i": "urn", "g": 40, "s": "urns"},
	"cartographer": {"n": ["Cartógrafo", "Cartographer"], "d": ["Descubre todas las salas del Estrato I.", "Discover every room of Stratum I."], "c": "explore", "xp": 15, "i": "map", "g": 20, "s": "rooms"},
	"lore": {"n": ["Lector de Ruinas", "Reader of Ruins"], "d": ["Lee todas las inscripciones del Estrato I.", "Read every inscription in Stratum I."], "c": "explore", "xp": 10, "i": "book", "g": 9, "s": "lore"},
	"bestiary": {"n": ["Bestiario", "Bestiary"], "d": ["Derrota a cada tipo de criatura del Estrato I.", "Defeat every kind of creature in Stratum I."], "c": "explore", "xp": 15, "i": "skull", "g": 7, "s": "bestiary"},
	"spark": {"n": ["Chispa", "Spark"], "d": ["Encuentra a Chispa, la brasa viva.", "Find Spark, the living ember."], "c": "explore", "xp": 10, "i": "star"},
	"bells": {"n": ["Al Revés", "Backwards"], "d": ["Tañe el Himno de la Vigilia como lo cantaba el Coro.", "Ring the Hymn of the Vigil as the Choir sang it."], "c": "explore", "xp": 10, "i": "bell"},
	# ---------------------------------------------------------------- combate
	"first_blood": {"n": ["Primera Sangre", "First Blood"], "d": ["Derrota a tu primer enemigo.", "Defeat your first enemy."], "c": "combat", "xp": 5, "i": "sword"},
	"kills100": {"n": ["Cien Caídos", "A Hundred Fallen"], "d": ["Derrota a 100 enemigos.", "Defeat 100 enemies."], "c": "combat", "xp": 10, "i": "sword", "g": 100, "s": "kills"},
	"kills500": {"n": ["Exterminio", "Extermination"], "d": ["Derrota a 500 enemigos.", "Defeat 500 enemies."], "c": "combat", "xp": 25, "i": "skull", "g": 500, "s": "kills"},
	"executioner": {"n": ["Mano Firme", "Steady Hand"], "d": ["Ejecuta a 10 enemigos con la postura rota.", "Execute 10 enemies with broken poise."], "c": "combat", "xp": 10, "i": "hand", "g": 10, "s": "executions"},
	"parry": {"n": ["Reflejo Seráfico", "Seraphic Reflex"], "d": ["Desvía 25 ataques o proyectiles con un parry.", "Parry 25 attacks or projectiles."], "c": "combat", "xp": 15, "i": "shield", "g": 25, "s": "parries"},
	"combo": {"n": ["Tormenta de Filos", "Storm of Blades"], "d": ["Encadena un combo de 40 golpes.", "Chain a 40-hit combo."], "c": "combat", "xp": 15, "i": "bolt", "g": 40, "s": "combo"},
	"arsenal": {"n": ["Arsenal Celestial", "Celestial Arsenal"], "d": ["Consigue todas las armas.", "Obtain every weapon."], "c": "combat", "xp": 25, "i": "scythe", "g": 9, "s": "weapons"},
	"forge": {"n": ["Forjado en Luz", "Forged in Light"], "d": ["Mejora un arma hasta +10.", "Upgrade a weapon to +10."], "c": "combat", "xp": 25, "i": "hammer", "g": 10, "s": "upgrade"},
	"level": {"n": ["Ascendido", "Ascended"], "d": ["Alcanza el nivel 15.", "Reach level 15."], "c": "combat", "xp": 15, "i": "star", "g": 15, "s": "level"},
	"synergy": {"n": ["Resonancia", "Resonance"], "d": ["Descubre una sinergia oculta entre amuletos.", "Discover a hidden amulet synergy."], "c": "combat", "xp": 10, "i": "eye"},
	"engrave": {"n": ["Grabado", "Engraved"], "d": ["Graba un arma con Ozias.", "Have Ozias engrave a weapon."], "c": "combat", "xp": 5, "i": "hammer"},
	# ---------------------------------------------------------------- destino
	"spare": {"n": ["Misericordia", "Mercy"], "d": ["Perdona a un Arconte.", "Spare an Archon."], "c": "fate", "xp": 10, "i": "heart"},
	"saint": {"n": ["Santo de la Espiral", "Saint of the Spiral"], "d": ["Perdona a los tres Arcontes del Estrato I.", "Spare all three Archons of Stratum I."], "c": "fate", "xp": 25, "i": "halo", "g": 3, "s": "spared"},
	"oath": {"n": ["Juramentado", "Sworn"], "d": ["Jura lealtad a un Arconte.", "Swear an oath to an Archon."], "c": "fate", "xp": 10, "i": "chain"},
	"featherless": {"n": ["Desplumado", "Featherless"], "d": ["Quédate con 3 plumas o menos.", "Be left with 3 feathers or fewer."], "c": "fate", "xp": 10, "i": "feather"},
	"route_wings": {"n": ["Alas Abiertas", "Open Wings"], "d": ["Derrota a Seravel con la balanza inclinada hacia las Alas.", "Defeat Seravel with the scales tipped towards the Wings."], "c": "fate", "xp": 15, "i": "wings"},
	"route_throne": {"n": ["El Trono Vacío", "The Empty Throne"], "d": ["Derrota a Seravel con la balanza inclinada hacia el Trono.", "Defeat Seravel with the scales tipped towards the Throne."], "c": "fate", "xp": 15, "i": "crown"},
	# ---------------------------------------------------------------- desafíos (los difíciles de verdad)
	"trials": {"n": ["Digno del Juicio", "Worthy of Judgement"], "d": ["Supera las tres pruebas de las antesalas.", "Clear all three antechamber trials."], "c": "challenge", "xp": 15, "i": "scale"},
	"untouched": {"n": ["Intocable", "Untouchable"], "d": ["Derrota a un Arconte sin recibir ni un golpe.", "Defeat an Archon without taking a single hit."], "c": "challenge", "xp": 50, "i": "shield"},
	"dry": {"n": ["Sin Lágrimas", "No Tears"], "d": ["Derrota a Seravel sin beber Lágrimas.", "Defeat Seravel without drinking any Tears."], "c": "challenge", "xp": 50, "i": "tear"},
	"full_wings": {"n": ["Alas Intactas", "Wings Intact"], "d": ["Derrota a Seravel con las 10 plumas.", "Defeat Seravel with all 10 feathers."], "c": "challenge", "xp": 50, "i": "wings"},
	"ascension": {"n": ["Ascensión III", "Ascension III"], "d": ["Supera a un Arconte en Ascensión III con Sor Velaria.", "Beat an Archon on Ascension III with Sister Velaria."], "c": "challenge", "xp": 50, "i": "crown"},
	"hardest": {"n": ["Serafín Caído", "Fallen Seraph"], "d": ["Derrota a los tres Arcontes en dificultad Serafín Caído.", "Defeat the three Archons on Fallen Seraph difficulty."], "c": "challenge", "xp": 100, "i": "skull", "g": 3, "s": "hard_archons"},
	"deathless": {"n": ["Inmaculado", "Immaculate"], "d": ["Derrota a Seravel sin haber muerto ni una vez en la partida.", "Defeat Seravel without dying once in that save."], "c": "challenge", "xp": 100, "i": "halo"},
	"speedrun": {"n": ["Contrarreloj", "Against the Clock"], "d": ["Derrota a Seravel en menos de 40 minutos de partida.", "Defeat Seravel in under 40 minutes of play."], "c": "challenge", "xp": 50, "i": "hourglass"},
	"ng": {"n": ["Segundo Descenso", "Second Descent"], "d": ["Empieza un Segundo Descenso (Nueva Partida+).", "Begin a Second Descent (New Game+)."], "c": "challenge", "xp": 25, "i": "moon"},
	# ---------------------------------------------------------------- batallas secretas (ocultas)
	"sb_verdugo": {"n": ["El Que Fui", "The One I Was"], "d": ["Derrota al Verdugo en el Cadalso, bajo la Capilla Olvidada.", "Defeat the Executioner in the Scaffold, beneath the Forgotten Chapel."], "c": "secret", "xp": 50, "i": "mask", "h": true},
	"sb_coloso": {"n": ["Lo que Sostenía la Espiral", "What Held the Spiral"], "d": ["Despierta y derrota al Coloso del Abismo.", "Wake and defeat the Colossus of the Abyss."], "c": "secret", "xp": 50, "i": "hand", "h": true},
	"sb_panteon": {"n": ["Panteón", "Pantheon"], "d": ["Supera el Panteón de los Arcontes de Sor Velaria.", "Clear Sister Velaria's Pantheon of the Archons."], "c": "secret", "xp": 100, "i": "crown", "h": true},
	"sb_legend": {"n": ["Leyenda de la Espiral", "Legend of the Spiral"], "d": ["Derrota a un jefe secreto sin recibir ni un golpe.", "Defeat a secret boss without taking a single hit."], "c": "secret", "xp": 100, "i": "star", "h": true},
	# ---------------------------------------------------------------- cooperativo
	"coop_join": {"n": ["Dos Alas", "Two Wings"], "d": ["Juega una partida cooperativa.", "Play a co-op game."], "c": "coop", "xp": 5, "i": "two"},
	"coop_revive": {"n": ["Hermanos de Ala", "Wing Siblings"], "d": ["Revive a tu compañero 10 veces atrapando su pluma.", "Revive your partner 10 times by catching their feather."], "c": "coop", "xp": 15, "i": "feather", "g": 10, "s": "revives"},
	"coop_cross": {"n": ["Alas Cruzadas", "Crossed Wings"], "d": ["Haz 25 Tajos en X con tu compañero.", "Perform 25 X-Slashes with your partner."], "c": "coop", "xp": 15, "i": "sword", "g": 25, "s": "cross"},
	"coop_boss": {"n": ["Juntos ante el Arconte", "Together Before the Archon"], "d": ["Derrota a un Arconte en cooperativo.", "Defeat an Archon in co-op."], "c": "coop", "xp": 15, "i": "two"},
	"coop_heal": {"n": ["Báculo Compartido", "Shared Staff"], "d": ["En cooperativo, recupera 300 de vida con las zonas de curación de tu compañero.", "In co-op, recover 300 health from your partner's healing zones."], "c": "coop", "xp": 15, "i": "heart", "g": 300, "s": "coop_heal"},
	"coop_ping": {"n": ["¡Por Aquí!", "Over Here!"], "d": ["Marca 20 sitios para tu compañero.", "Mark 20 spots for your partner."], "c": "coop", "xp": 5, "i": "eye", "g": 20, "s": "pings"},
	# ---------------------------------------------------------------- DLC I: Los Cielos Rotos (+10 %)
	"d1_enter": {"n": ["Hacia Arriba", "Upwards"], "d": ["Sube por la grieta hasta los Cielos Rotos.", "Climb through the rift to the Broken Heavens."], "c": "dlc", "xp": 10, "i": "wings", "p": "dlc1"},
	"d1_twins": {"n": ["Varek y Vael", "Varek and Vael"], "d": ["Derrota a los gemelos del cielo.", "Defeat the twins of the sky."], "c": "dlc", "xp": 25, "i": "two", "p": "dlc1"},
	"d1_lucen": {"n": ["El Primer Desplumado", "The First Featherless"], "d": ["Vence a Lucen en el duelo espejo.", "Beat Lucen in the mirror duel."], "c": "dlc", "xp": 25, "i": "mask", "p": "dlc1"},
	"d1_hand": {"n": ["La Mano del Arquitecto", "The Architect's Hand"], "d": ["Derrota a la Mano del Arquitecto.", "Defeat the Architect's Hand."], "c": "dlc", "xp": 25, "i": "hand", "p": "dlc1"},
	"d1_glide": {"n": ["Sin Tocar el Suelo", "Never Touch the Ground"], "d": ["Planea durante 60 segundos sin aterrizar.", "Glide for 60 seconds without landing."], "c": "dlc", "xp": 15, "i": "feather", "p": "dlc1"},
	"d1_lyre": {"n": ["La Lira de Pluma", "The Feather Lyre"], "d": ["Consigue la Lira de pluma.", "Obtain the Feather Lyre."], "c": "dlc", "xp": 10, "i": "bell", "p": "dlc1"},
	"d1_end": {"n": ["Las Puertas del Cielo", "The Gates of Heaven"], "d": ["Llega al final de los Cielos Rotos.", "Reach the ending of the Broken Heavens."], "c": "dlc", "xp": 50, "i": "door", "p": "dlc1"},
	# ---------------------------------------------------------------- DLC II: El Abismo Sin Nombre (+10 %)
	"d2_enter": {"n": ["Hacia Abajo", "Downwards"], "d": ["Desciende por la grieta al Abismo Sin Nombre.", "Descend through the rift into the Nameless Abyss."], "c": "dlc", "xp": 10, "i": "moon", "p": "dlc2"},
	"d2_mother": {"n": ["La Madre de las Sombras", "The Mother of Shadows"], "d": ["Derrota a tus Sombras acumuladas.", "Defeat your accumulated Shadows."], "c": "dlc", "xp": 25, "i": "ghost", "p": "dlc2"},
	"d2_king": {"n": ["El Rey Sin Nombre", "The Nameless King"], "d": ["Derrota al primer Serafín, borrado de la historia.", "Defeat the first Seraph, erased from history."], "c": "dlc", "xp": 50, "i": "crown", "p": "dlc2"},
	"d2_fish": {"n": ["Pescador de Almas", "Soul Angler"], "d": ["Pesca 30 almas.", "Catch 30 souls."], "c": "dlc", "xp": 15, "i": "tear", "p": "dlc2"},
	"d2_spiral": {"n": ["Espiral Infinita", "Infinite Spiral"], "d": ["Alcanza el piso 30 de la Espiral Infinita.", "Reach floor 30 of the Infinite Spiral."], "c": "dlc", "xp": 25, "i": "hourglass", "p": "dlc2"},
	"d2_end": {"n": ["El Fondo", "The Bottom"], "d": ["Llega al final del Abismo Sin Nombre.", "Reach the ending of the Nameless Abyss."], "c": "dlc", "xp": 25, "i": "door", "p": "dlc2"},
	"d2_final": {"n": ["El Último Serafín", "The Last Seraph"], "d": ["Consigue uno de los dos finales definitivos.", "Reach one of the two true endings."], "c": "dlc", "xp": 50, "i": "halo", "p": "dlc2"},
}

var data := {"un": {}, "st": {}, "goal": {}, "new": {}}
var _path := PATH
var _layer: CanvasLayer
var popup: AchPopup
var _last_tick := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 125
	add_child(_layer)
	popup = AchPopup.new()
	popup.size = Vector2(640, 360)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(popup)
	call_deferred("_late_load")

func _late_load() -> void:
	# las pruebas automáticas usan su propio archivo, vacío, para no tocar tus logros
	_path = PATH_TEST if G.autotest != "" else PATH
	if G.autotest != "":
		data = {"un": {}, "st": {}, "goal": {}, "new": {}}
		return
	if FileAccess.file_exists(_path):
		var f := FileAccess.open(_path, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			for k in ["un", "st", "goal", "new"]:
				if d.get(k) is Dictionary:
					data[k] = d[k]
	changed.emit()

func save() -> void:
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

# ------------------------------------------------------------------ consulta
func pack_of(id: String) -> String:
	return str(LIST[id].get("p", "base"))

func is_unlocked(id: String) -> bool:
	return data.un.has(id)

func goal(id: String) -> int:
	return int(data.goal.get(id, LIST[id].get("g", 0)))

func stat(s: String) -> float:
	return float(data.st.get(s, 0))

func progress(id: String) -> float:
	if is_unlocked(id):
		return 1.0
	var a: Dictionary = LIST[id]
	if not a.has("s"):
		return 0.0
	return clampf(stat(a.s) / float(max(1, goal(id))), 0.0, 1.0)

func progress_text(id: String) -> String:
	var a: Dictionary = LIST[id]
	if not a.has("s"):
		return ""
	return "%d/%d" % [mini(int(stat(a.s)), goal(id)), goal(id)]

func pack_xp(pack: String) -> int:
	var n := 0
	for k in LIST:
		if pack_of(k) == pack:
			n += int(LIST[k].xp)
	return n

func weight(id: String) -> float:
	## porcentaje del juego que vale este logro
	var p := pack_of(id)
	return float(LIST[id].xp) / float(pack_xp(p)) * float(PACKS[p].share)

func percent() -> float:
	var t := 0.0
	for k in data.un:
		if LIST.has(k) and owned.get(pack_of(k), false):
			t += weight(k)
	return snappedf(t, 0.01)

func max_percent() -> float:
	var m := 0.0
	for p in PACKS:
		if owned.get(p, false):
			m += float(PACKS[p].share)
	return m

func percent_text(v := -1.0) -> String:
	if v < 0.0:
		v = percent()
	return "%d%%" % int(floor(snappedf(v, 0.01)))

func xp_total() -> int:
	var n := 0
	for k in data.un:
		if LIST.has(k):
			n += int(LIST[k].xp)
	return n

func count(pack := "base") -> Array:
	var got := 0
	var tot := 0
	for k in LIST:
		if pack_of(k) != pack:
			continue
		tot += 1
		if is_unlocked(k):
			got += 1
	return [got, tot]

func tier(id: String) -> String:
	var xp: int = LIST[id].xp
	if xp >= 100:
		return "epic"
	if xp >= 50:
		return "gold"
	if xp >= 15:
		return "silver"
	return "bronze"

static func tier_col(t: String) -> Color:
	match t:
		"epic": return Color(0.82, 0.55, 1.0)
		"gold": return Color(1.0, 0.82, 0.3)
		"silver": return Color(0.8, 0.86, 0.95)
	return Color(0.9, 0.58, 0.34)

static func tier_name(t: String) -> Array:
	match t:
		"epic": return ["ÉPICO", "EPIC"]
		"gold": return ["ORO", "GOLD"]
		"silver": return ["PLATA", "SILVER"]
	return ["BRONCE", "BRONZE"]

# ------------------------------------------------------------------ registrar
func unlock(id: String) -> void:
	if not LIST.has(id) or is_unlocked(id) or not owned.get(pack_of(id), false):
		return
	var before := percent()
	data.un[id] = int(Time.get_unix_time_from_system())
	data.new[id] = true
	save()
	popup.push({"id": id, "kind": "unlock", "from": before, "to": percent()})
	unlocked.emit(id)
	changed.emit()

func add(s: String, n := 1.0) -> void:
	data.st[s] = stat(s) + n
	_check_stat(s)

func set_max(s: String, v: float) -> void:
	if v <= stat(s):
		return
	data.st[s] = v
	_check_stat(s)

func import_legacy(ids: Array) -> void:
	var any := false
	for id in ids:
		if LIST.has(id) and not is_unlocked(id):
			data.un[id] = int(Time.get_unix_time_from_system())
			any = true
	if any:
		save()
		changed.emit()

func set_goal(id: String, g: int) -> void:
	## algunas metas dependen del mapa (salas, cofres...): el mundo las ajusta al cargar
	if LIST.has(id) and g > 0 and int(data.goal.get(id, -1)) != g:
		data.goal[id] = g

func _check_stat(s: String) -> void:
	var dirty := false
	for k in LIST:
		var a: Dictionary = LIST[k]
		if a.get("s", "") != s or is_unlocked(k):
			continue
		if stat(s) >= goal(k):
			unlock(k)
		else:
			dirty = true
			# aviso pequeño de progreso a la mitad del camino (solo en metas largas)
			var g := goal(k)
			var half := int(g / 2)
			if g >= 6 and int(stat(s)) == half and not _last_tick.has(k + str(half)):
				_last_tick[k + str(half)] = true
				popup.push({"id": k, "kind": "progress"})
	if dirty:
		_save_soon()
	changed.emit()

var _save_t := -1.0
func _save_soon() -> void:
	if _save_t < 0.0:
		_save_t = 2.0

func _process(delta: float) -> void:
	if _save_t >= 0.0:
		_save_t -= delta
		if _save_t < 0.0:
			save()

func clear_new() -> void:
	if not data.new.is_empty():
		data.new = {}
		save()

func reset_all() -> void:
	data = {"un": {}, "st": {}, "goal": data.goal, "new": {}}
	save()
	changed.emit()

# ------------------------------------------------------------------ iconos (dibujados a mano, sin texturas)
static func draw_glyph(ci: CanvasItem, c: Vector2, s: float, icon: String, col: Color) -> void:
	## s: medio tamaño del glifo (≈ radio)
	var k := s / 8.0
	var P := func(pts: Array) -> PackedVector2Array:
		var o := PackedVector2Array()
		for p in pts:
			o.append(c + Vector2(p[0], p[1]) * k)
		return o
	match icon:
		"feather":
			ci.draw_colored_polygon(P.call([[5, -7], [2, -3], [-1, 1], [-4, 5], [-5, 7], [-2, 5], [2, 2], [5, -2], [6, -6]]), col)
			ci.draw_line(c + Vector2(-6, 8) * k, c + Vector2(4, -5) * k, Color(0, 0, 0, 0.5), maxf(1.0, k))
		"flame":
			ci.draw_colored_polygon(P.call([[0, -8], [3, -3], [5, 1], [4, 5], [0, 7], [-4, 5], [-5, 1], [-2, -2], [-1, -5]]), col)
			ci.draw_colored_polygon(P.call([[0, -2], [2, 2], [1, 5], [-1, 5], [-2, 2]]), Color(1, 1, 1, 0.75))
		"sword":
			ci.draw_colored_polygon(P.call([[6, -7], [7, -6], [-2, 3], [-3, 2]]), col)
			ci.draw_line(c + Vector2(-5, 0) * k, c + Vector2(0, 5) * k, col, maxf(1.0, 2.0 * k))
			ci.draw_line(c + Vector2(-3, 3) * k, c + Vector2(-6, 6) * k, col, maxf(1.0, 2.0 * k))
		"skull":
			ci.draw_circle(c + Vector2(0, -1) * k, 6.0 * k, col)
			ci.draw_rect(Rect2(c + Vector2(-3.5, 3) * k, Vector2(7, 4) * k), col)
			ci.draw_circle(c + Vector2(-2.5, -1) * k, 1.8 * k, Color(0, 0, 0, 0.8))
			ci.draw_circle(c + Vector2(2.5, -1) * k, 1.8 * k, Color(0, 0, 0, 0.8))
		"crown":
			ci.draw_colored_polygon(P.call([[-7, 5], [-7, -4], [-3.5, 0], [0, -6], [3.5, 0], [7, -4], [7, 5]]), col)
			ci.draw_rect(Rect2(c + Vector2(-7, 5) * k, Vector2(14, 2) * k), col.darkened(0.25))
		"bell":
			ci.draw_colored_polygon(P.call([[0, -7], [3, -5], [4, 0], [6, 4], [-6, 4], [-4, 0], [-3, -5]]), col)
			ci.draw_circle(c + Vector2(0, 6) * k, 1.6 * k, col)
		"eye":
			ci.draw_colored_polygon(P.call([[-7, 0], [-3, -4], [3, -4], [7, 0], [3, 4], [-3, 4]]), col)
			ci.draw_circle(c, 2.6 * k, Color(0, 0, 0, 0.8))
			ci.draw_circle(c + Vector2(-0.8, -0.8) * k, 0.9 * k, Color(1, 1, 1, 0.9))
		"key":
			ci.draw_arc(c + Vector2(-3, -3) * k, 3.0 * k, 0, TAU, 12, col, maxf(1.0, 2.0 * k))
			ci.draw_line(c + Vector2(-1, -1) * k, c + Vector2(6, 6) * k, col, maxf(1.0, 2.0 * k))
			ci.draw_line(c + Vector2(4, 4) * k, c + Vector2(2, 6) * k, col, maxf(1.0, 2.0 * k))
		"chain":
			for i in 3:
				ci.draw_arc(c + Vector2(-4 + i * 4, -4 + i * 4) * k, 2.6 * k, 0, TAU, 10, col, maxf(1.0, 1.5 * k))
		"wings":
			for sd in [-1.0, 1.0]:
				ci.draw_colored_polygon(P.call([[0.8 * sd, 2], [7 * sd, -6], [7.5 * sd, -1], [6 * sd, 3], [3 * sd, 6]]), col)
			ci.draw_circle(c + Vector2(0, -3) * k, 1.8 * k, col)
		"heart":
			ci.draw_circle(c + Vector2(-2.5, -2) * k, 3.3 * k, col)
			ci.draw_circle(c + Vector2(2.5, -2) * k, 3.3 * k, col)
			ci.draw_colored_polygon(P.call([[-5.6, -0.8], [5.6, -0.8], [0, 6.5]]), col)
		"book":
			ci.draw_colored_polygon(P.call([[-7, -5], [-1, -4], [0, 6], [-7, 5]]), col)
			ci.draw_colored_polygon(P.call([[7, -5], [1, -4], [0, 6], [7, 5]]), col.darkened(0.15))
		"map":
			ci.draw_colored_polygon(P.call([[-7, -5], [-2, -7], [2, -5], [7, -7], [7, 5], [2, 7], [-2, 5], [-7, 7]]), col)
			ci.draw_line(c + Vector2(-2, -7) * k, c + Vector2(-2, 5) * k, Color(0, 0, 0, 0.45), maxf(1.0, k))
			ci.draw_line(c + Vector2(2, -5) * k, c + Vector2(2, 7) * k, Color(0, 0, 0, 0.45), maxf(1.0, k))
		"chest":
			ci.draw_rect(Rect2(c + Vector2(-7, -2) * k, Vector2(14, 8) * k), col)
			ci.draw_colored_polygon(P.call([[-7, -2], [-6, -6], [6, -6], [7, -2]]), col.lightened(0.15))
			ci.draw_rect(Rect2(c + Vector2(-1, -2) * k, Vector2(2, 3) * k), Color(0, 0, 0, 0.6))
		"urn":
			ci.draw_colored_polygon(P.call([[-3, -7], [3, -7], [2, -5], [5, -1], [4, 5], [2, 7], [-2, 7], [-4, 5], [-5, -1], [-2, -5]]), col)
		"star":
			var pts := []
			for i in 10:
				var r := 7.5 if i % 2 == 0 else 3.0
				var a := -PI / 2 + i * PI / 5
				pts.append([cos(a) * r, sin(a) * r])
			ci.draw_colored_polygon(P.call(pts), col)
		"hand":
			ci.draw_rect(Rect2(c + Vector2(-4, -1) * k, Vector2(8, 7) * k), col)
			for i in 4:
				ci.draw_rect(Rect2(c + Vector2(-4 + i * 2.1, -7 + absf(i - 1.5) * 1.2) * k, Vector2(1.6, 6) * k), col)
			ci.draw_rect(Rect2(c + Vector2(-7, 0) * k, Vector2(3, 2) * k), col)
		"halo":
			ci.draw_arc(c + Vector2(0, -2) * k, 6.0 * k, 0, TAU, 20, col, maxf(1.5, 2.2 * k))
			ci.draw_circle(c + Vector2(0, 5) * k, 2.0 * k, col)
		"hourglass":
			ci.draw_colored_polygon(P.call([[-5, -7], [5, -7], [0, 0]]), col)
			ci.draw_colored_polygon(P.call([[-5, 7], [5, 7], [0, 0]]), col)
			ci.draw_rect(Rect2(c + Vector2(-6, -8) * k, Vector2(12, 1.5) * k), col.lightened(0.2))
			ci.draw_rect(Rect2(c + Vector2(-6, 6.5) * k, Vector2(12, 1.5) * k), col.lightened(0.2))
		"bolt":
			ci.draw_colored_polygon(P.call([[2, -8], [-4, 1], [0, 1], [-2, 8], [4, -1], [0, -1]]), col)
		"mask":
			ci.draw_colored_polygon(P.call([[-6, -5], [6, -5], [6, 1], [3, 6], [-3, 6], [-6, 1]]), col)
			ci.draw_rect(Rect2(c + Vector2(-4, -2) * k, Vector2(3, 1.5) * k), Color(0, 0, 0, 0.8))
			ci.draw_rect(Rect2(c + Vector2(1, -2) * k, Vector2(3, 1.5) * k), Color(0, 0, 0, 0.8))
		"scale":
			ci.draw_line(c + Vector2(0, -7) * k, c + Vector2(0, 6) * k, col, maxf(1.0, 1.5 * k))
			ci.draw_line(c + Vector2(-6, -4) * k, c + Vector2(6, -4) * k, col, maxf(1.0, 1.5 * k))
			ci.draw_colored_polygon(P.call([[-8, 1], [-4, 1], [-6, -4]]), col)
			ci.draw_colored_polygon(P.call([[8, 1], [4, 1], [6, -4]]), col)
			ci.draw_rect(Rect2(c + Vector2(-3, 6) * k, Vector2(6, 1.5) * k), col)
		"tear":
			ci.draw_colored_polygon(P.call([[0, -8], [3, -2], [4, 2], [2, 6], [-2, 6], [-4, 2], [-3, -2]]), col)
			ci.draw_circle(c + Vector2(-1.4, 2) * k, 1.0 * k, Color(1, 1, 1, 0.8))
		"door":
			ci.draw_colored_polygon(P.call([[-5, 7], [-5, -3], [-3, -6], [0, -7], [3, -6], [5, -3], [5, 7]]), col)
			ci.draw_colored_polygon(P.call([[-3, 7], [-3, -2], [0, -4.5], [3, -2], [3, 7]]), Color(0, 0, 0, 0.75))
		"shield":
			ci.draw_colored_polygon(P.call([[-6, -6], [6, -6], [6, 0], [0, 7], [-6, 0]]), col)
			ci.draw_line(c + Vector2(0, -5) * k, c + Vector2(0, 5) * k, Color(0, 0, 0, 0.4), maxf(1.0, k))
		"scythe":
			ci.draw_line(c + Vector2(-5, 7) * k, c + Vector2(3, -6) * k, col, maxf(1.0, 1.6 * k))
			ci.draw_colored_polygon(P.call([[3, -6], [-5, -7], [-7, -4], [-3, -5], [2, -4]]), col)
		"hammer":
			ci.draw_line(c + Vector2(-5, 7) * k, c + Vector2(2, -2) * k, col, maxf(1.0, 1.8 * k))
			ci.draw_colored_polygon(P.call([[-1, -5], [4, -8], [8, -3], [3, 0]]), col)
		"moon":
			ci.draw_circle(c, 6.5 * k, col)
			ci.draw_circle(c + Vector2(3, -2) * k, 5.5 * k, Color(0, 0, 0, 0.85))
		"ghost":
			ci.draw_circle(c + Vector2(0, -2) * k, 5.0 * k, col)
			ci.draw_colored_polygon(P.call([[-5, -2], [5, -2], [5, 6], [3, 4], [1, 7], [-1, 4], [-3, 7], [-5, 5]]), col)
			ci.draw_circle(c + Vector2(-2, -2) * k, 1.2 * k, Color(0, 0, 0, 0.8))
			ci.draw_circle(c + Vector2(2, -2) * k, 1.2 * k, Color(0, 0, 0, 0.8))
		"two":
			for sd in [-1.0, 1.0]:
				ci.draw_colored_polygon(P.call([[sd * 1, 4], [sd * 8, -5], [sd * 8, 0], [sd * 5, 5]]), col)
			ci.draw_circle(c + Vector2(-2.5, -1) * k, 2.2 * k, col)
			ci.draw_circle(c + Vector2(2.5, -1) * k, 2.2 * k, col)
		"lock":
			ci.draw_arc(c + Vector2(0, -2) * k, 3.5 * k, PI, TAU, 10, col, maxf(1.0, 1.8 * k))
			ci.draw_rect(Rect2(c + Vector2(-5, -2) * k, Vector2(10, 8) * k), col)
			ci.draw_rect(Rect2(c + Vector2(-0.8, 0.5) * k, Vector2(1.6, 3) * k), Color(0, 0, 0, 0.7))
		"?":
			var f := UIKit.font("head")
			var fs := int(maxf(8.0, round(s * 1.5 / 8.0) * 8.0))
			var w := f.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			f.draw_string(ci.get_canvas_item(), c + Vector2(-w / 2.0, fs * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		_:
			draw_glyph(ci, c, s, "star", col)

static func draw_medal(ci: CanvasItem, c: Vector2, r: float, id: String, got: bool, t := 0.0, locked_dlc := false) -> void:
	## medallón: anillo del rango, disco oscuro y glifo. Bloqueado: gris con candado o "?" si es oculto.
	var a: Dictionary = LIST[id]
	var tc := tier_col(Ach.tier(id)) if got else Color(0.36, 0.32, 0.4)
	var cc: Color = CATS[a.c].col if got else Color(0.5, 0.46, 0.55)
	ci.draw_circle(c + Vector2(1, 2), r + 1.0, Color(0, 0, 0, 0.45))
	ci.draw_circle(c, r + 1.0, UIKit.INK)
	ci.draw_circle(c, r, tc.darkened(0.35))
	# biseles del anillo
	ci.draw_arc(c, r - 0.5, PI * 1.05, PI * 1.95, 16, tc.lightened(0.35), 1.0)
	ci.draw_arc(c, r - 0.5, PI * 0.05, PI * 0.95, 16, tc.darkened(0.55), 1.0)
	var inner := r * 0.74
	ci.draw_circle(c, inner + 1.0, UIKit.INK)
	ci.draw_circle(c, inner, Color(0.13, 0.06, 0.17) if got else Color(0.11, 0.09, 0.13))
	if got:
		ci.draw_circle(c + Vector2(0, -inner * 0.25), inner * 0.7, Color(cc, 0.12))
		# muescas del anillo, como una moneda
		for i in 12:
			var ang := i * TAU / 12.0 + t * 0.3
			ci.draw_circle(c + Vector2(cos(ang), sin(ang)) * (r - (r - inner) * 0.5), maxf(0.6, r * 0.05), tc.lightened(0.25))
	var icon: String = a.i
	if not got:
		icon = "lock" if locked_dlc else ("?" if a.get("h", false) else str(a.i))
	draw_glyph(ci, c, inner * 0.78, icon, cc if got else Color(0.42, 0.38, 0.47))
	if got:
		# brillo en diagonal
		ci.draw_line(c + Vector2(-inner * 0.55, -inner * 0.2), c + Vector2(-inner * 0.2, -inner * 0.55), Color(1, 1, 1, 0.35), 1.0)

# ====================================================================== aviso emergente
class AchPopup extends Control:
	var queue: Array = []
	var cur := {}
	var t := 0.0
	var parts: Array = []
	var _dur := 4.2

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func push(e: Dictionary) -> void:
		# un desbloqueo reemplaza al aviso de progreso pendiente del mismo logro
		if e.kind == "unlock":
			for q in queue.duplicate():
				if q.id == e.id and q.kind == "progress":
					queue.erase(q)
		queue.append(e)

	func _epic() -> bool:
		return not cur.is_empty() and cur.kind == "unlock" and (int(Ach.LIST[cur.id].xp) >= 100 or Ach.LIST[cur.id].c == "secret")

	func _start(e: Dictionary) -> void:
		cur = e
		t = 0.0
		parts.clear()
		if e.kind == "progress":
			_dur = 2.6
			Audio.sfx("achieve_tick", -6.0, 0.0)
			return
		_dur = 5.4 if _epic() else 4.3
		Audio.sfx("achieve_epic" if _epic() else "achieve", -2.0, 0.0)
		if _epic():
			G.flash(Color(1, 0.9, 0.6, 0.18), 0.5)

	func _process(delta: float) -> void:
		if cur.is_empty():
			if queue.is_empty():
				if visible:
					queue_redraw()
				return
			_start(queue.pop_front())
		t += delta
		var bw := _banner_rect()
		# partículas: chispas y plumas que caen del aviso
		if cur.kind == "unlock" and t > 0.3 and t < _dur - 0.6:
			var rate := 26.0 if _epic() else 12.0
			if randf() < rate * delta:
				var col: Color = Ach.tier_col(Ach.tier(cur.id))
				parts.append({"p": Vector2(randf_range(bw.position.x + 8, bw.end.x - 8), bw.end.y - 2), "v": Vector2(randf_range(-14, 14), randf_range(10, 40)),
					"l": 0.0, "m": randf_range(0.9, 1.8), "k": "f" if randf() < 0.35 else "s", "c": col.lightened(randf_range(0.0, 0.5)), "r": randf() * TAU})
		for p in parts.duplicate():
			p.l += delta
			p.p += p.v * delta
			p.v.y += 22.0 * delta
			p.v.x += sin(p.l * 5.0 + p.r) * 12.0 * delta
			p.r += delta * 2.0
			if p.l > p.m:
				parts.erase(p)
		if t >= _dur:
			cur = {}
		queue_redraw()

	func _slide() -> float:
		## 0 fuera de pantalla, 1 en su sitio (entrada con rebote, salida rápida)
		var tin := clampf(t / 0.5, 0.0, 1.0)
		var e := 1.0 + 2.70158 * pow(tin - 1.0, 3) + 1.70158 * pow(tin - 1.0, 2)
		var tout := clampf((_dur - t) / 0.35, 0.0, 1.0)
		return e * (1.0 - pow(1.0 - tout, 2))

	func _banner_rect() -> Rect2:
		var big := _epic()
		var w := 300.0 if big else 256.0
		var h := 54.0 if big else 46.0
		if not cur.is_empty() and cur.kind == "progress":
			w = 200.0
			h = 28.0
		var y := lerpf(-h - 20.0, 12.0 if not big else 16.0, _slide())
		return Rect2(Vector2(320.0 - w / 2.0, y), Vector2(w, h))

	func _draw() -> void:
		if cur.is_empty():
			return
		var r := _banner_rect()
		if cur.kind == "progress":
			_draw_progress(r)
			return
		var id: String = cur.id
		var a: Dictionary = Ach.LIST[id]
		var tr := Ach.tier(id)
		var tc: Color = Ach.tier_col(tr)
		var big := _epic()
		var fh := UIKit.font("head")
		var ft := UIKit.font("title")
		# halo del épico: anillo que se expande detrás
		if big and t > 0.35 and t < 1.6:
			var k := (t - 0.35) / 1.25
			draw_arc(r.position + Vector2(30, r.size.y / 2.0), 20.0 + k * 140.0, 0, TAU, 48, Color(tc, (1.0 - k) * 0.6), 3.0 * (1.0 - k) + 1.0)
		# cinta superior "LOGRO ÉPICO"
		if big:
			var rib := G.L(["LOGRO ÉPICO", "EPIC ACHIEVEMENT"])
			var rw := fh.get_string_size(rib, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 28
			var rr := Rect2(Vector2(320.0 - rw / 2.0, r.end.y - 2), Vector2(rw, 13))
			draw_rect(rr.grow(1), UIKit.INK)
			draw_rect(rr, tc.darkened(0.2))
			draw_rect(Rect2(rr.position, Vector2(rr.size.x, 2)), tc.lightened(0.4))
			fh.draw_string(get_canvas_item(), rr.position + Vector2(14, 10), rib, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.INK)
			UIKit.diamond(self, rr.position + Vector2(7, 6.5), 3.0, UIKit.INK)
			UIKit.diamond(self, Vector2(rr.end.x - 7, rr.position.y + 6.5), 3.0, UIKit.INK)
		# sombra y cuerpo con esquinas cortadas
		var cut := 6.0
		var body := PackedVector2Array([r.position + Vector2(cut, 0), Vector2(r.end.x - cut, r.position.y), Vector2(r.end.x, r.position.y + cut),
			Vector2(r.end.x, r.end.y - cut), Vector2(r.end.x - cut, r.end.y), Vector2(r.position.x + cut, r.end.y), Vector2(r.position.x, r.end.y - cut), r.position + Vector2(0, cut)])
		var sh := PackedVector2Array()
		for p in body:
			sh.append(p + Vector2(3, 4))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.5))
		var outer := PackedVector2Array()
		for p in body:
			outer.append(p + (p - r.get_center()).sign() * 2.0)
		draw_colored_polygon(outer, UIKit.INK)
		var edge := PackedVector2Array()
		for p in body:
			edge.append(p + (p - r.get_center()).sign() * 1.0)
		draw_colored_polygon(edge, tc)
		draw_colored_polygon(body, Color(0.1, 0.04, 0.14, 0.97))
		# degradado y franja de color de la categoría
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.45)), Color(1, 1, 1, 0.04))
		draw_rect(Rect2(Vector2(r.position.x + 2, r.end.y - 4), Vector2(r.size.x - 4, 2)), Color(0, 0, 0, 0.4))
		# barra de compleción que se llena (de lo que tenías a lo que tienes)
		var maxp := Ach.max_percent()
		var k2 := clampf((t - 0.9) / 1.0, 0.0, 1.0)
		k2 = 1.0 - pow(1.0 - k2, 3)
		var pct: float = lerpf(float(cur.get("from", 0.0)), float(cur.get("to", 0.0)), k2)
		var bar := Rect2(Vector2(r.position.x + 6, r.end.y - 4), Vector2(r.size.x - 12, 2))
		draw_rect(bar, Color(0.25, 0.15, 0.3))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(pct / maxp, 0.0, 1.0), 2)), tc)
		# brillo que barre el aviso
		var sx := lerpf(r.position.x - 40.0, r.end.x + 40.0, clampf((t - 0.45) / 0.6, 0.0, 1.0))
		if t > 0.45 and t < 1.05:
			var band := PackedVector2Array([Vector2(sx, r.position.y + 2), Vector2(sx + 14, r.position.y + 2), Vector2(sx + 2, r.end.y - 2), Vector2(sx - 12, r.end.y - 2)])
			var cl := PackedVector2Array()
			for p in band:
				cl.append(Vector2(clampf(p.x, r.position.x + 2, r.end.x - 2), p.y))
			draw_colored_polygon(cl, Color(1, 1, 1, 0.22))
		# medallón con rayos que giran detrás
		var mc := r.position + Vector2(r.size.y / 2.0 + 4.0, r.size.y / 2.0 - 1.0)
		var mr := (r.size.y / 2.0 - 7.0)
		var pop := clampf((t - 0.2) / 0.35, 0.0, 1.0)
		var sc := 1.0 + sin(pop * PI) * 0.35 if pop < 1.0 else 1.0
		sc *= pop
		if sc > 0.01:
			var rays := 12 if big else 8
			for i in rays:
				var ang := t * (0.9 if big else 0.6) + i * TAU / rays
				var l := mr * (2.1 if big else 1.75) * sc
				var w2 := 0.16
				draw_colored_polygon(PackedVector2Array([mc, mc + Vector2(cos(ang - w2), sin(ang - w2)) * l, mc + Vector2(cos(ang + w2), sin(ang + w2)) * l]), Color(tc, 0.14 if not big else 0.22))
			draw_set_transform(mc, sin(t * 2.0) * 0.06 * (1.0 if pop >= 1.0 else 0.0), Vector2(sc, sc))
			Ach.draw_medal(self, Vector2.ZERO, mr, id, true, t)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# destellos alrededor
			for i in 4:
				var ph := t * 3.0 + i * 1.7
				var tw := maxf(0.0, sin(ph))
				if tw > 0.2:
					var sp := mc + Vector2(cos(i * 1.9 + 0.4), sin(i * 1.9 + 0.4)) * (mr + 6.0)
					_sparkle(sp, 3.0 * tw, Color(1, 1, 0.9, tw))
		# textos
		var tx := r.position.x + r.size.y + 8.0
		var head := G.L(["LOGRO DESBLOQUEADO", "ACHIEVEMENT UNLOCKED"])
		var ta := clampf((t - 0.3) / 0.3, 0.0, 1.0)
		fh.draw_string_outline(get_canvas_item(), Vector2(tx, r.position.y + 13), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(UIKit.INK, ta))
		fh.draw_string(get_canvas_item(), Vector2(tx, r.position.y + 13), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(tc, ta))
		var nm := G.L(a.n)
		var nfs := 20 if big else 16
		var maxw := r.end.x - tx - 8.0
		while nfs > 10 and ft.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > maxw:
			nfs -= 2
		# el nombre aparece letra a letra
		var nchars := int(clampf((t - 0.45) / 0.5, 0.0, 1.0) * nm.length())
		var shown := nm.substr(0, nchars)
		var ny := r.position.y + (31 if not big else 35)
		ft.draw_string_outline(get_canvas_item(), Vector2(tx, ny), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, 4, UIKit.INK)
		ft.draw_string(get_canvas_item(), Vector2(tx, ny), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, UIKit.WHITE)
		# categoría · rango · XP que va subiendo · % del juego
		var xp_k := clampf((t - 0.8) / 0.7, 0.0, 1.0)
		var xp := int(round(float(a.xp) * xp_k))
		var cat_t := G.L(Ach.CATS[a.c].n).to_upper()
		var line := "%s  ·  %s  ·  +%d XP" % [cat_t, G.L(Ach.tier_name(tr)), xp]
		var ly := r.end.y - (8 if not big else 9)
		fh.draw_string_outline(get_canvas_item(), Vector2(tx, ly), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(UIKit.INK, ta))
		fh.draw_string(get_canvas_item(), Vector2(tx, ly), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(Ach.CATS[a.c].col, ta))
		var pt := Ach.percent_text(pct)
		var pw := fh.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		fh.draw_string_outline(get_canvas_item(), Vector2(r.end.x - pw - 8, r.position.y + 13), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(UIKit.INK, ta))
		fh.draw_string(get_canvas_item(), Vector2(r.end.x - pw - 8, r.position.y + 13), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(UIKit.WHITE, ta * 0.85))
		# partículas
		for p in parts:
			var al = 1.0 - p.l / p.m
			if p.k == "f":
				draw_set_transform(p.p, p.r, Vector2.ONE)
				draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(1.2, 0), Vector2(0, 3), Vector2(-1.2, 0)]), Color(p.c, al))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_rect(Rect2(p.p, Vector2(1, 1)), Color(p.c, al))

	func _sparkle(p: Vector2, s: float, c: Color) -> void:
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), c, 1.0)
		draw_line(p - Vector2(0, s), p + Vector2(0, s), c, 1.0)
		draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, c.a))

	func _draw_progress(r: Rect2) -> void:
		var id: String = cur.id
		var a: Dictionary = Ach.LIST[id]
		var fh := UIKit.font("head")
		var ft := UIKit.font("title")
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.45))
		draw_rect(r.grow(1), UIKit.INK)
		draw_rect(r, Color(0.1, 0.04, 0.14, 0.95))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(0.45, 0.32, 0.55))
		var c := r.position + Vector2(14, 14)
		var pr := Ach.progress(id)
		draw_circle(c, 10.0, UIKit.INK)
		draw_arc(c, 9.0, -PI / 2, -PI / 2 + TAU * pr, 24, Ach.tier_col(Ach.tier(id)), 2.0)
		Ach.draw_glyph(self, c, 5.0, a.i, Ach.CATS[a.c].col)
		var nm := G.L(a.n)
		ft.draw_string_outline(get_canvas_item(), Vector2(r.position.x + 30, r.position.y + 13), nm, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 70, 12, 3, UIKit.INK)
		ft.draw_string(get_canvas_item(), Vector2(r.position.x + 30, r.position.y + 13), nm, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 70, 12, UIKit.WHITE)
		var pt := Ach.progress_text(id)
		var pw := fh.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		fh.draw_string(get_canvas_item(), Vector2(r.end.x - pw - 6, r.position.y + 12), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UIKit.GOLD)
		var bar := Rect2(Vector2(r.position.x + 30, r.end.y - 8), Vector2(r.size.x - 36, 3))
		draw_rect(bar, Color(0.25, 0.15, 0.3))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * pr, 3)), Ach.CATS[a.c].col)

extends Node
## Progreso del jugador local: nivel, atributos, Ecos, árbol de habilidades, armas, misiones, guardado.

signal changed
signal quest_updated(id: String)

const SAVE_PATH := "user://seraphall_save.json"

# ------------------------------------------------------------------ datos de armas
const WEAPONS := {
	"sword": {"name": ["Espada del Desplumado", "Featherless Sword"], "sprite": "sword", "dmg": 14.0, "speed": 1.0, "range": 30.0,
		"arc": 120.0, "combo": 3, "stam": 12.0, "poise": 10.0, "fue": 0.5, "des": 0.5, "fe": 0.0,
		"desc": ["Equilibrada y fiable. La primera hoja que recuerdas.", "Balanced and reliable. The first blade you remember."]},
	"spear": {"name": ["Lanza de Ceniza", "Ash Spear"], "sprite": "spear", "dmg": 12.0, "speed": 1.1, "range": 44.0,
		"arc": 46.0, "combo": 3, "stam": 11.0, "poise": 8.0, "fue": 0.2, "des": 0.8, "fe": 0.0,
		"desc": ["Estocadas largas y precisas. Mantén la distancia.", "Long, precise thrusts. Keep your distance."]},
	"scythe": {"name": ["Guadañas Gemelas", "Twin Scythes"], "sprite": "scythe", "dmg": 9.0, "speed": 1.45, "range": 30.0,
		"arc": 170.0, "combo": 4, "stam": 9.0, "poise": 6.0, "fue": 0.1, "des": 0.8, "fe": 0.0, "bleed": true,
		"desc": ["Torbellino de cortes. Provoca sangrado de luz.", "A whirlwind of cuts. Causes light-bleed."]},
	"hammer": {"name": ["Martillo del Juramento", "Oathbound Hammer"], "sprite": "hammer", "dmg": 27.0, "speed": 0.68, "range": 32.0,
		"arc": 140.0, "combo": 2, "stam": 20.0, "poise": 26.0, "fue": 1.0, "des": 0.0, "fe": 0.0,
		"desc": ["Lento y devastador. Rompe la postura de cualquiera.", "Slow and devastating. Breaks anyone's posture."]},
	"choir": {"name": ["Diapasón del Coro", "Choir Tuning-Blade"], "sprite": "choir", "dmg": 17.0, "speed": 1.2, "range": 34.0,
		"arc": 120.0, "combo": 3, "stam": 11.0, "poise": 9.0, "fue": 0.15, "des": 0.5, "fe": 0.6, "notes": true,
		"desc": ["Arma del Coro Hueco. El golpe final lanza notas que atraviesan a los enemigos.", "Weapon of the Hollow Choir. The final blow releases notes that pierce enemies."]},
	"seravel": {"name": ["Hoja de Seravel", "Seravel's Blade"], "sprite": "seravel", "dmg": 20.0, "speed": 1.1, "range": 36.0,
		"arc": 130.0, "combo": 3, "stam": 12.0, "poise": 12.0, "fue": 0.35, "des": 0.35, "fe": 0.5, "wave": true,
		"desc": ["Arma de Arconte. El tercer corte libera una onda de luz.", "Archon weapon. The third slash releases a wave of light."]},
}

# ------------------------------------------------------------------ objetos
## type: consumable | amulet | key | material ; rarity 0-4
const ITEMS := {
	"bomb": {"type": "consumable", "icon": "bomb", "rarity": 1, "price": 120, "name": ["Nudo de Brasa", "Ember Knot"],
		"desc": ["Plumas negras anudadas alrededor de un rescoldo vivo. Lánzalo con [X]: estalla en llamas.", "Black feathers knotted around a living ember. Throw with [X]: it bursts into flame."]},
	"incense": {"type": "consumable", "icon": "incense", "rarity": 1, "price": 200, "name": ["Himno Embotellado", "Bottled Hymn"],
		"desc": ["Un coro diminuto atrapado en cristal. Al romperlo, +30% de daño durante 30 s.", "A tiny choir trapped in glass. Break it for +30% damage for 30 s."]},
	"ointment": {"type": "consumable", "icon": "ointment", "rarity": 1, "price": 200, "name": ["Escama de Querubín", "Cherub Scale"],
		"desc": ["Escama que mudan los querubines al crecer. Endurece la piel: -35% de daño durante 30 s.", "A scale cherubs shed as they grow. Hardens the skin: -35% damage for 30 s."]},
	"vial_luz": {"type": "consumable", "icon": "vial_luz", "rarity": 1, "price": 180, "name": ["Vial de Luz", "Vial of Light"],
		"desc": ["Luz de vela atrapada en cristal. Te devuelve 30 de Luz al momento.", "Candlelight trapped in glass. Restores 30 Light instantly."]},
	"vial_aliento": {"type": "consumable", "icon": "vial_aliento", "rarity": 1, "price": 160, "name": ["Vial de Aliento", "Vial of Breath"],
		"desc": ["Aire de las alturas, embotellado. Llena el aguante y lo recupera el doble de rápido durante 20 s.", "Bottled air from the heights. Fills your stamina and doubles its recovery for 20 s."]},
	"phoenix": {"type": "consumable", "icon": "phoenix", "rarity": 3, "name": ["Plumón de Aurora", "Aurora Down"],
		"desc": ["El primer plumón de un ángel recién nacido. Si caes, renaces al instante. Se consume solo.", "The first down of a newborn angel. If you fall, you are reborn at once. Used automatically."]},
	"amulet_wing": {"type": "amulet", "icon": "amulet_wing", "rarity": 2, "name": ["Vértebra de Serafín", "Seraph Vertebra"],
		"desc": ["Hueso del ala de un serafín. Tu aguante se recupera un 30% más rápido.", "A bone from a seraph's wing. Your stamina recovers 30% faster."]},
	"amulet_eye": {"type": "amulet", "icon": "amulet_eye", "rarity": 3, "name": ["Ojo de la Guardiana", "Warden's Eye"],
		"desc": ["Nunca se cierra. +10% de probabilidad de crítico.", "It never closes. +10% critical chance."]},
	"amulet_ash": {"type": "amulet", "icon": "amulet_ash", "rarity": 2, "name": ["Corazón de Rescoldo", "Ember Heart"],
		"desc": ["Aún late bajo la ceniza. Tus golpes pueden quemar (+35% de daño).", "It still beats beneath the ash. Your hits may burn (+35% damage)."]},
	"choir_heart": {"type": "amulet", "icon": "choir_heart", "rarity": 3, "name": ["Garganta de Cristal", "Crystal Throat"],
		"desc": ["Canta cuando nadie la escucha. Tus hechizos cuestan un 25% menos de Luz.", "It sings when no one listens. Your spells cost 25% less Light."]},
	"amulet_bell": {"type": "amulet", "icon": "amulet_bell", "rarity": 3, "name": ["Campanilla de la Vigilia", "Vigil Bell"],
		"desc": ["Suena sola cuando te curas: los enemigos cercanos se frenan y retroceden.", "It rings by itself when you heal: nearby enemies slow down and stagger back."]},
	"key_vestibule": {"type": "key", "icon": "key", "rarity": 2, "name": ["Llave de Hueso Cantor", "Singing Bone Key"],
		"desc": ["Tallada en el hueso de un ángel que cantaba. Abre la puerta del Círculo de la Guardiana.", "Carved from the bone of a singing angel. Opens the gate to the Circle of the Warden."]},
	"map_carto": {"type": "key", "icon": "scroll", "rarity": 1, "name": ["Cartografía Táctil", "Tactile Chart"],
		"desc": ["Un mapa en relieve hecho para dedos ciegos. Huele a vela y a polvo.", "A raised map made for blind fingers. It smells of candle and dust."]},
	"iron": {"type": "material", "icon": "iron", "rarity": 2, "price": 700, "name": ["Esquirla de Nimbo", "Nimbus Shard"],
		"desc": ["Un trozo de la aureola que sellaba la Espiral. Ozias la usa para sus grabados y Brenna para las mejoras altas.", "A piece of the halo that sealed the Spiral. Ozias uses it for engravings and Brenna for high upgrades."]},
	"tear": {"type": "material", "icon": "tear", "rarity": 3, "price": 900, "name": ["Lágrima Cristalizada", "Crystallized Tear"],
		"desc": ["Lo que queda de un ángel que lloró hasta olvidar por qué. Madre Ilse la usa para fortalecer tus Lágrimas.", "What remains of an angel who wept until she forgot why. Mother Ilse uses it to strengthen your Tears."]},
}
const RARITY_COLORS := [Color(0.75, 0.72, 0.78), Color(0.55, 0.9, 0.55), Color(0.35, 0.75, 1.0), Color(0.85, 0.45, 1.0), Color(1.0, 0.75, 0.25)]

const MEMORIES := {
	"m3": {"title": ["La Primera Pluma", "The First Feather"], "lines": [
		["Recuerdas una sala blanca y una orden que no era tuya.", "You remember a white hall and an order that wasn't yours."],
		["Seravel, de rodillas, con las alas abiertas. Confiaba en ti.", "Seravel, on her knees, wings open. She trusted you."],
		["Y recuerdas tus propias manos arrancándole la primera pluma.", "And you remember your own hands tearing out her first feather."],
		["Antes de caer, fuiste el verdugo del Arquitecto.", "Before you fell, you were the Architect's executioner."]]},
	"m4": {"title": ["La Orden", "The Order"], "lines": [
		["Una voz sin boca te habla desde todas partes a la vez.", "A voice without a mouth speaks to you from everywhere at once."],
		["«Ellos se negaron. Tú no te negarás.» No era una pregunta.", "\"They refused. You will not refuse.\" It wasn't a question."],
		["Te dieron una capucha para que nadie viera tu cara. Ni siquiera tú.", "They gave you a hood so no one would see your face. Not even you."],
		["Dudaste una vez. Solo una. Y esa duda es lo único que te pertenece.", "You hesitated once. Only once. And that doubt is the only thing that is truly yours."]]},
	"m1": {"title": ["El Jardín de las Alas", "The Garden of Wings"], "lines": [
		["Antes de la Espiral, había un jardín donde nadie contaba los días.", "Before the Spiral, there was a garden where no one counted the days."],
		["Aprendimos a volar entre sus árboles de luz. Torpes. Riendo.", "We learned to fly among its trees of light. Clumsy. Laughing."],
		["Alguien me prometió que volveríamos cuando todo terminara.", "Someone promised me we would return when it was all over."],
		["No recuerdo su rostro. Solo el calor de su mano en la mía.", "I don't remember their face. Only the warmth of their hand in mine."],
	]},
	"m2": {"title": ["La Última Brasa", "The Last Ember"], "lines": [
		["La primera brasa la encendió una niña con las alas quemadas.", "The first ember was lit by a girl with burnt wings."],
		["Dijo que mientras ardiera, nadie se perdería del todo.", "She said that while it burned, no one would be lost entirely."],
		["Todavía arde.", "It still burns."],
	]},
}

# ------------------------------------------------------------------ dificultad
const DIFFICULTIES := [
	{"name": ["Ala Ligera", "Light Wing"], "tag": ["Accesible: para todo el mundo", "Accessible: for everyone"],
		"desc": ["Daño enemigo muy bajo, telegráficos más visibles y conservas todos tus Ecos. Las Brasas te devuelven plumas.", "Very low enemy damage, clearer telegraphs and you keep all your Echoes. Embers give feathers back."],
		"hp": 0.6, "dmg": 0.4, "cd": 1.4, "ecos": 1.0, "keep": 1.0, "phase3": false, "skulls": 0, "color": Color(0.55, 0.85, 1.0), "regrow": true},
	{"name": ["Peregrino", "Pilgrim"], "tag": ["Para disfrutar de la historia", "To enjoy the story"],
		"desc": ["Enemigos con menos vida y daño. Al morir conservas la mitad de tus Ecos. Los jefes no tienen fase final.", "Enemies have less health and damage. You keep half your Echoes on death. Bosses have no final phase."],
		"hp": 0.75, "dmg": 0.6, "cd": 1.25, "ecos": 1.0, "keep": 0.5, "phase3": false, "skulls": 1, "color": Color(0.45, 0.9, 0.6), "regrow": false},
	{"name": ["Desplumado", "Featherless"], "tag": ["La experiencia pensada", "The intended experience"],
		"desc": ["El equilibrio previsto. Los jefes despiertan su fase final al borde de la muerte.", "The intended balance. Bosses awaken their final phase at death's door."],
		"hp": 1.0, "dmg": 1.0, "cd": 1.0, "ecos": 1.0, "keep": 0.0, "phase3": true, "skulls": 2, "color": Color(1.0, 0.82, 0.3), "regrow": false},
	{"name": ["Serafín Caído", "Fallen Seraph"], "tag": ["Sin piedad", "No mercy"],
		"desc": ["Enemigos más fuertes, rápidos y agresivos; los jefes ganan ataques nuevos. +30% de Ecos.", "Stronger, faster and more aggressive enemies; bosses gain new attacks. +30% Echoes."],
		"hp": 1.45, "dmg": 1.5, "cd": 0.75, "ecos": 1.3, "keep": 0.0, "phase3": true, "skulls": 3, "color": Color(1.0, 0.25, 0.35), "regrow": false},
]

# ------------------------------------------------------------------ grabados de Ozias (infusiones de arma)
const INFUSIONS := {
	"": {"name": ["Sin grabado", "No engraving"], "color": Color(1, 0.95, 0.85), "desc": ["El acero tal y como salió de la forja.", "Steel as it left the forge."]},
	"brasa": {"name": ["Grabado de Brasa", "Ember Engraving"], "color": Color(1.0, 0.5, 0.15),
		"desc": ["Los golpes queman: +20% de daño de fuego que se acumula.", "Hits burn: +20% stacking fire damage."]},
	"escarcha": {"name": ["Grabado de Escarcha", "Frost Engraving"], "color": Color(0.5, 0.85, 1.0),
		"desc": ["Los golpes ralentizan al enemigo y quiebran su postura (+40%).", "Hits slow the enemy and crack their posture (+40%)."]},
	"nimbo": {"name": ["Grabado del Nimbo", "Nimbus Engraving"], "color": Color(1.0, 0.9, 0.45),
		"desc": ["El arma escala con Fe y recupera Luz al golpear.", "The weapon scales with Faith and restores Light on hit."]},
	"sangre": {"name": ["Grabado de Sangre de Luz", "Lightblood Engraving"], "color": Color(1.0, 0.25, 0.4),
		"desc": ["Cada tercer golpe abre una herida: daño igual al 6% de la vida máxima.", "Every third hit opens a wound: damage equal to 6% of max health."]},
}

const SHOP := [["vial_luz", 99], ["vial_aliento", 99], ["bomb", 99], ["incense", 99], ["ointment", 99], ["_feather", 6], ["iron", 2], ["tear", 1]]

const OATHS := {
	"carcelero": {"name": ["Juramento de la Cadena", "Oath of the Chain"], "color": Color(1, 0.5, 0.3),
		"desc": ["+40% de daño a la postura y +10% de daño. Te mueves un 8% más lento.", "+40% posture damage and +10% damage. You move 8% slower."]},
	"choir": {"name": ["Juramento del Coro", "Oath of the Choir"], "color": Color(0.8, 0.55, 1.0),
		"desc": ["Los hechizos cuestan un 30% menos de Luz y dañan un 20% más. -15% de vida máxima.", "Spells cost 30% less Light and deal 20% more damage. -15% max health."]},
	"seravel": {"name": ["Juramento de la Puerta", "Oath of the Gate"], "color": Color(1, 0.85, 0.45),
		"desc": ["El Instante (esquiva perfecta) dura el doble y llena más Ira. El aguante se recupera un 25% más lento.", "The Instant (perfect dodge) lasts twice as long and builds more Wrath. Stamina recovers 25% slower."]},
}
const WEAPON_MEMORY := {
	"hueco": [40, ["Segadora de Huecos", "Husk Reaper"]], "acolito": [25, ["Quiebracantos", "Chantbreaker"]],
	"bestia": [20, ["Domadora de Bestias", "Beast Tamer"]], "carcelero": [2, ["Matadora de Carceleros", "Jailer-Slayer"]],
	"choir": [2, ["Silenciadora del Coro", "Choir-Silencer"]], "seravel": [2, ["Rompepuertas", "Gatebreaker"]],
	"sombra": [3, ["Exorcista", "Exorcist"]],
}
const SYNERGIES := {
	"ash_wing": {"a": ["amulet_ash", "amulet_wing"], "name": ["Ala de Rescoldo", "Ember Wing"], "desc": ["Tus esquivas dejan un rastro de fuego.", "Your dashes leave a trail of fire."]},
	"eye_choir": {"a": ["amulet_eye", "choir_heart"], "name": ["Mirada Coral", "Choral Gaze"], "desc": ["Los críticos devuelven Luz.", "Critical hits restore Light."]},
	"wing_eye": {"a": ["amulet_wing", "amulet_eye"], "name": ["Vuelo del Halcón", "Hawk's Flight"], "desc": ["Tras una esquiva perfecta, el siguiente golpe es crítico doble.", "After a perfect dodge, your next hit is a double critical."]},
}

func ability(id: String) -> bool:
	## Empiezas solo con el ataque básico; el resto se gana jugando
	match id:
		"lance": return flags.get("ab_lance", false)
		"nova": return flags.get("ab_lance", false) and has_skill("l2")
		"wrath": return flags.get("ab_wrath", false)
	return true

func grant_ability(id: String) -> void:
	if flags.get("ab_" + id, false):
		return
	flags["ab_" + id] = true
	var names := {"lance": ["LANZA DE LUZ", "LANCE OF LIGHT"], "wrath": ["IRA SERÁFICA", "SERAPHIC WRATH"]}
	G.toast(G.L(["NUEVA HABILIDAD: ", "NEW ABILITY: "]) + G.L(names.get(id, ["?", "?"])) + "  [" + G.key_label({"lance": "spell1", "wrath": "wrath"}.get(id, "spell1")) + "]", Color(1, 0.85, 0.4))
	Audio.sfx("levelup", -4.0)
	changed.emit()

func desplume() -> float:
	return float(WING_MAX - wing_feathers) / float(WING_MAX)

func is_desplumado() -> bool:
	return wing_feathers <= 3

func weapon_memory_mult(etype: String, wid := "") -> float:
	if wid == "":
		wid = equipped
	if not WEAPON_MEMORY.has(etype):
		return 1.0
	return 1.2 if int(weapon_kills.get(wid, {}).get(etype, 0)) >= WEAPON_MEMORY[etype][0] else 1.0

func record_kill(etype: String) -> void:
	if not WEAPON_MEMORY.has(etype):
		return
	if not weapon_kills.has(equipped):
		weapon_kills[equipped] = {}
	var n: int = int(weapon_kills[equipped].get(etype, 0)) + 1
	weapon_kills[equipped][etype] = n
	if n == WEAPON_MEMORY[etype][0]:
		G.toast(G.L(["MEMORIA DEL ARMA: ", "WEAPON MEMORY: "]) + G.L(WEAPON_MEMORY[etype][1]).to_upper(), Color(1, 0.8, 0.4))
		Audio.sfx("levelup", -4.0)

func synergy(id: String) -> bool:
	var a: Array = SYNERGIES[id].a
	var on: bool = has_amulet(a[0]) and has_amulet(a[1])
	if on and not synergies.has(id):
		synergies[id] = true
		G.toast(G.L(["SINERGIA DESCUBIERTA: ", "SYNERGY DISCOVERED: "]) + G.L(SYNERGIES[id].name).to_upper(), Color(0.9, 0.6, 1.0))
	return on

# ------------------------------------------------------------------ estructura: juego base + 2 DLC -> 2 finales
## Juego base (~10 h, 4 estratos, final abierto) -> DLC I "Los Cielos Rotos" (~5 h) y DLC II "El Abismo Sin Nombre" (~5 h),
## cada uno con su final. Las decisiones de las tres partes deciden el final definitivo: ALAS ABIERTAS o EL TRONO VACÍO.
const CAMPAIGN := [
	{"id": "base", "name": ["Seraphall", "Seraphall"], "hours": 10, "strata": ["Vestíbulo de Ceniza", "Bosque de Plumas Muertas", "Fundición de Halos", "El Trono Vacío"]},
	{"id": "dlc1", "name": ["Los Cielos Rotos", "The Broken Heavens"], "hours": 5},
	{"id": "dlc2", "name": ["El Abismo Sin Nombre", "The Nameless Abyss"], "hours": 5},
]

func route_score() -> int:
	## > 0: Alas Abiertas (libertad) · < 0: El Trono Vacío (dominio)
	var sc := 0
	for b in BOSS_INFO:
		if flags.get(BOSS_INFO[b].flag, false):
			sc += 2 if spared.has(b) else -1
	sc += memories.size()
	if oath != "":
		sc -= 1
	if wing_feathers >= 7:
		sc += 1
	elif wing_feathers <= 3:
		sc -= 1
	return sc

func route_name() -> String:
	return G.T("route_wings") if route_score() >= 0 else G.T("route_throne")

func start_ng() -> void:
	## Segundo Descenso: conservas personaje, armas y objetos; el mundo vuelve a empezar, más cruel.
	ng += 1
	flags = {}; quests = {}; last_brasa = "sanct"; dropped_ecos = {}; shadow = {}; unrecovered = 0
	boss_deaths = {}; spared = {}; shop_bought = {}
	inventory.erase("key_vestibule")
	save_game()

func lose_wing_feather() -> void:
	wing_feathers = max(0, wing_feathers - 1)
	changed.emit()

func regrow_wing_feather() -> bool:
	if wing_feathers >= WING_MAX:
		return false
	wing_feathers += 1
	changed.emit()
	return true

const BOSS_INFO := {
	"carcelero": {"rank": 1, "title": "boss_carcelero", "flag": "carcelero_dead"},
	"choir": {"rank": 2, "title": "boss_choir", "flag": "choir_dead"},
	"seravel": {"rank": 3, "title": "boss_seravel", "flag": "seravel_dead"},
}
const ASCENSION_REWARDS := {1: {"ecos": 800, "iron": 1}, 2: {"ecos": 1600, "tear": 1}, 3: {"ecos": 3200, "iron": 2, "tear": 1}}

# ------------------------------------------------------------------ árbol de habilidades
## pos = (columna, fila) dentro de la rama; req = nodos necesarios
const SKILLS := {
	"f1": {"branch": "filo", "pos": Vector2i(1, 0), "cost": 1, "req": [], "name": ["Filo Templado", "Tempered Edge"], "desc": ["+12% daño cuerpo a cuerpo.", "+12% melee damage."]},
	"f2": {"branch": "filo", "pos": Vector2i(0, 1), "cost": 1, "req": ["f1"], "name": ["Corte Final", "Final Cut"], "desc": ["+1 golpe de combo, el último es devastador.", "+1 combo hit, the last one is devastating."]},
	"f3": {"branch": "filo", "pos": Vector2i(2, 1), "cost": 1, "req": ["f1"], "name": ["Carga Profunda", "Deep Charge"], "desc": ["Cargas el pesado un 35% más rápido y hace +25% daño.", "Charge heavy 35% faster, +25% damage."]},
	"f4": {"branch": "filo", "pos": Vector2i(0, 2), "cost": 2, "req": ["f2"], "name": ["Sed de Ceniza", "Ash Thirst"], "desc": ["Robas 3% del daño como vida.", "Steal 3% of damage as health."]},
	"f5": {"branch": "filo", "pos": Vector2i(2, 2), "cost": 2, "req": ["f3"], "name": ["Ejecución Brutal", "Brutal Execution"], "desc": ["+60% daño a enemigos con postura rota.", "+60% damage to posture-broken foes."]},
	"f6": {"branch": "filo", "pos": Vector2i(1, 3), "cost": 3, "req": ["f4", "f5"], "name": ["Tormenta de Acero", "Steel Tempest"], "desc": ["La Ira Seráfica se llena un 40% más rápido.", "Seraphic Wrath fills 40% faster."]},
	"a1": {"branch": "ala", "pos": Vector2i(1, 0), "cost": 1, "req": [], "name": ["Pies Ligeros", "Light Feet"], "desc": ["El dash cuesta 25% menos aguante.", "Dash costs 25% less stamina."]},
	"a2": {"branch": "ala", "pos": Vector2i(0, 1), "cost": 1, "req": ["a1"], "name": ["Doble Dash", "Double Dash"], "desc": ["Puedes encadenar dos dash seguidos.", "Chain two dashes in a row."]},
	"a3": {"branch": "ala", "pos": Vector2i(2, 1), "cost": 1, "req": ["a1"], "name": ["Instante Prolongado", "Lingering Instant"], "desc": ["La esquiva perfecta es más fácil y dura más.", "Perfect dodge is easier and lasts longer."]},
	"a4": {"branch": "ala", "pos": Vector2i(0, 2), "cost": 2, "req": ["a2"], "name": ["Dash Cortante", "Cutting Dash"], "desc": ["Tu dash hiere a los enemigos que atraviesas.", "Your dash damages enemies you pass through."]},
	"a5": {"branch": "ala", "pos": Vector2i(2, 2), "cost": 2, "req": ["a3"], "name": ["Velocidad Seráfica", "Seraphic Speed"], "desc": ["+12% velocidad de movimiento.", "+12% movement speed."]},
	"a6": {"branch": "ala", "pos": Vector2i(1, 3), "cost": 3, "req": ["a4", "a5"], "name": ["Alas de Fuego", "Wings of Fire"], "desc": ["El dash deja un rastro de fuego.", "Dashing leaves a trail of fire."]},
	"l1": {"branch": "luz", "pos": Vector2i(1, 0), "cost": 1, "req": [], "name": ["Lanza Afilada", "Honed Lance"], "desc": ["+25% daño de hechizos.", "+25% spell damage."]},
	"l2": {"branch": "luz", "pos": Vector2i(0, 1), "cost": 1, "req": ["l1"], "name": ["Nova de Ceniza", "Ash Nova"], "desc": ["Nuevo hechizo [E]: explosión a tu alrededor.", "New spell [E]: an explosion around you."]},
	"l3": {"branch": "luz", "pos": Vector2i(2, 1), "cost": 1, "req": ["l1"], "name": ["Fuente Interior", "Inner Spring"], "desc": ["+40% regeneración de Luz.", "+40% Light regeneration."]},
	"l4": {"branch": "luz", "pos": Vector2i(0, 2), "cost": 2, "req": ["l2"], "name": ["Lanza Triple", "Triple Lance"], "desc": ["La Lanza de Luz se divide en tres.", "Lance of Light splits into three."]},
	"l5": {"branch": "luz", "pos": Vector2i(2, 2), "cost": 2, "req": ["l3"], "name": ["Eco de Luz", "Echo of Light"], "desc": ["Golpear con armas recupera Luz.", "Weapon hits restore Light."]},
	"l6": {"branch": "luz", "pos": Vector2i(1, 3), "cost": 3, "req": ["l4", "l5"], "name": ["Juicio", "Judgement"], "desc": ["La Nova es enorme y quema.", "Nova becomes huge and burns."]},
	"c1": {"branch": "ceniza", "pos": Vector2i(1, 0), "cost": 1, "req": [], "name": ["Guardia de Ceniza", "Ash Guard"], "desc": ["Ventana de parry +50%.", "Parry window +50%."]},
	"c2": {"branch": "ceniza", "pos": Vector2i(0, 1), "cost": 1, "req": ["c1"], "name": ["Piel de Piedra", "Stoneskin"], "desc": ["-12% daño recibido.", "-12% damage taken."]},
	"c3": {"branch": "ceniza", "pos": Vector2i(2, 1), "cost": 1, "req": ["c1"], "name": ["Lágrima Extra", "Extra Tear"], "desc": ["+1 carga de Lágrima.", "+1 Tear Flask charge."]},
	"c4": {"branch": "ceniza", "pos": Vector2i(0, 2), "cost": 2, "req": ["c2"], "name": ["Represalia", "Retribution"], "desc": ["Un parry perfecto lanza una onda que daña.", "A perfect parry releases a damaging wave."]},
	"c5": {"branch": "ceniza", "pos": Vector2i(2, 2), "cost": 2, "req": ["c3"], "name": ["Vínculo", "Bond"], "desc": ["Revives al compañero el doble de rápido y regeneras vida cerca de él.", "Revive your partner twice as fast, regenerate near them."]},
	"c6": {"branch": "ceniza", "pos": Vector2i(1, 3), "cost": 3, "req": ["c4", "c5"], "name": ["Último Aliento", "Last Breath"], "desc": ["Una vez por descanso, sobrevives a un golpe mortal.", "Once per rest, survive a lethal blow."]},
	"k1": {"branch": "arconte", "pos": Vector2i(0, 0), "cost": 2, "req": [], "archon": "seravel", "name": ["Espadas Orbitantes", "Orbiting Blades"], "desc": ["Poder de Seravel: tres espadas de luz giran a tu alrededor.", "Seravel's power: three blades of light orbit you."]},
}
const BRANCHES := {
	"filo": {"name": ["Filo", "Edge"], "icon": "filo", "color": Color(1.0, 0.45, 0.4)},
	"ala": {"name": ["Ala", "Wing"], "icon": "ala", "color": Color(0.6, 0.85, 1.0)},
	"luz": {"name": ["Luz", "Light"], "icon": "luz", "color": Color(1.0, 0.9, 0.5)},
	"ceniza": {"name": ["Ceniza", "Ash"], "icon": "ceniza", "color": Color(0.85, 0.6, 0.4)},
	"arconte": {"name": ["Arconte", "Archon"], "icon": "arconte", "color": Color(1.0, 0.35, 0.45)},
}

# ------------------------------------------------------------------ misiones
const QUESTS := {
	"main1": {"type": "main", "title": ["El Primer Descenso", "The First Descent"], "giver": "",
		"steps": [
			{"id": "brasa", "text": ["Enciende la Brasa del Santuario", "Kindle the Sanctuary Ember"]},
			{"id": "talk_brenna", "text": ["Habla con Brenna, la herrera", "Talk to Brenna, the smith"]},
			{"id": "trial_celdas", "text": ["Sobrevive a las Celdas de Espera, al oeste del Pasillo", "Survive the Waiting Cells, west of the Hall"]},
			{"id": "kill_carcelero", "text": ["Derrota al Carcelero y toma su llave", "Defeat the Jailer and take his key"]},
			{"id": "trial_umbral", "text": ["Sube la Escalinata y vence al Custodio del Umbral", "Climb the Stairway and defeat the Threshold Warden"]},
			{"id": "enter_circle", "text": ["Cruza la puerta de luz", "Pass through the gate of light"]},
			{"id": "kill_seravel", "text": ["Derrota a Seravel, Guardiana de las Puertas", "Defeat Seravel, Warden of the Gates"]},
		],
		"reward": {"ecos": 0, "sp": 2}},
	"feathers": {"type": "side", "title": ["Plumas para la Forja", "Feathers for the Forge"], "giver": "brenna",
		"count": 5, "text": ["Reúne Fragmentos de Pluma (%d/%d)", "Gather Feather Shards (%d/%d)"],
		"reward": {"ecos": 300, "free_upgrade": 1}},
	"husks": {"type": "side", "title": ["Los Huecos del Pasillo", "Husks of the Hall"], "giver": "carto",
		"count": 8, "text": ["Abate Huecos (%d/%d)", "Slay Husks (%d/%d)"],
		"reward": {"ecos": 250, "sp": 1, "weapon": "scythe"}},
	"map": {"type": "side", "title": ["El Mapa Perdido", "The Lost Map"], "giver": "carto",
		"count": 1, "text": ["Encuentra el mapa en la Galería Rota (%d/%d)", "Find the map in the Broken Gallery (%d/%d)"],
		"reward": {"ecos": 200, "flask": 1}},
	"choir": {"type": "bounty", "title": ["Silencio en la Galería", "Silence in the Gallery"], "giver": "velaria",
		"count": 1, "text": ["Resuelve el Atrio de las Voces y derrota al Coro Hueco (%d/%d)", "Solve the Atrium of Voices and defeat the Hollow Choir (%d/%d)"],
		"reward": {"ecos": 600, "sp": 1}},
	"hymns": {"type": "side", "title": ["Las Páginas del Himno", "The Hymn Pages"], "giver": "",
		"count": 3, "text": ["Reúne las páginas del Himno de la Vigilia (%d/%d)", "Gather the pages of the Hymn of the Vigil (%d/%d)"],
		"reward": {"ecos": 500, "sp": 1, "item": "amulet_bell"}},
	"jailer_hunt": {"type": "bounty", "title": ["Caza: El Carcelero", "Hunt: The Jailer"], "giver": "brenna",
		"count": 1, "text": ["Derrota al Carcelero (%d/%d)", "Defeat the Jailer (%d/%d)"],
		"reward": {"ecos": 400, "feathers": 3}},
}

# ------------------------------------------------------------------ estado
var level := 1
var ecos := 0
var feathers := 0
var attr := {"vigor": 1, "aguante": 1, "fuerza": 1, "destreza": 1, "fe": 1, "arcano": 1}
var attr_points := 0
var skill_points := 1
var skills := {}  # id -> true
var weapons := {"sword": 0}  # id -> nivel de mejora
var equipped := "sword"
var flasks_max := 3
var free_upgrades := 0
var quests := {}  # id -> {"state": "active"/"done", "step": int, "progress": int}
var flags := {}  # banderas de mundo: brasa_lit, carcelero_dead, seravel_dead, chests...
var last_brasa := "sanct"
var dropped_ecos := {}  # {"amount": n, "pos": [x, y]}
var playtime := 0.0
var inventory := {}            # id -> cantidad
var amulets_eq := ["", ""]
var quick_item := "bomb"
var memories := {}             # id -> true
var buffs := {}                # efectos temporales (no se guardan): id -> segundos
var difficulty := 2
# ---- v0.4: plumas, sombra, memoria de armas, juramentos, perdón, aspecto
const WING_MAX := 10
var wing_feathers := WING_MAX   # plumas del ala: cada muerte arranca una
var deaths := 0
var boss_deaths := {}           # jefe -> veces que te ha matado
var unrecovered := 0            # muertes seguidas sin recuperar los Ecos
var shadow := {}                # sombra activa {"amount", "pos"}
var weapon_kills := {}          # arma -> {tipo: bajas}
var oath := ""                  # juramento activo (jefe)
var spared := {}                # Arcontes perdonados

# ------------------------------------------------------------------ logros
const ACHIEVEMENTS := {
	"first_blood": [["Primera Sangre", "First Blood"], ["Derrota a tu primer enemigo.", "Defeat your first enemy."]],
	"jailer": [["Sin Llave", "Keyless"], ["Derrota al Carcelero.", "Defeat the Jailer."]],
	"choir": [["Silencio", "Silence"], ["Haz callar al Coro Hueco.", "Silence the Hollow Choir."]],
	"seravel": [["Las Puertas", "The Gates"], ["Derrota a Seravel, Guardiana de las Puertas.", "Defeat Seravel, Warden of the Gates."]],
	"spare": [["Misericordia", "Mercy"], ["Perdona a un Arconte.", "Spare an Archon."]],
	"secret": [["Lo que se oculta", "What Lies Hidden"], ["Descubre la Capilla Olvidada.", "Discover the Forgotten Chapel."]],
	"bells": [["Al Revés", "Backwards"], ["Tañe el Himno de la Vigilia como lo cantaba el Coro.", "Ring the Hymn of the Vigil as the Choir sang it."]],
	"trials": [["Digno del Juicio", "Worthy of Judgement"], ["Supera las tres pruebas de las antesalas.", "Clear all three antechamber trials."]],
	"executioner": [["Verdugo", "Executioner"], ["Ejecuta a 10 enemigos.", "Execute 10 enemies."]],
	"featherless": [["Desplumado", "Featherless"], ["Quédate con 3 plumas o menos.", "Be left with 3 feathers or fewer."]],
	"hymn": [["El Himno Completo", "The Whole Hymn"], ["Reúne las tres páginas del himno.", "Gather all three hymn pages."]],
	"memories": [["Lo Que Fui", "What I Was"], ["Recupera 4 recuerdos.", "Recover 4 memories."]],
	"echoes": [["Mil Años Atrás", "A Thousand Years Ago"], ["Presencia todos los ecos del pasado (uno está bien escondido).", "Witness every echo of the past (one is well hidden)."]],
}

func achieve(id: String) -> void:
	if flags.get("ach_" + id, false) or not ACHIEVEMENTS.has(id):
		return
	flags["ach_" + id] = true
	G.pickup("icon_quest", G.L(["LOGRO: ", "ACHIEVEMENT: "]) + G.L(ACHIEVEMENTS[id][0]).to_upper(), Color(1, 0.85, 0.35))
	Audio.sfx("levelup", -10.0)

func achievements_count() -> int:
	var n := 0
	for k in ACHIEVEMENTS:
		if flags.get("ach_" + k, false):
			n += 1
	return n
var synergies := {}             # sinergias descubiertas
var ng := 0                     # Segundo Descenso (NG+)
var spark := false              # Chispa, la brasa viva
var event_ecos := 1.0           # multiplicador de los eventos del mundo (no se guarda)
var infusions := {}            # arma -> grabado
var flask_level := 0           # potencia de las Lágrimas (Madre Ilse)
var shop_bought := {}          # objeto -> comprados
var ascension := {}            # jefe -> nivel máximo superado

func _process(delta: float) -> void:
	playtime += delta
	for k in buffs.keys():
		buffs[k] -= delta
		if buffs[k] <= 0.0:
			buffs.erase(k)
			changed.emit()

func reset() -> void:
	level = 1; ecos = 0; feathers = 0
	attr = {"vigor": 1, "aguante": 1, "fuerza": 1, "destreza": 1, "fe": 1, "arcano": 1}
	attr_points = 0; skill_points = 1; skills = {}
	weapons = {"sword": 0}; equipped = "sword"; flasks_max = 3; free_upgrades = 0
	quests = {}; flags = {}; last_brasa = "sanct"; dropped_ecos = {}; playtime = 0.0
	inventory = {"bomb": 2, "incense": 1}; amulets_eq = ["", ""]; quick_item = "bomb"; memories = {}; buffs = {}
	infusions = {}; flask_level = 0; shop_bought = {}; ascension = {}
	wing_feathers = WING_MAX; deaths = 0; boss_deaths = {}; unrecovered = 0; shadow = {}; weapon_kills = {}
	oath = ""; spared = {}; synergies = {}; ng = 0; spark = false
	changed.emit()

# ------------------------------------------------------------------ estadísticas derivadas
func has_skill(id: String) -> bool:
	return skills.has(id)

func max_hp() -> float:
	var hp = (100.0 + (attr.vigor - 1) * 14.0) * (1.0 - 0.3 * desplume())
	if oath == "choir":
		hp *= 0.85
	return hp

func diff() -> Dictionary:
	return DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]

func infusion(wid := "") -> String:
	if wid == "":
		wid = equipped
	return infusions.get(wid, "")

func heal_ratio() -> float:
	return 0.45 + 0.07 * flask_level

func spell_cost_mult() -> float:
	return (0.75 if has_amulet("choir_heart") else 1.0) * (0.7 if oath == "choir" else 1.0)

func has_amulet(id: String) -> bool:
	return id in amulets_eq

func stamina_regen_mult() -> float:
	return (1.3 if has_amulet("amulet_wing") else 1.0) * (0.75 if oath == "seravel" else 1.0) * (2.0 if buffs.has("vial_aliento") else 1.0)

func buff_damage_mult() -> float:
	return 1.3 if buffs.has("incense") else 1.0

func max_stamina() -> float:
	return 100.0 + (attr.aguante - 1) * 7.0

func max_light() -> float:
	return 60.0 + (attr.fe - 1) * 6.0

func move_speed() -> float:
	return 118.0 * (1.12 if has_skill("a5") else 1.0) * (1.0 + 0.15 * desplume()) * (0.92 if oath == "carcelero" else 1.0)

func flask_count() -> int:
	return flasks_max + (1 if has_skill("c3") else 0)

func weapon_data(id := "") -> Dictionary:
	if id == "":
		id = equipped
	return WEAPONS.get(id, WEAPONS["sword"])

func weapon_damage(id := "") -> float:
	if id == "":
		id = equipped
	var w := weapon_data(id)
	var up: int = weapons.get(id, 0)
	var fe_s: float = w.fe + (0.6 if infusion(id) == "nimbo" else 0.0)
	var scale: float = 1.0 + 0.045 * ((attr.fuerza - 1) * w.fue + (attr.destreza - 1) * w.des + (attr.fe - 1) * fe_s)
	var dmg: float = w.dmg * scale * (1.0 + 0.09 * up)
	if has_skill("f1"):
		dmg *= 1.12
	dmg *= 1.0 + 0.3 * desplume() + (0.1 if is_desplumado() else 0.0)
	if oath == "carcelero":
		dmg *= 1.1
	return dmg * buff_damage_mult()

func spell_damage(base: float) -> float:
	return base * (1.0 + 0.06 * (attr.fe - 1)) * (1.25 if has_skill("l1") else 1.0) * buff_damage_mult() * (1.2 if oath == "choir" else 1.0)

func crit_chance() -> float:
	return 0.05 + 0.012 * (attr.destreza - 1) + (0.1 if has_amulet("amulet_eye") else 0.0)

func damage_taken_mult() -> float:
	return (0.88 if has_skill("c2") else 1.0) * (0.65 if buffs.has("ointment") else 1.0)

func ecos_mult() -> float:
	return (1.0 + 0.03 * (attr.arcano - 1)) * diff().ecos * event_ecos * (1.0 + 0.25 * ng)

func level_cost() -> int:
	return int(90 + 55 * level + 6 * level * level)

func upgrade_cost(id: String) -> Array:
	var lv: int = weapons.get(id, 0)
	return [180 * (lv + 1), lv + 1, 1 if lv >= 4 else 0]  # [ecos, plumas, esquirlas de nimbo]

# ------------------------------------------------------------------ acciones
func add_ecos(n: int) -> void:
	ecos += int(n * ecos_mult())
	changed.emit()

func add_feathers(n: int) -> void:
	feathers += n
	if quest_active("feathers"):
		quest_progress("feathers", n)
	changed.emit()

func buy_level(stat: String) -> bool:
	var c := level_cost()
	if ecos < c:
		return false
	ecos -= c
	level += 1
	attr[stat] += 1
	skill_points += 1
	changed.emit()
	return true

func can_unlock(id: String) -> bool:
	if has_skill(id):
		return false
	var s: Dictionary = SKILLS[id]
	if s.has("archon") and not flags.get(s.archon + "_dead", false):
		return false
	for r in s.req:
		if not has_skill(r):
			return false
	return skill_points >= s.cost

func unlock(id: String) -> bool:
	if not can_unlock(id):
		return false
	skill_points -= SKILLS[id].cost
	skills[id] = true
	changed.emit()
	return true

func add_weapon(id: String) -> void:
	if not weapons.has(id):
		weapons[id] = 0
		G.pickup("weapon_" + WEAPONS[id].sprite, G.T("new_weapon") % G.L(WEAPONS[id].name), Color(1, 0.8, 0.4))
	changed.emit()

func upgrade_weapon(id: String) -> bool:
	var lv: int = weapons.get(id, 0)
	if lv >= 10:
		return false
	if free_upgrades > 0:
		free_upgrades -= 1
	else:
		var c := upgrade_cost(id)
		if ecos < c[0] or feathers < c[1] or item_count("iron") < c[2]:
			return false
		ecos -= c[0]
		feathers -= c[1]
		if c[2] > 0:
			remove_item("iron", c[2])
	weapons[id] = lv + 1
	changed.emit()
	return true

# ------------------------------------------------------------------ inventario
func item_count(id: String) -> int:
	return int(inventory.get(id, 0))

func add_item(id: String, n := 1, silent := false) -> void:
	if not ITEMS.has(id):
		return
	inventory[id] = item_count(id) + n
	if ITEMS[id].type == "amulet":
		inventory[id] = 1
	if not silent:
		G.pickup("icon_" + ITEMS[id].icon, G.L(ITEMS[id].name) + ("" if n <= 1 else "  x%d" % n), RARITY_COLORS[ITEMS[id].rarity])
	changed.emit()

func remove_item(id: String, n := 1) -> bool:
	if item_count(id) < n:
		return false
	inventory[id] = item_count(id) - n
	if inventory[id] <= 0:
		inventory.erase(id)
	changed.emit()
	return true

## Consumir un objeto (los efectos de lanzamiento los aplica el jugador). Devuelve true si se usó.
func use_item(id: String) -> bool:
	if ITEMS.get(id, {}).get("type", "") != "consumable" or id == "phoenix":
		return false
	if not remove_item(id):
		return false
	match id:
		"incense":
			buffs["incense"] = 30.0
		"ointment":
			buffs["ointment"] = 30.0
		"vial_aliento":
			buffs["vial_aliento"] = 20.0
	changed.emit()
	return true

func equip_amulet(id: String) -> void:
	if not inventory.has(id) or has_amulet(id):
		return
	var slot := amulets_eq.find("")
	if slot < 0:
		slot = 1
	amulets_eq[slot] = id
	for sy in SYNERGIES:
		synergy(sy)
	changed.emit()

func unequip_amulet(id: String) -> void:
	var i := amulets_eq.find(id)
	if i >= 0:
		amulets_eq[i] = ""
	changed.emit()

# ------------------------------------------------------------------ servicios de la Sala del Nimbo
func engrave(wid: String, inf: String) -> bool:
	if infusion(wid) == inf or ecos < 400 or item_count("iron") < 1:
		return false
	ecos -= 400
	remove_item("iron", 1)
	infusions[wid] = inf
	changed.emit()
	return true

func flask_upgrade_cost() -> int:
	return 1 + flask_level / 2

func upgrade_flask_potency() -> bool:
	if flask_level >= 5 or item_count("tear") < flask_upgrade_cost():
		return false
	remove_item("tear", flask_upgrade_cost())
	flask_level += 1
	changed.emit()
	return true

func buy_flask_charge() -> bool:
	if flasks_max >= 8 or item_count("tear") < 2:
		return false
	remove_item("tear", 2)
	flasks_max += 1
	changed.emit()
	return true

func shop_price(id: String) -> int:
	if id == "_feather":
		return 250
	return int(ITEMS[id].get("price", 500))

func shop_left(id: String, limit: int) -> int:
	return limit - int(shop_bought.get(id, 0))

func buy(id: String, limit: int) -> bool:
	var price := shop_price(id)
	if ecos < price or shop_left(id, limit) <= 0:
		return false
	ecos -= price
	shop_bought[id] = int(shop_bought.get(id, 0)) + 1
	if id == "_feather":
		add_feathers(1)
	else:
		add_item(id, 1, true)
	changed.emit()
	return true

func grant_ascension(boss: String, level: int) -> void:
	var first := int(ascension.get(boss, 0)) < level
	ascension[boss] = max(int(ascension.get(boss, 0)), level)
	if first:
		var r: Dictionary = ASCENSION_REWARDS[level]
		ecos += r.ecos
		for k in r:
			if k != "ecos":
				add_item(k, r[k])
	changed.emit()

func unlock_memory(id: String) -> bool:
	if memories.size() >= 3:
		achieve("memories")
	if memories.has(id):
		return false
	memories[id] = true
	changed.emit()
	return true

# ------------------------------------------------------------------ misiones
func quest_active(id: String) -> bool:
	return quests.has(id) and quests[id].state == "active"

func quest_done(id: String) -> bool:
	return quests.has(id) and quests[id].state == "done"

func start_quest(id: String) -> void:
	if quests.has(id):
		return
	quests[id] = {"state": "active", "step": 0, "progress": 0}
	Audio.sfx("quest")
	G.toast(G.T("quest_new") + ": " + G.L(QUESTS[id].title), Color(0.7, 0.9, 1.0))
	if id == "feathers" and feathers > 0:
		quest_progress("feathers", feathers)
	quest_updated.emit(id)
	changed.emit()

func quest_step(id: String, step_id: String) -> void:
	## Avanza la misión principal si el paso actual coincide.
	if not quest_active(id):
		return
	var q: Dictionary = QUESTS[id]
	var st: int = quests[id].step
	var found := -1
	for i in range(st, q.steps.size()):
		if q.steps[i].id == step_id:
			found = i
			break
	if found >= 0:
		quests[id].step = found + 1
		st = found
		Audio.sfx("quest", -4.0)
		if quests[id].step >= q.steps.size():
			_complete(id)
		quest_updated.emit(id)
		changed.emit()

func quest_progress(id: String, n := 1) -> void:
	if not quest_active(id):
		return
	var q: Dictionary = QUESTS[id]
	quests[id].progress = min(q.count, quests[id].progress + n)
	if quests[id].progress >= q.count:
		_complete(id)
	quest_updated.emit(id)
	changed.emit()

func _complete(id: String) -> void:
	quests[id].state = "done"
	var r: Dictionary = QUESTS[id].reward
	ecos += r.get("ecos", 0)
	skill_points += r.get("sp", 0)
	free_upgrades += r.get("free_upgrade", 0)
	feathers += r.get("feathers", 0)
	if r.has("flask"):
		flasks_max += r.flask
		G.toast(G.T("flask_up"), Color(1, 0.6, 0.5))
	if r.has("weapon"):
		add_weapon(r.weapon)
	if r.has("item"):
		add_item(r.item)
	if id == "hymns":
		achieve("hymn")
	Audio.sfx("levelup")
	G.toast(G.T("quest_done") + ": " + G.L(QUESTS[id].title), Color(1.0, 0.85, 0.4))

func quest_text(id: String) -> String:
	var q: Dictionary = QUESTS[id]
	var st: Dictionary = quests.get(id, {})
	if q.has("steps"):
		var i: int = st.get("step", 0)
		if i >= q.steps.size():
			return G.L(q.title)
		return G.L(q.steps[i].text)
	return G.L(q.text) % [st.get("progress", 0), q.count]

# ------------------------------------------------------------------ guardado
func to_dict() -> Dictionary:
	return {"v": 1, "level": level, "ecos": ecos, "feathers": feathers, "attr": attr, "attr_points": attr_points,
		"skill_points": skill_points, "skills": skills, "weapons": weapons, "equipped": equipped, "flasks_max": flasks_max,
		"free_upgrades": free_upgrades, "quests": quests, "flags": flags, "last_brasa": last_brasa,
		"dropped_ecos": dropped_ecos, "playtime": playtime, "lang": G.lang, "inventory": inventory,
		"amulets_eq": amulets_eq, "quick_item": quick_item, "memories": memories, "difficulty": difficulty,
		"infusions": infusions, "flask_level": flask_level, "shop_bought": shop_bought, "ascension": ascension,
		"wing_feathers": wing_feathers, "deaths": deaths, "boss_deaths": boss_deaths, "unrecovered": unrecovered, "shadow": shadow,
		"weapon_kills": weapon_kills, "oath": oath, "spared": spared, "synergies": synergies, "ng": ng, "spark": spark, "look": G.look}

func from_dict(d: Dictionary) -> void:
	level = int(d.get("level", 1)); ecos = int(d.get("ecos", 0)); feathers = int(d.get("feathers", 0))
	for k in attr.keys():
		attr[k] = int(d.get("attr", {}).get(k, 1))
	attr_points = int(d.get("attr_points", 0)); skill_points = int(d.get("skill_points", 1))
	skills = d.get("skills", {})
	weapons = {}
	for k in d.get("weapons", {"sword": 0}):
		weapons[k] = int(d.weapons[k])
	equipped = d.get("equipped", "sword"); flasks_max = int(d.get("flasks_max", 3)); free_upgrades = int(d.get("free_upgrades", 0))
	quests = {}
	var dq: Dictionary = d.get("quests", {})
	for k in dq:
		quests[k] = {"state": dq[k].get("state", "active"), "step": int(dq[k].get("step", 0)), "progress": int(dq[k].get("progress", 0))}
	flags = d.get("flags", {}); last_brasa = d.get("last_brasa", "sanct"); dropped_ecos = d.get("dropped_ecos", {})
	playtime = float(d.get("playtime", 0.0))
	inventory = {}
	var inv: Dictionary = d.get("inventory", {"bomb": 2})
	for k in inv:
		inventory[k] = int(inv[k])
	var ae: Array = d.get("amulets_eq", ["", ""])
	amulets_eq = [str(ae[0]) if ae.size() > 0 else "", str(ae[1]) if ae.size() > 1 else ""]
	quick_item = d.get("quick_item", "bomb")
	memories = d.get("memories", {})
	buffs = {}
	difficulty = int(d.get("difficulty", 2))
	wing_feathers = int(d.get("wing_feathers", WING_MAX)); deaths = int(d.get("deaths", 0))
	boss_deaths = {}
	for k in d.get("boss_deaths", {}):
		boss_deaths[k] = int(d.boss_deaths[k])
	unrecovered = int(d.get("unrecovered", 0)); shadow = d.get("shadow", {})
	weapon_kills = d.get("weapon_kills", {}); oath = str(d.get("oath", "")); spared = d.get("spared", {})
	synergies = d.get("synergies", {}); ng = int(d.get("ng", 0)); spark = bool(d.get("spark", false))
	if d.has("look"):
		G.look = d.look
	if flags.get("brasa_sanct", false):
		flags["ab_lance"] = true
	if flags.get("carcelero_dead", false):
		flags["ab_wrath"] = true
	infusions = d.get("infusions", {})
	flask_level = int(d.get("flask_level", 0))
	shop_bought = d.get("shop_bought", {})
	ascension = {}
	var asc: Dictionary = d.get("ascension", {})
	for k in asc:
		ascension[k] = int(asc[k])
	changed.emit()

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "\t"))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Lee la partida guardada sin cargarla (para la ficha de "Continuar" en la pantalla de inicio)
func peek_save() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else {}

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		from_dict(data)
		return true
	return false

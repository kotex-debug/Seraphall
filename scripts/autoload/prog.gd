extends Node
## Progreso del jugador local: nivel, atributos, Ecos, árbol de habilidades, armas, misiones, guardado.

signal changed
signal quest_updated(id: String)

const SAVE_PATH := "user://seraphall_save.json"
## Las pruebas automáticas nunca tocan la partida real del jugador
const SAVE_PATH_TEST := "user://seraphall_save_test.json"
func save_path() -> String:
	return SAVE_PATH_TEST if G.autotest != "" else SAVE_PATH

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
	# --- v0.8: tres estilos de combate nuevos
	"reaper": {"name": ["Guadaña del Segador", "Reaper's Scythe"], "sprite": "reaper", "dmg": 19.0, "speed": 0.78, "range": 42.0,
		"arc": 220.0, "combo": 3, "stam": 15.0, "poise": 12.0, "fue": 0.6, "des": 0.4, "fe": 0.0, "drain": 0.06, "pull": true,
		"desc": ["Barridos enormes y lentos. Cada golpe te devuelve vida y el último atrae a todos hacia la hoja.", "Huge, slow sweeps. Every hit drains life and the last one pulls everyone toward the blade."]},
	"staff": {"name": ["Báculo del Alba", "Dawn Staff"], "sprite": "staff", "dmg": 11.0, "speed": 1.0, "range": 26.0,
		"arc": 90.0, "combo": 3, "stam": 8.0, "poise": 4.0, "fue": 0.0, "des": 0.2, "fe": 1.0, "ranged": true,
		"desc": ["Arma de apoyo: dispara orbes de luz. El ataque cargado crea un círculo que te cura a ti y a tu compañero; el último del combo estalla en una nova curativa.", "Support weapon: fires orbs of light. The charged attack creates a circle that heals you and your partner; the combo finisher bursts into a healing nova."]},
	"fists": {"name": ["Puños del Penitente", "Penitent's Fists"], "sprite": "fists", "dmg": 8.0, "speed": 1.75, "range": 22.0,
		"arc": 80.0, "combo": 5, "stam": 6.0, "poise": 11.0, "fue": 0.7, "des": 0.5, "fe": 0.0, "rapid": true,
		"desc": ["Ráfagas de cinco puñetazos que destrozan la postura. El quinto es un gancho que levanta al enemigo.", "Five-punch flurries that shred posture. The fifth is an uppercut that lifts the enemy."]},
	"verdugo": {"name": ["Hoja del Verdugo", "Executioner's Blade"], "sprite": "verdugo", "dmg": 23.0, "speed": 0.84, "range": 40.0,
		"arc": 165.0, "combo": 3, "stam": 15.0, "poise": 20.0, "fue": 0.8, "des": 0.1, "fe": 0.3, "sentence": true,
		"desc": ["La hoja que empuñaste antes de caer. Tajos anchos y pesados; el tercero, la Sentencia, lanza una media luna carmesí. +30% de daño a enemigos aturdidos y cada ejecución te devuelve un 20% de vida.", "The blade you wielded before the fall. Broad, heavy cuts; the third, the Sentence, hurls a crimson crescent. +30% damage to staggered foes and every execution restores 20% health."]},
	"bow": {"name": ["Arco de Pluma", "Feather Bow"], "sprite": "bow", "dmg": 12.0, "speed": 1.05, "range": 24.0,
		"arc": 60.0, "combo": 3, "stam": 7.0, "poise": 5.0, "fue": 0.1, "des": 0.9, "fe": 0.0, "ranged": true, "bow": true,
		"desc": ["Flechas de pluma a distancia; la tercera se abre en abanico. Cargado: una flecha que atraviesa a todos en línea.", "Feather arrows at range; the third fans out. Charged: an arrow that pierces everything in a line."]},
	# --- v0.9: armas de los Arcontes y del hierro de las celdas
	"mangual": {"name": ["Mangual del Carcelero", "Jailer's Flail"], "sprite": "mangual", "dmg": 21.0, "speed": 0.8, "range": 46.0,
		"arc": 200.0, "combo": 3, "stam": 15.0, "poise": 20.0, "fue": 0.9, "des": 0.2, "fe": 0.0,
		"desc": ["Una bola de hierro y una cadena. Barre a todo lo que tengas delante con mucho alcance.", "An iron ball on a chain. Sweeps everything in front of you with long reach."]},
	"yunque": {"name": ["Maza del Gran Yunque", "Great Anvil Mace"], "sprite": "yunque", "dmg": 30.0, "speed": 0.62, "range": 34.0,
		"arc": 150.0, "combo": 2, "stam": 21.0, "poise": 32.0, "fue": 1.1, "des": 0.0, "fe": 0.2, "burn": 0.25,
		"desc": ["Forjada por Vulkaris, sigue al rojo. Lenta y demoledora: cada golpe quema a quien lo recibe.", "Forged by Vulkaris and still white-hot. Slow and crushing: every hit burns its target."]},
	"astas": {"name": ["Astas de Orrun", "Orrun's Antlers"], "sprite": "astas", "dmg": 16.0, "speed": 1.15, "range": 48.0,
		"arc": 70.0, "combo": 4, "stam": 11.0, "poise": 11.0, "fue": 0.2, "des": 0.7, "fe": 0.3, "lunge": 1.6,
		"desc": ["Un glaive de hueso con fuego azul. Estocadas larguísimas que te lanzan hacia delante.", "A bone glaive with blue fire. Very long thrusts that carry you forward."]},
	"corona": {"name": ["Cetro del Rey Vacío", "Scepter of the Empty King"], "sprite": "corona", "dmg": 26.0, "speed": 0.95, "range": 40.0,
		"arc": 150.0, "combo": 3, "stam": 13.0, "poise": 18.0, "fue": 0.4, "des": 0.3, "fe": 0.9, "wave": true,
		"desc": ["La corona que nadie quiso, clavada en un asta. Quien la empuña manda... y paga por ello.", "The crown no one wanted, on a staff. Whoever wields it commands... and pays for it."]},
}

## Arte de arma: habilidad única de cada arma [V]. cd = segundos de recarga
const WEAPON_ARTS := {
	"sword": {"cd": 9.0, "name": ["Corte Lunar", "Lunar Cut"], "desc": ["Te lanzas atravesando a tus enemigos y remata una media luna a tu alrededor.", "You dash through your foes and finish with a crescent all around you."]},
	"spear": {"cd": 9.0, "name": ["Mil Estocadas", "Thousand Thrusts"], "desc": ["Seis estocadas relámpago en línea recta con un alcance enorme.", "Six lightning thrusts in a straight line with huge reach."]},
	"scythe": {"cd": 10.0, "name": ["Torbellino de Luz", "Whirl of Light"], "desc": ["Giras con las dos guadañas segando todo lo que haya alrededor.", "You spin with both scythes, reaping everything around you."]},
	"hammer": {"cd": 12.0, "name": ["Terremoto", "Earthquake"], "desc": ["Tres ondas sísmicas cada vez más grandes que rompen la postura.", "Three ever larger seismic waves that break posture."]},
	"choir": {"cd": 10.0, "name": ["Aria Hueca", "Hollow Aria"], "desc": ["Una nota imposible: dieciséis ondas en todas direcciones que frenan a quien tocan.", "An impossible note: sixteen waves in every direction that slow what they touch."]},
	"seravel": {"cd": 12.0, "name": ["Juicio de las Puertas", "Judgement of the Gates"], "desc": ["Cinco espadas de luz caen en línea delante de ti.", "Five swords of light fall in a line in front of you."]},
	"reaper": {"cd": 11.0, "name": ["La Cosecha", "The Harvest"], "desc": ["Un barrido total que atrae a todos hacia la hoja y te devuelve vida por cada uno.", "A total sweep that pulls everyone toward the blade and heals you for each."]},
	"staff": {"cd": 14.0, "name": ["Amanecer", "Daybreak"], "desc": ["Un sol estalla: círculo de curación enorme y doce orbes en todas direcciones.", "A sun bursts: a huge healing circle and twelve orbs in every direction."]},
	"fists": {"cd": 9.0, "name": ["Cien Puños", "Hundred Fists"], "desc": ["Una ráfaga imparable de diez puñetazos y un gancho final.", "An unstoppable barrage of ten punches and a final uppercut."]},
	"verdugo": {"cd": 12.0, "name": ["Sentencia Final", "Final Sentence"], "desc": ["Tres medias lunas carmesí que atraviesan todo.", "Three crimson crescents that pierce everything."]},
	"bow": {"cd": 11.0, "name": ["Lluvia de Plumas", "Feather Rain"], "desc": ["Una lluvia de flechas cae sobre la zona a la que apuntas.", "A rain of arrows falls on the area you aim at."]},
	"mangual": {"cd": 10.0, "name": ["Cadena Rota", "Broken Chain"], "desc": ["Haces girar la bola tres veces a tu alrededor y atraes a los enemigos.", "You whirl the ball around you three times and drag enemies in."]},
	"yunque": {"cd": 13.0, "name": ["Campanada del Yunque", "Anvil Toll"], "desc": ["Un único golpe que hace temblar la sala, quema y aturde a todos.", "A single blow that shakes the room, burning and stunning everyone."]},
	"astas": {"cd": 10.0, "name": ["Embestida del Ciervo", "Stag's Charge"], "desc": ["Cargas en línea recta dejando columnas de fuego azul a tu paso.", "You charge in a straight line, leaving pillars of blue fire behind."]},
	"corona": {"cd": 13.0, "name": ["Decreto Real", "Royal Decree"], "desc": ["Una orden que nadie puede desobedecer: daño enorme y rompe la postura de todos.", "An order no one can disobey: huge damage and breaks everyone's posture."]},
}
## Despertar del arma al llegar a +5: un poder propio que cambia cómo pelea
const WEAPON_AWAKE := {
	"sword": {"mods": {"wave": true}, "desc": ["El remate lanza una onda de luz.", "The finisher fires a wave of light."]},
	"spear": {"mods": {"range": 54.0}, "desc": ["Alcance mucho mayor.", "Much longer reach."]},
	"scythe": {"mods": {"bleed_ch": 0.7}, "desc": ["El sangrado de luz casi siempre se activa.", "Light-bleed triggers almost every time."]},
	"hammer": {"mods": {"arc": 180.0, "poise": 36.0}, "desc": ["Barridos más amplios y aún más castigo a la postura.", "Wider sweeps and even more posture damage."]},
	"choir": {"mods": {"notes_n": 5}, "desc": ["El remate lanza cinco notas.", "The finisher releases five notes."]},
	"seravel": {"mods": {"wave_mult": 1.6}, "desc": ["La onda de luz golpea un 60% más fuerte.", "The wave of light hits 60% harder."]},
	"reaper": {"mods": {"drain": 0.11}, "desc": ["Bebe casi el doble de vida.", "Drains almost twice the life."]},
	"staff": {"mods": {"orb_pierce": 2, "speed": 1.2}, "desc": ["Los orbes atraviesan y disparas más rápido.", "Orbs pierce and you fire faster."]},
	"fists": {"mods": {"combo": 6}, "desc": ["Ráfagas de seis golpes.", "Six-hit flurries."]},
	"verdugo": {"mods": {"sentence2": true}, "desc": ["La Sentencia lanza dos medias lunas.", "The Sentence hurls two crescents."]},
	"bow": {"mods": {"fan": 5}, "desc": ["El tercer disparo se abre en cinco flechas.", "The third shot fans into five arrows."]},
	"mangual": {"mods": {"pull": true}, "desc": ["El último golpe atrae a todos.", "The last hit pulls everyone in."]},
	"yunque": {"mods": {"burn": 0.45}, "desc": ["La quemadura casi se duplica.", "The burn nearly doubles."]},
	"astas": {"mods": {"drain": 0.04, "lunge": 2.2}, "desc": ["Estocadas aún más largas que roban vida.", "Even longer thrusts that steal life."]},
	"corona": {"mods": {"notes": true}, "desc": ["El remate lanza además notas que atraviesan.", "The finisher also releases piercing notes."]},
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
		"art": return flags.get("ab_art", false)
	return true

func grant_ability(id: String) -> void:
	if flags.get("ab_" + id, false):
		return
	flags["ab_" + id] = true
	reveal_ability(id)
	changed.emit()

## Datos del anuncio épico de cada habilidad
const ABILITY_INFO := {
	"lance": {"name": ["PLUMA DORADA", "GOLDEN FEATHER"], "key": "spell1", "icon": "icon_lance", "color": Color(1, 0.85, 0.4),
		"desc": ["Lanzas una pluma de oro que atraviesa a tus enemigos, se clava estallando en esquirlas y vuelve a tu mano.", "You hurl a golden feather that pierces your foes, bursts into shards and returns to your hand."]},
	"nova": {"name": ["NOVA DE CENIZA", "ASH NOVA"], "key": "spell2", "icon": "icon_nova", "color": Color(1, 0.6, 0.3),
		"desc": ["Una explosión de ceniza ardiente a tu alrededor.", "A burst of burning ash all around you."]},
	"wrath": {"name": ["IRA SERÁFICA", "SERAPHIC WRATH"], "key": "wrath", "icon": "icon_luz", "color": Color(1, 0.35, 0.35),
		"desc": ["Golpea y desvía para llenar el anillo de Ira. Cuando esté lleno, desata la furia de un serafín.", "Strike and parry to fill the Wrath ring. When full, unleash the fury of a seraph."]},
	"art": {"name": ["ARTE DE ARMA", "WEAPON ART"], "key": "art", "icon": "icon_filo", "color": Color(0.7, 0.9, 1.0),
		"desc": ["Cada arma guarda una técnica única. Úsala, espera a que se recargue y descubre la de todas.", "Every weapon holds a unique technique. Use it, wait for it to recharge and discover them all."]},
}
signal reveal_requested(title: String, desc: String, key: String, icon: String, color: Color, kind: String)

func reveal_ability(id: String) -> void:
	var a: Dictionary = ABILITY_INFO.get(id, {})
	if not a.is_empty():
		reveal_requested.emit(G.L(a.name), G.L(a.desc), G.key_label(a.key), a.icon, a.color, G.L(["NUEVA HABILIDAD", "NEW ABILITY"]))

# ------------------------------------------------------------------ armas: niveles y Artes
func weapon_tier(id: String) -> int:
	## 0: normal · 1: Arte afilada (+3) · 2: Despertada (+5) · 3: Ascendida (+10)
	var lv: int = weapons.get(id, 0)
	return 3 if lv >= 10 else (2 if lv >= 5 else (1 if lv >= 3 else 0))

func art_cooldown(id := "") -> float:
	if id == "":
		id = equipped
	var cd: float = WEAPON_ARTS.get(id, {"cd": 10.0}).cd
	return cd * (0.8 if weapon_tier(id) >= 1 else 1.0)

func art_power(id := "") -> float:
	if id == "":
		id = equipped
	return 1.0 + 0.1 * int(weapons.get(id, 0)) + (0.4 if weapon_tier(id) >= 3 else 0.0)

# ------------------------------------------------------------------ Resonancia: racha de bajas sin recibir golpes = más Ecos
var resonance := 0
var res_t := 0.0

func resonance_max() -> int:
	return 8 if has_skill("p4") else 5

func resonance_mult() -> float:
	return 1.0 + 0.1 * resonance

func resonance_add() -> void:
	resonance = mini(resonance + 1, resonance_max())
	res_t = 22.0 if has_skill("p4") else 15.0

func resonance_break() -> void:
	resonance = 0
	res_t = 0.0

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

const BESTIARY := ["hueco", "acolito", "planidera", "penitente", "bestia", "guardia", "custodio",
	"musgoso", "nidal", "espino", "garza", "lacrima", "ascua", "fundidor", "chispero", "forjador", "kronagh",
	"cortesano", "caballero", "doncella", "sabueso", "ysolde"]
func record_kill(etype: String) -> void:
	Ach.add("kills")
	resonance_add()
	if etype in BESTIARY:
		flags["slain_" + etype] = true
		var n := 0
		for b in BESTIARY:
			if flags.get("slain_" + b, false):
				n += 1
		Ach.set_max("bestiary", n)
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
		Ach.unlock("synergy")
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
	for b2 in ["orrun", "vulkaris"]:
		if flags.get(b2 + "_dead", false):
			sc += 2 if spared.has(b2) else -1
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
	Ach.unlock("ng")
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
	# --- Filo: ampliación
	"f7": {"branch": "filo", "pos": Vector2i(0, 3), "cost": 2, "req": ["f4"], "name": ["Doble Filo", "Double Edge"], "desc": ["+8% de probabilidad de crítico.", "+8% critical chance."]},
	"f8": {"branch": "filo", "pos": Vector2i(4, 3), "cost": 2, "req": ["f5"], "name": ["Romper Guardia", "Guard Breaker"], "desc": ["+25% de daño a la postura.", "+25% posture damage."]},
	"f9": {"branch": "filo", "pos": Vector2i(0, 4), "cost": 3, "req": ["f7"], "name": ["Golpe Maestro", "Master Stroke"], "desc": ["Tus críticos hacen x2,3 en lugar de x1,8.", "Your criticals deal x2.3 instead of x1.8."]},
	"f10": {"branch": "filo", "pos": Vector2i(4, 4), "cost": 3, "req": ["f8"], "name": ["Hoja Cantora", "Singing Blade"], "desc": ["Cada quinto golpe que aciertas lanza una onda cortante.", "Every fifth hit you land fires a cutting wave."]},
	"f11": {"branch": "filo", "pos": Vector2i(1, 4), "cost": 2, "req": ["f6"], "excl": "f12", "name": ["Furia", "Fury"], "desc": ["ELIGE UNA: con menos de un 35% de vida, +30% de daño.", "CHOOSE ONE: below 35% health, +30% damage."]},
	"f12": {"branch": "filo", "pos": Vector2i(3, 4), "cost": 2, "req": ["f6"], "excl": "f11", "name": ["Templanza", "Temperance"], "desc": ["ELIGE UNA: con más de un 80% de vida, +18% de daño.", "CHOOSE ONE: above 80% health, +18% damage."]},
	"f13": {"branch": "filo", "pos": Vector2i(2, 5), "cost": 4, "req": ["f9", "f10"], "any": ["f11", "f12"], "cap": true, "name": ["ESTIGMA: Mil Cortes", "STIGMA: Thousand Cuts"], "desc": ["Tras cada remate, el aire se abre en un segundo tajo que golpea a todos alrededor.", "After each finisher, the air splits in a second slash that strikes everyone around."]},
	# --- Ala: ampliación
	"a7": {"branch": "ala", "pos": Vector2i(0, 3), "cost": 2, "req": ["a4"], "name": ["Segundo Aire", "Second Wind"], "desc": ["La esquiva perfecta rellena tu aguante y tus esquivas.", "A perfect dodge refills your stamina and dashes."]},
	"a8": {"branch": "ala", "pos": Vector2i(4, 3), "cost": 2, "req": ["a5"], "name": ["Danza", "Dance"], "desc": ["Durante 2 s tras esquivar, atacas un 20% más rápido.", "For 2 s after a dash, you attack 20% faster."]},
	"a9": {"branch": "ala", "pos": Vector2i(0, 4), "cost": 3, "req": ["a7"], "name": ["Tercer Ala", "Third Wing"], "desc": ["Puedes encadenar tres esquivas.", "You can chain three dashes."]},
	"a10": {"branch": "ala", "pos": Vector2i(4, 4), "cost": 3, "req": ["a8"], "name": ["Golpe Alado", "Winged Strike"], "desc": ["Atacar justo después de esquivar hace +35% de daño.", "Attacking right after a dash deals +35% damage."]},
	"a11": {"branch": "ala", "pos": Vector2i(1, 4), "cost": 2, "req": ["a6"], "excl": "a12", "name": ["Plumaje Pesado", "Heavy Plumage"], "desc": ["ELIGE UNA: -8% de velocidad y -12% de daño recibido.", "CHOOSE ONE: -8% speed and -12% damage taken."]},
	"a12": {"branch": "ala", "pos": Vector2i(3, 4), "cost": 2, "req": ["a6"], "excl": "a11", "name": ["Plumaje Ligero", "Light Plumage"], "desc": ["ELIGE UNA: +8% de velocidad y esquivar cuesta un 20% menos.", "CHOOSE ONE: +8% speed and dashing costs 20% less."]},
	"a13": {"branch": "ala", "pos": Vector2i(2, 5), "cost": 4, "req": ["a9", "a10"], "any": ["a11", "a12"], "cap": true, "name": ["ESTIGMA: Vuelo del Serafín", "STIGMA: Seraph's Flight"], "desc": ["Las esquivas se recargan un 40% antes y cada esquiva perfecta dispara una corona de plumas.", "Dashes recharge 40% sooner and every perfect dodge fires a crown of feathers."]},
	# --- Luz: ampliación
	"l7": {"branch": "luz", "pos": Vector2i(0, 3), "cost": 2, "req": ["l4"], "name": ["Pluma Certera", "True Feather"], "desc": ["La Pluma Dorada atraviesa a dos enemigos más y busca mejor a sus objetivos.", "The Golden Feather pierces two more enemies and seeks targets better."]},
	"l8": {"branch": "luz", "pos": Vector2i(4, 3), "cost": 2, "req": ["l5"], "name": ["Reserva de Luz", "Light Reserve"], "desc": ["+25 de Luz máxima.", "+25 max Light."]},
	"l9": {"branch": "luz", "pos": Vector2i(0, 4), "cost": 3, "req": ["l7"], "name": ["Nova Cicatrizante", "Healing Nova"], "desc": ["La Nova te cura un 8% de tu vida.", "The Nova heals you for 8% of your health."]},
	"l10": {"branch": "luz", "pos": Vector2i(4, 4), "cost": 3, "req": ["l8"], "name": ["Sobrecarga", "Overcharge"], "desc": ["Cada baja te devuelve 6 de Luz.", "Every kill restores 6 Light."]},
	"l11": {"branch": "luz", "pos": Vector2i(1, 4), "cost": 2, "req": ["l6"], "excl": "l12", "name": ["Sol Negro", "Black Sun"], "desc": ["ELIGE UNA: los hechizos dañan un 30% más y cuestan un 20% más.", "CHOOSE ONE: spells deal 30% more and cost 20% more."]},
	"l12": {"branch": "luz", "pos": Vector2i(3, 4), "cost": 2, "req": ["l6"], "excl": "l11", "name": ["Alba Serena", "Serene Dawn"], "desc": ["ELIGE UNA: los hechizos cuestan un 25% menos.", "CHOOSE ONE: spells cost 25% less."]},
	"l13": {"branch": "luz", "pos": Vector2i(2, 5), "cost": 4, "req": ["l9", "l10"], "any": ["l11", "l12"], "cap": true, "name": ["ESTIGMA: Coro de Plumas", "STIGMA: Feather Choir"], "desc": ["Tras lanzar la Pluma Dorada, otras dos salen solas hacia los enemigos más cercanos.", "After casting the Golden Feather, two more fly by themselves at the nearest enemies."]},
	# --- Ceniza: ampliación
	"c7": {"branch": "ceniza", "pos": Vector2i(0, 3), "cost": 2, "req": ["c4"], "name": ["Cadena de Parries", "Parry Chain"], "desc": ["Cada parry perfecto seguido aumenta un 15% el daño de tu réplica y llena más Ira.", "Each perfect parry in a row raises your riposte's damage by 15% and builds more Wrath."]},
	"c8": {"branch": "ceniza", "pos": Vector2i(4, 3), "cost": 2, "req": ["c5"], "name": ["Manto de Ceniza", "Ash Mantle"], "desc": ["+15% de vida máxima.", "+15% max health."]},
	"c9": {"branch": "ceniza", "pos": Vector2i(0, 4), "cost": 3, "req": ["c7"], "name": ["Lágrima Potente", "Potent Tear"], "desc": ["Las Lágrimas curan un 12% más de tu vida.", "Tears heal 12% more of your health."]},
	"c10": {"branch": "ceniza", "pos": Vector2i(4, 4), "cost": 3, "req": ["c8"], "name": ["Ceniza Viva", "Living Ash"], "desc": ["Regeneras vida poco a poco si llevas 6 s sin recibir golpes.", "Slowly regenerate health after 6 s without being hit."]},
	"c11": {"branch": "ceniza", "pos": Vector2i(1, 4), "cost": 2, "req": ["c6"], "excl": "c12", "name": ["Espinas", "Thorns"], "desc": ["ELIGE UNA: quien te golpee de cerca recibe un 30% del daño.", "CHOOSE ONE: whoever hits you up close takes 30% of the damage."]},
	"c12": {"branch": "ceniza", "pos": Vector2i(3, 4), "cost": 2, "req": ["c6"], "excl": "c11", "name": ["Égida", "Aegis"], "desc": ["ELIGE UNA: tras 10 s sin recibir golpes, el siguiente hace la mitad.", "CHOOSE ONE: after 10 s unhit, the next blow deals half."]},
	"c13": {"branch": "ceniza", "pos": Vector2i(2, 5), "cost": 4, "req": ["c9", "c10"], "any": ["c11", "c12"], "cap": true, "name": ["ESTIGMA: Fénix de Ceniza", "STIGMA: Ash Phoenix"], "desc": ["Una vez por descanso, al caer renaces con la mitad de tu vida en una explosión.", "Once per rest, when you fall you are reborn at half health in an explosion."]},
	# --- Pluma: la rama de tus alas
	"p1": {"branch": "pluma", "pos": Vector2i(2, 0), "cost": 1, "req": [], "name": ["Pluma Afilada", "Sharpened Feather"], "desc": ["Con 7 plumas o menos, +10% de daño.", "With 7 feathers or fewer, +10% damage."]},
	"p2": {"branch": "pluma", "pos": Vector2i(1, 1), "cost": 1, "req": ["p1"], "name": ["Plumón Protector", "Guarding Down"], "desc": ["Con 7 plumas o más, -10% de daño recibido.", "With 7 feathers or more, -10% damage taken."]},
	"p3": {"branch": "pluma", "pos": Vector2i(3, 1), "cost": 1, "req": ["p1"], "name": ["Recolector", "Gatherer"], "desc": ["+20% de Ecos.", "+20% Echoes."]},
	"p4": {"branch": "pluma", "pos": Vector2i(3, 2), "cost": 2, "req": ["p3"], "name": ["Resonancia Alta", "High Resonance"], "desc": ["La Resonancia sube hasta x1,8 y tarda más en apagarse.", "Resonance rises to x1.8 and takes longer to fade."]},
	"p5": {"branch": "pluma", "pos": Vector2i(1, 2), "cost": 2, "req": ["p2"], "name": ["Lluvia de Plumas", "Feather Shower"], "desc": ["El ataque cargado lanza un abanico de plumas.", "The heavy attack throws a fan of feathers."]},
	"p6": {"branch": "pluma", "pos": Vector2i(0, 3), "cost": 2, "req": ["p5"], "name": ["Ala Rota", "Broken Wing"], "desc": ["Perder plumas te quita la mitad de vida máxima que antes.", "Losing feathers costs half as much max health."]},
	"p7": {"branch": "pluma", "pos": Vector2i(4, 3), "cost": 2, "req": ["p4"], "name": ["Ofrenda", "Offering"], "desc": ["Cada Brasa que enciendes te recompensa con 400 Ecos.", "Each Ember you kindle rewards you with 400 Echoes."]},
	"p8": {"branch": "pluma", "pos": Vector2i(2, 4), "cost": 4, "req": ["p6", "p7"], "cap": true, "name": ["ESTIGMA: El Desplumado", "STIGMA: The Featherless"], "desc": ["Cada pluma que te falta da +2% de crítico. Con 3 o menos, además robas vida.", "Each missing feather grants +2% crit. With 3 or fewer, you also steal life."]},
	# --- Arconte: un poder por cada caído
	"k1": {"branch": "arconte", "pos": Vector2i(1, 2), "cost": 2, "req": [], "archon": "seravel", "name": ["Espadas Orbitantes", "Orbiting Blades"], "desc": ["Poder de Seravel: tres espadas de luz giran a tu alrededor.", "Seravel's power: three blades of light orbit you."]},
	"k2": {"branch": "arconte", "pos": Vector2i(1, 0), "cost": 1, "req": [], "archon": "carcelero", "name": ["Cadenas del Carcelero", "Jailer's Chains"], "desc": ["Poder del Carcelero: el parry perfecto golpea la postura de quien esté cerca.", "The Jailer's power: a perfect parry strikes the posture of those nearby."]},
	"k3": {"branch": "arconte", "pos": Vector2i(3, 0), "cost": 1, "req": [], "archon": "choir", "name": ["Voz del Coro", "Voice of the Choir"], "desc": ["Poder del Coro: la Pluma Dorada y la Nova frenan a sus objetivos.", "The Choir's power: the Golden Feather and Nova slow their targets."]},
	"k4": {"branch": "arconte", "pos": Vector2i(3, 2), "cost": 2, "req": [], "archon": "orrun", "name": ["Astas de Orrun", "Orrun's Antlers"], "desc": ["Poder de Orrun: tus esquivas embisten y dañan a quien atraviesas.", "Orrun's power: your dashes ram and hurt whoever you pass through."]},
	"k5": {"branch": "arconte", "pos": Vector2i(1, 4), "cost": 3, "req": [], "archon": "vulkaris", "name": ["Yunque de Vulkaris", "Vulkaris's Anvil"], "desc": ["Poder de Vulkaris: todos tus golpes queman.", "Vulkaris's power: all your blows burn."]},
	"k6": {"branch": "arconte", "pos": Vector2i(3, 4), "cost": 4, "req": [], "archon": "azrahel", "name": ["Decreto de Azrahel", "Azrahel's Decree"], "desc": ["Poder de Azrahel: la Ira se llena antes y desatarla te cura un 30%.", "Azrahel's power: Wrath fills faster and unleashing it heals you 30%."]},
}
const BRANCHES := {
	"filo": {"name": ["Filo", "Edge"], "icon": "filo", "color": Color(1.0, 0.45, 0.4)},
	"ala": {"name": ["Ala", "Wing"], "icon": "ala", "color": Color(0.6, 0.85, 1.0)},
	"luz": {"name": ["Luz", "Light"], "icon": "luz", "color": Color(1.0, 0.9, 0.5)},
	"ceniza": {"name": ["Ceniza", "Ash"], "icon": "ceniza", "color": Color(0.85, 0.6, 0.4)},
	"pluma": {"name": ["Pluma", "Feather"], "icon": "feather", "color": Color(1.0, 0.82, 0.92)},
	"arconte": {"name": ["Arconte", "Archon"], "icon": "arconte", "color": Color(1.0, 0.35, 0.45)},
}
## Lema de cada rama (cabecera del árbol) y bonus de maestría por cada 4 nodos
const BRANCH_INFO := {
	"filo": {"motto": ["Golpear primero. Golpear último.", "Strike first. Strike last."], "bonus": ["+4% de daño", "+4% damage"]},
	"ala": {"motto": ["Lo que no te toca no te mata.", "What can't touch you can't kill you."], "bonus": ["+3% de velocidad", "+3% speed"]},
	"luz": {"motto": ["Arde la vela que te guía.", "The candle that guides you burns."], "bonus": ["+6% de daño de hechizos", "+6% spell damage"]},
	"ceniza": {"motto": ["Caer es la primera lección.", "Falling is the first lesson."], "bonus": ["+5% de vida máxima", "+5% max health"]},
	"pluma": {"motto": ["Cada pluma que pierdes te enseña algo.", "Every feather you lose teaches you something."], "bonus": ["+5% de Ecos", "+5% Echoes"]},
	"arconte": {"motto": ["Lo que les arrancas, lo llevas contigo.", "What you tear from them, you carry with you."], "bonus": ["-", "-"]},
}

func branch_count(b: String) -> int:
	var n := 0
	for id in skills:
		if SKILLS.has(id) and SKILLS[id].branch == b:
			n += 1
	return n

func mastery(b: String) -> int:
	return mini(branch_count(b) / 4, 3)

func respec_cost() -> int:
	return 150 + 40 * skills.size()

func respec() -> bool:
	var c := respec_cost()
	if ecos < c or skills.is_empty():
		return false
	ecos -= c
	for id in skills:
		if SKILLS.has(id):
			skill_points += int(SKILLS[id].cost)
	skills = {}
	changed.emit()
	return true

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
	"main2": {"type": "main", "title": ["El Bosque de Plumas Muertas", "The Forest of Dead Feathers"], "giver": "",
		"steps": [
			{"id": "talk_oso", "text": ["Busca a alguien en el Claro de los Nidos, al oeste del sendero", "Find someone in the Clearing of Nests, west of the path"]},
			{"id": "enter_ciervo", "text": ["Cruza la Arboleda Hueca hasta el Santuario del Ciervo", "Cross the Hollow Grove to the Stag's Sanctuary"]},
			{"id": "kill_orrun", "text": ["Derrota a Orrun, el Ciervo Hueco", "Defeat Orrun, the Hollow Stag"]},
		],
		"reward": {"ecos": 0, "sp": 1}},
	"main3": {"type": "main", "title": ["La Fundición de Halos", "The Halo Foundry"], "giver": "",
		"steps": [
			{"id": "talk_archivero", "text": ["Busca la Biblioteca de los Nombres, al oeste de los crisoles", "Find the Library of Names, west of the crucibles"]},
			{"id": "enter_yunque", "text": ["Sube por la Gran Fragua hasta el Gran Yunque", "Climb through the Great Forge to the Great Anvil"]},
			{"id": "kill_vulkaris", "text": ["Derrota a Vulkaris, el Herrero de Aureolas", "Defeat Vulkaris, the Halo Smith"]},
		],
		"reward": {"ecos": 0, "sp": 1}},
	"main4": {"type": "main", "title": ["El Trono Vacío", "The Empty Throne"], "giver": "",
		"steps": [
			{"id": "talk_lirio", "text": ["Habla con quien cuida el Jardín de Espinas Doradas", "Speak with whoever tends the Garden of Golden Thorns"]},
			{"id": "enter_trono", "text": ["Sube la Escalinata del Rey hasta el Trono Vacío", "Climb the King's Stairway to the Empty Throne"]},
			{"id": "kill_azrahel", "text": ["Derrota a Azrahel, Rey del Abismo", "Defeat Azrahel, King of the Abyss"]},
		],
		"reward": {"ecos": 0, "sp": 2}},
	"eggs": {"type": "side", "title": ["Huevos de Luz", "Eggs of Light"], "giver": "oso",
		"count": 3, "text": ["Encuentra los huevos de luz del bosque (%d/%d)", "Find the forest's eggs of light (%d/%d)"],
		"reward": {"ecos": 1500, "sp": 2, "flask": 1}},
	"names": {"type": "side", "title": ["Nombres Perdidos", "Lost Names"], "giver": "archivero",
		"count": 3, "text": ["Recupera las placas con nombres de la Fundición (%d/%d)", "Recover the name plates of the Foundry (%d/%d)"],
		"reward": {"ecos": 2200, "sp": 2, "item": "phoenix"}},
	"roses": {"type": "side", "title": ["Rosas Vivas", "Living Roses"], "giver": "lirio",
		"count": 3, "text": ["Encuentra las rosas que huelen (%d/%d)", "Find the roses that smell (%d/%d)"],
		"reward": {"ecos": 3000, "sp": 3, "flask": 1}},
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

func achieve(id: String) -> void:
	## los logros ahora son del perfil (autoload Ach); la partida solo recuerda que ya saltaron
	flags["ach_" + id] = true
	Ach.unlock(id)

func achievements_count() -> int:
	return Ach.count("base")[0]
var synergies := {}             # sinergias descubiertas
var ng := 0                     # Segundo Descenso (NG+)
var spark := false              # Chispa, la brasa viva
var event_ecos := 1.0           # multiplicador de los eventos del mundo (no se guarda)
var infusions := {}            # arma -> grabado
var flask_level := 0           # potencia de las Lágrimas (Madre Ilse)
var shop_bought := {}          # objeto -> comprados
var ascension := {}            # jefe -> nivel máximo superado
var tracked := ""              # misión que se sigue en pantalla

func _process(delta: float) -> void:
	playtime += delta
	if res_t > 0.0:
		res_t -= delta
		if res_t <= 0.0:
			resonance = 0
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
	resonance = 0; res_t = 0.0; tracked = ""
	changed.emit()

# ------------------------------------------------------------------ estadísticas derivadas
func has_skill(id: String) -> bool:
	return skills.has(id)

func max_hp() -> float:
	var hp = (100.0 + (attr.vigor - 1) * 14.0) * (1.0 - (0.15 if has_skill("p6") else 0.3) * desplume())
	hp *= (1.15 if has_skill("c8") else 1.0) * (1.0 + 0.05 * mastery("ceniza"))
	if oath == "choir":
		hp *= 0.85
	if flags.get("colossus_heart", false):
		hp *= 1.15
	return hp

func diff() -> Dictionary:
	return DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]

func infusion(wid := "") -> String:
	if wid == "":
		wid = equipped
	return infusions.get(wid, "")

func heal_ratio() -> float:
	return 0.45 + 0.07 * flask_level + (0.12 if has_skill("c9") else 0.0)

func spell_cost_mult() -> float:
	return (0.75 if has_amulet("choir_heart") else 1.0) * (0.7 if oath == "choir" else 1.0) * (1.2 if has_skill("l11") else 1.0) * (0.75 if has_skill("l12") else 1.0)

func has_amulet(id: String) -> bool:
	return id in amulets_eq

func stamina_regen_mult() -> float:
	return (1.3 if has_amulet("amulet_wing") else 1.0) * (0.75 if oath == "seravel" else 1.0) * (2.0 if buffs.has("vial_aliento") else 1.0)

func buff_damage_mult() -> float:
	return (1.3 if buffs.has("incense") else 1.0) * (1.2 if buffs.has("united") else 1.0)

func max_stamina() -> float:
	return 100.0 + (attr.aguante - 1) * 7.0

func max_light() -> float:
	return 60.0 + (attr.fe - 1) * 6.0 + (25.0 if has_skill("l8") else 0.0)

func move_speed() -> float:
	return 118.0 * (1.12 if has_skill("a5") else 1.0) * (1.0 + 0.15 * desplume()) * (0.92 if oath == "carcelero" else 1.0) * (0.92 if has_skill("a11") else 1.0) * (1.08 if has_skill("a12") else 1.0) * (1.0 + 0.03 * mastery("ala"))

func flask_count() -> int:
	return flasks_max + (1 if has_skill("c3") else 0)

func weapon_data(id := "") -> Dictionary:
	if id == "":
		id = equipped
	var w: Dictionary = WEAPONS.get(id, WEAPONS["sword"])
	# al llegar a +5 el arma despierta: su poder propio cambia cómo pelea
	if int(weapons.get(id, 0)) >= 5 and WEAPON_AWAKE.has(id):
		return w.merged(WEAPON_AWAKE[id].mods, true)
	return w

func dash_max() -> int:
	return 3 if has_skill("a9") else (2 if has_skill("a2") else 1)

func weapon_damage(id := "") -> float:
	if id == "":
		id = equipped
	var w := weapon_data(id)
	var up: int = weapons.get(id, 0)
	var fe_s: float = w.fe + (0.6 if infusion(id) == "nimbo" else 0.0)
	var scale: float = 1.0 + 0.045 * ((attr.fuerza - 1) * w.fue + (attr.destreza - 1) * w.des + (attr.fe - 1) * fe_s)
	var dmg: float = w.dmg * scale * (1.0 + 0.09 * up) * (1.2 if up >= 10 else 1.0)
	if has_skill("f1"):
		dmg *= 1.12
	dmg *= 1.0 + 0.04 * mastery("filo")
	if has_skill("p1") and wing_feathers <= 7:
		dmg *= 1.1
	dmg *= 1.0 + 0.3 * desplume() + (0.1 if is_desplumado() else 0.0)
	if oath == "carcelero":
		dmg *= 1.1
	return dmg * buff_damage_mult()

func spell_damage(base: float) -> float:
	return base * (1.0 + 0.06 * (attr.fe - 1)) * (1.25 if has_skill("l1") else 1.0) * buff_damage_mult() * (1.2 if oath == "choir" else 1.0) * (1.3 if has_skill("l11") else 1.0) * (1.0 + 0.06 * mastery("luz"))

func crit_chance() -> float:
	return 0.05 + 0.012 * (attr.destreza - 1) + (0.1 if has_amulet("amulet_eye") else 0.0) + (0.08 if has_skill("f7") else 0.0) + (0.02 * (WING_MAX - wing_feathers) if has_skill("p8") else 0.0)

func damage_taken_mult() -> float:
	return (0.88 if has_skill("c2") else 1.0) * (0.65 if buffs.has("ointment") else 1.0) * (0.88 if has_skill("a11") else 1.0) * (0.9 if has_skill("p2") and wing_feathers >= 7 else 1.0)

func ecos_mult() -> float:
	return (1.0 + 0.03 * (attr.arcano - 1)) * diff().ecos * event_ecos * (1.0 + 0.25 * ng) * resonance_mult() * (1.2 if has_skill("p3") else 1.0) * (1.0 + 0.05 * mastery("pluma"))

func level_cost() -> int:
	return int(90 + 55 * level + 6 * level * level)

func upgrade_cost(id: String) -> Array:
	var lv: int = weapons.get(id, 0)
	# [ecos, fragmentos, esquirlas de nimbo, lágrimas]: despertar (+5) y ascender (+10) piden una Lágrima
	return [180 * (lv + 1) + 40 * lv * lv, lv + 1, 1 if lv >= 3 else 0, 1 if lv == 4 or lv == 9 else 0]

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
	Ach.set_max("level", level)
	changed.emit()
	return true

func can_unlock(id: String) -> bool:
	if has_skill(id):
		return false
	var s: Dictionary = SKILLS[id]
	if s.has("archon") and not flags.get(s.archon + "_dead", false):
		return false
	if s.has("excl") and has_skill(s.excl):
		return false
	for r in s.req:
		if not has_skill(r):
			return false
	if s.has("any"):
		var ok := false
		for r2 in s.any:
			if has_skill(r2):
				ok = true
		if not ok:
			return false
	return skill_points >= s.cost

func unlock(id: String) -> bool:
	if not can_unlock(id):
		return false
	skill_points -= SKILLS[id].cost
	skills[id] = true
	if id == "l2":
		reveal_ability("nova")
	elif SKILLS[id].get("cap", false):
		reveal_requested.emit(G.L(SKILLS[id].name), G.L(SKILLS[id].desc), "", "icon_" + BRANCHES[SKILLS[id].branch].icon, BRANCHES[SKILLS[id].branch].color, G.L(["ESTIGMA GRABADO", "STIGMA ENGRAVED"]))
	changed.emit()
	return true

func add_weapon(id: String) -> void:
	if not weapons.has(id):
		weapons[id] = 0
		Ach.set_max("weapons", weapons.size())
		reveal_requested.emit(G.L(WEAPONS[id].name).to_upper(), G.L(WEAPONS[id].desc), "", "weapon_" + WEAPONS[id].sprite, Color(1, 0.8, 0.4), G.L(["NUEVA ARMA", "NEW WEAPON"]))
	changed.emit()

func upgrade_weapon(id: String) -> bool:
	var lv: int = weapons.get(id, 0)
	if lv >= 10:
		return false
	if free_upgrades > 0:
		free_upgrades -= 1
	else:
		var c := upgrade_cost(id)
		if ecos < c[0] or feathers < c[1] or item_count("iron") < c[2] or item_count("tear") < c[3]:
			return false
		ecos -= c[0]
		feathers -= c[1]
		if c[2] > 0:
			remove_item("iron", c[2])
		if c[3] > 0:
			remove_item("tear", c[3])
	weapons[id] = lv + 1
	Ach.set_max("upgrade", lv + 1)
	if lv + 1 == 5:
		reveal_requested.emit(G.L(WEAPONS[id].name).to_upper(), G.L(WEAPON_AWAKE[id].desc), "", "weapon_" + WEAPONS[id].sprite, Color(1, 0.8, 0.4), G.L(["ARMA DESPERTADA", "WEAPON AWAKENED"]))
	elif lv + 1 == 10:
		reveal_requested.emit(G.L(WEAPONS[id].name).to_upper(), G.L(["+20% de daño y su Arte alcanza todo su poder.", "+20% damage and its Art reaches full power."]), "", "weapon_" + WEAPONS[id].sprite, Color(1, 0.55, 0.9), G.L(["ARMA ASCENDIDA", "WEAPON ASCENDED"]))
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
	Ach.unlock("engrave")
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
	if level >= 3:
		Ach.unlock("ascension")
	if first:
		var r: Dictionary = ASCENSION_REWARDS[level]
		ecos += r.ecos
		for k in r:
			if k != "ecos":
				add_item(k, r[k])
	changed.emit()

func unlock_memory(id: String) -> bool:
	if memories.has(id):
		return false
	memories[id] = true
	Ach.set_max("memories", memories.size())
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
		if id == "main1":
			Ach.set_max("main_steps", found + 1)
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
	if id == "hymns":
		Ach.set_max("pages", quests[id].progress)
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
	if id == "eggs":
		achieve("oso_eggs")
	if id == "names":
		achieve("names")
	if id == "roses":
		achieve("roses")
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
		"weapon_kills": weapon_kills, "oath": oath, "spared": spared, "synergies": synergies, "ng": ng, "spark": spark, "look": G.look, "tracked": tracked}

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
	tracked = str(d.get("tracked", ""))
	if not weapons.has(equipped):
		equipped = "sword"
	if quests.has("feathers"):
		flags["ab_art"] = true  # partidas antiguas: ya hablaste con Brenna
	infusions = d.get("infusions", {})
	flask_level = int(d.get("flask_level", 0))
	shop_bought = d.get("shop_bought", {})
	ascension = {}
	var asc: Dictionary = d.get("ascension", {})
	for k in asc:
		ascension[k] = int(asc[k])
	changed.emit()

func save_game() -> void:
	var f := FileAccess.open(save_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "\t"))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(save_path())

## Lee la partida guardada sin cargarla (para la ficha de "Continuar" en la pantalla de inicio)
func peek_save() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(save_path(), FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else {}

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(save_path(), FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		from_dict(data)
		# partidas antiguas: sus logros pasan al perfil sin avisos
		var legacy := []
		for k in flags:
			if str(k).begins_with("ach_"):
				legacy.append(str(k).substr(4))
		Ach.import_legacy(legacy)
		return true
	return false

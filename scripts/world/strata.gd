class_name Strata
extends RefCounted
## ESTRATOS II, III y IV del juego base (el I vive en world.gd).
## Cada estrato ocupa su propia franja del mapa (x 100-190, 196-286 y 292-382) y se llega a él por la
## Grieta del Descenso que se abre al vencer al Arconte del estrato anterior.

# ------------------------------------------------------------------ salas
const ROOMS := [
	# --- Estrato II: Bosque de Plumas Muertas
	{"id": "b_llegada", "rect": Rect2i(136, 78, 16, 12)},
	{"id": "b_link1", "rect": Rect2i(142, 70, 4, 8)},
	{"id": "b_sendero", "rect": Rect2i(126, 56, 30, 14)},
	{"id": "b_link2", "rect": Rect2i(118, 60, 8, 4)},
	{"id": "b_nidos", "rect": Rect2i(104, 54, 14, 14)},
	{"id": "b_link3", "rect": Rect2i(156, 61, 8, 4)},
	{"id": "b_cienaga", "rect": Rect2i(164, 52, 20, 16)},
	{"id": "b_link4", "rect": Rect2i(138, 46, 4, 10)},
	{"id": "b_arboleda", "rect": Rect2i(124, 30, 34, 16)},
	{"id": "b_link5", "rect": Rect2i(118, 36, 6, 4)},
	{"id": "b_madriguera", "rect": Rect2i(104, 30, 14, 12)},
	{"id": "b_link6", "rect": Rect2i(139, 18, 4, 12)},
	{"id": "b_arena", "c": Vector2i(141, 10), "r": 8},
	# --- Estrato III: Fundición de Halos
	{"id": "f_llegada", "rect": Rect2i(232, 78, 16, 12)},
	{"id": "f_link1", "rect": Rect2i(238, 66, 4, 12)},
	{"id": "f_crisoles", "rect": Rect2i(220, 52, 40, 14)},
	{"id": "f_link2", "rect": Rect2i(212, 56, 8, 4)},
	{"id": "f_biblio", "rect": Rect2i(198, 48, 14, 14)},
	{"id": "f_link3", "rect": Rect2i(260, 57, 8, 4)},
	{"id": "f_moldes", "rect": Rect2i(268, 46, 16, 20)},
	{"id": "f_link4", "rect": Rect2i(238, 40, 4, 12)},
	{"id": "f_fragua", "rect": Rect2i(222, 26, 36, 14)},
	{"id": "f_link5", "rect": Rect2i(214, 30, 8, 4)},
	{"id": "f_archivo", "rect": Rect2i(200, 24, 14, 14)},
	{"id": "f_link6", "rect": Rect2i(238, 18, 4, 8)},
	{"id": "f_arena", "c": Vector2i(240, 10), "r": 8},
	# --- Estrato IV: El Trono Vacío
	{"id": "t_llegada", "rect": Rect2i(328, 80, 16, 10)},
	{"id": "t_link1", "rect": Rect2i(334, 68, 4, 12)},
	{"id": "t_jardin", "rect": Rect2i(318, 54, 36, 14)},
	{"id": "t_link2", "rect": Rect2i(310, 58, 8, 4)},
	{"id": "t_corte", "rect": Rect2i(294, 44, 16, 22)},
	{"id": "t_link3", "rect": Rect2i(354, 58, 8, 4)},
	{"id": "t_galeria", "rect": Rect2i(362, 46, 18, 20)},
	{"id": "t_link4", "rect": Rect2i(334, 40, 4, 14)},
	{"id": "t_escalera", "rect": Rect2i(322, 30, 30, 10)},
	{"id": "t_link5", "rect": Rect2i(334, 21, 4, 9)},
	{"id": "t_arena", "c": Vector2i(336, 11), "r": 10},
]

const AREAS := {
	"b_llegada": "area_bosque", "b_link1": "area_bosque", "b_sendero": "area_bosque", "b_link4": "area_bosque", "b_arboleda": "area_bosque",
	"b_link6": "area_bosque", "b_link2": "area_nidos", "b_nidos": "area_nidos", "b_link3": "area_cienaga", "b_cienaga": "area_cienaga",
	"b_link5": "area_madriguera", "b_madriguera": "area_madriguera", "b_arena": "area_ciervo",
	"f_llegada": "area_fundicion", "f_link1": "area_fundicion", "f_crisoles": "area_fundicion", "f_link4": "area_fundicion", "f_fragua": "area_fundicion",
	"f_link6": "area_fundicion", "f_link2": "area_biblio", "f_biblio": "area_biblio", "f_link3": "area_moldes", "f_moldes": "area_moldes",
	"f_link5": "area_archivo", "f_archivo": "area_archivo", "f_arena": "area_yunque",
	"t_llegada": "area_trono", "t_link1": "area_trono", "t_link4": "area_trono", "t_escalera": "area_trono", "t_link5": "area_trono",
	"t_jardin": "area_jardin", "t_link2": "area_corte", "t_corte": "area_corte", "t_link3": "area_galeria_reyes", "t_galeria": "area_galeria_reyes",
	"t_arena": "area_trono_vacio",
}

const AREA_COLORS := {
	"area_bosque": Color(0.6, 0.85, 0.55), "area_nidos": Color(0.95, 0.92, 0.75), "area_cienaga": Color(0.45, 0.8, 0.75),
	"area_madriguera": Color(0.85, 0.6, 0.4), "area_ciervo": Color(0.6, 0.85, 1.0),
	"area_fundicion": Color(1.0, 0.55, 0.25), "area_biblio": Color(0.95, 0.85, 0.6), "area_moldes": Color(0.9, 0.7, 0.4),
	"area_archivo": Color(0.7, 0.75, 0.9), "area_yunque": Color(1.0, 0.4, 0.2),
	"area_trono": Color(0.75, 0.55, 1.0), "area_jardin": Color(1.0, 0.85, 0.4), "area_corte": Color(0.8, 0.5, 0.9),
	"area_galeria_reyes": Color(0.95, 0.75, 0.95), "area_trono_vacio": Color(0.65, 0.35, 1.0),
}
const PEACE := ["area_nidos", "area_biblio", "area_jardin"]
## luz ambiente de cada zona
const AMBIENT := {
	"area_bosque": Color(0.46, 0.55, 0.5), "area_nidos": Color(0.66, 0.64, 0.56), "area_cienaga": Color(0.38, 0.5, 0.52),
	"area_madriguera": Color(0.5, 0.44, 0.4), "area_ciervo": Color(0.5, 0.58, 0.68),
	"area_fundicion": Color(0.6, 0.44, 0.4), "area_biblio": Color(0.62, 0.56, 0.48), "area_moldes": Color(0.55, 0.45, 0.4),
	"area_archivo": Color(0.48, 0.5, 0.6), "area_yunque": Color(0.62, 0.4, 0.34),
	"area_trono": Color(0.45, 0.4, 0.58), "area_jardin": Color(0.62, 0.56, 0.46), "area_corte": Color(0.48, 0.4, 0.56),
	"area_galeria_reyes": Color(0.52, 0.46, 0.6), "area_trono_vacio": Color(0.42, 0.34, 0.56),
}
## música de exploración de cada estrato
const MUSIC := {2: "forest", 3: "foundry", 4: "throne"}
## baldosas: suelos y muros de cada estrato (índices de tiles.png)
const FLOORS := {2: [34, 35, 36, 37], 3: [40, 41, 42, 43], 4: [46, 47, 48, 49]}
const WALLS := {2: [38, 39], 3: [44, 45], 4: [50, 51]}
const CARPET := 52

static func stratum_of_room(rid: String) -> int:
	if rid.begins_with("b_"):
		return 2
	if rid.begins_with("f_"):
		return 3
	if rid.begins_with("t_"):
		return 4
	return 1

# ------------------------------------------------------------------ llegada, Brasas y grietas
const ARRIVAL := {2: Vector2(143.5, 87.0), 3: Vector2(239.5, 87.0), 4: Vector2(335.5, 87.5)}
const ARRIVAL_BRASA := {2: "raices", 3: "yunque", 4: "espinas"}
const BRASAS := [["raices", Vector2(143.5, 82.6)], ["nidos", Vector2(110.5, 60.6)], ["yunque", Vector2(239.5, 82.6)],
	["nombres", Vector2(204.5, 54.6)], ["espinas", Vector2(335.5, 83.6)], ["jardin", Vector2(345.5, 60.6)]]
const BRASA_NAMES := {"sanct": ["Brasa del Santuario", "Sanctuary Ember"], "gate": ["Brasa del Patio", "Courtyard Ember"],
	"nimbo": ["Brasa del Nimbo", "Nimbus Ember"], "umbral": ["Brasa del Umbral", "Threshold Ember"],
	"raices": ["Brasa de las Raíces", "Ember of the Roots"], "nidos": ["Brasa de los Nidos", "Ember of the Nests"],
	"yunque": ["Brasa del Yunque", "Anvil Ember"], "nombres": ["Brasa de los Nombres", "Ember of Names"],
	"espinas": ["Brasa de las Espinas", "Ember of Thorns"], "jardin": ["Brasa del Jardín", "Garden Ember"]}
const BRASA_STRATUM := {"sanct": 1, "gate": 1, "nimbo": 1, "umbral": 1, "raices": 2, "nidos": 2, "yunque": 3, "nombres": 3, "espinas": 4, "jardin": 4}
## grieta que aparece donde cae el Arconte de cada estrato y lleva al siguiente
const RIFTS := {"seravel": [Vector2(49, 6.5), 2], "orrun": [Vector2(141, 4.5), 3], "vulkaris": [Vector2(240, 4.5), 4]}
const STRATUM_NAMES := {1: ["ESTRATO I · VESTÍBULO DE CENIZA", "STRATUM I · ASH VESTIBULE"],
	2: ["ESTRATO II · BOSQUE DE PLUMAS MUERTAS", "STRATUM II · FOREST OF DEAD FEATHERS"],
	3: ["ESTRATO III · FUNDICIÓN DE HALOS", "STRATUM III · HALO FOUNDRY"],
	4: ["ESTRATO IV · EL TRONO VACÍO", "STRATUM IV · THE EMPTY THRONE"]}

# ------------------------------------------------------------------ Arcontes
const ARCHONS := {
	"orrun": {"room": "b_arena", "stratum": 2, "music": "boss_orrun", "seal": "luz", "quest": "main2",
		"intro": [["Orrun", ["Guardaba los nidos. Todos. Hasta que el Arquitecto me pidió que los vaciara.", "I guarded the nests. All of them. Until the Architect asked me to empty them."]],
			["Orrun", ["Tú también vienes a llevarte algo. Lo huelo en tus plumas.", "You too have come to take something. I smell it on your feathers."]]],
		"phase": ["¡Mis astas aún arden! ¡Arden por cada cría que no volvió!", "My antlers still burn! They burn for every chick that never came back!"],
		"death": [["Orrun", ["Los huevos... estaban vacíos. Siempre lo estuvieron. Nos hizo cuidar... la nada.", "The eggs... were empty. They always were. He made us guard... nothing."]],
			["Orrun", ["Baja. La Fundición forja las aureolas... con lo que nos arrancan.", "Go down. The Foundry forges halos... out of what they tear from us."]]]},
	"vulkaris": {"room": "f_arena", "stratum": 3, "music": "boss_vulkaris", "seal": "celda", "quest": "main3",
		"intro": [["Vulkaris", ["Cada aureola de la Espiral salió de este yunque. Cada una pesa lo que pesa un nombre.", "Every halo in the Spiral came off this anvil. Each one weighs as much as a name."]],
			["Vulkaris", ["La tuya la forjé yo. Vengo a recuperarla.", "Yours, I forged myself. I've come to take it back."]]],
		"phase": ["¡AVIVA EL FUEGO! ¡Que funda hasta tus recuerdos!", "STOKE THE FIRE! Let it melt even your memories!"],
		"death": [["Vulkaris", ["Las aureolas no bendicen... encadenan. Fundí mil cadenas con forma de corona.", "Halos don't bless... they bind. I cast a thousand chains in the shape of a crown."]],
			["Vulkaris", ["Azrahel te espera abajo, en el trono que nadie quiso. Pregúntale por la Voz.", "Azrahel awaits you below, on the throne no one wanted. Ask him about the Voice."]]]},
	"azrahel": {"room": "t_arena", "stratum": 4, "music": "boss_azrahel", "seal": "luz", "quest": "main4",
		"intro": [["Azrahel", ["Por fin. El Desplumado que la Voz me prometió.", "At last. The Featherless the Voice promised me."]],
			["Azrahel", ["Te dijeron que me mataras, ¿verdad? A mí me dijeron lo mismo... del que se sentaba aquí antes.", "They told you to kill me, didn't they? They told me the same... about the one who sat here before."]],
			["Azrahel", ["Ven. Acabemos con la mentira de uno de los dos.", "Come. Let us end one of our lies."]]],
		"phase": ["¿Lo oyes? Es la Voz riéndose. Siempre se ríe cuando caemos.", "Do you hear it? It's the Voice laughing. It always laughs when we fall."],
		"phase3": ["¡Si he de romperme... que se rompa la Espiral conmigo!", "If I must break... let the Spiral break with me!"]},
}

# ------------------------------------------------------------------ enemigos (tipo, x, y)
const ENEMIES := [
	# Estrato II
	["musgoso", 131, 59], ["musgoso", 140, 64], ["musgoso", 150, 58], ["nidal", 146, 67], ["garza", 135, 66], ["espino", 152, 64],
	["musgoso", 128, 34], ["musgoso", 140, 41], ["nidal", 150, 33], ["nidal", 131, 43], ["garza", 145, 36], ["espino", 154, 40],
	["garza", 110, 35], ["musgoso", 113, 38], ["nidal", 107, 32], ["espino", 128, 40],
	# Estrato III
	["ascua", 226, 55], ["ascua", 236, 61], ["fundidor", 247, 56], ["chispero", 254, 62], ["forjador", 230, 63], ["ascua", 252, 54],
	["ascua", 227, 30], ["fundidor", 236, 35], ["chispero", 244, 29], ["forjador", 252, 36], ["chispero", 231, 37], ["fundidor", 255, 30],
	["forjador", 204, 28], ["ascua", 209, 33], ["chispero", 238, 70],
	# Estrato IV
	["cortesano", 324, 58], ["sabueso", 340, 64], ["doncella", 348, 57], ["caballero", 330, 63],
	["caballero", 299, 50], ["cortesano", 305, 58], ["sabueso", 297, 62], ["doncella", 304, 47],
	["caballero", 328, 33], ["cortesano", 345, 36], ["sabueso", 337, 32], ["doncella", 326, 37], ["caballero", 347, 33],
]

## pruebas con mini-jefe (oleadas en salas que se sellan)
const TRIALS := {
	"cienaga": {"room": "b_cienaga", "seal": "luz", "title": "trial_cienaga",
		"waves": [[["espino", 168, 55], ["musgoso", 178, 56], ["espino", 180, 64]], [["garza", 170, 62], ["nidal", 178, 54], ["musgoso", 167, 58]],
			[["lacrima", 174, 58]]],
		"reward": {"feathers": 2, "ecos": 900, "items": {"tear": 1, "iron": 1}}, "chest": Vector2(181, 54)},
	"moldes": {"room": "f_moldes", "seal": "celda", "title": "trial_moldes",
		"waves": [[["chispero", 271, 50], ["fundidor", 280, 52], ["ascua", 275, 62]], [["forjador", 270, 60], ["chispero", 281, 61], ["fundidor", 275, 49]],
			[["kronagh", 276, 54]]],
		"reward": {"feathers": 2, "ecos": 1400, "items": {"tear": 1, "iron": 2}}, "chest": Vector2(282, 48)},
	"galeria": {"room": "t_galeria", "seal": "luz", "title": "trial_galeria",
		"waves": [[["caballero", 366, 50], ["doncella", 376, 52], ["cortesano", 371, 61]], [["sabueso", 365, 60], ["caballero", 377, 61], ["doncella", 370, 49]],
			[["ysolde", 371, 54]]],
		"reward": {"feathers": 3, "ecos": 2000, "items": {"tear": 2, "iron": 2}}, "chest": Vector2(378, 48)},
}

# ------------------------------------------------------------------ cofres, inscripciones, PNJ y recados
const CHESTS := [
	["chest_b1", Vector2(154.5, 31.5), {"ecos": 600, "items": {"phoenix": 1}}],
	["chest_b2", Vector2(106, 31.4), {"ecos": 450, "feathers": 2, "items": {"tear": 1}}],
	["chest_b3", Vector2(127, 57.4), {"ecos": 380, "items": {"vial_luz": 2, "bomb": 2}}],
	["chest_f1", Vector2(201.5, 25.4), {"ecos": 900, "items": {"iron": 2, "phoenix": 1}}],
	["chest_f2", Vector2(256.5, 27.4), {"ecos": 700, "feathers": 2}],
	["chest_f3", Vector2(222, 53.4), {"ecos": 600, "items": {"incense": 2, "ointment": 1}}],
	["chest_t1", Vector2(295.5, 45.4), {"ecos": 1300, "items": {"phoenix": 1, "tear": 1}}],
	["chest_t2", Vector2(350.5, 31.4), {"ecos": 1000, "feathers": 3}],
	["chest_t3", Vector2(352, 55.4), {"ecos": 900, "items": {"iron": 2, "vial_aliento": 2}}],
]
const LORE := [
	["lore_bosque", Vector2(146, 57.4), [["Aquí anidaban los serafines recién caídos. Cada pluma blanca del suelo fue una cría que nunca voló.", "Here the newly fallen seraphs nested. Every white feather on the ground was a chick that never flew."]]],
	["lore_arboleda", Vector2(133, 31.4), [["«Orrun, guardián de los nidos: que ningún huevo salga del bosque.» Debajo, rayado con astas: «¿Por qué?»", "\"Orrun, keeper of the nests: let no egg leave the forest.\" Below, scratched with antlers: \"Why?\""]]],
	["lore_madriguera", Vector2(111, 31.4), [["Huellas de oso, enormes. Y huellas de alas que se arrastran. Alguien vivió aquí... y eligió no volar.", "Bear tracks, enormous. And the tracks of dragging wings. Someone lived here... and chose not to fly."]]],
	["lore_crisoles", Vector2(244, 53.4), [["Cada crisol lleva un nombre fundido en el borde. Ninguno es de un herrero.", "Each crucible bears a name melted into its rim. None of them belongs to a smith."]]],
	["lore_fragua", Vector2(229, 27.4), [["«La aureola no se gana. Se pone. Y una vez puesta, no se quita.» — Vulkaris, Herrero de Aureolas", "\"A halo is not earned. It is placed. And once placed, it never comes off.\" — Vulkaris, Halo Smith"]]],
	["lore_archivo", Vector2(207, 25.4), [["Estanterías de halos apagados, ordenados por fecha de caída. El primero no tiene fecha. Solo una palabra: AZRAHEL.", "Shelves of dimmed halos, sorted by date of fall. The first has no date. Only one word: AZRAHEL."]]],
	["lore_jardin", Vector2(327, 55.4), [["Las rosas de oro no tienen olor. El Arquitecto las plantó para que el Rey nunca echara de menos el cielo.", "The golden roses have no scent. The Architect planted them so the King would never miss the sky."]]],
	["lore_corte", Vector2(301, 45.4), [["Una corte entera de cortesanos de rodillas ante un trono vacío. Llevan mil años esperando una orden.", "An entire court kneeling before an empty throne. They have waited a thousand years for an order."]]],
	["lore_escalera", Vector2(326, 31.4), [["«El primero que se negó fue sentado en el trono más alto, para que todos lo vieran... y nadie lo escuchara.»", "\"The first who refused was seated on the highest throne, so that all would see him... and no one would hear him.\""]]],
]
const NPCS := [
	["oso", Vector2(113.5, 57.6), {"sheet": "npc_oso", "name": ["Hermano Oso", "Brother Bear"], "light": Color(1, 0.75, 0.4)}],
	["archivero", Vector2(201.5, 50.8), {"sheet": "npc_archivero", "name": ["El Archivero", "The Archivist"], "light": Color(0.7, 0.85, 1.0)}],
	["lirio", Vector2(323, 57.4), {"sheet": "npc_lirio", "name": ["Lirio, la Jardinera", "Lirio, the Gardener"], "light": Color(1, 0.9, 0.5), "flip": true}],
]
## recados: tres objetos repartidos por el estrato que entregar al PNJ
const ERRAND_ITEMS := [
	["egg_1", Vector2(152, 66.5), "eggs", "luz"], ["egg_2", Vector2(180, 65), "eggs", "luz"], ["egg_3", Vector2(156, 43.5), "eggs", "luz"],
	["name_1", Vector2(258, 64), "names", "scroll"], ["name_2", Vector2(212, 35), "names", "scroll"], ["name_3", Vector2(224, 38), "names", "scroll"],
	["rose_1", Vector2(296, 63), "roses", "heart"], ["rose_2", Vector2(377, 64), "roses", "heart"], ["rose_3", Vector2(348, 38), "roses", "heart"],
]

const DIALOGUE := {
	"oso": [
		["Hermano Oso", ["¡Uf! No te había oído. Ya nadie baja por la grieta... y los que bajan no suelen hablar.", "Oof! I didn't hear you. No one comes down the rift anymore... and those who do rarely talk."]],
		["Hermano Oso", ["Me llamo Oso. Fui serafín, como tú. Un día dejé de volar y me quedé a cuidar lo que queda del bosque.", "They call me Bear. I was a seraph, like you. One day I stopped flying and stayed to tend what's left of the forest."]],
		["Hermano Oso", ["Orrun, el Ciervo, vigila el santuario del norte. Antes cuidaba de las crías... ahora solo cuida de su rabia.", "Orrun, the Stag, watches over the northern sanctuary. He used to care for the chicks... now he only cares for his rage."]],
		["Hermano Oso", ["Si encuentras huevos de luz por el bosque, tráemelos. Quizá alguno aún... no, da igual. Tráemelos.", "If you find eggs of light in the forest, bring them to me. Maybe one still... no, never mind. Bring them."]]],
	"oso_again": [["Hermano Oso", ["El Ciervo está al norte, pasada la Arboleda Hueca. Ve con cuidado: embiste como una tormenta.", "The Stag is to the north, past the Hollow Grove. Careful: he charges like a storm."]]],
	"oso_done": [["Hermano Oso", ["Están vacíos... claro que lo están. Gracias igualmente. Toma: hace siglos que no me hace falta.", "They're empty... of course they are. Thank you all the same. Here: I haven't needed this in centuries."]]],
	"archivero": [
		["El Archivero", ["Shhh. Esto es una biblioteca. Aunque los libros ya no tengan letras.", "Shhh. This is a library. Even if the books have no letters left."]],
		["El Archivero", ["Guardo los nombres de los que cayeron. La Fundición se los arranca para fundir aureolas, y yo los copio antes de que se pierdan.", "I keep the names of the fallen. The Foundry tears them away to cast halos, and I copy them before they're lost."]],
		["El Archivero", ["El tuyo... déjame ver. No. No está. Alguien lo borró a propósito.", "Yours... let me see. No. It's not here. Someone erased it on purpose."]],
		["El Archivero", ["Si ves placas con nombres grabados por la Fundición, tráemelas. Cada una es alguien que merece ser recordado.", "If you see plates with engraved names around the Foundry, bring them to me. Each one is someone worth remembering."]]],
	"archivero_again": [["El Archivero", ["Vulkaris está en el Gran Yunque, al norte. Dicen que forjó la primera aureola... la de Azrahel.", "Vulkaris is at the Great Anvil, to the north. They say he forged the first halo... Azrahel's."]]],
	"archivero_done": [["El Archivero", ["Tres nombres más que no se perderán. Toma esto: lo encontré entre las cenizas, con tu forma.", "Three more names that won't be lost. Take this: I found it among the ashes, shaped like you."]]],
	"lirio": [
		["Lirio", ["¡Oh! Un visitante. Hacía tanto... ¿Te gustan mis rosas? Son de oro. No huelen a nada, pero brillan.", "Oh! A visitor. It's been so long... Do you like my roses? They're gold. They smell of nothing, but they shine."]],
		["Lirio", ["Cuido el jardín del Rey. Él nunca baja a verlo. Desde el trono solo se ve la Voz.", "I tend the King's garden. He never comes down to see it. From the throne you can only see the Voice."]],
		["Lirio", ["Se me escaparon tres rosas vivas. De las de verdad, de las que huelen. Si las encuentras... ¿me las traes?", "Three living roses got away from me. Real ones, ones that smell. If you find them... would you bring them to me?"]]],
	"lirio_again": [["Lirio", ["El Rey está arriba, al final de la escalinata. Si hablas con él... dile que el jardín sigue aquí.", "The King is up there, at the top of the stairs. If you speak to him... tell him the garden is still here."]]],
	"lirio_done": [["Lirio", ["¡Huelen! Huelen a cielo. Toma, para el camino: la última flor del primer jardín.", "They smell! They smell of sky. Here, for the road: the last flower of the first garden."]]],
}
const ERRANDS := {"oso": ["eggs", {"ecos": 1500, "sp": 2, "items": {"tear": 2}}], "archivero": ["names", {"ecos": 2200, "sp": 2, "items": {"iron": 3}}],
	"lirio": ["roses", {"ecos": 3000, "sp": 2, "items": {"phoenix": 2, "tear": 2}}]}

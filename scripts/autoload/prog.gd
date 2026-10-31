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
	"seravel": {"name": ["Hoja de Seravel", "Seravel's Blade"], "sprite": "seravel", "dmg": 20.0, "speed": 1.1, "range": 36.0,
		"arc": 130.0, "combo": 3, "stam": 12.0, "poise": 12.0, "fue": 0.35, "des": 0.35, "fe": 0.5, "wave": true,
		"desc": ["Arma de Arconte. El tercer corte libera una onda de luz.", "Archon weapon. The third slash releases a wave of light."]},
}

# ------------------------------------------------------------------ objetos
## type: consumable | amulet | key | material ; rarity 0-4
const ITEMS := {
	"bomb": {"type": "consumable", "icon": "bomb", "rarity": 1, "name": ["Bomba de Ceniza", "Ash Bomb"],
		"desc": ["Lánzala con [X]: estalla en llamas y daña a todos los enemigos cercanos.", "Throw with [X]: bursts into flame, damaging all nearby enemies."]},
	"incense": {"type": "consumable", "icon": "incense", "rarity": 1, "name": ["Incienso de Fe", "Incense of Faith"],
		"desc": ["+30% de daño durante 30 segundos.", "+30% damage for 30 seconds."]},
	"ointment": {"type": "consumable", "icon": "ointment", "rarity": 1, "name": ["Ungüento de Hierro", "Iron Ointment"],
		"desc": ["-35% de daño recibido durante 30 segundos.", "-35% damage taken for 30 seconds."]},
	"phoenix": {"type": "consumable", "icon": "phoenix", "rarity": 3, "name": ["Pluma de Fénix", "Phoenix Feather"],
		"desc": ["Si caes, renaces al instante con la mitad de vida. Se consume sola.", "If you fall, you are instantly reborn at half health. Used automatically."]},
	"amulet_wing": {"type": "amulet", "icon": "amulet_wing", "rarity": 2, "name": ["Amuleto del Ala Rota", "Broken Wing Amulet"],
		"desc": ["+30% recuperación de aguante.", "+30% stamina recovery."]},
	"amulet_eye": {"type": "amulet", "icon": "amulet_eye", "rarity": 3, "name": ["Ojo de la Guardiana", "Warden's Eye"],
		"desc": ["+10% probabilidad de crítico.", "+10% critical chance."]},
	"amulet_ash": {"type": "amulet", "icon": "amulet_ash", "rarity": 2, "name": ["Sello de Ceniza", "Ash Seal"],
		"desc": ["Tus golpes pueden quemar (+35% daño extra).", "Your hits may burn (+35% bonus damage)."]},
	"key_vestibule": {"type": "key", "icon": "key", "rarity": 2, "name": ["Llave del Vestíbulo", "Vestibule Key"],
		"desc": ["Abre la puerta sellada hacia el Círculo de la Guardiana.", "Opens the sealed gate to the Circle of the Warden."]},
	"map_carto": {"type": "key", "icon": "scroll", "rarity": 1, "name": ["Mapa del Cartógrafo", "Cartographer's Map"],
		"desc": ["Un mapa dibujado a tientas. Huele a vela y a polvo.", "A map drawn by touch. It smells of candle and dust."]},
	"iron": {"type": "material", "icon": "iron", "rarity": 2, "name": ["Hierro Celeste", "Celestial Iron"],
		"desc": ["Metal caído del cielo. Brenna lo usa para mejoras avanzadas.", "Metal fallen from the sky. Brenna uses it for advanced upgrades."]},
}
const RARITY_COLORS := [Color(0.75, 0.72, 0.78), Color(0.55, 0.9, 0.55), Color(0.35, 0.75, 1.0), Color(0.85, 0.45, 1.0), Color(1.0, 0.75, 0.25)]

const MEMORIES := {
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
			{"id": "kill_carcelero", "text": ["Derrota al Carcelero y toma su llave", "Defeat the Jailer and take his key"]},
			{"id": "enter_circle", "text": ["Cruza la puerta sellada", "Pass through the sealed gate"]},
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
	changed.emit()

# ------------------------------------------------------------------ estadísticas derivadas
func has_skill(id: String) -> bool:
	return skills.has(id)

func max_hp() -> float:
	return 100.0 + (attr.vigor - 1) * 14.0

func has_amulet(id: String) -> bool:
	return id in amulets_eq

func stamina_regen_mult() -> float:
	return 1.3 if has_amulet("amulet_wing") else 1.0

func buff_damage_mult() -> float:
	return 1.3 if buffs.has("incense") else 1.0

func max_stamina() -> float:
	return 100.0 + (attr.aguante - 1) * 7.0

func max_light() -> float:
	return 60.0 + (attr.fe - 1) * 6.0

func move_speed() -> float:
	return 118.0 * (1.12 if has_skill("a5") else 1.0)

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
	var scale = 1.0 + 0.045 * ((attr.fuerza - 1) * w.fue + (attr.destreza - 1) * w.des + (attr.fe - 1) * w.fe)
	var dmg: float = w.dmg * scale * (1.0 + 0.09 * up)
	if has_skill("f1"):
		dmg *= 1.12
	return dmg * buff_damage_mult()

func spell_damage(base: float) -> float:
	return base * (1.0 + 0.06 * (attr.fe - 1)) * (1.25 if has_skill("l1") else 1.0) * buff_damage_mult()

func crit_chance() -> float:
	return 0.05 + 0.012 * (attr.destreza - 1) + (0.1 if has_amulet("amulet_eye") else 0.0)

func damage_taken_mult() -> float:
	return (0.88 if has_skill("c2") else 1.0) * (0.65 if buffs.has("ointment") else 1.0)

func ecos_mult() -> float:
	return 1.0 + 0.03 * (attr.arcano - 1)

func level_cost() -> int:
	return int(90 + 55 * level + 6 * level * level)

func upgrade_cost(id: String) -> Array:
	var lv: int = weapons.get(id, 0)
	return [180 * (lv + 1), lv + 1]  # [ecos, plumas]

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
		G.toast(G.T("new_weapon") % G.L(WEAPONS[id].name), Color(1, 0.8, 0.4))
	changed.emit()

func upgrade_weapon(id: String) -> bool:
	var lv: int = weapons.get(id, 0)
	if lv >= 10:
		return false
	if free_upgrades > 0:
		free_upgrades -= 1
	else:
		var c := upgrade_cost(id)
		if ecos < c[0] or feathers < c[1]:
			return false
		ecos -= c[0]
		feathers -= c[1]
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
		G.toast(G.T("item_got") % (G.L(ITEMS[id].name) + ("" if n <= 1 else " x%d" % n)), RARITY_COLORS[ITEMS[id].rarity])
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
	changed.emit()
	return true

func equip_amulet(id: String) -> void:
	if not inventory.has(id) or has_amulet(id):
		return
	var slot := amulets_eq.find("")
	if slot < 0:
		slot = 1
	amulets_eq[slot] = id
	changed.emit()

func unequip_amulet(id: String) -> void:
	var i := amulets_eq.find(id)
	if i >= 0:
		amulets_eq[i] = ""
	changed.emit()

func unlock_memory(id: String) -> bool:
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
	if st < q.steps.size() and q.steps[st].id == step_id:
		quests[id].step = st + 1
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
		"amulets_eq": amulets_eq, "quick_item": quick_item, "memories": memories}

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
	changed.emit()

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict(), "\t"))
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

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

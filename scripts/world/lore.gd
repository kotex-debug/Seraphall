class_name Lore
extends RefCounted
## Diálogos que cambian con el progreso de la partida.
## Cada PNJ tiene frases para cada "etapa" de la historia (se dicen una sola vez, la primera vez que
## hablas con él después de alcanzarla) y un repertorio de frases sueltas que va rotando.

## Etapas en orden: la más avanzada que se cumpla es la que cuenta.
const STAGES := ["seravel_dead", "trial_umbral", "choir_dead", "trial_atrio", "carcelero_dead", "trial_celdas"]

const STAGE_LINES := {
	"brenna": {
		"trial_celdas": [["Brenna", ["¿Has abierto las Celdas de Espera? Por la Brasa... allí no se encerraba a nadie por castigo.", "You opened the Waiting Cells? By the Ember... no one was locked in there as punishment."]],
			["Brenna", ["Mi abuela decía que las celdas se cerraban desde dentro. Nunca entendí por qué.", "My grandmother said the cells were locked from the inside. I never understood why."]]],
		"carcelero_dead": [["Brenna", ["¡La llave del Carcelero! Déjame verla... Este hierro no es de la Espiral. Lo forjaron arriba, en el cielo.", "The Jailer's key! Let me see it... This iron isn't from the Spiral. It was forged up there, in the sky."]],
			["Brenna", ["Si los de arriba le dieron la llave, es que alguien de arriba quería que esa puerta siguiera cerrada.", "If those above gave him the key, someone above wanted that door to stay shut."]]],
		"choir_dead": [["Brenna", ["Ya no se oye el canto de la Galería. Raro... llevaba siglos sin pegar ojo y esta noche he dormido como una piedra.", "The Gallery's singing has stopped. Odd... I hadn't slept a wink in centuries and tonight I slept like a stone."]]],
		"trial_umbral": [["Brenna", ["¿El Custodio te habló? Las estatuas no hablan, criatura. Al menos, no a cualquiera.", "The Warden spoke to you? Statues don't speak, child. Not to just anyone, at least."]]],
		"seravel_dead": [["Brenna", ["Seravel... Yo forjé su primera espada, ¿sabes? Antes de que todo esto empezara.", "Seravel... I forged her first sword, you know. Before all this began."]],
			["Brenna", ["Si alguna vez vuelves a verla, en este círculo o en otro, dile que la hoja aún no tiene ni una mella.", "If you ever see her again, in this circle or another, tell her the blade still hasn't a single nick."]]],
	},
	"carto": {
		"trial_celdas": [["El Cartógrafo", ["Las Celdas... Oí cómo se abrían desde aquí. Fue como si la Espiral soltara el aliento que contenía.", "The Cells... I heard them open from here. As if the Spiral let out a breath it had been holding."]]],
		"carcelero_dead": [["El Cartógrafo", ["Al noreste del Patio hay una escalinata que no figura en ningún mapa. Ni en el mío. Y eso que lo dibujé yo.", "North-east of the Yard there's a stairway that's on no map. Not even mine. And I drew it myself."]]],
		"trial_atrio": [["El Cartógrafo", ["Tañiste las campanas al revés, ¿verdad? Lo noté en los huesos. Algo, muy abajo, se ha dado la vuelta en su sueño.", "You rang the bells backwards, didn't you? I felt it in my bones. Something, far below, turned over in its sleep."]]],
		"seravel_dead": [["El Cartógrafo", ["El Estrato I ya es tuyo. Mi mapa termina aquí. Lo que hay debajo... eso lo dibujarás tú.", "Stratum I is yours now. My map ends here. What lies below... you'll be the one to draw it."]]],
	},
	"ozias": {
		"carcelero_dead": [["Ozias", ["La llave del Carcelero tiene runas por dentro. No dicen «abrir». Dicen «que no entre».", "The Jailer's key has runes on the inside. They don't say \"open\". They say \"let it not enter\"."]]],
		"trial_atrio": [["Ozias", ["El Himno de la Vigilia... Lo grabé yo mismo en esas campanas. Hace tanto que olvidé para qué servía.", "The Hymn of the Vigil... I carved it into those bells myself. So long ago I forgot what it was for."]]],
		"trial_umbral": [["Ozias", ["El Custodio llevaba mil años sin moverse. Si se levantó por ti, es que te reconoció. La pregunta es: ¿como qué?", "The Warden hadn't moved in a thousand years. If it rose for you, it recognised you. The question is: as what?"]]],
		"seravel_dead": [["Ozias", ["La aureola de Seravel se partió en esquirlas. Tráemelas: cada una recuerda un trozo de la verdad.", "Seravel's halo shattered into shards. Bring them to me: each one remembers a piece of the truth."]]],
	},
	"ilse": {
		"trial_celdas": [["Madre Ilse", ["Tobías sigue vivo... Lo cuidé de joven, antes de que bajara a las Celdas. Dile que la vieja Ilse aún reza por él.", "Tobias is still alive... I looked after him when he was young, before he went down to the Cells. Tell him old Ilse still prays for him."]]],
		"choir_dead": [["Madre Ilse", ["Las voces del Coro no se han ido, criatura. Ahora cantan dentro de ti. Escúchalas cuando no puedas dormir.", "The Choir's voices haven't gone, child. Now they sing inside you. Listen to them when you can't sleep."]]],
		"seravel_dead": [["Madre Ilse", ["Has perdido algo más que plumas allí arriba. Lo veo en tus ojos. Siéntate un momento. Nadie te persigue aquí.", "You lost more than feathers up there. I can see it in your eyes. Sit for a while. Nothing hunts you here."]]],
	},
	"nyx": {
		"carcelero_dead": [["Nyx", ["Mataste al Carcelero y saliste con la llave. Te ofrecería un buen precio por ella... pero algo me dice que no está a la venta.", "You killed the Jailer and walked off with the key. I'd offer a good price for it... but something tells me it's not for sale."]]],
		"trial_atrio": [["Nyx", ["Desde que callaste ese himno, mis clientes no hablan de otra cosa. Las malas noticias venden mucho.", "Since you silenced that hymn, my customers talk of nothing else. Bad news sells very well."]]],
		"seravel_dead": [["Nyx", ["Venciste a la Guardiana. Mis precios suben. No es nada personal: es que ahora los clientes tienen miedo.", "You beat the Warden. My prices go up. Nothing personal: customers are just scared now."]]],
	},
	"velaria": {
		"carcelero_dead": [["Sor Velaria", ["El Carcelero ya duerme. Si quieres volver a verlo de pie, aquí estaré. Su eco es más fuerte que él.", "The Jailer sleeps now. If you want to see him standing again, I'll be here. His echo is stronger than he was."]]],
		"choir_dead": [["Sor Velaria", ["Has hecho callar al Coro. Cumpliste tu palabra. Toma... y no preguntes de qué estaba hecho su corazón.", "You silenced the Choir. You kept your word. Take this... and don't ask what its heart was made of."]]],
		"seravel_dead": [["Sor Velaria", ["La Guardiana ha caído y aun así la Espiral no se abre. Quizá nunca fue una puerta, sino un cerrojo.", "The Warden has fallen and still the Spiral won't open. Perhaps it was never a door, but a lock."]]],
	},
	"peregrina": {
		"trial_umbral": [["Sael", ["El Custodio te ha dejado pasar. A mí nunca me miró. Ni una sola vez en trescientos años.", "The Warden let you through. It never once looked at me. Not once in three hundred years."]]],
		"seravel_dead": [["Sael", ["Has llegado arriba... y la escalera sigue. Siempre sigue. Hacia abajo, eso sí.", "You reached the top... and the stairs go on. They always do. Downwards, mind you."]],
			["Sael", ["Si encuentras el último peldaño, vuelve y cuéntamelo. Me haría ilusión tener algo que esperar.", "If you find the last step, come back and tell me. I'd like to have something to look forward to."]]],
	},
	"preso": {
		"carcelero_dead": [["Tobías", ["El Carcelero ha caído. Lo noto: las cadenas pesan menos. Y algo, ahí fuera, se ha despertado.", "The Jailer has fallen. I can feel it: the chains weigh less. And something, out there, has woken up."]]],
		"trial_umbral": [["Tobías", ["Anoche soñé con una figura sin rostro bajando la escalinata. Tenía tus andares. Perdona... son cosas de viejo.", "Last night I dreamt of a faceless figure walking down the stairway. It walked like you. Forgive me... an old man's fancies."]]],
		"seravel_dead": [["Tobías", ["Ya no hay nadie a quien vigilar. Me quedaré aquí de todos modos. Alguien tiene que recordar a los que esperaban.", "There's no one left to watch over. I'll stay anyway. Someone has to remember the ones who waited."]]],
	},
}

## Frases sueltas que rotan cuando ya no hay nada nuevo que contar
const IDLE := {
	"brenna": [
		["Brenna", ["¿Has visto los esqueletos con alas del Pasillo? Algunos aún aprietan la empuñadura. Buen acero, ese.", "Seen the winged skeletons in the Hall? Some still grip their hilts. Good steel, that."]],
		["Brenna", ["Acércame esa hoja. A ver qué puedo hacer.", "Hand me that blade. Let's see what I can do."]],
		["Brenna", ["El fuego de la forja es de la Brasa. Por eso nunca se apaga... y por eso nunca calienta del todo.", "The forge fire comes from the Ember. That's why it never goes out... and why it never quite warms you."]],
		["Brenna", ["Si se te rompe el arma ahí abajo, no la tires. Las armas también recuerdan.", "If your weapon breaks down there, don't throw it away. Weapons remember too."]],
	],
	"carto": [
		["El Cartógrafo", ["A veces, en la Galería, veo a dos acólitos discutir. Llevan mil años muertos. Siguen sin ponerse de acuerdo.", "Sometimes, in the Gallery, I see two acolytes arguing. They've been dead a thousand years. Still can't agree."]],
		["El Cartógrafo", ["Los Arcontes no nacieron monstruos. Eran los mejores de nosotros.", "The Archons weren't born monsters. They were the best of us."]],
		["El Cartógrafo", ["Cien círculos hacia abajo. Nadie ha vuelto a subir. Nadie que yo haya oído.", "A hundred circles down. No one has ever climbed back up. No one I've heard."]],
		["El Cartógrafo", ["La Voz que te despertó... ¿te dijo su nombre? A mí tampoco.", "The Voice that woke you... did it tell you its name? It never told me either."]],
		["El Cartógrafo", ["Cuando pierdo el rumbo, cuento los pasos hasta la Brasa. Te aconsejo lo mismo.", "When I lose my way, I count my steps back to the Ember. I'd advise you to do the same."]],
	],
	"ozias": [
		["Ozias", ["La araña de velas del Nimbo la colgué yo. No me preguntes cómo: allí arriba no hay techo.", "I hung the Nimbus chandelier myself. Don't ask me how: there's no ceiling up there."]],
		["Ozias", ["Tráeme Esquirlas de Nimbo. Cada una guarda un eco de la aureola rota.", "Bring me Nimbus Shards. Each one holds an echo of the broken halo."]],
		["Ozias", ["Una runa mal grabada no se borra. Se aprende a vivir con ella. Como con todo.", "A badly carved rune can't be erased. You learn to live with it. Like with everything."]],
	],
	"ilse": [
		["Madre Ilse", ["Las urnas guardan cenizas de los que ardieron en la Brasa. Si rompes una, di su nombre. Cualquiera vale.", "The urns hold the ashes of those who burned in the Ember. If you break one, say a name. Any will do."]],
		["Madre Ilse", ["Cada Lágrima Cristalizada fue alguien. Úsalas bien.", "Every Crystallized Tear was someone. Use them well."]],
		["Madre Ilse", ["Si se te caen las plumas, tráemelas. Las coso yo, aunque se me vaya la vista en cada puntada.", "If your feathers fall, bring them to me. I'll sew them back, even if every stitch costs me my eyesight."]],
	],
	"nyx": [
		["Nyx", ["¿Rompes urnas para sacar Ecos? Bien. Así me los gastas a mí.", "Breaking urns for Echoes? Good. Then you'll spend them here."]],
		["Nyx", ["¿Ecos? Los acepto. Lo que vendo no pregunta de dónde vienes, y yo tampoco.", "Echoes? I'll take them. What I sell doesn't ask where you come from, and neither do I."]],
		["Nyx", ["La máscara no es por el frío, por si te lo preguntabas. Es para que nadie me reconozca... de antes.", "The mask isn't for the cold, if you were wondering. It's so no one recognises me... from before."]],
	],
	"velaria": [
		["Sor Velaria", ["Cuando truena en el abismo, los ecos de los Arcontes se revuelven. Hasta los muertos tienen pesadillas.", "When thunder rolls in the abyss, the Archons' echoes stir. Even the dead have nightmares."]],
		["Sor Velaria", ["Los Arcontes caídos dejan ecos. Puedo despertarlos, más fuertes, más crueles. Si sobrevives, el Nimbo te recompensará.", "Fallen Archons leave echoes. I can awaken them, stronger, crueler. Survive, and the Nimbus will reward you."]],
		["Sor Velaria", ["Un juramento pesa más que cualquier armadura. Elige bien antes de cargar con uno.", "An oath weighs more than any armour. Choose well before you carry one."]],
	],
	"peregrina": [
		["Sael", ["Cuenta los peldaños. Si un día salen distintos, es que la Espiral te está mintiendo.", "Count the steps. If one day the number changes, the Spiral is lying to you."]],
		["Sael", ["Mi farolillo no da calor. Lo llevo para que los de abajo sepan que aún queda alguien subiendo.", "My lantern gives no warmth. I carry it so those below know someone is still climbing."]],
		["Sael", ["¿Sabes por qué las estatuas de la escalera están de rodillas? Yo tampoco. Pero nunca les doy la espalda.", "Do you know why the statues on the stairs are kneeling? Neither do I. But I never turn my back on them."]],
	],
	"preso": [
		["Tobías", ["No abras las celdas. Por favor. Él nos metió aquí para que estuviéramos a salvo, no para castigarnos.", "Don't open the cells. Please. He put us here to keep us safe, not to punish us."]],
		["Tobías", ["Cuando la Voz habla, los de las celdas se vuelven... huecos. Si oyes que te llaman por tu nombre, no contestes.", "When the Voice speaks, those in the cells turn... hollow. If you hear your name being called, don't answer."]],
	],
}

static func stage_of(flags: Dictionary) -> String:
	for st in STAGES:
		if flags.get(st, false):
			return st
	return ""

## Frases de la etapa más avanzada alcanzada, si aún no se han escuchado (y las marca). [] si no hay.
static func stage_lines(npc: String, flags: Dictionary) -> Array:
	var table: Dictionary = STAGE_LINES.get(npc, {})
	for st in STAGES:
		if flags.get(st, false) and table.has(st):
			var key := "heard_%s_%s" % [npc, st]
			if not Prog.flags.get(key, false):
				Prog.flags[key] = true
				return (table[st] as Array).duplicate(true)
			return []
	return []

## Una frase suelta del repertorio (rota en cada visita).
static func idle_line(npc: String) -> Array:
	var pool: Array = IDLE.get(npc, [])
	if pool.is_empty():
		return []
	var ck := "talk_n_" + npc
	var n: int = int(Prog.flags.get(ck, 0))
	Prog.flags[ck] = n + 1
	return [(pool[n % pool.size()] as Array).duplicate(true)]

static func lines_for(npc: String, flags: Dictionary) -> Array:
	var l := stage_lines(npc, flags)
	return l if not l.is_empty() else idle_line(npc)

## Inscripciones repartidas por el Estrato I: [id, casilla, líneas]
const STELAE := [
	["lore_sanct", Vector2(56.6, 91.4), [
		["La Brasa no la encendió el Arquitecto. La encendió el primero que se negó a apagarse.", "The Ember was not lit by the Architect. It was lit by the first who refused to go out."]]],
	["lore_chains", Vector2(36.2, 68.6), [
		["Cada eslabón de estas cadenas lleva un nombre grabado. Casi todos están tachados.", "Every link of these chains bears an engraved name. Nearly all of them are scratched out."],
		["Uno, el último, sigue sin tachar. Tiene diez marcas al lado. Diez, como tus plumas.", "One, the last, is still untouched. Ten marks sit beside it. Ten, like your feathers."]]],
	["lore_gallery", Vector2(73.6, 70.6), [
		["«Pintamos el cielo en estas paredes para no olvidar su color. Ya no recordamos si era así.»", "\"We painted the sky on these walls so we wouldn't forget its colour. We no longer remember if it looked like this.\""]]],
	["lore_mirador", Vector2(29.8, 88.6), [
		["Desde aquí se ve el primer círculo entero. Dicen que, en días claros, se oye a alguien llorar en el fondo.", "From here you can see the whole first circle. They say that on clear days you can hear someone weeping at the bottom."]]],
	["lore_alcove", Vector2(35.4, 36.6), [
		["«El Carcelero no tiene llave para salir. Solo para que nadie entre. Recuérdalo cuando lo mates.»", "\"The Jailer has no key to get out. Only one to keep others from getting in. Remember that when you kill him.\""]]],
]


## Pensamientos del protagonista (y, a veces, la Voz) la primera vez que entra en cada zona.
## "" = pensamiento propio; "???" = la Voz.
const AREA_THOUGHTS := {
	"area_chains": [["", ["Cadenas por todas partes. Ninguna atada a nada. Como si lo encadenado se hubiera ido... o aún no hubiera llegado.", "Chains everywhere. None of them tied to anything. As if what they held had left... or had yet to arrive."]],
		["", ["Me duelen los omóplatos al verlas. Ahí es donde estaban mis alas.", "My shoulder blades ache at the sight. That's where my wings used to be."]]],
	"area_gallery": [["", ["Retratos sin rostro. Alguien rascó cada cara con las uñas, una a una.", "Faceless portraits. Someone scratched every face away with their nails, one by one."]],
		["???", ["No mires tanto. Uno de ellos era el tuyo.", "Don't stare. One of them was yours."]]],
	"area_yard": [["", ["Huele a hierro y a lluvia vieja. Aquí arriba nunca llovió... ¿o sí?", "It smells of iron and old rain. It never rained up here... or did it?"]],
		["", ["Algo enorme arrastra los pies al otro lado del patio. Y canturrea.", "Something huge drags its feet across the yard. And it hums."]]],
	"area_circle": [["", ["Un círculo perfecto. Los ángeles nunca supieron construir otra cosa.", "A perfect circle. Angels never knew how to build anything else."]]],
	"area_mirador": [["", ["Desde aquí se ve la caída entera. No recuerdo el golpe. Solo el silencio de después.", "From here you can see the whole fall. I don't remember the impact. Only the silence after."]],
		["", ["Allí abajo, entre la niebla... ¿eso son alas? Cientos de ellas.", "Down there, in the mist... are those wings? Hundreds of them."]]],
	"area_nimbo": [["", ["Un nimbo flota sin dueño en el centro de la sala. Todavía da calor.", "A halo floats ownerless in the middle of the hall. It's still warm."]]],
	"area_celdas": [["", ["Las puertas están cerradas por dentro. Nadie encerró a esta gente. Se encerraron ellos.", "The doors are locked from the inside. Nobody imprisoned these people. They locked themselves in."]],
		["???", ["Esperaban a alguien. Te esperaban a ti.", "They were waiting for someone. They were waiting for you."]]],
	"area_capilla": [["", ["Una capilla que nadie tapió por miedo. La tapiaron por cariño, para que nadie la rompiera.", "A chapel nobody walled up out of fear. They walled it up out of love, so no one would break it."]],
		["", ["Por primera vez desde la caída, la Voz no dice nada.", "For the first time since the fall, the Voice says nothing."]]],
}


## Ecos del pasado: fantasmas que reviven una escena cuando te acercas (una sola vez por partida).
const GHOST_ECHOES := {
	"galeria": [[["Acólito", "Acolyte"], ["¿Lo has oído? Dicen que uno de los Serafines se negó a cantar el Himno.", "Have you heard? They say one of the Seraphim refused to sing the Hymn."]],
		[["Acólita", "Acolyte"], ["Calla. Si la Voz te oye repetirlo, te raspará la cara como a los de los cuadros.", "Hush. If the Voice hears you say it, it'll scrape your face off like the ones in the paintings."]],
		[["Acólito", "Acolyte"], ["Dicen que no tenía miedo. Que solo... miraba hacia abajo.", "They say it wasn't afraid. That it just... kept looking down."]]],
	"patio": [[["Seravel", "Seravel"], ["Toma la llave, Carcelero. Desde hoy nadie baja. Nadie sube.", "Take the key, Jailer. From today, no one goes down. No one comes up."]],
		[["El Carcelero", "The Jailer"], ["¿Y si el que baja es uno de los vuestros, Guardiana?", "And if the one going down is one of yours, Warden?"]],
		[["Seravel", "Seravel"], ["Entonces, sobre todo, ese.", "Then that one above all."]]],
	"nimbo": [[["Seravel", "Seravel"], ["Si cruzas ese umbral tendré que darte caza. Lo sabes.", "If you cross that threshold I'll have to hunt you down. You know that."]],
		[["Tú, antes", "You, before"], ["Lo sé. Por eso te dejo mi nimbo. Para que tengas algo que perseguir.", "I know. That's why I'm leaving you my halo. So you'll have something to chase."]],
		[["Seravel", "Seravel"], ["...Pues vuelve a buscarlo. Prométemelo.", "...Then come back for it. Promise me."]]],
}


## Susurros de la Brasa al descansar (los dicen los caídos que ardieron en ella). [requisito, [es, en]]
const BRASA_WHISPERS := [
	["", ["«Siéntate. Nosotros también llegamos hasta aquí.»", "\"Sit. We made it this far too.\""]],
	["", ["«Cada pluma que entregas nos calienta un poco más.»", "\"Every feather you give warms us a little more.\""]],
	["", ["«No cuentes las muertes. Cuenta lo que recuerdas.»", "\"Don't count the deaths. Count what you remember.\""]],
	["", ["«La Voz nunca se sienta junto al fuego. ¿Te has fijado?»", "\"The Voice never sits by the fire. Have you noticed?\""]],
	["carcelero_dead", ["«El Carcelero también ardió aquí, una vez. Era tímido.»", "\"The Jailer burned here once, too. He was shy.\""]],
	["carcelero_dead", ["«La llave abre hacia abajo. Siempre hacia abajo.»", "\"The key opens downwards. Always downwards.\""]],
	["choir_dead", ["«Ya no cantan. Ahora podemos oír nuestros nombres.»", "\"They no longer sing. Now we can hear our names.\""]],
	["trial_umbral", ["«El Custodio te llamó por un nombre. No era el tuyo... aún.»", "\"The Warden called you by a name. Not yours... yet.\""]],
	["seravel_dead", ["«Ella también se sentaba aquí. Siempre de espaldas al abismo.»", "\"She used to sit here too. Always with her back to the abyss.\""]],
	["seravel_dead", ["«Abajo hay un bosque donde las plumas echan raíces.»", "\"Down below there's a forest where feathers take root.\""]],
]

static func brasa_whisper() -> String:
	var pool: Array = []
	for w in BRASA_WHISPERS:
		if w[0] == "" or Prog.flags.get(w[0], false):
			pool.append(w)
	# las frases de etapas más avanzadas pesan el doble
	for w in BRASA_WHISPERS:
		if w[0] != "" and Prog.flags.get(w[0], false):
			pool.append(w)
	return G.L(pool[randi() % pool.size()][1])

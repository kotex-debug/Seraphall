extends SceneTree
## Banda sonora original del tráiler, sintetizada nota a nota sobre los temas del juego (la Pluma y Seravel)
## y sincronizada con los cortes de tools/trailer_cortes.txt. No se exporta con el juego.
##   godot --headless --path . --script res://tools/gen_trailer_score.gd -- CARPETA
## Escribe una pista WAV por grupo de instrumentos; tools/make_trailer.sh las mezcla con reverberación.

const SR := 44100
const BEAT := 60.0 / 168.0
const FIN := 5.0  # segundos del cierre con el logo; igual que el último corte
const PLUMA := [[74, 1.0], [81, 1.0], [79, 0.5], [77, 0.5], [76, 1.0], [77, 0.5], [76, 0.5], [74, 2.0], [72, 1.0], [74, 0.5], [76, 0.5], [77, 1.0], [76, 1.0], [72, 1.0], [74, 3.0]]
const SERAVEL := [[69, 1.5], [72, 0.5], [76, 1.0], [74, 1.0], [72, 0.5], [71, 0.5], [69, 2.0], [65, 1.0], [67, 1.0], [69, 1.0], [76, 1.0], [74, 4.0]]
const DM := [38, 50, 57, 62, 65, 69]
const BB := [34, 46, 53, 58, 62, 65]
const CM := [36, 48, 55, 60, 64, 67]
const AM := [33, 45, 52, 57, 61, 64]
const DMAJ := [38, 50, 57, 62, 66, 69]

var drop := 6.5
var total := 41.714
var stems := {}
var cache := {}
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 2026
	var out: String = OS.get_cmdline_user_args()[0]
	var cuts := _read_cuts()
	var n := int((total + 3.0) * SR)
	for s in ["drums", "strings", "brass", "choir", "bass", "fx", "bell"]:
		var a := PackedFloat32Array()
		a.resize(n)
		stems[s] = a
	_intro()
	_body()
	_finale()
	_cut_fx(cuts)
	for s2: String in stems:
		_write_wav(out + "/score_%s.wav" % s2, stems[s2])
	_embers(out + "/embers.png")
	print("PARTITURA_OK cortes=", cuts.size(), " caida=", drop, " total=", total)
	quit()

## Capa de brasas para el tráiler: cuadrados dorados sobre negro que el montaje hace subir
func _embers(path: String) -> void:
	var img := Image.create(1080, 1920, false, Image.FORMAT_RGB8)
	for i in 90:
		var sz := rng.randi_range(3, 9)
		var c := Color(1.0, rng.randf_range(0.4, 0.75), rng.randf_range(0.1, 0.3)) * rng.randf_range(0.5, 1.0)
		img.fill_rect(Rect2i(rng.randi_range(0, 1070), rng.randi_range(0, 1910), sz, sz), c)
	img.save_png(path)

func _read_cuts() -> Array:
	## Mismo cálculo de tiempos que el montaje
	var res := []
	var t := 0.0
	for line in FileAccess.get_file_as_string("res://tools/trailer_cortes.txt").split("\n", false):
		if line.begins_with("# caida"):
			drop = float(line.split(" ")[2])
		if line.begins_with("#"):
			continue
		var p := line.strip_edges().split(" ", false)
		if p.size() < 3:
			continue
		res.append([t, p[0], p.size() > 4 and p[4] == "golpe"])
		t += float(p[2].trim_suffix("s")) if p[2].ends_with("s") else float(p[2]) * BEAT
	total = t
	return res

# ---------------------------------------------------------------------- utilidades
func mf(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)

func at(beat: float) -> float:
	return drop + beat * BEAT

func put(stem: String, src: PackedFloat32Array, t: float, gain := 1.0) -> void:
	var dst: PackedFloat32Array = stems[stem]
	var i0 := int(t * SR)
	if i0 < 0:
		i0 = 0
	var m := mini(src.size(), dst.size() - i0)
	for i in m:
		dst[i0 + i] += src[i] * gain

func noise_burst(n: int) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		o[i] = rng.randf_range(-1.0, 1.0)
	return o

func _write_wav(path: String, data: PackedFloat32Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	var bytes := data.to_byte_array()
	f.store_string("RIFF")
	f.store_32(36 + bytes.size())
	f.store_string("WAVEfmt ")
	f.store_32(16)
	f.store_16(3)      # coma flotante de 32 bits
	f.store_16(1)
	f.store_32(SR)
	f.store_32(SR * 4)
	f.store_16(4)
	f.store_16(32)
	f.store_string("data")
	f.store_32(bytes.size())
	f.store_buffer(bytes)
	f.close()

# ---------------------------------------------------------------------- instrumentos
func strings(m: float, dur: float, bright := 3000.0, att := 0.008, rel := 0.07) -> PackedFloat32Array:
	var key := "st%d_%d_%d_%d" % [int(m * 10), int(dur * 1000), int(bright), int(att * 1000)]
	if cache.has(key):
		return cache[key]
	var n := int((dur + rel) * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var f := mf(m) / SR
	var p0 := rng.randf()
	var p1 := rng.randf()
	var p2 := rng.randf()
	var lp := 0.0
	var a := 1.0 - exp(-TAU * bright / SR)
	for i in n:
		var t := float(i) / SR
		var env := minf(t / att, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
		p0 = fmod(p0 + f * 0.996, 1.0)
		p1 = fmod(p1 + f, 1.0)
		p2 = fmod(p2 + f * 1.005, 1.0)
		lp += a * ((p0 + p1 + p2) * 0.6667 - 1.0 - lp)
		o[i] = lp * env
	cache[key] = o
	return o

func brass(m: float, dur: float) -> PackedFloat32Array:
	var key := "br%d_%d" % [int(m * 10), int(dur * 1000)]
	if cache.has(key):
		return cache[key]
	var rel := 0.12
	var n := int((dur + rel) * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var f := mf(m) / SR
	var p0 := rng.randf()
	var p1 := rng.randf()
	var p2 := rng.randf()
	var lp := 0.0
	for i in n:
		var t := float(i) / SR
		var env := minf(t / 0.02, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
		var vib := 1.0 + 0.003 * sin(t * 33.0) * minf(t * 2.0, 1.0)
		p0 = fmod(p0 + f * 0.995 * vib, 1.0)
		p1 = fmod(p1 + f * vib, 1.0)
		p2 = fmod(p2 + f * 1.006 * vib, 1.0)
		var cut := 500.0 + 3400.0 * minf(t / 0.09, 1.0) * (0.75 + 0.25 * exp(-t * 3.0))
		lp += minf(TAU * cut / SR, 1.0) * ((p0 + p1 + p2) * 0.6667 - 1.0 - lp)
		var x := lp * 1.8
		o[i] = x / (1.0 + absf(x)) * env
	cache[key] = o
	return o

func choir(m: float, dur: float, vowel := "a") -> PackedFloat32Array:
	var key := "ch%d_%d_%s" % [int(m * 10), int(dur * 1000), vowel]
	if cache.has(key):
		return cache[key]
	var rel := 0.5
	var n := int((dur + rel) * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var f := mf(m) / SR
	var p0 := rng.randf()
	var p1 := rng.randf()
	var p2 := rng.randf()
	var fa: float = 2.0 * sin(PI * (800.0 if vowel == "a" else 460.0) / SR)
	var fb: float = 2.0 * sin(PI * (1200.0 if vowel == "a" else 820.0) / SR)
	var la := 0.0
	var ba := 0.0
	var lb := 0.0
	var bb := 0.0
	for i in n:
		var t := float(i) / SR
		var env := minf(t / 0.16, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
		var vib := 1.0 + 0.004 * sin(t * 31.0 + m)
		p0 = fmod(p0 + f * 0.994 * vib, 1.0)
		p1 = fmod(p1 + f * vib, 1.0)
		p2 = fmod(p2 + f * 1.007 * vib, 1.0)
		var s := (p0 + p1 + p2) * 0.6667 - 1.0
		la += fa * ba
		var ha := s - la - 0.22 * ba
		ba += fa * ha
		lb += fb * bb
		var hb := s - lb - 0.25 * bb
		bb += fb * hb
		o[i] = (ba * 0.75 + bb * 0.5) * env * 0.6
	cache[key] = o
	return o

func bass(m: float, dur: float) -> PackedFloat32Array:
	var key := "ba%d_%d" % [int(m * 10), int(dur * 1000)]
	if cache.has(key):
		return cache[key]
	var rel := 0.05
	var n := int((dur + rel) * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var f := mf(m) / SR
	var p := 0.0
	var lp := 0.0
	var a := 1.0 - exp(-TAU * 520.0 / SR)
	for i in n:
		var t := float(i) / SR
		var env := minf(t / 0.006, 1.0) * (1.0 if t < dur else maxf(0.0, 1.0 - (t - dur) / rel))
		p = fmod(p + f, 1.0)
		lp += a * (2.0 * p - 1.0 - lp)
		var x := (lp + 0.7 * sin(TAU * p)) * 1.6
		o[i] = x / (1.0 + absf(x)) * env
	cache[key] = o
	return o

func bell(m: float, dur := 2.2) -> PackedFloat32Array:
	var key := "be%d" % int(m * 10)
	if cache.has(key):
		return cache[key]
	var n := int(dur * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var f := mf(m)
	var parts := [[1.0, 1.0, 2.2], [2.0, 0.55, 3.0], [2.76, 0.35, 4.5], [5.4, 0.2, 7.0], [8.93, 0.12, 11.0]]
	for q: Array in parts:
		var w: float = TAU * f * q[0] / SR
		var g: float = q[1]
		var k: float = q[2]
		for i in n:
			o[i] += sin(w * i) * g * exp(-k * i / float(SR))
	cache[key] = o
	return o

func taiko(g := 1.0) -> PackedFloat32Array:
	if cache.has("taiko"):
		return cache["taiko"]
	var n := int(0.75 * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / SR
		var f := 58.0 + 90.0 * exp(-t * 26.0)
		ph += TAU * f / SR
		lp += 0.09 * (rng.randf_range(-1.0, 1.0) - lp)
		var x := (sin(ph) * exp(-t * 5.5) * 1.5 + lp * 2.2 * exp(-t * 34.0)) * 1.4
		o[i] = x / (1.0 + absf(x)) * g
	cache["taiko"] = o
	return o

func snare() -> PackedFloat32Array:
	if cache.has("snare"):
		return cache["snare"]
	var n := int(0.24 * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / SR
		var w := rng.randf_range(-1.0, 1.0)
		var hp := w - prev * 0.6
		prev = w
		o[i] = (hp * exp(-t * 22.0) * 0.7 + sin(TAU * 190.0 * t) * exp(-t * 34.0) * 0.6)
	cache["snare"] = o
	return o

func hat() -> PackedFloat32Array:
	if cache.has("hat"):
		return cache["hat"]
	var n := int(0.05 * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var prev := 0.0
	for i in n:
		var w := rng.randf_range(-1.0, 1.0)
		o[i] = (w - prev) * 0.5 * exp(-float(i) / SR * 90.0)
		prev = w
	cache["hat"] = o
	return o

func crash(dur := 2.6) -> PackedFloat32Array:
	var key := "crash%d" % int(dur * 10)
	if cache.has(key):
		return cache[key]
	var n := int(dur * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var prev := 0.0
	for i in n:
		var w := rng.randf_range(-1.0, 1.0)
		o[i] = (w - prev * 0.85) * exp(-float(i) / SR * 2.6)
		prev = w
	cache[key] = o
	return o

func boom(dur := 2.0) -> PackedFloat32Array:
	if cache.has("boom"):
		return cache["boom"]
	var n := int(dur * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / SR
		ph += TAU * (30.0 + 70.0 * exp(-t * 11.0)) / SR
		var x := sin(ph) * exp(-t * 2.4) * 2.6
		o[i] = x / (1.0 + absf(x))
	cache["boom"] = o
	return o

## El "braam" de los tráileres: metales graves y un filtro que se abre
func braam(dur := 2.0) -> PackedFloat32Array:
	var n := int(dur * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	for m in [26, 38, 45, 50, 57]:
		var f := mf(m) / SR
		var p0 := rng.randf()
		var p1 := rng.randf()
		var lp := 0.0
		for i in n:
			var t := float(i) / SR
			p0 = fmod(p0 + f * 0.997, 1.0)
			p1 = fmod(p1 + f * 1.004, 1.0)
			var cut := 180.0 + 2600.0 * minf(t / 0.28, 1.0) * exp(-t * 1.1)
			lp += minf(TAU * cut / SR, 1.0) * (p0 + p1 - 1.0 - lp)
			o[i] += lp * minf(t / 0.015, 1.0) * maxf(0.0, 1.0 - t / dur)
	for i2 in n:
		var x := o[i2] * 0.9
		o[i2] = x / (1.0 + absf(x))
	return o

## Ruido que sube de brillo y volumen hasta el momento de la caída
func riser(dur: float) -> PackedFloat32Array:
	var n := int(dur * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var l := 0.0
	var b := 0.0
	var ph := 0.0
	for i in n:
		var k := float(i) / n
		var f := 2.0 * sin(PI * (180.0 + 6500.0 * k * k) / SR)
		var w := rng.randf_range(-1.0, 1.0)
		l += f * b
		var h := w - l - 0.4 * b
		b += f * h
		ph += TAU * (70.0 + 760.0 * k * k) / SR
		o[i] = (b * 0.8 + sin(ph) * 0.35) * k * k
	return o

func whoosh(dur := 0.32) -> PackedFloat32Array:
	if cache.has("whoosh"):
		return cache["whoosh"]
	var n := int(dur * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var l := 0.0
	var b := 0.0
	for i in n:
		var k := float(i) / n
		var f := 2.0 * sin(PI * (300.0 + 4200.0 * sin(k * PI)) / SR)
		var w := rng.randf_range(-1.0, 1.0)
		l += f * b
		var h := w - l - 0.5 * b
		b += f * h
		o[i] = b * sin(k * PI) * sin(k * PI) * k
	cache["whoosh"] = o
	return o

## Filo metálico para los cortes de armas
func shing() -> PackedFloat32Array:
	if cache.has("shing"):
		return cache["shing"]
	var n := int(0.5 * SR)
	var o := PackedFloat32Array()
	o.resize(n)
	var fq := [2350.0, 3710.0, 5230.0, 7140.0]
	for i in n:
		var t := float(i) / SR
		var s := 0.0
		for q: float in fq:
			s += sin(TAU * q * t)
		o[i] = s * 0.2 * exp(-t * 9.0) * minf(t / 0.002, 1.0)
	cache["shing"] = o
	return o

# ---------------------------------------------------------------------- partitura
func chord_pad(ch: Array, t: float, dur: float, g: float, vowel := "a") -> void:
	for k in range(1, ch.size()):
		put("choir", choir(ch[k], dur, vowel), t, g / 3.0)

func melody(stem: String, notes: Array, beat0: float, g: float, oct_up := 0, vowel := "a") -> void:
	var b := beat0
	for nt: Array in notes:
		var m: float = nt[0] + oct_up
		var d: float = nt[1] * BEAT
		if stem == "brass":
			put(stem, brass(m, d * 0.95), at(b), g)
		elif stem == "choir":
			put(stem, choir(m, d, vowel), at(b), g)
		else:
			put(stem, bell(m), at(b), g)
		b += nt[1]

func _intro() -> void:
	# la nada: un zumbido grave, cuerdas y el coro que crece
	var d1 := drop - 1.9
	put("bass", bass(26, d1 + 0.6), 0.0, 0.22)
	put("strings", strings(50, d1, 900.0, 0.8, 0.8), 0.0, 0.13)
	put("strings", strings(57, d1, 900.0, 0.8, 0.8), 0.0, 0.13)
	chord_pad(DM, 0.2, d1 - 0.4, 0.3, "o")
	put("fx", boom(), 0.0, 0.5)
	# la Pluma, sola, en campana
	var t := 0.15
	for nt: Array in [[74, 0.42], [81, 0.42], [79, 0.21], [77, 0.21], [76, 0.42], [74, 0.9]]:
		put("bell", bell(nt[0]), t, 0.34)
		t += nt[1]
	# la pluma se arranca
	put("drums", taiko(), d1 - 1.2, 0.8)
	put("drums", taiko(), d1 - 0.85, 0.55)
	# braam y subida hasta la caída
	put("brass", braam(), d1, 1.0)
	put("fx", boom(), d1, 1.0)
	put("fx", crash(), d1, 0.4)
	put("fx", riser(drop - d1 - 0.08), d1, 0.8)
	for k in 24:
		# redoble que se acelera y deja un silencio justo antes de caer
		var kk := float(k) / 24.0
		var tk := d1 + 0.25 + (drop - d1 - 0.42) * (1.0 - pow(1.0 - kk, 1.7))
		put("drums", snare(), tk, 0.12 + 0.5 * kk)

func _bar_chord(beat: float) -> Array:
	# compases de 4 pulsos que caen justo en el corte final (el primero solo dura 3)
	var bar := int(floor((beat + 1.0) / 4.0))
	return [DM, BB, CM, AM][bar % 4]

func _body() -> void:
	var last := int(round((total - FIN - drop) / BEAT))
	for bi in last:
		var b := float(bi)
		var ch: Array = _bar_chord(b)
		var first_of_bar := (bi + 1) % 4 == 0 or bi == 0
		var sect := 0
		if bi >= 40:
			sect = 3
		elif bi >= 20:
			sect = 2
		elif bi >= 8:
			sect = 1
		# ostinato de cuerdas en corcheas
		for k in 2:
			var tone: int = ch[2 + ((bi * 2 + k) % 3)]
			put("strings", strings(tone + 12, BEAT * 0.42, 3200.0), at(b + k * 0.5), 0.34 + sect * 0.04)
		# bajo
		if first_of_bar:
			var dur_bar := (3.0 if bi == 0 else 4.0) * BEAT
			put("bass", bass(ch[0], dur_bar * 0.97), at(b), 0.5)
			chord_pad(ch, at(b), dur_bar, 0.28 + sect * 0.1)
			if sect <= 1:
				for k2 in range(1, ch.size()):
					put("brass", brass(ch[k2], BEAT * 0.8), at(b), 0.13)
		elif sect >= 2:
			put("bass", bass(ch[0], BEAT * 0.45), at(b), 0.32)
		# percusión de tráiler
		var pos := (bi + 1) % 4
		if pos == 0 or pos == 2:
			put("drums", taiko(), at(b), 1.0)
		if sect >= 1 and (pos == 1 or pos == 3):
			put("drums", snare(), at(b), 0.42 + sect * 0.05)
			put("drums", taiko(), at(b + 0.5), 0.5)
		if sect >= 2:
			put("drums", hat(), at(b), 0.3)
			put("drums", hat(), at(b + 0.5), 0.2)
		if sect >= 3:
			put("drums", taiko(), at(b + 0.5), 0.45)
	# melodías del juego
	melody("brass", PLUMA, 8.0, 0.34)
	melody("choir", SERAVEL, 24.0, 0.5, 0, "o")
	melody("brass", SERAVEL, 40.0, 0.46)
	melody("choir", SERAVEL, 40.0, 0.6)
	# redobles antes de cada sección
	for sb in [8.0, 20.0, 40.0, float(last)]:
		for k3 in 8:
			put("drums", snare(), at(sb - 2.0 + k3 * 0.25), 0.2 + k3 * 0.06)

func _finale() -> void:
	var t := total - FIN
	put("fx", boom(), t, 1.0)
	put("brass", braam(2.6), t, 0.9)
	put("fx", crash(), t, 0.6)
	put("drums", taiko(), t, 1.0)
	chord_pad(DM, t, 0.7, 0.8)
	for k in range(1, DM.size()):
		put("brass", brass(DM[k], 0.65), t, 0.2)
		put("strings", strings(DM[k] + 12, 0.65, 3400.0, 0.02, 0.3), t, 0.2)
	put("bass", bass(38, 0.7), t, 0.55)
	# el final se abre a modo mayor: la esperanza de la Pluma
	var t2 := t + 0.714
	put("drums", taiko(), t2, 1.0)
	put("fx", crash(), t2, 0.35)
	chord_pad(DMAJ, t2, 3.0, 0.95)
	for k2 in range(1, DMAJ.size()):
		put("brass", brass(DMAJ[k2], 2.2), t2, 0.2)
		put("strings", strings(DMAJ[k2] + 12, 3.0, 2600.0, 0.3, 1.0), t2, 0.26)
	put("bass", bass(38, 3.0), t2, 0.5)
	var tb := t2 + 0.3
	for nt: Array in [[74, 0.42], [81, 0.42], [79, 0.21], [78, 0.21], [76, 0.42], [74, 1.2]]:
		put("bell", bell(nt[0]), tb, 0.3)
		tb += nt[1]

func _cut_fx(cuts: Array) -> void:
	for c: Array in cuts:
		var t: float = c[0]
		var name: String = c[1]
		if t > 0.1 and t != drop:
			put("fx", whoosh(), t - 0.28, 0.5)
		if name.begins_with("art_"):
			put("fx", shing(), t + 0.05, 0.35)
		if c[2]:
			put("fx", boom(), t, 0.65)
			put("fx", crash(1.6), t, 0.22)
	# la caída
	put("fx", boom(), drop, 1.0)
	put("fx", crash(), drop, 0.55)
	put("drums", taiko(), drop, 1.0)

extends Node
## Música con fundido cruzado y efectos de sonido con pool de reproductores.

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current := ""
var _sfx_pool: Array[AudioStreamPlayer] = []
var _cache := {}
var _last_play := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	_cache[path] = s
	return s

func play_music(name: String, fade := 1.2) -> void:
	if name == _current:
		return
	_current = name
	var stream := _load("res://assets/audio/music_%s.ogg" % name)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = not (name in ["victory", "gameover"])
	var old := _music_a
	var nw := _music_b
	_music_a = nw
	_music_b = old
	nw.stream = stream
	nw.volume_db = -40.0
	nw.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nw, "volume_db", linear_to_db(max(0.001, G.music_volume)), fade)
	tw.tween_property(old, "volume_db", -60.0, fade)
	tw.chain().tween_callback(old.stop)

func stop_music(fade := 1.0) -> void:
	_current = ""
	var tw := create_tween()
	tw.tween_property(_music_a, "volume_db", -60.0, fade)
	tw.tween_callback(_music_a.stop)

func refresh_volume() -> void:
	if _music_a.playing:
		_music_a.volume_db = linear_to_db(max(0.001, G.music_volume))

const VOICES := {"Brenna": "brenna", "El Cartógrafo": "carto", "Ozias": "ozias", "Madre Ilse": "ilse", "Nyx": "nyx",
	"Sor Velaria": "velaria", "???": "voz", "Seravel": "seravel", "El Carcelero": "carcelero", "El Coro": "coro"}

## Voz de diálogo propia de cada personaje (pitidos como en Undertale)
func voice(speaker: String) -> void:
	sfx("voice_" + VOICES.get(speaker, "default"), -9.0, 0.05)

func sfx(name: String, vol := 0.0, pitch_var := 0.08) -> void:
	var now := Time.get_ticks_msec()
	if _last_play.get(name, -1000) > now - 25:
		return  # evita apilar el mismo sonido en el mismo frame
	_last_play[name] = now
	var stream := _load("res://assets/audio/sfx_%s.wav" % name)
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol + linear_to_db(max(0.001, G.sfx_volume))
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return

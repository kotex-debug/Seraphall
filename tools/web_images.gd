extends SceneTree
## Prepara docs/img a partir de las capturas (ver tools/web_shots.gd). No se exporta con el juego.
## godot --headless --path . --script res://tools/web_images.gd -- CARPETA_CAPTURAS
## Las imágenes se guardan en WebP: pesan una décima parte que en PNG.

const OUT := "res://docs/img/"

func _init() -> void:
	var src: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "sprites"))
	_cover(src)
	var list_path := src + "/lista.txt"
	if FileAccess.file_exists(list_path):
		for line in FileAccess.get_file_as_string(list_path).split("\n", false):
			var p := line.strip_edges().split(" ", false)
			if p.size() >= 3 and not line.begins_with("#"):
				_shot(src + "/" + p[0], p[1], int(p[2]), p.slice(3))
	_sprites()
	quit()

func _cover(src: String) -> void:
	var bg := Image.load_from_file(src + "/webtitle/t_fondo.png")
	bg.save_webp(ProjectSettings.globalize_path(OUT + "portada.webp"), true, 0.86)
	var small := bg.duplicate() as Image
	small.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	small.save_webp(ProjectSettings.globalize_path(OUT + "portada-960.webp"), true, 0.82)
	# logo con alas para la portada de la web
	var lg := Image.load_from_file(src + "/webtitle/t_logo.png")
	lg.get_region(Rect2i(250, 15, 1420, 335)).save_png(ProjectSettings.globalize_path(OUT + "logo-alas.png"))
	lg.get_region(Rect2i(480, 15, 960, 335)).save_png(ProjectSettings.globalize_path(OUT + "logo.png"))
	# imagen para compartir en redes (1200x630)
	var og := Image.load_from_file(src + "/webtitle/t_logo_fondo.png")
	og.convert(Image.FORMAT_RGB8)
	var cut := og.get_region(Rect2i(0, 0, 1920, 1008))
	cut.resize(1200, 630, Image.INTERPOLATE_LANCZOS)
	cut.save_jpg(ProjectSettings.globalize_path(OUT + "compartir.jpg"), 0.88)

## origen destino ancho [x y w h]
func _shot(path: String, dst: String, width: int, crop: PackedStringArray) -> void:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("falta " + path)
		return
	img.convert(Image.FORMAT_RGB8)
	if dst == "angel":
		img.fill_rect(Rect2i(85, 733, 178, 176), img.get_pixel(300, 925))  # tapa el retrato pequeño del creador
	if crop.size() == 4:
		img = img.get_region(Rect2i(int(crop[0]), int(crop[1]), int(crop[2]), int(crop[3])))
	if img.get_width() != width:
		img.resize(width, int(round(img.get_height() * float(width) / img.get_width())), Image.INTERPOLATE_LANCZOS)
	img.save_webp(ProjectSettings.globalize_path(OUT + dst + ".webp"), true, 0.84)

func _sprites() -> void:
	var spr := "res://assets/sprites/"
	for wid in ["sword", "spear", "scythe", "hammer", "choir", "seravel", "reaper", "staff", "fists", "verdugo", "bow", "mangual", "yunque", "astas", "corona"]:
		_copy(spr + "weapon_%s.png" % wid, "weapon_%s.png" % wid)
	for ic in ["feather", "filo", "ala", "luz", "ceniza", "arconte", "eco", "memory", "phoenix", "scroll", "key", "quest", "tear"]:
		_copy(spr + "icon_%s.png" % ic, "icon_%s.png" % ic)
	for b in ["brenna", "carto", "ozias", "ilse", "nyx", "velaria", "preso", "oso", "archivero", "lirio", "peregrina"]:
		_frame(spr + "bust_%s.png" % b, Rect2i(0, 0, 48, 48), "bust_%s.png" % b)
	for e in ["hueco", "acolito", "planidera", "penitente", "guardia", "musgoso", "nidal", "espino", "lacrima", "ascua", "fundidor", "chispero", "forjador", "cortesano", "caballero", "doncella", "ysolde"]:
		_frame(spr + "enemy_%s.png" % e, Rect2i(0, 0, 48 if e == "ysolde" else 32, 48 if e == "ysolde" else 32), "enemy_%s.png" % e)
	_frame(spr + "enemy_garza.png", Rect2i(0, 0, 38, 28), "enemy_garza.png")
	_frame(spr + "enemy_sabueso.png", Rect2i(0, 0, 38, 28), "enemy_sabueso.png")
	_frame(spr + "enemy_bestia.png", Rect2i(0, 0, 38, 28), "enemy_bestia.png")
	_frame(spr + "enemy_kronagh.png", Rect2i(0, 0, 48, 48), "enemy_kronagh.png")
	_frame(spr + "enemy_orrun.png", Rect2i(0, 0, 64, 64), "boss_orrun.png")
	_frame(spr + "enemy_vulkaris.png", Rect2i(0, 0, 64, 64), "boss_vulkaris.png")
	_copy(spr + "cinematic/carcelero_body.png", "boss_carcelero.png")
	_copy(spr + "cinematic/azrahel_body.png", "boss_azrahel.png")
	_copy(spr + "cinematic/seravel_body.png", "boss_seravel.png")
	_copy(spr + "app_icon.png", "app_icon.png")

func _copy(from: String, name: String) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(from))
	if img:
		img.save_png(ProjectSettings.globalize_path(OUT + "sprites/" + name))

func _frame(from: String, r: Rect2i, name: String) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(from))
	if img:
		img.get_region(r).save_png(ProjectSettings.globalize_path(OUT + "sprites/" + name))

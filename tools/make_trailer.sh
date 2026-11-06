#!/bin/sh
# Monta los vídeos a partir de las tomas rodadas por tools/web_trailer.gd.
#   tools/make_trailer.sh rodar CARPETA        graba trailer.avi (vertical) y trailerh.avi (panorámico)
#   tools/make_trailer.sh vertical CARPETA     escribe CARPETA/Seraphall_trailer_tiktok.mp4 (1080x1920) y docs/video/seraphall-trailer.mp4 (720x1280)
#   tools/make_trailer.sh tiktok CARPETA      escribe CARPETA/Seraphall_TikTok.mp4 (menos de 30 MB, rodado con tools/make_trailer.sh cerca)
#   tools/make_trailer.sh panoramico CARPETA   escribe assets/video/descenso.ogv (acto II de la película de introducción)
# Los cortes están en tools/trailer_cortes.txt y tools/descenso_cortes.txt.
# Necesita Godot 4.7 y FFmpeg (variables GODOT y FFMPEG, o en el PATH).
set -e
MODE="$1"
OUT="$2"
GODOT="${GODOT:-godot}"
FFMPEG="${FFMPEG:-ffmpeg}"
P="$(cd "$(dirname "$0")/.." && pwd)"
A="$P/assets/audio"
BEAT="0.357143"   # música de la parte rápida: 168 pulsos por minuto

rodar() {
	name="$1"; W="$2"; H="$3"; VW="$4"; VH="$5"
	printf '[display]\nwindow/size/viewport_width=%s\nwindow/size/viewport_height=%s\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\nwindow/size/borderless=true\n[editor]\nmovie_writer/mjpeg_quality=0.95\n' "$VW" "$VH" "$W" "$H" > "$P/override.cfg"
	SERAPHALL_SHOTS="$OUT" "$GODOT" --path "$P" --position 0,0 --fixed-fps 30 --write-movie "$OUT/$name.avi" -- --autotest="$name" > "$OUT/$name.log" 2> "$OUT/$name.err" || true
	rm -f "$P/override.cfg"
	grep -c '^TAKE' "$OUT/$name.log"
	# si la ventana deja de dibujarse las tomas salen vacías y el vídeo repetiría el último fotograma
	awk -F'|' '$1 == "TAKE" && $4 <= $3 { print "TOMA VACIA: " $2; mal = 1 } END { exit mal }' "$OUT/$name.log"
}

# Genera el filtro de corte. Acumula el tiempo real para no perder el ritmo al redondear a fotogramas.
# Columnas de la lista: toma desde duración destello golpe [velocidad]. Con fx=1 añade golpe de zoom,
# temblor y desdoblamiento de color en cada corte.
# Escribe en $3 el filtro, en $3.hits los instantes de golpe y en $3.dur la duración total.
montaje() {
	awk -v beat="$BEAT" -v log_file="$OUT/$1.log" -v hits="$3.hits" -v durf="$3.dur" -v fx="$4" '
	BEGIN { FS="|"; while ((getline line < log_file) > 0) { split(line, p, "|"); if (p[1] == "TAKE") st[p[2]] = p[3] } FS=" "; t = 0; n = 0; printf "" > hits }
	/^#/ || NF < 3 { next }
	{
		dur = ($3 ~ /s$/) ? substr($3, 1, length($3) - 1) + 0 : $3 * beat
		hit = ($5 == "golpe")
		vel = ($6 != "") ? $6 + 0 : 1
		if (hit) printf "%d\n", t * 1000 > hits
		a = int(t * 30 + 0.5); t += dur; b = int(t * 30 + 0.5); frames = b - a
		src = int(frames * vel + 0.5)
		f0 = st[$1] + int($2 * 30 + 0.5) + 2
		c = sprintf("[0:v]trim=start_frame=%d:end_frame=%d,setpts=%.4f*(PTS-STARTPTS),fps=30", f0, f0 + src, 1.0 / vel)
		if (fx == 1) {
			z = hit ? 0.11 : 0.045; s = hit ? 9 : 0
			c = c sprintf(",zoompan=z=\x27" "1.012+%g*exp(-in/3.2)" "\x27:x=\x27" "iw/2-(iw/zoom/2)+%d*sin(in*2.1)*exp(-in/5)" "\x27:y=\x27" "ih/2-(ih/zoom/2)+%d*cos(in*1.7)*exp(-in/5)" "\x27:d=1:s=1080x1920:fps=30", z, s, s)
			if (hit) c = c ",format=gbrp,rgbashift=rh=-9:bh=9:enable=\x27" "lt(t,0.2)" "\x27,format=yuv420p"
		}
		if ($4 != "-" && $4 != "") c = c sprintf(",fade=t=in:st=0:d=%s:color=white", $4)
		printf "%s,tpad=stop=-1:stop_mode=clone,trim=end_frame=%d,setpts=PTS-STARTPTS[v%d];\n", c, frames, n
		printf "[0:a]atrim=start=%.4f:end=%.4f,asetpts=PTS-STARTPTS,atempo=%.3f,apad,atrim=0:%.4f[a%d];\n", f0 / 30.0, (f0 + src) / 30.0, vel, frames / 30.0, n
		vl = vl sprintf("[v%d]", n); al = al sprintf("[a%d]", n); n++
	}
	END { printf "%s concat=n=%d:v=1:a=0[vout];\n%s concat=n=%d:v=0:a=1[sfx];\n", vl, n, al, n; printf "%.3f\n", t > durf }' "$2" > "$3"
}

case "$MODE" in
rodar)
	mkdir -p "$OUT"
	rodar trailer 1080 1920 360 640
	rodar trailerh 1920 1080 640 360
	;;
cerca)
	# para TikTok: el mismo guion con la cámara más cerca
	rodar trailerc 1080 1920 360 640
	;;
vertical|tiktok)
	# banda sonora original (tools/gen_trailer_score.gd) con el sonido del juego por debajo
	"$GODOT" --headless --path "$P" --script res://tools/gen_trailer_score.gd -- "$OUT" > /dev/null 2>&1
	TOMA=trailer
	[ "$MODE" = tiktok ] && TOMA=trailerc
	montaje "$TOMA" "$P/tools/trailer_cortes.txt" "$OUT/v.flt" 1
	DUR=$(cat "$OUT/v.flt.dur")
	TRUENO=1900   # cuando se arranca la pluma
	{
		# imagen: resplandor en las luces, color más intenso, viñeta y brasas que suben
		# shortcut: las mezclas "screen" van en RGB (format=gbrp); en YUV tiñen toda la imagen de magenta
		printf '[9:v]format=gbrp,scroll=vertical=0.0017,format=gbrp[brasas];
'
		printf '[vout]format=gbrp,split[base][alto];\n'
		printf '[alto]scale=270:480,curves=all=\x270/0 0.5/0 1/1\x27,gblur=sigma=9,scale=1080:1920:flags=bilinear,format=gbrp[brillo];\n'
		printf '[base][brillo]blend=all_mode=screen:all_opacity=0.5,eq=contrast=1.07:saturation=1.2:brightness=0.015:gamma=1.12,vignette=angle=PI/7,format=gbrp[grado];\n'
		if [ "$MODE" = tiktok ]; then
			cp "$P/assets/fonts/Silkscreen-Bold.ttf" "$OUT/aviso.ttf"
			AV="enable=\x27between(t,$(grep '^# caida' "$P/tools/trailer_cortes.txt" | cut -d' ' -f3),$(awk -v d="$DUR" 'BEGIN { print d - 5.0 }'))\x27"
			printf "[grado][brasas]blend=all_mode=screen:all_opacity=0.65,scale=out_range=tv,format=yuv420p,drawbox=x=130:y=146:w=820:h=70:color=0xff2e4d:t=fill:$AV,drawtext=fontfile=aviso.ttf:text=\x27SERAPHALL · GRATIS EN PC\x27:fontsize=40:fontcolor=white:x=(w-tw)/2:y=161:$AV[vfin];\\n"
		else
			printf '[grado][brasas]blend=all_mode=screen:all_opacity=0.65,scale=out_range=tv,format=yuv420p[vfin];\n'
		fi
		# música: cada grupo con su espacio
		printf '[1:a]aecho=0.9:0.4:28|47:0.16|0.1,pan=stereo|c0=c0|c1=c0,volume=0.8[m0];\n'
		printf '[2:a]aecho=0.85:0.6:45|95|160:0.26|0.2|0.13,pan=stereo|c0=c0|c1=c0,adelay=0|14,volume=0.95[m1];\n'
		printf '[3:a]aecho=0.85:0.65:60|120|210:0.3|0.22|0.15,pan=stereo|c0=c0|c1=c0,adelay=11|0,volume=1.15[m2];\n'
		printf '[4:a]aecho=0.85:0.7:70|150|260:0.34|0.26|0.18,pan=stereo|c0=c0|c1=c0,adelay=0|19,volume=1.3[m3];\n'
		printf '[5:a]pan=stereo|c0=c0|c1=c0,volume=0.5[m4];\n'
		printf '[6:a]aecho=0.8:0.5:40|90:0.2|0.12,pan=stereo|c0=c0|c1=c0,volume=0.6[m5];\n'
		printf '[7:a]aecho=0.85:0.7:90|180|300:0.35|0.25|0.16,pan=stereo|c0=c0|c1=c0,adelay=8|0,volume=0.85[m6];\n'
		printf '[m0][m1][m2][m3][m4][m5][m6]amix=inputs=7:normalize=0:duration=longest,highpass=f=32,equalizer=f=2600:t=q:w=1:g=3,acompressor=threshold=0.4:ratio=2:attack=15:release=200:makeup=1,volume=0.62[musica];\n'
		# sonido del juego, por debajo de la música; truenos en el gancho y en el logo
		printf '[sfx]highpass=f=150,volume=0.34[juego];\n'
		printf '[8:a]asplit=2[tr0][tr1];[tr0]volume=0.8[tr0b];[tr1]adelay=%s:all=1,volume=0.9[tr1b];\n' "$TRUENO"
		printf '[musica][juego][tr0b][tr1b]amix=inputs=4:normalize=0:duration=longest,atrim=0:%s,afade=t=out:st=%s:d=1.6,alimiter=limit=0.89:level=disabled[aout]\n' "$DUR" "$(awk -v d="$DUR" 'BEGIN { print d - 1.6 }')"
	} >> "$OUT/v.flt"
	ENTRADAS="-i $TOMA.avi -i score_drums.wav -i score_strings.wav -i score_brass.wav -i score_choir.wav -i score_bass.wav -i score_fx.wav -i score_bell.wav"
	if [ "$MODE" = tiktok ]; then
		# archivo ligero (menos de 30 MB) para pasarlo al móvil y subirlo desde allí
		( cd "$OUT" && "$FFMPEG" -y -v error $ENTRADAS -i "$A/sfx_thunder.wav" -loop 1 -framerate 30 -t "$DUR" -i embers.png \
			-/filter_complex v.flt -map "[vfin]" -map "[aout]" -r 30 -c:v libx264 -preset slow -b:v 5000k -maxrate 7000k -bufsize 10000k -profile:v high -level 4.2 -pix_fmt yuv420p -color_range tv -c:a aac -b:a 160k -movflags +faststart Seraphall_TikTok.mp4 )
		ls -la "$OUT/Seraphall_TikTok.mp4"
		exit 0
	fi
	( cd "$OUT" && "$FFMPEG" -y -v error $ENTRADAS -i "$A/sfx_thunder.wav" -loop 1 -framerate 30 -t "$DUR" -i embers.png \
		-/filter_complex v.flt -map "[vfin]" -map "[aout]" -r 30 -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart Seraphall_trailer_tiktok.mp4 )
	mkdir -p "$P/docs/video"
	"$FFMPEG" -y -v error -i "$OUT/Seraphall_trailer_tiktok.mp4" -vf scale=720:1280:flags=lanczos -c:v libx264 -preset slow -crf 27 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart "$P/docs/video/seraphall-trailer.mp4"
	ls -la "$OUT/Seraphall_trailer_tiktok.mp4" "$P/docs/video/seraphall-trailer.mp4"
	;;
panoramico)
	# sin textos: el juego los dibuja encima en el idioma del jugador
	montaje trailerh "$P/tools/descenso_cortes.txt" "$OUT/h.flt" 0
	DUR=$(cat "$OUT/h.flt.dur")
	{
		printf '[1:a]volume=0.85,afade=t=out:st=%s:d=1.2[m];\n' "$(awk -v d="$DUR" 'BEGIN { print d - 1.2 }')"
		printf '[m][sfx]amix=inputs=2:normalize=0:duration=longest,atrim=0:%s,alimiter=limit=0.95,aresample=44100[aout];\n' "$DUR"
		printf '[vout]scale=1280:720:flags=lanczos[v720]\n'
	} >> "$OUT/h.flt"
	mkdir -p "$P/assets/video"
	"$FFMPEG" -y -v error -i "$OUT/trailerh.avi" -i "$A/music_boss_seravel3.ogg" -/filter_complex "$OUT/h.flt" -map "[v720]" -map "[aout]" -r 30 -c:v libtheora -b:v 5500k -c:a libvorbis -q:a 4 "$P/assets/video/descenso.ogv"
	ls -la "$P/assets/video/descenso.ogv"
	;;
*)
	echo "uso: make_trailer.sh rodar|vertical|tiktok|panoramico CARPETA"; exit 1 ;;
esac

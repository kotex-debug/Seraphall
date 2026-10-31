shader_type canvas_item;
// Fondo del mundo: el Abismo de la Espiral bajo las ruinas flotantes.
// Nubes de ceniza en remolino, vórtice brillante muy abajo, rocas flotantes a dos profundidades,
// brasas que suben y relámpagos. Usa la posición de la cámara para el parallax.
uniform vec2 cam = vec2(0.0);
uniform vec2 res = vec2(640.0, 360.0);
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float calm = 0.0; // 1 = zona de paz (tonos más suaves y azulados)

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p = p * 2.02 + vec2(3.1, 1.7); a *= 0.5; }
	return v;
}

void fragment() {
	float t = TIME;
	vec2 px = UV * res;
	// capa lejana (parallax lento)
	vec2 far = (px + cam * 0.08) / 220.0;
	vec2 mid = (px + cam * 0.22) / 140.0;
	vec2 near = (px + cam * 0.45) / 90.0;

	vec3 deep = mix(vec3(0.05, 0.02, 0.09), vec3(0.03, 0.05, 0.1), calm);
	vec3 col = deep;

	// remolino de nubes de ceniza (domain warp)
	vec2 w = vec2(fbm(far + vec2(t * 0.02, 0.0)), fbm(far + vec2(5.2, t * 0.015)));
	float clouds = fbm(far * 1.4 + w * 1.6 + vec2(-t * 0.01, t * 0.008));
	vec3 cloud_col = mix(vec3(0.42, 0.13, 0.32), vec3(0.2, 0.25, 0.45), calm);
	col += cloud_col * pow(clouds, 2.2) * 0.9;

	// resplandor del vórtice muy abajo (sigue al mundo con parallax mínimo)
	vec2 vc = (px + cam * 0.05) - vec2(res.x * 0.5, res.y * 1.6) - vec2(-cam.x * 0.05 + 0.0, -cam.y * 0.02);
	float vd = length(vc / vec2(1.6, 1.0));
	vec3 glow_col = mix(vec3(1.0, 0.35, 0.12), vec3(0.45, 0.6, 1.0), calm);
	col += glow_col * exp(-vd / 260.0) * 0.55;
	float sw = sin(atan(vc.y, vc.x) * 4.0 + log(vd + 1.0) * 5.0 - t * 0.6);
	col += glow_col * smoothstep(0.6, 1.0, sw) * exp(-vd / 220.0) * 0.25;

	// nubes cercanas más oscuras que pasan
	float nc = fbm(mid + vec2(t * 0.05, t * 0.01));
	col = mix(col, col * 0.45, smoothstep(0.55, 0.8, nc) * 0.7);
	col += cloud_col * 0.25 * smoothstep(0.5, 0.75, nc) * (1.0 - smoothstep(0.75, 0.9, nc));

	// rocas flotantes (siluetas con borde iluminado)
	for (int layer = 0; layer < 2; layer++) {
		float fl = float(layer);
		vec2 q = (layer == 0 ? mid : near) * vec2(1.0, 1.6) + vec2(0.0, sin(t * 0.3 + fl) * 0.05);
		vec2 cell = floor(q);
		vec2 f = fract(q);
		float h = hash(cell + fl * 17.0);
		if (h > 0.72) {
			vec2 c = vec2(0.3 + 0.4 * hash(cell + 3.0), 0.3 + 0.4 * hash(cell + 9.0));
			vec2 d = (f - c) / vec2(0.32, 0.18) * (0.8 + 0.4 * h);
			float rock = length(d) + (noise(f * 9.0 + cell) - 0.5) * 0.45 + max(0.0, d.y) * 0.6;
			float inside = smoothstep(1.0, 0.92, rock);
			float rim = smoothstep(0.8, 1.0, rock) * inside * smoothstep(0.1, -0.4, d.y);
			vec3 rc = mix(vec3(0.04, 0.02, 0.06), vec3(0.08, 0.06, 0.12), fl);
			col = mix(col, rc, inside * (0.8 + fl * 0.2));
			col += glow_col * rim * 0.35;
		}
	}

	// brasas / motas que suben
	vec2 ep = (px + cam * 0.3) / 6.0 + vec2(0.0, t * 3.0);
	vec2 ec = floor(ep);
	float eh = hash(ec);
	if (eh > 0.993) {
		vec2 ef = fract(ep) - 0.5;
		float tw = 0.5 + 0.5 * sin(t * 4.0 + eh * 60.0);
		col += mix(vec3(1.0, 0.55, 0.2), vec3(0.6, 0.85, 1.0), calm) * smoothstep(0.35, 0.0, length(ef)) * tw * 0.9;
	}

	// relámpago lejano
	float lt = floor(t * 0.7);
	float fl2 = step(0.9, hash(vec2(lt, 1.0))) * pow(1.0 - fract(t * 0.7), 4.0) * (1.0 - calm);
	col += vec3(0.55, 0.4, 0.9) * fl2 * pow(clouds, 1.5) * 0.8;

	COLOR = vec4(col * tint.rgb, 1.0);
}

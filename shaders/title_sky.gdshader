shader_type canvas_item;
// Cielo de la pantalla de título: nebulosa, estrellas, aureola rota con rayos divinos,
// la Espiral (vórtice) al fondo, niebla y relámpagos lejanos. Todo animado.
uniform vec2 res = vec2(640.0, 360.0);
uniform vec2 parallax = vec2(0.0);
uniform float intensity = 1.0;
uniform float halo_y = 0.3;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	float asp = res.x / res.y;
	vec2 p = (uv - vec2(0.5, 0.0)) * vec2(asp, 1.0) + parallax * 0.02;
	float y = uv.y;

	// degradado del cielo
	vec3 top = vec3(0.035, 0.02, 0.09);
	vec3 mid = vec3(0.2, 0.06, 0.22);
	vec3 hor = vec3(0.85, 0.3, 0.16);
	vec3 col = mix(top, mid, smoothstep(0.0, 0.55, y));
	col = mix(col, hor, smoothstep(0.42, 0.7, y) * (1.0 - smoothstep(0.82, 1.0, y)) * 0.9);

	// nebulosa en movimiento
	float n = fbm(p * 2.6 + vec2(t * 0.018, -t * 0.006));
	float n2 = fbm(p * 5.0 + vec2(-t * 0.03, t * 0.012) + n * 1.5);
	col += vec3(0.5, 0.14, 0.45) * pow(n2, 2.2) * (1.0 - smoothstep(0.55, 0.85, y)) * 1.5;
	col += vec3(0.65, 0.26, 0.14) * pow(n, 3.2) * smoothstep(0.25, 0.7, y);
	col += vec3(0.12, 0.08, 0.3) * pow(fbm(p * 1.3 + t * 0.01), 2.0) * 0.6;

	// estrellas que titilan
	vec2 sp = (uv + parallax * 0.004) * res / 1.6;
	vec2 cell = floor(sp);
	float h = hash(cell);
	if (h > 0.982) {
		vec2 f = fract(sp) - 0.5 + (vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5) * 0.5;
		float tw = 0.55 + 0.45 * sin(t * (1.5 + h * 6.0) + h * 50.0);
		float s = smoothstep(0.22, 0.0, length(f)) + smoothstep(0.5, 0.0, abs(f.x)) * smoothstep(0.06, 0.0, abs(f.y)) * 0.4 * step(0.996, h);
		col += vec3(0.95, 0.88, 1.0) * s * tw * (1.0 - smoothstep(0.35, 0.65, y));
	}

	// aureola rota en el cielo
	vec2 hc = p - vec2(0.0, halo_y);
	float r = length(hc);
	float ang = atan(hc.y, hc.x);
	float R = 0.19 + 0.003 * sin(t * 1.3);
	float a2 = ang + t * 0.04;
	float gaps = smoothstep(-0.08, 0.08, sin(a2 * 3.0 + 1.3) * 0.55 + sin(a2 * 7.0 - 0.4) * 0.35 + 0.55);
	float ring = smoothstep(0.01, 0.0, abs(r - R));
	float glow = exp(-abs(r - R) * 26.0);
	float flicker = 0.85 + 0.15 * sin(t * 2.3) * sin(t * 3.7);
	col += vec3(1.0, 0.8, 0.42) * (ring * 1.6 + glow * 0.7) * gaps * flicker * intensity;
	col += vec3(1.0, 0.65, 0.35) * exp(-abs(r - R * 0.84) * 90.0) * 0.35 * gaps;
	col += vec3(1.0, 0.85, 0.6) * exp(-abs(r - R * 1.18) * 120.0) * 0.18 * (1.0 - gaps * 0.5);
	// esquirlas sueltas de la aureola
	for (int i = 0; i < 6; i++) {
		float fi = float(i);
		float sa = fi * 1.07 + t * (0.05 + fi * 0.01);
		vec2 sh = vec2(cos(sa), sin(sa)) * (R + 0.03 + 0.02 * sin(t * 0.7 + fi));
		col += vec3(1.0, 0.85, 0.5) * smoothstep(0.006, 0.0, length(hc - sh)) * 0.9;
	}
	// rayos divinos hacia abajo
	float ra = atan(hc.x, hc.y);
	float rays = pow(max(0.0, sin(ra * 13.0 + noise(vec2(ra * 5.0, t * 0.25)) * 4.0)), 5.0);
	float rmask = smoothstep(R, R + 0.06, r) * exp(-r * 2.0) * smoothstep(-0.25, 0.55, hc.y);
	col += vec3(1.0, 0.72, 0.42) * rays * rmask * 0.42 * intensity;
	col += vec3(1.0, 0.82, 0.58) * exp(-r * 8.0) * 0.4 * intensity;

	// la Espiral (vórtice en perspectiva)
	vec2 vp = p - vec2(0.0, 0.8);
	vp.y /= 0.22;
	vp *= 1.25;
	float vr = length(vp);
	float va = atan(vp.y, vp.x);
	float spiral = sin(va * 5.0 + log(vr + 0.001) * 9.0 - t * 1.1);
	float rings = sin(log(vr + 0.001) * 26.0 - t * 2.4);
	float vmask = smoothstep(1.4, 0.25, vr) * smoothstep(0.08, 0.3, vr);
	col += vec3(0.95, 0.28, 0.12) * smoothstep(0.55, 1.0, spiral) * vmask * 0.6;
	col += vec3(0.75, 0.2, 0.45) * smoothstep(0.85, 1.0, rings) * vmask * 0.35;
	col = mix(col, vec3(0.0), smoothstep(0.32, 0.02, vr) * 0.96);
	col += vec3(1.0, 0.35, 0.1) * exp(-abs(vr - 0.33) * 20.0) * 0.35;

	// niebla a la deriva
	float fog = fbm(vec2(p.x * 2.2 + t * 0.035, y * 5.0 - t * 0.01));
	col += vec3(0.4, 0.13, 0.16) * fog * smoothstep(0.5, 0.8, y) * (1.0 - smoothstep(0.88, 1.0, y)) * 0.7;

	// relámpago lejano ocasional
	float lt = floor(t * 1.5);
	float fl = step(0.93, hash(vec2(lt, 3.0))) * pow(1.0 - fract(t * 1.5), 3.0);
	col += vec3(0.55, 0.45, 0.95) * fl * 0.55 * pow(n2, 1.3) * (1.0 - smoothstep(0.4, 0.7, y));

	// viñeta
	col *= 1.0 - 0.6 * pow(length((uv - 0.5) * vec2(1.15, 1.0)), 2.2);
	COLOR = vec4(col, 1.0);
}

shader_type canvas_item;
// Barra "líquida": fluido animado, menisco brillante, rastro de daño, segmentos y pulso.
uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform float trail : hint_range(0.0, 1.0) = 1.0;
uniform vec4 col_deep : source_color = vec4(0.4, 0.02, 0.08, 1.0);
uniform vec4 col_bright : source_color = vec4(1.0, 0.25, 0.3, 1.0);
uniform vec4 trail_col : source_color = vec4(1.0, 0.92, 0.75, 1.0);
uniform vec4 empty_col : source_color = vec4(0.07, 0.035, 0.08, 1.0);
uniform float pulse = 0.0;
uniform float segments = 0.0;
uniform float flow_speed = 1.0;
uniform float tip = 4.0;
uniform vec2 size = vec2(150.0, 10.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 px = floor(UV * size) + 0.5;
	vec2 uv = px / size;
	float cy = abs(uv.y - 0.5) * 2.0;
	// extremos en punta (forma de hoja)
	if (px.x < tip * cy || px.x > size.x - tip * cy) {
		discard;
	}
	float wave = (noise(vec2(px.y * 0.35, TIME * 3.0)) - 0.5) * 2.5 / size.x;
	float edge = fill + wave * step(0.001, fill) * step(fill, 0.999);
	vec3 col = empty_col.rgb + 0.035 * noise(px * 0.35 + vec2(TIME * 0.6, 0.0));
	float a = 1.0;
	if (uv.x >= edge && uv.x < trail) {
		col = trail_col.rgb * (0.82 + 0.18 * sin(TIME * 24.0));
	}
	if (uv.x < edge) {
		float n = noise(vec2(px.x * 0.12 - TIME * 2.2 * flow_speed, px.y * 0.45));
		float n2 = noise(vec2(px.x * 0.35 - TIME * 3.6 * flow_speed, px.y * 0.8 + 7.0));
		float v = 1.0 - uv.y;
		vec3 c = mix(col_deep.rgb, col_bright.rgb, clamp(0.3 + 0.45 * n + 0.4 * v * v, 0.0, 1.0));
		c += vec3(0.22) * step(0.82, n2);
		c += vec3(0.4) * smoothstep(0.8, 1.0, v) * (0.6 + 0.4 * n);
		float d = (edge - uv.x) * size.x;
		c += col_bright.rgb * 1.1 * smoothstep(5.0, 0.0, d);
		c += vec3(1.0) * 0.5 * smoothstep(1.5, 0.0, d);
		c += col_bright.rgb * pulse * (0.45 + 0.45 * sin(TIME * 10.0));
		col = c;
	}
	if (segments > 0.0) {
		float seg_w = size.x / segments;
		float s = mod(px.x, seg_w);
		if (s < 1.0 && px.x > 2.0) { col *= 0.3; }
	}
	col *= 0.78 + 0.22 * (1.0 - uv.y * 0.7);
	COLOR = vec4(col, a * COLOR.a);
}

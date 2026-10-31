shader_type canvas_item;
// Texto dorado con degradado vertical y destello que recorre las letras.
uniform float height = 40.0;
uniform float width = 300.0;
uniform vec4 top_col : source_color = vec4(1.0, 0.98, 0.88, 1.0);
uniform vec4 mid_col : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform vec4 bot_col : source_color = vec4(0.7, 0.34, 0.14, 1.0);
uniform float shine_speed = 0.25;
uniform float shine_strength = 0.9;
varying vec2 lpos;

void vertex() {
	lpos = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	float lum = dot(c.rgb, vec3(0.333));
	if (lum > 0.55) {
		float t = clamp(lpos.y / max(height, 1.0), 0.0, 1.0);
		vec3 g = t < 0.5 ? mix(top_col.rgb, mid_col.rgb, t * 2.0) : mix(mid_col.rgb, bot_col.rgb, (t - 0.5) * 2.0);
		float p = fract(TIME * shine_speed) * (width + 260.0) - 130.0;
		float d = abs(lpos.x + lpos.y * 0.6 - p);
		float shine = smoothstep(16.0, 0.0, d) * shine_strength;
		c.rgb = g + vec3(shine);
	}
	COLOR = c;
}

shader_type canvas_item;
// Post-procesado del juego: ondas de choque, aberración cromática, desaturación, tinte, peligro y gradación.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 w0 = vec4(0.0);
uniform vec4 w1 = vec4(0.0);
uniform vec4 w2 = vec4(0.0);
uniform vec4 w3 = vec4(0.0);
uniform float chroma = 0.0;
uniform float desat = 0.0;
uniform vec4 tint : source_color = vec4(0.5, 0.7, 1.0, 0.0);
uniform float danger = 0.0;
uniform float aspect = 1.7778;

vec2 wave(vec2 uv, vec4 w) {
	if (w.w <= 0.0) { return vec2(0.0); }
	vec2 d = uv - w.xy;
	d.x *= aspect;
	float l = length(d);
	float f = smoothstep(0.035, 0.0, abs(l - w.z));
	vec2 dir = l > 0.0001 ? d / l : vec2(0.0);
	dir.x /= aspect;
	return dir * f * w.w * 0.025;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = wave(uv, w0) + wave(uv, w1) + wave(uv, w2) + wave(uv, w3);
	uv -= off;
	vec2 ca = (uv - 0.5) * (chroma * 0.014 + length(off) * 0.6);
	vec3 c;
	c.r = texture(screen_tex, uv + ca).r;
	c.g = texture(screen_tex, uv).g;
	c.b = texture(screen_tex, uv - ca).b;
	float g = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(g), desat);
	c = mix(c, c * tint.rgb * 1.7, tint.a);
	c = (c - 0.5) * 1.07 + 0.5;
	c += vec3(0.012, 0.0, 0.02);
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 1.25);
	float vig = dot(d, d);
	c = mix(c, vec3(0.55, 0.0, 0.05), danger * smoothstep(0.1, 0.42, vig) * (0.55 + 0.45 * sin(TIME * 6.5)));
	COLOR = vec4(c, 1.0);
}

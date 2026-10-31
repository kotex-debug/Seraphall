shader_type canvas_item;
// Fondo de menú: desenfoca el juego, lo desatura y lo tiñe.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.05, 0.02, 0.08, 0.72);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * 3.0 * amount;
	vec3 c = vec3(0.0);
	float ws = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			float w = exp(-float(x * x + y * y) / 6.0);
			c += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px).rgb * w;
			ws += w;
		}
	}
	c /= ws;
	float g = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(g), 0.55 * amount);
	c = mix(c, tint.rgb, tint.a * amount);
	vec2 d = UV - 0.5;
	c *= 1.0 - 0.8 * dot(d, d) * amount;
	COLOR = vec4(c, 1.0);
}

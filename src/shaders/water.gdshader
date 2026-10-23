shader_type canvas_item;
// Placeholder water: a depth gradient with soft moving caustic lines.

uniform vec4 shallow_color : source_color = vec4(0.22, 0.64, 0.80, 1.0);
uniform vec4 deep_color : source_color = vec4(0.08, 0.33, 0.56, 1.0);
uniform vec4 caustic_color : source_color = vec4(0.75, 0.95, 1.0, 1.0);
uniform float caustic_strength = 0.16;
uniform float caustic_scale = 5.0;
// Rect height / width, so the pattern is not stretched.
uniform float aspect = 1.78;

float caustic_lines(vec2 p, float t) {
	float a = sin(p.x * 1.3 + t * 0.8 + sin(p.y * 1.7 + t * 0.5) * 1.2);
	float b = sin(p.y * 1.1 - t * 0.6 + sin(p.x * 1.9 - t * 0.4) * 1.2);
	float c = abs(a + b) * 0.5;
	return pow(1.0 - clamp(c, 0.0, 1.0), 8.0);
}

void fragment() {
	vec2 p = vec2(UV.x, UV.y * aspect) * caustic_scale;
	float lines = caustic_lines(p, TIME) + 0.6 * caustic_lines(p * 1.7 + 3.1, TIME * 1.3);
	vec3 base = mix(shallow_color.rgb, deep_color.rgb, UV.y);
	COLOR = vec4(mix(base, caustic_color.rgb, clamp(lines * caustic_strength, 0.0, 1.0)), 1.0);
}

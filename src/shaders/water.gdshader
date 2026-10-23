shader_type canvas_item;
// Beach, seabed and water of a fishing spot in 2:1 isometric projection, following the camera.
// Works in ground coordinates, so the tile grid and caustics follow the perspective.
// Must match Iso (src/scenes/world/iso.gd).

// Screen size of this rect, the screen position of the world origin, and the world zoom.
uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform vec2 world_origin = vec2(0.0, 0.0);
uniform float zoom = 1.0;
// Ground y of the waterline; the beach is where ground y is smaller.
uniform float shore_y = 0.0;
// Ground y beyond which the beach turns into dunes.
uniform float dunes_y = -760.0;
uniform float tile_size = 140.0;
uniform float depth_range = 1600.0;
uniform vec4 sand_color : source_color = vec4(0.95, 0.85, 0.6, 1.0);
uniform vec4 wet_sand_color : source_color = vec4(0.8, 0.69, 0.47, 1.0);
uniform vec4 dune_color : source_color = vec4(0.82, 0.78, 0.5, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.32, 0.78, 0.8, 1.0);
uniform vec4 deep_color : source_color = vec4(0.07, 0.33, 0.55, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

vec2 to_ground(vec2 screen) {
	float a = screen.x / 0.70710678;
	float b = screen.y / 0.35355339;
	return vec2(a + b, b - a) * 0.5;
}

float caustic_lines(vec2 p, float t) {
	float a = sin(p.x * 1.3 + t * 0.8 + sin(p.y * 1.7 + t * 0.5) * 1.2);
	float b = sin(p.y * 1.1 - t * 0.6 + sin(p.x * 1.9 - t * 0.4) * 1.2);
	return pow(1.0 - clamp(abs(a + b) * 0.5, 0.0, 1.0), 8.0);
}

void fragment() {
	vec2 g = to_ground((UV * rect_size - world_origin) / zoom);
	// Distance from the waterline into the water, with gently lapping waves.
	float wave = sin(g.x * 0.02 + TIME * 1.5) * 10.0 + sin(g.x * 0.05 - TIME) * 5.0;
	float d = g.y - shore_y + wave;

	vec2 cell = abs(fract(g / tile_size) - 0.5);
	float grid = smoothstep(0.46, 0.5, max(cell.x, cell.y));

	vec3 color;
	if (d < 0.0) {
		color = mix(sand_color.rgb, wet_sand_color.rgb, smoothstep(-70.0, 0.0, d));
		color = mix(color, dune_color.rgb, smoothstep(dunes_y + 40.0, dunes_y - 40.0, g.y));
		color *= 1.0 - grid * 0.06;
	} else {
		float depth = clamp(d / depth_range, 0.0, 1.0);
		color = mix(shallow_color.rgb, deep_color.rgb, pow(depth, 0.7));
		// The seabed tiles show through where the water is shallow.
		color *= 1.0 - grid * 0.12 * (1.0 - depth);
		float caustics = caustic_lines(g / 160.0, TIME) + 0.6 * caustic_lines(g / 95.0 + 3.1, TIME * 1.3);
		color = mix(color, vec3(0.85, 1.0, 1.0), clamp(caustics * 0.16 * (1.0 - depth * 0.6), 0.0, 1.0));
		color = mix(color, foam_color.rgb, (1.0 - smoothstep(0.0, 24.0, d)) * 0.85);
	}
	COLOR = vec4(color, 1.0);
}

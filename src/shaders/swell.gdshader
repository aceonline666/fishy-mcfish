shader_type canvas_item;
// The heavy swell of the open sea (the last two zones of a spot), on the water's surface: drawn
// over the fish, the seabed props and the swimming wader, below the buoy lines (Layers.SURFACE).
// From swell_start (distance from the waterline) it builds up over SWELL_BUILD and rolls towards
// the shore: lit slopes, dark troughs and small whitecaps along the crests. Premultiplied alpha:
// what lies below is darkened in the troughs and covered by the light and the foam.
// Must match Iso (src/scenes/world/iso.gd) and water.gdshader.
render_mode blend_premul_alpha;

// Screen position and size of this rect, the screen position of the world origin, the world zoom.
uniform vec2 rect_pos = vec2(0.0, 0.0);
uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform vec2 world_origin = vec2(0.0, 0.0);
uniform float zoom = 1.0;
// Ground y of the waterline.
uniform float shore_y = 0.0;
uniform float swell_start = 1.0e9;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
const float SWELL_BUILD = 1400.0;

// 0 to 1, the look of rolling swell at ground point g: long crests coming in towards the shore,
// two trains crossing, bent by a slow sideways wobble.
float swell_height(vec2 g, float t) {
	float a = sin(g.y * 0.011 + t * 1.2 + sin(g.x * 0.0026 + t * 0.15) * 2.2);
	float b = sin((g.y * 0.8 + g.x * 0.55) * 0.0085 + t * 0.85);
	return (a * 0.65 + b * 0.35) * 0.5 + 0.5;
}

vec2 to_ground(vec2 screen) {
	float a = screen.x / 0.70710678;
	float b = screen.y / 0.35355339;
	return vec2(a + b, b - a) * 0.5;
}

void fragment() {
	vec2 g = to_ground((rect_pos + UV * rect_size - world_origin) / zoom);
	float wave = sin(g.x * 0.02 + TIME * 1.5) * 10.0 + sin(g.x * 0.05 - TIME) * 5.0;
	float d = g.y - shore_y + wave;
	float swell = smoothstep(swell_start - 200.0, swell_start + SWELL_BUILD, d);
	float h = swell_height(g, TIME);
	vec3 light = vec3(0.04, 0.09, 0.13) * smoothstep(0.4, 1.0, h) * swell;
	float dark = swell * (1.0 - h) * 0.3;
	float flecks = sin(g.x * 0.13 + sin(g.y * 0.09) * 3.0) * sin(g.y * 0.17 - g.x * 0.05 + TIME * 0.6);
	float foam = smoothstep(0.86, 0.98, h) * smoothstep(0.45, 0.9, flecks) * swell * 0.55;
	// result = mix(below * (1 - dark) + light, foam_color, foam)
	COLOR = vec4(light * (1.0 - foam) + foam_color.rgb * foam, 1.0 - (1.0 - dark) * (1.0 - foam));
}

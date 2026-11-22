shader_type canvas_item;
// The sun or the moon mirrored on the water's surface (Mirror, reflection.gdshaderinc): drawn over
// the fish (and over the wader while it swims), only on the water, fading out into the abyss.
// The rect covers just the mirrored light and its glints. Premultiplied alpha.
// Works in ground coordinates like water.gdshader: keep to_ground in step with Iso.
render_mode blend_premul_alpha;

// Screen position and size of this rect, the screen position of the world origin, the world zoom.
uniform vec2 rect_pos = vec2(0.0, 0.0);
uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform vec2 world_origin = vec2(0.0, 0.0);
uniform float zoom = 1.0;
// Ground y of the waterline.
uniform float shore_y = 0.0;
uniform float abyss_start = 3000.0;
uniform float abyss_end = 6600.0;

vec2 to_ground(vec2 screen) {
	float a = screen.x / 0.70710678;
	float b = screen.y / 0.35355339;
	return vec2(a + b, b - a) * 0.5;
}

#include "res://src/shaders/reflection.gdshaderinc"
#include "res://src/shaders/waves.gdshaderinc"

void fragment() {
	vec2 world = (rect_pos + UV * rect_size - world_origin) / zoom;
	vec2 g = to_ground(world);
	// The waterline laps like water.gdshader's.
	float d = g.y - shore_y + shore_wave(g);
	vec2 light = mirrored_light(world, g, TIME) * smoothstep(0.0, 60.0, d) * (1.0 - smoothstep(abyss_start, abyss_end, d));
	// result = mix(mix(below, colour, halo), colour, light)
	float alpha = 1.0 - (1.0 - light.x) * (1.0 - light.y);
	COLOR = vec4(glint_color.rgb * alpha, alpha);
}

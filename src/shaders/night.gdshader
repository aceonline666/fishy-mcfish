shader_type canvas_item;
render_mode blend_mul, unshaded;
// The time of day over the whole world (DayClock, src/scenes/world/night.gd): multiplied over
// everything below the HUD. White by day, gold at dusk, moonlit blue at night. The deep sea is
// dark already, so the tint fades out with the abyss (SeaDepth). Lamps light pools on the ground,
// in warm light, the sun or the moon on the water shines through, and the submarine's spotlight lights its cone.
// Works in ground coordinates like water.gdshader: keep to_ground in step with Iso.

uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform vec2 world_origin = vec2(0.0, 0.0);
uniform float zoom = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
// 0 by day to 1 at night: how bright the lamps' pools are.
uniform float darkness = 0.0;
// Ground y of the waterline: the sun or the moon mirrored on the water beyond it shines through
// the tint (reflection.gdshaderinc, Mirror), except where the wading wader stands in front of it
// (a screen rect: position, size).
uniform float shore_y = 0.0;
uniform vec4 mirror_hole = vec4(0.0);
uniform float abyss_start = 3000.0;
uniform float abyss_end = 6600.0;
// How much of the night tint is left at the abyss's darkest.
const float ABYSS_KEEP = 0.25;
// Pools of light: ground x and y, radius (ground units), strength; and each pool's colour.
const int MAX_LIGHTS = 16;
uniform vec4 lights[MAX_LIGHTS];
uniform vec4 light_colors[MAX_LIGHTS] : source_color;
uniform int light_count = 0;
#include "res://src/shaders/spotlight.gdshaderinc"

vec2 to_ground(vec2 screen) {
	float a = screen.x / 0.70710678;
	float b = screen.y / 0.35355339;
	return vec2(a + b, b - a) * 0.5;
}

#include "res://src/shaders/reflection.gdshaderinc"

void fragment() {
	vec2 g = to_ground((UV * rect_size - world_origin) / zoom);
	float deep = smoothstep(abyss_start, abyss_end, g.y);
	vec3 shade = mix(vec3(1.0), tint.rgb, mix(1.0, ABYSS_KEEP, deep));
	vec3 lit = shade;
	for (int i = 0; i < light_count; i++) {
		vec4 l = lights[i];
		float d = length(g - l.xy) / l.z;
		float pool = (1.0 - smoothstep(0.15, 1.0, d)) * l.w * darkness;
		lit = max(lit, mix(shade, light_colors[i].rgb, pool));
	}
	float beam = spotlight(g) * darkness;
	lit = max(lit, mix(shade, vec3(1.0), beam * 0.8));
	vec2 screen = UV * rect_size;
	vec2 in_hole = step(mirror_hole.xy, screen) * step(screen, mirror_hole.xy + mirror_hole.zw);
	if (glint_color.a > 0.0 && g.y > shore_y + 60.0 && in_hole.x * in_hole.y == 0.0) {
		float mirrored = mirrored_light((screen - world_origin) / zoom, g, TIME).x * (1.0 - deep);
		lit = max(lit, mix(shade, vec3(1.0), mirrored));
	}
	COLOR = vec4(lit, 1.0);
}

shader_type canvas_item;
render_mode blend_add, unshaded;
// A glowing beach at night (GlowingShore): the edge of each wave lights up blue as it runs up the
// sand, brightest while it breaks, the surf behind it glows faintly, and sparks twinkle on the wet
// sand and in the shallows. Drawn on a strip along the waterline, in the world's coordinates.
// Must match Iso (src/scenes/world/iso.gd) and the waterline of water.gdshader (waves.gdshaderinc).

uniform float shore_y = 0.0;
// 0 by day to 1 at night.
uniform float strength = 1.0;
// No glow over the pier (ground x from, to; it runs out over the waterline) nor over the wader
// standing in front of it (a rect in the world: position, size).
uniform vec2 pier = vec2(0.0, 0.0);
uniform vec4 hole = vec4(0.0);
// How softly the glow ends at the pier's sides (ground units).
const float PIER_EDGE = 24.0;
#include "res://src/shaders/waves.gdshaderinc"

// Night.SEA_SPARKLE.
const vec3 GLOW = vec3(0.3, 0.85, 1.0);
// Sparks: one place per cell of this many ground units, only in some cells.
const float SPARK_CELL = 18.0;

varying vec2 ground;
varying vec2 world;

vec2 to_ground(vec2 screen) {
	float a = screen.x / 0.70710678;
	float b = screen.y / 0.35355339;
	return vec2(a + b, b - a) * 0.5;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	ground = to_ground(VERTEX);
	world = VERTEX;
}

void fragment() {
	vec2 g = ground;
	// Into the water from its edge (> 0 is water), as in water.gdshader.
	float d = g.y - shore_y + shore_wave(g);
	// How fast the water runs up the beach here (shore_wave over wave_time): a breaking wave.
	float rush = (cos(g.x * 0.02 + wave_time * 1.5) * 15.0 - cos(g.x * 0.05 - wave_time) * 5.0) * wave_amp;
	float breaking = 0.25 + 0.75 * smoothstep(-4.0, 14.0, rush);
	float front = smoothstep(-6.0, 2.0, d) * (1.0 - smoothstep(2.0, 46.0, d));
	float surf = step(0.0, d) * (1.0 - smoothstep(0.0, 140.0, d)) * 0.12;
	vec2 cell = floor(g / SPARK_CELL);
	float h = hash(cell);
	vec2 spot = fract(g / SPARK_CELL) - 0.5 - (vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5) * 0.6;
	float dot_shape = 1.0 - smoothstep(0.07, 0.18, length(spot));
	float twinkle = pow(max(sin(TIME * (1.5 + h * 3.0) + h * 40.0), 0.0), 6.0);
	float wet = smoothstep(-80.0, -25.0, d) * (1.0 - smoothstep(10.0, 100.0, d));
	float sparks = dot_shape * twinkle * wet * step(0.55, h);
	float light = (front * breaking * 0.85 + surf + sparks) * strength;
	light *= 1.0 - smoothstep(pier.x - PIER_EDGE, pier.x, g.x) * (1.0 - smoothstep(pier.y, pier.y + PIER_EDGE, g.x));
	vec2 in_hole = step(hole.xy, world) * step(world, hole.xy + hole.zw);
	light *= 1.0 - in_hole.x * in_hole.y;
	COLOR = vec4(GLOW, clamp(light, 0.0, 1.0));
}

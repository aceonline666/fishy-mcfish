shader_type canvas_item;
// Raindrops hitting the water (RainRings, Weather): one quad per ring in a MultiMesh, moved
// entirely here. Each ring lives LIFE seconds, then starts again somewhere else: its place is a
// hash of its instance and its round. It lies at a fixed point of the world, picked in the view
// (wrapped into it, so a ring only jumps when the view has moved past it), and only on the water.
// Drawn in the world's coordinates on the water's surface.
// Works in ground coordinates like water.gdshader: keep to_ground in step with Iso.

// The part of the world on screen (world coordinates, before zoom).
uniform vec2 view_pos = vec2(0.0, 0.0);
uniform vec2 view_size = vec2(1080.0, 1920.0);
// Ground y of the waterline: no rings on the sand.
uniform float shore_y = 0.0;
uniform float strength = 1.0;
const float LIFE = 0.7;
// The ring's radius at the end (world units); rings vary a little.
const float RADIUS = 26.0;

varying float v_age;

vec2 to_ground(vec2 screen) {
	float a = screen.x / 0.70710678;
	float b = screen.y / 0.35355339;
	return vec2(a + b, b - a) * 0.5;
}

vec2 ring_hash(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void vertex() {
	float id = float(INSTANCE_ID) + 1.0;
	float phase = TIME / LIFE + ring_hash(vec2(id, 0.37)).x;
	float round_number = floor(phase);
	v_age = fract(phase);
	vec2 h = ring_hash(vec2(id, round_number));
	vec2 at = view_pos + mod(h * view_size - view_pos, view_size);
	float size = RADIUS * mix(0.7, 1.2, ring_hash(vec2(round_number, id)).x);
	// Flat on the water, twice as wide as deep (Iso); none on the beach.
	if (to_ground(at).y < shore_y + 40.0) {
		size = 0.0;
	}
	VERTEX = at + (UV - 0.5) * vec2(2.0, 1.0) * size * 2.0;
}

void fragment() {
	float grow = 1.0 - pow(1.0 - v_age, 3.0);
	float d = length((UV - 0.5) * 2.0);
	float ring = 1.0 - smoothstep(0.0, mix(0.06, 0.14, v_age), abs(d - mix(0.15, 0.95, grow)));
	// A smaller ring follows the first.
	float inner = 1.0 - smoothstep(0.0, 0.08, abs(d - mix(0.0, 0.55, grow)));
	float alpha = (ring + inner * 0.5 * step(0.15, v_age)) * (1.0 - v_age) * 0.55 * strength;
	COLOR = vec4(1.0, 1.0, 1.0, clamp(alpha, 0.0, 1.0));
}

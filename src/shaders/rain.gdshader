shader_type canvas_item;
// Rain or snow falling over the screen (Rain, Weather): one quad per drop in a MultiMesh, moved
// entirely here, so the drops cost the CPU nothing. Each drop's place, speed and size come from
// a hash of its instance; it falls through the view and comes in again at the top. They drift a
// little with the camera (scroll), so they seem to fall over the world. Rain streaks slant with
// the wind; snowflakes sway and drift, and in a blizzard race almost sideways, drawn out into
// short streaks. Drawn under the time of day's tint, so night darkens them.

uniform vec2 view_size = vec2(1080.0, 1920.0);
// The world's screen position: the drops shift with it, a little less than the world.
uniform vec2 scroll = vec2(0.0, 0.0);
// 0 to 1 each (Weather.State).
uniform float wind = 0.0;
uniform float strength = 1.0;
uniform float snow = 0.0;
// How far beyond the view a drop starts and ends (screen pixels).
const float MARGIN = 90.0;
const float PARALLAX = 0.7;

varying float v_alpha;
// 1 for a gust streak of a blizzard (drawn like a raindrop), 0 for a flake.
varying float v_streak;

vec3 drop_hash(float n) {
	return fract(sin(vec3(n * 12.9898, n * 78.233, n * 37.719)) * 43758.5453);
}

void vertex() {
	vec3 h = drop_hash(float(INSTANCE_ID) + 1.0);
	// h.z: near (1, big and fast) or far (0, small and slow).
	float near = h.z;
	vec2 area = view_size + MARGIN * 2.0;
	float speed;
	vec2 dir;
	vec2 extent;
	float sway = 0.0;
	if (snow > 0.5) {
		speed = mix(70.0, 170.0, near) * (1.0 + wind * wind * 11.0);
		dir = normalize(vec2(-(0.15 + wind * 3.6), 1.0));
		float flake = mix(12.0, 28.0, near) * (1.0 - wind * 0.15);
		extent = vec2(flake, flake * (1.0 + wind * 2.8));
		sway = sin(TIME * (0.7 + h.x) + h.y * 40.0) * 22.0 * (1.0 - wind * 0.7);
		v_alpha = mix(0.75, 1.0, near);
		// In a blizzard one in six is a long, faint streak of blown snow racing past.
		v_streak = step(fract(h.x * 7.31), 0.17) * step(0.5, wind);
		if (v_streak > 0.5) {
			speed *= 1.6;
			extent = vec2(mix(3.0, 6.0, near), mix(120.0, 260.0, near) * wind);
			v_alpha = mix(0.22, 0.4, near);
			sway = 0.0;
		}
	} else {
		speed = mix(1300.0, 2300.0, near) * (1.0 + wind * 0.25);
		dir = normalize(vec2(-(0.08 + wind * 0.5), 1.0));
		extent = vec2(mix(2.5, 5.0, near), mix(40.0, 90.0, near) * (1.0 + wind * 0.4));
		v_alpha = mix(0.4, 0.75, near);
		v_streak = 1.0;
	}
	// Down the screen along dir, wrapping around the view.
	float fall = fract(h.y + TIME * speed * dir.y / area.y) * area.y;
	vec2 at = vec2(h.x * area.x + fall * dir.x / dir.y + sway, fall) + scroll * PARALLAX * mix(0.6, 1.0, near);
	at = mod(at, area) - MARGIN;
	// UV is 0 to 1 over the quad: across the drop (x) and along it, tail to head (y).
	vec2 corner = UV - 0.5;
	vec2 side = vec2(-dir.y, dir.x);
	VERTEX = at + side * corner.x * extent.x + dir * corner.y * extent.y;
	v_alpha *= strength;
}

void fragment() {
	float alpha;
	if (v_streak < 0.5) {
		alpha = 1.0 - smoothstep(0.55, 1.0, length(UV - 0.5) * 2.0);
	} else {
		// A thin streak, fading out towards its tail.
		alpha = (1.0 - smoothstep(0.35, 1.0, abs(UV.x - 0.5) * 2.0)) * smoothstep(0.0, 0.7, UV.y);
	}
	COLOR = vec4(0.9, 0.95, 1.0, alpha * v_alpha);
}

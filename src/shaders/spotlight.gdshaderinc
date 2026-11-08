// The submarine's spotlight (Spotlight, src/scenes/world/spotlight.gd: keep the two in step): a
// cone of light along the ground from the sub in the direction it faces, and a small pool around
// it. Inside, the deep sea's dark lifts and the seabed shows through as in shallower water. The
// seabed's props and the fish are lit as a whole, by Spotlight.amount().
uniform vec2 light_origin = vec2(0.0, 0.0);
uniform vec2 light_dir = vec2(1.0, 0.0);
// 0 off to 1 on; it fades in and out.
uniform float light_on = 0.0;
const float LIGHT_RANGE = 900.0;
const float LIGHT_COS_INNER = 0.94;
const float LIGHT_COS_OUTER = 0.8;
const float LIGHT_POOL = 220.0;

// 0 to 1, how brightly ground point g is lit.
float spotlight(vec2 g) {
	if (light_on <= 0.0) {
		return 0.0;
	}
	vec2 to = g - light_origin;
	float dist = length(to);
	float along = dot(to, light_dir);
	float cone = smoothstep(LIGHT_COS_OUTER, LIGHT_COS_INNER, along / max(dist, 1.0))
			* (1.0 - smoothstep(LIGHT_RANGE * 0.5, LIGHT_RANGE, dist));
	float pool = (1.0 - smoothstep(LIGHT_POOL * 0.3, LIGHT_POOL, dist)) * 0.6;
	return max(cone, pool) * light_on;
}

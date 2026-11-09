// The submarine's spotlight (Spotlight, src/scenes/world/spotlight.gd: keep the two in step): a
// cone of light along the ground in the direction the sub faces, shone down from its headlamp, and
// a soft pool around it. The cone's tip lies behind the sub and its near end fades in softly, so
// there is no sharp point under the sub. Inside, the deep sea's dark lifts and the seabed shows through as in shallower water. The
// seabed's props and the fish are lit as a whole, by Spotlight.amount().
uniform vec2 light_origin = vec2(0.0, 0.0);
uniform vec2 light_dir = vec2(1.0, 0.0);
// 0 off to 1 on; it fades in and out.
uniform float light_on = 0.0;
const float LIGHT_RANGE = 1050.0;
const float LIGHT_COS_INNER = 0.95;
const float LIGHT_COS_OUTER = 0.74;
const float LIGHT_POOL = 260.0;
const float LIGHT_BACK = 150.0;
const vec2 LIGHT_FADE_IN = vec2(60.0, 420.0);

// 0 to 1, how brightly ground point g is lit.
float spotlight(vec2 g) {
	if (light_on <= 0.0) {
		return 0.0;
	}
	vec2 to = g - (light_origin - light_dir * LIGHT_BACK);
	float dist = length(to);
	float along = dot(to, light_dir);
	float cone = smoothstep(LIGHT_COS_OUTER, LIGHT_COS_INNER, along / max(dist, 1.0))
			* (1.0 - smoothstep(LIGHT_RANGE * 0.5, LIGHT_RANGE, dist))
			* smoothstep(LIGHT_BACK + LIGHT_FADE_IN.x, LIGHT_BACK + LIGHT_FADE_IN.y, along);
	float pool = (1.0 - smoothstep(0.0, LIGHT_POOL, length(g - light_origin))) * 0.45;
	return max(cone, pool) * light_on;
}

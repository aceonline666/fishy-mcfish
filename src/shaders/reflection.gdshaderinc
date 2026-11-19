// The sun or the moon mirrored on the water (DayClock.glint, Mirror): a disc lying on the sea,
// broken up by the waves into wobbling slices with frayed edges, a soft halo and glints flashing
// around it. mirror.gdshader draws it on the water's surface; night.gdshader lets it shine through
// the night's tint, so the moon stays bright. Include it after to_ground; the including shader
// has `zoom` and works in the screen coordinates of the world (world_origin).
// The light's colour (alpha: how strongly it shows) and how high it stands (0 on the horizon:
// drawn out long towards the viewer; 1 overhead: round).
uniform vec4 glint_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float glint_height = 1.0;
// Where the light lies on the water (ground) and its radius (ground units).
uniform vec2 mirror_at = vec2(0.0, 0.0);
uniform float mirror_radius = 120.0;
// The size of a glint's cell (ground units): one glint at most in each.
const float GLINT_CELL = 44.0;
// How much of the light the mirror shows at its brightest: the wader and the fish stay visible
// through it.
const float MIRROR_OPACITY = 0.5;

float glint_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 0 to 1, the glints at ground point g: in each cell, if they are dense enough there, a short
// flash now and then, stretched along the screen's horizontal.
float glints(vec2 g, float t, float density) {
	vec2 p = g / GLINT_CELL;
	vec2 cell = floor(p);
	float a = glint_hash(cell);
	float b = glint_hash(cell + 17.31);
	if (a > density) {
		return 0.0;
	}
	vec2 f = fract(p) - 0.5 - (vec2(a, b) - 0.5) * 0.4;
	float along = (f.x - f.y) * 0.7071;
	float across = (f.x + f.y) * 0.7071;
	float dot_shape = 1.0 - smoothstep(0.08, 0.2, length(vec2(along * 0.3, across)));
	return dot_shape * pow(max(sin(t * (1.6 + b * 2.4) + a * 40.0), 0.0), 3.0);
}

// Where world screen point `world` lies from the mirrored light, in its radii, rippled by the
// waves (Iso: keep in step with to_ground).
vec2 reflection_point(vec2 world, float t) {
	vec2 centre = vec2(mirror_at.x - mirror_at.y, (mirror_at.x + mirror_at.y) * 0.5) * 0.70710678;
	vec2 p = (world - centre) / (mirror_radius * 0.70710678);
	// A low light is mirrored long, drawn out towards the viewer.
	p.y /= mix(1.8, 1.0, glint_height);
	// The waves shift each slice sideways.
	p.x += sin(p.y * 7.0 + t * 2.6) * 0.09 + sin(p.y * 3.1 - t * 1.7 + p.x) * 0.06;
	return p;
}

// The mirrored light at world screen point `world` (ground point g), 0 to 1 each. x: the disc, cut
// by thin gaps between the waves, frayed strands beyond its edge and the glints around it;
// y: its soft halo.
vec2 mirrored_light(vec2 world, vec2 g, float t) {
	vec2 p = reflection_point(world, t);
	float len = length(p);
	float slices = sin(p.y * 11.0 - t * 2.2 + sin(p.x * 2.5 + t) * 1.4);
	float disc = (1.0 - smoothstep(0.85, 1.0, len)) * mix(0.4, 1.0, smoothstep(-0.65, 0.1, slices));
	float strands = (1.0 - smoothstep(1.0, 1.6, len)) * smoothstep(0.6, 0.95, slices) * 0.7;
	float near = exp(-len * len * 0.08);
	float light = clamp(max(disc, strands) + glints(g, t, near * 0.9) * near * 1.5, 0.0, 1.0);
	return vec2(light, exp(-len * len * 0.3) * 0.3) * glint_color.a * MIRROR_OPACITY;
}

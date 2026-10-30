shader_type canvas_item;
// Something seen through the water (fish, the wader): half of the seabed's tint (see
// seabed_props.gdshader), so it sits in the water instead of looking like it floats above it.
// `depth` and `abyss` are its own (SeaDepth). Only what is drawn below `waterline` (local y) is
// tinted, with a thin bright line where the surface cuts it; fish are always below it.

uniform vec4 shallow_color : source_color = vec4(0.32, 0.78, 0.8, 1.0);
uniform vec4 deep_color : source_color = vec4(0.07, 0.33, 0.55, 1.0);
uniform vec4 abyss_color : source_color = vec4(0.01, 0.03, 0.09, 1.0);
uniform float clarity = 0.8;
uniform float depth = 0.0;
uniform float abyss = 0.0;
// Share of the seabed's tint.
uniform float strength = 0.5;
uniform float waterline = -100000.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	// COLOR already holds the texture times the vertex colour.
	vec4 base = COLOR;
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, pow(depth, 0.7));
	vec3 seen = mix(water, base.rgb * mix(vec3(1.0), shallow_color.rgb * 1.4, 0.25), clarity * pow(1.0 - depth, 1.4));
	seen = mix(seen, abyss_color.rgb, abyss * 0.92);
	float below = smoothstep(waterline - 1.5, waterline + 1.5, local_position.y);
	vec3 color = mix(base.rgb, seen, strength * below);
	// The surface line, where the water cuts the body.
	float surface = 1.0 - smoothstep(1.0, 3.0, abs(local_position.y - waterline));
	color = mix(color, vec3(1.0), surface * 0.6);
	COLOR = vec4(color, base.a);
}

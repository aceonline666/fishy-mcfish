shader_type canvas_item;
// A fish seen through the water: half of the seabed's tint (see seabed_props.gdshader), so it
// sits in the water instead of looking like it floats above it. `depth` and `abyss` are the
// fish's own (SeaDepth).

uniform vec4 shallow_color : source_color = vec4(0.32, 0.78, 0.8, 1.0);
uniform vec4 deep_color : source_color = vec4(0.07, 0.33, 0.55, 1.0);
uniform vec4 abyss_color : source_color = vec4(0.01, 0.03, 0.09, 1.0);
uniform float clarity = 0.8;
uniform float depth = 0.0;
uniform float abyss = 0.0;
// Share of the seabed's tint.
uniform float strength = 0.5;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, pow(depth, 0.7));
	vec3 seen = mix(water, base.rgb * mix(vec3(1.0), shallow_color.rgb * 1.4, 0.25), clarity * pow(1.0 - depth, 1.4));
	seen = mix(seen, abyss_color.rgb, abyss * 0.92);
	COLOR = vec4(mix(base.rgb, seen, strength), base.a);
}

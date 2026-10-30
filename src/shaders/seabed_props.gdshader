shader_type canvas_item;
// Seabed props seen through the water, tinted like the painted seabed in water.gdshader: they
// fade into the water colour with depth and into the dark of the deep sea beyond the open water.
// Each prop passes its depth in its vertex colour: r = depth (0..1 over depth_range),
// g = how far into the abyss (0..1).

uniform vec4 shallow_color : source_color = vec4(0.32, 0.78, 0.8, 1.0);
uniform vec4 deep_color : source_color = vec4(0.07, 0.33, 0.55, 1.0);
uniform vec4 abyss_color : source_color = vec4(0.01, 0.03, 0.09, 1.0);
// As the seabed's floor_strength: how clearly things show through shallow water.
uniform float clarity = 0.8;

// The vertex colour, before the fragment's COLOR is multiplied by the texture.
varying vec4 depth_data;

void vertex() {
	depth_data = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float depth = depth_data.r;
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, pow(depth, 0.7));
	vec3 color = mix(water, tex.rgb * mix(vec3(1.0), shallow_color.rgb * 1.4, 0.25), clarity * pow(1.0 - depth, 1.4));
	color = mix(color, abyss_color.rgb, depth_data.g * 0.92);
	COLOR = vec4(color, tex.a);
}

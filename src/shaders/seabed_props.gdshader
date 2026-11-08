shader_type canvas_item;
// Seabed props seen through the water, tinted like the painted seabed in water.gdshader: they
// fade into the water colour with depth and into the dark of the deep sea beyond the open water.
// Each prop passes its depth in its vertex colour: r = depth (0..1 over depth_range),
// g = how far into the abyss (0..1), a = opacity. A glowing prop (SeabedDecor.GLOWS) passes the
// height of its light in b (share of the sprite from the top): around the light it shows through
// the dark, fading into it towards its foot, and above the light (its painted smoke) it is cut
// away, as the smoke is drawn moving.

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
	float abyss = depth_data.g;
	float alpha = tex.a * depth_data.a;
	if (depth_data.b > 0.0) {
		float lit = 1.0 - smoothstep(depth_data.b, 1.0, UV.y);
		depth *= mix(1.0, 0.3, lit);
		abyss *= mix(1.0, 0.3, lit);
		alpha *= smoothstep(depth_data.b - 0.05, depth_data.b + 0.02, UV.y);
	}
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, pow(depth, 0.7));
	vec3 color = mix(water, tex.rgb * mix(vec3(1.0), shallow_color.rgb * 1.4, 0.25), clarity * pow(1.0 - depth, 1.4));
	color = mix(color, abyss_color.rgb, abyss * 0.92);
	COLOR = vec4(color, alpha);
}

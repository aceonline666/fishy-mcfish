// The waves lapping at the waterline, shared by water.gdshader, swell.gdshader and
// mirror.gdshader so their waterlines stay in step. The fishing scene sets both uniforms on all
// three every frame from the weather: wave_time runs faster in the wind (accumulated, so a change
// of speed never makes the waves jump) and wave_amp makes them higher.
uniform float wave_time = 0.0;
uniform float wave_amp = 1.0;

// How far the water reaches up the beach at ground x (ground units).
float shore_wave(vec2 g) {
	return (sin(g.x * 0.02 + wave_time * 1.5) * 10.0 + sin(g.x * 0.05 - wave_time) * 5.0) * wave_amp;
}

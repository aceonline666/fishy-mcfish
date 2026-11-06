extends Node
## Placeholder sound effects, synthesized at startup and kept soft. They play on the sound bus,
## whose volume and mute the Settings control.

const MIX_RATE := 22050
const VOICES := 10
## Added to every sound, so effects sit below the music instead of on top of it.
const HEADROOM_DB := -6.0
## The same sound started again within this time (but not in the same frame, which is a chord)
## is skipped, so fast selling does not turn into a buzz.
const REPEAT_GAP_S := 0.055
## How fast a hum fades in and out (share of full level per second).
const HUM_FADE := 2.5
## Seconds over which a looping sound's end blends into its start.
const LOOP_BLEND := 0.08

var _sounds: Dictionary[StringName, AudioStreamWAV] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
## Sound name -> Time.get_ticks_msec() and process frame when it last started.
var _last_played: Dictionary[StringName, Vector2i] = {}
## Looping sounds (hum()): their own players and their current levels, which follow the levels
## asked for smoothly.
var _hum_players: Dictionary[StringName, AudioStreamPlayer] = {}
var _hum_levels: Dictionary[StringName, float] = {}


func _ready() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = Settings.SOUND_BUS
		add_child(player)
		_players.append(player)
	_sounds[&"pop"] = _pop()
	_sounds[&"splash"] = _splash()
	_sounds[&"slosh"] = _slosh()
	_sounds[&"sand"] = _sand()
	_sounds[&"wood"] = _wood()
	_sounds[&"plop"] = _plop()
	_sounds[&"ding"] = _ding()
	_sounds[&"coin"] = _coin()
	_sounds[&"fanfare"] = _fanfare()
	_sounds[&"motor"] = _motor()
	_sounds[&"rotors"] = _rotors()


func play(sound: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var now := Vector2i(Time.get_ticks_msec(), Engine.get_process_frames())
	var last: Vector2i = _last_played.get(sound, Vector2i(-100000, -1))
	if last.y != now.y and now.x - last.x < int(REPEAT_GAP_S * 1000.0):
		return
	_last_played[sound] = now
	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = _sounds[sound]
	player.pitch_scale = pitch
	player.volume_db = volume_db + HEADROOM_DB
	player.play()


## Keeps the looping `sound` going at `level` (0 silent to 1 full, at `volume_db`): call it every
## frame with the level wanted; it fades there at HUM_FADE per second and stops when silent.
func hum(sound: StringName, level: float, delta: float, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var current: float = move_toward(_hum_levels.get(sound, 0.0), clampf(level, 0.0, 1.0), HUM_FADE * delta)
	_hum_levels[sound] = current
	var player: AudioStreamPlayer = _hum_players.get(sound)
	if current <= 0.001:
		if player != null and player.playing:
			player.stop()
		return
	if player == null:
		player = AudioStreamPlayer.new()
		player.bus = Settings.SOUND_BUS
		player.stream = _sounds[sound]
		add_child(player)
		_hum_players[sound] = player
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(current) + volume_db + HEADROOM_DB
	if not player.playing:
		player.play()


## Bubble "bloop": a sine sweeping down with a fast decay.
static func _pop() -> AudioStreamWAV:
	var duration := 0.12
	var samples := PackedFloat32Array()
	var phase := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		phase += TAU * lerpf(950.0, 320.0, t / duration) / MIX_RATE
		samples.append(sin(phase) * exp(-t * 32.0) * 0.8)
	return _to_wav(samples)


## Low-passed noise burst whose cutoff falls over time.
static func _splash() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var duration := 0.4
	var samples := PackedFloat32Array()
	var filtered := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		filtered += (rng.randf_range(-1.0, 1.0) - filtered) * lerpf(0.5, 0.05, t / duration)
		samples.append(filtered * exp(-t * 9.0) * minf(t * 200.0, 1.0) * 1.4)
	return _to_wav(samples)


## Wading step: deep, twice low-passed noise that swells in and out (no hiss, no click), under
## a quiet low "plop" of a leg pulling out of the water.
static func _slosh() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var duration := 0.26
	var samples := PackedFloat32Array()
	var first := 0.0
	var second := 0.0
	var phase := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		var cutoff := lerpf(0.09, 0.03, t / duration)
		first += (rng.randf_range(-1.0, 1.0) - first) * cutoff
		second += (first - second) * cutoff
		var swell := sin(PI * minf(t / 0.05, 1.0) * 0.5) * exp(-maxf(t - 0.05, 0.0) * 14.0)
		phase += TAU * lerpf(210.0, 120.0, t / duration) / MIX_RATE
		samples.append((second * 3.5 + sin(phase) * 0.12) * swell)
	return _to_wav(samples)


## Step on sand: a short soft crunch of many tiny grains (band-passed noise that crackles), no
## thump.
static func _sand() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var duration := 0.16
	var samples := PackedFloat32Array()
	var low := 0.0
	var lower := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		var noise := rng.randf_range(-1.0, 1.0)
		low += (noise - low) * 0.35
		lower += (low - lower) * 0.08
		# Band-pass: the low-passed noise minus its slower copy; grains crackle in and out.
		var grain := 1.0 if rng.randf() < 0.35 else 0.25
		var envelope := sin(PI * minf(t / 0.015, 1.0) * 0.5) * exp(-t * 22.0)
		samples.append((low - lower) * grain * envelope * 1.6)
	return _to_wav(samples)


## Step on a wooden plank: a low hollow knock (a short falling tone under a muffled click), with
## a little ring of the board.
static func _wood() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var duration := 0.2
	var samples := PackedFloat32Array()
	var phase := 0.0
	var ring := 0.0
	var click := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		phase += TAU * (95.0 + 70.0 * exp(-t * 40.0)) / MIX_RATE
		ring += TAU * 410.0 / MIX_RATE
		click += (rng.randf_range(-1.0, 1.0) - click) * 0.25
		var attack := sin(PI * minf(t / 0.004, 1.0) * 0.5)
		var knock := sin(phase) * exp(-t * 28.0) * 0.7
		var board := sin(ring) * exp(-t * 45.0) * 0.18
		samples.append((knock + board + click * exp(-t * 120.0) * 0.5) * attack)
	return _to_wav(samples)


## Something small dropping into water: a round low "bloop" that bends down, eased in so it has
## no hard edge, with a short muffled swish behind it.
static func _plop() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var duration := 0.3
	var samples := PackedFloat32Array()
	var phase := 0.0
	var first := 0.0
	var second := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		phase += TAU * (180.0 + 320.0 * exp(-t * 30.0)) / MIX_RATE
		var bloop := sin(phase) * sin(PI * minf(t / 0.012, 1.0) * 0.5) * exp(-t * 18.0)
		first += (rng.randf_range(-1.0, 1.0) - first) * 0.06
		second += (first - second) * 0.06
		var swish := second * sin(PI * minf(t / 0.04, 1.0) * 0.5) * exp(-t * 12.0)
		samples.append(bloop * 0.45 + swish * 2.0)
	return _to_wav(samples)


## Soft bell: fundamental plus a quiet octave, a short fade-in against clicks and a slow decay.
static func _ding() -> AudioStreamWAV:
	var duration := 0.6
	var samples := PackedFloat32Array()
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		var tone := sin(TAU * 880.0 * t) + 0.2 * sin(TAU * 1760.0 * t)
		samples.append(tone * exp(-t * 7.0) * minf(t * 150.0, 1.0) * 0.4)
	return _to_wav(samples)


## Two quick rising blips with a gentle octave instead of a buzzy overtone.
static func _coin() -> AudioStreamWAV:
	var duration := 0.16
	var samples := PackedFloat32Array()
	var phase := 0.0
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		phase += TAU * (1175.0 if t < 0.06 else 1568.0) / MIX_RATE
		samples.append((sin(phase) + 0.15 * sin(phase * 2.0)) * exp(-t * 16.0) * minf(t * 300.0, 1.0) * 0.35)
	return _to_wav(samples)


## A rising major arpeggio whose top note rings on, for reached goals.
static func _fanfare() -> AudioStreamWAV:
	const NOTES: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	const STEP_S := 0.09
	var duration := STEP_S * (NOTES.size() - 1) + 0.9
	var samples := PackedFloat32Array()
	for i in int(duration * MIX_RATE):
		var t := float(i) / MIX_RATE
		var value := 0.0
		for n in NOTES.size():
			var local := t - n * STEP_S
			if local < 0.0:
				continue
			var decay := 4.0 if n == NOTES.size() - 1 else 14.0
			var tone := sin(TAU * NOTES[n] * local) + 0.25 * sin(TAU * NOTES[n] * 2.0 * local)
			value += tone * exp(-local * decay) * minf(local * 200.0, 1.0)
		samples.append(value * 0.28)
	return _to_wav(samples)


## The submarine's motor, looping: a low throb whose propeller chops it a few times a second,
## under the muffled churn of the water. One second long, every tone a whole number of cycles.
static func _motor() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var samples := PackedFloat32Array()
	var first := 0.0
	var second := 0.0
	for i in MIX_RATE:
		var t := float(i) / MIX_RATE
		var throb := sin(TAU * 55.0 * t) * 0.5 + sin(TAU * 110.0 * t) * 0.22 + sin(TAU * 165.0 * t) * 0.08
		var chop := 0.75 + 0.25 * sin(TAU * 9.0 * t)
		first += (rng.randf_range(-1.0, 1.0) - first) * 0.05
		second += (first - second) * 0.05
		samples.append((throb * chop + second * 2.5) * 0.7)
	return _to_loop(samples)


## Drone rotors, looping: two slightly different buzzing tones that beat against each other,
## softened, with a little air noise. One second long, every tone a whole number of cycles.
static func _rotors() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	var samples := PackedFloat32Array()
	var soft := 0.0
	var air := 0.0
	for i in MIX_RATE:
		var t := float(i) / MIX_RATE
		var buzz := 0.0
		for rotor: float in [180.0, 187.0]:
			# A few harmonics of a sawtooth.
			for k in range(1, 6):
				buzz += sin(TAU * rotor * k * t) / k
		soft += (buzz * 0.25 - soft) * 0.3
		air += (rng.randf_range(-1.0, 1.0) - air) * 0.2
		samples.append(soft * 0.8 + air * 0.15)
	return _to_loop(samples)


## A looping WAV: the end fades into the start over LOOP_BLEND seconds, so noise loops without a
## click.
static func _to_loop(samples: PackedFloat32Array) -> AudioStreamWAV:
	var blend := int(LOOP_BLEND * MIX_RATE)
	var count := samples.size() - blend
	var looped := samples.slice(0, count)
	for i in blend:
		var w := float(i) / blend
		looped[i] = samples[count + i] * (1.0 - w) + samples[i] * w
	var wav := _to_wav(looped)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = looped.size()
	return wav


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav

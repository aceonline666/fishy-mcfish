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

var _sounds: Dictionary[StringName, AudioStreamWAV] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
## Sound name -> Time.get_ticks_msec() and process frame when it last started.
var _last_played: Dictionary[StringName, Vector2i] = {}


func _ready() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = Settings.SOUND_BUS
		add_child(player)
		_players.append(player)
	_sounds[&"pop"] = _pop()
	_sounds[&"splash"] = _splash()
	_sounds[&"ding"] = _ding()
	_sounds[&"coin"] = _coin()


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

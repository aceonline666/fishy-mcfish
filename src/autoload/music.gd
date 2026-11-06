extends Node
## Background music on the music bus: a relaxed loop on the beach and a bossa nova shop theme in
## the gear shop (GameState.in_store). Entering the shop crossfades to its theme, which starts from
## the beginning each visit; the beach loop keeps running underneath, silent, and fades back in on
## leaving. Volume and on/off come from the Settings; while the music is off both players pause.

const BEACH_TRACK := preload("res://assets/music/feel_good_island_loop.ogg")
const SHOP_TRACK := preload("res://assets/music/shop_theme.ogg")
## Seconds a crossfade takes.
const FADE_S := 0.8
## The shop theme is mastered about 2 dB quieter than the beach loop; this evens them out.
const SHOP_DB := 2.0
const SILENT_DB := -60.0

var player: AudioStreamPlayer
var shop_player: AudioStreamPlayer
## 0 on the beach, 1 in the shop; moves towards where the player is.
var _shop_mix := 0.0


func _ready() -> void:
	player = _make_player(BEACH_TRACK)
	shop_player = _make_player(SHOP_TRACK)
	player.play()
	Settings.audio_changed.connect(_on_audio_changed)
	_on_audio_changed()


func _make_player(track: AudioStream) -> AudioStreamPlayer:
	var new_player := AudioStreamPlayer.new()
	new_player.stream = track
	new_player.bus = Settings.MUSIC_BUS
	add_child(new_player)
	return new_player


func _process(delta: float) -> void:
	var in_shop := GameState.in_store
	if in_shop and not shop_player.playing:
		shop_player.play()
	_shop_mix = move_toward(_shop_mix, 1.0 if in_shop else 0.0, delta / FADE_S)
	# Equal-power crossfade, so the loudness does not dip in the middle.
	player.volume_db = _db(cos(_shop_mix * PI * 0.5))
	shop_player.volume_db = _db(sin(_shop_mix * PI * 0.5)) + SHOP_DB
	if _shop_mix <= 0.0 and shop_player.playing:
		shop_player.stop()


func _db(level: float) -> float:
	return maxf(linear_to_db(level), SILENT_DB)


func _on_audio_changed() -> void:
	var paused := not Settings.music_on or Settings.music_volume <= 0.0
	player.stream_paused = paused
	shop_player.stream_paused = paused

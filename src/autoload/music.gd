extends Node
## Background music: one relaxed loop for now, on the music bus. Volume and on/off come from the
## Settings; while the music is off the player pauses.

const TRACK := preload("res://assets/music/feel_good_island_loop.ogg")

var player: AudioStreamPlayer


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.stream = TRACK
	player.bus = Settings.MUSIC_BUS
	add_child(player)
	player.play()
	Settings.audio_changed.connect(_on_audio_changed)
	_on_audio_changed()


func _on_audio_changed() -> void:
	player.stream_paused = not Settings.music_on or Settings.music_volume <= 0.0

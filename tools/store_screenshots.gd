extends SceneTree
## Takes the raw Play Store screenshots (see tools/store_shots_runner.gd). Captions and the frame
## are added by tools/make_play_store_art.py.
##
## Usage (not headless, it needs to render):
##   godot --path . -s res://tools/store_screenshots.gd -- --out=C:/temp/store_shots [--lang=de] [--only=reef]
##
## --only runs the shots whose function name ends with the given text. --view=x,y takes only one
## shot of the developed beach with the wader at that ground point, e.g. --view=2040,-360 (the
## drone dock). With --view, --tank=N sets the tank level, --gear=N the gear level, --carry=id,id
## the fish in the backpack, --face=x,y the wader's ground direction (-1,-1: its back),
## --location=id the place, --full fills the tank.


func _initialize() -> void:
	_start.call_deferred()


## Deferred: the runner uses the game's classes, which need the autoloads to compile.
func _start() -> void:
	var runner := Node.new()
	runner.set_script(load("res://tools/store_shots_runner.gd"))
	root.add_child(runner)

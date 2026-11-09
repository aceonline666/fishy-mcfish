extends SceneTree
## Renders every species as the game draws it (FishArt) at four points of its swimming cycle, one
## row per species, into contact sheets: to check the sprites and their animation at a glance.
##
## Usage (not headless, it needs to render):
##   godot --path . -s res://tools/species_sheet.gd -- --out=C:/temp/species [--only=eel,shark] [--phases=8] [--length=230]
##
## --only keeps the species whose id contains one of the given texts; --phases sets the points of
## the swimming cycle drawn per species (4), --length how long each is drawn (230).


func _initialize() -> void:
	_start.call_deferred()


## Deferred: the runner uses the game's classes, which need the autoloads to compile.
func _start() -> void:
	var runner := Node.new()
	runner.set_script(load("res://tools/species_sheet_runner.gd"))
	root.add_child(runner)

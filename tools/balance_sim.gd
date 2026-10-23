extends SceneTree
## Plays the game headless with a simple greedy strategy and prints when milestones are reached,
## to check the pacing. See tools/balance_sim_runner.gd for the player model.
##
## Usage: godot --headless --path . -s res://tools/balance_sim.gd -- [--hours=3] [--seed=1]
##
## The runner is loaded at runtime: scripts compiled before the autoloads exist cannot use them.

var _hours := 3.0
var _seed := 1


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hours="):
			_hours = arg.trim_prefix("--hours=").to_float()
		elif arg.begins_with("--seed="):
			_seed = arg.trim_prefix("--seed=").to_int()
	_run.call_deferred()


func _run() -> void:
	root.get_node("SaveSystem").call("use_sandbox", "user://balance_sim/save.json")
	var runner: RefCounted = load("res://tools/balance_sim_runner.gd").new()
	runner.call("run", _hours, _seed)
	quit()

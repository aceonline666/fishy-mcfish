extends GutTest
## Plays the game with the balance bot (tools/balance_sim_runner.gd) and checks the pacing
## targets from the design. The bot plays perfectly; real players are slower.

const RunnerScript := preload("res://tools/balance_sim_runner.gd")
const MINUTE := 60.0

var _milestones: Dictionary[String, float] = {}


func before_all() -> void:
	# Long enough to see the open sea charted at the upper end of its range.
	_milestones = RunnerScript.new().run(2.5, 1, true)


func _minutes(key: String) -> float:
	return _milestones.get(key, INF) / MINUTE


func test_the_first_upgrade_comes_quickly() -> void:
	assert_lt(_minutes("tank"), 5.0, "first tank upgrade")


func test_the_snorkel_is_affordable_after_a_short_while() -> void:
	assert_between(_minutes("gear"), 5.0, 25.0)


func test_the_coral_reef_opens_after_about_half_an_hour_to_an_hour() -> void:
	assert_between(_minutes("unlock_coral_reef"), 25.0, 70.0)


## Seed 1 charts it after about 127 minutes, seeds 2 and 3 after 101 and 109: the long save for
## the rebreather (60K) decides it.
func test_the_open_sea_is_reached_after_about_one_to_two_hours() -> void:
	assert_between(_minutes("charted_open_sea"), 55.0, 140.0)

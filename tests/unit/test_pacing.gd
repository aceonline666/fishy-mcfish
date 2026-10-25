extends GutTest
## Plays the game with the balance bot (tools/balance_sim_runner.gd) and checks the pacing
## targets from the design. The bot plays perfectly; real players are slower.

const RunnerScript := preload("res://tools/balance_sim_runner.gd")
const MINUTE := 60.0

var _milestones: Dictionary[String, float] = {}


func before_all() -> void:
	_milestones = RunnerScript.new().run(2.0, 1, true)


func _minutes(key: String) -> float:
	return _milestones.get(key, INF) / MINUTE


func test_the_first_upgrade_comes_quickly() -> void:
	assert_lt(_minutes("tank"), 5.0, "first tank upgrade")


func test_the_snorkel_is_affordable_after_a_short_while() -> void:
	assert_between(_minutes("gear"), 5.0, 25.0)


func test_the_coral_reef_opens_after_about_half_an_hour_to_an_hour() -> void:
	assert_between(_minutes("unlock_coral_reef"), 25.0, 70.0)


func test_the_open_sea_is_reached_in_the_second_hour() -> void:
	assert_between(_minutes("charted_open_sea"), 60.0, 120.0)

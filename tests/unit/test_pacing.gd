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


## The bot buys a bigger tank once its tank is 70 % full: the glass tank lasts a while (seed 1:
## 13 minutes), but not so long that it never fills.
func test_the_first_tank_fills_up_after_a_while() -> void:
	assert_between(_minutes("tank"), 5.0, 20.0, "first tank upgrade")


func test_the_snorkel_is_affordable_after_a_short_while() -> void:
	assert_between(_minutes("gear"), 5.0, 25.0)


func test_the_coral_reef_opens_after_about_half_an_hour_to_an_hour() -> void:
	assert_between(_minutes("unlock_coral_reef"), 25.0, 70.0)


## Seed 1 charts it after about 75 minutes: the long save for the rebreather (60K) decides it.
func test_the_open_sea_is_reached_after_about_one_to_two_hours() -> void:
	assert_between(_minutes("charted_open_sea"), 55.0, 140.0)

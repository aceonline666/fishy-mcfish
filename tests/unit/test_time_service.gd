extends GutTest

const TimeServiceScript := preload("res://src/autoload/time_service.gd")


func test_offline_seconds_is_elapsed_time() -> void:
	assert_eq(TimeServiceScript.offline_seconds(1600, 1000, 3600.0), 600.0)


func test_offline_seconds_is_capped() -> void:
	assert_eq(TimeServiceScript.offline_seconds(100_000, 0, 3600.0), 3600.0)


func test_clock_moved_backwards_grants_nothing() -> void:
	assert_eq(TimeServiceScript.offline_seconds(500, 1000, 3600.0), 0.0)

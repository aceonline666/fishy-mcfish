extends GutTest


func test_small_values_are_whole_numbers() -> void:
	assert_eq(NumberFormat.compact(0.0), "0")
	assert_eq(NumberFormat.compact(7.9), "7")
	assert_eq(NumberFormat.compact(999.99), "999")


func test_thousands_use_three_significant_digits() -> void:
	assert_eq(NumberFormat.compact(1000.0), "1.00K")
	assert_eq(NumberFormat.compact(1234.0), "1.23K")
	assert_eq(NumberFormat.compact(12345.0), "12.3K")
	assert_eq(NumberFormat.compact(123456.0), "123K")


func test_rounds_down_never_up() -> void:
	assert_eq(NumberFormat.compact(999_999.0), "999K")
	assert_eq(NumberFormat.compact(1150.0), "1.15K")


func test_larger_tiers() -> void:
	assert_eq(NumberFormat.compact(1_500_000.0), "1.50M")
	assert_eq(NumberFormat.compact(2.5e9), "2.50B")
	assert_eq(NumberFormat.compact(3e12), "3.00T")


func test_negative_values() -> void:
	assert_eq(NumberFormat.compact(-1500.0), "-1.50K")

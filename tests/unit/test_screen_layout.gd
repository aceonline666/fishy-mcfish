extends GutTest
## Portrait and landscape: the base size turns with the screen, so the short side stays 1080
## pixels, and the fishing HUD and panels fit the screen's shape.

const PORTRAIT := Vector2i(1080, 1920)


func test_the_base_size_turns_with_the_window() -> void:
	assert_eq(Platform.base_size(Vector2(1080.0, 2400.0), PORTRAIT), PORTRAIT)
	assert_eq(Platform.base_size(Vector2(2400.0, 1080.0), PORTRAIT), Vector2i(1920, 1080))
	assert_eq(Platform.base_size(Vector2(2048.0, 1536.0), PORTRAIT), Vector2i(1920, 1080), "a tablet held sideways")
	assert_eq(Platform.base_size(Vector2(800.0, 800.0), PORTRAIT), PORTRAIT, "a square window stays portrait")


func test_a_panel_stays_a_centred_column_on_a_wide_screen() -> void:
	var margin := SafeAreaContainer.new()
	margin.edge_padding = 32
	margin.max_content_width = 1200.0
	add_child_autofree(margin)
	var width := get_viewport().get_visible_rect().size.x
	var expected := 32 + int(maxf(0.0, (width - 64.0 - 1200.0) * 0.5))
	assert_eq(margin.get_theme_constant("margin_left"), expected)
	assert_eq(margin.get_theme_constant("margin_right"), expected)

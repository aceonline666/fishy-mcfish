class_name GoalsPanel
extends OverlayPanel
## Lists every goal with its progress and reward. Reached goals are ticked off.

const DONE_COLOR := Color(0.55, 1.0, 0.65)
const REWARD_COLOR := Color(1.0, 0.86, 0.3)


func _refresh() -> void:
	for child in content.get_children():
		child.queue_free()
	var state := GameState.state
	set_title("Goals  %d / %d" % [state.achievements.size(), DataRegistry.achievements.size()])
	# Open goals first, in data order; reached ones at the end.
	for done: bool in [false, true]:
		for def in DataRegistry.achievements:
			if state.achievements.has(def.id) == done:
				content.add_child(_make_row(def, done))


func _make_row(def: AchievementDef, done: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", card_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)

	var top := HBoxContainer.new()
	column.add_child(top)
	var name_label := make_label(def.name, 40, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var reward := make_label("Done" if done else "+%s" % NumberFormat.compact(def.reward), 36, HORIZONTAL_ALIGNMENT_RIGHT)
	reward.add_theme_color_override("font_color", DONE_COLOR if done else REWARD_COLOR)
	reward.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(reward)

	var description := make_label(def.description, 30, HORIZONTAL_ALIGNMENT_LEFT)
	description.add_theme_color_override("font_color", MUTED)
	column.add_child(description)

	if not done:
		var current := minf(Achievements.progress(GameState.state, def), def.target)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0.0, 30.0)
		bar.max_value = def.target
		bar.value = current
		bar.show_percentage = false
		column.add_child(bar)
		if def.target > 1.0:
			var numbers := make_label("%s / %s" % [NumberFormat.compact(current), NumberFormat.compact(def.target)], 26, HORIZONTAL_ALIGNMENT_RIGHT)
			numbers.add_theme_color_override("font_color", MUTED)
			column.add_child(numbers)
	return row

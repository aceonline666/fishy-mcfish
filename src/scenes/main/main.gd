extends Control
## M0 placeholder screen. Proves that data loading, the money flow and saving work on a device.
## Replaced by the real scene router with bottom navigation in M2.

const EDGE_PADDING := 32
const TEST_SPECIES_ID := "european_sprat"

@onready var _safe_area: MarginContainer = $SafeArea
@onready var _money_label: Label = %MoneyLabel
@onready var _info_label: Label = %InfoLabel
@onready var _earn_button: Button = %EarnButton


func _ready() -> void:
	EventBus.money_changed.connect(_on_money_changed)
	_earn_button.pressed.connect(_on_earn_pressed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_on_money_changed(GameState.state.money)
	_info_label.text = "%d species loaded\nv%s · Godot %s" % [
		DataRegistry.species.size(),
		ProjectSettings.get_setting("application/config/version"),
		Engine.get_version_info()["string"],
	]


func _apply_safe_area() -> void:
	var insets := Platform.safe_area_margins(get_viewport())
	_safe_area.add_theme_constant_override("margin_left", EDGE_PADDING + int(insets.x))
	_safe_area.add_theme_constant_override("margin_top", EDGE_PADDING + int(insets.y))
	_safe_area.add_theme_constant_override("margin_right", EDGE_PADDING + int(insets.z))
	_safe_area.add_theme_constant_override("margin_bottom", EDGE_PADDING + int(insets.w))


func _on_money_changed(money: float) -> void:
	_money_label.text = "Coins: " + NumberFormat.compact(money)


func _on_earn_pressed() -> void:
	GameState.add_money(DataRegistry.species[TEST_SPECIES_ID].base_value)
	Haptics.tick()

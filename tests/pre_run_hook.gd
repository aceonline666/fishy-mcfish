extends GutHookScript
## Runs before any test: keeps the test run away from the player's real save file.

const SANDBOX_SAVE := "user://test_run/save.json"


func run() -> void:
	SaveSystem.use_sandbox(SANDBOX_SAVE)

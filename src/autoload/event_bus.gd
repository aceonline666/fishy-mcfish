extends Node
## Global typed signals, so systems and scenes stay decoupled.
## Signals are emitted by other scripts, hence the unused_signal suppression.

@warning_ignore_start("unused_signal")

## Fixed-rate simulation step while the app is running.
signal sim_tick(dt: float)
## Simulated time to catch up after the app was closed or in the background.
signal offline_progress(seconds: float)
## The whole PlayerState was replaced (new game or save loaded).
signal state_replaced
signal money_changed(money: float)
signal fish_caught(species_id: String, is_new_species: bool)
signal fish_stored(species_id: String)
signal achievement_reached(def: AchievementDef)

@warning_ignore_restore("unused_signal")

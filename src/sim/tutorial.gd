class_name Tutorial
extends RefCounted
## The first steps of a new game. A card at the top tells the player what to do next, and an
## arrow on the beach shows where to walk: fetch fish until the basket is full, put them into the
## tank, sell a grown fish at the booth, then go into the gear shop. The step is saved in
## PlayerState.tutorial_step. Saves from before the tutorial existed start with it done.

enum Step {
	## Welcome: wade into the sea and fill the basket.
	CATCH,
	## The basket is full: put the catch into the tank.
	STORE,
	## Wait for a fish to grow, then sell it at the player's booth.
	SELL,
	## Spend the coins at the gear shop.
	GEAR,
	DONE,
}


## Moves the tutorial on if it is at `step`; does nothing at any other step.
static func complete(state: PlayerState, step: Step) -> void:
	if state.tutorial_step == step:
		state.tutorial_step = step + 1


static func is_done(state: PlayerState) -> bool:
	return state.tutorial_step >= Step.DONE

class_name Tutorial
extends RefCounted
## The first steps of a new game. A card at the top tells the player what to do next, and an
## arrow on the beach shows where to walk: fetch fish until the basket is full, put them into the
## tank, sell a grown fish at the booth, then go into the gear shop, where a tip over each pad
## says what it is for until the player buys something or leaves. Back at the booth, a last tip
## shows what the "Hire seller" pad, hidden until then, is for. The step is saved in
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
	## In the gear shop: what each pad is for.
	SHOP,
	## Back on the "Sell fish" pad: what the "Hire seller" pad is for, until a seller is hired.
	HIRE,
	DONE,
}


## Moves the tutorial on if it is at `step`; does nothing at any other step.
static func complete(state: PlayerState, step: Step) -> void:
	if state.tutorial_step == step:
		state.tutorial_step = step + 1


## True once the tutorial got to `step` (or past it).
static func reached(state: PlayerState, step: Step) -> bool:
	return state.tutorial_step >= step


static func is_done(state: PlayerState) -> bool:
	return state.tutorial_step >= Step.DONE

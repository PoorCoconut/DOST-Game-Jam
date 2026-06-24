extends Node

signal judgment_made(result)
signal score_updated(volts, watts)

const PERFECT_WINDOW: float = 0.05   # +-50ms
const GREAT_WINDOW: float = 0.083    # +-83ms
const GOOD_WINDOW: float = 0.116     # +-116ms

const AMPS: Dictionary = {
	"perfect": 10,
	"great": 5,
	"good": 2,
	"miss": 0,
}

var volts: int = 0
var watts: int = 0


func register_judgment(time_diff: float) -> String:
	var result: String = _get_judgment(time_diff)
	var amps: int = AMPS[result]

	if result == "miss":
		volts = 0
	else:
		volts += 1
		watts += volts * amps

	judgment_made.emit(result)
	score_updated.emit(volts, watts)

	# for debug
	print("[DEBUG] %s | Amps: %d | Volts: %d | Watts: %d" % [result.to_upper(), amps, volts, watts])

	return result


func register_hold_judgment(base_amps: int, beats_held: float, completed: bool) -> void:
	# amps = base amps from head press * beats actually held
	var amps: int = int(base_amps * beats_held)

	if completed:
		volts += 1
	else:
		# early release — combo resets
		volts = 0

	watts += volts * amps

	var result: String = "hold_complete" if completed else "hold_early"
	judgment_made.emit(result)
	score_updated.emit(volts, watts)

	# for debug
	print("[DEBUG] HOLD %s | Base Amps: %d | Beats Held: %.2f | Amps: %d | Volts: %d | Watts: %d" % [
		"COMPLETE" if completed else "EARLY", base_amps, beats_held, amps, volts, watts
	])


# didn't click
func register_miss() -> void:
	register_judgment(INF)


# timings
func _get_judgment(time_diff: float) -> String:
	if time_diff <= PERFECT_WINDOW:
		return "perfect"
	elif time_diff <= GREAT_WINDOW:
		return "great"
	elif time_diff <= GOOD_WINDOW:
		return "good"
	else:
		return "miss"


func reset() -> void:
	volts = 0
	watts = 0

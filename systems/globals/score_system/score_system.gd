extends Node

signal judgment_made(result)
signal score_updated(volts, watts)

#adjust please
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
	
	
	#debug rani
	print("[DEBUG] %s | Amps: %d | Volts: %d | Watts: %d" % [result.to_upper(), amps, volts, watts])
	
	
	return result

#didn't click
func register_miss() -> void:
	register_judgment(INF)

#timings
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

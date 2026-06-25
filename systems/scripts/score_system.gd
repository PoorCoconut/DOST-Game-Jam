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

const ACCURACY_RATIO: Dictionary = {
	"perfect": 1.0,
	"great": 0.5,
	"good": 0.2,
	"miss": 0.0,
}

const MAX_SCORE: int = 900000
const ACCURACY_PORTION: float = 0.9   # 90% from accuracy
const COMBO_PORTION: float = 0.1      # 10% from combo

var volts: int = 0
var watts: float = 0.0               # float internally to avoid rounding loss

var total_note_weight: float = 0.0
var max_combo: int = 0
var base_score_per_weight: float = 0.0
var combo_bonus_per_note: float = 0.0


func load_chart(chart_resource) -> void:
	total_note_weight = 0.0
	max_combo = 0

	for note in chart_resource.notes:
		if note.is_hold_note():
			total_note_weight += note.beat_end - note.beat_start
		else:
			total_note_weight += 1.0
		max_combo += 1

	if total_note_weight > 0:
		base_score_per_weight = (MAX_SCORE * ACCURACY_PORTION) / total_note_weight

	if max_combo > 0:
		combo_bonus_per_note = (MAX_SCORE * COMBO_PORTION) / float(max_combo)


func register_judgment(time_diff: float) -> String:
	var result: String = _get_judgment(time_diff)
	var amps: int = AMPS[result]

	if result == "miss":
		volts = 0
	else:
		volts += 1
		watts += base_score_per_weight * ACCURACY_RATIO[result]
		watts += combo_bonus_per_note

	judgment_made.emit(result)
	score_updated.emit(volts, int(watts))

	# for debug
	print("[DEBUG] %s | Amps: %d | Volts: %d | Watts: %d" % [result.to_upper(), amps, volts, int(watts)])
	return result


func register_hold_judgment(base_amps: int, beats_held: float, completed: bool) -> void:
	# amps = base amps from head press * beats actually held
	var amps: int = int(base_amps * beats_held)

	if completed:
		volts += 1
		watts += base_score_per_weight * beats_held * ACCURACY_RATIO[_amps_to_judgment(base_amps)]
		watts += combo_bonus_per_note
	else:
		# early release — combo resets, partial accuracy score only
		volts = 0
		watts += base_score_per_weight * beats_held * ACCURACY_RATIO[_amps_to_judgment(base_amps)]

	var result: String = "hold_complete" if completed else "hold_early"
	judgment_made.emit(result)
	score_updated.emit(volts, int(watts))

	# debug rani
	print("[DEBUG] HOLD %s | Base Amps: %d | Beats Held: %.2f | Amps: %d | Volts: %d | Watts: %d" % [
		"COMPLETE" if completed else "EARLY", base_amps, beats_held, amps, volts, int(watts)
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


func _amps_to_judgment(amps: int) -> String:
	# converts base_amps back to judgment string for hold scoring
	match amps:
		10: return "perfect"
		5: return "great"
		2: return "good"
		_: return "miss"


func reset() -> void:
	volts = 0
	watts = 0.0

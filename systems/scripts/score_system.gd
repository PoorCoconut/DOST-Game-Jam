extends Node

signal judgment_made(result)
signal score_updated(volts, watts)
signal hp_changed(current_hp, max_hp)  # emitted on every HP change so FrequencyBar can react
signal player_failed                   # emitted when HP reaches 0

const PERFECT_WINDOW: float = 0.05   # +-50ms
const GOOD_WINDOW: float = 0.083     # +-83ms
const BAD_WINDOW: float = 0.116      # +-116ms
# anything beyond bad window = miss

const AMPS: Dictionary = {
	"perfect": 10,
	"good": 6,
	"bad": 2,
	"miss": 0,
}

const ACCURACY_RATIO: Dictionary = {
	"perfect": 1.0,
	"good": 0.6,
	"bad": 0.2,
	"miss": 0.0,
}

const MAX_AMP_SCORE: int = 900000
const MAX_VOLT_SCORE: int = 100000
const MAX_BONUS_SCORE: int = 0        # placeholder — Solar/Hydro bonus, not implemented yet
const MAX_SCORE: int = MAX_AMP_SCORE + MAX_VOLT_SCORE + MAX_BONUS_SCORE

var volts: int = 0
var watts: float = 0.0

# per-chart stats
var total_notes: int = 0
var base_amp_per_note: float = 0.0
var base_volt_per_note: float = 0.0

# judgment counters for ranking panel
var perfects: int = 0
var goods: int = 0
var bads: int = 0
var misses: int = 0

# HP settings — adjust these freely, balazon is indecisive HAHAHA
var hp_perfect: float = 2.0    # HP gained on perfect hit
var hp_good: float = 1.0       # HP gained on good hit
var hp_bad: float = 0.5        # HP gained on bad hit
var hp_miss_ratio: float = 0.1 # HP lost on miss (10% of max HP)

# HP state — managed here, displayed by FrequencyBarComponent
var current_hp: float = 100.0
var max_hp: float = 100.0


func load_chart(chart_resource) -> void:
	total_notes = 0
	perfects = 0
	goods = 0
	bads = 0
	misses = 0
	volts = 0
	watts = 0.0
	current_hp = max_hp  # reset HP on new chart

	for note in chart_resource.notes:
		if note.is_hold_note():
			# hold note counts as beat_duration slices
			total_notes += int(round(note.beat_end - note.beat_start))
		else:
			total_notes += 1

	if total_notes > 0:
		base_amp_per_note = float(MAX_AMP_SCORE) / float(total_notes)
		base_volt_per_note = float(MAX_VOLT_SCORE) / float(total_notes)


func register_judgment(time_diff: float) -> String:
	var result: String = _get_judgment(time_diff)
	_record_judgment(result)
	_apply_hp(result)

	if result == "miss":
		volts = 0
	else:
		volts += 1
		watts += base_amp_per_note * ACCURACY_RATIO[result]
		watts += base_volt_per_note

	judgment_made.emit(result)
	score_updated.emit(volts, roundi(watts))

	# for debug
	print("[DEBUG] %s | Volts: %d | Watts: %d | HP: %.1f" % [result.to_upper(), volts, roundi(watts), current_hp])
	return result


func register_hold_slice(result: String) -> void:
	# called once per beat slice while a hold note is active
	_record_judgment(result)
	_apply_hp(result)

	if result == "miss":
		volts = 0
	else:
		volts += 1
		watts += base_amp_per_note * ACCURACY_RATIO[result]
		watts += base_volt_per_note

	judgment_made.emit(result)
	score_updated.emit(volts, roundi(watts))

	# for debug
	print("[DEBUG] HOLD SLICE %s | Volts: %d | Watts: %d | HP: %.1f" % [result.to_upper(), volts, roundi(watts), current_hp])


# didn't click
func register_miss() -> void:
	register_judgment(INF)


func get_rank() -> String:
	var score = int(watts)
	if score >= 1000000: return "AP"
	elif score >= 960000: return "S"
	elif score >= 920000: return "A"
	elif score >= 840000: return "B"
	elif score >= 760000: return "C"
	elif score >= 600000: return "D"
	else: return "F"


func _apply_hp(result: String) -> void:
	match result:
		"perfect": current_hp = min(current_hp + hp_perfect, max_hp)
		"good":    current_hp = min(current_hp + hp_good, max_hp)
		"bad":     current_hp = min(current_hp + hp_bad, max_hp)
		"miss":    current_hp = max(current_hp - (max_hp * hp_miss_ratio), 0.0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		player_failed.emit()


func _record_judgment(result: String) -> void:
	match result:
		"perfect": perfects += 1
		"good": goods += 1
		"bad": bads += 1
		"miss": misses += 1


# timings
func _get_judgment(time_diff: float) -> String:
	if time_diff <= PERFECT_WINDOW:
		return "perfect"
	elif time_diff <= GOOD_WINDOW:
		return "good"
	elif time_diff <= BAD_WINDOW:
		return "bad"
	else:
		return "miss"


func reset() -> void:
	volts = 0
	watts = 0.0
	perfects = 0
	goods = 0
	bads = 0
	misses = 0
	current_hp = max_hp

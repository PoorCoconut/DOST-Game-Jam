extends Node

signal judgement_made(result)
signal score_updated(volts, watts)
signal hp_changed(current_hp, max_hp)  # emitted on every HP change so FrequencyBar can react
signal player_failed                   # emitted when HP reaches 0

const PERFECT_WINDOW: float = 0.05     # +-50ms
const GOOD_WINDOW: float = 0.083       # +-83ms
const BAD_WINDOW: float = 0.116        # +-116ms
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

const MAX_AMP_SCORE: int   = 900000
const MAX_VOLT_SCORE: int  = 100000
const MAX_BONUS_SCORE: float = 100000.0  # SOLAR power-up, does NOT overflow
const MAX_SCORE: int = MAX_AMP_SCORE + MAX_VOLT_SCORE

var volts: int = 0           # combo
var max_volts: int = 0       # highest combo
var base_watts: float = 0.0  # watts before the bonus
var watts: float = 0.0       # score

# per-chart stats
var total_notes: int = 0
var base_amp_per_note: float = 0.0
var base_volt_per_note: float = 0.0

# judgement counters for ranking panel
var perfects: int = 0
var goods: int = 0
var bads: int = 0
var misses: int = 0

# HP settings
var hp_perfect: float = 2.0      # HP gained on perfect hit
var hp_good: float = 1.0         # HP gained on good hit
var hp_bad: float = 0.5          # HP gained on bad hit
var hp_miss_ratio: float = 0.1   # HP lost on miss (10% of max HP)

var hp_lite_hit: float = hp_good # HP gained on lite note hit
var hp_lite_miss: float = 0.05   # HP lost on lite note misses (5% of max HP)

# HP state — managed here, displayed by FrequencyBarComponent
var current_hp: float = 100.0
var max_hp: float = 100.0
var is_failed: bool = false      # true once HP hits 0 — forces F rank regardless of watts

# geo skill, overflow hp
var overflow_hp: float = 0.0

# solar skill, overflow watts
var solar_bonus: float = 0.0


func load_chart(chart_resource: ChartData) -> void:
	_reset()
	
	# use the built-in function of ChartData
	total_notes = chart_resource.total_notes()
	
	if total_notes > 0:
		base_amp_per_note = float(MAX_AMP_SCORE) / float(total_notes)
		base_volt_per_note = float(MAX_VOLT_SCORE) / float(total_notes)


func register_judgement(time_diff: float) -> String:
	var result: String = _get_judgement(time_diff)
	_record_judgement(result)
	_apply_hp(result)

	if result == "miss":
		# WIND GATE (Combo Protection Trade-off)
		if MatchRules.current_skill == "wind" and MatchRules.is_overdrive:
			MatchRules.reset_sustain_meter()
			MatchRules.is_overdrive = false
		else:
			volts = 0
	else:
		volts += 1
		max_volts = max(max_volts, volts)
		
		var raw_score = base_amp_per_note * ACCURACY_RATIO[result]
		
		base_watts += raw_score
		base_watts += base_volt_per_note
		
		MatchRules.add_sustain(raw_score + base_volt_per_note)
		
		if MatchRules.current_skill == "solar" and MatchRules.is_overdrive and result == "perfect":
			var bonus_gain = raw_score * 0.5
			solar_bonus = min(solar_bonus + bonus_gain, MAX_BONUS_SCORE)

	watts = base_watts + solar_bonus

	judgement_made.emit(result)
	score_updated.emit(volts, roundi(watts))

	# DEBUG
	print("[SCORE] %s | Volts: %d | Watts: %d | HP: %.1f" % [result.to_upper(), volts, roundi(watts), current_hp])
	return result


func register_hold_slice(result: String) -> void:
	# called once per beat slice while a hold note is active
	_record_judgement(result)
	_apply_hp(result)

	if result == "miss":
		if MatchRules.current_skill == "wind" and MatchRules.is_overdrive:
			MatchRules.reset_sustain_meter()
			MatchRules.is_overdrive = false
		else:
			volts = 0
	else:
		volts += 1
		max_volts = max(max_volts, volts)
		
		var raw_score = base_amp_per_note * ACCURACY_RATIO[result]
		
		base_watts += raw_score
		base_watts += base_volt_per_note
		
		# add to sustain
		MatchRules.add_sustain(raw_score + base_volt_per_note)
		
		if MatchRules.current_skill == "solar" and MatchRules.is_overdrive and result == "perfect":
			var bonus_gain = raw_score * 0.5
			solar_bonus = min(solar_bonus + bonus_gain, MAX_BONUS_SCORE)

	# 3. Final score assembly before emitting (happens hit or miss)
	watts = base_watts + solar_bonus

	judgement_made.emit(result)
	score_updated.emit(volts, roundi(watts))

	# DEBUG
	# print("[SCORE] HOLD SLICE %s | Volts: %d | Watts: %d | HP: %.1f" % [result.to_upper(), volts, roundi(watts), current_hp])


func register_lite_hit() -> void:
	_record_judgement("perfect")
	_apply_hp_direct(hp_lite_hit)
	
	volts += 1
	max_volts = max(max_volts, volts)
	
	var raw_score = base_amp_per_note * ACCURACY_RATIO["perfect"]
	
	base_watts += raw_score
	base_watts += base_volt_per_note
	
	#add to sustain
	MatchRules.add_sustain(raw_score + base_volt_per_note)
	
	if MatchRules.current_skill == "solar" and MatchRules.is_overdrive:
		var bonus_gain = raw_score * 0.5
		solar_bonus = min(solar_bonus + bonus_gain, MAX_BONUS_SCORE)
	
	watts = base_watts + solar_bonus
	
	judgement_made.emit("perfect")
	score_updated.emit(volts, roundi(watts))


func register_lite_miss() -> void:
	_record_judgement("miss")
	_apply_hp_direct(-(max_hp * hp_lite_miss))
	
	if MatchRules.current_skill == "wind" and MatchRules.is_overdrive:
		MatchRules.reset_sustain_meter()
		pass
	else:
		volts = 0
	
	judgement_made.emit("miss")
	score_updated.emit(volts, roundi(watts))
	print("[SCORE] LITE MISS | Combo Reset | HP: %.1f" % current_hp)
	


# didn't click
func register_miss() -> void:
	register_judgement(INF)


func get_rank() -> String:
	if is_failed:
		return "F"
	var score = int(watts)
	if score >= 1000000: return "AP"
	elif score >= 960000: return "S"
	elif score >= 920000: return "A"
	elif score >= 840000: return "B"
	elif score >= 760000: return "C"
	elif score >= 600000: return "D"
	else: return "F"


func _apply_hp(result: String) -> void:
	var damage = 0.0
	match result:
		"perfect": current_hp = min(current_hp + hp_perfect, max_hp)
		"good":    current_hp = min(current_hp + hp_good, max_hp)
		"bad":     current_hp = min(current_hp + hp_bad, max_hp)
		"miss":    current_hp = max(current_hp - (max_hp * hp_miss_ratio), 0.0)
	
	if result == "miss":
		# geo skill
		#print("skill =  ", MatchRules.current_skill, " overdrive = ", MatchRules.is_overdrive, " overflow = ", overflow_hp)
		if MatchRules.current_skill == "geo" and MatchRules.is_overdrive and overflow_hp > 0:
			overflow_hp = max(overflow_hp - damage, 0.0)
			print("overflow hp active, remaining = ", overflow_hp)
		else:
			current_hp = max(current_hp - damage, 0.0)
			
	hp_changed.emit(current_hp, max_hp)
	
	# Invincibility override
	if MatchRules.is_invincible:
		current_hp = max_hp
		return
	
	if current_hp <= 0 and not is_failed:
		is_failed = true
		player_failed.emit()

# USED FOR LITE NOTES
func _apply_hp_direct(amount: float) -> void:
	# Calculate potential damage if amount is negative
	var damage = -amount if amount < 0 else 0.0
	
	# geo skill
	#print("skill =  ", MatchRules.current_skill, " overdrive = ", MatchRules.is_overdrive, " overflow = ", overflow_hp)
	if damage > 0 and MatchRules.current_skill == "geo" and overflow_hp > 0:
		overflow_hp = max(overflow_hp - damage, 0.0)
		print("overflow hp active, remaining = ", overflow_hp)
		hp_changed.emit(current_hp, max_hp)
		return
	
	# normal
	current_hp = clamp(current_hp + amount, 0.0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	
	if MatchRules.is_invincible:
		current_hp = max_hp
		return
	
	if current_hp <= 0 and not is_failed:
		is_failed = true
		player_failed.emit()


func _record_judgement(result: String) -> void:
	match result:
		"perfect": perfects += 1
		"good": goods += 1
		"bad": bads += 1
		"miss": misses += 1


# timings
func _get_judgement(time_diff: float) -> String:
	# hydro skill and rock hard
	var multiplier = 1.0
	if MatchRules.current_skill == "hydro" and MatchRules.is_overdrive: multiplier *= 1.5
	if MatchRules.mod_hard_rock: multiplier *= 0.75
	
	if time_diff <= PERFECT_WINDOW * multiplier:
		return "perfect"
	elif time_diff <= GOOD_WINDOW * multiplier:
		return "good"
	elif time_diff <= BAD_WINDOW * multiplier:
		return "bad"
	else:
		return "miss"


func _reset() -> void:
	total_notes = 0
	perfects = 0
	goods = 0
	bads = 0
	misses = 0
	volts = 0
	max_volts = 0
	base_watts = 0.0
	watts = 0.0
	current_hp = max_hp
	overflow_hp = 0.0
	solar_bonus = 0.0
	is_failed = false

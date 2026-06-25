extends Node

#idk how this work much so this is just how i assumed how things worked
signal energy_changed(new_energy)
signal meter_changed(value)
signal skill_ready_changed(is_ready)
signal skill_activated(energy, debuff_strength)

enum Energy { SOLAR, HYDRO, WIND, GEO }

@export var meter_max: float = 100.0
@export var combo_threshold: int = 10

var current_energy: Energy = Energy.SOLAR
var combo: int = 0
var meter: float = 0.0
var skill_ready: bool = false


func set_energy(energy: Energy) -> void:
	current_energy = energy
	energy_changed.emit(current_energy)


func register_hit() -> void:
	combo += 1
	var fill_amount: float = 2.0 + (combo * 0.5)
	meter = min(meter + fill_amount, meter_max)
	meter_changed.emit(meter / meter_max)

	if meter >= meter_max and not skill_ready:
		skill_ready = true
		skill_ready_changed.emit(true)


func register_miss() -> void:
	combo = 0
	meter = 0.0
	skill_ready = false
	meter_changed.emit(0.0)
	skill_ready_changed.emit(false)


func try_activate_skill() -> bool:
	if not skill_ready:
		return false

	return true

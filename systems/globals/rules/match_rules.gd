extends Node

# LEVEL EDITOR AND REPLAYER STATES
# can: true by default
# is:  false by default
# level_editor flips all of these
var is_autoplay: bool   = false
var is_preview: bool    = false
var is_invincible: bool = false
var can_pause: bool     = true
var can_record: bool    = true

# SKILL SYSTEM
var sustain_meter: float = 0.0
var is_overdrive: bool = false
const SUSTAIN_MAX: float = 200000.0
var current_skill: String = ""

# MOD SYSTEM
var mod_fading_light: bool = false
var mod_double_time: bool  = false
var mod_flow_state: bool   = false
var mod_hard_rock: bool    = false

func _ready() -> void:
	# hardcode time
	current_skill = "wind"
	mod_flow_state = false
	mod_double_time = false
	mod_flow_state = false
	mod_hard_rock = false
	
	sustain_meter = 199999
	print("sustain: ", sustain_meter)

func level_editor(enable: bool) -> void:
	if enable:
		is_autoplay   = true
		is_preview    = true
		is_invincible = true
		can_pause     = false
		can_record    = false
	else:
		is_autoplay   = false
		is_preview    = false
		is_invincible = false
		can_pause     = true
		can_record    = true


# Reset all variables
func reset_all() -> void:
	is_autoplay   = false
	is_preview    = false
	is_invincible = false
	can_pause     = true
	can_record    = true
	
	sustain_meter = 0.0
	is_overdrive  = false
	
	mod_fading_light = false
	mod_double_time  = false
	mod_flow_state   = false
	mod_hard_rock    = false


func add_sustain(amount: float) -> void:
	if mod_flow_state:
		return
		
	sustain_meter += amount
	if sustain_meter >= SUSTAIN_MAX and not is_overdrive:
		activate_overdrive()

func reset_sustain_meter() ->void:
	MatchRules.sustain_meter = 0.0
	MatchRules.is_overdrive = false
func activate_overdrive() -> void:
	is_overdrive = true
	print("OVERDRIVEEEEEEEEEEEEEEEEEEEEE")
	
	if current_skill == "geo":
		ScoreSystem.overflow_hp = 50.0
		print("DEBUG: Geo Overflow set to: ", ScoreSystem.overflow_hp)
	
	

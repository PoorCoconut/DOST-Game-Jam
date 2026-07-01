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

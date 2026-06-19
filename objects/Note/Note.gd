extends Area2D

var target_beat: float = 0.0
var lane: int = 0
var scroll_speed: float = 100.0 # Pixels per beat

# This is where the hit line is on your screen (e.g., y = 500)
var hit_line_y: float = 500.0 

func _process(_delta):
	# The math: (My Target Beat - Current Beat) * Speed
	# As current_beat gets closer to target_beat, the distance becomes 0
	var current_beat = Conductor.song_position / Conductor.seconds_per_beat
	var distance_to_hit_line = (target_beat - current_beat) * scroll_speed
	
	position.y = hit_line_y - distance_to_hit_line
	
	# Optional: Delete note if it goes too far past the hit line
	if position.y > hit_line_y + 100:
		queue_free()

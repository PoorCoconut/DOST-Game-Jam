extends Node2D

var lane: int = 0                             # which lane the note starts
var direction_vector: Vector2 = Vector2.ZERO  # direction line of the note
var target_time: float = 0.0                  # when the note should be hit
var judged: bool = false                      # true once head is pressed or missed
# @onready var parent_scale = get_parent().global_scale

func setup(p_lane: int, p_target_time: float, p_direction: Vector2) -> void:
	lane = p_lane
	target_time = p_target_time
	direction_vector = p_direction.normalized()
	rotation = direction_vector.angle() + (PI / 2.0)
	
	var current_time = Conductor.get_time()
	var time_until_hit = target_time - current_time
	var distance = max((time_until_hit * Conductor.SCROLL_SPEED) + Conductor.HIT_RADIUS, 0.0)
	position = direction_vector * distance
	
	visible = true


func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	if judged: return
	
	var current_time = Conductor.get_time()
	var parent_scale = get_parent().global_scale.x
	var time_until_hit = target_time - current_time
	var distance = (time_until_hit * Conductor.SCROLL_SPEED) + Conductor.HIT_RADIUS / parent_scale
	position = direction_vector * distance
	if time_until_hit < -Conductor.MISS_WINDOW:
		on_miss()
	
	# debug auto-clicker
	# if time_until_hit < 0:
	#	SoundManager.play_hitsound(0)
	#	judged = true
	#	ScoreSystem.register_judgment(0)
	#	destroy()


func on_miss():
	judged = true
	ScoreSystem.register_miss()
	VisualEffects.play_note_miss(self)
	if not is_inside_tree(): return  # add this
	await get_tree().create_timer(0.15).timeout
	queue_free()

func destroy():
	judged = true
	VisualEffects.play_note_hit(self)
	if not is_inside_tree(): return  # add this
	await get_tree().create_timer(0.15).timeout
	queue_free()

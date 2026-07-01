extends Node2D

var lane: int = 0                             # which lane the note starts
var direction_vector: Vector2 = Vector2.ZERO  # direction line of the note
var target_time: float = 0.0                  # when the note should be hit
var judged: bool = false                      # true once head is pressed or missed
var is_lite: bool = false                     # needs to be pressed, not "just pressed"


func _actual_speed() -> float:
	return Conductor.BASE_SCROLL_SPEED * Settings.current_scroll_speed


func setup(p_lane: int, p_target_time: float, p_direction: Vector2, p_is_lite: bool) -> void:
	lane = p_lane
	target_time = p_target_time
	direction_vector = p_direction.normalized()
	is_lite = p_is_lite
	rotation = direction_vector.angle() + (PI / 2.0)

	var current_time = Conductor.get_time()
	var time_until_hit = target_time - current_time
	var speed := _actual_speed()
	var distance = max((time_until_hit * speed) + Conductor.HIT_RADIUS, 0.0)
	position = direction_vector * distance

	visible = true


func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	if judged: return

	var current_time = Conductor.get_time()
	var parent_scale = get_parent().global_scale.x
	var time_until_hit = target_time - current_time
	var speed := _actual_speed()

	var distance = max((time_until_hit * speed) + (Conductor.HIT_RADIUS / parent_scale), 0.0)
	position = direction_vector * distance

	if MatchRules.mod_fading_light:
		modulate.a = VisualEffects.get_fading_alpha(distance)
	else:
		modulate.a = 1.0

	var effective_miss_window: float = Conductor.MISS_WINDOW / Settings.current_scroll_speed
	if time_until_hit < -effective_miss_window:
		on_miss()


func on_miss():
	judged = true
	if is_lite:
		ScoreSystem.register_lite_miss()
	else:
		ScoreSystem.register_miss()
	
	VisualEffects.play_note_miss(self)
	if not is_inside_tree(): return
	await get_tree().create_timer(0.15).timeout
	queue_free()


func destroy():
	judged = true
	VisualEffects.play_note_hit(self)
	if not is_inside_tree(): return
	await get_tree().create_timer(0.15).timeout
	queue_free()

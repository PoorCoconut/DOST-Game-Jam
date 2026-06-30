extends Node2D

var lane: int = 0
var direction_vector: Vector2 = Vector2.ZERO
var target_time: float = 0.0
var end_time: float = 0.0
var beat_duration: float = 0.0
var judged: bool = false
var is_held: bool = false
var head_judgment: String = "miss"
var press_time: float = 0.0
var last_tick_beat: float = 0.0

var slices_total: int = 0
var slices_hit: int = 0
var next_slice_beat: float = 0.0

signal auto_resolved(note)

@onready var head: Node2D = $Head
@onready var tail: Node2D = $Tail
@onready var body: Line2D = $Body


func _actual_speed() -> float:
	return Conductor.BASE_SCROLL_SPEED * Settings.current_scroll_speed


func setup(p_lane: int, p_target_time: float, p_end_time: float, p_beat_duration: float, p_direction: Vector2) -> void:
	lane = p_lane
	target_time = p_target_time
	end_time = p_end_time
	beat_duration = p_beat_duration
	direction_vector = p_direction.normalized()
	slices_total = int(round(p_beat_duration))

	head.rotation = direction_vector.angle() + (PI / 2.0)
	tail.rotation = direction_vector.angle() + (PI / 2.0)

	var current_time = Conductor.get_time()
	var spd := _actual_speed()
	var time_until_head = target_time - current_time
	head.position = direction_vector * max((time_until_head * spd) + Conductor.HIT_RADIUS, Conductor.HIT_RADIUS)
	var time_until_tail = end_time - current_time
	tail.position = direction_vector * max((time_until_tail * spd) + Conductor.HIT_RADIUS, Conductor.HIT_RADIUS)
	body.clear_points()
	body.add_point(head.position)
	body.add_point(tail.position)
	visible = true


func _play_sound() -> void:
	if SoundManager.has_method("play_hitsound"):
		SoundManager.play_hitsound(lane)


func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	var parent_scale = get_parent().global_scale.x
	var now: float = Conductor.get_time()
	var spd := _actual_speed()

	# Lock head at hit radius while held, otherwise scroll toward center
	if is_held:
		head.position = direction_vector * Conductor.HIT_RADIUS
	else:
		var time_until_head: float = target_time - now
		var head_distance: float = max((time_until_head * spd) + (Conductor.HIT_RADIUS / parent_scale), Conductor.HIT_RADIUS / parent_scale)
		head.position = direction_vector * head_distance

	# Tail scrolls inward until it reaches the hit radius
	var time_until_tail: float = end_time - now
	var tail_distance: float = max((time_until_tail * spd) + Conductor.HIT_RADIUS, Conductor.HIT_RADIUS)
	tail.position = direction_vector * tail_distance

	body.clear_points()
	body.add_point(head.position)
	body.add_point(tail.position)

	# Auto-miss if head passes without being pressed
	var effective_miss_window: float = Conductor.MISS_WINDOW / Settings.current_scroll_speed
	if not judged and now > target_time + effective_miss_window:
		if SceneManager.is_replay and now < end_time:
			return
		_on_miss()
		return

	# Tick beat slices while held
	if is_held:
		var current_beat: float = Conductor.get_beat()
		while slices_hit < slices_total and current_beat >= next_slice_beat:
			ScoreSystem.register_hold_slice("perfect")
			slices_hit += 1
			next_slice_beat += 1.0

		# Auto-resolve if held through the tail
		if now >= end_time:
			is_held = false
			emit_signal("auto_resolved", self)
			_play_sound()
			VisualEffects.play_note_hit(self)
			if not is_inside_tree(): return
			await get_tree().create_timer(0.15).timeout
			queue_free()


func _on_miss() -> void:
	judged = true
	for i in range(slices_total):
		ScoreSystem.register_hold_slice("miss")
	VisualEffects.play_note_miss(self)
	if not is_inside_tree(): return
	await get_tree().create_timer(0.15).timeout
	queue_free()


func on_head_pressed(time_diff: float) -> void:
	judged = true
	is_held = true
	press_time = Conductor.get_time()
	head_judgment = ScoreSystem._get_judgment(time_diff)

	ScoreSystem.register_hold_slice(head_judgment)
	_play_sound()
	slices_hit = 1

	var head_beat: float = target_time / Conductor.seconds_per_beat
	next_slice_beat = head_beat + 1.0


func on_released() -> void:
	if not is_held:
		return

	is_held = false
	var now: float = Conductor.get_time()

	if now >= end_time:
		_play_sound()
		VisualEffects.play_note_hit(self)
		if not is_inside_tree(): return
		await get_tree().create_timer(0.15).timeout
		queue_free()
	else:
		while slices_hit < slices_total:
			ScoreSystem.register_hold_slice("miss")
			slices_hit += 1
		VisualEffects.play_note_miss(self)
		if not is_inside_tree(): return
		await get_tree().create_timer(0.15).timeout
		queue_free()

extends Node2D

var lane: int = 0                             # which lane the note starts
var direction_vector: Vector2 = Vector2.ZERO  # direction line of the note
var target_time: float = 0.0                  # when the head should be hit
var end_time: float = 0.0                     # when the tail ends
var beat_duration: float = 0.0                # total beats this note spans
var judged: bool = false                      # true once head is pressed or missed
var is_held: bool = false                     # true while player is holding
var head_judgment: String = "miss"            # judgment from head press
var press_time: float = 0.0                   # when the player pressed the head
var last_tick_beat: float = 0.0               # tracks the last sustain tick

# beat slice tracking
var slices_total: int = 0          # total beat slices for this hold note
var slices_hit: int = 0            # how many slices have been scored so far
var next_slice_beat: float = 0.0   # the beat time of the next slice to score

# Emitted when the note auto-resolves (held through the tail).
# Judgement listens to this so it can record the hold and clean up held_notes[].
signal auto_resolved(note)

@onready var head: Node2D = $Head
@onready var tail: Node2D = $Tail
@onready var body: Line2D = $Body


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
	var time_until_head = target_time - current_time
	head.position = direction_vector * max((time_until_head * Conductor.SCROLL_SPEED) + Conductor.HIT_RADIUS, Conductor.HIT_RADIUS)
	var time_until_tail = end_time - current_time
	tail.position = direction_vector * max((time_until_tail * Conductor.SCROLL_SPEED) + Conductor.HIT_RADIUS, Conductor.HIT_RADIUS)
	body.clear_points()
	body.add_point(head.position)
	body.add_point(tail.position)
	visible = true


func _play_sound() -> void:
	if SoundManager.has_method("play_hitsound"):
		SoundManager.play_hitsound(lane)


# okay this sounds bad, this is deactivated (in _process) by default for now
func _play_sound_on_tick() -> void:
	var current_beat: float = Conductor.get_beat()
	if is_held:
		if current_beat >= last_tick_beat + 1.0:
			SoundManager.play_tick(lane)
			last_tick_beat = floor(current_beat)


func _process(_delta: float) -> void:
	global_scale = Vector2.ONE
	var parent_scale = get_parent().global_scale.x
	var now: float = Conductor.get_time()

	# once held, lock the head at the hit radius instead of overshooting
	if is_held:
		head.position = direction_vector * Conductor.HIT_RADIUS
	else:
		var time_until_head: float = target_time - now
		var head_distance: float = (time_until_head * Conductor.SCROLL_SPEED) + Conductor.HIT_RADIUS / parent_scale
		head.position = direction_vector * head_distance

	# tail keeps moving inward until it reaches the hit radius
	var time_until_tail: float = end_time - now
	var tail_distance: float = max((time_until_tail * Conductor.SCROLL_SPEED) + Conductor.HIT_RADIUS, Conductor.HIT_RADIUS)
	tail.position = direction_vector * tail_distance

	# body connects head to tail
	body.clear_points()
	body.add_point(head.position)
	body.add_point(tail.position)

	# auto-miss if head passes without being pressed
	# During replay, never auto-miss — the replayer hits notes on its own schedule
	if not judged and now > target_time + Conductor.MISS_WINDOW:
		if SceneManager.is_replay:
			return
		_on_miss()
		return

	# tick beat slices while held
	if is_held:
		var current_beat: float = Conductor.get_beat()
		while slices_hit < slices_total and current_beat >= next_slice_beat:
			ScoreSystem.register_hold_slice("perfect")
			slices_hit += 1
			next_slice_beat += 1.0

		# auto-resolve if held through the tail
		if now >= end_time:
			is_held = false  # mark before emitting so on_released() no-ops if called again
			emit_signal("auto_resolved", self)  # notify Judgement to record + clean up
			_play_sound()
			VisualEffects.play_note_hit(self)
			if not is_inside_tree(): return
			await get_tree().create_timer(0.15).timeout
			queue_free()

	# deactivated
	# _play_sound_on_tick()


func _on_miss() -> void:
	judged = true
	# score all slices as miss
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

	# next slice is one beat after the head beat
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

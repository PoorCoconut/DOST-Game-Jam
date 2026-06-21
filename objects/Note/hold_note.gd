extends Node2D

var lane: int = 0
var target_time: float = 0.0       # when the head should be hit
var end_time: float = 0.0          # when the tail ends
var beat_duration: float = 0.0     # total beats this note spans
var judged: bool = false           # true once head is pressed or missed
var is_held: bool = false          # true while player is holding
var base_amps: int = 0             # amps earned from head press accuracy
var press_time: float = 0.0        # when the player pressed the head

@export var miss_window: float = 0.15
@export var HIT_RADIUS: float = 100.0
@export var scroll_speed: float = 600.0

var direction_vector: Vector2 = Vector2.ZERO

@onready var head: Node2D = $Head
@onready var tail: Node2D = $Tail
@onready var body: Line2D = $Body


func setup(p_lane: int, p_target_time: float, p_end_time: float, p_beat_duration: float, p_direction: Vector2) -> void:
	lane = p_lane
	target_time = p_target_time
	end_time = p_end_time
	beat_duration = p_beat_duration
	direction_vector = p_direction.normalized()
	head.rotation = direction_vector.angle() + (PI / 2.0)


func _process(_delta: float) -> void:
	var now: float = Conductor.get_time()

	# once held, lock the head at the hit radius instead of overshooting
	if is_held:
		head.position = direction_vector * HIT_RADIUS
	else:
		var time_until_head: float = target_time - now
		var head_distance: float = (time_until_head * scroll_speed) + HIT_RADIUS
		head.position = direction_vector * head_distance

	# tail keeps moving inward until it reaches the hit radius
	var time_until_tail: float = end_time - now
	var tail_distance: float = max((time_until_tail * scroll_speed) + HIT_RADIUS, HIT_RADIUS)
	tail.position = direction_vector * tail_distance

	# body connects head to tail
	body.clear_points()
	body.add_point(head.position)
	body.add_point(tail.position)

	# auto-miss if head passes without being pressed
	if not judged and now > target_time + miss_window:
		_on_miss()
		return

	# auto-resolve if held through the tail
	if is_held and now >= end_time:
		_resolve(beat_duration)


func on_head_pressed(time_diff: float) -> void:
	judged = true
	is_held = true
	press_time = Conductor.get_time()
	base_amps = ScoreSystem.AMPS[ScoreSystem._get_judgment(time_diff)]


func on_released() -> void:
	if not is_held:
		return

	var now: float = Conductor.get_time()

	if now >= end_time:
		_resolve(beat_duration)
	else:
		# early release — score based on how much was actually held
		var seconds_held: float = now - press_time
		var beats_held: float = seconds_held / Conductor.seconds_per_beat
		_resolve(beats_held)


func _resolve(beats_held: float) -> void:
	is_held = false
	ScoreSystem.register_hold_judgment(base_amps, beats_held, beats_held >= beat_duration)
	queue_free()


func _on_miss() -> void:
	judged = true
	ScoreSystem.register_miss()
	queue_free()

extends Node2D

var lane: int = 0
var target_time: float = 0.0
var travel_time: float = 5
var judged: bool = false

@export var miss_window: float = 0.18

var spawn_time: float = 0.0
var spawn_position: Vector2
var hit_position: Vector2


func setup(p_lane: int, p_target_time: float, p_travel_time: float, p_spawn_pos: Vector2, p_hit_pos: Vector2) -> void:
	lane = p_lane
	target_time = p_target_time
	travel_time = p_travel_time
	spawn_position = p_spawn_pos
	hit_position = p_hit_pos
	spawn_time = Conductor.get_time()
	position = spawn_position
	rotation = hit_position.angle() + (PI / 2.0)


func _process(_delta: float) -> void:
	var now: float = Conductor.get_time()
	var elapsed: float = now - spawn_time
	var progress: float = elapsed / travel_time

	position = spawn_position.lerp(hit_position, clamp(progress, 0.0, 1.3))

	if not judged and now > target_time + miss_window:
		judged = true
		ScoreSystem.register_miss()
		queue_free()
	elif progress >= 1.3:
		queue_free()


func destroy() -> void:
	judged = true
	modulate = Color(0.0, 0.0, 0.0, 1)
	scale = Vector2(1.5, 1.5)
	await get_tree().create_timer(0.15).timeout
	queue_free()

extends Node2D

var lane: int = 0
var target_time: float = 0.0
var judged: bool = false
@export var miss_window: float = 0.15
@export var HIT_RADIUS: float = 100.0

var scroll_speed: float = 600.0

var direction_vector: Vector2 = Vector2.ZERO

func setup(p_lane: int, p_target_time: float, p_direction: Vector2) -> void:
	lane = p_lane
	target_time = p_target_time
	direction_vector = p_direction.normalized()
	
	rotation = direction_vector.angle() + (PI / 2.0)

func _process(_delta: float) -> void:
	if judged: return
	
	var current_time = Conductor.get_time()
	var time_until_hit = target_time - current_time
	var distance = (time_until_hit * scroll_speed) + HIT_RADIUS
	position = direction_vector * distance
	if time_until_hit < -miss_window:
		on_miss()

func on_miss():
	judged = true
	ScoreSystem.register_miss()
	queue_free()
	
func destroy():
	judged = true
	modulate = Color(0.0, 0.0, 0.0, 1)
	scale = Vector2(1.5, 1.5)
	await get_tree().create_timer(0.15).timeout
	queue_free()

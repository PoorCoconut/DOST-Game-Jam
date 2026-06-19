extends Node


var time_elapsed: float = 0.0
var is_running: bool = false


func start() -> void:
	time_elapsed = 0.0
	is_running = true


func stop() -> void:
	is_running = false


func _process(delta: float) -> void:
	if is_running:
		time_elapsed += delta


func get_time() -> float:
	return time_elapsed

# song_scrubber.gd
extends Control

signal seek_requested(time_seconds: float)

@export var duration: float = 1.0
var progress: float = 0.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_seek_from_x(mb.position.x)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_seek_from_x((event as InputEventMouseMotion).position.x)

func _seek_from_x(x: float) -> void:
	var ratio: float = clamp(x / size.x, 0.0, 1.0)
	seek_requested.emit(ratio * duration)

func update_progress(time_seconds: float) -> void:
	if duration <= 0:
		return
	progress = clamp(time_seconds / duration, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.15))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * progress, size.y)), Color.CYAN)
	_draw_playhead_marker()

func _draw_playhead_marker() -> void:
	var x := size.x * progress
	draw_line(Vector2(x, 0), Vector2(x, size.y), Color.RED, 3.0)
	# small triangle cap on top so it's visible even at a glance
	var tri := PackedVector2Array([
		Vector2(x - 5, 0), Vector2(x + 5, 0), Vector2(x, 8)
	])
	draw_colored_polygon(tri, Color.WHITE)

# ring_scale_controller.gd
extends Node2D

var chart: ChartData
var current_event_index: int = -1
var active_tween: Tween

func _ready() -> void:
	chart = SceneManager.selected_chart
	reset_to_default()

func _process(_delta: float) -> void:
	if chart == null or chart.scale_events.is_empty():
		return
	var beat := Conductor.get_beat()
	var idx := -1
	for i in range(chart.scale_events.size()):
		if chart.scale_events[i].beat <= beat:
			idx = i
		else:
			break
	if idx != current_event_index and idx >= 0:
		current_event_index = idx
		_apply_event(chart.scale_events[idx])

func _apply_event(ev: ScaleEvent) -> void:
	if active_tween:
		active_tween.kill()
	var duration_sec := ev.duration_beats * Conductor.seconds_per_beat
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2.ONE * ev.target_scale, max(duration_sec, 0.01))

func reset_to_default() -> void:
	if active_tween:
		active_tween.kill()
	current_event_index = -1
	scale = Vector2.ONE

func recalculate_for_beat(beat: float) -> void:
	if active_tween:
		active_tween.kill()
	current_event_index = -1
	for i in range(chart.scale_events.size()):
		if chart.scale_events[i].beat <= beat:
			current_event_index = i
		else:
			break
	if current_event_index >= 0:
		scale = Vector2.ONE * chart.scale_events[current_event_index].target_scale
	else:
		scale = Vector2.ONE

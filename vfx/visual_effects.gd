extends Node

# this should probably be renamed to NoteEffects

@export var plus_color: Color = Color.WHITE
@export var x_color:    Color = Color(0.49, 0.745, 1.0, 1.0)
@export var sync_color: Color = Color(2.0, 1.5, 0.0)
@export var lite_color: Color = Color(0.75, 0.45, 1.0) 


func setup_note_visuals(note: Node2D, mode: String) -> void:
	note.global_scale = Vector2.ONE
	
	if note.get("is_lite") == true:
		note.modulate = lite_color
		note.modulate.a = 0.7 
	else:
		if mode == "+":
			note.modulate = plus_color
		else:
			note.modulate = x_color


func apply_sync_visuals(note_group: Array) -> void:
	for note in note_group:
		note.modulate = sync_color


# fading light
func get_fading_alpha(distance_to_center: float) -> float:
	return clamp(distance_to_center / 400.0, 0.0, 1.0)


func play_note_miss(note: Node2D) -> void:
	note.set_process(false)
	
	var tween = create_tween()
	note.modulate = Color(0.37, 0.111, 0.111, 1.0)
	tween.tween_property(note, "modulate:a", 0.0, 0.2)


func play_note_hit(note: Node2D):
	note.set_process(false) 
	
	var tween = create_tween().set_parallel(true)
	var parent_scale = note.get_parent().global_scale
	
	tween.tween_property(note, "scale", Vector2(1.3, 1.3) / parent_scale, 0.15)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(note, "modulate", Color(2, 2, 2, 1), 0.05)
	
	tween.tween_property(note, "modulate:a", 0.0, 0.2)\
		.set_delay(0.05)

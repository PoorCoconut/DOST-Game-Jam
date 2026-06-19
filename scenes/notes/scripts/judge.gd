extends Node

const LANE_ACTIONS: Array = ["lane1", "lane2", "lane3", "lane4"]
const TRANSFORM_ACTION: String = "transform"

@onready var spawner: Node = get_node("../Spawner")

var current_mode: String = "plus"


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(TRANSFORM_ACTION):
		current_mode = "x" if current_mode == "plus" else "plus"
		print("Transform → ", "High Current" if current_mode == "x" else "Low Current")

	for lane in range(LANE_ACTIONS.size()):
		if Input.is_action_just_pressed(LANE_ACTIONS[lane]):
			_try_hit(lane)


func _try_hit(lane: int) -> void:
	var now: float = Conductor.get_time()
	var notes: Array = spawner.active_notes[current_mode][lane]

	var closest_note: Node2D = null
	var closest_diff: float = INF

	for note in notes:
		if not is_instance_valid(note) or note.judged:
			continue

		var diff: float = abs(note.target_time - now)
		if diff < closest_diff:
			closest_diff = diff
			closest_note = note

	if closest_note == null or closest_diff > ScoreSystem.GOOD_WINDOW:
		return

	closest_note.judged = true

	ScoreSystem.register_judgment(closest_diff)

	if closest_note.has_method("destroy"):
		closest_note.destroy()
	else:
		closest_note.queue_free()

extends Node

const LANE_ACTIONS: Array = ["lane1", "lane2", "lane3", "lane4"]
const TRANSFORM_ACTION: String = "transform"

@onready var spawner: Node = get_node("../Spawner")
@onready var sustain_ring: Node2D = get_node("../Sustain_Ring")

var current_mode: String = "+"

# tracks which hold note is currently being held per lane
var held_notes: Array = [null, null, null, null]


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(TRANSFORM_ACTION):
		current_mode = "x" if current_mode == "+" else "+"
		print("Transform → ", "High Current" if current_mode == "x" else "Low Current")
		sustain_ring.rotation_degrees = 45.0 if current_mode == "x" else 0.0

	for lane in range(LANE_ACTIONS.size()):
		if Input.is_action_just_pressed(LANE_ACTIONS[lane]):
			_try_hit(lane)
		elif Input.is_action_just_released(LANE_ACTIONS[lane]):
			_try_release(lane)
			


func _try_hit(lane: int) -> void:
	var now: float = Conductor.get_time()

	# check hold notes first
	var hold_notes: Array = spawner.active_hold_notes[current_mode][lane]
	for note in hold_notes:
		if not is_instance_valid(note) or note.judged:
			continue
		var diff: float = abs(note.target_time - now)
		if diff <= ScoreSystem.GOOD_WINDOW:
			note.on_head_pressed(diff)
			held_notes[lane] = note
			return

	# fall through to tap notes
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


func _try_release(lane: int) -> void:
	var note = held_notes[lane]
	if note != null and is_instance_valid(note):
		note.on_released()
	held_notes[lane] = null

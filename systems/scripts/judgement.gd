extends Node

const LANE_ACTIONS: Array = ["lane1 (Top)", "lane2 (Right)", "lane3 (Bottom)", "lane4 (Left)"]
const TRANSFORM_ACTION: String = "transform"

@onready var spawner: Node = get_node("../Spawner")
@onready var sustain_ring: Node2D = get_node("../Sustain_Ring")

# Autoplayer
@export var autoplay: bool = false

var current_mode: String = "+"
var held_notes: Array = [null, null, null, null]

func _process(_delta: float) -> void:
	if autoplay:
		_run_autoplay()
		return

	if Input.is_action_just_pressed(TRANSFORM_ACTION):
		current_mode = "x" if current_mode == "+" else "+"
		print("Transform → ", "High Current"  if current_mode == "x" else "Low Current")
		sustain_ring.rotation_degrees = 45.0 if current_mode == "x" else 0.0

	for lane in range(LANE_ACTIONS.size()):
		if Input.is_action_just_pressed(LANE_ACTIONS[lane]):
			SoundManager.play_hitsound(lane)
			_try_hit(lane)
		elif Input.is_action_just_released(LANE_ACTIONS[lane]):
			_try_release(lane)

func _try_hit(lane: int) -> void:
	var now: float = Conductor.get_time()
	var hold_notes: Array = spawner.active_hold_notes[current_mode][lane]
	for note in hold_notes:
		if not is_instance_valid(note) or note.judged:
			continue
		var diff: float = abs(note.target_time - now)
		if diff <= ScoreSystem.GOOD_WINDOW:
			note.on_head_pressed(diff)
			held_notes[lane] = note
			return

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

# Autoplayer
func _run_autoplay() -> void:
	var now: float = Conductor.get_time()

	for lane in range(LANE_ACTIONS.size()):
		# check both modes for upcoming notes in this lane, switch mode just-in-time, then hit
		for mode in ["+", "x"]:
			var hit_something := false

			for note in spawner.active_hold_notes[mode][lane]:
				if not is_instance_valid(note) or note.judged:
					continue
				if now >= note.target_time:
					_auto_switch_mode(mode)
					SoundManager.play_hitsound(lane)
					_try_hit(lane)
					hit_something = true
					break

			if not hit_something:
				for note in spawner.active_notes[mode][lane]:
					if not is_instance_valid(note) or note.judged:
						continue
					if now >= note.target_time:
						_auto_switch_mode(mode)
						SoundManager.play_hitsound(lane)
						_try_hit(lane)
						break

		# release held notes exactly at their end_time
		var held = held_notes[lane]
		if held != null and is_instance_valid(held) and now >= held.end_time:
			_try_release(lane)

func _auto_switch_mode(target_mode: String) -> void:
	if current_mode != target_mode:
		current_mode = target_mode
		sustain_ring.rotation_degrees = 45.0 if current_mode == "x" else 0.0

extends Node

const LANE_ACTIONS: Array = ["lane1 (Top)", "lane2 (Right)", "lane3 (Bottom)", "lane4 (Left)"]
const TRANSFORM_ACTION: String = "transform"

@onready var spawner: Node2D = %NoteSpawner
@onready var sustain_ring: Sprite2D = %SustainRing
@onready var replay_recorder: Node = %ReplayRecorder

# --- AUTOPLAYER ---
@export var autoplay: bool = false

var current_mode: String = "+"
var held_notes: Array = [null, null, null, null]
var held_note_data: Array = [null, null, null, null]  # stores beat_start for held notes
# Stores the mode each held note was hit in, so auto_resolved can record correctly
var held_note_modes: Array = ["", "", "", ""]


func _ready() -> void:
	print("[JUDGE] replay_recorder is null: ", replay_recorder == null)


func _play_sound(lane: int) -> void:
	if SoundManager.has_method("play_hitsound"):
		SoundManager.play_hitsound(lane)


func _process(_delta: float) -> void:
	if autoplay:
		_run_autoplay()
		return
	
	if Input.is_action_just_pressed(TRANSFORM_ACTION):
		_toggle_mode()
	
	for lane in range(LANE_ACTIONS.size()):
		if Input.is_action_just_pressed(LANE_ACTIONS[lane]):
			SoundManager.play_hitsound(lane)
			_try_hit(lane)
		elif Input.is_action_just_released(LANE_ACTIONS[lane]):
			_try_release(lane)


func _toggle_mode() -> void:
	current_mode = "x" if current_mode == "+" else "+"
	sustain_ring.rotation_degrees = 45.0 if current_mode == "x" else 0.0
	print("[JUDGE] Mode Switched: ", current_mode)


func _try_hit(lane: int) -> void:
	var now: float = Conductor.get_time()
	var hold_notes: Array = spawner.active_hold_notes[current_mode][lane]
	
	for note in hold_notes:
		if not is_instance_valid(note) or note.judged:
			continue
			
		var diff: float = abs(note.target_time - now)
		print("[DEBUG-JUDGE] Checking Hold Note -> Lane: %d | Target Time: %f | Now: %f | Diff: %f | Good Window: %f" % [lane, note.target_time, now, diff, ScoreSystem.GOOD_WINDOW])
		
		if diff <= ScoreSystem.GOOD_WINDOW:
			note.on_head_pressed(diff)
			held_notes[lane] = note
			held_note_data[lane] = note.target_time / Conductor.seconds_per_beat
			held_note_modes[lane] = current_mode
			print("[DEBUG-JUDGE] SUCCESS! Hold note assigned to held_notes array.")
			
			if not note.auto_resolved.is_connected(_on_hold_auto_resolved):
				note.auto_resolved.connect(_on_hold_auto_resolved)
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
	var result = ScoreSystem.register_judgment(closest_diff)
	var time_offset: float = now - closest_note.target_time
	var beat_start = closest_note.target_time / Conductor.seconds_per_beat
	
	if replay_recorder != null:
		replay_recorder.record_tap(beat_start, lane, current_mode, result, time_offset)
	else:
		print("[JUDGE] WARNING: replay_recorder is null, tap not recorded")

	if closest_note.has_method("destroy"):
		closest_note.destroy()
	else:
		closest_note.queue_free()


func _on_hold_auto_resolved(note: Node2D) -> void:
	var lane: int = note.lane
	var beat_start = held_note_data[lane]
	if beat_start == null:
		return

	var press_offset: float = note.press_time - note.target_time
	var release_offset: float = Conductor.get_time() - note.end_time
	var beat_end = note.end_time / Conductor.seconds_per_beat
	# Use the stored mode for this lane, not current_mode (avoids mode-switch corruption)
	var note_mode: String = held_note_modes[lane]

	if replay_recorder != null:
		replay_recorder.record_hold(beat_start, lane, note_mode, note.head_judgment, press_offset, release_offset, beat_end)

	held_notes[lane] = null
	held_note_data[lane] = null
	held_note_modes[lane] = ""


func _try_release(lane: int) -> void:
	var note = held_notes[lane]
	# null means already handled by _on_hold_auto_resolved — skip to avoid double-record
	if note == null or not is_instance_valid(note):
		held_notes[lane] = null
		held_note_data[lane] = null
		held_note_modes[lane] = ""
		return

	var now: float = Conductor.get_time()
	var judgment = note.head_judgment
	var beat_start = held_note_data[lane]
	var note_mode: String = held_note_modes[lane]

	var press_offset: float = note.press_time - note.target_time
	var release_offset: float = now - note.end_time
	var note_beat_end = note.end_time / Conductor.seconds_per_beat

	note.on_released()

	if replay_recorder != null:
		replay_recorder.record_hold(beat_start, lane, note_mode, judgment, press_offset, release_offset, note_beat_end)
	else:
		print("[JUDGE] WARNING: replay_recorder is null, hold not recorded")

	held_notes[lane] = null
	held_note_data[lane] = null
	held_note_modes[lane] = ""


# --- AUTOPLAYER ---
func _run_autoplay() -> void:
	var now: float = Conductor.get_time()
	
	for lane in range(LANE_ACTIONS.size()):
		for mode in ["+", "x"]:
			var hit_something := false
			
			for note in spawner.active_hold_notes[mode][lane]:
				if not is_instance_valid(note) or note.judged:
					continue
				if now >= note.target_time:
					_auto_switch_mode(mode)
					_play_sound(lane)
					_try_hit(lane)
					hit_something = true
					break
			
			if not hit_something:
				for note in spawner.active_notes[mode][lane]:
					if not is_instance_valid(note) or note.judged:
						continue
					if now >= note.target_time:
						_auto_switch_mode(mode)
						_play_sound(lane)
						_try_hit(lane)
						break


func _auto_switch_mode(target_mode: String) -> void:
	if current_mode != target_mode:
		current_mode = target_mode
		sustain_ring.rotation_degrees = 45.0 if current_mode == "x" else 0.0

extends Node

# lane action names are now generated dynamically from Settings

@onready var spawner: Node2D        = %NoteSpawner
@onready var sustain_ring: Sprite2D = %SustainRing
@onready var replay_recorder: Node  = %ReplayRecorder

# --- AUTOPLAYER ---
var autoplay: bool = MatchRules.is_autoplay

var current_mode: String = "+"
var held_notes: Array     = [null, null, null, null]
var held_note_data: Array = [null, null, null, null]
var held_note_modes: Array = ["", "", "", ""]


func _ready() -> void:
	print("[JUDGE] Replay Recorder NULL: ", replay_recorder == null)


func _get_lane_action(lane: int) -> String:
	if current_mode == "+":
		return "lane%d" % (lane + 1)
	else:
		return "lane_x%d" % (lane + 1)


func _play_sound(lane: int) -> void:
	if SoundManager.has_method("play_hitsound"):
		SoundManager.play_hitsound(lane)


func _process(_delta: float) -> void:
	if autoplay:
		_run_autoplay()
		return

	# Quick Retry
	if Input.is_action_just_pressed(Settings.QUICK_RETRY_ACTION):
		_quick_retry()
		return

	# Transform (mode switch)
	if Input.is_action_just_pressed(Settings.TRANSFORM_ACTION):
		_toggle_mode()


	for lane in range(4):
		var action := _get_lane_action(lane)
		
		var just_pressed  := Input.is_action_just_pressed(action)
		var just_released := Input.is_action_just_released(action)
		var pressed       := Input.is_action_pressed(action)

		if just_pressed:
			_play_sound(lane)
			_try_hit(lane)
		elif just_released:
			_try_release(lane)

		# LITE NOTES
		if pressed:
			_try_lite_hit(lane)


func _toggle_mode() -> void:
	current_mode = "x" if current_mode == "+" else "+"
	sustain_ring.rotation_degrees = 45.0 if current_mode == "x" else 0.0
	print("[JUDGE] Mode Switched: ", current_mode)


func _quick_retry() -> void:
	PauseManager.retry_level()


func _try_hit(lane: int) -> void:
	var now: float = Conductor.get_time()
	var hold_notes: Array = spawner.active_hold_notes[current_mode][lane]

	# check hold notes first
	for note in hold_notes:
		if not is_instance_valid(note) or note.judged:
			continue

		var diff: float = abs(note.target_time - now)
		if diff <= ScoreSystem.GOOD_WINDOW:
			note.on_head_pressed(diff)
			held_notes[lane]      = note
			held_note_data[lane]  = note.target_time / Conductor.seconds_per_beat
			held_note_modes[lane] = current_mode

			if not note.auto_resolved.is_connected(_on_hold_auto_resolved):
				note.auto_resolved.connect(_on_hold_auto_resolved)
			return

	# fall through to tap notes
	var notes: Array = spawner.active_notes[current_mode][lane]
	var closest_note: Node2D = null
	var closest_diff: float  = INF

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
	var result = ScoreSystem.register_judgement(closest_diff)
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


func _try_lite_hit(lane: int) -> void:
	var now: float = Conductor.get_time()
	
	# Check for Lite HOLD HEADS
	var hold_notes: Array = spawner.active_hold_notes[current_mode][lane]
	for note in hold_notes:
		if is_instance_valid(note) and not note.judged and note.is_lite:
			if now >= note.target_time:
				note.on_head_pressed(0.0) # force perfect
				
				held_notes[lane]      = note
				held_note_data[lane]  = note.target_time / Conductor.seconds_per_beat
				held_note_modes[lane] = current_mode
				
				if not note.auto_resolved.is_connected(_on_hold_auto_resolved):
					note.auto_resolved.connect(_on_hold_auto_resolved)
				
				_play_sound(lane)
				return

	# Check for Lite TAP NOTES
	var tap_notes: Array = spawner.active_notes[current_mode][lane]
	for note in tap_notes:
		if is_instance_valid(note) and not note.judged and note.is_lite:
			if now >= note.target_time:
				note.judged = true
				
				ScoreSystem.register_lite_hit()
				if replay_recorder:
					replay_recorder.record_tap(note.target_time / Conductor.seconds_per_beat, lane, current_mode, "perfect", 0.0)
				_play_sound(lane)
				note.destroy()
				return


func _on_hold_auto_resolved(note: Node2D) -> void:
	var lane: int      = note.lane
	var beat_start     = held_note_data[lane]
	if beat_start == null:
		return

	var press_offset: float   = note.press_time - note.target_time
	var release_offset: float = Conductor.get_time() - note.end_time
	var beat_end = note.end_time / Conductor.seconds_per_beat
	var note_mode: String = held_note_modes[lane]

	if replay_recorder != null:
		replay_recorder.record_hold(beat_start, lane, note_mode, note.head_judgement, press_offset, release_offset, beat_end)

	held_notes[lane]      = null
	held_note_data[lane]  = null
	held_note_modes[lane] = ""


func _try_release(lane: int) -> void:
	var note = held_notes[lane]
	if note == null or not is_instance_valid(note):
		held_notes[lane]      = null
		held_note_data[lane]  = null
		held_note_modes[lane] = ""
		return

	var now: float            = Conductor.get_time()
	var judgement              = note.head_judgement
	var beat_start            = held_note_data[lane]
	var note_mode: String     = held_note_modes[lane]
	var press_offset: float   = note.press_time - note.target_time
	var release_offset: float = now - note.end_time
	var note_beat_end         = note.end_time / Conductor.seconds_per_beat

	note.on_released()

	if replay_recorder != null:
		replay_recorder.record_hold(beat_start, lane, note_mode, judgement, press_offset, release_offset, note_beat_end)
	else:
		print("[JUDGE] WARNING: replay_recorder is null, hold not recorded")

	held_notes[lane]      = null
	held_note_data[lane]  = null
	held_note_modes[lane] = ""


# --- AUTOPLAYER ---
func _run_autoplay() -> void:
	var now: float = Conductor.get_time()

	for lane in range(4):
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

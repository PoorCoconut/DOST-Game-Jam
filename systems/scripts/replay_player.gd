extends Node

var spawner: Node2D
var sustain_ring: Node2D
var judge: Node

var _replay: ReplayData = null
var _pending_releases: Array = []

var _hold_entries: Array = []
var _hold_index: int = 0
var _tap_entries: Array = []
var _tap_index: int = 0

var current_mode: String = "+"


func _ready() -> void:
	var root = get_parent()
	judge = root.get_node("Judge")
	sustain_ring = root.get_node("SustainRing")
	spawner = root.get_node("PlayfieldContainer/NoteMask/NoteSpawner")
	print("[REPLAYER] judge: ", judge, " | spawner: ", spawner, " | sustain_ring: ", sustain_ring)


func load_replay(replay: ReplayData) -> void:
	_replay = replay
	_hold_entries = []
	_tap_entries = []
	_hold_index = 0
	_tap_index = 0
	_pending_releases = []
	current_mode = "+"

	for entry in replay.entries:
		if not entry is Dictionary:
			continue
		if entry.get("is_hold", false):
			_hold_entries.append(entry)
		else:
			_tap_entries.append(entry)

	print("[REPLAYER] Loaded replay: %d taps, %d holds" % [_tap_entries.size(), _hold_entries.size()])


func _process(_delta: float) -> void:
	if _replay == null:
		return

	var now: float = Conductor.get_time()

	while _hold_index < _hold_entries.size():
		var entry = _hold_entries[_hold_index]
		var ideal_target_time: float = entry["beat_start"] * Conductor.seconds_per_beat
		if now < ideal_target_time:
			break
		_fire_hold(entry, ideal_target_time + entry["time_offset"])
		_hold_index += 1

	while _tap_index < _tap_entries.size():
		var entry = _tap_entries[_tap_index]
		var ideal_target_time: float = entry["beat_start"] * Conductor.seconds_per_beat
		var scheduled_press_time: float = ideal_target_time + entry["time_offset"]
		if now < scheduled_press_time:
			break
		_fire_tap(entry, scheduled_press_time)
		_tap_index += 1

	var i = _pending_releases.size() - 1
	while i >= 0:
		var pending = _pending_releases[i]
		if now >= pending["release_time"]:
			judge._try_release(pending["lane"])
			_pending_releases.remove_at(i)
		i -= 1


func _fire_hold(entry: Dictionary, scheduled_press_time: float) -> void:
	# print("[DEBUG-REPLAYER] _fire_entry called -> is_hold: true | judgement: %s | lane: %d | mode: %s" % [entry.get("judgement", "??"), entry.get("lane", -1), entry.get("mode", "??")])

	var lane: int = entry["lane"]
	var mode: String = entry["mode"]

	if current_mode != mode:
		current_mode = mode
		sustain_ring.rotation_degrees = 45.0 if mode == "x" else 0.0

	if entry["judgement"] == "miss":
		return

	var ideal_target_time: float = entry["beat_start"] * Conductor.seconds_per_beat
	# print("[DEBUG-REPLAYER] Firing HOLD entry -> Lane: %d | Mode: %s | Target: %.3f" % [lane, mode, ideal_target_time])

	var hold_note = _find_hold_note(mode, lane, ideal_target_time)
	if hold_note == null:
		# print("[DEBUG-REPLAYER] WARNING: Could not find hold note for Lane %d | Mode: %s | Target: %.3f" % [lane, mode, ideal_target_time])
		return

	# print("[DEBUG-REPLAYER] Found hold note -> target_time: %.3f" % hold_note.target_time)

	var diff: float = abs(hold_note.target_time - scheduled_press_time)
	hold_note.on_head_pressed(diff)
	
	# OH MY GOOOODDD OKAY FINE
	SoundManager.play_hitsound(lane)
	judge.held_notes[lane] = hold_note
	judge.held_note_data[lane] = entry["beat_start"]
	judge.held_note_modes[lane] = mode

	if not hold_note.auto_resolved.is_connected(judge._on_hold_auto_resolved):
		hold_note.auto_resolved.connect(judge._on_hold_auto_resolved)

	var beat_end: float = entry.get("beat_end", -1.0)
	var release_offset: float = entry.get("time_of_release_offset", 0.0)
	if beat_end >= 0.0:
		var scheduled_release_time = (beat_end * Conductor.seconds_per_beat) + release_offset
		# print("[DEBUG-REPLAYER] Scheduling release -> Lane: %d | Release at: %.3f" % [lane, scheduled_release_time])
		_pending_releases.append({"lane": lane, "release_time": scheduled_release_time})
	else:
		return
		# print("[DEBUG-REPLAYER] WARNING: No beat_end in hold entry for lane %d!" % lane)


func _fire_tap(entry: Dictionary, scheduled_press_time: float) -> void:
	# print("[DEBUG-REPLAYER] _fire_entry called -> is_hold: false | judgement: %s | lane: %d | mode: %s" % [entry.get("judgement", "??"), entry.get("lane", -1), entry.get("mode", "??")])

	var lane: int = entry["lane"]
	var mode: String = entry["mode"]

	if current_mode != mode:
		current_mode = mode
		sustain_ring.rotation_degrees = 45.0 if mode == "x" else 0.0

	if entry["judgement"] == "miss":
		return

	var notes: Array = spawner.active_notes[mode][lane]
	var closest_note: Node2D = null
	var closest_diff: float = INF

	for note in notes:
		if not is_instance_valid(note) or note.judged:
			continue
		var diff: float = abs(note.target_time - scheduled_press_time)
		if diff < closest_diff:
			closest_diff = diff
			closest_note = note

	if closest_note != null:
		closest_note.judged = true
		ScoreSystem.register_judgement(abs(entry["time_offset"]))
		if SoundManager.has_method("play_hitsound"):
			SoundManager.play_hitsound(lane)
		if closest_note.has_method("destroy"):
			closest_note.destroy()
		else:
			closest_note.queue_free()


func _find_hold_note(mode: String, lane: int, ideal_target_time: float) -> Node2D:
	var best_note: Node2D = null
	var best_diff: float = 0.05

	var hold_notes: Array = spawner.active_hold_notes[mode][lane]
	for note in hold_notes:
		if not is_instance_valid(note):
			continue
		if note.judged and note.is_held:
			continue
		var diff: float = abs(note.target_time - ideal_target_time)
		if diff < best_diff:
			best_diff = diff
			best_note = note

	return best_note

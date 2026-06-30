extends Node

# ─── STATE ───────────────────────────────────────────────────────────────────
signal paused(is_fail: bool)
signal resumed
signal retried

const PAUSE_PANEL_SCENE: String = "res://scenes/menus/pause/pause_panel.tscn"

var pause_panel_instance: CanvasLayer = null
var is_paused: bool = false
var is_fail_state: bool = false


# ─── PAUSE ───────────────────────────────────────────────────────────────────
func pause_game(is_fail: bool = false) -> void:
	if is_paused:
		return

	is_paused = true
	is_fail_state = is_fail

	get_tree().paused = true

	if pause_panel_instance == null:
		var scene := load(PAUSE_PANEL_SCENE) as PackedScene
		pause_panel_instance = scene.instantiate()
		pause_panel_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		get_tree().root.add_child(pause_panel_instance)

	pause_panel_instance.setup(is_fail)
	pause_panel_instance.visible = true

	paused.emit(is_fail)


func resume_game() -> void:
	if not is_paused:
		return

	is_paused = false
	is_fail_state = false
	get_tree().paused = false

	if pause_panel_instance != null:
		pause_panel_instance.visible = false

	resumed.emit()


# ─── RESULTS (from fail screen) ──────────────────────────────────────────────
func go_to_results_after_fail() -> void:
	# Player clicked "Results" on the fail screen.
	# NOW we save the replay, then unpause and go to ranking.
	get_tree().paused = false
	is_paused = false

	if pause_panel_instance != null:
		pause_panel_instance.visible = false

	var replay_recorder := get_tree().get_first_node_in_group("replay_recorder")
	if replay_recorder != null and replay_recorder.has_method("save_replay_now"):
		replay_recorder.save_replay_now()

	SceneManager.go_to_ranking()


# ─── RETRY ───────────────────────────────────────────────────────────────────
func retry_level() -> void:
	get_tree().paused = false
	is_paused = false
	is_fail_state = false

	if pause_panel_instance != null:
		pause_panel_instance.visible = false

	retried.emit()
	# Reloading the gameplay scene is the cleanest full reset —
	# everything (notes, judge state, replay recorder, conductor) is freshly instanced.
	get_tree().reload_current_scene()


# ─── QUIT ────────────────────────────────────────────────────────────────────
func quit_to_menu() -> void:
	get_tree().paused = false
	is_paused = false
	is_fail_state = false

	if pause_panel_instance != null:
		pause_panel_instance.queue_free()
		pause_panel_instance = null

	SceneManager.quit_to_menu()


# ─── CLEANUP (call when leaving gameplay scene normally, e.g. song finished) ──
func cleanup() -> void:
	is_paused = false
	is_fail_state = false
	if pause_panel_instance != null:
		pause_panel_instance.queue_free()
		pause_panel_instance = null

extends Control

@onready var rank_label: Label = $ScrollContainer/VBoxContainer/RankLabel
@onready var score_label: Label = $ScrollContainer/VBoxContainer/ScoreLabel
@onready var max_combo_label: Label = $ScrollContainer/VBoxContainer/MaxComboLabel
@onready var perfects_label: Label = $ScrollContainer/VBoxContainer/PerfectsLabel
@onready var goods_label: Label = $ScrollContainer/VBoxContainer/GoodsLabel
@onready var bads_label: Label = $ScrollContainer/VBoxContainer/BadsLabel
@onready var misses_label: Label = $ScrollContainer/VBoxContainer/MissesLabel
@onready var watch_replay_btn: Button = $ScrollContainer/VBoxContainer/WatchReplayButton
@onready var quit_btn: Button = $ScrollContainer/VBoxContainer/QuitButton
@onready var leaderboard_btn: Button = $ScrollContainer/VBoxContainer/LeaderboardButton

const LEADERBOARD_SCENE: String = "res://scenes/menus/leaderboard/leaderboard_panel.tscn"

# Set when viewing a leaderboard entry instead of the just-played result.
var _viewing_replay: ReplayData = null
var _leaderboard_instance: CanvasLayer = null


func _ready() -> void:
	_show_live_result()
	watch_replay_btn.pressed.connect(_on_watch_replay)
	quit_btn.pressed.connect(_on_quit)
	leaderboard_btn.pressed.connect(_on_leaderboard_pressed)


func _show_live_result() -> void:
	_viewing_replay = null
	rank_label.text = "Rank: " + ScoreSystem.get_rank()
	score_label.text = "Score: " + str(roundi(ScoreSystem.watts))
	max_combo_label.text = "Max Combo: " + str(ScoreSystem.max_volts) + "V"
	perfects_label.text = "Perfect: " + str(ScoreSystem.perfects)
	goods_label.text = "Good: " + str(ScoreSystem.goods)
	bads_label.text = "Bad: " + str(ScoreSystem.bads)
	misses_label.text = "Miss: " + str(ScoreSystem.misses)


func _show_replay_result(replay: ReplayData) -> void:
	_viewing_replay = replay
	rank_label.text = "Rank: " + replay.final_rank
	score_label.text = "Score: " + str(replay.final_watts)
	max_combo_label.text = "Max Combo: " + str(replay.max_volts) + "V"
	perfects_label.text = "Perfect: " + str(replay.perfects)
	goods_label.text = "Good: " + str(replay.goods)
	bads_label.text = "Bad: " + str(replay.bads)
	misses_label.text = "Miss: " + str(replay.misses)


func _on_watch_replay() -> void:
	# If we're viewing a specific leaderboard entry, watch that one directly.
	if _viewing_replay != null:
		SceneManager.load_replay(_viewing_replay)
		return

	# Otherwise, find the most recently saved replay for the current song
	# in its per-song folder.
	var song_slug = SceneManager.selected_chart.song_name.to_lower().replace(" ", "_")
	var dir_path = "user://replays/%s/" % song_slug

	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("[RANKING] No replays folder found for song: " + song_slug)
		return

	var latest_file: String = ""
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			if file_name > latest_file:
				latest_file = file_name
		file_name = dir.get_next()
	dir.list_dir_end()

	if latest_file == "":
		push_error("[RANKING] No replay found for song: " + song_slug)
		return

	var path = dir_path + latest_file
	print("[RANKING] Loading replay: ", path)
	var replay = ResourceLoader.load(path) as ReplayData
	if replay == null:
		push_error("[RANKING] Failed to load replay at: " + path)
		return
	SceneManager.load_replay(replay)


func _on_leaderboard_pressed() -> void:
	if SceneManager.selected_chart == null:
		push_error("[RANKING] No selected_chart to show leaderboard for")
		return

	if _leaderboard_instance == null:
		var scene := load(LEADERBOARD_SCENE) as PackedScene
		_leaderboard_instance = scene.instantiate()
		get_tree().root.add_child(_leaderboard_instance)
		_leaderboard_instance.entry_selected.connect(_on_leaderboard_entry_selected)

	_leaderboard_instance.open_for_chart(SceneManager.selected_chart)


func _on_leaderboard_entry_selected(replay: ReplayData) -> void:
	_show_replay_result(replay)


func _on_quit() -> void:
	if _leaderboard_instance != null:
		_leaderboard_instance.queue_free()
	SceneManager.quit_to_menu()

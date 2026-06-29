extends Control

@onready var rank_label: Label = $VBoxContainer/RankLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var perfects_label: Label = $VBoxContainer/PerfectsLabel
@onready var goods_label: Label = $VBoxContainer/GoodsLabel
@onready var bads_label: Label = $VBoxContainer/BadsLabel
@onready var misses_label: Label = $VBoxContainer/MissesLabel
@onready var watch_replay_btn: Button = $VBoxContainer/WatchReplayButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	rank_label.text = "Rank: " + ScoreSystem.get_rank()
	score_label.text = "Score: " + str(roundi(ScoreSystem.watts))
	perfects_label.text = "Perfect: " + str(ScoreSystem.perfects)
	goods_label.text = "Good: " + str(ScoreSystem.goods)
	bads_label.text = "Bad: " + str(ScoreSystem.bads)
	misses_label.text = "Miss: " + str(ScoreSystem.misses)
	watch_replay_btn.pressed.connect(_on_watch_replay)
	quit_btn.pressed.connect(_on_quit)


func _on_watch_replay() -> void:
	var song_slug = SceneManager.selected_chart.song_name.to_lower().replace(" ", "_")
	var dir_path = "user://replays/"

	# Find the most recently saved replay for this song by picking the
	# alphabetically last filename that starts with the song slug.
	# Timestamps are ISO format so alphabetical order == chronological order.
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("[RANKING] Replays directory not found")
		return

	var latest_file: String = ""
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with(song_slug) and file_name.ends_with(".tres"):
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


func _on_quit() -> void:
	SceneManager.quit_to_menu()

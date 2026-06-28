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
	# display results from ScoreSystem
	rank_label.text = "Rank: " + ScoreSystem.get_rank()
	score_label.text = "Score: " + str(roundi(ScoreSystem.watts))
	perfects_label.text = "Perfect: " + str(ScoreSystem.perfects)
	goods_label.text = "Good: " + str(ScoreSystem.goods)
	bads_label.text = "Bad: " + str(ScoreSystem.bads)
	misses_label.text = "Miss: " + str(ScoreSystem.misses)

	watch_replay_btn.pressed.connect(_on_watch_replay)
	quit_btn.pressed.connect(_on_quit)


func _on_watch_replay() -> void:
	# load the replay file for this chart
	var song_name = SceneManager.selected_chart.song_name.to_lower().replace(" ", "_")
	var path = "user://replays/" + song_name + "_replay.tres"

	if ResourceLoader.exists(path):
		var replay = ResourceLoader.load(path) as ReplayData
		SceneManager.load_replay(replay)
	else:
		push_error("[RANKING] No replay found at: " + path)


func _on_quit() -> void:
	SceneManager.quit_to_menu()

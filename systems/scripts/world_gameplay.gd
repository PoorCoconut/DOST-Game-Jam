extends Node2D

@onready var judge: Node = $Judge
@onready var replay_recorder: Node = $ReplayRecorder
@onready var replay_player: Node = $ReplayPlayer


func _ready() -> void:
	print("[GAMEPLAY] is_replay: ", SceneManager.is_replay)
	if SceneManager.is_replay:
		# replay mode — disable judge and recorder, enable replay player
		judge.process_mode = Node.PROCESS_MODE_DISABLED
		replay_recorder.process_mode = Node.PROCESS_MODE_DISABLED
		replay_player.process_mode = Node.PROCESS_MODE_INHERIT
		replay_player.load_replay(SceneManager.selected_replay)
	else:
		# normal play — disable replay player
		replay_player.process_mode = Node.PROCESS_MODE_DISABLED

	# listen for song end to go to ranking panel
	Conductor.song_finished.connect(_on_song_finished)
	ScoreSystem.player_failed.connect(_on_song_finished)


func _on_song_finished() -> void:
	SceneManager.go_to_ranking()

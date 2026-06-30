extends Node2D

@onready var judge: Node = $Judge
@onready var replay_recorder: Node = $ReplayRecorder
@onready var replay_player: Node = $ReplayPlayer


func _ready() -> void:
	print("[GAMEPLAY] is_replay: ", SceneManager.is_replay)
	replay_recorder.add_to_group("replay_recorder")

	if SceneManager.is_replay:
		# replay mode — disable judge and recorder, enable replay player
		judge.process_mode = Node.PROCESS_MODE_DISABLED
		replay_recorder.process_mode = Node.PROCESS_MODE_DISABLED
		replay_player.process_mode = Node.PROCESS_MODE_INHERIT
		replay_player.load_replay(SceneManager.selected_replay)
	else:
		# normal play — disable replay player
		replay_player.process_mode = Node.PROCESS_MODE_DISABLED

	# song end -> normal
	# 0 hp -> player fail
	Conductor.song_finished.connect(_on_song_finished)
	ScoreSystem.player_failed.connect(_on_player_failed)

	PauseManager.cleanup()


func _unhandled_input(_event: InputEvent) -> void:
	if SceneManager.is_replay:
		return

	if Input.is_action_just_pressed("pause"):
		if PauseManager.is_paused:
			# only allow resuming via this shortcut on a normal (non-fail) pause
			if not PauseManager.is_fail_state:
				PauseManager.resume_game()
		else:
			if not ScoreSystem.is_failed:
				PauseManager.pause_game(false)


func _on_song_finished() -> void:
	# normal completion — replay auto-saves
	SceneManager.go_to_ranking()


func _on_player_failed() -> void:
	# when player fails, do not save the replay YET
	# only if they choose to see the results
	# audio is paused
	Conductor.audio_player.stop()
	PauseManager.pause_game(true)

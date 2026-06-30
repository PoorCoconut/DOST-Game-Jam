extends Node2D

@onready var judge: Node = $Judge
@onready var replay_recorder: Node = $ReplayRecorder
@onready var replay_player: Node = $ReplayPlayer


func _ready() -> void:
	print("[Gameplay] Multiplayer =", SceneManager.is_multiplayer)

	print("[GAMEPLAY] is_replay: ", SceneManager.is_replay)

	# So PauseManager can find this recorder without a hard node path
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

	# listen for song end -> normal happy path, straight to ranking
	Conductor.song_finished.connect(_on_song_finished)

	# listen for HP hitting 0 -> fail-pause screen (does NOT save replay yet)
	ScoreSystem.player_failed.connect(_on_player_failed)

	PauseManager.cleanup()

	# Multiplayer startup flow
	if SceneManager.is_multiplayer:
		print("[Gameplay] Connected countdown signal")
		NetworkManager.countdown_started.connect(_on_countdown_started)

		if multiplayer.is_server():
			print("[Gameplay] Host ready")
			NetworkManager.set_host_ready()
		else:
			print("[Gameplay] Guest ready")
			NetworkManager.send_ready()


func _unhandled_input(event: InputEvent) -> void:
	if SceneManager.is_replay:
		return  # no pausing while watching a replay

	if Input.is_action_just_pressed("pause"):
		if PauseManager.is_paused:
			# Only allow resuming via this shortcut on a normal (non-fail) pause
			if not PauseManager.is_fail_state:
				PauseManager.resume_game()
		else:
			if not ScoreSystem.is_failed:
				PauseManager.pause_game(false)


func _on_song_finished() -> void:
	# Normal completion — replay already auto-saves via replay_recorder's
	# own Conductor.song_finished connection.
	SceneManager.go_to_ranking()


func _on_player_failed() -> void:
	# Death — DO NOT save replay here. Pause with fail UI (Results/Retry/Quit).
	# Conductor's audio keeps playing under pause unless we stop it explicitly:
	Conductor.audio_player.stop()
	PauseManager.pause_game(true)

func _on_countdown_started(start_time: int): #for multiplayer countdown
	var delay := (start_time - Time.get_ticks_msec()) / 1000.0
	print("[Gameplay] Countdown started | delay=", delay, "s | start_time=", start_time)

	if delay > 0:
		await get_tree().create_timer(delay).timeout

	print("[Gameplay] Starting song now")
	Conductor.play_song()

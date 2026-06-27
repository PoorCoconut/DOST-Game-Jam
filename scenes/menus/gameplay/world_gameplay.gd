extends Node

func _ready():
	print("[Gameplay] Multiplayer =", SceneManager.is_multiplayer)
	if not SceneManager.is_multiplayer:
		return
	print("[Gameplay] Connected countdown signal")
	NetworkManager.countdown_started.connect(_on_countdown_started)

	if multiplayer.is_server():
		print("[Gameplay] Host ready")
		NetworkManager.set_host_ready()
	else:
		print("[Gameplay] Guest ready")
		NetworkManager.send_ready()


func _on_countdown_started(start_time: int):
	var delay := (start_time - Time.get_ticks_msec()) / 1000.0
	print("[Gameplay] Countdown started | delay=", delay, "s | start_time=", start_time)

	if delay > 0:
		await get_tree().create_timer(delay).timeout

	print("[Gameplay] Starting song now")
	Conductor.play_song()

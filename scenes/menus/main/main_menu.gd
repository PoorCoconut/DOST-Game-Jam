extends Control

@export var test_chart: ChartData 

func _on_play_button_pressed() -> void:
	# NOTE: this is now activated with a space button for faster debug
	# check Inspector -> BaseButton -> Shortcut
	SceneManager.load_gameplay(test_chart, "Solar")

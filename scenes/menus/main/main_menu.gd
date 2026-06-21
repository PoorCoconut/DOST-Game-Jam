extends Control

@export var test_chart: ChartData 

func _on_play_button_pressed() -> void:
	SceneManager.load_gameplay(test_chart, "Solar")

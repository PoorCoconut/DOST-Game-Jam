extends Control

@export var test_chart: ChartData

func _on_play_button_pressed() -> void:
	SceneManager.load_gameplay(test_chart, "Solar")

func _on_settings_button_pressed() -> void:
	SceneManager.go_to_settings()

func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/lan/lan_lobby.tscn")
	

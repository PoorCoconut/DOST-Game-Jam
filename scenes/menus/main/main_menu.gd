extends Control

@export var test_chart: ChartData 

func _on_play_button_pressed() -> void:
	SceneManager.load_gameplay(test_chart, "Solar")

func _on_play_lan_button_pressed() -> void:
	var lobby_scene := preload("res://scenes/menus/lan/lan_lobby.tscn")
	add_child(lobby_scene.instantiate())

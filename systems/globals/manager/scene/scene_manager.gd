extends Node

# holds "shared data" between menu and gameplay
var selected_chart: ChartData
var selected_energy: String = "Solar"

# maybe future LAN logic goes here
var is_multiplayer: bool = false


func load_gameplay(chart: ChartData, energy: String):
	selected_chart = chart
	selected_energy = energy
	get_tree().change_scene_to_file("res://scenes/levels/test/test_level.tscn")


func quit_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

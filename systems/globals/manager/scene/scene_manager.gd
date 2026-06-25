extends Node

# holds "shared data" between menu and gameplay
var selected_chart: ChartData
var selected_energy: String = "Solar"
# maybe future LAN logic goes here
var is_multiplayer: bool = false

const GAMEPLAY_DIR: String = "res://scenes/menus/gameplay/gameplay.tscn"
const MENU_DIR: String     = "res://scenes/menus/main/main_menu.tscn"

func load_gameplay(chart: ChartData, energy: String):
	selected_chart = chart
	selected_energy = energy
	get_tree().change_scene_to_file(GAMEPLAY_DIR)


func quit_to_menu():
	get_tree().change_scene_to_file(MENU_DIR)

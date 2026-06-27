extends Node

# holds "shared data" between menu and gameplay
var selected_chart: ChartData
var selected_energy: String = "Solar"
# maybe future LAN logic goes here
var is_multiplayer: bool = false

# multiplayer purposes
var opponent_name: String = ""
var waiting_for_start: bool = false
var start_time_msec: int = 0

const GAMEPLAY_DIR: String = "res://scenes/menus/gameplay/world_gameplay.tscn"
const MENU_DIR: String     = "res://scenes/menus/main/main_menu.tscn"
const MULTIPLAYER_LOBBY_DIR := "res://scenes/menus/multiplayer/multiplayer_lobby.tscn"

func load_gameplay(chart: ChartData, energy: String):
	print("[SceneManager] Multiplayer =", is_multiplayer)

	selected_chart = chart
	selected_energy = energy
	get_tree().change_scene_to_file(GAMEPLAY_DIR)
	


func load_multiplayer_lobby():
	get_tree().change_scene_to_file(MULTIPLAYER_LOBBY_DIR)


func quit_to_menu():
	get_tree().change_scene_to_file(MENU_DIR)

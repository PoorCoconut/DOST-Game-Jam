extends Node

var selected_chart: ChartData
var selected_energy: String = "Solar"
var selected_replay: ReplayData = null
var is_replay: bool = false
# maybe future LAN logic goes here
var is_multiplayer: bool = false

# Menu Directories
const GAMEPLAY_DIR: String  = "res://scenes/menus/gameplay/world_gameplay.tscn"
const MENU_DIR: String      = "res://scenes/menus/main/main_menu.tscn"
const RANKING_DIR: String   = "res://scenes/menus/ranking/ranking_panel.tscn"
const SETTINGS_DIR: String  = "res://scenes/menus/settings/settings_panel.tscn"
const PAUSE_DIR: String     = "res://scenes/menus/pause/pause_panel.tscn"


func load_gameplay(chart: ChartData, energy: String) -> void:
	selected_chart = chart
	selected_energy = energy
	is_replay = false
	selected_replay = null
	get_tree().change_scene_to_file(GAMEPLAY_DIR)


func load_replay(replay: ReplayData) -> void:
	selected_replay = replay
	selected_chart = replay.chart
	is_replay = true
	get_tree().change_scene_to_file(GAMEPLAY_DIR)


func go_to_ranking() -> void:
	get_tree().change_scene_to_file(RANKING_DIR)


func go_to_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_DIR)


func quit_to_menu() -> void:
	is_replay = false
	selected_replay = null
	get_tree().change_scene_to_file(MENU_DIR)

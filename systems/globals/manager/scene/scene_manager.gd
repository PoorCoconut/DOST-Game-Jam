extends Node

var selected_chart: ChartData
var selected_energy: String = "Solar"
var selected_replay: ReplayData = null
var is_replay: bool = false

# maybe future LAN logic goes here
var is_multiplayer: bool = false

# multiplayer purposes
var opponent_name: String = ""
var waiting_for_start: bool = false
var start_time_msec: int = 0

var _disconnect_message: String = ""

# Menu Directories
const GAMEPLAY_DIR: String  = "res://scenes/menus/gameplay/world_gameplay.tscn"
const MENU_DIR: String      = "res://scenes/menus/test_main/main_menu.tscn"
const RANKING_DIR: String   = "res://scenes/menus/ranking/ranking_panel.tscn"
const SETTINGS_DIR: String  = "res://scenes/menus/settings/settings_panel.tscn"
const PAUSE_DIR: String     = "res://scenes/menus/pause/pause_panel.tscn"
const MULTIPLAYER_LOBBY_DIR: String = "res://scenes/menus/multiplayer/multiplayer_lobby.tscn"

func _ready() -> void:
	NetworkManager.opponent_disconnected.connect(_on_opponent_disconnected)

func _on_opponent_disconnected() -> void:
	if not is_multiplayer:
		return
	var disconnected_name := NetworkManager.guest_name if multiplayer.is_server() else NetworkManager.host_name
	_disconnect_message = "%s has disconnected." % disconnected_name
	handle_opponent_disconnected()

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

func load_multiplayer_lobby():
	get_tree().change_scene_to_file(MULTIPLAYER_LOBBY_DIR)

func go_to_ranking() -> void:
	get_tree().change_scene_to_file(RANKING_DIR)


func go_to_settings() -> void:
	get_tree().change_scene_to_file(SETTINGS_DIR)


func quit_to_menu() -> void:
	is_replay = false
	selected_replay = null
	get_tree().change_scene_to_file(MENU_DIR)

#for handling disconnection
func handle_opponent_disconnected() -> void:
	is_multiplayer = false
	get_tree().change_scene_to_file(MENU_DIR)

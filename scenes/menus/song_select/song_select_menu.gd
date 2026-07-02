extends Control
class_name SongSelectMenuController

@export var charts_to_load: Array[ChartData] = []

@onready var ui_header: UIHeaderComponent = $MainVerticalStack/UIHeader
@onready var song_list: SongListComponent = $MainVerticalStack/MarginContainer/CenterLayoutContainer/SongList
@onready var song_card: SongCardComponent = $MainVerticalStack/MarginContainer/CenterLayoutContainer/SongCard
@onready var loading_spinner: Control = $ViewportLoadingIndicator

var active_gameplay_mods: Dictionary = {"FL": false, "FS": false, "DT": false, "HR": false}
var active_character_skill: String = "Radiance"

func _ready() -> void:
	if loading_spinner: loading_spinner.visible = false
	
	if song_list:
		song_list.selection_changed.connect(_on_song_selection_shifted)
		song_list.song_activated.connect(_on_song_item_triggered)
	
	if ui_header:
		ui_header.gameplay_mods_changed.connect(_on_mods_payload_updated)
		ui_header.character_skill_changed.connect(_on_skill_payload_updated)
		
	_initialize_menu()

func _on_mods_payload_updated(new_mods: Dictionary) -> void:
	active_gameplay_mods = new_mods

func _on_skill_payload_updated(new_skill: String) -> void:
	active_character_skill = new_skill

func _on_song_selection_shifted(chart: ChartData) -> void:
	if song_card: song_card.display_chart_details(chart)

func _on_song_item_triggered(chart: ChartData) -> void:
	SceneManager.load_gameplay(chart, SceneManager.selected_energy)

func _initialize_menu() -> void:
	if charts_to_load.is_empty():
		if song_list: song_list.setup_list(_generate_mock_track_data())
	else:
		if song_list: song_list.setup_list(charts_to_load)
	if song_list: song_list.grab_list_focus()

func _generate_mock_track_data() -> Array[ChartData]:
	var mock_list: Array[ChartData] = []
		
	var tracks_metadata := [
		{"name": "Beyond the Edge", "artist": "Xyris (feat. Hanakuma Chifuyu)", "bpm": 205.0},
		{"name": "Lollipop", "artist": "Geoxor", "bpm": 120.0},
		{"name": "Breakbeat Chaos", "artist": "Barely Reliable DJ", "bpm": 140.0}
	]
	for metadata in tracks_metadata:
		var chart := ChartData.new()
		chart.song_name = metadata["name"]
		chart.artist = metadata["artist"]
		chart.bpm = metadata["bpm"]
		mock_list.append(chart)
	return mock_list

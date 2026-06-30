extends Control
class_name SongSelectMenuController

@export var charts_to_load: Array[ChartData] = []

@onready var ui_header: UIHeaderComponent = $MainVerticalStack/UIHeader
@onready var song_list: SongListComponent = $MainVerticalStack/MarginContainer/CenterLayoutContainer/SongList
@onready var song_card: SongCardComponent = $MainVerticalStack/MarginContainer/CenterLayoutContainer/SongCard
@onready var loading_spinner: Control = $ViewportLoadingIndicator
@onready var profile_dropdown: ProfileDropdownOverlayComponent = $ProfileDropdownOverlay
@onready var profile_input_modal: ProfileInputModalComponent = $ProfileInputModal
func _ready() -> void:
	loading_spinner.visible = false
	
	song_list.selection_changed.connect(_on_song_selection_shifted)
	song_list.song_activated.connect(_on_song_item_triggered)
	
	# Wire up unified UI Header signal channels
	ui_header.back_pressed.connect(_on_back_navigated)
	ui_header.settings_pressed.connect(_on_settings_overlay_opened)
	ui_header.volume_pressed.connect(_on_volume_overlay_opened)
	ui_header.profile_toggled.connect(_on_profile_dropdown_toggled)
	ui_header.skills_toggled.connect(_on_skills_menu_toggled)
	ui_header.mods_toggled.connect(_on_mods_menu_toggled)
	
	profile_dropdown.edit_profile_requested.connect(_on_edit_profile_window_triggered)
	
	_initialize_menu()

func _initialize_menu() -> void:
	if charts_to_load.is_empty():
		var dummy_charts: Array[ChartData] = _generate_mock_track_data()
		song_list.setup_list(dummy_charts)
	else:
		song_list.setup_list(charts_to_load)
	
	song_list.grab_list_focus()

func _on_song_selection_shifted(chart: ChartData) -> void:
	song_card.display_chart_details(chart)

func _on_song_item_triggered(chart: ChartData) -> void:
	print("[SYSTEM] Launching match track criteria: ", chart.song_name)
	SceneManager.load_gameplay(chart, SceneManager.selected_energy)

func _on_back_navigated() -> void:
	print("[NAV] Dropping back to principal title sequence menu...")
	# Directly re-routing back to your main menu scene tree location

func _on_settings_overlay_opened() -> void:
	print("[OVERLAY] Opening volume and hardware offset configuration panels...")

func _on_volume_overlay_opened() -> void:
	print("[OVERLAY] Initializing instant audio volume slider mix controls...")

func _on_profile_dropdown_toggled(is_open: bool) -> void:
	print("[OVERLAY] Profile dropdown tracking state updated: ", is_open)
	if is_open:
		var profile_card_ref = ui_header.profile_card
		var target_global_pos: Vector2 = profile_card_ref.global_position
		
		target_global_pos.y += profile_card_ref.size.y - 8
		
		profile_dropdown.custom_minimum_size.x = profile_card_ref.size.x
		profile_dropdown.size.x = profile_card_ref.size.x
		
		profile_dropdown.global_position = target_global_pos
		
	profile_dropdown.toggle_dropdown(is_open)

func _on_skills_menu_toggled(is_open: bool) -> void:
	print("[OVERLAY] Skills configuration panel toggle received: ", is_open)
	if is_open:
		profile_dropdown.toggle_dropdown(false)

func _on_mods_menu_toggled(is_open: bool) -> void:
	print("[OVERLAY] Gameplay modifiers selection grid toggle received: ", is_open)
	if is_open:
		profile_dropdown.toggle_dropdown(false)

func _on_edit_profile_window_triggered() -> void:
	print("[OVERLAY] Opening profile edit overlay...")
	ui_header.profile_card.set_dropdown_state_no_signal(false)
	profile_dropdown.toggle_dropdown(false)
	
	# Pull both data points directly from your existing header layout component tracking branches
	var active_name: String = ui_header.profile_card.username_label.text
	var active_pfp: Texture2D = ui_header.profile_card.avatar_texture.texture
	
	# Launch modal with the active profile details filled out
	profile_input_modal.open_modal(active_name, active_pfp)
	
	if profile_input_modal.change_confirmed.is_connected(_on_profile_identity_updated):
		profile_input_modal.change_confirmed.disconnect(_on_profile_identity_updated)
		
	profile_input_modal.change_confirmed.connect(_on_profile_identity_updated)

func _on_profile_identity_updated(new_username: String, new_avatar: Texture2D) -> void:
	print("[SYSTEM] Saving profile changes...")
	# Instantly apply both visual variables right back onto the visible user profile components
	ui_header.profile_card.username_label.text = new_username
	ui_header.profile_card.avatar_texture.texture = new_avatar
# Dummy Data
func _generate_mock_track_data() -> Array[ChartData]:
	var mock_list: Array[ChartData] = []
	var test_texture: Texture2D = preload("res://assets/backgrounds/test.jpg")
	
	var tracks_metadata := [
		{"name": "Beyond the Edge", "artist": "Xyris (feat. Hanakuma Chifuyu)", "bpm": 205.0, "notes": 1036},
		{"name": "Lollipop", "artist": "Geoxor", "bpm": 120.0, "notes": 642},
		{"name": "Breakbeat Chaos", "artist": "Barely Reliable DJ", "bpm": 140.0, "notes": 812},
		{"name": "Gothic Noir Resonance", "artist": "Vantablack Symphony", "bpm": 95.0, "notes": 420},
		{"name": "Cyberpunk Rebellion", "artist": "Neon Vizard", "bpm": 175.0, "notes": 1250},
		{"name": "Eldritch Whispers", "artist": "Revelation Source", "bpm": 110.0, "notes": 530},
		{"name": "StashRaid Groove", "artist": "Digital Grunge Project", "bpm": 132.0, "notes": 715}
	]
	
	for metadata in tracks_metadata:
		var chart := ChartData.new()
		chart.song_name = metadata["name"]
		chart.artist = metadata["artist"]
		chart.bpm = metadata["bpm"]
		chart.background = test_texture
		
		for i in range(metadata["notes"]):
			var note := NoteData.new()
			chart.notes.append(note)
			
		mock_list.append(chart)
		
	return mock_list

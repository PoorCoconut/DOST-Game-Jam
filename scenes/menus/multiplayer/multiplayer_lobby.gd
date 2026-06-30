extends Control

# Who is shown in the lobby
@onready var host_label: Label = $Layout/PlayerPanel/HostLabel
@onready var guest_label: Label = $Layout/PlayerPanel/GuestLabel

# Energy type picker — each player picks their own lane
@onready var energy_option: OptionButton = $Layout/SettingsPanel/EnergyOption

# Only the host sees and can press Start
@onready var start_button: Button = $Layout/StartButton
@onready var waiting_label: Label = $Layout/WaitingLabel

@onready var status_label: Label = $Layout/StatusLabel

const ENERGY_TYPES := ["Solar", "Wind", "Hydro", "Geo"]


func _ready() -> void:
	_populate_energy_options()
	_setup_player_labels()
	_setup_host_or_guest_ui()

	if not NetworkManager.match_load_requested.is_connected(_on_match_load_requested):
		NetworkManager.match_load_requested.connect(_on_match_load_requested)


func _populate_energy_options() -> void:
	energy_option.clear()
	for e in ENERGY_TYPES:
		energy_option.add_item(e)

	# Default to whatever was last used (Solar if first time)
	var default_idx := ENERGY_TYPES.find(SceneManager.selected_energy)
	energy_option.selected = max(default_idx, 0)


func _setup_player_labels() -> void:
	if multiplayer.is_server():
		host_label.text = "You (Host): %s" % NetworkManager.player_name
		guest_label.text = "Guest: connecting..."
	else:
		host_label.text = "Host: %s" % NetworkManager.host_name
		guest_label.text = "You (Guest): %s" % NetworkManager.player_name


func _setup_host_or_guest_ui() -> void:
	var i_am_host := multiplayer.is_server()
	start_button.visible = i_am_host
	waiting_label.visible = not i_am_host


func _on_energy_selected(index: int) -> void:
	# Store locally — sent to SceneManager just before gameplay loads
	SceneManager.selected_energy = ENERGY_TYPES[index]


func _on_start_pressed() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	status_label.text = "Loading match..."
	start_button.disabled = true

	if not SceneManager.selected_chart:
		push_error("[MultiplayerLobby] No chart selected!")
		return

	NetworkManager.send_match_data(
		SceneManager.selected_chart,
		SceneManager.selected_energy
	)

func _on_match_load_requested(_chart_path: String,_energy: String) -> void:
	status_label.text = "Loading gameplay..."
	SceneManager.load_gameplay(
		SceneManager.selected_chart,
		SceneManager.selected_energy
	)

func _on_quit_pressed() -> void:
	NetworkManager.disconnect_session()
	SceneManager.quit_to_menu()

extends Control

@onready var name_input: LineEdit     = $CenterContainer/MainPanel/Margin/VBox/InputRow/NameInput
@onready var host_room_button: Button = $CenterContainer/MainPanel/Margin/VBox/InputRow/HostRoomButton
@onready var status_label: Label      = $CenterContainer/MainPanel/Margin/VBox/StatusLabel
@onready var room_list: VBoxContainer = $CenterContainer/MainPanel/Margin/VBox/ScrollContainer/RoomList

var _room_ips: Array[String] = []
var _is_hosting: bool = false

func _ready() -> void:
	NetworkManager.start_presence("Player")
	NetworkManager.room_found.connect(_on_room_found)
	NetworkManager.room_lost.connect(_on_room_lost)
	# Only guest needs session_ready — host goes to lobby directly
	if not _is_hosting:
		NetworkManager.session_ready.connect(_on_session_ready)


func _on_back_pressed() -> void:
	NetworkManager.stop_presence()
	NetworkManager.close_room()
	SceneManager.quit_to_menu()


func _on_host_room_pressed() -> void:
	var entered_name := name_input.text.strip_edges()
	if entered_name.is_empty():
		status_label.text = "Enter a name first."
		return
	NetworkManager.player_name = entered_name
	NetworkManager.start_presence(entered_name)
	NetworkManager.create_room(entered_name + "'s room")
	_is_hosting = true
	SceneManager.is_multiplayer = true
	SceneManager.load_multiplayer_lobby()


func _on_room_found(ip: String, room_name: String, _host_name: String) -> void:
	if _room_ips.has(ip):
		return
	_room_ips.append(ip)

	var btn := Button.new()
	btn.text = room_name
	btn.name = "Room_" + ip.replace(".", "_")
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func(): _on_room_clicked(ip))
	room_list.add_child(btn)


func _on_room_lost(ip: String) -> void:
	var idx := _room_ips.find(ip)
	if idx == -1:
		return
	_room_ips.remove_at(idx)
	var node := room_list.get_node_or_null("Room_" + ip.replace(".", "_"))
	if node:
		node.queue_free()


func _on_room_clicked(ip: String) -> void:
	var entered_name := name_input.text.strip_edges()
	if entered_name.is_empty():
		status_label.text = "Enter a name first."
		return

	NetworkManager.player_name = entered_name
	status_label.text = "Joining room..."
	NetworkManager.send_invite(ip)


func _on_session_ready() -> void:
	NetworkManager.session_ready.disconnect(_on_session_ready)
	SceneManager.is_multiplayer = true
	await get_tree().create_timer(0.1).timeout
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		NetworkManager.send_guest_name.rpc_id(1, NetworkManager.player_name)
	SceneManager.load_multiplayer_lobby()

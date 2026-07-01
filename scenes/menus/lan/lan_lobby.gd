extends Control

@onready var name_input: LineEdit = $MainPanel/NameInput
@onready var go_online_button: Button = $MainPanel/GoOnlineButton
@onready var status_label: Label = $MainPanel/StatusLabel
@onready var peer_list: ItemList = $MainPanel/PeerList

@onready var invite_panel: PanelContainer = $InvitePanel
@onready var invite_label: Label = $InvitePanel/InviteVBox/InviteLabel

var _peer_ips: Array[String] = []
var _pending_invite_from: String = ""
var _awaiting_response: bool = false


func _ready() -> void:
	invite_panel.visible = false
	peer_list.visible = false

	NetworkManager.peer_found.connect(_on_peer_found)
	NetworkManager.peer_lost.connect(_on_peer_lost)
	NetworkManager.invite_received.connect(_on_invite_received)
	NetworkManager.invite_declined.connect(_on_invite_declined)
	NetworkManager.session_ready.connect(_on_session_ready)


func _on_go_online_pressed() -> void:
	var entered_name := name_input.text.strip_edges()
	if entered_name.is_empty():
		status_label.text = "Enter a name first."
		return

	NetworkManager.start_presence(entered_name)
	name_input.editable = false
	go_online_button.disabled = true
	peer_list.visible = true
	status_label.text = "Scanning for players on the LAN..."


func _on_peer_found(ip: String, peer_name: String) -> void:
	_peer_ips.append(ip)
	peer_list.add_item("%s  (%s)" % [peer_name, ip])


func _on_peer_lost(ip: String) -> void:
	var idx := _peer_ips.find(ip)
	if idx == -1:
		return
	_peer_ips.remove_at(idx)
	peer_list.remove_item(idx)


func _on_peer_selected(index: int) -> void:
	if _awaiting_response:
		return
	_awaiting_response = true

	var target_ip := _peer_ips[index]
	NetworkManager.send_invite(target_ip)
	status_label.text = "Invite sent. Waiting for response..."


func _on_invite_received(from_ip: String, from_name: String) -> void:
	_pending_invite_from = from_ip
	invite_label.text = "%s wants to play. Accept?" % from_name
	invite_panel.visible = true


func _on_accept_pressed() -> void:
	invite_panel.visible = false
	NetworkManager.accept_invite(_pending_invite_from)
	status_label.text = "Connecting..."


func _on_decline_pressed() -> void:
	invite_panel.visible = false
	NetworkManager.decline_invite(_pending_invite_from)
	_pending_invite_from = ""


func _on_invite_declined() -> void:
	status_label.text = "Invite declined."
	_awaiting_response = false


func _on_session_ready() -> void:
	SceneManager.is_multiplayer = true
	SceneManager.load_multiplayer_lobby()


func _on_back_pressed() -> void:
	NetworkManager.stop_presence()
	queue_free()
	SceneManager.quit_to_menu()

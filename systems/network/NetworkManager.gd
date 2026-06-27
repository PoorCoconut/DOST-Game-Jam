# what this does is
#UDP hadnshakes between two client machines or players(i lik euysing networking lingos)
#then transitions to eNet for the actual game session 

#networking?
#yeah, my net working
extends Node

# ports to use
const PRESENCE_PORT = 4243
const SIGNAL_PORT   = 4244
const GAME_PORT     = 4242
const BROADCAST_INTERVAL = 1.5
const PEER_TIMEOUT  = 4.0

const MSG_PRESENCE = "PRESENCE"
const MSG_INVITE   = "INVITE"
const MSG_ACCEPT   = "ACCEPT"
const MSG_DECLINE  = "DECLINE"
const MSG_SESSION  = "SESSION"

# what the ui listens
signal peer_found(ip: String, peer_name: String)
signal peer_lost(ip: String)
signal invite_received(from_ip: String, from_name: String)
signal invite_declined()
signal session_ready()          # ENet establishjed
signal opponent_disconnected()

var player_name: String = "Player"
var host_name: String = ""
var my_ip: String = ""

var _active_peers: Dictionary = {}      # ip -> { "name": String, "last_seen": float }
var _pending_invite_ip: String = ""     # who WE invited (we become host if accepted)

var _broadcast_socket: PacketPeerUDP
var _presence_socket: PacketPeerUDP
var _signal_socket: PacketPeerUDP

var _broadcasting: bool = false
var _broadcast_timer: float = 0.0
var _session_starting: bool = false   # true once we begin tearing down for ENet

signal match_load_requested(chart_name: String, energy: String)
signal opponent_ready()
signal countdown_started(start_time: int)

var host_ready := false
var guest_opponent_ready := false


func _ready() -> void:
	my_ip = _get_local_ip()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func _process(delta: float) -> void:
	if _session_starting:
		return  # stops udp handsahke 
	if _broadcasting:
		_broadcast_tick(delta)
	_read_presence()
	_read_signals()
	_expire_peers(delta)


#presence loops
#presence is a player being shown in the ui

func start_presence(name: String) -> void:
	player_name = name
	host_name = ""
	_active_peers.clear()
	_session_starting = false

	_broadcast_socket = PacketPeerUDP.new()
	_broadcast_socket.set_broadcast_enabled(true)
	_broadcast_socket.bind(0)

	_presence_socket = PacketPeerUDP.new()
	var err1 := _presence_socket.bind(PRESENCE_PORT)
	if err1 != OK:
		push_warning("NetworkManager: failed to bind presence port (%d) — is another instance already using it?" % err1)

	_signal_socket = PacketPeerUDP.new()
	var err2 := _signal_socket.bind(SIGNAL_PORT)
	if err2 != OK:
		push_warning("NetworkManager: failed to bind signal port (%d) — is another instance already using it?" % err2)

	_broadcasting = true
	print("[Net] Presence started. My IP: ", my_ip)


func stop_presence() -> void:
	_broadcasting = false
	if _broadcast_socket: _broadcast_socket.close()
	if _presence_socket:  _presence_socket.close()
	if _signal_socket:    _signal_socket.close()
	_broadcast_socket = null
	_presence_socket = null
	_signal_socket = null


#preseence listens + broadcasts presence to otther people in the same net

func _broadcast_tick(delta: float) -> void:
	_broadcast_timer += delta
	if _broadcast_timer >= BROADCAST_INTERVAL:
		_broadcast_timer = 0.0
		var packet := { "type": MSG_PRESENCE, "name": player_name }
		_broadcast_socket.set_dest_address("255.255.255.255", PRESENCE_PORT)
		_broadcast_socket.put_packet(JSON.stringify(packet).to_utf8_buffer())


func _read_presence() -> void:
	if not _presence_socket:
		return
	while _presence_socket.get_available_packet_count() > 0:
		var bytes := _presence_socket.get_packet()
		var sender_ip := _presence_socket.get_packet_ip()

		if sender_ip == my_ip:
			continue  # ignore our own broadcast

		var msg = JSON.parse_string(bytes.get_string_from_utf8())
		if msg == null or msg.get("type") != MSG_PRESENCE:
			continue

		var peer_name: String = msg.get("name", "Unknown")

		if not _active_peers.has(sender_ip):
			_active_peers[sender_ip] = { "name": peer_name, "last_seen": 0.0 }
			peer_found.emit(sender_ip, peer_name)
		else:
			_active_peers[sender_ip]["last_seen"] = 0.0


func _expire_peers(delta: float) -> void:
	var to_remove: Array = []
	for ip in _active_peers:
		_active_peers[ip]["last_seen"] += delta
		if _active_peers[ip]["last_seen"] > PEER_TIMEOUT:
			to_remove.append(ip)
	for ip in to_remove:
		_active_peers.erase(ip)
		peer_lost.emit(ip)


# on some signalingg tyshttt invite, accept, reject sessions

func _read_signals() -> void:
	if not _signal_socket:
		return
		
	# Add a safety check to ensure _signal_socket still exists
	while _signal_socket and _signal_socket.get_available_packet_count() > 0:
		var bytes := _signal_socket.get_packet()
		var sender_ip := _signal_socket.get_packet_ip()
		var msg = JSON.parse_string(bytes.get_string_from_utf8())
		if msg == null:
			continue

		match msg.get("type"):
			MSG_INVITE:
				invite_received.emit(sender_ip, msg.get("name", "Unknown"))

			MSG_ACCEPT:
				print("[Net] %s accepted — becoming host" % sender_ip)
				_become_host(sender_ip)
				return 

			MSG_DECLINE:
				_pending_invite_ip = ""
				invite_declined.emit()

			MSG_SESSION:
				host_name = msg.get("name", "Host")
				var host_ip: String = msg.get("ip", "")
				var port: int = msg.get("port", GAME_PORT)
				_join_as_client(host_ip, port)
				return

#ping
func _send_signal(target_ip: String, data: Dictionary) -> void:
	if not _signal_socket:
		return
	_signal_socket.set_dest_address(target_ip, SIGNAL_PORT)
	_signal_socket.put_packet(JSON.stringify(data).to_utf8_buffer())


func send_invite(target_ip: String) -> void:
	_pending_invite_ip = target_ip
	_send_signal(target_ip, { "type": MSG_INVITE, "name": player_name })
	print("[Net] Invite sent to ", target_ip)


func accept_invite(from_ip: String) -> void:
	_send_signal(from_ip, { "type": MSG_ACCEPT })
	print("[Net] Accepted invite from ", from_ip)
	# We now wait for a seesion message from them (they become host)


func decline_invite(from_ip: String) -> void:
	_send_signal(from_ip, { "type": MSG_DECLINE })
	print("[Net] Declined invite from ", from_ip)


# host 

func _become_host(client_ip: String) -> void:
	_session_starting = true
	stop_presence()

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(GAME_PORT, 1)
	if err != OK:
		push_error("NetworkManager: failed to create server (%d)" % err)
		return

	multiplayer.multiplayer_peer = peer

	#holy wtich craft : creates a temporary connection to send a invitation message to a client 
#	what that message contains? the ip and the port of where encore is being hosted then this connection is destroyed

	var notify := PacketPeerUDP.new()
	notify.bind(0)
	notify.set_dest_address(client_ip, SIGNAL_PORT)
	notify.put_packet(JSON.stringify({
		"type": MSG_SESSION,
		"ip": my_ip,
		"port": GAME_PORT,
		"name": player_name
}).to_utf8_buffer())
	notify.close()

	print("[Net] Hosting on port ", GAME_PORT)

#end of witch craft

#client side
func _join_as_client(host_ip: String, port: int) -> void:
	_session_starting = true
	stop_presence()

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host_ip, port)
	if err != OK:
		push_error("NetworkManager: failed to connect (%d)" % err)
		return

	multiplayer.multiplayer_peer = peer
	print("[Net] Connecting to host at %s:%d" % [host_ip, port])


#Enet callbacks(witchcraft)
func _on_peer_connected(_id: int) -> void:
	print("[Net] ENet peer connected")
	session_ready.emit()


func _on_peer_disconnected(_id: int) -> void:
	print("[Net] ENet peer disconnected")
	opponent_disconnected.emit()


func _on_connected_to_server() -> void:
	print("[Net] Connected to host")
	session_ready.emit()


func _on_connection_failed() -> void:
	push_warning("[Net] Connection failed")

# ayaw idelete kay magamit
# para makuha ang lista sa mga nagduwa
func get_peers() -> Dictionary:
	return _active_peers

# para ma check knsa ang host sa duha
func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()


func reset_session() -> void: #basically sets everything to false to run back defaults
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	multiplayer.multiplayer_peer = null
	_pending_invite_ip = ""
	_active_peers.clear()
	_session_starting = false
	host_ready = false
	guest_opponent_ready = false

func disconnect_session() -> void:
	reset_session()

#witchcraft


func _get_local_ip() -> String:
	# Check 192.168.x.x first lan setups use this range
	# and it avoids accidentally picking Docker (172.17.x.x) or VPN interfaces
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168."):
			return addr
			
	
	# Fall back to 10.x.x.x (incase it doesnt find 192.168 lan setups)
	for addr in IP.get_local_addresses():
		if addr.begins_with("10."):
			return addr
			
	#added this because it routed to my docker server instead to my pc(foiund the docker address first)
	#this also fixed the found myself in the lan search problem(the game detected my docker address first
	# and used it as the player1 address instead of my actual address)
	# worst case scenario 172.x.x.x but skip Docker's default bridge (172.17.x.x)
	for addr in IP.get_local_addresses():
		if addr.begins_with("172.") and not addr.begins_with("172.17."):
			return addr
	return "127.0.0.1"

# RPC calls are divided into purposes and not crammed into one
@rpc("authority", "reliable")
func receive_match_data(chart_path: String, energy: String):
	print("[Match] Loading chart: ", chart_path)

	SceneManager.selected_chart = load(chart_path)
	SceneManager.selected_energy = energy

	match_load_requested.emit(chart_path, energy)

@rpc("any_peer", "reliable")
func notify_ready():
	guest_opponent_ready = true
	opponent_ready.emit()

	if host_ready and guest_opponent_ready:
		begin_match_countdown()

@rpc("authority", "reliable")
func start_countdown(countdown_ms: int):
	var start_time := Time.get_ticks_msec() + countdown_ms
	SceneManager.start_time_msec = start_time
	countdown_started.emit(start_time)

func send_match_data(chart: ChartData, energy: String):
	host_ready = false
	guest_opponent_ready = false
	var peer_ids = multiplayer.get_peers()
	if peer_ids.is_empty():
		return
	var guest_id = peer_ids[0]
	# host
	SceneManager.selected_chart = chart
	SceneManager.selected_energy = energy

	match_load_requested.emit(chart.resource_path,energy)
	# guest
	receive_match_data.rpc_id(guest_id,chart.resource_path,energy)


func begin_match_countdown():
	var peer_ids = multiplayer.get_peers()
	if peer_ids.is_empty():
		return
	var guest_id = peer_ids[0]
	var countdown_ms: int = 3000
	start_countdown.rpc_id(guest_id, countdown_ms)
	start_countdown(countdown_ms)

# helper
func send_ready():
	print(multiplayer.get_unique_id())#checker
	notify_ready.rpc_id(1) # 1 = host

func set_host_ready():
	host_ready = true

	if host_ready and guest_opponent_ready:
		begin_match_countdown()

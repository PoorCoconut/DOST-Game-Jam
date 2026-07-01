extends ScrollContainer
class_name SongListComponent

signal selection_changed(chart_data: ChartData)
signal song_activated(chart_data: ChartData)

@export var song_item_scene: PackedScene = preload("res://scenes/menus/song_select/song_list/song_item/song_item.tscn")
@onready var container: VBoxContainer = $SongsContainerVBox

var compiled_item_nodes: Array[SongItem] = []
var active_charts_dataset: Array[ChartData] = []

var top_spacer: Control = null
var bottom_spacer: Control = null

var current_focused_idx: int = 0
var last_clicked_item: SongItem = null

func setup_list(charts: Array[ChartData]) -> void:
	active_charts_dataset = charts
	last_clicked_item = null
	
	for child in container.get_children():
		child.queue_free()
	compiled_item_nodes.clear()

	if charts.is_empty():
		return

	top_spacer = Control.new()
	container.add_child(top_spacer)

	for i in range(charts.size()):
		var chart := charts[i]
		var item := song_item_scene.instantiate() as SongItem
		
		container.add_child(item)
		item.setup(chart)
		compiled_item_nodes.append(item)
		
		item.item_focused.connect(func(c: ChartData): _on_item_focused_in_list(i, c))
		item.item_pressed.connect(_on_item_pressed_evaluation)

	bottom_spacer = Control.new()
	container.add_child(bottom_spacer)

	_rebuild_loop_navigation_paths()
	_update_padding_spacers.call_deferred()

func _update_padding_spacers() -> void:
	if compiled_item_nodes.is_empty() or not is_inside_tree():
		return
		
	var item_height: float = compiled_item_nodes[0].custom_minimum_size.y
	var pad_height: float = (size.y / 2.0) - (item_height / 2.0)
	
	top_spacer.custom_minimum_size.y = pad_height
	bottom_spacer.custom_minimum_size.y = pad_height

func _rebuild_loop_navigation_paths() -> void:
	var total_items := compiled_item_nodes.size()
	if total_items <= 1:
		return

	for i in range(total_items):
		var up_idx := (i - 1 + total_items) % total_items
		var down_idx := (i + 1) % total_items
		
		compiled_item_nodes[i].focus_neighbor_top = compiled_item_nodes[up_idx].get_path()
		compiled_item_nodes[i].focus_neighbor_bottom = compiled_item_nodes[down_idx].get_path()

func _on_item_focused_in_list(index: int, chart: ChartData) -> void:
	current_focused_idx = index
	selection_changed.emit(chart)
	_ensure_item_is_centered_visually(index)

# --- FOOLPROOF INPUT CLICK EVALUATOR ---

func _on_item_pressed_evaluation(clicked_item: SongItem) -> void:
	var clicked_idx = compiled_item_nodes.find(clicked_item)
	if clicked_idx == -1: return
	
	# Check if this node instance matches our consecutive click history register
	if last_clicked_item == clicked_item:
		print("[SONG_LIST] Consecutive click confirmed. Opening stage scene...")
		song_activated.emit(clicked_item.chart_ref)
	else:
		print("[SONG_LIST] First click registered. Transferring navigation focus context...")
		last_clicked_item = clicked_item
		_shift_focus_index_explicitly(clicked_idx)

# --- KEYBOARD NAVIGATION CONTROLLER PASSTHROUGHS ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		accept_event()
		_step_selection(1)
	elif event.is_action_pressed("ui_up"):
		accept_event()
		_step_selection(-1)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		if current_focused_idx >= 0 and current_focused_idx < compiled_item_nodes.size():
			song_activated.emit(compiled_item_nodes[current_focused_idx].chart_ref)

func _step_selection(direction: int) -> void:
	var total_items := compiled_item_nodes.size()
	if total_items == 0: return
	
	var target_idx = (current_focused_idx + direction + total_items) % total_items
	_shift_focus_index_explicitly(target_idx)

func _shift_focus_index_explicitly(target_idx: int) -> void:
	if target_idx >= 0 and target_idx < compiled_item_nodes.size():
		# Sync history context tracking during manual arrow key operations
		last_clicked_item = compiled_item_nodes[target_idx]
		compiled_item_nodes[target_idx].grab_focus()

func _ensure_item_is_centered_visually(index: int) -> void:
	var target_item := compiled_item_nodes[index]
	var target_scroll_y := target_item.position.y - (size.y / 2.0) + (target_item.custom_minimum_size.y / 2.0)
	
	var tween := create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scroll_vertical", target_scroll_y, 0.3)

func grab_list_focus() -> void:
	if not compiled_item_nodes.is_empty():
		compiled_item_nodes[current_focused_idx].grab_focus()

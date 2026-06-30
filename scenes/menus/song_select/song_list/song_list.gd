extends ScrollContainer
class_name SongListComponent

signal selection_changed(chart_data: ChartData)
signal song_activated(chart_data: ChartData)

@export var song_item_scene: PackedScene = preload("res://scenes/menus/song_select/song_list/song_item/song_item.tscn")
@onready var container: VBoxContainer = $SongsContainerVBox

var compiled_item_nodes: Array[SongItem] = []
var active_charts_dataset: Array[ChartData] = []

# Keep tracker references for our dynamic padding blocks
var top_spacer: Control = null
var bottom_spacer: Control = null

func setup_list(charts: Array[ChartData]) -> void:
	active_charts_dataset = charts
	
	for child in container.get_children():
		child.queue_free()
	compiled_item_nodes.clear()

	if charts.is_empty():
		return

	# 1. Create and inject the TOP invisible spacer
	top_spacer = Control.new()
	container.add_child(top_spacer)

	# 2. Populate the actual track rows
	for i in range(charts.size()):
		var chart := charts[i]
		var item := song_item_scene.instantiate() as SongItem
		
		container.add_child(item)
		item.setup(chart)
		compiled_item_nodes.append(item)
		
		item.item_focused.connect(func(c: ChartData): _on_item_focused_in_list(i, c))
		item.item_pressed.connect(func(c: ChartData): song_activated.emit(c))

	# 3. Create and inject the BOTTOM invisible spacer
	bottom_spacer = Control.new()
	container.add_child(bottom_spacer)

	_rebuild_loop_navigation_paths()
	
	# 4. Wait a frame for Godot to calculate layout size transforms, then size pads
	_update_padding_spacers.call_deferred()

func _update_padding_spacers() -> void:
	if compiled_item_nodes.is_empty() or not is_inside_tree():
		return
		
	# Target dimension formula: (Viewport Height / 2) - (Item Height / 2)
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
	selection_changed.emit(chart)
	_ensure_item_is_centered_visually(index)

func _ensure_item_is_centered_visually(index: int) -> void:
	var target_item := compiled_item_nodes[index]
	
	# Calculate target centering frame point relative to the layout position
	var target_scroll_y := target_item.position.y - (size.y / 2.0) + (target_item.custom_minimum_size.y / 2.0)
	
	var tween := create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Removed max(0.0, ...) constraint so it can smoothly cruise into our newly padded spacer zones
	tween.tween_property(self, "scroll_vertical", target_scroll_y, 0.3)

func grab_list_focus() -> void:
	if not compiled_item_nodes.is_empty():
		compiled_item_nodes[0].grab_focus()

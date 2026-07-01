extends Button
class_name SongItem

signal item_focused(chart_data: ChartData)
signal item_pressed(item_ref: SongItem) # Passes self instead to let the list handle activation logic

@onready var artwork_texture: TextureRect = $HBoxContainer/ArtworkTexture
@onready var title_label: Label = $HBoxContainer/VBoxContainer/TitleLabel
@onready var artist_label: Label = $HBoxContainer/VBoxContainer/ArtistLabel
@onready var difficulty_row: HBoxContainer = $HBoxContainer/VBoxContainer/DifficultyRow
@onready var hbox: HBoxContainer = $HBoxContainer

var chart_ref: ChartData = null
var active_tween: Tween
var is_visually_hovered: bool = false
var has_list_focus: bool = false

func _ready() -> void:
	# Lock scaling anchors securely to the right margin line
	pivot_offset = Vector2(custom_minimum_size.x, custom_minimum_size.y / 2.0)
	item_rect_changed.connect(func(): pivot_offset = Vector2(custom_minimum_size.x, custom_minimum_size.y / 2.0))
	
	# Focus updates strictly from engine keyboard / scrollwheel indexing passes
	focus_entered.connect(_on_highlight_gained)
	focus_exited.connect(_on_highlight_lost)
	
	# Mouse interactions now trigger isolated cosmetic changes ONLY
	mouse_entered.connect(_on_mouse_hover_entered)
	mouse_exited.connect(_on_mouse_hover_exited)
	
	pressed.connect(_on_pressed)

func setup(chart: ChartData) -> void:
	chart_ref = chart
	title_label.text = chart.song_name
	artist_label.text = chart.artist
	
	if chart.background:
		artwork_texture.texture = chart.background
	
	for child in difficulty_row.get_children():
		child.queue_free()
		
	for i in range(5): 
		var diff_indicator := Label.new()
		diff_indicator.text = "Ω"
		difficulty_row.add_child(diff_indicator)

func _on_mouse_hover_entered() -> void:
	is_visually_hovered = true
	# Slight standalone pop up wherever the mouse is sitting without touching selection focus rules
	if not has_list_focus:
		_animate_state(Vector2(1.05, 1.05), Color(1.1, 1.1, 1.1, 1.0))

func _on_mouse_hover_exited() -> void:
	is_visually_hovered = false
	if not has_list_focus:
		_animate_state(Vector2(1.0, 1.0), Color.WHITE)

func _on_highlight_gained() -> void:
	has_list_focus = true
	item_focused.emit(chart_ref)
	# Full size highlight when selection snaps to this card row
	_animate_state(Vector2(1.12, 1.12), Color(1.2, 1.2, 1.2, 1.0))

func _on_highlight_lost() -> void:
	has_list_focus = false
	# If mouse is still hovering inside the area when focus drops, maintain the slight hover size pop up instead of snapping flat
	if is_visually_hovered:
		_animate_state(Vector2(1.05, 1.05), Color(1.1, 1.1, 1.1, 1.0))
	else:
		_animate_state(Vector2(1.0, 1.0), Color.WHITE)

func _animate_state(target_scale: Vector2, target_modulate: Color) -> void:
	if active_tween:
		active_tween.kill()
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	active_tween.tween_property(self, "scale", target_scale, 0.25)
	active_tween.tween_property(self, "modulate", target_modulate, 0.25)

func _on_pressed() -> void:
	item_pressed.emit(self)

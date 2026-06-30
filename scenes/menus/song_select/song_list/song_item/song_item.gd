extends Button
class_name SongItem

signal item_focused(chart_data: ChartData)
signal item_pressed(chart_data: ChartData)

@onready var artwork_texture: TextureRect = $HBoxContainer/ArtworkTexture
@onready var title_label: Label = $HBoxContainer/VBoxContainer/TitleLabel
@onready var artist_label: Label = $HBoxContainer/VBoxContainer/ArtistLabel
@onready var difficulty_row: HBoxContainer = $HBoxContainer/VBoxContainer/DifficultyRow
@onready var hbox: HBoxContainer = $HBoxContainer

var chart_ref: ChartData = null
var active_tween: Tween

func _ready() -> void:
	# Keep scaling anchors locked comfortably to the right margin line
	# This ensures expansion forces the item to pop out leftward!
	pivot_offset = Vector2(custom_minimum_size.x, custom_minimum_size.y / 2.0)
	item_rect_changed.connect(func(): pivot_offset = Vector2(custom_minimum_size.x, custom_minimum_size.y / 2.0))
	
	focus_entered.connect(_on_highlight_gained)
	focus_exited.connect(_on_highlight_lost)
	mouse_entered.connect(grab_focus)
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

func _on_highlight_gained() -> void:
	item_focused.emit(chart_ref)
	# Grow smoothly and push the layout leftward away from the right anchor line
	_animate_state(Vector2(1.12, 1.12), Color(1.2, 1.2, 1.2, 1.0))

func _on_highlight_lost() -> void:
	_animate_state(Vector2(1.0, 1.0), Color.WHITE)

func _animate_state(target_scale: Vector2, target_modulate: Color) -> void:
	if active_tween:
		active_tween.kill()
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Scale smoothly from the right anchor point
	active_tween.tween_property(self, "scale", target_scale, 0.25)
	# Add a slight brightness bloom to highlight the active track option card
	active_tween.tween_property(self, "modulate", target_modulate, 0.25)

func _on_pressed() -> void:
	item_pressed.emit(chart_ref)

extends Control
class_name SkillsOverlayComponent

signal skill_applied(selected_skill: String)

@onready var card_radiance: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/SkillCard_Radiance
@onready var card_transience: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/SkillCard_Transience
@onready var card_prominence: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/SkillCard_Prominence
@onready var card_convergence: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/SkillCard_Convergence

@onready var accept_btn: Button = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/AcceptButton

var normal_card_style: StyleBoxFlat
var selected_card_style: StyleBoxFlat

# Track the active selection as a single string token identifier
var current_selected_skill: String = "Radiance"

func _ready() -> void:
	visible = false
	_initialize_ui_styles()
	
	card_radiance.gui_input.connect(func(event): _on_card_clicked(event, "Radiance"))
	card_transience.gui_input.connect(func(event): _on_card_clicked(event, "Transience"))
	card_prominence.gui_input.connect(func(event): _on_card_clicked(event, "Prominence"))
	card_convergence.gui_input.connect(func(event): _on_card_clicked(event, "Convergence"))
	
	accept_btn.pressed.connect(_on_accept_pressed)

func _initialize_ui_styles() -> void:
	normal_card_style = StyleBoxFlat.new()
	normal_card_style.bg_color = Color("#2d2d30")
	normal_card_style.set_corner_radius_all(6)
	normal_card_style.border_width_left = 0
	normal_card_style.border_width_top = 0
	normal_card_style.border_width_right = 0
	normal_card_style.border_width_bottom = 0

	selected_card_style = normal_card_style.duplicate()
	selected_card_style.border_width_left = 2
	selected_card_style.border_width_top = 2
	selected_card_style.border_width_right = 2
	selected_card_style.border_width_bottom = 2
	selected_card_style.border_color = Color("#ffffff")

func open_overlay(active_skill: String) -> void:
	current_selected_skill = active_skill
	_refresh_card_visuals()
	visible = true

func _on_card_clicked(event: InputEvent, skill_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		# Enforce mutual exclusivity by overwriting the selection token instantly
		current_selected_skill = skill_id
		_refresh_card_visuals()

func _refresh_card_visuals() -> void:
	card_radiance.add_theme_stylebox_override("panel", selected_card_style if current_selected_skill == "Radiance" else normal_card_style)
	card_transience.add_theme_stylebox_override("panel", selected_card_style if current_selected_skill == "Transience" else normal_card_style)
	card_prominence.add_theme_stylebox_override("panel", selected_card_style if current_selected_skill == "Prominence" else normal_card_style)
	card_convergence.add_theme_stylebox_override("panel", selected_card_style if current_selected_skill == "Convergence" else normal_card_style)

func _on_accept_pressed() -> void:
	skill_applied.emit(current_selected_skill)
	visible = false

extends PanelContainer
class_name ProfileCardComponent

signal profile_clicked(is_open: bool)
var is_dropdown_open: bool = false

@onready var username_label: Label = $MarginContainer/HBoxContainer/UserTextVBox/UsernameLabel
@onready var avatar_texture: TextureRect = $MarginContainer/HBoxContainer/AvatarFrame/AvatarTexture
@onready var energy_icon: TextureRect = $MarginContainer/HBoxContainer/UserTextVBox/EnergyHBox/EnergyIcon
@onready var energy_label: Label = $MarginContainer/HBoxContainer/UserTextVBox/EnergyHBox/EnergyLabelVBox/EnergyLabel
@onready var element_label: Label = $MarginContainer/HBoxContainer/UserTextVBox/EnergyHBox/EnergyLabelVBox/ElementLabel

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	print("[DIAGNOSTIC] ProfileCard initialized successfully.")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		is_dropdown_open = !is_dropdown_open
		profile_clicked.emit(is_dropdown_open)

func set_dropdown_state_no_signal(state: bool) -> void:
	is_dropdown_open = state

func update_skill_display(skill_name: String, element_text: String, theme_color: Color, icon_texture: Texture2D) -> void:
	if username_label and username_label.text.is_empty(): 
		username_label.text = "Shrek Serato"
	if energy_label:
		energy_label.text = skill_name
		energy_label.add_theme_color_override("font_color", theme_color)
	if element_label:
		element_label.text = element_text
	if energy_icon:
		energy_icon.texture = icon_texture # Safely handles placeholder textures or null

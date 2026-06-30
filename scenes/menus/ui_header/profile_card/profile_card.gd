extends PanelContainer
class_name ProfileCardComponent

signal profile_clicked(is_open: bool)

@onready var username_label: Label = $MarginContainer/HBoxContainer/UserTextVBox/UsernameLabel
@onready var energy_label: Label = $MarginContainer/HBoxContainer/UserTextVBox/EnergyHBox/EnergyLabel
@onready var avatar_texture: TextureRect = $MarginContainer/HBoxContainer/AvatarFrame/AvatarTexture

var dropdown_open: bool = false

func _ready() -> void:
	# Set filter type so this container intercepts mouse clicks natively
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Load default placeholder profile metrics
	update_display("asterialumi", "Radiance", "SOLAR")
	
	var pfp: Texture2D = preload("res://assets/backgrounds/test.jpg")
	if pfp:
		avatar_texture.texture = pfp

func _gui_input(event: InputEvent) -> void:
	# Check for left-mouse clicks anywhere on the panel frame
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dropdown_open = !dropdown_open
		profile_clicked.emit(dropdown_open)
		accept_event() # Stops the click from hitting underlying menu layers

func update_display(username: String, energy_name: String, energy_type: String) -> void:
	username_label.text = username
	energy_label.text = "%s (%s)" % [energy_name.to_upper(), energy_type.to_upper()]

## Call this to programmatically close the dropdown when other tabs override it
func set_dropdown_state_no_signal(state: bool) -> void:
	dropdown_open = state

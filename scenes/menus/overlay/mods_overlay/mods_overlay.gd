extends Control
class_name ModsOverlayComponent

signal mods_applied(active_mods: Dictionary)

# Card Node Map References
@onready var card_fl: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/ModCard_FL
@onready var card_fs: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/ModCard_FS
@onready var card_dt: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/ModCard_DT
@onready var card_hr: PanelContainer = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/CardsHBOX/ModCard_HR

@onready var accept_btn: Button = $MarginContainer/ModalFrame/MarginContainer/VBoxContainer/AcceptButton

# Preloading Stylebox variations for selection highlights
var normal_card_style: StyleBoxFlat
var selected_card_style: StyleBoxFlat

var current_mods: Dictionary = {
	"FL": false,
	"FS": false,
	"DT": false,
	"HR": false
}

func _ready() -> void:
	visible = false
	_initialize_ui_styles()
	
	# Wire up individual mouse click listeners directly on the custom panel card hitboxes
	card_fl.gui_input.connect(func(event): _on_card_clicked(event, "FL"))
	card_fs.gui_input.connect(func(event): _on_card_clicked(event, "FS"))
	card_dt.gui_input.connect(func(event): _on_card_clicked(event, "DT"))
	card_hr.gui_input.connect(func(event): _on_card_clicked(event, "HR"))
	
	accept_btn.pressed.connect(_on_accept_pressed)

func _initialize_ui_styles() -> void:
	# Define your normal dark gray card look
	normal_card_style = StyleBoxFlat.new()
	normal_card_style.bg_color = Color("#2d2d30")
	normal_card_style.set_corner_radius_all(6)
	normal_card_style.border_width_left = 0
	normal_card_style.border_width_top = 0
	normal_card_style.border_width_right = 0
	normal_card_style.border_width_bottom = 0

	# Define the white selection boundary look matching the mockup
	selected_card_style = normal_card_style.duplicate()
	selected_card_style.border_width_left = 2
	selected_card_style.border_width_top = 2
	selected_card_style.border_width_right = 2
	selected_card_style.border_width_bottom = 2
	selected_card_style.border_color = Color("#ffffff")

func open_overlay(active_state: Dictionary) -> void:
	current_mods = active_state.duplicate()
	_refresh_card_visuals()
	visible = true

func _on_card_clicked(event: InputEvent, mod_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		
		# Toggle selection state
		current_mods[mod_id] = !current_mods[mod_id]
			
		_refresh_card_visuals()

func _refresh_card_visuals() -> void:
	# Dynamically swap style outlines to match selection states
	card_fl.add_theme_stylebox_override("panel", selected_card_style if current_mods["FL"] else normal_card_style)
	card_fs.add_theme_stylebox_override("panel", selected_card_style if current_mods["FS"] else normal_card_style)
	card_dt.add_theme_stylebox_override("panel", selected_card_style if current_mods["DT"] else normal_card_style)
	card_hr.add_theme_stylebox_override("panel", selected_card_style if current_mods["HR"] else normal_card_style)

func _on_accept_pressed() -> void:
	mods_applied.emit(current_mods)
	visible = false

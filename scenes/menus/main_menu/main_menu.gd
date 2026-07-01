extends Control

@export var test_chart: ChartData

@onready var menu_list: VBoxContainer = $MenuList
@onready var focus_indicator: Control = $FocusIndicator
@onready var confirm_popup: Control = $ConfirmPopup
@onready var settings_overlay: Control = $SettingsOverlay

var buttons: Array[Button] = []

func _ready() -> void:
	buttons = []
	for child in menu_list.get_children():
		if child is Button:
			buttons.append(child)
			child.focus_entered.connect(_on_button_focused.bind(child))
	confirm_popup.confirmed.connect(_on_quit_confirmed)
	confirm_popup.cancelled.connect(_on_quit_cancelled)

	# set up keyboard/gamepad focus chain so arrow keys move between buttons
	for i in range(buttons.size()):
		buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()

	buttons[0].grab_focus()  # Freeplay selected by default, matches mockup

func _on_button_focused(button: Button) -> void:
	focus_indicator.global_position.y = button.global_position.y + (button.size.y / 2.0) - (focus_indicator.size.y / 2.0)

func _on_freeplay_button_pressed() -> void:
	SceneManager.load_gameplay(test_chart, "Solar")

func _on_multi_button_pressed() -> void:
	#print("Multi — stub, scene not built yet")
	SceneManager.load_multiplayer_lobby()

func _on_tutorial_button_pressed() -> void:
	print("Tutorial — stub, scene not built yet")

func _on_settings_button_pressed() -> void:
	SceneManager.go_to_settings()

func _on_quit_button_pressed() -> void:
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
	confirm_popup.open("Exit Encore?")
func _on_quit_confirmed() -> void:
	get_tree().quit()
func _on_quit_cancelled() -> void:
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_ALL
	buttons[4].grab_focus()

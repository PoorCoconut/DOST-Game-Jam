extends Control
class_name SettingsOverlayComponent
signal closed
signal volume_changed(slider_name: String, value: float)
signal other_value_changed(field_name: String, value: float)
signal keybind_changed(action: String, key_name: String)

# Audio sliders
@onready var scroll_speed_slider: HSlider = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Audio/Audio/ScrollSpeedRow/HSlider
@onready var scroll_speed_value: Label = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Audio/Audio/ScrollSpeedRow/ValueLabel
@onready var offset_slider: HSlider = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Audio/Audio/AudioOffsetRow/HSlider
@onready var offset_value: Label = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Audio/Audio/AudioOffsetRow/ValueLabel

@onready var master_slider: HSlider = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Volume/Volume/MasterRow/HSlider
@onready var master_value: Label = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Volume/Volume/MasterRow/ValueLabel
@onready var music_slider: HSlider = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Volume/Volume/MusicRow/HSlider
@onready var music_value: Label = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Volume/Volume/MusicRow/ValueLabel
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Volume/Volume/SFXRow/HSlider
@onready var sfx_value: Label = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Volume/Volume/SFXRow/ValueLabel

# Keybind rings
const RINGS_PATH := "Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Keybinds/Keybinds/KeybindsRings/KeybindsRings"

@onready var low_top: Button = get_node(RINGS_PATH + "/LowRing/LaneTop")
@onready var low_right: Button = get_node(RINGS_PATH + "/LowRing/LaneRight")
@onready var low_bottom: Button = get_node(RINGS_PATH + "/LowRing/LaneBottom")
@onready var low_left: Button = get_node(RINGS_PATH + "/LowRing/LaneLeft")

@onready var high_topright: Button = get_node(RINGS_PATH + "/HighRing/LaneTopRight")
@onready var high_bottomright: Button = get_node(RINGS_PATH + "/HighRing/LaneBottomRight")
@onready var high_bottomleft: Button = get_node(RINGS_PATH + "/HighRing/LaneBottomLeft")
@onready var high_topleft: Button = get_node(RINGS_PATH + "/HighRing/LaneTopLeft")

@onready var transform_button: Button = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Keybinds/Keybinds/Transform_Retry/TransformRow/RebindButton
@onready var quick_retry_button: Button = $Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/Keybinds/Keybinds/Transform_Retry/QuickRetryRow/RebindButton

var control_buttons: Dictionary = {}
var awaiting_rebind: String = "" #


func _ready() -> void:
	control_buttons = {
		"low_top": low_top,
		"low_right": low_right,
		"low_bottom": low_bottom,
		"low_left": low_left,
		"high_topright": high_topright,
		"high_bottomright": high_bottomright,
		"high_bottomleft": high_bottomleft,
		"high_topleft": high_topleft,
		"transform": transform_button,
		"quick_retry": quick_retry_button
	}

	for action in control_buttons.keys():
		var btn: Button = control_buttons[action]
		if btn:
			btn.focus_mode = Control.FOCUS_NONE # Banish spacebar click hijacking
			btn.pressed.connect(_on_rebind_pressed.bind(action))

	scroll_speed_slider.value_changed.connect(func(v): _update_percent_label(scroll_speed_value, scroll_speed_slider, v); other_value_changed.emit("scroll_speed", v))
	offset_slider.value_changed.connect(func(v): _update_percent_label(offset_value, offset_slider, v); other_value_changed.emit("audio_offset_ms", v))
	master_slider.value_changed.connect(func(v): _update_percent_label(master_value, master_slider, v); volume_changed.emit("master", v))
	music_slider.value_changed.connect(func(v): _update_percent_label(music_value, music_slider, v); volume_changed.emit("music", v))
	sfx_slider.value_changed.connect(func(v): _update_percent_label(sfx_value, sfx_slider, v); volume_changed.emit("sfx", v))

	# Wire signals to Settings autoload
	volume_changed.connect(_on_volume_changed)
	other_value_changed.connect(_on_other_value_changed)
	keybind_changed.connect(_on_keybind_changed)

	# Populate from Settings
	_load_from_settings()


func _load_from_settings() -> void:
	scroll_speed_slider.value = Settings.current_scroll_speed
	offset_slider.value = Settings.audio_offset
	master_slider.value = Settings.volume_master
	music_slider.value = Settings.volume_music
	sfx_slider.value = Settings.volume_sfx

	_update_percent_label(scroll_speed_value, scroll_speed_slider, scroll_speed_slider.value)
	_update_percent_label(offset_value, offset_slider, offset_slider.value)
	_update_percent_label(master_value, master_slider, master_slider.value)
	_update_percent_label(music_value, music_slider, music_slider.value)
	_update_percent_label(sfx_value, sfx_slider, sfx_slider.value)

	# Keybind button labels
	low_top.text    = OS.get_keycode_string(Settings.keybind_plus_lanes[0])
	low_right.text  = OS.get_keycode_string(Settings.keybind_plus_lanes[1])
	low_bottom.text = OS.get_keycode_string(Settings.keybind_plus_lanes[2])
	low_left.text   = OS.get_keycode_string(Settings.keybind_plus_lanes[3])

	high_topright.text   = OS.get_keycode_string(Settings.keybind_x_lanes[0])
	high_bottomright.text = OS.get_keycode_string(Settings.keybind_x_lanes[1])
	high_bottomleft.text = OS.get_keycode_string(Settings.keybind_x_lanes[2])
	high_topleft.text    = OS.get_keycode_string(Settings.keybind_x_lanes[3])

	transform_button.text   = OS.get_keycode_string(Settings.keybind_transform)
	quick_retry_button.text = OS.get_keycode_string(Settings.keybind_quick_retry)


# Signal handlers — write to Settings autoload
func _on_volume_changed(slider_name: String, value: float) -> void:
	match slider_name:
		"master": Settings.apply_volume_master(value)
		"music":  Settings.apply_volume_music(value)
		"sfx":    Settings.apply_volume_sfx(value)


func _on_other_value_changed(field_name: String, value: float) -> void:
	match field_name:
		"scroll_speed":    Settings.current_scroll_speed = value
		"audio_offset_ms": Settings.audio_offset = value


func _on_keybind_changed(action: String, key_name: String) -> void:
	# Convert key_name string back to keycode
	var key_code := OS.find_keycode_from_string(key_name)
	match action:
		"low_top":          Settings.set_keybind_plus_lane(0, key_code)
		"low_right":        Settings.set_keybind_plus_lane(1, key_code)
		"low_bottom":       Settings.set_keybind_plus_lane(2, key_code)
		"low_left":         Settings.set_keybind_plus_lane(3, key_code)
		"high_topright":    Settings.set_keybind_x_lane(0, key_code)
		"high_bottomright": Settings.set_keybind_x_lane(1, key_code)
		"high_bottomleft":  Settings.set_keybind_x_lane(2, key_code)
		"high_topleft":     Settings.set_keybind_x_lane(3, key_code)
		"transform":        Settings.set_keybind_transform(key_code)
		"quick_retry":      Settings.set_keybind_quick_retry(key_code)


func _update_percent_label(label: Label, slider: HSlider, value: float) -> void:
	var range_size: float = slider.max_value - slider.min_value
	var percent: float = 0.0
	if range_size > 0:
		percent = (value - slider.min_value) / range_size * 100.0
	label.text = "%d" % round(percent)


func _on_rebind_pressed(action: String) -> void:
	awaiting_rebind = action
	_set_action_button_text(action, "Press a key")


func _input(event: InputEvent) -> void:
	if awaiting_rebind == "":
		if visible and event.is_action_pressed("ui_cancel"):
			close()
		return

	if event is InputEventKey and event.pressed:
		var key_name := OS.get_keycode_string(event.keycode)
		_set_action_button_text(awaiting_rebind, key_name)
		keybind_changed.emit(awaiting_rebind, key_name)
		awaiting_rebind = ""


func _set_action_button_text(action: String, text: String) -> void:
	if control_buttons.has(action):
		control_buttons[action].text = text


func set_initial_keybind(action: String, key_name: String) -> void:
	_set_action_button_text(action, key_name)


func open() -> void:
	visible = true


func close() -> void:
	Settings.save_settings()
	visible = false
	closed.emit()
	get_tree().change_scene_to_file(SceneManager.MENU_DIR)

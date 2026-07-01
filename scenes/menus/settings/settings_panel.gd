extends Control

# ─── NODE REFS ───────────────────────────────────────────────────────────────
@onready var slider_scroll_speed : HSlider = $ScrollContainer/VBox/RowScrollSpeed/SliderScrollSpeed
@onready var label_scroll_speed  : Label   = $ScrollContainer/VBox/RowScrollSpeed/LabelScrollSpeedVal

@onready var slider_audio_offset : HSlider = $ScrollContainer/VBox/RowAudioOffset/SliderAudioOffset
@onready var label_audio_offset  : Label   = $ScrollContainer/VBox/RowAudioOffset/LabelAudioOffsetVal

@onready var slider_master : HSlider = $ScrollContainer/VBox/RowMaster/SliderMaster
@onready var label_master  : Label   = $ScrollContainer/VBox/RowMaster/LabelMasterVal

@onready var slider_music  : HSlider = $ScrollContainer/VBox/RowMusic/SliderMusic
@onready var label_music   : Label   = $ScrollContainer/VBox/RowMusic/LabelMusicVal

@onready var slider_sfx    : HSlider = $ScrollContainer/VBox/RowSFX/SliderSFX
@onready var label_sfx     : Label   = $ScrollContainer/VBox/RowSFX/LabelSFXVal

@onready var btn_plus_top    : Button = $ScrollContainer/VBox/RowPlusTop/BtnPlusTop
@onready var btn_plus_right  : Button = $ScrollContainer/VBox/RowPlusRight/BtnPlusRight
@onready var btn_plus_bottom : Button = $ScrollContainer/VBox/RowPlusBottom/BtnPlusBottom
@onready var btn_plus_left   : Button = $ScrollContainer/VBox/RowPlusLeft/BtnPlusLeft

@onready var btn_x_top    : Button = $ScrollContainer/VBox/RowXTop/BtnXTop
@onready var btn_x_right  : Button = $ScrollContainer/VBox/RowXRight/BtnXRight
@onready var btn_x_bottom : Button = $ScrollContainer/VBox/RowXBottom/BtnXBottom
@onready var btn_x_left   : Button = $ScrollContainer/VBox/RowXLeft/BtnXLeft

@onready var btn_transform   : Button = $ScrollContainer/VBox/RowTransform/BtnTransform
@onready var btn_quick_retry : Button = $ScrollContainer/VBox/RowQuickRetry/BtnQuickRetry

@onready var remap_overlay : ColorRect = $RemapOverlay
@onready var remap_label   : Label     = $RemapOverlay/RemapLabel

# ─── REMAP STATE ─────────────────────────────────────────────────────────────
enum RemapTarget { NONE, PLUS_0, PLUS_1, PLUS_2, PLUS_3, X_0, X_1, X_2, X_3, TRANSFORM, QUICK_RETRY }
var _remap_target: RemapTarget = RemapTarget.NONE
var _waiting_for_key: bool = false


# ─── READY ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	_connect_signals()
	_load_from_settings()


func _load_from_settings() -> void:
	slider_scroll_speed.value = Settings.current_scroll_speed
	slider_audio_offset.value = Settings.audio_offset
	slider_master.value       = Settings.volume_master
	slider_music.value        = Settings.volume_music
	slider_sfx.value          = Settings.volume_sfx

	label_scroll_speed.text = "%.1fx" % Settings.current_scroll_speed
	label_audio_offset.text = "%dms"  % roundi(Settings.audio_offset * 1000.0)
	label_master.text       = "%d"    % int(Settings.volume_master)
	label_music.text        = "%d"    % int(Settings.volume_music)
	label_sfx.text          = "%d"    % int(Settings.volume_sfx)

	# Keybind button labels
	btn_plus_top.text    = OS.get_keycode_string(Settings.keybind_plus_lanes[0])
	btn_plus_right.text  = OS.get_keycode_string(Settings.keybind_plus_lanes[1])
	btn_plus_bottom.text = OS.get_keycode_string(Settings.keybind_plus_lanes[2])
	btn_plus_left.text   = OS.get_keycode_string(Settings.keybind_plus_lanes[3])

	btn_x_top.text    = OS.get_keycode_string(Settings.keybind_x_lanes[0])
	btn_x_right.text  = OS.get_keycode_string(Settings.keybind_x_lanes[1])
	btn_x_bottom.text = OS.get_keycode_string(Settings.keybind_x_lanes[2])
	btn_x_left.text   = OS.get_keycode_string(Settings.keybind_x_lanes[3])

	btn_transform.text   = OS.get_keycode_string(Settings.keybind_transform)
	btn_quick_retry.text = OS.get_keycode_string(Settings.keybind_quick_retry)


func _connect_signals() -> void:
	slider_scroll_speed.value_changed.connect(_on_scroll_speed_changed)
	slider_audio_offset.value_changed.connect(_on_audio_offset_changed)
	slider_master.value_changed.connect(_on_master_changed)
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)

	btn_plus_top.pressed.connect(func(): _start_remap(RemapTarget.PLUS_0))
	btn_plus_right.pressed.connect(func(): _start_remap(RemapTarget.PLUS_1))
	btn_plus_bottom.pressed.connect(func(): _start_remap(RemapTarget.PLUS_2))
	btn_plus_left.pressed.connect(func(): _start_remap(RemapTarget.PLUS_3))

	btn_x_top.pressed.connect(func(): _start_remap(RemapTarget.X_0))
	btn_x_right.pressed.connect(func(): _start_remap(RemapTarget.X_1))
	btn_x_bottom.pressed.connect(func(): _start_remap(RemapTarget.X_2))
	btn_x_left.pressed.connect(func(): _start_remap(RemapTarget.X_3))

	btn_transform.pressed.connect(func(): _start_remap(RemapTarget.TRANSFORM))
	btn_quick_retry.pressed.connect(func(): _start_remap(RemapTarget.QUICK_RETRY))

	$ScrollContainer/VBox/RowButtons/BtnSave.pressed.connect(_on_save_pressed)
	$ScrollContainer/VBox/RowButtons/BtnDiscard.pressed.connect(_on_discard_pressed)


func _on_scroll_speed_changed(value: float) -> void:
	Settings.current_scroll_speed = value
	label_scroll_speed.text = "%.1fx" % value

func _on_audio_offset_changed(value: float) -> void:
	Settings.audio_offset = value
	label_audio_offset.text = "%dms" % roundi(value * 1000.0)

func _on_master_changed(value: float) -> void:
	Settings.apply_volume_master(value)
	label_master.text = "%d" % int(value)

func _on_music_changed(value: float) -> void:
	Settings.apply_volume_music(value)
	label_music.text = "%d" % int(value)

func _on_sfx_changed(value: float) -> void:
	Settings.apply_volume_sfx(value)
	label_sfx.text = "%d" % int(value)


func _start_remap(target: RemapTarget) -> void:
	_remap_target = target
	_waiting_for_key = false
	remap_overlay.visible = true
	remap_label.text = "Press any key...\n(Escape to cancel)"
	await get_tree().process_frame
	_waiting_for_key = true


func _input(event: InputEvent) -> void:
	if _remap_target == RemapTarget.NONE or not _waiting_for_key:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	get_viewport().set_input_as_handled()

	if event.keycode == KEY_ESCAPE:
		_cancel_remap()
		return

	_apply_remap(event.keycode)


func _apply_remap(key_code: int) -> void:
	var key_name := OS.get_keycode_string(key_code)

	match _remap_target:
		RemapTarget.PLUS_0:
			Settings.set_keybind_plus_lane(0, key_code)
			btn_plus_top.text = key_name
		RemapTarget.PLUS_1:
			Settings.set_keybind_plus_lane(1, key_code)
			btn_plus_right.text = key_name
		RemapTarget.PLUS_2:
			Settings.set_keybind_plus_lane(2, key_code)
			btn_plus_bottom.text = key_name
		RemapTarget.PLUS_3:
			Settings.set_keybind_plus_lane(3, key_code)
			btn_plus_left.text = key_name
		RemapTarget.X_0:
			Settings.set_keybind_x_lane(0, key_code)
			btn_x_top.text = key_name
		RemapTarget.X_1:
			Settings.set_keybind_x_lane(1, key_code)
			btn_x_right.text = key_name
		RemapTarget.X_2:
			Settings.set_keybind_x_lane(2, key_code)
			btn_x_bottom.text = key_name
		RemapTarget.X_3:
			Settings.set_keybind_x_lane(3, key_code)
			btn_x_left.text = key_name
		RemapTarget.TRANSFORM:
			Settings.set_keybind_transform(key_code)
			btn_transform.text = key_name
		RemapTarget.QUICK_RETRY:
			Settings.set_keybind_quick_retry(key_code)
			btn_quick_retry.text = key_name

	_cancel_remap()


func _cancel_remap() -> void:
	_remap_target = RemapTarget.NONE
	_waiting_for_key = false
	remap_overlay.visible = false


# ─── SAVE / DISCARD / BACK ───────────────────────────────────────────────────
func _on_save_pressed() -> void:
	Settings.save_settings()
	get_tree().change_scene_to_file(SceneManager.MENU_DIR)

func _on_discard_pressed() -> void:
	Settings.load_settings()
	Settings._apply_all()
	get_tree().change_scene_to_file(SceneManager.MENU_DIR)

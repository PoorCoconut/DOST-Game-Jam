extends Control
class_name UIHeaderComponent

signal back_pressed
signal settings_pressed
signal volume_pressed
signal skills_toggled(is_open: bool)
signal mods_toggled(is_open: bool)
signal profile_toggled(is_open: bool)

# Profile Card component reference matching your scene architecture
@onready var profile_card: ProfileCardComponent = $HBoxContainer/LeftProfileSection/ProfileCard
@onready var skills_btn: Button = $HBoxContainer/LeftProfileSection/SkillsTabButton
@onready var mods_btn: Button = $HBoxContainer/LeftProfileSection/ModsTabButton
@onready var active_mods_row: HBoxContainer = $HBoxContainer/LeftProfileSection/ActiveModsRow

# Individual modifier badge textures inside your LeftProfileSection tracker row
@onready var mod_fl: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModFL
@onready var mod_fs: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModFS
@onready var mod_dt: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModDT
@onready var mod_hr: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModHR

func _ready() -> void:
	_clear_modifier_strip()
	
	profile_card.profile_clicked.connect(_on_profile_card_clicked)
	skills_btn.toggled.connect(_on_skills_tab_toggled)
	mods_btn.toggled.connect(_on_mods_tab_toggled)
	
	# Emits the back_pressed signal outwards when the button is hit
	$HBoxContainer/LeftProfileSection/MarginContainer/BackButton.pressed.connect(func(): back_pressed.emit())
	$HBoxContainer/RightControlsSection/SettingsButton.pressed.connect(func(): settings_pressed.emit())
	$HBoxContainer/RightControlsSection/VolumeButton.pressed.connect(func(): volume_pressed.emit())

func update_active_modifiers(activated_mods: Dictionary) -> void:
	if activated_mods.has("FL"): mod_fl.visible = activated_mods["FL"]
	if activated_mods.has("FS"): mod_fs.visible = activated_mods["FS"]
	if activated_mods.has("DT"): mod_dt.visible = activated_mods["DT"]
	if activated_mods.has("HR"): mod_hr.visible = activated_mods["HR"]

func _clear_modifier_strip() -> void:
	mod_fl.visible = false
	mod_fs.visible = false
	mod_dt.visible = false
	mod_hr.visible = false

func _on_profile_card_clicked(is_open: bool) -> void:
	if is_open:
		skills_btn.set_pressed_no_signal(false)
		mods_btn.set_pressed_no_signal(false)
		skills_toggled.emit(false)
		mods_toggled.emit(false)
	profile_toggled.emit(is_open)

func _on_skills_tab_toggled(button_pressed: bool) -> void:
	if button_pressed:
		profile_card.set_dropdown_state_no_signal(false)
		mods_btn.set_pressed_no_signal(false)
		mods_toggled.emit(false)
		profile_toggled.emit(false)
	skills_toggled.emit(button_pressed)

func _on_mods_tab_toggled(button_pressed: bool) -> void:
	if button_pressed:
		profile_card.set_dropdown_state_no_signal(false)
		skills_btn.set_pressed_no_signal(false)
		skills_toggled.emit(false)
		profile_toggled.emit(false)
	mods_toggled.emit(button_pressed)

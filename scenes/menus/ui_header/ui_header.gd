extends Control
class_name UIHeaderComponent

signal gameplay_mods_changed(new_mods: Dictionary)
signal character_skill_changed(new_skill_name: String)
signal settings_pressed
signal volume_pressed

@onready var profile_card: ProfileCardComponent = $HBoxContainer/LeftProfileSection/ProfileCard
@onready var skills_btn: Button = $HBoxContainer/LeftProfileSection/SkillsTabButton
@onready var mods_btn: Button = $HBoxContainer/LeftProfileSection/ModsTabButton
@onready var active_mods_row: HBoxContainer = $HBoxContainer/LeftProfileSection/ActiveModsRow

@onready var mod_fl: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModFL
@onready var mod_fs: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModFS
@onready var mod_dt: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModDT
@onready var mod_hr: TextureRect = $HBoxContainer/LeftProfileSection/ActiveModsRow/ModHR

# Managed by the Main Scene Traffic Controller
var mods_overlay: ModsOverlayComponent
var skills_overlay: SkillsOverlayComponent
var profile_dropdown: ProfileDropdownOverlayComponent
var profile_input_modal: ProfileInputModalComponent
var settings_overlay: SettingsOverlayComponent

var original_btn_y: float = 0.0
var active_extended_button: Button = null
var mods_button_original_height: float = 0.0
var is_mods_button_extended: bool = false

var skills_button_original_height: float = 0.0
var is_skills_button_extended: bool = false

const ELEMENT_DATA = {
	"Radiance": {"name": "Radiance", "element": "SOLAR", "color": "#f1c40f", "icon": "res://assets/backgrounds/test.jpg"},
	"Transience": {"name": "Transience", "element": "HYDRO", "color": "#3498db", "icon": "res://assets/backgrounds/test.jpg"},
	"Prominence": {"name": "Prominence", "element": "WIND", "color": "#2ecc71", "icon": "res://assets/backgrounds/test.jpg"},
	"Convergence": {"name": "Convergence", "element": "GEO", "color": "#e67e22", "icon": "res://assets/backgrounds/test.jpg"}
}

func _ready() -> void:
	_clear_modifier_strip()
	
	# Clean guard connections to avoid duplicate listener exceptions
	if not profile_card.profile_clicked.is_connected(_on_profile_card_clicked):
		profile_card.profile_clicked.connect(_on_profile_card_clicked)
	if not skills_btn.toggled.is_connected(_on_skills_tab_toggled):
		skills_btn.toggled.connect(_on_skills_tab_toggled)
	if not mods_btn.toggled.is_connected(_on_mods_tab_toggled):
		mods_btn.toggled.connect(_on_mods_tab_toggled)
	var settings_btn = $HBoxContainer/RightControlsSection/SettingsButton
	if not settings_btn.pressed.is_connected(_on_settings_button_pressed):
		settings_btn.pressed.connect(_on_settings_button_pressed)
	
	call_deferred("_update_skill_card_display", "Radiance")
	call_deferred("_connect_overlays_runtime")

func _connect_overlays_runtime() -> void:
	if mods_overlay and not mods_overlay.mods_applied.is_connected(_on_mods_overlay_closed):
		mods_overlay.mods_applied.connect(_on_mods_overlay_closed)
	if skills_overlay and not skills_overlay.skill_applied.is_connected(_on_skills_overlay_closed):
		skills_overlay.skill_applied.connect(_on_skills_overlay_closed)
	if profile_dropdown and not profile_dropdown.edit_profile_requested.is_connected(_on_edit_profile_triggered):
		profile_dropdown.edit_profile_requested.connect(_on_edit_profile_triggered)
	if profile_input_modal and not profile_input_modal.change_confirmed.is_connected(_on_profile_saved):
		profile_input_modal.change_confirmed.connect(_on_profile_saved)
	if settings_overlay and not settings_overlay.closed.is_connected(_on_settings_overlay_closed):
		settings_overlay.closed.connect(_on_settings_overlay_closed)

# --- CLEAN TAB ANIMATIONS ---

func _animate_tab_extension(target_button: Button) -> void:
	if active_extended_button and active_extended_button != target_button:
		_retract_active_tab()
		
	active_extended_button = target_button
	original_btn_y = target_button.position.y
	
	# Adjusting position.y downwards allows the tab background to integrate perfectly with the menu box
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target_button, "position:y", original_btn_y + 12.0, 0.15)

func _retract_active_tab() -> void:
	if active_extended_button:
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(active_extended_button, "position:y", original_btn_y, 0.12)
		active_extended_button.set_pressed_no_signal(false)
		active_extended_button = null

# --- EMITTED INTERACTION PROCESSING ---

func _on_profile_card_clicked(is_open: bool) -> void:
	if is_open:
		_retract_active_tab()
		skills_btn.set_pressed_no_signal(false)
		mods_btn.set_pressed_no_signal(false)
		
		if profile_dropdown:
			var target_pos = profile_card.global_position
			target_pos.y += profile_card.size.y - 10
			profile_dropdown.global_position = target_pos
			profile_dropdown.custom_minimum_size.x = profile_card.size.x
			profile_dropdown.size.x = profile_card.size.x
			
	if profile_dropdown:
		profile_dropdown.toggle_dropdown(is_open)

# --- SKILLS TAB LOOP ---

func _on_skills_tab_toggled(is_pressed: bool) -> void:
	if is_pressed:
		# Shut off mods tab if open
		mods_btn.set_pressed_no_signal(false)
		if is_mods_button_extended:
			_force_retract_mods_tab()
			
		if profile_card.is_dropdown_open:
			profile_card.set_dropdown_state_no_signal(false)
			if profile_dropdown: profile_dropdown.toggle_dropdown(false)
		
		# Record and force-stretch size:y down blindly
		if not is_skills_button_extended:
			skills_button_original_height = skills_btn.size.y
			
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(skills_btn, "size:y", skills_button_original_height + 44.0, 0.15)
		is_skills_button_extended = true
		
		tween.tween_callback(func():
			if skills_overlay:
				var raw_skill = "Radiance"
				if profile_card.energy_label and not profile_card.energy_label.text.is_empty():
					raw_skill = profile_card.energy_label.text
				skills_overlay.open_overlay(raw_skill)
		)
	else:
		if is_skills_button_extended:
			_force_retract_skills_tab()

func _on_skills_overlay_closed(selected_skill: String) -> void:
	# --- RESET THE TAB SIZE EXTENSION HERE ON ACCEPT ---
	_force_retract_skills_tab()
	_update_skill_card_display(selected_skill)
	character_skill_changed.emit(selected_skill)

func _force_retract_skills_tab() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(skills_btn, "size:y", skills_button_original_height, 0.15)
	is_skills_button_extended = false
	skills_btn.set_pressed_no_signal(false)

# --- MODS TAB LOOP ---

func _on_mods_tab_toggled(is_pressed: bool) -> void:
	if is_pressed:
		# Shut off skills tab if open
		skills_btn.set_pressed_no_signal(false)
		if is_skills_button_extended:
			_force_retract_skills_tab()
			
		if profile_card.is_dropdown_open:
			profile_card.set_dropdown_state_no_signal(false)
			if profile_dropdown: profile_dropdown.toggle_dropdown(false)
		
		# Record and force-stretch size:y down blindly
		if not is_mods_button_extended:
			mods_button_original_height = mods_btn.size.y
			
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(mods_btn, "size:y", mods_button_original_height + 44.0, 0.15)
		is_mods_button_extended = true
		
		tween.tween_callback(func():
			if mods_overlay:
				mods_overlay.open_overlay(owner.active_gameplay_mods if owner else {})
		)
	else:
		if is_mods_button_extended:
			_force_retract_mods_tab()

func _on_mods_overlay_closed(confirmed_mods: Dictionary) -> void:
	# --- RESET THE TAB SIZE EXTENSION HERE ON ACCEPT ---
	_force_retract_mods_tab()
	update_active_modifiers(confirmed_mods)
	gameplay_mods_changed.emit(confirmed_mods)

func _force_retract_mods_tab() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mods_btn, "size:y", mods_button_original_height, 0.15)
	is_mods_button_extended = false
	mods_btn.set_pressed_no_signal(false)

func _on_edit_profile_triggered() -> void:
	if profile_card: profile_card.set_dropdown_state_no_signal(false)
	if profile_dropdown: profile_dropdown.toggle_dropdown(false)
	if profile_input_modal:
		var current_username = profile_card.username_label.text if profile_card.username_label.text else "asterialumi"
		profile_input_modal.open_modal(current_username, profile_card.avatar_texture.texture)

func _on_profile_saved(new_username: String, new_avatar: Texture2D) -> void:
	if profile_card:
		if profile_card.username_label: profile_card.username_label.text = new_username
		if profile_card.avatar_texture: profile_card.avatar_texture.texture = new_avatar

func _update_skill_card_display(skill_name: String) -> void:
	if ELEMENT_DATA.has(skill_name):
		var data = ELEMENT_DATA[skill_name]
		var theme_color := Color(data["color"])
		var icon_tex: Texture2D = null
		if ResourceLoader.exists(data["icon"]):
			icon_tex = load(data["icon"])
		if profile_card:
			profile_card.update_skill_display(data["name"], data["element"], theme_color, icon_tex)

func update_active_modifiers(activated_mods: Dictionary) -> void:
	if mod_fl: mod_fl.visible = activated_mods.get("FL", false)
	if mod_fs: mod_fs.visible = activated_mods.get("FS", false)
	if mod_dt: mod_dt.visible = activated_mods.get("DT", false)
	if mod_hr: mod_hr.visible = activated_mods.get("HR", false)

func _clear_modifier_strip() -> void:
	update_active_modifiers({})

func _on_back_button_pressed() -> void:
	print("Back Button pressed")
	#SceneManager.change_scene("res://scenes/menus/main_menu/main_menu.tscn")


func _on_settings_button_pressed() -> void:
	print("[UI_HEADER] Settings button activated. Clearing active workspace panels...")
	
	# Clear out any hanging active workspace cards or open tabs first [cite: 22, 23]
	if is_skills_button_extended:
		_force_retract_skills_tab()
	if is_mods_button_extended:
		_force_retract_mods_tab()
		
	if profile_card.is_dropdown_open:
		profile_card.set_dropdown_state_no_signal(false)
		if profile_dropdown: 
			profile_dropdown.toggle_dropdown(false)
			
	if settings_overlay:
		settings_overlay.open() # Calls your component open loop method cleanly [cite: 19]
		settings_pressed.emit() # Notify the main scene state engine just in case 

func _on_settings_overlay_closed() -> void:
	print("[UI_HEADER] Settings configuration saved and closed.")
	# Add any extra UI refocusing code here if needed when returning to selection

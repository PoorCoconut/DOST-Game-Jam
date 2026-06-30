extends Control
class_name ProfileInputModalComponent

signal change_confirmed(new_username: String, new_avatar_texture: Texture2D)
signal change_canceled

@onready var username_edit: LineEdit = $ModalFrame/MarginContainer/VBoxContainer/HBoxContainer/InputFieldVBox/UsernameLineEdit
@onready var avatar_preview: TextureRect = $ModalFrame/MarginContainer/VBoxContainer/HBoxContainer/AvatarEditWrapper/AvatarTexture
@onready var change_avatar_btn: TextureButton = $ModalFrame/MarginContainer/VBoxContainer/HBoxContainer/AvatarEditWrapper/ChangeAvatarButton
@onready var file_dialog: FileDialog = $AvatarFileDialog

@onready var save_btn: Button = $ModalFrame/MarginContainer/VBoxContainer/ButtonHBox/SaveButton
@onready var cancel_btn: Button = $ModalFrame/MarginContainer/VBoxContainer/ButtonHBox/CancelButton

var current_selected_texture: Texture2D

func _ready() -> void:
	visible = false
	
	cancel_btn.pressed.connect(_on_cancel_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	username_edit.text_submitted.connect(func(_text): _on_save_pressed())
	
	# Wire up file dialog triggers
	change_avatar_btn.pressed.connect(_on_change_avatar_pressed)
	change_avatar_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	file_dialog.file_selected.connect(_on_avatar_file_selected)

func open_modal(current_username: String, current_texture: Texture2D) -> void:
	username_edit.text = current_username
	current_selected_texture = current_texture
	avatar_preview.texture = current_texture
	
	visible = true
	username_edit.grab_focus()
	username_edit.select_all()

func _on_change_avatar_pressed() -> void:
	# Pops up the system file dialog explorer overlay frame cleanly
	file_dialog.popup_centered_clamped(Vector2i(700, 500))

func _on_avatar_file_selected(path: String) -> void:
	# Load image file path from disk arrays safely
	var img := Image.load_from_file(path)
	if img:
		var tex := ImageTexture.create_from_image(img)
		current_selected_texture = tex
		avatar_preview.texture = tex # Instantly runs circle shader calculations natively!

func _on_save_pressed() -> void:
	var clean_text := username_edit.text.strip_edges()
	if clean_text.is_empty():
		return
		
	change_confirmed.emit(clean_text, current_selected_texture)
	_close()

func _on_cancel_pressed() -> void:
	change_canceled.emit()
	_close()

func _close() -> void:
	visible = false
	username_edit.release_focus()

extends Control

signal confirmed
signal cancelled

@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel
@onready var confirm_button: Button = $Panel/VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $Panel/VBoxContainer/HBoxContainer/CancelButton

func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func open(message: String) -> void:
	message_label.text = message
	visible = true
	confirm_button.grab_focus()

func _on_confirm_pressed() -> void:
	visible = false
	confirmed.emit()

func _on_cancel_pressed() -> void:
	visible = false
	cancelled.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):  # Esc — treat like Cancel
		_on_cancel_pressed()

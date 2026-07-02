extends Control
class_name ResultsMenuController

@onready var ui_header : UIHeaderComponent = $UIHeader

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ui_header._hide_skills_mods_buttons()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

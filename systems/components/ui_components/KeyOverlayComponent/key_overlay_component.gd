extends Node2D
class_name KeyOverlayComponent

@export var panel_up_target_color : Color = Color(1.0, 0.0, 0.0, 0.6)
@export var panel_left_target_color : Color = Color(0.0, 1.0, 0.0, 0.6)
@export var panel_down_target_color : Color = Color(0.0, 0.0, 1.0, 0.6)
@export var panel_right_target_color : Color = Color(1.0, 1.0, 0.0, 0.6)

@export var panel_base_color : Color = Color(0.1015625, 0.1015625, 0.1015625, 0.6)

@export var color_duration : float = 0.1

@onready var panel_up: PanelContainer = %Panel_Up
@onready var panel_left: PanelContainer = %Panel_Left
@onready var panel_down: PanelContainer = %Panel_Down
@onready var panel_right: PanelContainer = %Panel_Right

@onready var count_up: Label = %Count_Up
@onready var count_left: Label = %Count_Left
@onready var count_down: Label = %Count_Down
@onready var count_right: Label = %Count_Right

func _ready() -> void:
	var up_panel_style = panel_up.get_theme_stylebox("panel") as StyleBoxFlat
	var left_panel_style = panel_left.get_theme_stylebox("panel") as StyleBoxFlat
	var right_panel_style = panel_right.get_theme_stylebox("panel") as StyleBoxFlat
	var down_panel_style = panel_down.get_theme_stylebox("panel") as StyleBoxFlat
	up_panel_style.bg_color = panel_base_color
	left_panel_style.bg_color = panel_base_color
	right_panel_style.bg_color = panel_base_color
	down_panel_style.bg_color = panel_base_color

#Glow effect when pressing buttons
func _input(_event: InputEvent) -> void:
	var up_panel_style = panel_up.get_theme_stylebox("panel") as StyleBoxFlat
	var right_panel_style = panel_right.get_theme_stylebox("panel") as StyleBoxFlat
	var down_panel_style = panel_down.get_theme_stylebox("panel") as StyleBoxFlat
	var left_panel_style = panel_left.get_theme_stylebox("panel") as StyleBoxFlat
	
	var up_tween = get_tree().create_tween()
	var left_tween = get_tree().create_tween()
	var right_tween = get_tree().create_tween()
	var down_tween = get_tree().create_tween()
	
	# W LANE
	if Input.is_action_pressed("lane1"):
		up_tween.tween_property(up_panel_style,"bg_color", panel_up_target_color, color_duration)
	else:
		up_tween.tween_property(up_panel_style,"bg_color", panel_base_color, color_duration)
	
	# D LANE
	if Input.is_action_pressed("lane2"): #D
		right_tween.tween_property(right_panel_style,"bg_color", panel_right_target_color, color_duration)
	else:
		right_tween.tween_property(right_panel_style,"bg_color", panel_base_color, color_duration)
	
	# S LANE
	if Input.is_action_pressed("lane3"): #S
		down_tween.tween_property(down_panel_style,"bg_color", panel_down_target_color, color_duration)
	else:
		down_tween.tween_property(down_panel_style,"bg_color", panel_base_color, color_duration)
	
	# A LANE
	if Input.is_action_pressed("lane4"): #A
		left_tween.tween_property(left_panel_style,"bg_color", panel_left_target_color, color_duration)
	else:
		left_tween.tween_property(left_panel_style,"bg_color", panel_base_color, color_duration)

#Adds a point to the label thingy of each score
func add_score(orientation : String):
	if orientation == "up":
		count_up.text = str(int(count_up.text) + 1)
	elif orientation == "left":
		count_left.text = str(int(count_left.text) + 1)
	elif orientation == " down":
		count_down.text = str(int(count_down.text) + 1)
	elif orientation == "right":
		count_right.text = str(int(count_right.text) + 1)
	else:
		printerr(orientation + " is not a set orientation!")

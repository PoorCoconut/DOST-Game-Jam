extends Node2D
@onready var quad1: Sprite2D = $Ring/Quadrant1
@onready var quad2: Sprite2D = $Ring/Quadrant2
@onready var quad3: Sprite2D = $Ring/Quadrant3
@onready var quad4: Sprite2D = $Ring/Quadrant4
@onready var judgement_ring: Sprite2D = $Ring/JudgementRing
@onready var ring: Node2D = $Ring
@onready var energy_source: Sprite2D = $EnergySource

#Sustain Meters
#Simple
@onready var simple_solar: TextureProgressBar = $ControlCenter/SimpleSustainMeters/SimpleSolar
@onready var simple_geo: TextureProgressBar = $ControlCenter/SimpleSustainMeters/SimpleGeo
@onready var simple_hydro: TextureProgressBar = $ControlCenter/SimpleSustainMeters/SimpleHydro
@onready var simple_wind: TextureProgressBar = $ControlCenter/SimpleSustainMeters/SimpleWind

#Complex
@onready var complex_solar: TextureProgressBar = $ControlCenter/ComplexSustainMeters/ComplexSolar
@onready var complex_geo: TextureProgressBar = $ControlCenter/ComplexSustainMeters/ComplexGeo
@onready var complex_hydro: TextureProgressBar = $ControlCenter/ComplexSustainMeters/ComplexHydro
@onready var complex_wind: TextureProgressBar = $ControlCenter/ComplexSustainMeters/ComplexWind


@export_category("Quadrant Colors")
@export var quadrant1_color : Color = Color(1, 1, 1, 1)
@export var quadrant2_color : Color = Color(1, 1, 1, 1)
@export var quadrant3_color : Color = Color(1, 1, 1, 1)
@export var quadrant4_color : Color = Color(1, 1, 1, 1)
##The higher the number, the faster the speed
@export var fade_speed : float = 10.0  

@export_category("Transform")
##How many seconds for the 45 degree turn
@export var rotate_speed : float = 0.4  

var is_rotated: bool = false
var is_rotating: bool = false
var base_rotation: float = 45.0 #This is kind of a constant number. Changes on this isn't really recommended.
var quad_colors: Array[Color] = []
var quads: Array[Sprite2D] = []
var lane_actions := ["lane2", "lane3", "lane4", "lane1"]

func _ready() -> void:
	quads = [quad1, quad2, quad3, quad4]
	quad_colors = [quadrant1_color, quadrant2_color, quadrant3_color, quadrant4_color]
	for i in quads.size():
		var c : Color = quad_colors[i]
		c.a = 0.0 #Set the stuff to invisible
		quads[i].modulate = c #Set the color of the quadrants
	base_rotation = ring.rotation_degrees

func _process(delta: float) -> void:
	for i in quads.size():
		var target_alpha : float
		if Input.is_action_pressed(lane_actions[i]):
			target_alpha = 1.0
		else:
			target_alpha = 0.0
		var c : Color = quads[i].modulate
		c.a = lerp(c.a, target_alpha, fade_speed * delta)
		quads[i].modulate = c

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("transform") and not is_rotating:
		_rotate_ring()

#Magic
func _rotate_ring() -> void:
	is_rotating = true
	is_rotated = !is_rotated
	var target := base_rotation + 45.0 if is_rotated else base_rotation
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ring, "rotation_degrees", target, rotate_speed)
	tween.finished.connect(func(): is_rotating = false)

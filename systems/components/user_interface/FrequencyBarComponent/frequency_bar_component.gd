extends Node2D
class_name FrequencyBarComponent

@export_category("DEBUG SETTINGS")
@export var MAX_HP : float = 100.0
@export var CUR_HP : float = 100.0

@export_category("FREQUENCY SETTINGS")
@export var amplitude: float = 20.0 ##How high the wave is.
@export var frequency: float = 6 ##The frequency of the waves.
@export var length: float = 350.0 ##The length of the wave [horizontal]
@export var resolution: int = 100  ##Resolution of the entire wave.
@export var speed : float = 6.0 ##Controls the animation speed
@export var lerp_speed : float = 5.0 ##Controls how fast hp_ratio catches up to target_ratio

var phase: float = 0.1
var hp_ratio: float = 1.0  #Made by CUR_HP / MAX_HP. 1 is full health, 0 is no health
#^^^ Note that hp_ratio controls many aspects of the wave. The Speed as well as the frequency!
var target_ratio: float = 1.0  #hp_ratio lerps toward this. Set this when HP changes.
@onready var frequency_line: Line2D = %Frequency

func _ready():
	print("[STATS] HP: ", CUR_HP, " / ", MAX_HP)
	_redraw()

#Example [very simple] hp setter
func set_hp(current: float, max_hp: float = MAX_HP) -> void:
	if current <= 0:
		CUR_HP = 0
	else: CUR_HP = current
	MAX_HP = max_hp
	target_ratio = clamp(CUR_HP / MAX_HP, 0.0, 1.0)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		CUR_HP -= 5
		set_hp(CUR_HP - 5)
		print("[STATS] HP: ",CUR_HP, " / ", MAX_HP)

func _process(delta: float) -> void:
	hp_ratio = lerp(hp_ratio, target_ratio, delta * lerp_speed) #Changes the hp ratio with an interpolation
	phase += delta * (speed * hp_ratio) #Animation speed scales with hp!
	_redraw()

func _redraw() -> void:
	frequency_line.clear_points()
	var new_freq = frequency * hp_ratio  #Frequency also scales with hp!
	for i in range(resolution + 1):
		var x = (float(i) / resolution) * length
		var y = sin((x / length) * TAU * new_freq + phase) * amplitude
		frequency_line.add_point(Vector2(x, y))

extends Control
class_name AudioVisualizerComponent
#TODO REMOVE THE TestMusic node, and currently lines 14, 51-55. They are just debugs!

@onready var audio_spectrum : AudioEffectInstance = AudioServer.get_bus_effect_instance(1,0)
@onready var bars_array_down : Array = %BarContainerDown.get_children()
@onready var bars_array_up : Array = %BarContainerUp.get_children()

@onready var bars_up: MarginContainer = $BarsUp
@onready var bars_down: MarginContainer = $BarsDown
@onready var bar_container_up: HBoxContainer = %BarContainerUp
@onready var bar_container_down: HBoxContainer = %BarContainerDown

@onready var test_music: AudioStreamPlayer2D = $TestMusic

@export_category("General Settings")
##Controls whether both the upper and/or lower bars are seen.
@export_enum("Show Both", "Show Only Up", "Show Only Down") var bar_orientation : String = "Show Both"

##The Lower the step scale, the slower the bars move
@export var step_scale : float = 0.1

@export_category("Gradient")
@export var bar_gradient : Gradient

@export_category("Bar Settings")
@export var HEIGHT_LOWER_BAR : float = 1200.0
@export var HEIGHT_UPPER_BAR : float = 1200.0
@export var upper_bar_separation : int = 10
@export var lower_bar_separation : int = 10
@export var reverse_upper_bar : bool = false
@export var reverse_lower_bar : bool = false
const BAR_COUNT = 12
const MAX_FREQ = 11050.0 #Standard Cap
const MIN_DB = 60 #Also another standard cap

func _ready():
	_set_settings()
	
	for i in range(1,BAR_COUNT+1):
		var bar_up = bars_array_up[i-1]
		var bar_down = bars_array_down[i-1]
		
		#Gradient
		var ratio : float = float(i) / float(BAR_COUNT - 1)
		var sample_color := _get_gradient_color(ratio)
		bar_up.color = sample_color
		bar_down.color = sample_color

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		if test_music.playing == true:
			test_music.stop()
		else: 
			test_music.play()
	
	var prev_hz = 0
	for i in range(1,BAR_COUNT+1):   
		
		#Bar Movement
		var hz = i * MAX_FREQ / BAR_COUNT;
		var frq = audio_spectrum.get_magnitude_for_frequency_range(prev_hz,hz)
		var energy = clamp((MIN_DB + linear_to_db(frq.length()))/MIN_DB,0,1)
		var height_up = energy * HEIGHT_UPPER_BAR
		var height_low = energy * HEIGHT_LOWER_BAR
		prev_hz = hz
		
		var bar_up = bars_array_up[i-1]
		var bar_down = bars_array_down[i-1]
		
		bar_up.custom_minimum_size = Vector2(bar_up.custom_minimum_size.x, lerp(bar_up.custom_minimum_size.y, height_up, step_scale))
		bar_down.custom_minimum_size = Vector2(bar_down.custom_minimum_size.x, lerp(bar_down.custom_minimum_size.y, height_low, step_scale))

func _get_gradient_color(pos : float) -> Color:
	if bar_gradient:
		return bar_gradient.sample(pos)
	#print("No gradient given. Switching to default White.")
	return Color.WHITE #White shalt be the default color

func _set_settings() -> void:
	#Bar Orientation Settings
	match bar_orientation:
		"Show Both":
			bars_down.visible = true
			bars_up.visible = true
		"Show Only Up":
			bars_down.visible = false
			bars_up.visible = true
		"Show Only Down":
			bars_down.visible = true
			bars_up.visible = false
	
	#Upper / Lower Bar Separation Settings
	bars_up.add_theme_constant_override("margin_left", upper_bar_separation)
	bars_up.add_theme_constant_override("margin_right", upper_bar_separation)
	bar_container_up.add_theme_constant_override("separation", upper_bar_separation)
	
	bars_down.add_theme_constant_override("margin_left", lower_bar_separation)
	bars_down.add_theme_constant_override("margin_right", lower_bar_separation)
	bar_container_down.add_theme_constant_override("separation", lower_bar_separation)
	
	#Bar Reversal Settings
	if reverse_lower_bar:
		bars_array_down.reverse()
	if reverse_upper_bar:
		bars_array_up.reverse()

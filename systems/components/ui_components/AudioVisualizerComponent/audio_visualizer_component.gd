extends Control
class_name AudioVisualizerComponent
#TODO REMOVE THE TestMusic node.

@onready var audio_spectrum : AudioEffectInstance = AudioServer.get_bus_effect_instance(1,0)
@onready var bars_array_down : Array = %BarContainerDown.get_children()
@onready var bars_array_up : Array = %BarContainerUp.get_children()
@onready var bars_array_right : Array = %BarContainerRight.get_children()
@onready var bars_array_left : Array = %BarContainerLeft.get_children()

@onready var bars_up: MarginContainer = $BarsUp
@onready var bars_down: MarginContainer = $BarsDown
@onready var bars_right: MarginContainer = $BarsRight
@onready var bars_left: MarginContainer = $BarsLeft

@onready var bar_container_up: HBoxContainer = %BarContainerUp
@onready var bar_container_down: HBoxContainer = %BarContainerDown
@onready var bar_container_right: HBoxContainer = %BarContainerRight
@onready var bar_container_left: HBoxContainer = %BarContainerLeft

##DEBUG DEBUG DEBUG!
@onready var test_music: AudioStreamPlayer2D = $TestMusic

@export_category("General Settings")
#Controls which portion of the screen the bars will be shown.
@export var show_up_bar : bool = true
@export var show_down_bar : bool = true
@export var show_left_bar : bool = false
@export var show_right_bar : bool = false

##The Lower the step scale, the slower the bars move
@export var step_scale : float = 0.1

@export_category("Gradient")
@export var bar_gradient : Gradient

@export_category("Bar Settings")
@export var HEIGHT_LOWER_BAR : float = 1200.0
@export var HEIGHT_UPPER_BAR : float = 1200.0
@export var HEIGHT_RIGHT_BAR : float = 1200.0
@export var HEIGHT_LEFT_BAR : float = 1200.0

@export var upper_bar_separation : int = 10
@export var lower_bar_separation : int = 10
@export var right_bar_separation : int = 10
@export var left_bar_separation : int = 10

@export var reverse_upper_bar : bool = false
@export var reverse_lower_bar : bool = false
@export var reverse_right_bar : bool = false
@export var reverse_left_bar : bool = false

const BAR_COUNT = 12
const MAX_FREQ = 11050.0 #Standard Cap
const MIN_DB = 60 #Also another standard cap

var music_playing : bool = false

func _ready():
	_set_settings()
	
	for i in range(1,BAR_COUNT+1):
		var bar_up = bars_array_up[i-1]
		var bar_down = bars_array_down[i-1]
		var bar_right = bars_array_right[i-1]
		var bar_left = bars_array_left[i-1]
		
		#Gradient
		var ratio : float = float(i) / float(BAR_COUNT - 1)
		var sample_color := _get_gradient_color(ratio)
		bar_up.color = sample_color
		bar_down.color = sample_color
		bar_right.color = sample_color
		bar_left.color = sample_color

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and test_music:
		if test_music.playing == true:
			music_playing = false
			test_music.stop()
		else: 
			music_playing = true
			test_music.play()
	
	##Gates the bar movement. If no music is playing, manually interpolate the bars to 0.
	if not music_playing:
		_lower_bars()
	else:
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
			var bar_right = bars_array_right[i-1]
			var bar_left = bars_array_left[i-1]
			
			bar_up.custom_minimum_size = Vector2(bar_up.custom_minimum_size.x, lerp(bar_up.custom_minimum_size.y, height_up, step_scale))
			bar_down.custom_minimum_size = Vector2(bar_down.custom_minimum_size.x, lerp(bar_down.custom_minimum_size.y, height_low, step_scale))
			bar_right.custom_minimum_size = Vector2(bar_down.custom_minimum_size.x, lerp(bar_down.custom_minimum_size.y, height_low, step_scale))
			bar_left.custom_minimum_size = Vector2(bar_down.custom_minimum_size.x, lerp(bar_down.custom_minimum_size.y, height_low, step_scale))

func _get_gradient_color(pos : float) -> Color:
	if bar_gradient:
		return bar_gradient.sample(pos)
	#print("No gradient given. Switching to default White.")
	return Color.WHITE #White shalt be the default color

func _set_settings() -> void:
	#Bar Orientation Settings
	if show_up_bar:
		bars_up.show()
	else:
		bars_up.hide()
	
	if show_down_bar:
		bars_down.show()
	else:
		bars_down.hide()
	
	if show_right_bar:
		bars_right.show()
	else:
		bars_right.hide()
	
	if show_left_bar:
		bars_left.show()
	else:
		bars_left.hide()
	
	#Upper / Lower / Right / Left Bar Separation Settings
	bars_up.add_theme_constant_override("margin_left", upper_bar_separation)
	bars_up.add_theme_constant_override("margin_right", upper_bar_separation)
	bar_container_up.add_theme_constant_override("separation", upper_bar_separation)
	
	bars_down.add_theme_constant_override("margin_left", lower_bar_separation)
	bars_down.add_theme_constant_override("margin_right", lower_bar_separation)
	bar_container_down.add_theme_constant_override("separation", lower_bar_separation)
	
	bars_right.add_theme_constant_override("margin_left", right_bar_separation)
	bars_right.add_theme_constant_override("margin_right", right_bar_separation)
	bar_container_right.add_theme_constant_override("separation", right_bar_separation)
	
	bars_left.add_theme_constant_override("margin_left", left_bar_separation)
	bars_left.add_theme_constant_override("margin_right", left_bar_separation)
	bar_container_left.add_theme_constant_override("separation", left_bar_separation)
	
	#Bar Reversal Settings
	if reverse_lower_bar:
		bars_array_down.reverse()
	if reverse_upper_bar:
		bars_array_up.reverse()
	if reverse_right_bar:
		bars_array_right.reverse()
	if reverse_left_bar:
		bars_array_left.reverse()

func _lower_bars():
	for i in range(1,BAR_COUNT+1):   
		var bar_up = bars_array_up[i-1]
		var bar_down = bars_array_down[i-1]
		var bar_right = bars_array_right[i-1]
		var bar_left = bars_array_left[i-1]
		
		bar_up.custom_minimum_size = Vector2(bar_up.custom_minimum_size.x, lerp(bar_up.custom_minimum_size.y, 0.0, step_scale))
		bar_down.custom_minimum_size = Vector2(bar_down.custom_minimum_size.x, lerp(bar_down.custom_minimum_size.y, 0.0, step_scale))
		bar_right.custom_minimum_size = Vector2(bar_right.custom_minimum_size.x, lerp(bar_right.custom_minimum_size.y, 0.0, step_scale))
		bar_left.custom_minimum_size = Vector2(bar_left.custom_minimum_size.x, lerp(bar_left.custom_minimum_size.y, 0.0, step_scale))

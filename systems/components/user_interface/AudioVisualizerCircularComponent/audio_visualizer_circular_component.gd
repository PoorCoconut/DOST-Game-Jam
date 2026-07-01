extends Control
class_name AudioVisualizerCircularComponent

@onready var audio_spectrum: AudioEffectInstance = AudioServer.get_bus_effect_instance(1, 0)
@onready var center_marker: Marker2D = %CenterMarker

@export_category("Audio Visualizer Circle Settings")
@export var center_offset: Vector2 = Vector2(0,0)
@export var radius: float = 280.0
@export var major_bar_width: float = 6.0
@export var minor_bar_width: float = 2.0
##Max height the bars always show, even with no audio
@export var major_bar_max_height: float = 40.0
@export var minor_bar_max_height: float = 20.0
##Min height the bars always show, even with no audio
@export var major_bar_min_height: float = 16.0
@export var minor_bar_min_height: float = 8.0
##Raises quieter bars so all quadrants feel active. Higher = more aggressive boost.
@export var normalization_power: float = 0.5
const BAR_COUNT = 60
const MAJOR_EVERY = 5

@export_category("Animation")
##Positive for right, Negative for left
@export var rotation_speed: float = 0.05  # negative = clockwise, positive = counter-clockwise
##How fast / snappy a change of rotation feels like. Default 0.01 feels very smooth for example but it depends on the roation speed itself as well.
@export var rotation_change_speed : float = 0.01
var target_rotation_speed: float = 0.0
##The lower the number, the slower the bar movement
@export var step_scale: float = 0.1

@export_category("Gradient")
@export var bar_gradient: Gradient

const MAX_FREQ = 11050.0
const MIN_DB = 60
const MIN_FREQ = 20.0

var bars: Array = []
var music_playing: bool = false

func _ready():
	# Wait one frame so get_rect() returns the correct size
	set_rotation_speed(rotation_speed)
	await get_tree().process_frame
	pivot_offset = center_marker.global_position
	_spawn_bars()

func _spawn_bars():
	var center = get_global_transform().affine_inverse() * center_marker.global_position
	center += center_offset
	for i in range(BAR_COUNT):
		var bar = ColorRect.new()
		var is_major = (i % MAJOR_EVERY == 0)
		var bw = major_bar_width if is_major else minor_bar_width
		var min_h = major_bar_min_height if is_major else minor_bar_min_height
		bar.color = _get_gradient_color(float(i) / float(BAR_COUNT - 1))
		bar.size = Vector2(bw, min_h)
		bar.custom_minimum_size = Vector2(bw, min_h)
		var angle = (2.0 * PI / BAR_COUNT) * i - PI / 2.0
		bar.position = center + Vector2(cos(angle), sin(angle)) * radius
		bar.rotation = angle + PI / 2.0
		# Pivot at base so bar grows outward only
		bar.pivot_offset = Vector2(bw / 2.0, 0.0)

		add_child(bar)
		bars.append(bar)

func _process(delta):
	rotation_speed = lerp(rotation_speed, target_rotation_speed, rotation_change_speed)
	rotation += rotation_speed * delta
	# DEBUG music toggle
	#if Input.is_action_just_pressed("ui_accept") and test_music:
		#if test_music.playing:
			#set_rotation_speed(-0.05)
			#music_playing = false
			#test_music.stop()
		#else:
			#music_playing = true
			#test_music.play()

	if music_playing:
		_update_bars()
	else:
		_lower_bars()

func _update_bars():
	for i in range(BAR_COUNT):
		var t_lo = float(i) / float(BAR_COUNT)
		var t_hi = float(i + 1) / float(BAR_COUNT)
		var hz_lo = MIN_FREQ * pow(MAX_FREQ / MIN_FREQ, t_lo)
		var hz_hi = MIN_FREQ * pow(MAX_FREQ / MIN_FREQ, t_hi)
		var frq = audio_spectrum.get_magnitude_for_frequency_range(hz_lo, hz_hi)
		var energy = clamp((MIN_DB + linear_to_db(frq.length())) / MIN_DB, 0.0, 1.0)
		energy = pow(energy, normalization_power)
		var is_major = (i % MAJOR_EVERY == 0)
		var min_h = major_bar_min_height if is_major else minor_bar_min_height
		var max_h = major_bar_max_height if is_major else minor_bar_max_height
		var target = min_h + energy * max_h

		_apply_bar(i, target)

func _lower_bars():
	for i in range(BAR_COUNT):
		var is_major = (i % MAJOR_EVERY == 0)
		var min_h = major_bar_min_height if is_major else minor_bar_min_height
		_apply_bar(i, min_h)

func _apply_bar(i: int, target: float):
	var bar = bars[i]
	var new_h = lerp(bar.size.y, target, step_scale)
	bar.size.y = new_h
	bar.custom_minimum_size.y = new_h

func _get_gradient_color(pos: float) -> Color:
	if bar_gradient:
		return bar_gradient.sample(pos)
	return Color.WHITE

func set_rotation_speed(to: float) -> void:
	target_rotation_speed = to

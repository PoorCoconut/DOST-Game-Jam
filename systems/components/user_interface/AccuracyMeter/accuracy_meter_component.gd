extends Node2D

@export_category("Electricity Effect")
@export var start_point: Vector2 = Vector2(-57, 0)
@export var end_point: Vector2 = Vector2(59, 0)

@export_range(0.0, 1.0, 0.01) var jaggedness: float = 1.0
@export_range(0.0, 1.0, 0.01) var min_jaggedness: float = 0.2

@export var segment_count: int = 12
@export var max_amplitude: float = 8.0
@export_range(0.0, 60.0, 0.5) var speed: float = 16.0
@export var line_color: Color = Color.WHITE:
	set(v): line_color = v; if accuracy_wave: accuracy_wave.default_color = v
@export var line_width: float = 4.5:
	set(v): line_width = v; if accuracy_wave: accuracy_wave.width = v

@export_category("Amp Hand")
@export_range(0.1, 2.0, 0.05) var hand_tween_duration: float = 0.6

@onready var accuracy_wave: Line2D = $AccuracyWave
@onready var amp_hand: Line2D = $AmpHand

var _timer: float = 0.0
var _target_jaggedness: float = 1.0
var _hand_tween: Tween

func _ready() -> void:
	accuracy_wave.width = line_width
	accuracy_wave.default_color = line_color
	amp_hand.rotation_degrees = -90.0

func _process(delta: float) -> void:
	# Smoothly lerp jaggedness toward target each frame
	jaggedness = lerp(jaggedness, _target_jaggedness, 1.0 - pow(0.001, delta))

	if speed <= 0.0:
		return
	_timer += delta
	if _timer >= 1.0 / speed:
		_timer = 0.0
		_rebuild()

func update_accuracy(accuracy: float) -> void:
	accuracy = clampf(accuracy, 0.0, 1.0)

	#The more accurate the palyer is, the less jagged the line will be
	_target_jaggedness = maxf(1.0 - accuracy, min_jaggedness)

	#-90 = far left, 0 = center, 90 = far right
	var side := 1.0 if randf() > 0.5 else -1.0
	var target_angle := side * (1.0 - accuracy) * 90.0

	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()
	_hand_tween = create_tween()
	_hand_tween.set_trans(Tween.TRANS_SINE)
	_hand_tween.set_ease(Tween.EASE_OUT)
	_hand_tween.tween_property(amp_hand, "rotation_degrees", target_angle, hand_tween_duration)

func _rebuild() -> void:
	
	if not accuracy_wave:
		return
	var dir := end_point - start_point
	if dir.length() < 0.001:
		return
	var tangent := dir.normalized()
	var normal := tangent.rotated(PI * 0.5)
	var amplitude := max_amplitude * jaggedness
	accuracy_wave.clear_points()
	accuracy_wave.add_point(start_point)
	for i in range(1, segment_count):
		var t := float(i) / float(segment_count)
		var base := start_point + dir * t
		var displacement := randf_range(-1.0, 1.0)
		var fade := 4.0 * t * (1.0 - t)
		fade = fade * fade * fade
		accuracy_wave.add_point(base + normal * displacement * amplitude * fade)
	accuracy_wave.add_point(end_point)

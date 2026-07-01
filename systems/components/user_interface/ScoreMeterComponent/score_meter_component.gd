extends Node2D
class_name ScoreMeterComponent

@export_category("Arrow Hand")
##!!! THE POINT POSITIONS ARE EXPORTABLE MOSTLY FOR DEBUG PURPOSES!
##This should really not be changed, unless you're actually trying to lengthen the "bar" [good luck with that...]
##Arrow position at 0.0 accuracy
@export var fail_point: Vector2 = Vector2(236, 20) 
##Arrow position at 1.0 accuracy
@export var perfect_point: Vector2 = Vector2(44, 20) 
@export_range(0.05, 2.0, 0.05) var hand_tween_speed_scale: float = 0.6 ##How many seconds it takes for the hand's tween to move

@export_category("Counter Animation")
@export_range(1.0, 60.0, 0.5) var count_up_speed_scale: float = 20.0 ##How many points/units per second the counters animate up at
@export var count_up_min_duration: float = 0.1 ##Minimum tween duration for +1 point additions
@export var count_up_max_duration: float = 0.6 ##Cap tween duration for massive point additions

@onready var arrow_line: Line2D = $ArrowLine
@onready var score_label: Label = $ScoreLabel
@onready var miss_label: Label = $HBoxContainer/MissLabel
@onready var bad_label: Label = $HBoxContainer/BadLabel
@onready var good_label: Label = $HBoxContainer/GoodLabel
@onready var perfect_label: Label = $HBoxContainer/PerfectLabel

@onready var rank_o: Sprite2D = $Ranks/RankO
@onready var rank_s: Sprite2D = $Ranks/RankS
@onready var rank_a: Sprite2D = $Ranks/RankA
@onready var rank_b: Sprite2D = $Ranks/RankB
@onready var rank_c: Sprite2D = $Ranks/RankC
@onready var rank_d: Sprite2D = $Ranks/RankD
@onready var rank_f: Sprite2D = $Ranks/RankF
@onready var rank_animations: AnimationPlayer = $RankAnimations

var _score_value: float = 0.0
var _miss_value: float = 0.0
var _bad_value: float = 0.0
var _good_value: float = 0.0
var _perfect_value: float = 0.0

var _hand_tween: Tween
var _score_tween: Tween
var _miss_tween: Tween
var _bad_tween: Tween
var _good_tween: Tween
var _perfect_tween: Tween

var _current_rank: String = "F"

func _ready() -> void:
	ScoreSystem.score_updated.connect(_on_score_updated)
	ScoreSystem.judgment_made.connect(_on_judgment_made)

func _on_score_updated(_volts: int, watts: int) -> void:
	set_score(watts)
	var new_rank := ScoreSystem.get_rank()
	if new_rank != _current_rank:
		set_rank(new_rank)

func _on_judgment_made(result: String) -> void:
	set_perfects(ScoreSystem.perfects)
	set_goods(ScoreSystem.goods)
	set_bads(ScoreSystem.bads)
	set_misses(ScoreSystem.misses)
	update_accuracy(ScoreSystem.ACCURACY_RATIO[result])

func update_accuracy(accuracy: float) -> void:
	accuracy = clampf(accuracy, 0.0, 1.0)
	#lerp from base to 'perfect' point based on accuracy
	var target_pos := fail_point.lerp(perfect_point, accuracy)
	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()
	_hand_tween = create_tween()
	_hand_tween.set_trans(Tween.TRANS_SINE)
	_hand_tween.set_ease(Tween.EASE_OUT)
	_hand_tween.tween_property(arrow_line, "position", target_pos, hand_tween_speed_scale)

func set_rank(rank_name: String) -> void:
	_get_rank_sprite(_current_rank).visible = false
	var new_sprite := _get_rank_sprite(rank_name)
	new_sprite.visible = true
	rank_animations.play("rank_pop")
	_current_rank = rank_name

#region HELPER FUNCTIONS
func _get_rank_sprite(rank_name: String) -> Sprite2D:
	match rank_name:
		"AP": return rank_o
		"S": return rank_s
		"A": return rank_a
		"B": return rank_b
		"C": return rank_c
		"D": return rank_d
		_: return rank_f

func set_score(new_total: float) -> void:
	_score_value = _animate_to(score_label, _score_value, new_total, _score_tween)

func set_misses(new_total: float) -> void:
	_miss_value = _animate_to(miss_label, _miss_value, new_total, _miss_tween)

func set_bads(new_total: float) -> void:
	_bad_value = _animate_to(bad_label, _bad_value, new_total, _bad_tween)

func set_goods(new_total: float) -> void:
	_good_value = _animate_to(good_label, _good_value, new_total, _good_tween)

func set_perfects(new_total: float) -> void:
	_perfect_value = _animate_to(perfect_label, _perfect_value, new_total, _perfect_tween)

#Counter logic. Tweens the displayed value up to whatever total it's given.
func _animate_to(label: Label, current_value: float, new_total: float, tween: Tween) -> float:
	if tween and tween.is_valid():
		tween.kill()
	var diff := absf(new_total - current_value)
	var duration := clampf(diff / count_up_speed_scale, count_up_min_duration, count_up_max_duration)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(_set_label_value.bind(label), current_value, new_total, duration)
	return new_total

func _set_label_value(value: float, label: Label) -> void:
	label.text = str(int(round(value)))
#endregion

extends Node

@export var hitsound:  AudioStream
@export var ticksound: AudioStream
@onready var lanes: Array[AudioStreamPlayer] = []
@onready var ticks: Array[AudioStreamPlayer] = []


func _ready():
	for i in range(4):
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = hitsound
		p.bus = "SFX"
		p.max_polyphony = 4
		lanes.append(p)
		
		var tp = AudioStreamPlayer.new()
		add_child(tp)
		tp.stream = ticksound
		tp.volume_db = -20
		tp.bus = "SFX"
		ticks.append(tp)


func play_hitsound(lane_index: int) -> void:
	if lane_index >= 0 and lane_index < lanes.size():
		lanes[lane_index].play()

func play_tick(lane_index: int) -> void:
	if lane_index >= 0 and lane_index < lanes.size():
		ticks[lane_index].play()

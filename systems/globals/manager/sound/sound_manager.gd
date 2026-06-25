extends Node

@export var hitsound: AudioStream
@onready var lanes: Array[AudioStreamPlayer] = []


func _ready():
	for i in range(4):
		var p = AudioStreamPlayer.new()
		add_child(p)
		p.stream = hitsound
		p.bus = "SFX"
		lanes.append(p)


func play_hitsound(lane_index: int) -> void:
	lanes[lane_index].play()

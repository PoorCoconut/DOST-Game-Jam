extends Node

@export var hitsound:  AudioStream
@export var ticksound: AudioStream
@onready var lanes: Array[AudioStreamPlayer] = []
@onready var ticks: Array[AudioStreamPlayer] = []


func _ready():
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		p.stream = hitsound
		p.bus = "SFX"
		p.max_polyphony = 4
		lanes.append(p)

		var tp := AudioStreamPlayer.new()
		add_child(tp)
		tp.stream = ticksound
		tp.volume_db = -20
		tp.bus = "SFX"
		ticks.append(tp)


func play_hitsound(lane_index: int) -> void:
	if lane_index >= 0 and lane_index < lanes.size():
		lanes[lane_index].play()


func play_tick(lane_index: int) -> void:
	if lane_index >= 0 and lane_index < ticks.size():
		ticks[lane_index].play()


# ─── VOLUME HELPERS ───────────────────────────────────────────────────────────
# Called by Settings (or the settings UI) — pass a value from 0 to 100.

func set_master_volume(value: float) -> void:
	Settings.apply_volume_master(value)

func set_music_volume(value: float) -> void:
	Settings.apply_volume_music(value)

func set_sfx_volume(value: float) -> void:
	Settings.apply_volume_sfx(value)

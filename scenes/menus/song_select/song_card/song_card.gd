extends Control
class_name SongCardComponent

@onready var jacket_texture: TextureRect = $VBoxContainer/LargeJacketTexture
@onready var title_label: Label = $VBoxContainer/DisplayTitle
@onready var artist_label: Label = $VBoxContainer/DisplayArtist

# Info layout spec references
@onready var length_label: Label = $VBoxContainer/InfoGrid/LengthValue
@onready var bpm_label: Label = $VBoxContainer/InfoGrid/BPMValue
@onready var count_label: Label = $VBoxContainer/InfoGrid/CountValue
@onready var diff_label: Label = $VBoxContainer/InfoGrid/DiffValue

func _ready() -> void:
	clear_card()

func clear_card() -> void:
	title_label.text = "No Song Selected"
	artist_label.text = "—"
	length_label.text = "00:00"
	bpm_label.text = "0"
	count_label.text = "0"
	diff_label.text = "—"
	jacket_texture.texture = null

func display_chart_details(chart: ChartData) -> void:
	title_label.text = chart.song_name
	artist_label.text = chart.artist
	bpm_label.text = "%.0f" % chart.bpm
	count_label.text = str(chart.notes.size())
		
	# Calculate duration string if stream audio tracks are loaded
	if chart.stream:
		var total_seconds := chart.stream.get_length()
		var minutes := int(total_seconds) / 60
		var seconds := int(total_seconds) % 60
		length_label.text = "%02d:%02d" % [minutes, seconds]
	else:
		length_label.text = "00:00"
		
	diff_label.text = "12 Ω" # Static layout baseline matching the mockup for now

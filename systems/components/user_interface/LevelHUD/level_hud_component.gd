extends CanvasLayer
class_name LevelHUDComponent

@onready var song_name_label: Label = $SongNameLabel
@onready var difficulty_label: Label = $DifficultyLabel
@onready var song_progress_bar: ProgressBar = %SongProgressBar

func _ready() -> void:
	set_song_name()
	set_difficulty_text()

func set_song_name(song_name : String = "SONG NAME") -> void:
	song_name_label.text = song_name

func set_difficulty_text(diff_text : String = "DIFFICULTY LABEL") -> void:
	difficulty_label.text = diff_text

extends CanvasLayer
class_name LevelHUDComponent

@onready var beat: Timer = %Beat
@onready var label: Label = %SongLabel
@onready var hbox_container: HBoxContainer = %HBoxContainer
@onready var song_panel: Panel = %SongPanel

@export_category("DEBUG SETTINGS")
##120 Seems to be a perfect fit for the current panel. Feel free to change however to fit the need.
@export var margin : int = 120

var song_name : String = "Song Name"
var bpm : int = 0
var music_playing : bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#These processes should be automatic. Waiting for a Game Manager or a Global Singleton
	#or something that collects The Song name and BPM and stores it in there.
	
	update_song_name("Hey, so...")
	bpm = 120 #This should be replaced with the song's BPM itself
	
	#Set Beat (If there's a global beat..er then use that instead)
	beat.wait_time = 60 / float(bpm)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_song_name(_song_name: String) -> void:
	label.text = _song_name
	song_name = _song_name
	label.custom_minimum_size.x = label.get_minimum_size().x
	
	await get_tree().process_frame  # wait one frame for layout to update
	song_panel.size.x = hbox_container.size.x + margin

extends CanvasLayer
class_name LevelHUDComponent

@onready var beat: Timer = %Beat

var song_name : String = "Song Name"
var bpm : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#These processes should be automatic. Waiting for a Game Manager or a Global Singleton
	#or something that collects The Song name and BPM and stores it in there.
	
	song_name = "This should be replaced with the song name itself"
	bpm = 120 #This should be replaced with the song's BPM itself
	
	#Set Beat (If there's a global beat..er then use that instead)
	beat.wait_time = 60 / float(bpm)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

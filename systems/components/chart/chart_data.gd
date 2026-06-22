extends Resource
class_name ChartData

@export var song_name: String         # the song title
@export var bpm: float                # the 'real' bpm of the song
@export var stream: AudioStream       # the music file
@export var notes: Array[NoteData]    # list of NoteData resources

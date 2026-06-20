extends Resource
class_name NoteData

@export var beat: float
@export var lane: int
@export_enum("low (+)", "high (x)") var mode: String = "low (+)"

# hold notes only — leave 0 for tap notes
@export var beat_end: float = 0.0

extends Resource
class_name NoteData

@export var beat: float
@export var lane: int
@export_enum("low (+)", "high (x)") var mode: String = "low (+)"

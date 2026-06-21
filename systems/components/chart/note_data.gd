extends Resource
class_name NoteData

@export var beat_start: float     # tap notes
@export var beat_end: float = 0.0 # hold notes — leave 0 for tap notes

# 0   1   2   3
# N   E   S   W
# NE  SE  SW  NW
@export var lane: int

# rotation (+,x)
@export_enum("low (+)", "high (x)") var mode: String = "low (+)"

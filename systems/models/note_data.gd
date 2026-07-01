extends Resource
class_name NoteData

@export var beat_start: float     # tap notes
@export var beat_end: float = 0.0 # hold notes — leave 0 for tap notes
@export var is_lite: bool = false # lite notes - leave false if normal

# 0   1   2   3
# N   E   S   W
# NE  SE  NW  SW (CW)
# NW  SW  SE  NE (CT)
@export_range(0,3) var lane: int

# rotation (+,x)
@export_enum("low (+)", "high (x)") var mode: String = "low (+)"


func is_hold_note() -> bool: return beat_end > beat_start
func mode_type() -> String: return "+" if mode.contains("+") else "x"

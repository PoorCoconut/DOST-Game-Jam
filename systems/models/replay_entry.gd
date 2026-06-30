extends Resource
class_name ReplayEntry

# identifies which note this entry belongs to
@export var beat_start: float
@export var lane: int
@export var mode: String

# what happened
@export var judgment: String               # "perfect", "good", "bad", "miss"
@export var time_of_press: float           # when the player pressed (Conductor.get_time())
@export var is_hold: bool = false
@export var time_of_release: float = -1.0  # -1 means full hold or not applicable

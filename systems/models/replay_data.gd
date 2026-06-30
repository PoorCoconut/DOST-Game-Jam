extends Resource
class_name ReplayData
@export var chart: ChartData
@export var entries: Array = []
@export var final_watts: int
@export var final_volts: int
@export var final_rank: String
@export var perfects: int
@export var goods: int
@export var bads: int
@export var misses: int
@export var max_volts: int = 0  # peak combo reached during the run
@export var timestamp: float = 0.0  # Unix time when the replay was saved

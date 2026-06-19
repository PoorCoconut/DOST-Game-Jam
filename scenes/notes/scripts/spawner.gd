extends Node2D


@export var note_scene: PackedScene
@export var approach_time: float = 1.5
@export var outer_radius: float = 400.0
@export var hit_radius: float = 100.0

# temporary spawner
var chart: Array = [
	{ "time": 1.0, "lane": 0, "mode": "plus" },
	{ "time": 2.5, "lane": 1, "mode": "plus" },
	{ "time": 4.0, "lane": 2, "mode": "plus" },
	{ "time": 5.5, "lane": 3, "mode": "plus" },
	{ "time": 6, "lane": 0, "mode": "x" },
	{ "time": 7.5, "lane": 1, "mode": "x" },
	{ "time": 9, "lane": 2, "mode": "x" },
	{ "time": 10.5, "lane": 3, "mode": "x" },
]

var next_index: int = 0
#+ diretion
var plus_angles: Array = [-90.0, 0.0, 90.0, 180.0]
#x directions
var x_angles: Array = [-45.0, 45.0, 135.0, 225.0]

var active_notes: Dictionary = {
	"plus": [[], [], [], []],
	"x": [[], [], [], []],
}


func _ready() -> void:
	Conductor.start()


func _process(_delta: float) -> void:
	var curr: float = Conductor.get_time()

	while next_index < chart.size():
		var note_data: Dictionary = chart[next_index]
		var spawn_at: float = note_data["time"] - approach_time

		if curr < spawn_at:
			break

		_spawn_note(note_data["lane"], note_data["time"], note_data["mode"])
		next_index += 1


func _spawn_note(lane: int, target_time: float, mode: String) -> void:
	var angles: Array = plus_angles if mode == "plus" else x_angles
	var angle_rad: float = deg_to_rad(angles[lane])
	var direction: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))

	var note: Node2D = note_scene.instantiate()
	add_child(note)
	note.setup(lane, target_time, approach_time, direction * outer_radius, direction * hit_radius)

	active_notes[mode][lane].append(note)
	note.tree_exited.connect(_on_note_removed.bind(mode, lane, note))


func _on_note_removed(mode: String, lane: int, note: Node2D) -> void:
	active_notes[mode][lane].erase(note)

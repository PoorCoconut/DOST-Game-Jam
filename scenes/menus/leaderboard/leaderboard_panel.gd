extends CanvasLayer

signal entry_selected(replay: ReplayData)
signal closed

@onready var list_container : VBoxContainer = $Background/Panel/VBox/ScrollContainer/ListContainer
@onready var title_label    : Label         = $Background/Panel/VBox/TitleLabel
@onready var empty_label    : Label         = $Background/Panel/VBox/EmptyLabel
@onready var close_btn      : Button        = $Background/Panel/VBox/CloseButton

const ENTRY_SCENE_TEMPLATE_HEIGHT: int = 56

var _chart: ChartData = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	close_btn.pressed.connect(_on_close_pressed)


func open_for_chart(chart: ChartData) -> void:
	_chart = chart
	title_label.text = "Leaderboard — " + chart.song_name
	visible = true
	get_tree().paused = true
	_populate()


func _on_close_pressed() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _populate() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var replays := _load_replays_for_chart(_chart)

	if replays.is_empty():
		empty_label.visible = true
		return
	empty_label.visible = false

	replays.sort_custom(func(a, b): return a.final_watts > b.final_watts)

	for i in range(replays.size()):
		var replay: ReplayData = replays[i]
		_add_entry_row(i + 1, replay)


func _add_entry_row(placement: int, replay: ReplayData) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ENTRY_SCENE_TEMPLATE_HEIGHT)

	var rank_label := Label.new()
	rank_label.text = "#%d" % placement
	rank_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(rank_label)

	var name_label := Label.new()
	#
	#
	#Change the name here
	#
	#
	name_label.text = "nameless"
	name_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(name_label)

	var grade_label := Label.new()
	grade_label.text = replay.final_rank
	grade_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(grade_label)

	var score_label := Label.new()
	score_label.text = str(replay.final_watts)
	score_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(score_label)

	var combo_label := Label.new()
	combo_label.text = "%dV" % replay.max_volts
	combo_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(combo_label)

	var date_label := Label.new()
	date_label.text = _format_timestamp(replay.timestamp)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(date_label)

	var select_btn := Button.new()
	select_btn.text = "View"
	select_btn.pressed.connect(func(): _on_entry_pressed(replay))
	row.add_child(select_btn)

	list_container.add_child(row)


func _on_entry_pressed(replay: ReplayData) -> void:
	entry_selected.emit(replay)
	visible = false
	get_tree().paused = false


func _format_timestamp(unix_time: float) -> String:
	if unix_time <= 0:
		return "—"
	var datetime := Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d-%02d-%02d %02d:%02d" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute]


func _load_replays_for_chart(chart: ChartData) -> Array[ReplayData]:
	var results: Array[ReplayData] = []
	if chart == null:
		return results

	var song_slug := chart.song_name.to_lower().replace(" ", "_")
	var dir_path := "user://replays/%s/" % song_slug

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results  # no replays for this song yet

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var replay := ResourceLoader.load(dir_path + file_name) as ReplayData
			if replay != null:
				results.append(replay)
		file_name = dir.get_next()
	dir.list_dir_end()

	return results

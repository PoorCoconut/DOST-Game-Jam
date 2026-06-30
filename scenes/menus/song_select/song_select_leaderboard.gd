extends Control


@onready var title_label    : Label         = $VBox/TitleLabel
@onready var list_container : VBoxContainer = $VBox/ScrollContainer/ListContainer
@onready var empty_label    : Label         = $VBox/EmptyLabel

const ENTRY_ROW_HEIGHT: int = 56

var _current_chart: ChartData = null

#just call show_chart when hoving or selecting a song
func show_chart(chart: ChartData) -> void:
	if chart == _current_chart:
		return

	_current_chart = chart
	title_label.text = "Leaderboard"
	if chart != null:
		title_label.text = "Leaderboard — " + chart.song_name

	_refresh()


func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()

	if _current_chart == null:
		empty_label.visible = true
		empty_label.text = "Select a song"
		return

	var replays := _load_replays_for_chart(_current_chart)

	if replays.is_empty():
		empty_label.visible = true
		empty_label.text = "No scores yet for this song."
		return

	empty_label.visible = false
	replays.sort_custom(func(a, b): return a.final_watts > b.final_watts)

	for i in range(replays.size()):
		_add_entry_row(i + 1, replays[i])


func _add_entry_row(placement: int, replay: ReplayData) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ENTRY_ROW_HEIGHT)

	var rank_label := Label.new()
	rank_label.text = "#%d" % placement
	rank_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(rank_label)

	var name_label := Label.new()
	#
	#
	#Change for the final
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

	list_container.add_child(row)


func _format_timestamp(unix_time: float) -> String:
	if unix_time <= 0:
		return "—"
	var datetime := Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%02d/%02d/%04d" % [datetime.month, datetime.day, datetime.year]


func _load_replays_for_chart(chart: ChartData) -> Array[ReplayData]:
	var results: Array[ReplayData] = []
	if chart == null:
		return results

	var song_slug := chart.song_name.to_lower().replace(" ", "_")
	var dir_path := "user://replays/%s/" % song_slug

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results

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

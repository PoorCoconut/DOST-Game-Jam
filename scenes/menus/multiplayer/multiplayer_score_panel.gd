extends Control

var my_score: int = 0
var opponent_score: int = 0
var my_name: String = ""
var opponent_name: String = ""

var _row_top: Label
var _row_bottom: Label

func _ready() -> void:
	print("[SCORE PANEL] READY")
	if not SceneManager.is_multiplayer:
		visible = false
		return

	my_name = NetworkManager.player_name
	if multiplayer.is_server():
		opponent_name = NetworkManager.guest_name
	else:
		opponent_name = NetworkManager.host_name

	# Build UI in code so no scne editing needed BUT WILL CHANGE LATER FEELING LAZY
	var panel := PanelContainer.new()
	panel.size = Vector2(150, 50)
	#dont fotget (x,y)
	var viewport_width := get_viewport_rect().size.x
	panel.position = Vector2(viewport_width - panel.size.x,70)
	add_child(panel)

	print("[SCORE PANEL] panel added")

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	_row_top = Label.new()
	_row_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_row_top)

	_row_bottom = Label.new()
	_row_bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_row_bottom)
	_update_display()

	ScoreSystem.score_updated.connect(_on_my_score_updated)
	NetworkManager.opponent_score_updated.connect(_on_opponent_score_updated)


func _on_my_score_updated(_volts: int, watts: int) -> void:
	my_score = watts
	NetworkManager.send_score_update(my_score)
	_update_display()


func _on_opponent_score_updated(score: int) -> void:
	opponent_score = score
	_update_display()


func _update_display() -> void:
	var entries := [
		{"name": my_name,       "score": my_score},
		{"name": opponent_name, "score": opponent_score},
	]
	entries.sort_custom(func(a, b): return a.score > b.score)

	_row_top.text    = "#1  %s:  %d" % [entries[0].name, entries[0].score]
	_row_bottom.text = "#2  %s:  %d" % [entries[1].name, entries[1].score]

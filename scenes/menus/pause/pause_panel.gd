extends CanvasLayer

@onready var title_label    : Label  = $Background/VBox/TitleLabel
@onready var continue_btn   : Button = $Background/VBox/ContinueButton
@onready var results_btn    : Button = $Background/VBox/ResultsButton
@onready var retry_btn      : Button = $Background/VBox/RetryButton
@onready var quit_btn       : Button = $Background/VBox/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	continue_btn.pressed.connect(_on_continue_pressed)
	results_btn.pressed.connect(_on_results_pressed)
	retry_btn.pressed.connect(_on_retry_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)


func setup(is_fail: bool) -> void:
	if is_fail:
		title_label.text = "You Failed"
		continue_btn.visible = false
		results_btn.visible = true
	else:
		title_label.text = "Paused"
		continue_btn.visible = true
		results_btn.visible = false


func _on_continue_pressed() -> void:
	PauseManager.resume_game()

func _on_results_pressed() -> void:
	PauseManager.go_to_results_after_fail()

func _on_retry_pressed() -> void:
	PauseManager.retry_level()

func _on_quit_pressed() -> void:
	PauseManager.quit_to_menu()

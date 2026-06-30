extends PanelContainer
class_name ProfileDropdownOverlayComponent

signal edit_profile_requested

# Mapping targets exactly from the VBox rows hierarchy layout grid
@onready var skill_count: Label = $MarginContainer/VBoxContainer/StatRowsVBox/MostUsedSkillRow/Count
@onready var skill_tier: Label = $MarginContainer/VBoxContainer/StatRowsVBox/MostUsedSkillRow/Tier

@onready var mod_count: Label = $MarginContainer/VBoxContainer/StatRowsVBox/MostUsedModRow/Count
@onready var mod_tier: Label = $MarginContainer/VBoxContainer/StatRowsVBox/MostUsedModRow/Tier

@onready var edit_btn: Button = $MarginContainer/VBoxContainer/MarginContainer/EditButton

func _ready() -> void:
	# Hide by default until toggled by header parent signals
	visible = false
	
	edit_btn.pressed.connect(func(): edit_profile_requested.emit())
	
	# Seed tracking data placeholder baseline specs directly on boot
	load_player_stats_mockup()

func load_player_stats_mockup() -> void:
	# Matches your user details layout overlay reference values exactly
	skill_count.text = "10"
	skill_tier.text = "Ω"
	skill_tier.add_theme_color_override("font_color", Color(0.6, 0.2, 0.9)) # Purple
	
	mod_count.text = "5"
	mod_tier.text = "S"
	mod_tier.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1)) # Orange

func toggle_dropdown(should_open: bool) -> void:
	if should_open:
		visible = true
		# Animate drop sequence nicely using a quick opacity/scale fade
		modulate.a = 0.0
		scale = Vector2(1.0, 0.9)
		pivot_offset = Vector2(size.x / 2.0, 0.0) # Scale down from top edge line
		
		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 1.0, 0.2)
		tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	else:
		visible = false

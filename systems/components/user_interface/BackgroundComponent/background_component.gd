extends Node2D
class_name BackgroundComponent

##NOTE! 
##THE BACKGROUND WILL TRY TO FIT THE IMAGE IN THE CORRECT SCALE BY WARPING THEM.
##THIS MAY MAKE IMAGES THAT AREN'T 16:9 LOOK STRETCHED!

@export var parallax: bool = false
##Fraction of max offset actually used, keeps a buffer from the edge. This controls how far the edge can be seen.
@export_range(0.0, 1.0) var parallax_safety_margin: float = 0.9
@export var parallax_smoothing: float = 8.0 ##The higher the number, the snappier the follow. The lower, the slower it is!

@onready var background: TextureRect = $Background
@onready var background_container: Node2D = $BackgroundContainer

#WARNING! Magic Numbers. They're due to how I didn't use Control nodes as the root node for this one.
const BG_SIZE := Vector2(1265.778, 712.0)
const VIEWPORT_SIZE := Vector2(1152, 648)

var _max_offset: Vector2
var _target_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	var slack := BG_SIZE - VIEWPORT_SIZE
	_max_offset = (slack / 2.0) * parallax_safety_margin

func _process(delta: float) -> void:
	if not parallax:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var mouse_pos := get_viewport().get_mouse_position()
	var normalized := Vector2(
		(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
		(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	)
	normalized = normalized.clamp(Vector2(-1, -1), Vector2(1, 1))
	_target_offset = -normalized * _max_offset
	background_container.position = background_container.position.lerp(
		_target_offset, 1.0 - exp(-parallax_smoothing * delta)
	)

func set_background(source: Variant) -> void:
	if source is Texture2D:
		background.texture = source
	elif source is String:
		var tex := load(source) as Texture2D
		if tex:
			background.texture = tex
		else:
			push_warning("Failed to load background texture at: %s .File path might not exist!" % source)
	else:
		push_warning("set_background() expected Texture2D or String, got: %s" % typeof(source))

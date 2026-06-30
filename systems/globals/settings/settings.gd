extends Node

# ─── SAVE PATH ───────────────────────────────────────────────────────────────
const SAVE_PATH := "user://settings.cfg"

# ─── SCROLL SPEED ────────────────────────────────────────────────────────────
# Multiplier. 1.0x = default BASE_SCROLL_SPEED in NoteSpawner.
var current_scroll_speed: float = 1.0

# ─── AUDIO OFFSET ────────────────────────────────────────────────────────────
# In seconds. Added to _song_position in Conductor.
var audio_offset: float = 0.0

# ─── VOLUME (0–100) ──────────────────────────────────────────────────────────
var volume_master: float = 100.0
var volume_music:  float = 100.0
var volume_sfx:    float = 100.0

# ─── KEYBINDS ────────────────────────────────────────────────────────────────
# These match the InputMap action names you define in Project Settings.
# Values are the KEY_ constants (e.g. KEY_F, KEY_J, etc.)
var keybind_plus_lanes:  Array[int] = [KEY_F, KEY_K, KEY_J, KEY_D]   # Top, Right, Bottom, Left
var keybind_x_lanes:     Array[int] = [KEY_F, KEY_K, KEY_J, KEY_D]   # same keys, different mode
var keybind_transform:   int        = KEY_SPACE
var keybind_quick_retry: int        = KEY_Q

# Internal: action names used by judgement.gd
const PLUS_ACTION_PREFIX:  String = "lane"          # lane1..lane4
const X_ACTION_PREFIX:     String = "lane_x"        # lane_x1..lane_x4
const TRANSFORM_ACTION:    String = "transform"
const QUICK_RETRY_ACTION:  String = "quick_retry"

# ─── READY ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	load_settings()
	_apply_all()


# ─── APPLY ALL ───────────────────────────────────────────────────────────────
func _apply_all() -> void:
	apply_volume_master(volume_master)
	apply_volume_music(volume_music)
	apply_volume_sfx(volume_sfx)
	apply_keybinds()


# ─── VOLUME ──────────────────────────────────────────────────────────────────
func apply_volume_master(value: float) -> void:
	volume_master = clampf(value, 0.0, 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(volume_master / 100.0)
	)

func apply_volume_music(value: float) -> void:
	volume_music = clampf(value, 0.0, 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(volume_music / 100.0)
	)

func apply_volume_sfx(value: float) -> void:
	volume_sfx = clampf(value, 0.0, 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(volume_sfx / 100.0)
	)


# ─── KEYBINDS ────────────────────────────────────────────────────────────────
func apply_keybinds() -> void:
	# + lanes: lane1..lane4
	for i in range(4):
		var action := "lane%d" % (i + 1)
		_remap_action(action, keybind_plus_lanes[i])

	# x lanes: lane_x1..lane_x4
	for i in range(4):
		var action := "lane_x%d" % (i + 1)
		_remap_action(action, keybind_x_lanes[i])

	_remap_action(TRANSFORM_ACTION, keybind_transform)
	_remap_action(QUICK_RETRY_ACTION, keybind_quick_retry)


func _remap_action(action: String, key_code: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.keycode = key_code
	InputMap.action_add_event(action, ev)


func set_keybind_plus_lane(lane_idx: int, key_code: int) -> void:
	keybind_plus_lanes[lane_idx] = key_code
	_remap_action("lane%d" % (lane_idx + 1), key_code)

func set_keybind_x_lane(lane_idx: int, key_code: int) -> void:
	keybind_x_lanes[lane_idx] = key_code
	_remap_action("lane_x%d" % (lane_idx + 1), key_code)

func set_keybind_transform(key_code: int) -> void:
	keybind_transform = key_code
	_remap_action(TRANSFORM_ACTION, key_code)

func set_keybind_quick_retry(key_code: int) -> void:
	keybind_quick_retry = key_code
	_remap_action(QUICK_RETRY_ACTION, key_code)


# ─── SAVE / LOAD ─────────────────────────────────────────────────────────────
func save_settings() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("gameplay", "scroll_speed",    current_scroll_speed)
	cfg.set_value("audio",    "offset",          audio_offset)
	cfg.set_value("volume",   "master",          volume_master)
	cfg.set_value("volume",   "music",           volume_music)
	cfg.set_value("volume",   "sfx",             volume_sfx)
	cfg.set_value("keybinds", "plus_lanes",      keybind_plus_lanes)
	cfg.set_value("keybinds", "x_lanes",         keybind_x_lanes)
	cfg.set_value("keybinds", "transform",       keybind_transform)
	cfg.set_value("keybinds", "quick_retry",     keybind_quick_retry)

	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		print("[SETTINGS] No save file found, using defaults.")
		return

	current_scroll_speed = cfg.get_value("gameplay", "scroll_speed",    1.0)
	audio_offset         = cfg.get_value("audio",    "offset",          0.0)
	volume_master        = cfg.get_value("volume",   "master",          100.0)
	volume_music         = cfg.get_value("volume",   "music",           100.0)
	volume_sfx           = cfg.get_value("volume",   "sfx",             100.0)
	keybind_plus_lanes   = cfg.get_value("keybinds", "plus_lanes",      [KEY_F, KEY_K, KEY_J, KEY_D])
	keybind_x_lanes      = cfg.get_value("keybinds", "x_lanes",         [KEY_F, KEY_K, KEY_J, KEY_D])
	keybind_transform    = cfg.get_value("keybinds", "transform",       KEY_SPACE)
	keybind_quick_retry  = cfg.get_value("keybinds", "quick_retry",     KEY_Q)

extends Node

const SAVE_PATH := "user://player.cfg"

# no entries yet dawg
const DEFAULT_PROFILE_ICONS: Array[Texture2D] = [
	preload("res://assets/profile_icons/default_icon.png"),
]

#for future tutorial purposes
var is_first_time_playing: bool = true

#identifiers
var username: String = "Player"
var profile_icons: Array[Texture2D] = DEFAULT_PROFILE_ICONS.duplicate()
var icon_index: int = 0

#energy sauce
var last_used_energy_source: String = "solar"

# placeholders
var skill_solar: String = ""
var skill_hydro: String = ""
var skill_wind:  String = ""
var skill_geo:   String = ""

#mods
var mod_solar: String = ""
var mod_hydro: String = ""
var mod_wind:  String = ""
var mod_geo:   String = ""

# stats
var most_used_skill: String       = ""
var most_used_skill_count: int    = 0
var most_used_mod: String         = ""
var most_used_mod_count: int      = 0
var last_used_mods: Array[String] = []

var energies_sustained: int = 0
var energies_missed: int    = 0
var multiplayer_wins: int   = 0
var multiplayer_losses: int = 0


func _ready() -> void:
	load_player()


func get_current_icon() -> Texture2D:
	if icon_index < 0 or icon_index >= profile_icons.size():
		return DEFAULT_PROFILE_ICONS[0]
	return profile_icons[icon_index]


func set_icon_index(index: int) -> void:
	icon_index = clampi(index, 0, profile_icons.size() - 1)


#save/load
func save_player() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("meta",     "is_first_time_playing",   is_first_time_playing)

	cfg.set_value("identity", "username",                username)
	cfg.set_value("identity", "icon_index",               icon_index)

	cfg.set_value("energy",   "last_used_source",         last_used_energy_source)

	cfg.set_value("skills",   "solar",                    skill_solar)
	cfg.set_value("skills",   "hydro",                    skill_hydro)
	cfg.set_value("skills",   "wind",                     skill_wind)
	cfg.set_value("skills",   "geo",                      skill_geo)

	cfg.set_value("mods",     "solar",                    mod_solar)
	cfg.set_value("mods",     "hydro",                    mod_hydro)
	cfg.set_value("mods",     "wind",                     mod_wind)
	cfg.set_value("mods",     "geo",                      mod_geo)

	cfg.set_value("stats",    "most_used_skill",          most_used_skill)
	cfg.set_value("stats",    "most_used_skill_count",    most_used_skill_count)
	cfg.set_value("stats",    "most_used_mod",             most_used_mod)
	cfg.set_value("stats",    "most_used_mod_count",       most_used_mod_count)
	cfg.set_value("stats",    "last_used_mods",            last_used_mods)
	cfg.set_value("stats",    "energies_sustained",        energies_sustained)
	cfg.set_value("stats",    "energies_missed",           energies_missed)
	cfg.set_value("stats",    "multiplayer_wins",          multiplayer_wins)
	cfg.set_value("stats",    "multiplayer_losses",        multiplayer_losses)

	cfg.save(SAVE_PATH)


func load_player() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		print("[PLAYER] No save file found, using defaults.")
		return

	is_first_time_playing = cfg.get_value("meta", "is_first_time_playing", true)

	username    = cfg.get_value("identity", "username",    "Player")
	icon_index  = cfg.get_value("identity", "icon_index",  0)

	last_used_energy_source = cfg.get_value("energy", "last_used_source", "solar")

	skill_solar = cfg.get_value("skills", "solar", "")
	skill_hydro = cfg.get_value("skills", "hydro", "")
	skill_wind  = cfg.get_value("skills", "wind",  "")
	skill_geo   = cfg.get_value("skills", "geo",   "")

	mod_solar = cfg.get_value("mods", "solar", "")
	mod_hydro = cfg.get_value("mods", "hydro", "")
	mod_wind  = cfg.get_value("mods", "wind",  "")
	mod_geo   = cfg.get_value("mods", "geo",   "")

	most_used_skill       = cfg.get_value("stats", "most_used_skill",       "")
	most_used_skill_count = cfg.get_value("stats", "most_used_skill_count", 0)
	most_used_mod         = cfg.get_value("stats", "most_used_mod",         "")
	most_used_mod_count   = cfg.get_value("stats", "most_used_mod_count",   0)
	last_used_mods        = Array(cfg.get_value("stats", "last_used_mods", []), TYPE_STRING, "", null)
	energies_sustained    = cfg.get_value("stats", "energies_sustained",    0)
	energies_missed       = cfg.get_value("stats", "energies_missed",       0)
	multiplayer_wins      = cfg.get_value("stats", "multiplayer_wins",      0)
	multiplayer_losses    = cfg.get_value("stats", "multiplayer_losses",    0)


#future purposes
func mark_tutorial_seen() -> void:
	is_first_time_playing = false
	save_player()

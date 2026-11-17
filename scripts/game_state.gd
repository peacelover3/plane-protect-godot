extends Node
## Persistent progress, level definitions, difficulty and scoring.

const SAVE_PATH := "user://sky_warden_save.cfg"
const SAVE_VERSION := 2
const MAX_LEVEL := 4

const BEACON_POS := Vector2(640, 545)

const SCORE_GRUNT := 10
const SCORE_RUNNER := 15
const SCORE_TANK := 30
const SCORE_FLAK := 40

enum Difficulty { EASY, NORMAL, HARD }
const DIFFICULTY_NAMES := ["Easy", "Normal", "Hard"]

## Four records, one note each, then the King.
const LEVELS: Array[Dictionary] = [
	{
		"name": "First Patrol",
		"blurb": "A few scouts are testing the perimeter.",
		"target": 200, "duration": 60.0, "spawn_interval": 1.60,
		"max_alive": 6, "flak": 0, "speed_mult": 1.00,
		"weights": {"grunt": 1.0},
	},
	{
		"name": "Open Sky",
		"blurb": "Runners are joining the push.",
		"target": 300, "duration": 55.0, "spawn_interval": 1.35,
		"max_alive": 8, "flak": 0, "speed_mult": 1.04,
		"weights": {"grunt": 0.70, "runner": 0.30},
	},
	{
		"name": "Crossfire",
		"blurb": "Flak crews have dug in.",
		"target": 380, "duration": 55.0, "spawn_interval": 1.15,
		"max_alive": 10, "flak": 1, "speed_mult": 1.08,
		"weights": {"grunt": 0.55, "runner": 0.35, "tank": 0.10},
	},
	{
		"name": "The Last Gate",
		"blurb": "Everything they have left, before the King.",
		"target": 450, "duration": 50.0, "spawn_interval": 1.00,
		"max_alive": 12, "flak": 2, "speed_mult": 1.14,
		"weights": {"grunt": 0.40, "runner": 0.30, "tank": 0.30},
	},
]

var unlocked_level: int = 1
var boss_unlocked: bool = false
var boss_defeated: bool = false
var records: Dictionary = {}
var endless_best: int = 0
var total_kills: int = 0
var total_runs: int = 0
var muted: bool = false
var sfx_volume: float = 0.85
var seen_tutorial: bool = false
var note_sent: bool = false
var difficulty: int = Difficulty.NORMAL


func _ready() -> void:
	load_progress()


# --- Level data -------------------------------------------------------------

func level_data(level: int) -> Dictionary:
	var idx := clampi(level, 1, MAX_LEVEL) - 1
	return LEVELS[idx]


func level_name(level: int) -> String:
	return str(level_data(level).get("name", "Level %d" % level))


func base_target_for(level: int) -> int:
	return int(level_data(level).get("target", 0))


func target_for(level: int) -> int:
	return int(round(base_target_for(level) * target_scale() / 10.0) * 10)


func duration_for(level: int) -> float:
	return float(level_data(level).get("duration", 60.0))


func record_for(level: int) -> int:
	return int(records.get(level, 0))


func is_level_cleared(level: int) -> bool:
	return level < unlocked_level or (level == MAX_LEVEL and boss_unlocked)


func cleared_count() -> int:
	var count := 0
	for i in range(1, MAX_LEVEL + 1):
		if is_level_cleared(i):
			count += 1
	return count


func next_level() -> int:
	return clampi(unlocked_level, 1, MAX_LEVEL)


# --- Difficulty -------------------------------------------------------------

func difficulty_name() -> String:
	return str(DIFFICULTY_NAMES[clampi(difficulty, 0, 2)])


func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, 2)
	save_progress()


func target_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.75
		Difficulty.HARD:
			return 1.25
		_:
			return 1.0


func spawn_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 1.25
		Difficulty.HARD:
			return 0.85
		_:
			return 1.0


func speed_scale() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.92
		Difficulty.HARD:
			return 1.08
		_:
			return 1.0


func flak_adjust() -> int:
	match difficulty:
		Difficulty.EASY:
			return -1
		Difficulty.HARD:
			return 1
		_:
			return 0


func boss_hp() -> int:
	match difficulty:
		Difficulty.EASY:
			return 50
		Difficulty.HARD:
			return 88
		_:
			return 70


# --- Progress ---------------------------------------------------------------

func apply_level_result(level: int, score: int, won: bool) -> void:
	if score > record_for(level):
		records[level] = score
	if won:
		if level >= MAX_LEVEL:
			boss_unlocked = true
		else:
			unlocked_level = maxi(unlocked_level, level + 1)
	save_progress()


func mark_boss_defeated() -> void:
	boss_defeated = true
	boss_unlocked = true
	save_progress()


func record_endless(score: int) -> void:
	endless_best = maxi(endless_best, score)
	save_progress()


# --- Persistence ------------------------------------------------------------

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "version", SAVE_VERSION)
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	cfg.set_value("progress", "boss_unlocked", boss_unlocked)
	cfg.set_value("progress", "boss_defeated", boss_defeated)
	cfg.set_value("progress", "records", records.duplicate())
	cfg.set_value("progress", "endless_best", endless_best)
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "total_runs", total_runs)
	cfg.set_value("progress", "seen_tutorial", seen_tutorial)
	cfg.set_value("progress", "note_sent", note_sent)
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "difficulty", difficulty)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save progress (error %d)" % err)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked_level = clampi(int(cfg.get_value("progress", "unlocked_level", 1)), 1, MAX_LEVEL)
	boss_unlocked = bool(cfg.get_value("progress", "boss_unlocked", false))
	boss_defeated = bool(cfg.get_value("progress", "boss_defeated", false))
	var loaded_records = cfg.get_value("progress", "records", {})
	if loaded_records is Dictionary:
		records = loaded_records.duplicate()
	endless_best = int(cfg.get_value("progress", "endless_best", 0))
	total_kills = int(cfg.get_value("progress", "total_kills", 0))
	total_runs = int(cfg.get_value("progress", "total_runs", 0))
	seen_tutorial = bool(cfg.get_value("progress", "seen_tutorial", false))
	note_sent = bool(cfg.get_value("progress", "note_sent", false))
	muted = bool(cfg.get_value("settings", "muted", false))
	sfx_volume = clampf(float(cfg.get_value("settings", "sfx_volume", 0.85)), 0.0, 1.0)
	difficulty = clampi(int(cfg.get_value("settings", "difficulty", Difficulty.NORMAL)), 0, 2)


func reset_progress() -> void:
	unlocked_level = 1
	boss_unlocked = false
	boss_defeated = false
	records = {}
	endless_best = 0
	total_kills = 0
	total_runs = 0
	seen_tutorial = false
	note_sent = false
	difficulty = Difficulty.NORMAL
	save_progress()

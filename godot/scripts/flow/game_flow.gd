extends Node

## Scene routing Autoload.

const SCENE_LOGO := "res://scenes/menus/Logo.tscn"
const SCENE_MAIN_MENU := "res://scenes/menus/MainMenu.tscn"
const SCENE_QUEST_MAP := "res://scenes/menus/QuestMap.tscn"
const SCENE_MODE_MENU := "res://scenes/menus/ModeMenu.tscn"
const SCENE_HELP := "res://scenes/menus/Help.tscn"
const SCENE_COUNTDOWN := "res://scenes/menus/CountDown.tscn"
const SCENE_START_AT_10 := "res://scenes/menus/StartAt10.tscn"
const SCENE_MATCH := "res://scenes/match/MatchRoot.tscn"
const SCENE_END_GAME := "res://scenes/menus/EndGame.tscn"
const SCENE_RATE_IT := "res://scenes/overlays/RateIt.tscn"
const SCENE_ABOUT := "res://scenes/overlays/AboutUs.tscn"
const SCENE_ELITE := "res://scenes/overlays/ElitePopup.tscn"
const SCENE_CRAFT_TRAY := "res://scenes/menus/CraftTray.tscn"
const SCENE_CODEX := "res://scenes/menus/ScrapCodex.tscn"
const SCENE_FEELS := "res://scenes/menus/FeelsLab.tscn"

## Pending run config
var selected_mode: int = GameModeBase.MODE_QUEST
var selected_difficulty: int = Difficulty.EASY
var start_level: int = 1
var last_score: Dictionary = {}
var returning_from_match: bool = false
var quest_level_index: int = 0
var quest_level_def: Dictionary = {}
var selected_booster: String = ""
var boosters := BoosterInventory.new()
var scrap_codex := ScrapCodex.new()
var replay_seed: int = 0


func _ready() -> void:
	var prog := SaveService.load_scrap_progress()
	if prog.has("boosters"):
		boosters.from_dict(prog.boosters)
	if prog.has("codex"):
		scrap_codex.from_dict(prog.codex)


func go(path: String) -> void:
	get_tree().change_scene_to_file(path)


func go_logo() -> void:
	go(SCENE_LOGO)


func go_main_menu() -> void:
	go(SCENE_MAIN_MENU)


func go_quest_map() -> void:
	go(SCENE_QUEST_MAP)


func go_mode_menu() -> void:
	go(SCENE_MODE_MENU)


func go_help() -> void:
	go(SCENE_HELP)


func go_countdown() -> void:
	go(SCENE_COUNTDOWN)


func go_start_at_10() -> void:
	go(SCENE_START_AT_10)


func go_match() -> void:
	go(SCENE_MATCH)


func go_end_game() -> void:
	go(SCENE_END_GAME)


func go_rate_it() -> void:
	go(SCENE_RATE_IT)


func go_about() -> void:
	go(SCENE_ABOUT)


func go_elite() -> void:
	go(SCENE_ELITE)


func go_craft_tray() -> void:
	go(SCENE_CRAFT_TRAY)


func go_codex() -> void:
	go(SCENE_CODEX)


func go_feels() -> void:
	go(SCENE_FEELS)


func begin_run(mode: int, difficulty: int, level: int = 1) -> void:
	selected_mode = mode
	selected_difficulty = difficulty
	start_level = level
	quest_level_def = {}
	selected_booster = ""
	Achievements.new_game(difficulty)
	RunSnapshot.clear()
	go_countdown()


func begin_quest_level(index: int) -> void:
	quest_level_index = index
	quest_level_def = LevelCatalog.get_level_by_index(index)
	selected_mode = GameModeBase.MODE_ZEN if bool(quest_level_def.get("zen", false)) else GameModeBase.MODE_QUEST
	selected_difficulty = Difficulty.MEDIUM
	start_level = index + 1
	selected_booster = ""
	replay_seed = int(SaveService.options.get("seed", 0))
	if replay_seed == 0:
		replay_seed = randi()
	Achievements.new_game(selected_difficulty)
	RunSnapshot.clear()
	go_craft_tray()


func begin_daily() -> void:
	quest_level_def = DailyDesk.level_for_today()
	quest_level_index = -1
	selected_mode = GameModeBase.MODE_QUEST
	selected_difficulty = Difficulty.MEDIUM
	start_level = 1
	selected_booster = ""
	RunSnapshot.clear()
	go_craft_tray()


func begin_zen() -> void:
	quest_level_def = LevelCatalog.get_level("zen")
	selected_mode = GameModeBase.MODE_ZEN
	selected_difficulty = Difficulty.HARD
	start_level = 1
	selected_booster = ""
	RunSnapshot.clear()
	go_countdown()

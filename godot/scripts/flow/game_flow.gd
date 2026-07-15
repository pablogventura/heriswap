extends Node

## Scene routing Autoload.

const SCENE_LOGO := "res://scenes/menus/Logo.tscn"
const SCENE_MAIN_MENU := "res://scenes/menus/MainMenu.tscn"
const SCENE_MODE_MENU := "res://scenes/menus/ModeMenu.tscn"
const SCENE_HELP := "res://scenes/menus/Help.tscn"
const SCENE_COUNTDOWN := "res://scenes/menus/CountDown.tscn"
const SCENE_START_AT_10 := "res://scenes/menus/StartAt10.tscn"
const SCENE_MATCH := "res://scenes/match/MatchRoot.tscn"
const SCENE_END_GAME := "res://scenes/menus/EndGame.tscn"
const SCENE_RATE_IT := "res://scenes/overlays/RateIt.tscn"
const SCENE_ABOUT := "res://scenes/overlays/AboutUs.tscn"
const SCENE_ELITE := "res://scenes/overlays/ElitePopup.tscn"

## Pending run config
var selected_mode: int = 0 ## 0 Normal, 1 TilesAttack, 2 Go100Seconds
var selected_difficulty: int = Difficulty.EASY
var start_level: int = 1
var last_score: Dictionary = {}
var returning_from_match: bool = false


func go(path: String) -> void:
	get_tree().change_scene_to_file(path)


func go_logo() -> void:
	go(SCENE_LOGO)


func go_main_menu() -> void:
	go(SCENE_MAIN_MENU)


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


func begin_run(mode: int, difficulty: int, level: int = 1) -> void:
	selected_mode = mode
	selected_difficulty = difficulty
	start_level = level
	Achievements.new_game(difficulty)
	RunSnapshot.clear()
	go_countdown()

extends Node2D

class_name Constants

# Paths
const PLAYER_PREFS_PATH := "/root/PlayerPrefs"
const GAME_MANAGER_PATH := "/root/GameManager"
const FARM_MANAGER_PATH := "/root/FarmManager"
const MAIN_WAVES_PATH := "res://meta/waves.json"
const DEBUG_SCENE_PATH := "res://scenes/levels/debug_room.tscn"

# Map data
const STANDARD_TILEMAP_SIZE := Vector2(16, 16)

# Enums
enum BusEvents {
	TOWER_SELECTED
}

enum TowerTargetMode {
	FIRST,
	RANDOM,
	LOWEST_HEALTH,
	HIGHEST_HEALTH,
	LAST
}

enum InputMode {
	CONTROLLER,
	KEYBOARD
}

enum EventLevel {
	INFO,
	WARNING,
	ERROR,
	GOOD,
	META
}

enum LogLevel {
	INFO,
	WARNING,
	ERROR,
	DEBUG
}

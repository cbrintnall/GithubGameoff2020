extends Node2D

class_name Constants

const PLAYER_PREFS_PATH = "/root/PlayerPrefs"

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

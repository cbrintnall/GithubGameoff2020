extends MarginContainer

signal close

class_name TowerDisplay

onready var remove_button = get_node("VBoxContainer/MarginContainer/Button")
onready var target_selector = get_node("VBoxContainer/MarginContainer2/OptionButton")

var _tower: Tower
var _text_to_mode := {
	"First": Constants.TowerTargetMode.FIRST,
	"Last": Constants.TowerTargetMode.LAST,
	"Random": Constants.TowerTargetMode.RANDOM,
	"Lowest Health": Constants.TowerTargetMode.LOWEST_HEALTH,
	"Highest Health": Constants.TowerTargetMode.HIGHEST_HEALTH,
}

func set_tower(tower: Tower):
	_tower = tower

	# TODO: close the panel, and the parent panel.
	if !_tower:
		return

	target_selector.visible = tower.uses_targetting
	target_selector.select(_tower._target_mode)
	
	_setup_upgrades()
	
func _setup_upgrades():
	print(_tower.get_upgrades())

func _target_mode_selected(mode: int):
	if !_tower:
		return
		
	_tower.set_to_target_mode(mode)

func _on_remove_tower():
	if !_tower:
		return
		
	_tower.destroy_tower()
	emit_signal("close")

func _ready():
	remove_button.connect("button_down", self, "_on_remove_tower")
	target_selector.connect("item_selected", self, "_target_mode_selected")
	
	_initialize_target_modes()

func _initialize_target_modes():
	for mode in _text_to_mode:
		target_selector.add_item(mode, _text_to_mode[mode])

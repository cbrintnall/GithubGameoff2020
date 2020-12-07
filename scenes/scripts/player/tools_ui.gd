extends CanvasLayer

signal tower_selected(tower)
signal tower_purchase_failed

export(AudioStream) var revoke_selection
export(AudioStream) var choose_selection

onready var audio = get_node("AudioStreamPlayer")
onready var game_manager = get_node("/root/GameManager")
onready var tween := get_node("Tween")
onready var selection_tween := get_node("SelectionTween")
onready var tower_base = get_node("MarginContainer/HBoxContainer")

var input_handler

var _icon_selection_height := 20
var _idx_to_key := {}
var _key_to_idx := {
	KEY_1: 1,
	KEY_2: 2,
	KEY_3: 3,
	KEY_4: 4,
	KEY_5: 5,
	KEY_6: 6,
	KEY_7: 7
}

var _selected_idx := 0
var _instances := {}
var _tower_selector = preload("res://scenes/towers/tower_selector.tscn")
var _selected
var _controller_selection := false

func purchase_done():
	if _selected:
		_revert_height_on_icon(_selected)
		_selected = null

func register_tower(key, tower: PackedScene):
	_idx_to_key[key] = tower
	_set_all_prices()

func _ready():
	# since we have some dummy values for building the UI
	# we clear them before we initialize
	_clear_selectors()
	
	input_handler = get_node(Constants.PLAYER_PREFS_PATH).get_input_handler()
	input_handler.connect("input_mode_changed", self, "_on_input_mode_changed")

	_on_input_mode_changed(input_handler.input_mode)

# todo: if we ever add unlocking towers as we 
func _on_input_mode_changed(mode):
	_controller_selection = mode == Constants.InputMode.CONTROLLER
	
	if _controller_selection:
		for instance in _instances.values():
			instance.show_button_hint(false)
			
		if len(_instances.values()) > 0:
			_instances.values()[_selected_idx].set_controller_selected(false)
			_selected_idx = 0
			_instances.values()[_selected_idx].set_controller_selected(true)
	else:
		for instance in _instances.values():
			instance.show_button_hint(true)
			instance.set_controller_selected(false)

func _revert_height_on_icon(instance):
	var duration = .25
	
	# prevents the selectors from flying off and tweening too far
	if selection_tween.is_active():
		selection_tween.stop_all()
		tower_base.queue_sort()
	
	selection_tween.interpolate_property(
		instance,
		"rect_position",
		instance.rect_position,
		instance.rect_position + (Vector2.DOWN * _icon_selection_height),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	selection_tween.start()

func _create_new_slot(key, tower: PackedScene):
	pass
	
func _set_all_prices():
	for i in range(0, tower_base.get_child_count()):
		tower_base.get_child(i).queue_free()
	
	var count := 0
	for i in _idx_to_key:
		var instance = _idx_to_key[i].instance()
		var selector = _tower_selector.instance()

		if count == _selected_idx and _controller_selection:
			selector.set_controller_selected(true)

		selector.set_price(instance.value)
		selector.set_key(str(_key_to_idx[i]))
		selector.set_texture(instance.icon_texture)
		selector.show_button_hint(!_controller_selection)
		
		tower_base.add_child(selector)
		
		_instances[_idx_to_key[i]] = selector
		
		# i am lazy
		count += 1

func _unhandled_input(event):
	if _controller_selection:
		if event.is_action_pressed("select_next_alt"):
			_instances.values()[_selected_idx].set_controller_selected(false)
			_selected_idx = int(
				clamp(_selected_idx+1, 0, _idx_to_key.values().size()-1)
			)
			_instances.values()[_selected_idx].set_controller_selected(true)

		if event.is_action_pressed("select_previous_alt"):
			_instances.values()[_selected_idx].set_controller_selected(false)
			_selected_idx = int(
				clamp(_selected_idx-1, 0, _idx_to_key.values().size()-1)
			)
			_instances.values()[_selected_idx].set_controller_selected(true)

		if event.is_action_pressed("select_next"):
			_do_purchase_tower(
				_idx_to_key.values()[_selected_idx]
			)

	if event is InputEventKey:
		if event.pressed and _idx_to_key.has(event.scancode):
			_do_purchase_tower(_idx_to_key[event.scancode])

func _do_purchase_tower(tower: PackedScene):
	if tower.instance().value > game_manager.get_farm_manager().current_lunar_rocks:
		_do_cant_purchase_tween(_instances[tower])
		emit_signal("tower_purchase_failed")
		return
	
	# if we selected something, lower it
	if _selected:
		_revert_height_on_icon(_selected)

	# if what is selected is the same, we wipe out our selection
	if _selected != _instances[tower]:
		_selected = _instances[tower]
		_do_purchasing_tween(_selected)
		audio.pitch_scale = 1.0
		audio.stream = choose_selection
		audio.play()
	else:
		_selected = null
		audio.pitch_scale = .75
		audio.stream = choose_selection
		audio.play()

	# todo: make this emit null, and have the player queue free
	# on their current tower. that way full selection control
	# comes from this node
	emit_signal("tower_selected", tower)
	
func _clear_selectors():
	for i in range(0, tower_base.get_child_count()):
		tower_base.get_child(i).queue_free()

func _do_purchasing_tween(instance):
	var duration = .25

	# prevents the selectors from flying off and tweening too far
	if selection_tween.is_active():
		selection_tween.stop_all()
		tower_base.queue_sort()

	selection_tween.interpolate_property(
		instance,
		"rect_position",
		instance.rect_position,
		instance.rect_position + (Vector2.UP * _icon_selection_height),
		duration,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	selection_tween.start()

func _do_cant_purchase_tween(instance):
	if tween.is_active():
		return

	var duration = .125
	var previous_color = instance.modulate
	tween.interpolate_property(
		instance,
		"rect_scale",
		Vector2.ONE,
		Vector2.ONE * 1.1,
		duration/2,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.interpolate_property(
		instance,
		"modulate",
		instance.modulate,
		Color.red,
		duration/2,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.start()
	yield(tween,"tween_all_completed")
	tween.interpolate_property(
		instance,
		"rect_scale",
		instance.rect_scale,
		Vector2.ONE,
		duration/2,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.interpolate_property(
		instance,
		"modulate",
		Color.red,
		previous_color,
		duration/2,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	tween.start()

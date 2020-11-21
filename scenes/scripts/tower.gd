extends StaticBody2D

signal state_changed(new_state)
signal new_target(target)
signal lost_target(target)

class_name Tower

enum TowerState {
	INVALID_PLACEMENT,
	PURCHASING,
	UNCHARGED,
	CHARGING,
	CHARGED,
	FIRING
}

const target_detectable_bit = 18
const cant_place_bit = 17

# All tower parameters
export(String) var tower_name = "Tower"
export(float) var value = 100.0
export(float) var damage_per_hit = 10
export(float) var charge_time = 2.5
export(AudioStream) var shoot_audio
export(AudioStream) var charging_audio
export(Texture) var icon_texture
export(NodePath) var ui_parent
export(NodePath) onready var no_place_area = get_node(no_place_area) as Area2D
export(NodePath) onready var collision_zone = get_node(collision_zone)
export(NodePath) onready var vision_area = get_node(vision_area) as Area2D
export(NodePath) onready var animation = get_node(animation)

onready var audio_player = get_node("VariableNodes/ChargeAudio")
onready var vision_child: CollisionShape2D

var damage_multiplier := 1
var charge_timer = Timer.new()
var state: int = TowerState.UNCHARGED
var targets := []

var _line_wind_down_time = .5
var _draw_vision := false
var _ui_parent

func in_world() -> bool:
	return state != TowerState.PURCHASING and state != TowerState.INVALID_PLACEMENT

func get_texture() -> Texture:
	return null

func purchase():
	_set_state(TowerState.UNCHARGED)
	
	no_place_area.get_node("CollisionShape2D").disabled = true

func can_place() -> bool:
	return state != TowerState.INVALID_PLACEMENT

func set_damage_multiplier(amt):
	damage_multiplier = amt
	
func reset_damage_multiplier():
	damage_multiplier = 1

func on_action_hover():
	_draw_vision = true

func on_action_leave():
	_draw_vision = false

func add_target(target):
	targets.append(target)
	emit_signal("new_target", target)

func use():
	if in_world():
		_ui_parent.visible = true

func destroy_tower():
	queue_free()

func _ready():
	vision_area.connect("body_entered", self, "_on_target_enter")
	vision_area.connect("body_exited", self, "_on_target_exit")
	vision_area.set_collision_layer_bit(0, false)
	vision_area.set_collision_mask_bit(0, false)
	vision_area.set_collision_mask_bit(target_detectable_bit, true)
	
	for i in range(0, vision_area.get_child_count()):
		var child = vision_area.get_child(i)
		
		if child is CollisionShape2D:
			vision_child = child
			break
	
	charge_timer.connect("timeout", self, "_on_finish_charging")
	
	no_place_area.connect("body_entered", self, "_on_collision_enter")
	no_place_area.connect("body_exited", self, "_on_collision_exit")
	no_place_area.connect("area_entered", self, "_on_collision_enter")
	no_place_area.connect("area_exited", self, "_on_collision_exit")
	no_place_area.collision_layer = 0
	no_place_area.collision_mask = 0
	no_place_area.set_collision_layer_bit(cant_place_bit, true)
	no_place_area.set_collision_mask_bit(cant_place_bit, true)

	add_child(charge_timer)
	charge_timer.wait_time = charge_time
	charge_timer.one_shot = true
	
	if ui_parent:
		_ui_parent = get_node(ui_parent)
		
		_ui_parent.visible = false
		_ui_parent.connect("remove_tower", self, "destroy_tower")
	
	_set_state(TowerState.PURCHASING)

func _on_collision_exit(body):
	_set_state(TowerState.PURCHASING)

func _on_collision_enter(body):
	_set_state(TowerState.INVALID_PLACEMENT)

# handle state initialization here
func _set_state(_state):
	match _state:
		TowerState.UNCHARGED:
			pass
		TowerState.CHARGED:
			pass
		TowerState.FIRING:
			pass
		TowerState.PURCHASING:
			var color = Color.aqua
			color.a = .4
			modulate = color
			collision_zone.call_deferred("set_disabled", true)
		TowerState.CHARGING:
			pass
		TowerState.INVALID_PLACEMENT:
			var color = Color.red
			color.a = .4
			modulate = color
	
	if _state != TowerState.PURCHASING and _state != TowerState.INVALID_PLACEMENT:
		modulate = Color.white
		collision_zone.call_deferred("set_disabled", false)
	
	state = _state
	emit_signal("state_changed", state)

# meant to be overwritten, is a noop
func _charge():
	_set_state(TowerState.CHARGING)
	charge_timer.start()

func _get_random_target():
	return targets[int(floor(rand_range(0, len(targets)-1)))]

func _on_finish_charging():
	animation.play("default")
	state = TowerState.CHARGED

func _on_target_enter(body: PhysicsBody2D):
	add_target(body)
	
func _on_target_exit(body):
	if body in targets:
		targets.erase(body)
		emit_signal("lost_target", body)

func _overlaps_cant_place():
	return len(no_place_area.get_overlapping_areas()) > 0 or len(no_place_area.get_overlapping_bodies()) > 0

func _physics_process(delta):
	if state != TowerState.INVALID_PLACEMENT and _overlaps_cant_place():
		_set_state(TowerState.INVALID_PLACEMENT)

func _do_fire():
	pass

func _process(delta):
	if state == TowerState.UNCHARGED:
		_charge()

	if state == TowerState.CHARGED and len(targets) > 0:
		_do_fire()

	update()

func _draw():
	if _draw_vision:
		if vision_child.shape is CircleShape2D:
			draw_arc(Vector2.ZERO, vision_child.shape.radius, 0, 540, 30, Color.white)

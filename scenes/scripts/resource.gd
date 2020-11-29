extends Area2D

signal destroyed(Node2D)
signal finished_growing

export(Resource) var inner_resource

onready var on_break_audio_stream: AudioStreamPlayer2D = get_node("onbreak")
onready var sprite: Sprite = get_node("ground_resource")
onready var label: Label = get_node("LabelParent/Label")
onready var particles: CPUParticles2D = get_node("Particles2D")
onready var grow_tween: Tween = get_node("Tween")

var grown: bool
var entered: bool

var _destroyed:bool

func _ready():
	label.visible = false
	label.text = inner_resource.ground_resource_name
	
	particles.texture = inner_resource.normal_texture

	sprite.texture = inner_resource.normal_texture
	
	if inner_resource.on_break:
		on_break_audio_stream.stream = inner_resource.on_break
	
	grow_tween.interpolate_property(
		self,
		"scale",
		Vector2(1, 0),
		Vector2.ONE,
		1.0,
		Tween.TRANS_LINEAR
	)
	
	grow_tween.start()
	
	yield(grow_tween,"tween_all_completed")
	
	grown = true
	emit_signal("finished_growing")
	
func on_action_hover():
	if !grown:
		yield(self, "finished_growing")
		
	sprite.texture = inner_resource.hovered_texture
	# TODO: evaluate if we want to keep this
#	label.visible = true
	label.text = inner_resource.ground_resource_name
	entered = true
	
func on_action_leave():
	if !grown:
		yield(self, "finished_growing")

	sprite.texture = inner_resource.normal_texture
	label.visible = false
	entered = false

func use():
	if _destroyed:
		return

	on_break_audio_stream.play() 
	particles.emitting = true
	emit_signal("destroyed", self)
	_destroyed = true
	
	grow_tween.interpolate_property(
		self,
		"modulate",
		Color.white,
		Color.transparent,
		particles.lifetime,
		Tween.TRANS_LINEAR
	)
	
	grow_tween.start()
	
	yield(grow_tween,"tween_all_completed")

	queue_free()

func get_loot_table() -> Dictionary:
	return inner_resource.drop_table

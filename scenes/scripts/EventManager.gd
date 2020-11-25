extends CanvasLayer

export(float) var label_time = 1.0
export(AudioStream) var warning_sound

onready var audio_player = get_node("AudioStreamPlayer")
onready var base_label = get_node("Control/VBoxContainer/BaseLabel")
onready var events_base = get_node("Control/VBoxContainer")
onready var tree = get_tree()

const event_limit = 15
const level_to_color := {
	Constants.EventLevel.INFO: Color.white,
	Constants.EventLevel.WARNING: Color.yellow,
	Constants.EventLevel.GOOD: Color.greenyellow,
	Constants.EventLevel.META: Color("#18d8ed")
}

func new_message(
	message: String,
	importance = Constants.EventLevel.INFO,
	timer_override = -1
):
	var timer_time = timer_override
	if timer_override == -1:
		timer_time = label_time
	
	var new_label = base_label.duplicate()
	var color = level_to_color[importance]
	
	new_label.visible = true
	new_label.text = message
	new_label.modulate = color
	
	if importance == Constants.EventLevel.WARNING:
		audio_player.stream = warning_sound
		audio_player.play()
	
	events_base.add_child(new_label)
	
	yield(tree.create_timer(timer_time),"timeout")
	var t = Tween.new()
	add_child(t) 
	t.interpolate_property(
		new_label,
		"modulate",
		color,
		Color.transparent,
		.5,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	t.interpolate_property(
		new_label,
		"rect_position",
		new_label.rect_position,
		new_label.rect_position + (Vector2.RIGHT * new_label.rect_size.x),
		.5,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN
	)
	t.start()
	yield(t,"tween_all_completed")
	t.queue_free()
	new_label.queue_free()

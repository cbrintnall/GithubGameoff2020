extends Area2D

export(NodePath) var usable
export(String) var text
export(String) var run_command

onready var animation = get_node("AnimatedSprite")

func _ready():
	if text:
		$Label.text = text

func on_action_hover():
	pass
	
func on_action_leave():
	pass
	
func use():
	if usable:
		var usable_node = get_node(usable)
		
		if usable_node and usable_node.has_method("use"):
			usable_node.use()
	elif run_command:
		$"/root/PlayerPrefs".run_command(run_command)

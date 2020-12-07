extends Area2D

export(NodePath) var usable

onready var animation = get_node("AnimatedSprite")

func on_action_hover():
	pass
	
func on_action_leave():
	pass
	
func use():
	var usable_node = get_node(usable)
	
	if usable_node and usable_node.has_method("use"):
		usable_node.use()

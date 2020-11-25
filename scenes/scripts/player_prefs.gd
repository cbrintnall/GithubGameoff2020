extends Node2D

const schema := {}

onready var console = get_node("DebugUi")

func get_input_handler():
	return get_node("InputHandler")

func register_command(command, method):
	console.commands[command] = method

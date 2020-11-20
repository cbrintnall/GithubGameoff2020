extends Node2D

const schema := {}

onready var console = get_node("CanvasLayer")

func register_command(command, method):
	console.commands[command] = method

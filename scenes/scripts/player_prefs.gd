extends Node2D

onready var console = get_node("DebugUi")

func get_input_handler():
	return get_node("InputHandler")

func register_command(command, method):
	console.commands[command] = method

func run_command(command: String):
	console._handle_command(command)

func _ready():
	_register_default_commands()

func _register_default_commands():
	register_command("scene", funcref(self, "_load_scene"))

func _load_scene(args := []):
	print(args)
	match args:
		[ "change", var path ]:
			var _ok := get_tree().change_scene(path)

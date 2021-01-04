extends Node2D

onready var console = get_node("DebugUi")

func get_input_handler():
	return get_node("InputHandler")

func register_command(command, method):
	console.commands[command] = method

func run_command(command: String):
	console._handle_command(command)

func write(text: String, level = Constants.LogLevel.INFO, clear := true):
	console.write_output(text, level, clear)

func _ready():
	_register_default_commands()

func _register_default_commands():
	register_command("clear", funcref(self, "_clear_output"))
	register_command("scene", funcref(self, "_load_scene"))
	register_command("commands", funcref(self, "_print_commands"))
	
func _clear_output(args := []):
	console.clear()

func _print_commands(args := []):
	for command in console.commands:
		write(command, Constants.LogLevel.DEBUG, false)

func _load_scene(args := []):
	match args:
		[ "change", var path ]:
			var _ok := get_tree().change_scene(path)

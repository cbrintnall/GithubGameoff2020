extends CanvasLayer

onready var how_to_play = get_node("HowToPlay")
onready var tween = get_node("Tween")
onready var moon_tween = get_node("MoonTween")
onready var music_player = get_node("Music")
onready var button_hover = get_node("AudioStreamPlayer")
onready var play_button = get_node("MarginContainer2/VBoxContainer/PlayButton/TextureButton")
onready var options_button = get_node("MarginContainer2/VBoxContainer/OptionsButton/TextureButton")
onready var quit_button = get_node("MarginContainer2/VBoxContainer/QuitButton/TextureButton")
onready var how_to_play_button = get_node("MarginContainer2/VBoxContainer/HowToPlayButton/TextureButton")
onready var buttons_base = get_node("MarginContainer2/VBoxContainer")
onready var play_button_base = get_node("MarginContainer2/VBoxContainer/PlayButton")
onready var options_button_base = get_node("MarginContainer2/VBoxContainer/OptionsButton")
onready var quit_button_base = get_node("MarginContainer2/VBoxContainer/QuitButton")

var how_to_base:Vector2

func _ready():
	var tree = get_tree()
	var prefs_base = get_node(Constants.PLAYER_PREFS_PATH)
	
	play_button.connect("button_down", tree, "change_scene", [ "res://scenes/ui/Intro.tscn" ])
	quit_button.connect("button_down", tree, "quit")
	options_button.connect("button_down", get_node("PlayerPrefs/PlayerPreferences/MarginContainer"), "set_visible", [ true ])
	play_button.connect("mouse_entered", button_hover, "play")
	quit_button.connect("mouse_entered", button_hover, "play")
	options_button.connect("mouse_entered", button_hover, "play")
	how_to_play_button.connect("mouse_entered", button_hover, "play")

	prefs_base.register_command("generate", funcref(self, "_on_generate"))
	
	var args = OS.get_cmdline_args()

	if len(args) > 0:
		prefs_base.run_command(args.join(" "))
		
	music_player.connect("finished", music_player, "play")
	
	how_to_base = Vector2(
		how_to_play.rect_position.x - (how_to_play.rect_size.x*2),
		how_to_play.rect_position.y
	)

	how_to_play.rect_position = how_to_base
	how_to_play_button.connect("button_down", self, "_show_how_to_play")
	
func _show_how_to_play():
	if !how_to_play.visible:
		how_to_play.visible = true
		tween.interpolate_property(
			how_to_play,
			"rect_position",
			how_to_base,
			how_to_base + (Vector2.RIGHT * (how_to_play.rect_size.x)),
			0.5,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
		
		tween.start()
	else:
		tween.interpolate_property(
			how_to_play,
			"rect_position",
			how_to_play.rect_position,
			how_to_base,
			0.5,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)

		tween.start()
		
		yield(tween,"tween_all_completed")
		how_to_play.visible = false

func _on_generate(args: Array):
	var resource_initializer = get_node("ResourceInitializer")

	match args:
		[ "crops" ]:
			resource_initializer.create_crop_resource("res://meta/crops.json")
		[ "plants" ]:
			resource_initializer.create_plant_resource("res://meta/plants.json")
		[ "seeds" ]:
			resource_initializer.create_seed_resource("res://meta/seeds.json")
		[ "resources" ]:
			resource_initializer.create_ground_resource("res://meta/resources.json")
		[ "all" ]:
			resource_initializer.create_crop_resource("res://meta/crops.json")
			resource_initializer.create_plant_resource("res://meta/plants.json")
			resource_initializer.create_seed_resource("res://meta/seeds.json")
			resource_initializer.create_ground_resource("res://meta/resources.json")
		[ var cmd, "quit" ]:
			_on_generate([ cmd ])
			get_tree().quit(0)
		[ "debug" ]:
			get_tree().change_scene("res://scenes/farm.tscn")

func _make_visible(button, second):
	button.visible = true

func _unhandled_input(event):
	# if how to play is open, back out
	if event.is_action_pressed("cancel_selection") and how_to_play.visible:
		_show_how_to_play()

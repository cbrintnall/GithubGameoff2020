extends Node2D

const screenshots_base := "user://screenshots/"
const screenshot_default_name := "screenshot"

onready var viewport = get_viewport()

func _save_screenshot():
	var screenshot_dir = Directory.new()
	
	if !screenshot_dir.dir_exists(screenshots_base):
		screenshot_dir.make_dir(screenshots_base)

	var date = "_{day}_{month}_{year}".format(OS.get_date())
	var time = "_{hour}_{minute}_{second}".format(OS.get_time())
	var image_name = screenshots_base + screenshot_default_name + date + time + ".png"
	var img = get_viewport().get_texture().get_data()

	img.flip_y()
	img.save_png(image_name)

func _input(event):
	if event.is_action_pressed("screenshot"):
		_save_screenshot()

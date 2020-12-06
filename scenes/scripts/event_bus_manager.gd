extends Node2D

signal new_event

func send_event(event_name: int, event_data := {}):
	emit_signal("new_event", event_name, event_data)

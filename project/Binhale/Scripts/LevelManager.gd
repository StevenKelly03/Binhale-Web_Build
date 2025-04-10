extends Node

var current_level = 1 

func set_level(level: int) -> void:
	current_level = level

func get_current_level() -> int:
	return current_level

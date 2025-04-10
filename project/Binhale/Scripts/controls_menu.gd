extends Node2D

func _on_back_pressed():
	$ButtonSound.play()
	await $ButtonSound.finished
	get_tree().change_scene_to_file("res://Binhale/Scenes/main_menu.tscn")

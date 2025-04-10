extends Area2D
var player

var level1Path = "res://Binhale/Scenes/Level1.tscn"
var level2Path = "res://Binhale/Scenes/Level2.tscn"
var level3Path = "res://Binhale/Scenes/Level3.tscn"

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	self.body_entered.connect(_on_body_entered) #connect body entered signal to handler function

func _on_body_entered(body):
	if body.is_in_group("Player"):
		call_deferred("_progress_level")
			
func _progress_level():
	if player.get_current_level() == "Level1":
		player._make_invis()
		get_tree().current_scene._play_bus_drive_away()
		await get_tree().create_timer(1.75).timeout
		get_tree().change_scene_to_file(level3Path)
	elif player.get_current_level() == "Level2":
		player._make_invis()
		get_tree().current_scene._play_bus_drive_away()
		await get_tree().create_timer(1.75).timeout
		get_tree().change_scene_to_file(level1Path)
	elif player.get_current_level() == "Level3":
		player._make_invis()
		get_tree().current_scene._play_bus_drive_away()
		await get_tree().create_timer(1.75).timeout
		get_tree().change_scene_to_file(level2Path)

extends Node2D

@onready var area = $Area2D #get area2d from hierarchy
@onready var soundPlayer = $Sound

var interface #variable to track the UI node in hierarchy
var value = 25 #value of generic consumable

func _ready() -> void:
	var level_name = get_tree().current_scene.name
	var level_number_str = level_name.substr(5, level_name.length() - 5)
	var level_number = int(level_number_str)

	var level = get_tree().root.get_node("Level" + str(level_number)) #get current scene from hierarchy
	
	soundPlayer.stream = load("res://Binhale/Assets/Audio/Other/pickup.mp3")
	soundPlayer.volume_db = -5
	
	if level == null:
		print("level node not found")
		return
	
	interface = level.get_node("Canvas/ScoreCounter")
	
	if interface == null:
		print("ui node not found")
		return
		
	area.body_entered.connect(_on_body_entered) #connect body entered signal to handler function

func _on_body_entered(body):
	if body.is_in_group("Player"):
		ScoreManager.increment_score(value)
		interface.update_score_display()
		
		soundPlayer.play()
		self.visible = false		
		await soundPlayer.finished
		queue_free()
		queue_free()

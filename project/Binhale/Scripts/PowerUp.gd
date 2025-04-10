extends Node2D

var hoverHeight = 4
var hoverSpeed = randf_range(1.5, 3.5)
var time = 0.0

var interface
var current_level
var value = 50

@onready var sprite = $Sprite2D
@onready var area = $Area2D
@onready var soundPlayer = $Sound

var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	soundPlayer.stream = load("res://Binhale/Assets/Audio/Other/power_up.mp3")
	soundPlayer.volume_db = -5
	
	var level_name = get_tree().current_scene.name
	var level_number_str = level_name.substr(5, level_name.length() - 5)
	var level_number = int(level_number_str)

	current_level = get_tree().root.get_node("Level" + str(level_number))
	
	if current_level == null:
		print("Level node not found")
		return
	
	interface = current_level.get_node("Canvas/ScoreCounter")
	
	if interface == null:
		print("UI node not found")
		return
	
	area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta
	sprite.position.y = sin(time * hoverSpeed) * hoverHeight

func _on_body_entered(body):
	print("Body entered: ", body.name)
	if body.is_in_group("Player"):
		soundPlayer.play()
		ScoreManager.increment_score(value)
		interface.update_score_display()
		
		if self.is_in_group("Vape"):
			player.on_collect_powerup("smoke")
			player.switch_power("Smoke")
		elif self.is_in_group("Lighter"):
			player.on_collect_powerup("fire")
			player.switch_power("Fire")
		elif self.is_in_group("Battery"):
			player.on_collect_powerup("electricity")
			player.switch_power("Electricity")
		
		self.visible = false
		self.set_process(false)
		
		await soundPlayer.finished
		queue_free()

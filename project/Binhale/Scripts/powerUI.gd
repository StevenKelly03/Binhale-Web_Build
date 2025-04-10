extends Node

@onready var sprite = self
var last_power = -1

#textures for UI Power
var fire_texture = preload("res://Binhale/Assets/AnimationFrames/Powers/Fire/FB500-1.png")
var smoke_texture = preload("res://Binhale/Assets/AnimationFrames/Powers/Smoke/smoke3.png")
var electricity_texture = preload("res://Binhale/Assets/AnimationFrames/Powers/Electricity/lightning_skill5_frame3.png")
var null_texture = preload("res://Binhale/Assets/AnimationFrames/Powers/none.png")

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	var current_power = get_tree().get_first_node_in_group("Player").get_current_power() #get current power from player object

#set texture based on current equipped ppower
	if current_power != last_power:
		match current_power:
			0:
				sprite.texture = fire_texture
				sprite.scale.x = 0.3
				sprite.scale.y = 0.3
			1:
				sprite.texture = smoke_texture
				sprite.scale.x = 0.5
				sprite.scale.y = 0.5
			2:
				sprite.texture = electricity_texture
				sprite.scale.x = 1
				sprite.scale.y = 1
			3:
				sprite.texture = null_texture
				sprite.scale.x = 0.2
				sprite.scale.y = 0.2
		last_power = current_power

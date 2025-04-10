extends Node2D

@onready var healthbar = $Canvas/EnvironmentHealth #progress bar node for environment health
@onready var particles = $CPUParticles2D
@onready var ember_sprite = preload("res://Binhale/Assets/Environment/ember.png")
@onready var background_image_path = preload("res://Binhale/Assets/Backgrounds/forestBackground.jpg")
@onready var tilemap = $TileMap
@onready var door_collision = $Boundaries/RightBoundary
@onready var bus_animation = $Bus/AnimationPlayer
@onready var bus = $Bus

var max_health = 100
var current_health = max_health
var damage_amount = (100/6)
var power_usage = 0
var overlay_rect : Rect2
var overlay_opacity = 0.0
var enemies_remaining: int = 0  # Initialize to 0
var door_position: Vector2i = Vector2i(120, 55)

func _ready():
	var game_over_screen = load("res://Binhale/Scenes/GameOver.tscn").instantiate()
	
	game_over_screen.set_background_image(background_image_path)
	bus._play_arrival_sound()
	
	# Create a 2-second timer before playing the bus animation
	var timer = get_tree().create_timer(2.0)
	await timer.timeout
	bus_animation.play("Drive")
	
	MenuMusicManager.changeVolume(-20)
	update_healthbar()
	overlay_rect = Rect2(Vector2.ZERO, get_viewport().size)
	
	# Count and connect to all enemies
	enemies_remaining = 0  # Reset count
	
	# Count StillEnemies
	var still_enemies = get_tree().get_nodes_in_group("StillEnemy")
	enemies_remaining += still_enemies.size()
	for enemy in still_enemies:
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", _on_enemy_died)
	
	# Count FollowingEnemies
	var following_enemies = get_tree().get_nodes_in_group("FollowingEnemy")
	enemies_remaining += following_enemies.size()
	for enemy in following_enemies:
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", _on_enemy_died)
	
	print("Initial enemy count: ", enemies_remaining)  # Debug print

func _process(_delta):
	pass

func use_power():
	# increase power usage count
	var previous_power_usage = power_usage
	power_usage += 1

	if(power_usage == 2):
		change_particle_sprite()
	if(power_usage == 3):
		particles.amount = 60
	apply_environmental_damage()

func apply_environmental_damage():
	# reduce health if power is overused
	current_health -= damage_amount
	current_health = max(current_health, 0)
	update_healthbar()
	if current_health == 0:
		environmental_collapse()

func update_healthbar():
	# set healthbar value
	healthbar.value = float(current_health) / max_health * 100
	
	# get fill style
	var stylebox: StyleBoxFlat = healthbar.get("theme_override_styles/fill")

	if stylebox:
		# get health ratio
		var health_ratio = float(current_health) / max_health
		var new_color = Color(0, 1, 0) # green default

		if health_ratio > 0.5:
			# green to yellow
			new_color = Color(1, 1, 0).lerp(Color(0, 1, 0), (health_ratio - 0.5) * 2)
		elif health_ratio > 0.2:
			# yellow to red
			new_color = Color(1, 0, 0).lerp(Color(1, 1, 0), (health_ratio - 0.2) * (10/3))
		else:
			# danger, deep red
			new_color = Color(0.6, 0, 0)

		# apply color
		stylebox.bg_color = new_color

func change_particle_sprite():
	if particles and ember_sprite:
		particles.texture = ember_sprite

func environmental_collapse():
	var timer = get_tree().create_timer(2.5)
	await timer.timeout
	get_tree().change_scene_to_file("res://Binhale/Scenes/GameOver.tscn")
	print("environment destroyed")

func _draw():
	if overlay_opacity > 0:
		draw_rect(overlay_rect, Color(0, 0, 0, overlay_opacity), true)

func update_overlay_opacity():
	if power_usage > 0:
		overlay_opacity = min(overlay_opacity + 0.1, 1.0)

func _on_enemy_died():
	enemies_remaining -= 1
	print("Enemy died. Remaining: ", enemies_remaining)  # Debug print
	if enemies_remaining <= 0:
		print("All enemies defeated, opening door...")  # Debug print
		open_door()

func open_door():
	var door_sound = AudioStreamPlayer2D.new()
	door_sound.volume_db = 30
	door_sound.pitch_scale = 0.5
	door_sound.stream = preload("res://Binhale/Assets/Audio/Other/doorOpen.mp3")
	add_child(door_sound)
	door_sound.play()
	
	# Remove the door tiles
	tilemap.set_cell(0, Vector2i(120, 55), -1)
	tilemap.set_cell(0, Vector2i(121, 55), -1)
	tilemap.set_cell(0, Vector2i(120, 56), -1)
	tilemap.set_cell(0, Vector2i(121, 56), -1)

	
	# Adjust collision shape to allow passage
	if door_collision:
		door_collision.scale.y = 0.93  # Scale the Area2D instead of the shape
	
	await door_sound.finished
	door_sound.queue_free() 
	
func _play_bus_drive_away():
	bus._play_leaving_sound()
	bus_animation.play("DriveAway")

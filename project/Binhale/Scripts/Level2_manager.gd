extends Node2D

@onready var music_player = $AudioStreamPlayer2D
@onready var ambience = preload("res://Binhale/Assets/Audio/Ambience/underwater.mp3")
@onready var background_image_path = preload("res://Binhale/Assets/Backgrounds/Level2 .png")
@onready var particles = $CPUParticles2D
@onready var fish_sprite = preload("res://Binhale/Assets/Environment/ember.png")

@onready var healthbar = $Canvas/EnvironmentHealth
@onready var tilemap = $TileMap
@onready var door_collision = $Boundaries/RightBoundary/Collider
@onready var bus_animation = $Bus/AnimationPlayer
@onready var bus = $Bus

var player
var max_health = 100
var current_health = max_health
var damage_amount = (100/6)
var power_usage = 0
var overlay_rect : Rect2
var overlay_opacity = 0.0
var enemies_remaining: int = 0
var door_position: Vector2i = Vector2i(120, 55)
var damage_timer: Timer
var damage_interval = 1.0  # Damage every second

func _ready():
	particles.emitting = false
	
	var game_over_screen = load("res://Binhale/Scenes/GameOver.tscn").instantiate()
	game_over_screen.set_background_image(background_image_path)
	
	player = get_tree().get_first_node_in_group("Player")
	MenuMusicManager.changeVolume(-20)
	music_player.stream = ambience
	music_player.stream.loop = true
	music_player.play()
	
	bus._play_arrival_sound()
	
	# Create a 2-second timer before playing the bus animation
	var timer = get_tree().create_timer(2.0)
	await timer.timeout
	bus_animation.play("Drive")
	
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
			
	# Count FlyingEnemies
	var flying_enemies = get_tree().get_nodes_in_group("FlyingEnemy")
	enemies_remaining += flying_enemies.size()
	for enemy in flying_enemies:
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", _on_enemy_died)

	# Count BossEnemies
	var bossses = get_tree().get_nodes_in_group("BossEnemy")
	enemies_remaining += bossses.size()
	for enemy in bossses:
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", _on_enemy_died)
	
	print("Initial enemy count: ", enemies_remaining)  # Debug print - Final count including all enemy types
	
	# Setup damage timer
	damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)
	damage_timer.start()  # Start the timer, but damage will only apply when power is active

func use_power():
	pass

func _on_damage_timer_timeout():
	if player and player.get_electric_state():
		apply_environmental_damage()

func apply_environmental_damage():
	current_health -= damage_amount
	current_health = max(current_health, 0)
	update_healthbar()
	if current_health == 0:
		environmental_collapse()

func update_healthbar():
	healthbar.value = float(current_health) / max_health * 100
	
	var stylebox: StyleBoxFlat = healthbar.get("theme_override_styles/fill")

	if stylebox:
		var health_ratio = float(current_health) / max_health
		var new_color = Color(0, 1, 0)

		if health_ratio > 0.5:
			new_color = Color(1, 1, 0).lerp(Color(0, 1, 0), (health_ratio - 0.5) * 2)
		elif health_ratio > 0.2:
			new_color = Color(1, 0, 0).lerp(Color(1, 1, 0), (health_ratio - 0.2) * (10.0/3))
		else:
			new_color = Color(0.6, 0, 0)

		stylebox.bg_color = new_color
		
		# Start emitting particles when health reaches 50%
		if health_ratio <= 0.5 and not particles.emitting:
			particles.emitting = true

func environmental_collapse():
	var timer = get_tree().create_timer(2.5)
	await timer.timeout
	get_tree().change_scene_to_file("res://Binhale/Scenes/GameOver.tscn")

func _on_enemy_died():
	enemies_remaining -= 1
	print("Enemy died. Remaining: ", enemies_remaining)  # Debug print
	if enemies_remaining <= 0:
		print("All enemies defeated, opening door...")  # Debug print
		open_door()

func open_door():
	var door_sound = AudioStreamPlayer2D.new()
	door_sound.volume_db = 30
	door_sound.pitch_scale = 0.6
	door_sound.stream = preload("res://Binhale/Assets/Audio/Other/doorOpen.mp3")
	add_child(door_sound)
	door_sound.play()
	
	tilemap.set_cell(0, Vector2i(127, 55), -1)
	tilemap.set_cell(0, Vector2i(128, 55), -1)
	tilemap.set_cell(0, Vector2i(127, 56), -1)
	tilemap.set_cell(0, Vector2i(128, 56), -1)
	
	if door_collision:
		var area = door_collision.get_parent()
		if area:
			area.scale.y = 0.93
	
	await door_sound.finished
	door_sound.queue_free() 
	
func _play_bus_drive_away():
	bus._play_leaving_sound()
	bus_animation.play("DriveAway")

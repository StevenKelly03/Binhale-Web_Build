extends CharacterBody2D

@export var speed: float = 100.0 # enemy movement speed
@export var can_shoot: bool = false # whether the enemy can shoot
@export var fire_rate: float = 1.5 # delay between shots
@export var projectile_scene: PackedScene # scene for projectiles
@export var jump_speed: float = 225.0  # Jump speed for the enemy
@export var gravity: float = 200.0  # Gravity force
@export var value: int = 50
@export var flying_speed: float = 50.0  # Speed for flying enemies
@export var flying_amplitude: float = 20.0  # How much the flying enemy moves up and down
@export var target_y_position: float = 325.0  # Target Y position for flying enemies
@export var initial_y_position: float = 935.0 #starting y position for flying enemies
@export var activation_distance: float = 200.0  # Distance at which flying enemies activate
@export var left_boundary: float = 50.0  # Left boundary for flying enemies
@export var boss_jump_interval: float = 2.0  # How often the boss enemy jumps
@export var boss_hp: int = 5 # HP for boss enemies
@export var start_moving_right: bool = true  # Whether flying enemy starts moving right

var interface
var current_level
signal enemy_died

enum State { MOVING_LEFT, MOVING_RIGHT, IDLE, JUMPING, FLYING, FLYING_UP, WAITING } # possible enemy states

var current_state: State = State.IDLE # default state is idle
var player: Node2D = null # reference to the player
var time: float = 0.0  # Time counter for flying movement
var reached_target_y: bool = false  # Flag to track if flying enemy reached target Y
var original_collision_mask: int
var original_collision_layer: int
var current_hp: int = 1  # Current HP, default 1 for normal enemies
var jump_timer: Timer  # Timer for boss jumping

@onready var area = $EnemyArea # reference to area for collision detection
@onready var sprite = $EnemySprite # reference to enemy sprite
@onready var raycast_left = $RayCast_Left # raycast to detect obstacles to the left
@onready var raycast_right = $RayCast_Right # raycast to detect obstacles to the right
@onready var shoot_timer: Timer = $ShootTimer if has_node("ShootTimer") else null # shoot timer for enemies that shoot
@onready var initial_delay_timer: Timer = Timer.new() # timer for initial delay
@onready var current_scene = get_tree().current_scene

var current_scene_as_string
var can_move: bool = false # flag to control when enemies can start moving

@onready var audio_player = $AudioStreamPlayer2D # audio player for shooting sounds
@onready var level1_attack_sound = preload("res://Binhale/Assets/Audio/Enemy/Hit Sound-001.wav") # attack sound
@onready var level2_attack_sound = preload("res://Binhale/Assets/Audio/Enemy/frog-qua-cry-36013.mp3")
@onready var flying_enemy_attack_sound = preload("res://Binhale/Assets/Audio/Enemy/FlyingEnemyAttack.mp3")
@onready var death_sound = preload("res://Binhale/Assets/Audio/Enemy/hit-flesh-02-266309.mp3"
)
@export var arrow_scene: PackedScene # scene for the offscreen arrow
var arrow_instance: Node2D = null # instance of the offscreen arrow
@onready var screen_notifier = $VisibleOnScreenNotifier2D # notifier for screen visibility


func _ready() -> void:
	# Disable physics process at the very start for flying enemies
	if is_in_group("FlyingEnemy"):
		set_physics_process(false)
		up_direction = Vector2.UP
		
	current_scene_as_string = current_scene.scene_file_path.get_file().get_basename()
	
	# Store initial position for MovingEnemy
	if is_in_group("MovingEnemy"):
		$InitialPosition.position = position

	if current_scene_as_string == "Level2" and can_shoot == true:
		audio_player.stream = level2_attack_sound
	else:
		audio_player.stream = level1_attack_sound
		audio_player.pitch_scale = 1.2
		
	area.area_entered.connect(_on_area_entered) # connect to area entered signal
	screen_notifier.screen_exited.connect(_on_screen_exited) # connect to screen exit signal
	screen_notifier.screen_entered.connect(_on_screen_entered) # connect to screen enter signal
	
	player = get_tree().get_first_node_in_group("Player") # get player reference

	if not screen_notifier.is_on_screen(): 
		_on_screen_exited()  # manually trigger arrow if already offscreen
	
	# Initialize flying enemies first, regardless of can_shoot
	if is_in_group("FlyingEnemy"):
		audio_player.stream = flying_enemy_attack_sound # play attack sound
		current_state = State.WAITING # set state to waiting
		sprite.play("Idle") # play idle animation
		can_move = true # flying enemies start moving immediately
		
		# Store original collision settings
		original_collision_mask = collision_mask
		original_collision_layer = collision_layer
		# Disable collisions initially for flying enemies
		collision_mask = 0
		collision_layer = 0
		
		# Set initial Y position and ensure it stays there
		position.y = initial_y_position
		velocity = Vector2.ZERO
		
		if can_shoot:
			audio_player.pitch_scale = 4 # change pitch for shooting sound
			# Set up initial delay timer
			initial_delay_timer.wait_time = 4.0
			initial_delay_timer.one_shot = true
			initial_delay_timer.timeout.connect(_on_initial_delay_timeout)
			add_child(initial_delay_timer)
			initial_delay_timer.start()
		
		# Wait a frame to ensure position is set
		await get_tree().process_frame
		# Re-enable physics process after initialization
		set_physics_process(true)
	elif can_shoot:
		audio_player.pitch_scale = 1.1
		# Set up initial delay timer
		initial_delay_timer.wait_time = 4.0
		initial_delay_timer.one_shot = true
		initial_delay_timer.timeout.connect(_on_initial_delay_timeout)
		add_child(initial_delay_timer)
		initial_delay_timer.start()
		
		# Initialize animation state for shooting enemies
		current_state = State.IDLE
		sprite.play("Idle")
		sprite.speed_scale = 1.0
	elif is_in_group("FollowingEnemy"): 
		current_state = State.MOVING_LEFT # set state to idle
		sprite.play("Run") # play idle animation
	elif is_in_group("BossEnemy"):
		audio_player.volume_db = 5
		audio_player.stream = level2_attack_sound
		audio_player.pitch_scale = 0.75
		current_state = State.IDLE
		sprite.play("Idle")
		current_hp = boss_hp  # Set boss HP
		# Setup jump timer
		jump_timer = Timer.new()
		jump_timer.wait_time = boss_jump_interval
		jump_timer.connect("timeout", _on_jump_timer_timeout)
		add_child(jump_timer)
		jump_timer.start()
	else:
		current_state = State.IDLE # default idle state
		sprite.play("Idle") # play idle animation

	if can_shoot and shoot_timer: # check if enemy can shoot
		shoot_timer.wait_time = fire_rate # set shoot timer
		shoot_timer.stop() # stop the timer until delay is over
	
	var level_name = get_tree().current_scene.name
	var level_number_str = level_name.substr(5, level_name.length() - 5)
	var level_number = int(level_number_str)

	current_level = get_tree().root.get_node("Level" + str(level_number))
	interface = current_level.get_node("Canvas/ScoreCounter")

func _physics_process(delta: float) -> void:
	if is_in_group("BossEnemy"):
		if is_on_floor() == false:
			$EnemySprite.play("Jump")
		elif is_on_floor() == true and sprite.animation != "Hit":
			$EnemySprite.play("Idle")
			
	if is_in_group("FlyingEnemy"):
		# Flying enemies ignore gravity completely
		velocity.y = 0 if current_state == State.WAITING else velocity.y
	else:
		velocity.y += gravity * delta  # Apply gravity only to non-flying enemies
		
	time += delta  # Increment time for flying movement

	if is_in_group("StillEnemy"): # for stationary enemies
		if player:
			sprite.flip_h = player.global_position.x < global_position.x # flip sprite based on player's position
		
		if current_state != State.IDLE and sprite.animation != "Hit":
			current_state = State.IDLE # change state to idle
			sprite.play("Idle") # play idle animation
			sprite.speed_scale = 1.0  # Ensure normal animation speed
		velocity.x = 0 # no movement for stationary enemies
	elif is_in_group("FollowingEnemy"): # for enemies that follow the player
		if player:
			var direction = player.global_position - global_position
			velocity.x = direction.x * speed / direction.length() # move horizontally toward player

			# checks if the player is above or below the enemy
			if player.global_position.y < global_position.y and player.is_on_floor() and is_on_floor() and player.global_position.x - global_position.x < 175:  # Player is above
				current_state = State.JUMPING
				velocity.y = -jump_speed  # jump upwards towards player
				sprite.play("Jump")
			else:
				velocity.y = min(velocity.y, jump_speed)

			sprite.flip_h = player.global_position.x < global_position.x # flip sprite based on player's position
			
			# Handle landing state
			if is_on_floor() and current_state == State.JUMPING:
				current_state = State.IDLE
			
			# Only play Run animation if not jumping and not in Hit state
			if current_state != State.JUMPING and sprite.animation != "Hit":
				sprite.play("Run")
		move_and_slide()
	elif is_in_group("FlyingEnemy"): # for flying enemies
		if not can_move:
			velocity.x = 0
			velocity.y = 0
			return
			
		# Check if player is within activation distance
		if current_state == State.WAITING and player:
			var distance_to_player = abs(global_position.x - player.global_position.x)
			if distance_to_player <= activation_distance:
				current_state = State.FLYING_UP
				sprite.flip_h = player.global_position.x < global_position.x
			
		# First, move up to target Y position
		if current_state == State.FLYING_UP:
			velocity.x = 0
			velocity.y = -flying_speed * 2  # Move up faster
			
			# Check if we've reached the target Y position
			if global_position.y <= target_y_position:
				global_position.y = target_y_position  # Snap to exact position
				current_state = State.MOVING_RIGHT if start_moving_right else State.MOVING_LEFT  # Start moving in specified direction
				reached_target_y = true
				sprite.flip_h = !start_moving_right
				# Restore original collision settings when reaching target height
				collision_mask = original_collision_mask
				collision_layer = original_collision_layer
		# Then start the normal flying pattern
		elif reached_target_y:
			# Horizontal movement
			if position.x <= left_boundary:
				current_state = State.MOVING_RIGHT
				sprite.flip_h = false
			elif position.x >= get_viewport_rect().size.x - 300:
				current_state = State.MOVING_LEFT
				sprite.flip_h = true
				
			if current_state == State.MOVING_LEFT:
				velocity.x = -flying_speed
			else:
				velocity.x = flying_speed
				
			# Vertical movement (sine wave pattern)
			velocity.y = sin(time * 2) * flying_amplitude
		
		sprite.play("Idle")
		move_and_slide()
	elif is_in_group("BossEnemy"):  # Boss enemy behavior
		if current_state == State.JUMPING:
			sprite.play("Jump")
			if is_on_floor():
				current_state = State.IDLE
				sprite.play("Idle")
		elif current_state == State.IDLE:
			velocity.x = 0
			if player:
				sprite.flip_h = player.global_position.x < global_position.x
		move_and_slide()
	else: #other enemies
		if raycast_left.is_colliding():
			if current_state != State.MOVING_RIGHT: 
				current_state = State.MOVING_RIGHT # move right if colliding on left
				sprite.play("Run") # play running animation
		elif position.x >= get_viewport_rect().size.x:
			if current_state != State.MOVING_LEFT:
				current_state = State.MOVING_LEFT # move left if on the edge
				sprite.play("Run") # play running animation

		if current_state == State.MOVING_LEFT: 
			velocity.x = -speed # move left
			sprite.flip_h = true # flip sprite to face left
		elif current_state == State.MOVING_RIGHT:
			velocity.x = speed # move right
			sprite.flip_h = false # flip sprite to face right
		elif current_state == State.IDLE:
			velocity.x = 0 # stop moving if idle
			sprite.play("Idle") # play idle animation

		move_and_slide()

		if player and is_on_floor() and player.is_on_floor() and abs(global_position.y - player.global_position.y) < 50 and abs(global_position.x - player.global_position.x) < 50:
			velocity.y = -jump_speed * 0.8
			position.y -= 10

func _on_area_entered(incoming_area: Area2D) -> void:
	if (incoming_area.is_in_group("Fire")) or (incoming_area.is_in_group("Electricity") and player.get_electric_state()):
		if is_in_group("BossEnemy"):
			audio_player.stream = death_sound
			audio_player.volume_db = 5
			$EnemySprite.speed_scale = 2
			$EnemySprite.play("Hit")
			current_hp -= 1
			if current_hp <= 0:
				await audio_player.finished
				queue_free() # remove enemy if HP reaches 0
				ScoreManager.increment_score(value)
				interface.update_score_display()
				emit_signal("enemy_died")
		else:
			queue_free() # remove non-boss enemy immediately
			ScoreManager.increment_score(value)
			interface.update_score_display()
			emit_signal("enemy_died")

func _on_shoot_timer_timeout() -> void:
	if not player or not projectile_scene:
		return # do nothing if no player or no projectile scene
		
	var projectile = projectile_scene.instantiate() # instantiate a projectile
	projectile.global_position = global_position # set projectile position
	projectile.direction = (player.global_position - global_position).normalized() # set projectile direction
	get_tree().root.add_child.call_deferred(projectile) # add projectile to the scene
		
	audio_player.play() # play audio

func _on_screen_exited() -> void:
	if not arrow_instance and arrow_scene: 
		# Only show arrow if enemy can shoot
		if can_shoot and player and shoot_timer:
			arrow_instance = arrow_scene.instantiate() # create a new arrow if not already created
			get_tree().get_first_node_in_group("UI").add_child(arrow_instance) # add the arrow to the UI layer
			arrow_instance.enemy = self # set the arrow's target to this enemy

func _on_screen_entered() -> void:
	if arrow_instance:
		arrow_instance.queue_free() # remove arrow when enemy comes back on screen
		arrow_instance = null # reset the arrow reference

func _on_initial_delay_timeout() -> void:
	if can_shoot and shoot_timer:
		shoot_timer.wait_time = fire_rate
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start()
	
	if is_in_group("FlyingEnemy"):
		can_move = true # allow flying enemies to start moving after delay

func _on_jump_timer_timeout() -> void:
	if is_in_group("BossEnemy") and is_on_floor() and sprite.animation_finished:
		audio_player.play()
		current_state = State.JUMPING
		velocity.y = -jump_speed
		$EnemySprite.play("Jump")

func _process(_delta: float) -> void:
	if shoot_timer and can_shoot and player:
		if shoot_timer.time_left <= 1.5 and not screen_notifier.is_on_screen():
			if not arrow_instance:
				arrow_instance = arrow_scene.instantiate()
				get_tree().get_first_node_in_group("UI").add_child(arrow_instance)
				arrow_instance.enemy = self
		elif (shoot_timer.time_left > 1.0 or screen_notifier.is_on_screen()) and arrow_instance:
			arrow_instance.queue_free()
			arrow_instance = null

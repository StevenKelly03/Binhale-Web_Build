extends CharacterBody2D

var speed = 200 #movement speed
var gravity = 400 #gravity force for falling
var jump_strength = 300 #strength of player jump
var platform_drop_timer = 0.0 #timer for platform dropping
var can_drop_through = false #flag to check if player can drop through platforms

enum PlayerState { IDLE, RUNNING, JUMPING, FALLING, D_JUMP } #enum for player states
var state = PlayerState.IDLE #variable to track current player state

enum CurrentPower { FIRE, SMOKE_JUMP, ELECTRICITY, NONE } #enum for available powers
var power = CurrentPower.NONE #variable to track current equipped power
var powerString = "Fire" #string to return from function to be used by the canvas for the power in top right
var unlocked_powers: Dictionary

var max_health : int = 5  # maximum health
var current_health : int = 5  # initial health, starting at full
var hearts = []  # list to hold heart sprites

var unlocked_power_list = []

enum PowerState { ACTIVE, INACTIVE } #enum to track if current power is active or not
var smokeState = PowerState.INACTIVE #variable to track iff smoke power active
var electricityState = PowerState.INACTIVE #variable to track if electric power active

var current_level = 1 #current level player is on
var current_scene_as_string

@onready var current_scene = get_tree().current_scene
@onready var sprite = $PlayerSprite #player sprite
@onready var powerSprite #sprite for current power
@onready var player_area = $PlayerArea #player area2d

@onready var smoke_timer = $Timers/SmokeTimer #timer for smoke animation

@onready var run_audio_player = $Audio/PlayerSound
@onready var power_audio_player = $Audio/PowerSound
@onready var hurt_sound_player = $Audio/HurtSound

var grass_run_sound = preload("res://Binhale/Assets/Audio/Player/Movement/running_grass.mp3")
var sand_run_sound = preload("res://Binhale/Assets/Audio/Player/Movement/running_grass.mp3")
var fireSound = preload("res://Binhale/Assets/Audio/Player/Powers/fire.mp3")
var smokeSound = preload("res://Binhale/Assets/Audio/Player/Powers/smoke.mp3")
var electricitySound = preload("res://Binhale/Assets/Audio/Player/Powers/electricity.mp3")
var hurt_sound = preload("res://Binhale/Assets/Audio/Player/hurt.mp3")

# check movement collisions
var can_move_left = true
var can_move_right = true
var can_move_up = true
var can_move = false  # New variable to control overall movement

@export var fireball_scene: PackedScene
const FireBall = preload("res://Binhale/Scripts/FireBall.gd")

func _ready() -> void:	
	can_move = false  # Start with movement disabled
	await get_tree().create_timer(4.0).timeout
	can_move = true  # Enable movement after 4 seconds
	
	current_scene_as_string = current_scene.scene_file_path.get_file().get_basename()
	unlocked_powers = PowerManager.get_unlocked_powers()
	
	var saved_power = PowerManager.get_current_power()
	
	match saved_power:
		"fire": power = CurrentPower.FIRE
		"smoke": power = CurrentPower.SMOKE_JUMP
		"electricity": power = CurrentPower.ELECTRICITY
		_: power = CurrentPower.NONE
	
	if power == CurrentPower.FIRE:
		powerString = "Fire"
	elif power == CurrentPower.SMOKE_JUMP:
		powerString = "Smoke"
	elif power == CurrentPower.ELECTRICITY:
		powerString = "Electricity"
	elif power == CurrentPower.NONE:
		powerString = "None"

	var ui_layer = get_tree().current_scene.get_node("Canvas")
	if ui_layer:
		hearts = [
			ui_layer.get_node("PlayerHealth/Heart1"),
			ui_layer.get_node("PlayerHealth/Heart2"),
			ui_layer.get_node("PlayerHealth/Heart3"),
			ui_layer.get_node("PlayerHealth/Heart4"),
			ui_layer.get_node("PlayerHealth/Heart5")
		]

	hurt_sound_player.stream = hurt_sound
	
	if current_scene_as_string == "Level1":
		run_audio_player.stream = grass_run_sound
	else:
		run_audio_player.stream = sand_run_sound
		
	run_audio_player.pitch_scale = 0.6
	player_area.monitoring = true #ensure player area being monitrored
	player_area.connect("area_entered", _on_area_entered) # connect area entered signal to handler
	smoke_timer.timeout.connect(_on_SmokeTimer_timeout) # connect smoke timer timeout to handler

func _process(delta: float) -> void:	
	# Update raycast checks
	can_move_left = not $RayCast_Left.is_colliding()
	can_move_right = not $RayCast_Right.is_colliding()
	can_move_up = not $RayCast_Up.is_colliding()
	
	# deactivate smoke power on landing
	if is_on_floor() and power == CurrentPower.SMOKE_JUMP:
		set_power_state(PowerState.INACTIVE, "inactive")

	# Handle platform dropping
	if Input.is_action_just_pressed("DropDown") and is_on_floor():
		can_drop_through = true
		platform_drop_timer = 0.0
		# Temporarily disable collision with platforms
		set_collision_mask_value(1, false)  # Assuming layer 1 is platforms
	
	if can_drop_through:
		platform_drop_timer += delta
		if platform_drop_timer >= 0.1:  # After 0.1 seconds
			can_drop_through = false
			set_collision_mask_value(1, true)  # Re-enable platform collision

	# update unlocked powers list
	unlocked_power_list.clear()  
	if unlocked_powers.has("fire") and unlocked_powers["fire"]:
		unlocked_power_list.append(CurrentPower.FIRE)
	if unlocked_powers.has("smoke") and unlocked_powers["smoke"]:
		unlocked_power_list.append(CurrentPower.SMOKE_JUMP)
	if unlocked_powers.has("electricity") and unlocked_powers["electricity"]:
		unlocked_power_list.append(CurrentPower.ELECTRICITY)
		
	# If we have no power but there are unlocked powers available, set to first unlocked power
	if power == CurrentPower.NONE and unlocked_power_list.size() > 0:
		power = unlocked_power_list[0]
		match power:
			CurrentPower.FIRE: 
				switch_power("Fire")
			CurrentPower.SMOKE_JUMP: 
				switch_power("Smoke")
			CurrentPower.ELECTRICITY: 
				switch_power("Electricity")

	# set power sprite and name
	if power == CurrentPower.SMOKE_JUMP:
		powerSprite = $SmokePower
		powerString = "Smoke"
	elif power == CurrentPower.FIRE:
		powerSprite = null  # We don't need a power sprite for the fireball
		powerString = "Fire"
	elif power == CurrentPower.ELECTRICITY:
		powerSprite = $Electric/ElectricityPower
		powerString = "Electricity"
	elif power == CurrentPower.NONE:
		powerSprite = null
		powerString = "None"

	# apply gravity
	velocity.y += gravity * delta

	# handle movement
	if can_move:  # Only allow movement if can_move is true
		if Input.is_action_pressed("MoveLeft") and can_move_left:
			velocity.x = -speed
			if is_on_floor() and state != PlayerState.RUNNING:
				run_audio_player.play()
				set_player_state(PlayerState.RUNNING, "Run")
			sprite.flip_h = true
		elif Input.is_action_pressed("MoveRight") and can_move_right:
			velocity.x = speed
			if is_on_floor() and state != PlayerState.RUNNING:
				run_audio_player.play()
				set_player_state(PlayerState.RUNNING, "Run")
			sprite.flip_h = false
		else:
			velocity.x = 0
			if is_on_floor() and state != PlayerState.IDLE:
				set_player_state(PlayerState.IDLE, "Idle")

		# handle jumping
		if Input.is_action_just_pressed("Jump") and is_on_floor() and can_move_up:
			velocity.y = -jump_strength
			set_player_state(PlayerState.JUMPING, "Jump")

	if not is_on_floor() and velocity.y > 0 and state != PlayerState.FALLING:
		set_player_state(PlayerState.FALLING, "Fall")

	# handle power usage
	if Input.is_action_just_pressed("UsePower"):
		if power == CurrentPower.SMOKE_JUMP:
			if current_scene_as_string == "Level3":
				current_scene.use_power()
			if current_scene_as_string == "Level3":
				current_scene.use_power()
			if state == PlayerState.JUMPING:
				power_audio_player.play()
				velocity.y = -(jump_strength * 1.65)
				set_player_state(PlayerState.D_JUMP, "DoubleJump")
				set_power_state(PowerState.ACTIVE, "active")
			elif is_on_floor() and can_move_up:
				power_audio_player.play()
				velocity.y = -(jump_strength * 1.75)
				set_player_state(PlayerState.JUMPING, "DoubleJump")
				set_power_state(PowerState.ACTIVE, "active")
			smoke_timer.start(1.2)
		elif power == CurrentPower.FIRE:
			if current_scene_as_string == "Level1":
				current_scene.use_power()
			if fireball_scene:
				power_audio_player.play()
				var fireball = fireball_scene.instantiate()
				fireball.direction = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
				fireball.position = global_position + Vector2(25 if not sprite.flip_h else -25, 0)
				get_parent().add_child(fireball)
		elif power == CurrentPower.ELECTRICITY:
			if electricityState == PowerState.ACTIVE:
				set_power_state(PowerState.INACTIVE, "inactive")
				power_audio_player.stop()
			else:
				if current_scene_as_string == "Level2":
					current_scene.use_power()
				set_power_state(PowerState.ACTIVE, "active")
				power_audio_player.play()
		elif power == CurrentPower.NONE:
			print("no power active, switch powers")

	# handle power switching
	if Input.is_action_just_pressed("SwitchPower"):
		var is_power_active = (smokeState == PowerState.ACTIVE or 
							  electricityState == PowerState.ACTIVE)
		
		if not is_power_active and unlocked_power_list.size() > 1:
			var current_power_index = unlocked_power_list.find(power)
			if current_power_index != -1:
				var next_power_index = (current_power_index + 1) % unlocked_power_list.size()
				power = unlocked_power_list[next_power_index]
				update_power_state_for_switch()
		elif is_power_active:
			print("Cannot switch powers while a power is in use")
		else:
			print("no other powers unlocked")

	move_and_slide()

	# handle landing state
	if is_on_floor():
		velocity.y = 0
		if velocity.x == 0 and state != PlayerState.IDLE:
			set_player_state(PlayerState.IDLE, "Idle")
		elif velocity.x != 0 and state != PlayerState.RUNNING:
			set_player_state(PlayerState.RUNNING, "Run")

func _on_SmokeTimer_timeout() -> void: #handler for smoke timer timeout signal
	power_audio_player.stop()
	set_power_state(PowerState.INACTIVE, "inactive")
	smokeState = PowerState.INACTIVE

func set_player_state(new_state: PlayerState, anim_name: String) -> void: 
	if state != new_state:
		state = new_state
		play_player_animation(anim_name) #ensures anmation is played

func set_power_state(new_state: PowerState, power_anim_name: String) -> void:
	if power == CurrentPower.SMOKE_JUMP and smokeState != new_state:
		smokeState = new_state
		play_power_animation(power_anim_name)
	elif power == CurrentPower.ELECTRICITY and electricityState != new_state:
		electricityState = new_state
		play_power_animation(power_anim_name)

#animation function for player sprite
func play_player_animation(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.animation = anim_name
		sprite.play()

#animation function for power animation
func play_power_animation(power_anim_name: String) -> void:
	if powerSprite and powerSprite.animation != power_anim_name:
		powerSprite.animation = power_anim_name
		powerSprite.play()

#function to handle collisions on player area2d
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyProjectile"):
		hurt_sound_player.play()
		if electricityState == PowerState.INACTIVE:
			current_health -= 1
			if current_health <= 0:
				die()
			update_health_display() #update hearts
			area.queue_free()
		else:
			area.queue_free()  #destroy projectile
			
func change_scene_to_game_over() -> void:
	MenuMusicManager.stopMusic()
	get_tree().change_scene_to_file("res://Binhale/Scenes/GameOver.tscn")

#returns current state of smoke po=wer
func get_smoke_state() -> bool:
	if smokeState == PowerState.ACTIVE:
		return true
	else:
		return false
		
#returns current state of electicty po=wer
func get_electric_state() -> bool:
	if electricityState == PowerState.ACTIVE:
		return true
	else:
		return false

#returns the current power equipped
func get_current_power() -> int:
	return power

#function for switching powers based on power-ups
func switch_power(newPower: String):
	PowerManager.set_current_power(newPower)
	if newPower == "Fire":
		power_audio_player.stream = fireSound
		power_audio_player.volume_db = 10
		power = CurrentPower.FIRE
		smoke_timer.stop()
		smokeState = PowerState.INACTIVE
		electricityState = PowerState.INACTIVE
	elif newPower == "Smoke":
		power_audio_player.stream = smokeSound
		power_audio_player.volume_db = 1
		power = CurrentPower.SMOKE_JUMP
		electricityState = PowerState.INACTIVE
	elif newPower == "Electricity":
		power_audio_player.stream = electricitySound
		power_audio_player.volume_db = -5
		power = CurrentPower.ELECTRICITY
		smoke_timer.stop()
		smokeState = PowerState.INACTIVE
		electricityState = PowerState.INACTIVE

func on_collect_powerup(power_name: String):
	PowerManager.unlock_power(power_name)
	unlocked_powers = PowerManager.get_unlocked_powers()
	
func update_power_state_for_switch():
	# stop all timers to prevent unwanted power cut-off
	smoke_timer.stop()

	# reset all power states
	smokeState = PowerState.INACTIVE
	electricityState = PowerState.INACTIVE

	# set audio stream
	if power == CurrentPower.FIRE:
		power_audio_player.stream = fireSound
		powerSprite = null
	elif power == CurrentPower.SMOKE_JUMP:
		power_audio_player.stream = smokeSound
		powerSprite = $SmokePower
	elif power == CurrentPower.ELECTRICITY:
		power_audio_player.stream = electricitySound
		powerSprite = $Electric/ElectricityPower
	else:
		power_audio_player.stream = null
		powerSprite = null

func update_health_display() -> void:
	# update heart sprites
	for i in range(max_health):
		if i < current_health:
			hearts[i].visible = true  # make heart visible if in lst
		else:
			hearts[i].visible = false  # hide heart if health lower than i

func die():
	set_physics_process(false)  # disable movement
	set_collision_layer_value(1, false)  # turn off collisions so the player falls through platforms & floor
	set_collision_mask_value(1, false)
	
	#detach cmera from player when death occurs
	if $RemoteTransform2D:
		$RemoteTransform2D.remote_path = ""
		
	var fall_duration = 1.0  #animation duration
	var fall_distance = 200  # distance the player falls

	var end_position = position + Vector2(0, fall_distance)

	#smoothy move downwards over duration of animation
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", end_position, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN) 

	await tween.finished  #wait for animation to b e o er to switch to game over screen
	call_deferred("change_scene_to_game_over")
	
func get_current_level() -> String:
	return current_scene_as_string
	
func _make_invis():
	if $RemoteTransform2D:
		$RemoteTransform2D.remote_path = ""
	visible = false

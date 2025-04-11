extends Node

@onready var music_player = $AudioStreamPlayer2D
@onready var score_label1 = $CanvasLayer/Label
@onready var score_label2 = $CanvasLayer/Label2
@onready var score_label3 = $CanvasLayer/Label3

@onready var background = $TextureRect
var game_over_sound = preload("res://Binhale/Assets/Audio/Other/game_over.wav")

# Store the current level's background
var current_level_background: Texture2D

func _ready():
	MenuMusicManager.stopMusic()
	music_player.stream = game_over_sound
	music_player.volume_db = -2
	music_player.pitch_scale = 0.75
	# Set the background texture based on the current level
	if current_level_background:
		background.texture = current_level_background
	
	# Display the final score before resetting
	var final_score = ScoreManager.score
	
	score_label1.text = "Game Over!\nEarth's Environment Has Been Destroyed\n\n"
	score_label2.text = "Press 'R' To Try Again\n\nOr\n\nPress 'Esc' To Return To Menu\n\n"
	score_label3.text = "Your Score Was:   " + str(final_score)

	ScoreManager.reset_score()
	remove_enemy_projectiles()
	
	play_music()

func remove_enemy_projectiles():
	for projectile in get_tree().get_nodes_in_group("EnemyProjectile"):
		projectile.queue_free()

func _input(event):
	if event.is_action_pressed("Restart"):
		PowerManager.reset_powers()
		get_tree().change_scene_to_file("res://Binhale/Scenes/Level1.tscn")
	if event.is_action_pressed("Escape to Menu"):
		PowerManager.reset_powers()
		get_tree().change_scene_to_file("res://Binhale/Scenes/main_menu.tscn")
		
func play_music():
	music_player.play()
	
func set_background_image(texture: Texture2D):
	$TextureRect.texture = texture

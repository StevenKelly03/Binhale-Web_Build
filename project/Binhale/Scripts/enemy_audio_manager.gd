extends Node

var audio_players: Array[AudioStreamPlayer2D] = []
var current_player_index: int = 0
var max_players: int = 4

func _ready():
	# Create a pool of audio players
	for i in range(max_players):
		var player = AudioStreamPlayer2D.new()
		player.volume_db = 0.05
		add_child(player)
		audio_players.append(player)

func play_sound(stream: AudioStream, position: Vector2):
	if audio_players.size() == 0:
		return
		
	var player = audio_players[current_player_index]
	player.stream = stream
	player.global_position = position
	player.play()
	
	# Cycle to next player
	current_player_index = (current_player_index + 1) % max_players 
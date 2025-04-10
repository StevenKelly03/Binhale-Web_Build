extends Node2D

@onready var sound_player = $AudioStreamPlayer2D


var leavingSoundPath = preload("res://Binhale/Assets/Audio/Other/bus_leaving.mp3")
var arrivalSoundPath = preload("res://Binhale/Assets/Audio/Other/bus_arrival.mp3")
var drivingSoundPath = preload("res://Binhale/Assets/Audio/Other/bus_driving.mp3")

func _ready() -> void:
	pass 
func _process(_delta: float) -> void:
	pass
	
func _play_arrival_sound():
	sound_player.stream = arrivalSoundPath
	sound_player.play()
	
	# Small delay
	await get_tree().create_timer(2.0).timeout
	_play_driving_sound()
	
func _play_leaving_sound():
	# Play leaving sound first
	sound_player.stream = leavingSoundPath
	sound_player.play()
	
	# Small delay
	await get_tree().create_timer(2.0).timeout
	_play_driving_sound()
	
func _play_driving_sound():
	sound_player.stream = drivingSoundPath
	sound_player.play()

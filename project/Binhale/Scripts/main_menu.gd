extends Node2D

@onready var buttonSound = $ButtonSound
@onready var muteSprite = $Buttons/Mute/Sprite2D

var muteSymbol = preload("res://Binhale/Assets/Other/muted.png")
var unmuteSymbol = preload("res://Binhale/Assets/Other/unmuted.png")

func _ready():
	MenuMusicManager.playMusic()

func _on_start_game_pressed():
	buttonSound.play()
	await buttonSound.finished
	get_tree().change_scene_to_file("res://Binhale/Scenes/Level1.tscn")

func _on_controls_pressed():
	buttonSound.play()
	await buttonSound.finished
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://Binhale/Scenes/controls_menu.tscn")

func _on_quit_pressed():
	buttonSound.play()
	await buttonSound.finished
	get_tree().quit()
	
func _on_mute_pressed():
	buttonSound.play()
	if muteSprite.texture == unmuteSymbol:
		muteSprite.texture = muteSymbol
		MenuMusicManager.stopMusic()
	else:
		muteSprite.texture = unmuteSymbol
		MenuMusicManager.playMusic()

func _on_credits_pressed():
	buttonSound.play()
	$ButtonText/CreditText.visible = !$ButtonText/CreditText.visible
	$TileMap.visible = !$TileMap.visible

extends Node

@onready var score_label = $CanvasLayer/ScoreText

func _ready():
	update_score_display()

func update_score_display():
	score_label.text = "Score: " + str(ScoreManager.get_score())

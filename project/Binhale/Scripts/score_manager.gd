extends Node

signal score_changed

var score = 0

func increment_score(value: int) -> void:
	score += value
	score_changed.emit()

func get_score() -> int:
	return score

func reset_score():
	score = 0
	score_changed.emit()

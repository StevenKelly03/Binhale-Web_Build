extends Node2D

var base_width = 275  # Base width for score rectangle
var width_per_digit = 25  # Additional width per digit
var min_width = 275  # Minimum width
var max_width = 800  # Maximum width to prevent excessive expansion

func _ready() -> void:
	queue_redraw()
	# Connect to score changes
	ScoreManager.score_changed.connect(_on_score_changed)

func _on_score_changed() -> void:
	queue_redraw()

func _draw():
	var rect_position1 = Vector2(1700, 25) #position for rect1
	var rect_size1 = Vector2(200, 130) #size for rect1
	
	# Calculate score rectangle width based on number of digits
	var score = ScoreManager.get_score()
	var score_digits = str(score).length()
	
	# Adjust width based on digit count
	var score_width = base_width
	if score_digits > 3:  # Only expand if more than 3 digits
		score_width += (score_digits - 3) * width_per_digit
	score_width = clamp(score_width, min_width, max_width)
	
	var rect_position2 = Vector2(10, 25) #position for rect2
	var rect_size2 = Vector2(304, 130) #size for rect2
	
	var rect_position3 = Vector2(860, 60) #position for rect3
	var rect_size3 = Vector2(300, 60) #size for rect3
	
	var rect_color = Color(0, 0, 0, 0.8) #colour for rectangles

	draw_rect(Rect2(rect_position1, rect_size1), rect_color) #draw rectangle 1 (Power Ui BG)
	draw_rect(Rect2(rect_position2, rect_size2), rect_color) #draw rectangle 2 (Score BG)
	draw_rect(Rect2(rect_position3, rect_size3), rect_color) #draw rectangle 3 (Player Health BG)

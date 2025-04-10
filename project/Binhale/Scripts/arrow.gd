extends Node2D

var enemy: Node2D = null
@onready var sprite = $Sprite2D  

const MARGIN = 50 # margin to stay inside the screen

func _process(_delta):
	if not enemy or not enemy.is_inside_tree():
		queue_free() # remove arrow if enemy is gone or invalid
		return

	var camera = get_viewport().get_camera_2d()
	if not camera:
		return # do nothing if there's no camera

	var viewport_rect = get_viewport_rect() # get viewport size
	var screen_position = (enemy.global_position - camera.global_position) * camera.zoom + (viewport_rect.size / 2) # convert enemy world pos to screen

	var clamped_x = clamp(screen_position.x, MARGIN, viewport_rect.size.x - MARGIN) # restrict x to inside margin
	var clamped_y = clamp(screen_position.y, MARGIN, viewport_rect.size.y - MARGIN) # restrict y to inside margin

	if screen_position.x < 0:
		global_position = Vector2(MARGIN, clamped_y) # place arrow on left
	elif screen_position.x > viewport_rect.size.x:
		global_position = Vector2(viewport_rect.size.x - MARGIN, clamped_y) # place arrow on right
	elif screen_position.y < 0:
		global_position = Vector2(clamped_x, MARGIN) # place arrow on top
	elif screen_position.y > viewport_rect.size.y:
		global_position = Vector2(clamped_x, viewport_rect.size.y - MARGIN) # place arrow on bottom

	rotation = (screen_position - global_position).angle() # rotate arrow to face enemy

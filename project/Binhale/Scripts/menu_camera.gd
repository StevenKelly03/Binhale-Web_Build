extends Camera2D

func _ready():
	self.zoom = Vector2(1.2, 1.2)
	
	self.offset = -self.position
	
	self.position = get_viewport().size / 2

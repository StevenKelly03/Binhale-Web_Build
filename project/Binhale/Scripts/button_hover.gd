extends TextureButton

@export var hover_scale: float = 1.1
@export var animation_duration: float = 0.2

var tween: Tween
var original_scale: Vector2

func _ready():
	original_scale = scale
	pivot_offset = size / 2
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", original_scale * hover_scale, animation_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", original_scale, animation_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) 

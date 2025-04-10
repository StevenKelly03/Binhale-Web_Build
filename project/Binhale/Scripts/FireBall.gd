extends CharacterBody2D

@export var speed: float = 300.0
@export var max_distance: float = 500.0
@export var damage: int = 1

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var initial_position: Vector2

@onready var hitbox = $Hitbox

func _ready():
	initial_position = global_position
	velocity = direction * speed
	hitbox.area_entered.connect(_on_area_entered)

func _physics_process(delta):
	$AnimatedSprite2D.play("Active")
	velocity = direction * speed 
	position += velocity * delta
	
	distance_traveled = (global_position - initial_position).length()
	
	if distance_traveled > max_distance:
		queue_free()
		return
		
func _on_area_entered(area: Area2D):
	if area.is_in_group("Electricity"):
		return
	else:
		queue_free()

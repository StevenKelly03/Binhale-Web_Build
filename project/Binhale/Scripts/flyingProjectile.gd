extends Area2D

@export var speed: float = 300.0  # projectile falling speed
@export var lifetime: float = 4.0  # time before destruction
@export var spin_speed: float = 180.0  # rotation speed
@export var fall_gravity: float = 500.0  # gravity force for falling

var velocity: Vector2 = Vector2.ZERO  # velocity vector
var direction: Vector2 = Vector2.ZERO  # this property will be set by the spawning code

func _ready() -> void:
	add_to_group("EnemyProjectile")  # add to enemy group
	# Initialize downward velocity, ignoring the direction since we always want to fall down
	velocity = Vector2(0, speed)
	
	await get_tree().create_timer(lifetime).timeout  # wait for lifetime
	self.body_entered.connect(_on_body_entered)  # detect collisions
	queue_free()  # remove after lifetime

func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y += fall_gravity * delta
	
	# Move projectile
	position += velocity * delta
	
	# Spin sprite
	var sprite = $Sprite2D  # get sprite node
	if sprite:
		sprite.rotation_degrees += spin_speed * delta  # spin sprite

func _on_body_entered(_body):
	queue_free()  # destroy on collision 

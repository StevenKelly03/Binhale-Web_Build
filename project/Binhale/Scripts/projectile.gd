extends Area2D

@export var speed: float = 500.0  # projectile speed
@export var lifetime: float = 4.0  # time before destruction
@export var spin_speed: float = 360.0  # rotation speed

var direction: Vector2 = Vector2.ZERO  # movement direction

func _ready() -> void:
	add_to_group("EnemyProjectile")  # add to enemy group
	await get_tree().create_timer(lifetime).timeout  # wait for lifetime
	self.body_entered.connect(_on_body_entered)  # detect collisions
	queue_free()  # remove after lifetime

func _process(delta: float) -> void:
	position += direction * speed * delta  # move projectile
	
	var sprite = $Sprite2D  # get sprite node
	if sprite:
		sprite.rotation_degrees += spin_speed * delta  # spin sprite

func _on_body_entered(_body):
	queue_free()  # destroy on collision

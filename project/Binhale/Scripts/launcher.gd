extends Node2D

@export var projectile_scene: PackedScene  # projectile scene
@export var fire_rate: float = 1.0  # time between shots
var can_shoot: bool = true  # can shoot boolean
var player: Node2D = null  # reference to player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")  # get player node
	start_firing()  # start shooting

func start_firing() -> void:
	while can_shoot:  # keep shooting
		shoot()  # shoot
		await get_tree().create_timer(fire_rate).timeout  # wait before next shot

func shoot() -> void:
	if not player:  # no player, return
		return

	var projectile = projectile_scene.instantiate()  # create projectile
	projectile.global_position = $spawnPoint.global_position  # set spawn point

	# get direction towards player
	projectile.direction = (player.global_position - $spawnPoint.global_position).normalized()

	get_tree().root.add_child.call_deferred(projectile)  # add to scene

extends CPUParticles2D

@export var flutter_speed: float = 2.0  # Speed of the sine wave
@export var flutter_amplitude: float = 50.0  # How far the particles move sideways
@export var fall_speed: float = 100.0  # Speed at which particles fall

var time: float = 0.0

func _ready():
	# Set initial parameters for falling particles
	direction = Vector2(0, 1)  # Falling downward
	spread = 15.0  # Slight spread for natural look
	initial_velocity_min = fall_speed * 0.8
	initial_velocity_max = fall_speed
	gravity = Vector2(0, 98)  # Standard downward gravity

func _process(delta):
	time += delta
	
	# Calculate the sine wave offset for horizontal movement
	var horizontal_offset = sin(time * flutter_speed) * flutter_amplitude
	
	# Apply horizontal movement to particles
	direction = Vector2(horizontal_offset * 0.01, 1).normalized()  # Small horizontal influence
	gravity = Vector2(horizontal_offset * 0.5, 98)  # Add slight horizontal gravity while maintaining downward fall

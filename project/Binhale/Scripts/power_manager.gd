extends Node

var unlocked_powers = {
	"fire": false,
	"smoke": true,
	"electricity": false,
	"none": true
}

var current_power = "none"

func _ready():
	# Make this node persist between scenes
	process_mode = Node.PROCESS_MODE_ALWAYS

func unlock_power(power_name: String):
	if power_name in unlocked_powers:
		unlocked_powers[power_name] = true
		print("Unlocked power: ", power_name)
		
func get_unlocked_powers() -> Dictionary:
	return unlocked_powers
	
func set_current_power(power_name: String):
	current_power = power_name
	print("Set current power to: ", power_name)
	
func get_current_power() -> String:
	return current_power 
	
func reset_powers():
	for power in unlocked_powers:
		if power != "none":  # Keep "none" power unlocked
			unlocked_powers[power] = false
	current_power = "none"  # Also reset current power to none

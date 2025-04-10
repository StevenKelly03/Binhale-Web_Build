extends AudioStreamPlayer

var saved_position = 0.0

func _ready():
	if not playing:
		play()

func playMusic():
	if not playing:
		if saved_position > 0:
			play(saved_position)
		else:
			play()

func stopMusic():
	saved_position = get_playback_position()
	stop()
	
func changeVolume(newValue: float):
	self.volume_db = newValue

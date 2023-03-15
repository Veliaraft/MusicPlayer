extends Label

var PlayerTime

func _process(delta):
	PlayerTime = int($"../AudioStreamPlayer".get_playback_position())
	var hours = "%02d" % [PlayerTime / 3600]
	var minutes = "%02d" % [PlayerTime / 60]
	var seconds = "%02d" % [PlayerTime % 60]
	self.text = hours + ":" + minutes + ":" + seconds

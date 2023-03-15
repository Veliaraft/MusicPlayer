extends HSlider

var dragged = false

func _process(delta):
	if dragged:
		$"../AudioStreamPlayer".volume_db = value

func _on_Volume_drag_started():
	dragged = true

func _on_Volume_drag_ended(value_changed):
	dragged = false

extends CanvasModulate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameSettings.dark_mode:
		color = Color.BLACK
	else:
		color = Color(0.1, 0.1, 0.1)

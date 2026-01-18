extends Node2D

func _ready():
	# Absolute must-haves
	get_tree().paused = false
	Engine.time_scale = 1.0

	# Timers safety
	for timer in get_tree().get_nodes_in_group("timers"):
		timer.stop()

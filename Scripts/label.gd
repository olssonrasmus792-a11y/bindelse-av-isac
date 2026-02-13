extends Label

@export var float_distance: float = 50.0
@export var float_time: float = 1.0

var start_position: Vector2
var timer: float = 0.0

func _ready():
	start_position = position
	modulate.a = 1.0  # Make sure alpha starts at 1

func _process(delta):
	timer += delta
	var t = timer / float_time
	if t > 1:
		queue_free()  # Remove text when done
		return

	# Move text upward
	position = start_position - Vector2(0, float_distance * t)
	
	# Fade out
	modulate.a = 1.0 - t

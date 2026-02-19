extends Label

@export var float_distance: float
@export var float_time: float = 1.0

var start_position: Vector2
var direction: Vector2
var timer: float = 0.0

func _ready():
	start_position = Vector2(position.x - 50, position.y)
	modulate.a = 1.0
	
	# Random distance
	float_distance = randf_range(40, 100)
	
	# Random direction (normalized so speed is consistent)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	

func _process(delta):
	timer += delta
	var t = timer / float_time
	
	if t > 1:
		queue_free()
		return

	# Move in random direction
	position = start_position + direction * float_distance * t
	
	# Fade out
	modulate.a = 1.0 - t

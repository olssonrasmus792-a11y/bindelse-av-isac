extends Camera2D

@export var shake_decay = 5.0
@export var max_offset = 20.0

var shake_strength = 0.0

func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		
		offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_strength * max_offset
	else:
		offset = Vector2.ZERO

func shake(strength = 1.0):
	shake_strength = strength

extends Camera2D

@export var shake_decay = 5.0
@export var max_offset = 20.0

@export var cursor_influence = 0.2   # how much the camera moves toward cursor
@export var max_cursor_offset = 180.0 # clamp so it doesn't go too far
@export var follow_smoothness = 8.0   # smoothing
var cursor_offset := Vector2.ZERO

var shake_strength = 0.0

func _process(delta):
	# --- Cursor offset ---
	var mouse_world = get_global_mouse_position()
	var to_mouse = mouse_world - global_position
	var target_cursor_offset = to_mouse * cursor_influence
	var factor = clamp(to_mouse.length() / max_cursor_offset, 0, 1)
	
	target_cursor_offset = to_mouse.normalized() * factor * max_cursor_offset * cursor_influence
	
	if to_mouse.length() < 10:
		target_cursor_offset = Vector2.ZERO
	
	# Clamp distance
	to_mouse = to_mouse.limit_length(max_cursor_offset)
	
	cursor_offset = cursor_offset.lerp(target_cursor_offset, follow_smoothness * delta)

	# --- Shake ---
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		
		var shake_offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_strength * max_offset
		
		offset = cursor_offset + shake_offset
	else:
		offset = cursor_offset


func shake(strength):
	shake_strength = strength

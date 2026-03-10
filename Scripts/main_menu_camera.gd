extends Camera2D

@export var cursor_influence = 0.1   # how much the camera moves toward cursor
@export var max_cursor_offset = 30.0 # clamp so it doesn't go too far
@export var follow_smoothness = 5   # smoothing
var cursor_offset := Vector2.ZERO

func _process(delta):
	# --- Cursor offset ---
	var mouse_world = get_global_mouse_position()
	var to_mouse = mouse_world - global_position
	var target_cursor_offset = to_mouse * cursor_influence
	var factor = clamp(to_mouse.length() / max_cursor_offset, 0, 1)
	
	target_cursor_offset = to_mouse.normalized() * factor * max_cursor_offset * cursor_influence
	
	if to_mouse.length() < 100:
		target_cursor_offset = Vector2.ZERO
	
	# Clamp distance
	to_mouse = to_mouse.limit_length(max_cursor_offset)
	
	cursor_offset = cursor_offset.lerp(target_cursor_offset, follow_smoothness * delta)
	offset = cursor_offset

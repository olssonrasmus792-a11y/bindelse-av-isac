extends Node2D

@export var target: Node2D
@export var margin: float = 25.0

func _process(_delta: float) -> void:
	if not target:
		queue_free()
		return

	var screen_size = get_viewport_rect().size
	var screen_pos = target.get_global_transform_with_canvas().origin

	# Check if target is on screen
	var on_screen = (
		screen_pos.x >= 0 and screen_pos.x <= screen_size.x and
		screen_pos.y >= 0 and screen_pos.y <= screen_size.y
	)

	if on_screen:
		visible = false
		return

	visible = true

	# Center of screen
	var center = screen_size / 2
	
	# Direction from center → target
	var dir = (screen_pos - center).normalized()

	# --- FIX: Proper edge clamping ---
	var scale_x = INF
	var scale_y = INF

	if dir.x != 0:
		scale_x = (center.x - margin) / abs(dir.x)
	if dir.y != 0:
		scale_y = (center.y - margin) / abs(dir.y)

	var scaled = min(scale_x, scale_y)

	var edge_pos = center + dir * scaled

	# Extra safety clamp (keeps inside margins)
	edge_pos.x = clamp(edge_pos.x, margin, screen_size.x - margin)
	edge_pos.y = clamp(edge_pos.y, margin, screen_size.y - margin)

	global_position = edge_pos

	# Rotate arrow to point toward target
	rotation = dir.angle()

extends Area2D


@export var distance_from_player := 15

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - get_parent().global_position
	
	if dir.length() > 5:
		dir = dir.normalized()
		global_position = get_parent().global_position + dir * distance_from_player
		rotation = dir.angle()
	
	if get_global_mouse_position().x < global_position.x:
		scale.y = -1
	else:
		scale.y = 1

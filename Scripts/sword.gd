extends Node2D

@export var distance_from_player := 15
@export var scale_factor = 1.0
@export var offset_amount := 10.0
@onready var trail: Polygon2D = $SwordPivot/Trail

func _ready() -> void:
	trail.visible = false

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - get_parent().global_position
	
	if dir.length() > 5:
		dir = dir.normalized()
		
		var flip = 1.0
		if mouse_pos.x < get_parent().global_position.x:
			flip = -1.0
		
		var perp = dir.rotated(PI / 2) * flip
		
		global_position = (
			get_parent().global_position
			+ dir * distance_from_player
			+ perp * offset_amount
		)
		
		rotation = dir.angle()
		
		scale.y = flip * scale_factor
		scale.x = 1 * scale_factor

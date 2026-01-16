extends Node2D
@onready var room: Node2D = $"."

@onready var camera: Camera2D = $Camera2D
var room_entered = false
var zoomed_out = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		switch_camera()

func switch_camera():
	camera.make_current()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if zoomed_out:
			camera.zoom = Vector2(0.65, 0.65)
			zoomed_out = false
		else:
			camera.zoom = Vector2(0.2, 0.2)
			zoomed_out = true

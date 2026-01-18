extends Node2D
@onready var room: Node2D = $"."

@onready var camera: Camera2D = $Camera2D
@onready var sprite_2d: Sprite2D = $Sprite2D
var room_entered = false
var zoomed_out = false
var camera_normal_zoom
var camera_map_zoom

func _ready() -> void:
	room_entered = false
	sprite_2d.visible = true
	camera_normal_zoom = camera.zoom.x
	camera_map_zoom = camera.zoom.x / 3

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		switch_camera()
		light_up_room()

func switch_camera():
	camera.make_current()

func light_up_room():
	sprite_2d.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if zoomed_out:
			camera.zoom = Vector2(camera_normal_zoom, camera_normal_zoom)
			zoomed_out = false
		else:
			camera.zoom = Vector2(camera_map_zoom, camera_map_zoom)
			zoomed_out = true

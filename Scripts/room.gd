extends Node2D
@onready var room: Node2D = $"."

@onready var camera: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect
var room_entered = false
var zoomed_out = false
var camera_normal_zoom
var camera_map_zoom
var target_position: Vector2

signal swap_cam(pos)

func _ready() -> void:
	room_entered = false
	color_rect.visible = true
	camera_normal_zoom = camera.zoom.x
	camera_map_zoom = camera.zoom.x / 3

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		switch_camera()
		light_up_room()

func switch_camera():
	#camera.make_current()
	emit_signal("swap_cam", target_position)

func light_up_room():
	color_rect.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if zoomed_out:
			camera.zoom = Vector2(camera_normal_zoom, camera_normal_zoom)
			zoomed_out = false
		else:
			camera.zoom = Vector2(camera_map_zoom, camera_map_zoom)
			zoomed_out = true

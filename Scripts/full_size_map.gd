extends SubViewport

@onready var full_size_cam: Camera2D = $FullSizeCam
@onready var camera_2d: Camera2D = $"../../../../Player/Camera2D"
@onready var sub_viewport_container: SubViewportContainer = $".."
@onready var label: Label = $"../../Label"
@onready var label_2: Label = $"../../Label2"

var opening

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_2d = get_tree().root.world_2d
	sub_viewport_container.modulate.a = 1
	sub_viewport_container.visible = false
	label.visible = false
	label_2.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map") and (!get_tree().paused or opening):
		opening = !sub_viewport_container.visible
		
		sub_viewport_container.visible = opening
		label.visible = opening
		label_2.visible = !opening
		get_tree().paused = opening
		
		if opening:
			full_size_cam.global_position = camera_2d.global_position

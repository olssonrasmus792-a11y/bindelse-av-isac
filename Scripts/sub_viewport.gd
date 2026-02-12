extends SubViewport

@onready var minimap: Camera2D = $Minimap
@onready var camera_2d: Camera2D = $"../../../Player/Camera2D"
@onready var sub_viewport_container: SubViewportContainer = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_2d = get_tree().root.world_2d
	sub_viewport_container.modulate.a = 0.75


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	minimap.position = camera_2d.global_position

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		sub_viewport_container.visible = !sub_viewport_container.visible

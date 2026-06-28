extends SubViewport

@onready var player := get_tree().get_first_node_in_group("player")

@onready var full_size_cam: Camera2D = $FullSizeCam
@onready var camera_2d: Camera2D = $"../../../../Player/Camera2D"
@onready var minimap: SubViewportContainer = $"../../Minimap"
@onready var sub_viewport_container: SubViewportContainer = $".."
@onready var label: Label = $"../../Label"
@onready var label_2: Label = $"../../Label2"
@onready var label_3: Label = $"../../Label3"
@onready var treasure_map: Control = $"../../TreasureMap"

var opening

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	world_2d = get_tree().root.world_2d
	sub_viewport_container.modulate.a = 1
	sub_viewport_container.visible = false
	label.visible = false
	label_2.visible = true
	label_3.visible = false
	treasure_map.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map") and (!get_tree().paused or opening):
		if GameState.is_fighting or (GameState.boss_spawned and !GameState.boss_killed):
			spawn_floating_text("Can't open map in combat!", Color.RED, player.global_position)
			return
		
		opening = !sub_viewport_container.visible
		
		sub_viewport_container.visible = opening
		label.visible = opening
		label_2.visible = !opening
		label_3.visible = opening
		treasure_map.visible = opening
		var percent = float(GameState.rooms_explored) / max(GameState.total_rooms, 1)

		label_3.self_modulate = Color.RED.lerp(Color.GREEN, percent)
		@warning_ignore("integer_division")
		label_3.text = ("Rooms Explored: " + str(( (GameState.rooms_explored * 100) / GameState.total_rooms) ) + "%")
		get_tree().paused = opening
		
		if opening:
			full_size_cam.global_position = camera_2d.global_position

func spawn_floating_text(text: String, color: Color, pos: Vector2):
	var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
	var ft = floating_text_scene.instantiate()
	
	ft.text = text
	ft.modulate = color
	ft.global_position = pos
	
	get_tree().current_scene.call_deferred("add_child", ft)

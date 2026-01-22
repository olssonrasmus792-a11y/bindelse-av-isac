extends Node2D

@export var room_scene = preload("res://Scenes/room.tscn")
@export var player_scene = preload("res://Scenes/player.tscn")
@export var room_size := Vector2i(11, 7) # tiles
@onready var camera_2d: Camera2D = $"../Camera2D"
@export var tile_size := 200.0
@export var dungeon_width := 6.0
@export var dungeon_height := 6.0
var room_width  = 11 * tile_size
var room_height = 7 * tile_size

var placed_rooms := {}

var room_spawn_rate = 0.6

var start_pos : Vector2

func _ready():
	generate_dungeon()
	print("Generating dungeon")

func generate_dungeon():
	start_pos = Vector2(dungeon_width / 2, dungeon_height / 2)
	place_room(start_pos)
	
	for x in range(dungeon_width):
		for y in range(dungeon_height):
			var pos := Vector2(start_pos.x + x, start_pos.y + y)
			if pos == start_pos:
				continue
			
			if randf() < room_spawn_rate:
				place_room(pos)
	
	for x in range(dungeon_width):
		for y in range(dungeon_height):
			var pos := Vector2(start_pos.x - x, start_pos.y - y)
			if pos == start_pos:
				continue
			
			if randf() < room_spawn_rate:
				place_room(pos)
	
	for x in range(dungeon_width):
		for y in range(dungeon_height):
			var pos := Vector2(start_pos.x+ x, start_pos.y - y)
			if pos == start_pos:
				continue
			
			if randf() < room_spawn_rate:
				place_room(pos)
	
	for x in range(dungeon_width):
		for y in range(dungeon_height):
			var pos := Vector2(start_pos.x - x, start_pos.y + y)
			if pos == start_pos:
				continue
			
			if randf() < room_spawn_rate:
				place_room(pos)

func place_room(grid_pos: Vector2):
	if placed_rooms.has(grid_pos):
		return
	
	var room_left = Vector2(grid_pos.x - 1, grid_pos.y)
	var room_right = Vector2(grid_pos.x + 1, grid_pos.y)
	var room_up = Vector2(grid_pos.x, grid_pos.y - 1)
	var room_down = Vector2(grid_pos.x, grid_pos.y + 1)
	
	
	if grid_pos != start_pos:
		if !(placed_rooms.has(room_left) or placed_rooms.has(room_right) or placed_rooms.has(room_up) or placed_rooms.has(room_down)):
			return
	
	var room = room_scene.instantiate()
	add_child(room)
	
	if placed_rooms.has(room_left):
		room.get_node("Doors/Door_Left/Sprite2D").visible = false
		room.get_node("Doors/Door_Left/CollisionShape2D").disabled = true
		room.get_node("Doors/Door_Left/LightOccluder2D").visible = false
		placed_rooms[room_left].get_node("Doors/Door_Right/Sprite2D").visible = false
		placed_rooms[room_left].get_node("Doors/Door_Right/CollisionShape2D").disabled = true
		placed_rooms[room_left].get_node("Doors/Door_Right/LightOccluder2D").visible = false
	
	if placed_rooms.has(room_right):
		room.get_node("Doors/Door_Right/Sprite2D").visible = false
		room.get_node("Doors/Door_Right/CollisionShape2D").disabled = true
		room.get_node("Doors/Door_Right/LightOccluder2D").visible = false
		placed_rooms[room_right].get_node("Doors/Door_Left/Sprite2D").visible = false
		placed_rooms[room_right].get_node("Doors/Door_Left/CollisionShape2D").disabled = true
		placed_rooms[room_right].get_node("Doors/Door_Left/LightOccluder2D").visible = false
	
	if placed_rooms.has(room_down):
		room.get_node("Doors/Door_Down/Sprite2D").visible = false
		room.get_node("Doors/Door_Down/CollisionShape2D").disabled = true
		room.get_node("Doors/Door_Down/LightOccluder2D").visible = false
		placed_rooms[room_down].get_node("Doors/Door_Up/Sprite2D").visible = false
		placed_rooms[room_down].get_node("Doors/Door_Up/CollisionShape2D").disabled = true
		placed_rooms[room_down].get_node("Doors/Door_Up/LightOccluder2D").visible = false

	if placed_rooms.has(room_up):
		room.get_node("Doors/Door_Up/Sprite2D").visible = false
		room.get_node("Doors/Door_Up/CollisionShape2D").disabled = true
		room.get_node("Doors/Door_Up/LightOccluder2D").visible = false
		placed_rooms[room_up].get_node("Doors/Door_Down/Sprite2D").visible = false
		placed_rooms[room_up].get_node("Doors/Door_Down/CollisionShape2D").disabled = true
		placed_rooms[room_up].get_node("Doors/Door_Down/LightOccluder2D").visible = false
	
	room.position = Vector2(
		grid_pos.x * room_size.x * tile_size - (room_width * dungeon_width / 2),
		grid_pos.y * room_size.y * tile_size - (room_height * dungeon_height / 2)
	)
	
	placed_rooms[grid_pos] = room
	
	room.target_position = room.get_node("Camera2D").global_position
	room.swap_cam.connect(_on_room_swap_cam)

func _on_room_swap_cam(pos):
	camera_2d.global_position = pos

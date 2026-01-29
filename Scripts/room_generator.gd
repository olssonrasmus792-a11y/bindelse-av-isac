extends Node2D

@onready var enemies: Node2D = $"../Enemies"
@export var room_scene = preload("res://Scenes/room.tscn")
@export var player_scene = preload("res://Scenes/player.tscn")
@export var chest_scene = preload("res://Scenes/Chest.tscn")
@export var room_size := Vector2i(11, 7) # tiles
@onready var camera_2d: Camera2D = $"../Camera2D"
@export var tile_size := 200.0
@export var dungeon_width := 6.0
@export var dungeon_height := 6.0
var room_width  = 11 * tile_size
var room_height = 7 * tile_size

var placed_rooms := {}

var room_spawn_rate = 0.6
var chest_spawn_chance = 0.4

var start_pos : Vector2

func _ready():
	generate_dungeon()

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
		change_door_state(room, room_left, "Left", "Right", false)
	
	if placed_rooms.has(room_right):
		change_door_state(room, room_right, "Right", "Left", false)
	
	if placed_rooms.has(room_down):
		change_door_state(room, room_down, "Down", "Up", false)

	if placed_rooms.has(room_up):
		change_door_state(room, room_up, "Up", "Down", false)
	
	room.position = Vector2(
		grid_pos.x * room_size.x * tile_size - (room_width * dungeon_width / 2),
		grid_pos.y * room_size.y * tile_size - (room_height * dungeon_height / 2)
	)
	
	placed_rooms[grid_pos] = room
	room.doors_finalized()
	
	if randf() < chest_spawn_chance:
		spawnChest(room)
	
	room.target_position = room.get_node("Camera2D").global_position
	room.swap_cam.connect(_on_room_swap_cam)

func _on_room_swap_cam(pos):
	camera_2d.global_position = pos

func spawnChest(room):
	var chest = chest_scene.instantiate()
	room.add_child(chest)
	chest.global_position = Vector2(room.position.x + room_width/2 - tile_size*3, room.position.y + room_height/2 - tile_size)

func change_door_state(room, room2, dir, dir2, state):
	room.get_node("Doors/Door_" + str(dir) + "/Wall").visible = state
	room.get_node("Doors/Door_" + str(dir) + "/Door").visible = state
	room.get_node("Doors/Door_" + str(dir) + "/CollisionShape2D").set_deferred("disabled", !state)
	room.get_node("Doors/Door_" + str(dir) + "/LightOccluder2D").visible = state
	placed_rooms[room2].get_node("Doors/Door_" + str(dir2) + "/Wall").visible = state
	placed_rooms[room2].get_node("Doors/Door_" + str(dir2) + "/Door").visible = state
	placed_rooms[room2].get_node("Doors/Door_" + str(dir2) + "/CollisionShape2D").set_deferred("disabled", !state)
	placed_rooms[room2].get_node("Doors/Door_" + str(dir2) + "/LightOccluder2D").visible = state
	return

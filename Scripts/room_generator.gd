extends Node2D

@onready var enemies: Node2D = $"../Enemies"
@export var room_scenes = [
	preload("res://Scenes/room.tscn"),
	preload("res://Scenes/room2.tscn"),
	preload("res://Scenes/room3.tscn")
]
@export var player_scene = preload("res://Scenes/player.tscn")
@export var chest_scene = preload("res://Scenes/Chest.tscn")
@onready var player: CharacterBody2D = $"../Player"
@export var room_size := Vector2i(GameState.room_tiles_x, GameState.room_tiles_y) # tiles
@onready var camera_2d: Camera2D = $"../Player/Camera2D"
@export var tile_size := 200.0
@export var dungeon_width := 6.0
@export var dungeon_height := 6.0
var room_width  = GameState.room_tiles_x * tile_size
var room_height = GameState.room_tiles_y * tile_size

var placed_rooms := {}

var room_spawn_rate = 0.6
var chest_spawn_chance = 0.6 # 1.0 = 100% chans, 0.0 = 0%

var start_pos : Vector2

func _ready():
	generate_dungeon()

func generate_dungeon():
	start_pos = Vector2(dungeon_width / 2, dungeon_height / 2)
	place_room(start_pos)
	player.spawn_pos = Vector2(room_width/2 - tile_size*3,room_height/2 - tile_size)
	player.global_position = player.spawn_pos
	
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
	
	var room_scene = room_scenes.pick_random()
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
		grid_pos.x * room_width - (room_width * dungeon_width / 2),
		grid_pos.y * room_height - (room_height * dungeon_height / 2)
	)
	
	placed_rooms[grid_pos] = room
	room.doors_finalized()
	
	if randf() < chest_spawn_chance and grid_pos != start_pos:
		spawnChest(room)
	
	if grid_pos == start_pos:
		room.clear_light.visible = true
	
	room.target_position = room.get_node("Camera2D").global_position
	room.swap_cam.connect(_on_room_swap_cam)

func _on_room_swap_cam(pos):
	#camera_2d.global_position = pos
	camera_2d.limit_left = pos.x - room_width/2 + tile_size * 3.25
	camera_2d.limit_right = pos.x + room_width/2 + tile_size * 2.75
	camera_2d.limit_bottom = pos.y + room_height/2 + tile_size * 1.75
	camera_2d.limit_top = pos.y - room_height/2 + tile_size * 2.25

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

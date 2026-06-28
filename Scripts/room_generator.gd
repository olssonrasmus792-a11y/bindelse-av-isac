extends Node2D

@onready var enemies: Node2D = $"../Enemies"

@export var room_scenes = [
	preload("res://Scenes/Rooms/room.tscn"),
	preload("res://Scenes/Rooms/room2.tscn"),
	preload("res://Scenes/Rooms/room3.tscn"),
	preload("res://Scenes/Rooms/room4.tscn"),
	preload("res://Scenes/Rooms/storage_room.tscn"),
	preload("res://Scenes/Rooms/room_shop.tscn"),
	preload("res://Scenes/Rooms/challenge_room.tscn"),
	preload("res://Scenes/Rooms/challenge_room_2.tscn"),
	preload("res://Scenes/Rooms/room_workshop.tscn")
]
@export var room_weights = [5, 5, 5, 5, 1, 0, 4, 4, 0] # Hur stor chans att ett rum spawnar jämfört med andra

@export var start_room_scene = preload("res://Scenes/Rooms/room_start.tscn")
@export var boss_room_scene = preload("res://Scenes/Rooms/room_boss.tscn")

@export var shop_scene = preload("res://Scenes/Rooms/room_shop.tscn")
var shop_rooms_spawned = 0
var min_shop_rooms = 4
var max_shop_rooms = 6

var workshops_spawned = 0
var min_workshops = 2
var max_workshops = 3

@export var boss_room_distance := 6.4 # how many rooms away from start

var shop_positions: Array = []
var workshop_positions: Array = []
@export var min_shop_distance_from_start := 1.4
@export var max_shop_distance_from_start := 6.4
@export var min_shop_distance_between := 1.4


@export var player_scene = preload("res://Scenes/player.tscn")
@export var chest_scene = preload("res://Scenes/Chest.tscn")
@onready var player: CharacterBody2D = $"../Player"
@export var room_size := Vector2i(GameState.room_tiles_x, GameState.room_tiles_y) # tiles
@onready var camera_2d: Camera2D = $"../Player/Camera2D"
@export var tile_size := 200.0
@export var dungeon_width := 4.0
@export var dungeon_height := dungeon_width
var room_width  = GameState.room_tiles_x * tile_size
var room_height = GameState.room_tiles_y * tile_size

@export var min_rooms := 8
var placed_rooms := {}
var rooms_spawned = false

var random_step = 1.0
var room_spawn_rate = 0.6
var chest_spawn_chance = 0.6 # 1.0 = 100% chans, 0.0 = 0%

var start_pos : Vector2
var main_path := []
var end_room_pos := Vector2.ZERO

signal dungeon_loaded

func _ready():
	generate_dungeon()
	add_extra_rooms()
	
	rooms_spawned = true
	
	ensure_special_rooms()
	
	GameState.total_rooms = placed_rooms.size()
	save_map_data()
	
	dungeon_loaded.emit()

func generate_dungeon():
	start_pos = Vector2(dungeon_width / 2, dungeon_height / 2)

	place_room(start_pos)

	player.spawn_pos = Vector2(room_width/2 - tile_size*3, room_height/2 - tile_size)
	player.global_position = player.spawn_pos

	# pick farthest end point
	end_room_pos = get_final_room_pos()

	# build clean path first
	generate_clean_path(start_pos, end_room_pos)

	# spawn rooms from path
	for pos in main_path:
		place_room(pos)

	# ensure end room overrides last tile
	place_room(end_room_pos)

	rooms_spawned = true

func get_final_room_pos() -> Vector2:
	var angle = randf() * TAU  # random angle in any direction
	var offset = Vector2(
		round(cos(angle) * boss_room_distance),
		round(sin(angle) * boss_room_distance)
	)
	return start_pos + offset

func generate_clean_path(start: Vector2, end: Vector2):
	main_path.clear()

	var current = start
	main_path.append(current)

	var safety = 0

	while current != end and safety < 200:
		safety += 1

		var step_options = []

		# bias toward target (no chaos anymore)
		if current.x < end.x:
			step_options.append(Vector2.RIGHT)
		elif current.x > end.x:
			step_options.append(Vector2.LEFT)

		if current.y < end.y:
			step_options.append(Vector2.DOWN)
		elif current.y > end.y:
			step_options.append(Vector2.UP)

		# small controlled randomness (prevents straight boring lines)
		if randf() < random_step:
			random_step = 0.4
			step_options.append(Vector2.LEFT)
			step_options.append(Vector2.RIGHT)
			step_options.append(Vector2.UP)
			step_options.append(Vector2.DOWN)

		var dir = step_options.pick_random()
		current += dir

		if not main_path.has(current):
			main_path.append(current)

	# guarantee end connection
	if not main_path.has(end):
		main_path.append(end)

func place_room(grid_pos: Vector2):
	if placed_rooms.has(grid_pos) and !rooms_spawned:
		return
	
	var room_left = Vector2(grid_pos.x - 1, grid_pos.y)
	var room_right = Vector2(grid_pos.x + 1, grid_pos.y)
	var room_up = Vector2(grid_pos.x, grid_pos.y - 1)
	var room_down = Vector2(grid_pos.x, grid_pos.y + 1)
	
	
	if grid_pos != start_pos:
		if !(placed_rooms.has(room_left) or placed_rooms.has(room_right) or placed_rooms.has(room_up) or placed_rooms.has(room_down)):
			return
	
	var room_scene

	if grid_pos == start_pos:
		room_scene = start_room_scene

	elif grid_pos == end_room_pos:
		room_scene = boss_room_scene

	elif main_path.has(grid_pos):
		room_scene = pick_weighted_room() # MAIN PATH ROOMS

	else:
		room_scene = shop_scene # SIDE ROOMS
	
	
	var room = room_scene.instantiate()
	add_child(room)
	
	if room_scene == room_scenes[5]:
		shop_rooms_spawned += 1
		shop_positions.append(grid_pos)
	
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
	
	if randf() < chest_spawn_chance and grid_pos != start_pos and room_scene != room_scenes[4] and room_scene != boss_room_scene and room_scene != room_scenes[5] and room_scene != room_scenes[6] and room_scene != room_scenes[7]:
		spawnChest(room)
	
	if grid_pos == start_pos:
		room.clear_light.visible = true
	
	room.target_position = room.get_node("Camera2D").global_position
	room.swap_cam.connect(_on_room_swap_cam)

func _on_room_swap_cam(pos):
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

func pick_weighted_room():
	var total := 0
	
	# Calculate total weight of allowed rooms only
	for i in range(room_scenes.size()):
		if room_scenes[i] == shop_scene and shop_rooms_spawned >= max_shop_rooms:
			continue
		total += room_weights[i]

	# Safety check
	if total <= 0:
		return room_scenes[0]

	var roll := randi() % total
	var cumulative := 0

	for i in range(room_scenes.size()):
		if room_scenes[i] == shop_scene and shop_rooms_spawned >= max_shop_rooms:
			continue
		
		cumulative += room_weights[i]
		if roll < cumulative:
			return room_scenes[i]

	# Final fallback (guaranteed return)
	return room_scenes[0]

func add_extra_rooms():
	var attempts := 0
	
	while placed_rooms.size() < min_rooms and attempts < 100:
		attempts += 1
		
		var existing_positions = placed_rooms.keys()
		var base_pos = existing_positions.pick_random()
		
		var directions = [
			Vector2.LEFT,
			Vector2.RIGHT,
			Vector2.UP,
			Vector2.DOWN
		]
		
		var new_pos = base_pos + directions.pick_random()
		
		if not placed_rooms.has(new_pos) and not shop_positions.has(new_pos) and not main_path.has(new_pos) and new_pos.distance_to(end_room_pos) >= 2.0:
			place_room(new_pos)

func ensure_special_rooms():
	# Spawn minimum shops
	while shop_rooms_spawned < min_shop_rooms:
		if !spawn_special_room("shop"):
			break

	# Spawn minimum workshops
	while workshops_spawned < min_workshops:
		if !spawn_special_room("workshop"):
			break

	# Fill remaining slots until both reach max
	var attempts := 0
	while attempts < 1000:
		attempts += 1

		var can_spawn_shop = shop_rooms_spawned < max_shop_rooms
		var can_spawn_workshop = workshops_spawned < max_workshops

		if !can_spawn_shop and !can_spawn_workshop:
			break

		if can_spawn_shop and can_spawn_workshop:
			if randf() < 0.5:
				spawn_special_room("shop")
			else:
				spawn_special_room("workshop")
		elif can_spawn_shop:
			spawn_special_room("shop")
		else:
			spawn_special_room("workshop")

func spawn_special_room(type: String) -> bool:
	var attempts := 0

	while attempts < 1000:
		attempts += 1

		var base_pos = placed_rooms.keys().pick_random()
		var directions = [
			Vector2.LEFT,
			Vector2.RIGHT,
			Vector2.UP,
			Vector2.DOWN
		]

		var new_pos = base_pos + directions.pick_random()

		# Already occupied
		if placed_rooms.has(new_pos):
			continue

		var dist_to_start = new_pos.distance_to(start_pos)

		if dist_to_start < min_shop_distance_from_start:
			continue

		if dist_to_start > max_shop_distance_from_start:
			continue

		if new_pos.distance_to(end_room_pos) < 1.4:
			continue

		var too_close := false

		for shop_pos in shop_positions:
			if new_pos.distance_to(shop_pos) < min_shop_distance_between:
				too_close = true
				break

		if !too_close:
			for workshop_pos in workshop_positions:
				if new_pos.distance_to(workshop_pos) < min_shop_distance_between:
					too_close = true
					break

		if too_close:
			continue

		if type == "shop":
			place_room(new_pos)
			shop_positions.append(new_pos)
		else:
			place_workshop(new_pos)

		return true

	return false

func place_workshop(grid_pos: Vector2):
	var room = room_scenes[8].instantiate() # room_workshop.tscn
	add_child(room)

	workshops_spawned += 1
	workshop_positions.append(grid_pos)

	var room_left = Vector2(grid_pos.x - 1, grid_pos.y)
	var room_right = Vector2(grid_pos.x + 1, grid_pos.y)
	var room_up = Vector2(grid_pos.x, grid_pos.y - 1)
	var room_down = Vector2(grid_pos.x, grid_pos.y + 1)

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

	room.target_position = room.get_node("Camera2D").global_position
	room.swap_cam.connect(_on_room_swap_cam)


func save_map_data():

	GameState.dungeon_map.clear()

	for pos in placed_rooms.keys():

		var room_data = {
			"connections": []
		}


		var directions = [
			Vector2.LEFT,
			Vector2.RIGHT,
			Vector2.UP,
			Vector2.DOWN
		]


		for dir in directions:

			var neighbor = pos + dir

			if placed_rooms.has(neighbor):
				room_data.connections.append(neighbor)


		GameState.dungeon_map[pos] = room_data


	GameState.start_room_pos = start_pos
	GameState.treasure_room_pos = end_room_pos
	GameState.shop_positions = shop_positions
	GameState.workshop_positions = workshop_positions

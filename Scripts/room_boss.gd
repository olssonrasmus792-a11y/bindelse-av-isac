extends Node2D
@onready var room: Node2D = $"."

@export var enemy_scenes = [
	preload("res://Scenes/Enemies/Muddy.tscn"),
	preload("res://Scenes/Enemies/Snail.tscn"),
	preload("res://Scenes/Enemies/stoney.tscn"),
	preload("res://Scenes/Enemies/water_guy.tscn")
]

@export var clover_boss_scene := preload("res://Scenes/clover_boss.tscn")
@export var coin_scene = preload("res://Scenes/Coin.tscn")
@export var key_scene := preload("res://Scenes/Key.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect

@onready var tile_map: TileMapLayer = $TileMapLayer

@onready var door_up: StaticBody2D = $Doors/Door_Up
@onready var door_left: StaticBody2D = $Doors/Door_Left
@onready var door_down: StaticBody2D = $Doors/Door_Down
@onready var door_right: StaticBody2D = $Doors/Door_Right

@onready var door_light_up: PointLight2D = $Lamps/DoorLightUp
@onready var door_light_down: PointLight2D = $Lamps/DoorLightDown
@onready var door_light_right: PointLight2D = $Lamps/DoorLightRight
@onready var door_light_left: PointLight2D = $Lamps/DoorLightLeft

@onready var clear_light: PointLight2D = $Lamps/PointLight2D2

@export var room_size := Vector2i(GameState.room_tiles_x, GameState.room_tiles_y)
@export var tile_size := 200.0
@export var dungeon_width := 5.0
@export var dungeon_height := 5.0
var room_width  = GameState.room_tiles_x * tile_size
var room_height = GameState.room_tiles_y * tile_size
var start_pos : Vector2
var start_room_pos : Vector2

var key_spawn_rate = 0.75
var item_pos_offset = 50

var room_entered = false
var room_closed = false
var room_cleared = false
var player_is_in_room = false
var zoomed_out = false
var camera_normal_zoom
var camera_map_zoom
var target_position: Vector2 = Vector2(0, 0)

var has_door_up
var has_door_left
var has_door_down
var has_door_right

var alive_enemies: Array = []
var can_spawn_boss = false

signal swap_cam(pos)

func _ready() -> void:
	start_pos = Vector2(dungeon_width / 2, dungeon_height / 2)
	start_room_pos = Vector2(
		start_pos.x * room_size.x * tile_size - (room_width * dungeon_width / 2),
		start_pos.y * room_size.y * tile_size - (room_height * dungeon_height / 2)
		)
	
	room_entered = false
	room_closed = false
	clear_light.visible = true
	clear_light.color = Color.WHITE
	color_rect.visible = true
	camera_normal_zoom = camera.zoom.x
	camera_map_zoom = camera.zoom.x / 3
	can_spawn_boss = false

func _process(_delta: float) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.is_dead:
			clear_light.visible = false
	
	var player_inside := is_player_inside()

	if player_inside:
		# This room becomes active ONLY if player is fully inside
		GameState.current_room = self
		player_is_in_room = true
	else:
		# Only clear if THIS room was the active one
		if GameState.current_room == self:
			GameState.current_room = null

		player_is_in_room = false
	
	if GameState.boss_spawned:
		clear_light.color = Color.RED
	
	if GameState.boss_killed:
		clear_light.color = Color.PALE_GREEN

func doors_finalized():
	await get_tree().create_timer(0.2).timeout
	check_doors()
	draw_paths()

func check_doors():
	has_door_up    = door_up.get_node("Door").visible
	has_door_left  = door_left.get_node("Door").visible
	has_door_down  = door_down.get_node("Door").visible
	has_door_right = door_right.get_node("Door").visible

func draw_paths():
	var center = get_room_center()

	if !has_door_up:
		var door_pos = door_up.get_node("Door").global_position
		draw_path_line(door_pos, Vector2(door_pos.x, center.y))  # lock X to door
		door_light_up.enabled = true

	if !has_door_down:
		var door_pos = door_down.get_node("Door").global_position
		draw_path_line(door_pos, Vector2(door_pos.x, center.y))  # lock X to door
		door_light_down.enabled = true

	if !has_door_left:
		var door_pos = door_left.get_node("Door").global_position
		draw_path_line(door_pos, Vector2(center.x, door_pos.y))  # lock Y to door
		door_light_left.enabled = true

	if !has_door_right:
		var door_pos = door_right.get_node("Door").global_position
		draw_path_line(door_pos, Vector2(center.x, door_pos.y))  # lock Y to door
		door_light_right.enabled = true

func get_room_center() -> Vector2:
	return global_position + Vector2(
		get_parent().room_width / 2.0 - 3 * tile_size,
		get_parent().room_height / 2.0 - 1 * tile_size
	)

func draw_path_line(from: Vector2, to: Vector2):
	var start: Vector2i = to_tile(from)
	var end: Vector2i   = to_tile(to)
	draw_path_cells(start, end)

func to_tile(pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(pos))

func draw_path_cells(start: Vector2i, end: Vector2i):
	var x = start.x
	var y = start.y

	# Walk horizontally first
	while x != end.x:
		x += sign(end.x - x)
		var coords = Vector2i(x, y)
		if tile_map.get_cell_source_id(coords) == 0:
			tile_map.set_cell(Vector2i(x, y), 4, Vector2i(0, 0))

	# Then vertically
	while y != end.y:
		y += sign(end.y - y)
		var coords = Vector2i(x, y)
		if tile_map.get_cell_source_id(coords) == 0:
			tile_map.set_cell(Vector2i(x, y), 4, Vector2i(0, 0))

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		switch_camera()
		light_up_room()
		room_entered = true
		player_is_in_room = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_in_room = false

func switch_camera():
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

func _on_enemy_spawn_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and room.position != start_room_pos and !room_closed and !room_cleared:
		check_doors()
		close_room()
	
	if body.is_in_group("player"):
		GameState.current_room = self
		can_spawn_boss = true

func _on_enemy_spawn_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.current_room = null
		can_spawn_boss = false

func is_player_inside() -> bool:
	var area := $EnemySpawnArea
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func close_room():
	room_closed = true
	
	if !has_door_up:
		close_door(door_up)
	
	if !has_door_left:
		close_door(door_left)
	
	if !has_door_down:
		close_door(door_down)
	
	if !has_door_right:
		close_door(door_right)

func open_room():
	room_cleared = true
	room_closed = false
	clear_light.visible = true
	
	if !has_door_up:
		open_door(door_up)
	
	if !has_door_left:
		open_door(door_left)
	
	if !has_door_down:
		open_door(door_down)
	
	if !has_door_right:
		open_door(door_right)

func on_room_cleared():
	open_room()
	GameState.is_fighting = false
	GameState.rooms_cleared += 1

func close_door(door):
	door.get_node("Door").visible = true
	door.get_node("CollisionShape2D").set_deferred("disabled", false)
	door.get_node("LightOccluder2D").visible = true

func open_door(door):
	door.get_node("Door").visible = false
	door.get_node("CollisionShape2D").set_deferred("disabled", true)
	door.get_node("LightOccluder2D").visible = false

func get_enemy_container() -> Node:
	return get_tree().get_first_node_in_group("enemy_container")

func get_enemy_weight(scene):
	if scene == preload("res://Scenes/Enemies/Muddy.tscn"):
		return GameState.muddy_spawn_rate

	if scene == preload("res://Scenes/Enemies/Snail.tscn"):
		return GameState.snail_spawn_rate

	if scene == preload("res://Scenes/Enemies/stoney.tscn"):
		return GameState.stoney_spawn_rate
	
	if scene == preload("res://Scenes/Enemies/water_guy.tscn"):
		return GameState.waterguy_spawn_rate

	return 1

func pick_weighted_enemy():
	var total_weight = 0
	
	for e in enemy_scenes:
		total_weight += get_enemy_weight(e)
	
	var roll = randf_range(0, total_weight)
	var current = 0
	
	for e in enemy_scenes:
		var weight = get_enemy_weight(e)
		current += weight
	
		if roll <= current:
			if e == preload("res://Scenes/Enemies/Muddy.tscn") and roll > GameState.muddy_base_spawn_rate:
				for item in GameState.taken_items:
					if item.name == "Caged Muddy":
						item.tracked_stat_values[0] += 1
			return e
	
	return enemy_scenes[0]

func _on_enemy_died(enemy):
	var last_position = enemy.global_position
	alive_enemies.erase(enemy)
	
	GameState.kills += 1
	GameState.combo += 1
	
	if randf() < GameState.coin_drop_chance:
		drop_coin(last_position)
	
	if alive_enemies.is_empty():
		on_room_cleared()
		if randf() < key_spawn_rate * (1 + GameState.luck):
			drop_key(last_position)
	
	if enemy.name == "CloverBoss":
		drop_key(last_position)
		if self.get_parent():  # room node still exists
			for x in range(randi_range(5, 20)):
				drop_coin(last_position)

func drop_key(pos):
	var key = key_scene.instantiate()
	key.global_position = pos + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
	if self.get_parent():  # room node still exists
		self.get_parent().add_child(key)

func drop_coin(pos):
	var coin = coin_scene.instantiate()
	coin.global_position = pos + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
	if self.get_parent():  # room node still exists
		self.get_parent().add_child(coin)

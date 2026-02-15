extends Node2D
@onready var room: Node2D = $"."

@export var enemy_scenes = [
	preload("res://Scenes/Muddy.tscn"),
	preload("res://Scenes/Snail.tscn"),
	preload("res://Scenes/stoney.tscn")
]
@export var key_scene := preload("res://Scenes/Key.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect

@onready var door_up: StaticBody2D = $Doors/Door_Up
@onready var door_left: StaticBody2D = $Doors/Door_Left
@onready var door_down: StaticBody2D = $Doors/Door_Down
@onready var door_right: StaticBody2D = $Doors/Door_Right

@onready var clear_light: PointLight2D = $Lamps/PointLight2D2

@export var room_size := Vector2i(GameState.room_tiles_x, GameState.room_tiles_y)
@export var tile_size := 200.0
@export var dungeon_width := 6.0
@export var dungeon_height := 6.0
var room_width  = GameState.room_tiles_x * tile_size
var room_height = GameState.room_tiles_y * tile_size
var start_pos : Vector2
var start_room_pos : Vector2

var key_spawn_rate = 1

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
var enemies_per_room = 10

signal swap_cam(pos)

func _ready() -> void:
	start_pos = Vector2(dungeon_width / 2, dungeon_height / 2)
	start_room_pos = Vector2(
		start_pos.x * room_size.x * tile_size - (room_width * dungeon_width / 2),
		start_pos.y * room_size.y * tile_size - (room_height * dungeon_height / 2)
		)
	
	room_entered = false
	room_closed = false
	clear_light.visible = false
	color_rect.visible = true
	camera_normal_zoom = camera.zoom.x
	camera_map_zoom = camera.zoom.x / 3

func _process(_delta: float) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.is_dead:
			clear_light.visible = false

func doors_finalized():
	check_doors()

func check_doors():
	has_door_up    = door_up.get_node("Door").visible
	has_door_left  = door_left.get_node("Door").visible
	has_door_down  = door_down.get_node("Door").visible
	has_door_right = door_right.get_node("Door").visible


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
		call_deferred("spawn_enemies")
		close_room()

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
	GameState.rooms_cleared += 1
	enemies_per_room = 10 + GameState.rooms_cleared * 2


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

func spawn_enemies():
	var enemies = get_enemy_container()
	for x in range(enemies_per_room):
		var enemy_scene = enemy_scenes.pick_random()
		var enemy = enemy_scene.instantiate()
		enemy.global_position.x = global_position.x + room_width/2 - tile_size * 3 + randf_range(-room_width/4, room_width/4)
		enemy.global_position.y = global_position.y + room_height/2 - tile_size + randf_range(-room_height/4, room_height/4)
		enemies.add_child(enemy)
		
		alive_enemies.append(enemy)
		enemy.tree_exited.connect(_on_enemy_died.bind(enemy))

func _on_enemy_died(enemy):
	var last_position = enemy.global_position
	alive_enemies.erase(enemy)
	
	GameState.kills += 1
	
	if alive_enemies.is_empty():
		on_room_cleared()
		if randf() < key_spawn_rate:
			drop_key(last_position)

func drop_key(pos):
	var key = key_scene.instantiate()
	key.global_position = pos
	if self.get_parent():  # room node still exists
		self.get_parent().add_child(key)

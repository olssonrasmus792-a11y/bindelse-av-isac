extends Node2D

@onready var player := get_tree().get_first_node_in_group("player")

@export var enemy_scene := preload("res://Scenes/Enemies/Muddy.tscn")
@export var snail_scene := preload("res://Scenes/Enemies/Snail.tscn")
@export var stoney_scene := preload("res://Scenes/Enemies/stoney.tscn")
@export var ghosty_scene := preload("res://Scenes/Enemies/ghosty.tscn")
@export var clover_boss_scene := preload("res://Scenes/clover_boss.tscn")
@onready var ui: CanvasLayer = $"../UI"

var spawn_muddy = false
var spawn_snail = false
var spawn_stoney = false
var spawn_clover_boss = false
var spawn_ghosty = true

var ghosty_timer = 0.0
var ghosty_spawn_interval = 5.0
var ghost_increase_timer = 0.0
var ghost_increase_interval = 5.0
var ghosty_bonus_speed = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GameState.boss_spawned and !GameState.boss_killed:
		ghosty_spawn_interval = 4.0
		ghosty_bonus_speed = 60
	
	if GameState.time_left <= 0:
		ghosty_timer += delta
		if GameState.boss_killed:
			ghosty_timer += delta
		ghost_increase_timer += delta
	
	if ghost_increase_timer >= ghost_increase_interval:
		ghost_increase_timer = 0.0
		ghosty_spawn_interval -= 0.25
		ghosty_bonus_speed += 15
		ghosty_spawn_interval = clampf(ghosty_spawn_interval, 0.1, 5.0)
	
	if ghosty_timer >= ghosty_spawn_interval:
		ghosty_timer = 0.0
		var roll = randf()
		var dir
		if roll < 0.5:
			dir = -1
		else:
			dir = 1
		spawn_enemy(Vector2(player.global_position.x + (randi_range(1200, 2000) * dir), player.global_position.y + (randi_range(800, 1600) * dir)))

func spawn_enemy(pos: Vector2):
	if player.is_dead:
		return
	
	if spawn_muddy:
		var muddy = enemy_scene.instantiate()
		muddy.global_position = pos
		get_parent().add_child(muddy)
	
	if spawn_snail:
		var snail = snail_scene.instantiate()
		snail.global_position = pos
		get_parent().add_child(snail)
	
	if spawn_stoney:
		var stoney = stoney_scene.instantiate()
		stoney.global_position = pos
		get_parent().add_child(stoney)
	
	if spawn_clover_boss:
		var clover_boss = clover_boss_scene.instantiate()
		clover_boss.global_position = pos
		get_parent().add_child(clover_boss)
	
	if spawn_ghosty:
		var arrow_manager = get_tree().get_first_node_in_group("arrow_manager")
		var ghosty = ghosty_scene.instantiate()
		
		ghosty.global_position = pos
		ghosty.speed = ghosty.base_speed + ghosty_bonus_speed
		
		await get_tree().create_timer(0.1).timeout
		
		if GameState.boss_spawned and !GameState.boss_killed:
			ghosty.max_health = 1
			ghosty.health = 1
		
		if arrow_manager and !GameSettings.dark_mode:
			arrow_manager.create_arrow(ghosty)
		
		get_parent().add_child(ghosty)

func _on_spawn_enemy_pressed() -> void:
	for x in range(1):
		spawn_enemy(Vector2(randf_range(400, 1600), randf_range(400, 1600)))

func _on_spawn_enemies_signal(pos) -> void:
	spawn_enemy(pos)

func _on_remove_enemies_pressed() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_in_group("boss"):
			continue
		if "health" in enemy:
			enemy.health = 0.0
			if enemy.has_method("take_damage"):
				enemy.take_damage(0)
			elif enemy.has_method("explode"):
				enemy.explode(enemy) 
			else:
				enemy.queue_free()

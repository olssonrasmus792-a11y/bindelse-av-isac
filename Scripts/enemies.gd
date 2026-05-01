extends Node2D

@export var enemy_scene := preload("res://Scenes/Enemies/Muddy.tscn")
@export var snail_scene := preload("res://Scenes/Enemies/Snail.tscn")
@export var stoney_scene := preload("res://Scenes/Enemies/stoney.tscn")
@export var clover_boss_scene := preload("res://Scenes/clover_boss.tscn")
@onready var ui: CanvasLayer = $"../UI"

var spawn_muddy = false
var spawn_snail = false
var spawn_stoney = false
var spawn_clover_boss = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func spawn_enemy(pos: Vector2):
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

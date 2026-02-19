extends Node2D

@export var explosion_scene = preload("res://Scenes/barrel_explosion.tscn")
@export var coin_scene = preload("res://Scenes/Coin.tscn")
@export var key_scene := preload("res://Scenes/Key.tscn")
@export var heart_scene := preload("res://Heart.tscn")

var coin_spawn_chance = 0.4
var key_spawn_chance = 0.05
var hp_spawn_chance = 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func hit():
	drop_loot()
	
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = position
	get_parent().call_deferred("add_child", explosion)  # defer adding
	explosion.emitting = true
	
	queue_free()

func drop_loot():
	
	if randf() < coin_spawn_chance:
		var item = coin_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-25, 25), randi_range(-25, 25))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	if randf() < key_spawn_chance:
		var item = key_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-25, 25), randi_range(-25, 25))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	if randf() < hp_spawn_chance:
		var item = heart_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-25, 25), randi_range(-25, 25))
		get_parent().call_deferred("add_child", item)  # defer adding

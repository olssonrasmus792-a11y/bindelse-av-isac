extends Node2D

@export var item_to_spawn: ItemData

@onready var item_scene := preload("res://Scenes/item.tscn")

func spawn_items():
	if item_to_spawn == null:
		return

	for spawn in $SpawnPoints.get_children():
		var item = item_scene.instantiate()
		item.position = spawn.global_position
		item.data = item_to_spawn

		get_tree().current_scene.call_deferred("add_child", item)

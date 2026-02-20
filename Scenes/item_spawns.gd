extends Node2D

@export var all_items: Array[ItemData] = []
@onready var item_scene = preload("res://Scenes/item.tscn")
@onready var spawn_points = $SpawnPoints.get_children()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_items()
	for spawn in spawn_points:
		spawn_random_item(spawn.global_position)

func spawn_random_item(pos):
	if all_items.is_empty():
		push_error("No possible_items assigned!")
		return

	var item = item_scene.instantiate()
	item.position = pos
	item.data = all_items.pick_random()
	add_child(item)

func load_items():
	all_items.clear()

	var dir = DirAccess.open("res://Resources/Items")
	if dir == null:
		push_error("Items folder not found!")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var item: ItemData = load("res://Resources/Items/" + file_name)
			if item:
				all_items.append(item)
		file_name = dir.get_next()

	dir.list_dir_end()

	print("Loaded items:", all_items.size())

extends Node2D

@export var all_items: Array[ItemData] = []
@onready var item_scene = preload("res://Scenes/item.tscn")
@onready var spawn_points = $SpawnPoints.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_items() #asdasd
	for spawn in spawn_points:
		spawn_random_item(spawn.global_position)

func _process(_delta: float) -> void:
	if (get_children().size() - 1) < 3:
		get_parent().queue_free()

func spawn_random_item(pos):
	if all_items.is_empty():
		return  # Nothing left to spawn

	# Pick a random index
	var index = randi() % all_items.size()
	var item_data = all_items[index].duplicate()

	# Remove it from the list so it won't spawn again
	all_items.remove_at(index)

	# Instantiate the item and set it up
	var item = item_scene.instantiate()
	item.position = pos
	item.data = item_data
	item_data.price = 0
	add_child(item)

func load_items():
	all_items.clear()

	var dir = DirAccess.open("res://Resources/Items")
	if dir == null:
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

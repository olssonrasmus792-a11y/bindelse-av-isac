extends Node2D

var rarity_weights = {
	ItemData.Rarity.COMMON: 50,
	ItemData.Rarity.RARE: 20,
	ItemData.Rarity.EPIC: 0,
	ItemData.Rarity.LEGENDARY: 0
}

@export var all_items: Array[ItemData] = []
@onready var item_scene = preload("res://Scenes/item.tscn")
@onready var spawn_points = $SpawnPoints.get_children()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_items()
	for spawn in spawn_points:
		spawn_random_item(spawn.global_position)

func _process(_delta: float) -> void:
	if (get_children().size() - 1) < 3:
		get_parent().queue_free()

func spawn_random_item(pos):
	if all_items.is_empty():
		return

	var item_data: ItemData = get_weighted_random_item()

	# remove the ORIGINAL so it can’t spawn again
	all_items.erase(item_data)

	# create runtime copy (for the world)
	var runtime_data: ItemData = item_data.duplicate()
	runtime_data.price = 0

	var item = item_scene.instantiate()
	item.position = pos
	item.data = runtime_data

	add_child(item)

func get_weighted_random_item():
	var total_weight = 0
	var adjusted_weights = []

	var luck = GameState.luck  # or wherever you store it

	# Build adjusted weights per item
	for item in all_items:
		var base_weight = rarity_weights.get(item.rarity, 1)
		var weight = base_weight

		# Apply luck scaling here
		match item.rarity:
			ItemData.Rarity.COMMON:
				weight *= max(0.1, 1.0 - luck * 0.05) # reduce commons
			ItemData.Rarity.RARE:
				weight *= 1.0 + luck * 0.06
			ItemData.Rarity.EPIC:
				weight *= 1.0 + luck * 0.10
			ItemData.Rarity.LEGENDARY:
				weight *= 1.0 + luck * 0.15

		adjusted_weights.append(weight)
		total_weight += weight

	# Roll
	var rand_value = randf() * total_weight
	var current_sum = 0

	for i in range(all_items.size()):
		current_sum += adjusted_weights[i]
		if rand_value < current_sum:
			return all_items[i]

	return all_items[0]

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

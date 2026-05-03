extends Node2D

var rarity_weights = {
	ItemData.Rarity.COMMON: 50,
	ItemData.Rarity.RARE: 20,
	ItemData.Rarity.EPIC: 8,
	ItemData.Rarity.LEGENDARY: 2
}

@export var item_registry: ItemRegistry

@onready var item_scene = preload("res://Scenes/item.tscn")
@onready var spawn_points = $SpawnPoints.get_children()

var local_items: Array[ItemData] = []


func _ready() -> void:
	if item_registry == null:
		push_error("ItemRegistry is not assigned!")
		return

	# Make a COPY so we can safely remove items
	local_items = item_registry.items.duplicate()

	for spawn in spawn_points:
		spawn_random_item(spawn.global_position)


func spawn_random_item(pos):
	if local_items.is_empty():
		return

	var item_data = get_weighted_random_item(local_items)

	# remove so it can’t appear again in this batch
	local_items.erase(item_data)

	var item = item_scene.instantiate()
	item.position = pos
	item.data = item_data
	add_child(item)


func get_weighted_random_item(items: Array):
	var total_weight := 0.0
	var adjusted_weights := []

	var luck = GameState.luck

	for item in items:
		var weight = rarity_weights.get(item.rarity, 1)

		match item.rarity:
			ItemData.Rarity.COMMON:
				weight *= max(0.1, 1.0 - luck * 0.05)
			ItemData.Rarity.RARE:
				weight *= 1.0 + luck * 0.06
			ItemData.Rarity.EPIC:
				weight *= 1.0 + luck * 0.10
			ItemData.Rarity.LEGENDARY:
				weight *= 1.0 + luck * 0.15

		adjusted_weights.append(weight)
		total_weight += weight

	var roll = randf() * total_weight
	var current := 0.0

	for i in range(items.size()):
		current += adjusted_weights[i]
		if roll < current:
			return items[i]

	return items[0]

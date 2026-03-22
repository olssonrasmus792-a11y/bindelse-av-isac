extends Control

@onready var grid = $ItemsGrid
@onready var tooltip: Panel = $Tooltip
@onready var item_name: Label = $Tooltip/ItemName
@onready var item_description: Label = $Tooltip/ItemDescription
@onready var item_icon: TextureRect = $Tooltip/ItemIcon
@onready var item_amount: Label = $Tooltip/ItemAmount
@onready var item_damage: Label = $Tooltip/ItemDamage

var slot_scene = preload("res://Scenes/item_slot.tscn")

func _process(_delta):
	if tooltip.visible:
		tooltip.global_position = get_global_mouse_position() + Vector2(10, 10)

func display_inventory():
	# Clear old slots
	for child in grid.get_children():
		child.queue_free()

	var stacked_items = get_stacked_items(GameState.taken_items)

	for item in stacked_items.keys():
		var count = stacked_items[item]

		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slot.set_item(item, count)

		slot.hovered.connect(_on_item_hovered)
		slot.unhovered.connect(_on_item_unhovered)

func get_stacked_items(items: Array) -> Dictionary:
	var stacked := {}

	for item in items:
		if stacked.has(item):
			stacked[item] += 1
		else:
			stacked[item] = 1

	return stacked

func _on_item_hovered(item: ItemData, count: int):
	tooltip.visible = true
	item_name.text = item.name
	item_description.text = item.description
	item_icon.texture = item.icon
	item_amount.text = "x" + str(count)
	if item.damage_dealt > 0:
		item_damage.text = "Damage dealt: " + str(item.damage_dealt)
	else:
		item_damage.text = ""

func _on_item_unhovered():
	tooltip.visible = false

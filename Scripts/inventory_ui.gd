extends Control

@onready var grid = $ItemsGrid
@onready var tooltip: Panel = $Tooltip
@onready var item_name: Label = $Tooltip/ItemName
@onready var item_description: RichTextLabel = $Tooltip/ItemDescription
@onready var item_icon: TextureRect = $Tooltip/ItemIcon
@onready var item_amount: Label = $Tooltip/ItemAmount
@onready var item_tracked_stats: RichTextLabel = $Tooltip/ItemTrackedStats

var slot_scene = preload("res://Scenes/item_slot.tscn")

func _process(_delta):
	if tooltip.visible:
		tooltip.global_position = get_global_mouse_position() + Vector2(10, 10)

func display_inventory():
	# Clear old slots
	for child in grid.get_children():
		child.queue_free()

	var stacked_items = get_stacked_items(GameState.taken_items)

	for key in stacked_items.keys():

		var entry = stacked_items[key]

		var item = entry["item"]
		var count = entry["count"]

		var slot = slot_scene.instantiate()
		grid.add_child(slot)

		slot.set_item(item, count)

		slot.hovered.connect(_on_item_hovered)
		slot.unhovered.connect(_on_item_unhovered)

func get_stacked_items(items: Array) -> Dictionary:
	var stacked := {}

	for item in items:

		var key = item.name

		if not stacked.has(key):
			stacked[key] = {
				"item": item,
				"count": 0,
				"values": item.tracked_stat_values.duplicate()
			}

		stacked[key]["count"] += 1

		# Add tracked values
		for i in range(item.tracked_stat_values.size()):
			stacked[key]["values"][i] += item.tracked_stat_values[i]

	return stacked

func _on_item_hovered(item: ItemData, count: int):

	tooltip.visible = true

	item_name.text = item.name
	item_description.text = item.description

	if item.description == "":
		item_description.text = get_stats_text(
			item.stats,
			item.stat_colors
		)

	item_icon.texture = item.icon
	item_amount.text = "x" + str(count)

	var tracked_text := ""

	for i in range(item.tracked_stats.size()):

		var stat_name = item.tracked_stats[i]
		var stat_value = item.tracked_stat_values[i]
		var stat_is_percentage = item.tracked_stat_value_percentage[i]
		var color = item.tracked_stat_colors[i]

		tracked_text += "[color=" + color.to_html() + "]"
		tracked_text += stat_name + ": " + str(stat_value)
		
		if stat_is_percentage:
			tracked_text += "%"
		
		tracked_text += "[/color]"

		if i < item.tracked_stats.size() - 1:
			tracked_text += "\n"

	item_tracked_stats.text = tracked_text

func _on_item_unhovered():
	tooltip.visible = false

func get_stats_text(stats: Array[String], stat_colors: Array[Color]) -> String:
	var text := ""
	
	for i in range(stats.size()):
		var stat = stats[i]
		
		# fallback color if missing
		var color = Color.WHITE
		if i < stat_colors.size():
			color = stat_colors[i]
		
		text += "[color=#%s]• %s[/color]\n" % [color.to_html(), stat]
	
	return text.strip_edges()

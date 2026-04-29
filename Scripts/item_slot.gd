# item_slot.gd
extends TextureRect

signal hovered(item)
signal unhovered()

@onready var count_label: Label = $CountLabel
var rarity_color

var item: ItemData
var count: int = 1

func set_item(new_item: ItemData, new_count: int = 1):
	item = new_item
	count = new_count

	match item.rarity:
			ItemData.Rarity.COMMON:
				rarity_color = Color(0.873, 0.873, 0.873, 1.0)
			ItemData.Rarity.RARE:
				rarity_color = Color(0.2, 0.435, 1.0, 1.0)
			ItemData.Rarity.EPIC:
				rarity_color = Color(0.484, 0.003, 0.983)
			ItemData.Rarity.LEGENDARY:
				rarity_color = Color(1.0, 1.0, 0.0, 1.0)
	count_label.modulate = rarity_color
	
	texture = item.icon

	if count_label and count > 1:
		count_label.text = "x" + str(count)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _on_mouse_entered() -> void:
	emit_signal("hovered", item, count)


func _on_mouse_exited() -> void:
	emit_signal("unhovered")

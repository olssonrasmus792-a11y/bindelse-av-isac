# item_slot.gd
extends TextureRect

signal hovered(item)
signal unhovered()

@onready var count_label: Label = $CountLabel

var item: ItemData
var count: int = 1

func set_item(new_item: ItemData, new_count: int = 1):
	item = new_item
	count = new_count

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
	emit_signal("hovered", item)


func _on_mouse_exited() -> void:
	emit_signal("unhovered")

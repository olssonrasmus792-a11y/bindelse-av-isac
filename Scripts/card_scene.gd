extends Control
class_name CardScene

signal upgrade_chosen(card_data: CardData)

@export var card_data: CardData  # MUST be CardData, not Resource
# UI references
@onready var name_label = $Panel/Label
@onready var level_label = $Panel/Label2
@onready var upgrade_button = $Panel/Button

func _ready():
	if card_data:
		name_label.text = card_data.card_name
	level_label.text = "Level: " + str(card_data.current_level)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	update_button_state()


func _on_upgrade_pressed():
	emit_signal("upgrade_chosen", card_data)
	if card_data.current_level < card_data.max_level:
		card_data.current_level += 1

func update_button_state():
	upgrade_button.disabled = card_data.current_level >= card_data.max_level

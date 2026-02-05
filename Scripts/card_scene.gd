extends Control

@export var card_data: CardData  # MUST be CardData, not Resource

var level: int = 1

# UI references
@onready var name_label = $Panel/Label
@onready var level_label = $Panel/Label2
@onready var upgrade_button = $Panel/Button

func _ready():
	if card_data:
		name_label.text = card_data.card_name
	level_label.text = "Level: %d" % level
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	update_button_state()


func _on_upgrade_pressed():
	if level < card_data.max_level:
		level += 1
		level_label.text = "Level: %d" % level
		update_button_state()

func update_button_state():
	upgrade_button.disabled = level >= card_data.max_level

extends Control
class_name CardScene

signal upgrade_chosen(card_data: CardData)

@export var card_data: CardData  # MUST be CardData, not Resource
# UI references
@onready var name_label = $Panel/Label
@onready var level_label = $Panel/Label2
@onready var desc_label: Label = $Panel/Label3
@onready var rarity_label: Label = $Panel/Label4
@onready var upgrade_button = $Panel/Button
@onready var icon: TextureRect = $Panel/Panel/TextureRect
@onready var panel: Panel = $Panel

func _ready():
	if card_data:
		name_label.text = card_data.card_name
		desc_label.text = card_data.description
		rarity_label.text = card_data.rarity
		icon.texture = card_data.icon
		level_label.text = "Level: " + str(card_data.current_level)
	
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	match card_data.rarity:
		"Uncommon":
			style.bg_color = Color.DIM_GRAY
		"Rare":
			style.bg_color = Color.ROYAL_BLUE
		"Epic":
			style.bg_color = Color.REBECCA_PURPLE
		"Legendary":
			style.bg_color = Color.GOLD

	panel.add_theme_stylebox_override("panel", style)
	
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	update_button_state()


func _on_upgrade_pressed():
	emit_signal("upgrade_chosen", card_data)
	if card_data.current_level < card_data.max_level:
		card_data.current_level += 1

func update_button_state():
	upgrade_button.disabled = card_data.current_level >= card_data.max_level

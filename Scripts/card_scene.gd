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
@onready var inner_panel: Panel = $Panel/Panel

@export var appear_duration: float = 0
@export var start_scale: Vector2 = Vector2(0.8, 0.8)

var rarity_color
var target_y

func _ready():
	
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var inner_style := inner_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	match card_data.rarity:
		"Uncommon":
			rarity_color = Color.MEDIUM_SEA_GREEN
		"Rare":
			rarity_color = Color.ROYAL_BLUE
		"Epic":
			rarity_color = Color.REBECCA_PURPLE
		"Legendary":
			rarity_color = Color.GOLD
	
	print("Rarity Color: ", card_data.rarity)
	
	if card_data:
		name_label.text = card_data.card_name
		desc_label.text = card_data.description
		rarity_label.text = card_data.rarity
		icon.texture = card_data.icon
		level_label.text = "Level: " + str(card_data.current_level)
		style.border_color = rarity_color
		inner_style.border_color = rarity_color
		rarity_label.add_theme_color_override("font_color", rarity_color)
	
	panel.add_theme_stylebox_override("panel", style)
	inner_panel.add_theme_stylebox_override("panel", inner_style)
	
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	update_button_state()
	
	# Start small and transparent
	scale = start_scale
	modulate.a = 0.0
	
	target_y = position.y
	position.y += 2000
	
	appear()

func appear():
	var tween = create_tween()
	
	# Scale up with a slight bounce
	tween.tween_property(self, "scale", Vector2(1, 1), appear_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 1.0, appear_duration)


func _on_upgrade_pressed():
	emit_signal("upgrade_chosen", card_data)
	if card_data.current_level < card_data.max_level:
		card_data.current_level += 1

func update_button_state():
	upgrade_button.disabled = card_data.current_level >= card_data.max_level

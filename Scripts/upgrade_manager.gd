extends Control

@onready var player := get_tree().get_first_node_in_group("player")
@export var card_scene = preload("res://Scenes/card_scene.tscn")
@onready var cards_container: HBoxContainer = $HBoxContainer

var all_cards = [
	preload("res://Resources/Damage.tres"),
	preload("res://Resources/Speed.tres"),
	preload("res://Resources/Stamina.tres"),
	preload("res://Resources/Health.tres")
]

func _ready():
	#spawn_random_cards(3)
	pass

func spawn_random_cards(count: int):
	clear_cards()
	# Make a copy of the list so we don't remove originals
	var available_cards = all_cards.duplicate()
	available_cards.shuffle()  # Randomize order

	# Take first 'count' cards
	var selected_cards = available_cards.slice(0, count)

	for card_data in selected_cards:
		var card_instance = card_scene.instantiate()
		card_instance.card_data = card_data  # Assign unique data
		card_instance.upgrade_chosen.connect(_on_upgrade_chosen)
		cards_container.add_child(card_instance)
	
	visible = true

func clear_cards():
	for child in cards_container.get_children():
		child.queue_free()


func _on_upgrade_chosen(card_data: CardData):
	print("player chose: ", card_data.card_name)
	
	apply_upgrade(card_data)
	close_upgrade_screen()

func apply_upgrade(card_data: CardData):

	match card_data.card_name:
		"Damage":
			player.damage += 1
		"Speed":
			player.max_speed *= 1.2
		"Health":
			player.max_health += 1
			player.health += 1
			player.update_health()
		"Stamina":
			player.max_stamina += 1
			player.update_stamina_ui()

func close_upgrade_screen():
	clear_cards()
	visible = false

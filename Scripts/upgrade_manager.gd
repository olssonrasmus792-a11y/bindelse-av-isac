extends Control

@export var card_scene = preload("res://Scenes/card_scene.tscn")
@onready var cards_container: HBoxContainer = $HBoxContainer

var all_cards = [
	preload("res://Resources/Damage.tres"),
	preload("res://Resources/Speed.tres"),
	preload("res://Resources/Stamina.tres"),
	preload("res://Resources/Health.tres")
]

func _ready():
	spawn_random_cards(3)

func spawn_random_cards(count: int):
	# Make a copy of the list so we don't remove originals
	var available_cards = all_cards.duplicate()
	available_cards.shuffle()  # Randomize order

	# Take first 'count' cards
	var selected_cards = available_cards.slice(0, count)

	for card_data in selected_cards:
		var card_instance = card_scene.instantiate()
		card_instance.card_data = card_data  # Assign unique data
		cards_container.add_child(card_instance)

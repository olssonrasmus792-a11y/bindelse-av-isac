extends Control

@onready var player := get_tree().get_first_node_in_group("player")
@export var card_scene = preload("res://Scenes/card_scene.tscn")
@onready var cards_container: HBoxContainer = $HBoxContainer

@export var uncommon_chance = 0.5
@export var rare_chance = 0.3
@export var epic_chance = 0.15
@export var legendary_chance = 0.05

var all_cards := []

func _ready():
	var dir = DirAccess.open("res://Resources/Cards")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card = load("res://Resources/Cards/" + file_name)
				all_cards.append(card)
			file_name = dir.get_next()

func spawn_random_cards(count: int):
	clear_cards()
	# Make a copy of the list so we don't remove originals
	var available_cards = all_cards.duplicate()
	
	available_cards = available_cards.filter(func(card):
		return card.current_level < card.max_level
		)
	
	available_cards.shuffle()  # Randomize order
	
	# Take first 'count' cards
	var selected_cards = available_cards.slice(0, count)
	
	for card_data in selected_cards:
		var card_instance = card_scene.instantiate()
		card_instance.card_data = card_data  # Assign unique data
		if card_instance.card_data.current_level >= card_instance.card_data.max_level:
			return
		card_instance.upgrade_chosen.connect(_on_upgrade_chosen)
		#card_instance.card_data.rarity = choose_rarity()
		cards_container.add_child(card_instance)
	
	if available_cards.is_empty():
		print("No upgrades available")
		close_upgrade_screen()
		return
	
	visible = true

func clear_cards():
	for child in cards_container.get_children():
		child.queue_free()

func choose_rarity():
	var roll := randf()
	
	if roll < legendary_chance:
		return "Legendary"
	elif roll < epic_chance:
		return "Epic"
	elif roll < rare_chance:
		return "Rare"
	else:
		return "Uncommon"

func _on_upgrade_chosen(card_data: CardData):
	print("player chose: ", card_data.card_name)
	
	GameState.taken_upgrades[card_data.card_name] = true
	
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
	get_tree().paused = false

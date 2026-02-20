extends Control

@onready var player := get_tree().get_first_node_in_group("player")
@onready var sword := get_tree().get_first_node_in_group("sword")
var card_scene = preload("res://Scenes/card_scene.tscn")
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
	
	var available_cards = all_cards.duplicate()
	
	# Filter out maxed cards
	available_cards = available_cards.filter(func(card):
		return card.current_level < card.max_level
	)

	if available_cards.is_empty():
		print("No upgrades available")
		close_upgrade_screen()
		return
	
	var selected_cards := []
	
	# Assign weights based on rarity
	for i in range(count):
		if available_cards.is_empty():
			break
		
		# Calculate total weight
		var total_weight := 0.0
		for card in available_cards:
			total_weight += get_rarity_weight(card.rarity)
		
		# Roll a random number up to total_weight
		var roll := randf() * total_weight
		var cumulative := 0.0
		var chosen_card = null
		
		for card in available_cards:
			cumulative += get_rarity_weight(card.rarity)
			if roll <= cumulative:
				chosen_card = card
				break
		
		if chosen_card:
			selected_cards.append(chosen_card)
			available_cards.erase(chosen_card)
	
	# Spawn the card nodes
	for card_data in selected_cards:
		var card_instance = card_scene.instantiate()
		card_instance.card_data = card_data
		card_instance.upgrade_chosen.connect(_on_upgrade_chosen)
		cards_container.add_child(card_instance)
	
	visible = true

func clear_cards():
	for child in cards_container.get_children():
		child.queue_free()

# Define weight per rarity (rarer = lower weight)
func get_rarity_weight(rarity: String) -> float:
	match rarity:
		"Uncommon":
			return 1.0
		"Rare":
			return 0.5
		"Epic":
			return 0.2
		"Legendary":
			return 0.02
		_:
			return 1.0

func _on_upgrade_chosen(card_data: CardData):
	GameState.taken_upgrades[card_data.card_name] = true
	apply_upgrade(card_data)
	close_upgrade_screen()

func apply_upgrade(card_data: CardData):

	match card_data.card_name:
		"Big Biceps":
			player.damage += 1
		"Speedy":
			player.max_speed *= 1.15
			player.speed = player.max_speed
		"Healthy Boy":
			player.max_health += 1
			player.health += 1
			player.update_health()
		"Cardio Maxxing":
			player.max_stamina += 1
			player.update_stamina_ui()
		"Cardio Enjoyer":
			player.stamina_regen -= 0.25
		"Big Ass Sword":
			sword.scale_factor *= 1.5
		"Speedy Attacks":
			player.attack_speed -= 0.25


func close_upgrade_screen():
	clear_cards()
	visible = false
	get_tree().paused = false

extends Control

@onready var player := get_tree().get_first_node_in_group("player")
@onready var sword := get_tree().get_first_node_in_group("sword")

var card_scene = preload("res://Scenes/card_scene.tscn")

@onready var cards_container: HBoxContainer = $HBoxContainer
@onready var pop_4: AudioStreamPlayer = $Pop4
@onready var pop_3: AudioStreamPlayer = $Pop3
@onready var coin: AudioStreamPlayer = $Coin

@export var card_registry: CardRegistry

var local_cards: Array[CardData] = []


func spawn_random_cards(count: int):
	clear_cards()
	pop_3.play()

	if card_registry == null:
		push_error("CardRegistry not assigned!")
		return

	# snapshot pool (IMPORTANT)
	local_cards = card_registry.cards.duplicate()

	# filter maxed upgrades
	local_cards = local_cards.filter(func(card):
		return card.current_level < card.max_level
	)

	if local_cards.is_empty():
		print("No upgrades available")
		close_upgrade_screen()
		return

	var selected_cards: Array = []

	for i in range(count):
		if local_cards.is_empty():
			break

		var chosen = roll_card(local_cards)
		if chosen == null:
			break

		selected_cards.append(chosen)
		local_cards.erase(chosen) # no duplicates in this roll

	# spawn UI cards
	for card_data in selected_cards:
		var card_instance = card_scene.instantiate()
		card_instance.card_data = card_data
		card_instance.upgrade_chosen.connect(_on_upgrade_chosen)
		cards_container.add_child(card_instance)

	visible = true


func roll_card(cards: Array):
	var total_weight := 0.0
	var weights := []

	for card in cards:
		var w = get_rarity_weight(card.rarity)
		weights.append(w)
		total_weight += w

	var roll = randf() * total_weight
	var sum := 0.0

	for i in range(cards.size()):
		sum += weights[i]
		if roll <= sum:
			return cards[i]

	return cards[0]


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


func clear_cards():
	for child in cards_container.get_children():
		child.queue_free()


func _on_upgrade_chosen(card_data: CardData):
	GameState.taken_upgrades[card_data.card_name] = true
	pop_4.play()
	coin.play()

	apply_upgrade(card_data)
	close_upgrade_screen()


func apply_upgrade(card_data: CardData):
	match card_data.card_name:
		"Big Biceps":
			player.damage += 4

		"Speedy":
			player.max_speed *= 1.05
			player.speed = player.max_speed

		"Healthy Boy":
			player.max_health += 1
			player.health += 1
			player.update_health()

		"Cardio Maxxing":
			player.max_stamina += 1
			player.update_stamina_ui()

		"Cardio Enjoyer":
			player.stamina_regen -= 0.1


func close_upgrade_screen():
	clear_cards()
	visible = false
	get_tree().paused = false

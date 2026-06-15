extends CanvasLayer

@onready var player := get_tree().get_first_node_in_group("player")
@onready var sword := get_tree().get_first_node_in_group("sword")

var card_scene = preload("res://Scenes/upgrade_card.tscn")

@onready var cards_container: HBoxContainer = $HBoxContainer
@onready var pop_4: AudioStreamPlayer = $Pop4
@onready var coin: AudioStreamPlayer = $Coin

@export var card_registry: CardRegistry

var local_cards: Array[CardData] = []
var upgrade_selected = false

func show_level_up():
	clear_cards()
	
	MusicManager.set_music_muffle(0.96)

	upgrade_selected = false
	visible = true
	get_tree().paused = true

	clear_cards()

	if card_registry == null:
		push_error("CardRegistry not assigned!")
		return

	# Copy registry cards
	local_cards = card_registry.cards.duplicate()

	# Remove maxed cards
	local_cards = local_cards.filter(func(card):
		var weapon_ok = card.required_weapon == "" or card.required_weapon == GameState.weapon
		return card.current_level < card.max_level and weapon_ok
	)

	if local_cards.is_empty():
		close_upgrade_screen()
		return

	var selected_cards: Array[CardData] = []

	# Pick 3 unique cards
	while selected_cards.size() < 3 and !local_cards.is_empty():
		var chosen = roll_card(local_cards)

		if chosen == null:
			break

		selected_cards.append(chosen)

		# Prevent duplicates
		local_cards.erase(chosen)



	var spawned_cards = []
	var delay := 0.2

# Spawn all cards first
	for card_data in selected_cards:
		var card = card_scene.instantiate()

		card.card_data = card_data

		card.selected.connect(_on_card_selected)

		cards_container.add_child(card)

		spawned_cards.append(card)

	# Wait for HBoxContainer layout
	await get_tree().process_frame

	# Animate cards
	for i in range(spawned_cards.size()):
		var card = spawned_cards[i]

		# EXACT old animation setup
		card.position.y = 800
		card.scale = Vector2.ZERO
		card.modulate.a = 1.0

		var tween = create_tween()

		tween.tween_interval(i * delay)

		tween.tween_property(
			card,
			"position:y",
			60,
			0.5
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(
			card,
			"scale",
			Vector2.ONE,
			0.3
		)


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
	var luck_multiplier = 1.0 + (GameState.luck / 100.0)

	match rarity:
		"Uncommon":
			return 1.0 / pow(luck_multiplier, 0.2)

		"Rare":
			return 0.6 * pow(luck_multiplier, 0.4)

		"Epic":
			return 0.25 * pow(luck_multiplier, 0.8)

		"Legendary":
			return 0.1 * pow(luck_multiplier, 1.2)

		"Unique":
			return 0.2 * pow(luck_multiplier, 0.9)

		_:
			return 1.0


func clear_cards():
	for child in cards_container.get_children():
		child.queue_free()


func _on_card_selected(card):
	if upgrade_selected:
		return
	
	upgrade_selected = true
	pop_4.play()
	coin.play()
	var card_data: CardData = card.card_data

	# Level up
	if card_data.current_level < card_data.max_level:
		card_data.current_level += 1

	apply_upgrade(card_data)

	# Animate unselected cards away
	for c in cards_container.get_children():
		if c != card:
			var tween = create_tween()

			tween.tween_property(c, "modulate:a", 0.0, 0.2)
			tween.parallel().tween_property(c, "scale", Vector2.ZERO, 0.2)

	# Selected card animation
	var tween2 = create_tween()

	tween2.tween_property(card, "scale", Vector2(1.1, 1.1), 0.15)

	tween2.tween_interval(0.1)

	tween2.tween_property(card, "scale", Vector2.ZERO, 0.25)

	await tween2.finished

	close_upgrade_screen()


func apply_upgrade(card_data: CardData):
	GameState.taken_upgrades.append(card_data)
	
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
		
		"Lucky Guy":
			GameState.luck += 0.07
			for item in GameState.taken_items:
				if item.name == "Clover":
					item.tracked_stat_values[0] = int(GameState.luck * 100)
			GameState.calculate_stats()
		
		"The Thinker":
			player.xp_gain += 0.2
		
		"Sweeping Edge":
			player.sword.scale_factor += 0.25
			player.sword.distance_from_player -= 5
			player.sword.max_distance += 50
		
		"Bomberman":
			player.explosion_damage += 8
		
		"Walter White":
			player.knockback *= 1.1
		
		"Negotiator":
			for item in get_tree().get_nodes_in_group("item"):
				if item.final_price > 0:
					item.final_price -= 1
		
		"Strong Arm":
			player.sword.max_distance *= 1.15
		
		"Quick Throws":
			player.ability_cooldown -= 2.0
		
		"Rapid Bonk":
			player.ability_cooldown -= 1.5
		
		"Bigger Bonk":
			player.ability_damage_mult += 0.25


func close_upgrade_screen():
	clear_cards()
	
	MusicManager.set_music_muffle(0.0)
	
	visible = false
	
	get_tree().paused = false


func _on_discard_pressed() -> void:
	close_upgrade_screen()

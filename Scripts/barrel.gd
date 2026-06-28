extends RigidBody2D

var rarity_weights = {
	ItemData.Rarity.COMMON: 50,
	ItemData.Rarity.RARE: 20,
	ItemData.Rarity.EPIC: 10,
	ItemData.Rarity.LEGENDARY: 3
}

@onready var player := get_tree().get_first_node_in_group("player")
@export var item_registry: ItemRegistry

@onready var item_scene = preload("res://Scenes/item.tscn")
@export var explosion_scene = preload("res://Scenes/barrel_explosion.tscn")
@export var coin_scene = preload("res://Scenes/Coin.tscn")
@export var key_scene := preload("res://Scenes/Key.tscn")
@export var heart_scene := preload("res://Scenes/Heart_pickup.tscn")
@onready var sprite: Sprite2D = $Sprite2D
@onready var flying: AudioStreamPlayer = $Flying

@export var knockback_strength_player = 200
@export var knockback_strength = 1500
@export var knockback_duration = 0.6

var health = 2
var knocked_back = false
var spawned_by_player = false

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

var sprite_spin := 0.0

var item_pos_offset = 50

var coin_spawn_chance = 0.20
var hp_spawn_chance = 0.05
var key_spawn_chance = 0.01
var item_spawn_chance = 1.002

var local_items: Array[ItemData] = []


func _physics_process(delta):
	if sprite_spin != 0:
		sprite.rotation += sprite_spin * delta
		sprite_spin = lerp(sprite_spin, 0.0, 1 * delta) # slowly stop spinning

func hit():
	health -= 1
	
	if health <= 0:
		drop_loot()
		
		var explosion = explosion_scene.instantiate()
		
		explosion.scale = Vector2(player.explosion_size, player.explosion_size)
		
		explosion.global_position = position
		explosion.explosion_damage = player.explosion_damage
		explosion.explosion_particles = player.explosion_particles
		get_parent().call_deferred("add_child", explosion)  # defer adding
		explosion.emitting = true
		
		queue_free()

func drop_loot():
	if spawned_by_player:
		return
	
	if randf() < coin_spawn_chance * (1 + GameState.luck):
		var item = coin_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	if randf() < key_spawn_chance * (1 + GameState.luck):
		var item = key_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	if randf() < hp_spawn_chance * (1 + GameState.luck):
		var item = heart_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	print("Lucky Barrels: ", GameState.get_upgrade_count("Lucky Barrels"))
	if randf() < item_spawn_chance * (1 + GameState.luck) and GameState.get_upgrade_count("Lucky Barrels") > 0:
		spawn_item()

func apply_knockback(aim_direction: Vector2):
	flying.play(randf_range(0.25, 2.0))
	
	var knockback_direction = aim_direction.normalized()
	knocked_back = true

	# push the barrel
	apply_central_impulse(knockback_direction * knockback_strength)

	# add random spin 
	sprite_spin = randf_range(-20.0, 20.0)

func _on_body_entered(body: Node) -> void:
	await get_tree().physics_frame
	
	if body.name == "player" and spawned_by_player:
		return
	
	if knocked_back:
		hit()
	
	if body.is_in_group("barrel"):
		body.health = 0
		body.hit()

func spawn_item():
	local_items = item_registry.items.duplicate()
	
	if local_items.is_empty():
		print("Local items is empty")
		return

	var valid_items: Array = []

	for item in local_items:
		# Skip already taken unique items
		if item.unique and GameState.taken_items.has(item):
			print("Filtering out unique item...")
			continue

		valid_items.append(item)

	# No valid items left
	if valid_items.is_empty():
		print("No valid items")
		return

	var item_data = get_weighted_random_item(valid_items)

	# Remove from local chest pool
	local_items.erase(item_data)

	var runtime_data: ItemData = item_data.duplicate(true)
	runtime_data.original_price = runtime_data.price
	runtime_data.price = 0

	var item = item_scene.instantiate()
	item.global_position = global_position
	item.data = runtime_data

	print("Spawning item at: ", item.global_position)
	get_tree().current_scene.call_deferred("add_child", item)


func get_weighted_random_item(items: Array):
	var total_weight := 0.0
	var adjusted_weights := []

	var luck = GameState.luck
	var luck_multiplier = 1.0 + (luck / 100.0)

	for item in items:
		var weight = rarity_weights.get(item.rarity, 1)

		match item.rarity:
			ItemData.Rarity.COMMON:
				weight *= pow(luck_multiplier, -0.6)

			ItemData.Rarity.RARE:
				weight *= pow(luck_multiplier, 0.3)

			ItemData.Rarity.EPIC:
				weight *= pow(luck_multiplier, 0.7)

			ItemData.Rarity.LEGENDARY:
				weight *= pow(luck_multiplier, 1.0)

		adjusted_weights.append(weight)
		total_weight += weight

	var roll = randf() * total_weight
	var current := 0.0

	for i in range(items.size()):
		current += adjusted_weights[i]
		if roll < current:
			return items[i]

	return items[0]

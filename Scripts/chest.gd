extends Node2D

var rarity_weights = {
	ItemData.Rarity.COMMON: 50,
	ItemData.Rarity.RARE: 20,
	ItemData.Rarity.EPIC: 8,
	ItemData.Rarity.LEGENDARY: 2
}

@export var item_registry: ItemRegistry
@export var coin_scene = preload("res://Scenes/Coin.tscn")
@onready var item_scene = preload("res://Scenes/item.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var collision: CollisionShape2D = $CollisionClosed
@onready var label: Label = $NoKeys
@onready var pop_3: AudioStreamPlayer = $Pop3
@onready var deny: AudioStreamPlayer = $Deny
@onready var pop_up: Control = $PopUp
@onready var label_2: Label = $PopUp/Panel/Label2

var player_is_close = false
var chest_opened = false
var coin_amount

var local_items: Array[ItemData] = []

var lines = [
	"Holy moly!",
	"Wow!",
	"Nice bro",
	"Yippie!"
]


func _ready() -> void:
	if item_registry == null:
		push_error("ItemRegistry is not assigned!")
		return

	coin_amount = randi_range(2, 5)

	label.modulate.a = 0
	animated_sprite_2d.play("Closed")
	pop_up.visible = false

	# IMPORTANT: snapshot for THIS chest only (no duplicates inside chest)
	local_items = item_registry.items.duplicate()


func _process(delta: float) -> void:
	if label.modulate.a > 0:
		label.modulate.a -= delta * 0.5
		label.position.y -= delta * 20

	if GameState.boss_spawned:
		queue_free()

	label_2.modulate = Color.LIME_GREEN if GameState.keys >= 1 else Color.RED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_is_close and !chest_opened:
		if GameState.keys > 0:
			label.modulate.a = 1
			label.position.y = -88
			label.text = lines.pick_random()
			label.modulate = Color.YELLOW
			open_chest()
		else:
			shake_label()
			deny.play()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and !chest_opened:
		player_is_close = true
		pop_up.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false
		pop_up.visible = false


func open_chest():
	pop_3.play()
	animated_sprite_2d.play("Open")
	chest_opened = true
	pop_up.visible = false
	gpu_particles_2d.emitting = true

	GameState.keys -= 1

	for i in range(coin_amount):
		drop_coin(global_position)

	spawn_item()


func spawn_item():
	if local_items.is_empty():
		return

	var item_data = get_weighted_random_item(local_items)

	# REMOVE so no duplicates in this chest
	local_items.erase(item_data)

	if item_data.unique:
		item_registry.items.erase(item_data)

	var runtime_data: ItemData = item_data.duplicate()
	runtime_data.price = 0

	var item = item_scene.instantiate()
	item.global_position = global_position + Vector2(0, -16)
	item.data = runtime_data

	var dir = [-1, 1].pick_random()
	item.flying = true
	item.velocity = Vector2(randf_range(80, 140) * dir, -300)
	item.floor_y = global_position.y + 10

	get_tree().current_scene.add_child(item)


func get_weighted_random_item(items: Array):
	var total_weight := 0.0
	var adjusted_weights := []

	var luck = GameState.luck

	for item in items:
		var weight = rarity_weights.get(item.rarity, 1)

		match item.rarity:
			ItemData.Rarity.COMMON:
				weight *= max(0.1, 1.0 - luck * 0.05)
			ItemData.Rarity.RARE:
				weight *= 1.0 + luck * 0.06
			ItemData.Rarity.EPIC:
				weight *= 1.0 + luck * 0.10
			ItemData.Rarity.LEGENDARY:
				weight *= 1.0 + luck * 0.15

		adjusted_weights.append(weight)
		total_weight += weight

	var roll = randf() * total_weight
	var current := 0.0

	for i in range(items.size()):
		current += adjusted_weights[i]
		if roll < current:
			return items[i]

	return items[0]


func drop_coin(pos):
	var coin = coin_scene.instantiate()

	coin.global_position = pos
	var dir = [-1, 1].pick_random()
	coin.flying = true
	coin.velocity = Vector2(randf_range(100, 160) * dir, randf_range(-250, -500))
	coin.floor_y = global_position.y + randi_range(1, 25)

	get_tree().current_scene.add_child(coin)


func shake_label():
	var original_pos = label_2.position

	var strength = 10.0
	var duration = 0.15
	var elapsed = 0.0

	label_2.scale = Vector2(1.15, 1.15)

	while elapsed < duration:
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)

		label_2.position = original_pos + offset
		label_2.rotation = randf_range(-0.02, 0.02)

		await get_tree().process_frame

		elapsed += get_process_delta_time()
		strength = lerp(strength, 0.0, 0.35)
		label_2.scale = lerp(label_2.scale, Vector2.ONE, 0.25)

	label_2.position = original_pos
	label_2.rotation = 0
	label_2.scale = Vector2.ONE

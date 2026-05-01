extends Node2D

var rarity_weights = {
	ItemData.Rarity.COMMON: 50,
	ItemData.Rarity.RARE: 20,
	ItemData.Rarity.EPIC: 8,
	ItemData.Rarity.LEGENDARY: 2
}

@export var all_items: Array[ItemData] = []
@onready var item_scene = preload("res://Scenes/item.tscn")
@export var coin_scene = preload("res://Scenes/Coin.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var collision: CollisionShape2D = $CollisionClosed
@onready var label: Label = $NoKeys
@onready var pop_3: AudioStreamPlayer = $Pop3
@onready var deny: AudioStreamPlayer = $Deny

var item_pos_offset = 50

var player_is_close = false
var chest_opened = false
var coin_amount

var lines = [
	"Holy moly!",
	"Wow!",
	"Nice bro",
	"Yippie!"
]

func _ready() -> void:
	coin_amount = randi_range(2, 5)
	label.modulate.a = 0
	animated_sprite_2d.play("Closed")

func _process(delta: float) -> void:
	if label.modulate.a > 0:
		label.modulate.a -= delta
		label.position.y -= delta * 20
	
	if GameState.boss_spawned:
		queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_is_close and !chest_opened:
		label.modulate.a = 1
		
		if GameState.keys > 0:
			label.position.y = -88
			label.text = lines.pick_random()
			label.modulate = Color.YELLOW
			open_chest()
		else:
			label.position.y = -64
			label.text = "No Keys!"
			label.modulate = Color.RED
			deny.play()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false


func open_chest():
	pop_3.play()
	animated_sprite_2d.play("Open")
	chest_opened = true
	gpu_particles_2d.emitting = true
	GameState.keys -= 1
	for i in range(coin_amount):
		drop_coin(global_position)
	spawn_item()


func spawn_item():
	load_items()

	if all_items.is_empty():
		return

	var item_data = get_weighted_random_item()

	# Create item
	var item = item_scene.instantiate()
	item.global_position = global_position + Vector2(0, -16)
	item.data = item_data
	item_data.price = 0

	var dir = [-1, 1].pick_random()
	item.flying = true
	item.velocity = Vector2(randf_range(80, 140) * dir, -300) # up + sideways
	item.floor_y = global_position.y + 10 # ground level

	get_tree().current_scene.add_child(item)


func load_items():
	all_items.clear()

	var dir = DirAccess.open("res://Resources/Items")
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var item: ItemData = load("res://Resources/Items/" + file_name)
			if item:
				all_items.append(item)
		file_name = dir.get_next()

	dir.list_dir_end()

func get_weighted_random_item():
	var total_weight = 0
	var adjusted_weights = []

	var luck = GameState.luck  # or wherever you store it

	# Build adjusted weights per item
	for item in all_items:
		var base_weight = rarity_weights.get(item.rarity, 1)
		var weight = base_weight

		# Apply luck scaling here
		match item.rarity:
			ItemData.Rarity.COMMON:
				weight *= max(0.1, 1.0 - luck * 0.05) # reduce commons
			ItemData.Rarity.RARE:
				weight *= 1.0 + luck * 0.06
			ItemData.Rarity.EPIC:
				weight *= 1.0 + luck * 0.10
			ItemData.Rarity.LEGENDARY:
				weight *= 1.0 + luck * 0.15

		adjusted_weights.append(weight)
		total_weight += weight

	# Roll
	var rand_value = randf() * total_weight
	var current_sum = 0

	for i in range(all_items.size()):
		current_sum += adjusted_weights[i]
		if rand_value < current_sum:
			return all_items[i]

	return all_items[0]

func drop_coin(pos):
	var coin = coin_scene.instantiate()
	
	coin.global_position = pos
	var dir = [-1, 1].pick_random()
	coin.flying = true
	coin.velocity = Vector2(randf_range(100, 160) * dir, randf_range(-250, -500)) # up + sideways
	coin.floor_y = global_position.y + randi_range(1, 25) # ground level
	
	get_tree().current_scene.add_child(coin)

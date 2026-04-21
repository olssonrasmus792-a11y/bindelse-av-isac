extends Node2D

@export var all_items: Array[ItemData] = []
@onready var item_scene = preload("res://Scenes/item.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var collision: CollisionShape2D = $CollisionClosed
@onready var label: Label = $NoKeys
@onready var pop_3: AudioStreamPlayer = $Pop3

var player_is_close = false
var chest_opened = false
var coin_amount

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
			label.text = "+" + str(coin_amount) + " Coins"
			label.modulate = Color.YELLOW
			open_chest()
		else:
			label.position.y = -64
			label.text = "No Keys!"
			label.modulate = Color.RED


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false


func open_chest():
	animated_sprite_2d.play("Open")
	chest_opened = true
	gpu_particles_2d.emitting = true
	GameState.keys -= 1
	GameState.coins += coin_amount
	spawn_item()


func spawn_item():
	load_items()

	if all_items.is_empty():
		return

	# Pick random item
	var index = randi() % all_items.size()
	var item_data = all_items[index].duplicate()

	# Create item
	var item = item_scene.instantiate()
	item.global_position = global_position + Vector2(0, -16)
	item.data = item_data
	item_data.price = 0

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





func upgrade_cards(): #Använd för xp system sen
	var upgrade_scene = get_tree().get_first_node_in_group("upgrade_screen")
	get_tree().paused = true
	upgrade_scene.spawn_random_cards(3)
	pop_3.play()

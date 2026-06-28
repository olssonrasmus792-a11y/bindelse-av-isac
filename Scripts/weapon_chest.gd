extends Node2D

@onready var guy := get_tree().get_nodes_in_group("guy")

var rarity_weights = {
	ItemData.Rarity.COMMON: 50,
	ItemData.Rarity.RARE: 20,
	ItemData.Rarity.EPIC: 10,
	ItemData.Rarity.LEGENDARY: 3
}

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

var can_open = true
var free_chest = false
var item_amount = 0
var item_fly_length_mult = 1.0

var lines = [
	"Holy moly!",
	"Wow!",
	"Nice bro",
	"Yippie!"
]


func _ready() -> void:
	coin_amount = randi_range(5, 8)
	
	label.modulate.a = 0
	animated_sprite_2d.play("Closed")
	pop_up.visible = false


func _process(delta: float) -> void:
	if label.modulate.a > 0:
		label.modulate.a -= delta * 0.5
		label.position.y -= delta * 20

	if GameState.boss_spawned:
		queue_free()

	label_2.modulate = Color.LIME_GREEN if (GameState.keys >= 3 or free_chest) else Color.RED
	
	if !can_open:
		label_2.modulate = Color.RED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_is_close and !chest_opened and can_open:
		if GameState.keys > 2 or free_chest:
			label.modulate.a = 1
			label.position.y = -88
			label.text = lines.pick_random()
			label.modulate = Color.YELLOW
			open_chest()
		else:
			shake_label()
			deny.play()
			for guys in guy:
				guys.not_enough_keys()


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
	
	if !free_chest:
		GameState.keys -= 3
	
	get_tree().paused = true
	var ui = get_tree().get_first_node_in_group("level_up_ui")
	ui.show_weapon_cards()
	
	for i in range(coin_amount):
		drop_coin(global_position)
	
	var player = get_tree().get_first_node_in_group("player")
	
	player.chest_bonus_damage += 0.04 * GameState.get_item_count("Credit Card")
	for item in GameState.taken_items:
		if item.name == "Credit Card":
			item.tracked_stat_values[0] = int(player.chest_bonus_damage * 100)

func drop_coin(pos):
	var coin = coin_scene.instantiate()

	coin.global_position = pos
	var dir = [-1, 1].pick_random()
	coin.flying = true
	coin.velocity = Vector2(randf_range(100, 160) * dir, randf_range(-250, -500))
	coin.floor_y = global_position.y + randi_range(50, 75)

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

extends RigidBody2D

@export var explosion_scene = preload("res://Scenes/barrel_explosion.tscn")
@export var coin_scene = preload("res://Scenes/Coin.tscn")
@export var key_scene := preload("res://Scenes/Key.tscn")
@export var heart_scene := preload("res://Scenes/Heart_pickup.tscn")
@onready var sprite: Sprite2D = $Sprite2D

@export var knockback_strength_player = 200
@export var knockback_strength = 1500
@export var knockback_duration = 0.6

var knocked_back = false

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

var sprite_spin := 0.0

var item_pos_offset = 50

var coin_spawn_chance = 0.20
var key_spawn_chance = 0.01
var hp_spawn_chance = 0.05

var health = 2

func _physics_process(delta):
	if sprite_spin != 0:
		sprite.rotation += sprite_spin * delta
		sprite_spin = lerp(sprite_spin, 0.0, 1 * delta) # slowly stop spinning

func hit():
	health -= 1
	
	if health <= 0:
		drop_loot()
		
		var explosion = explosion_scene.instantiate()
		
		explosion.global_position = position
		get_parent().call_deferred("add_child", explosion)  # defer adding
		explosion.emitting = true
		
		queue_free()

func drop_loot():
	if randf() < coin_spawn_chance:
		var item = coin_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	if randf() < key_spawn_chance:
		var item = key_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
		get_parent().call_deferred("add_child", item)  # defer adding
	
	if randf() < hp_spawn_chance:
		var item = heart_scene.instantiate()
		item.global_position = position + Vector2(randi_range(-item_pos_offset, item_pos_offset), randi_range(-item_pos_offset, item_pos_offset))
		get_parent().call_deferred("add_child", item)  # defer adding

func apply_knockback(from_position: Vector2):
	var dir = (global_position - from_position).normalized()
	knocked_back = true

	# push the barrel
	apply_central_impulse(dir * knockback_strength)

	# add random spin
	sprite_spin = randf_range(-20.0, 20.0)

func _on_body_entered(body: Node) -> void:
	if knocked_back:
		hit()
	
	if body.is_in_group("barrel"):
		body.health = 0
		body.hit()

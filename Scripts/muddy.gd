extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/MuddyExplosion.tscn")

@export var speed := 275
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var point_light_2d: PointLight2D = $PointLight2D

var direction := Vector2(1, 1).normalized()
var health = 12

@export var knockback_strength_player = 325
@export var knockback_strength = 2250
@export var knockback_duration = 1.0

var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

signal enemy_died

func _ready() -> void:
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	point_light_2d.visible = false

func _physics_process(delta):
	if knockback_timer > 0.0:
		velocity = knockback_velocity
		knockback_timer -= delta
		point_light_2d.visible = true
		if knockback_timer <= 0:
			var tween := create_tween()
			tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1), 0.5)
	else:
		velocity = direction * speed
		point_light_2d.visible = false
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		var collider = collision.get_collider()
		if knockback_timer > 0.0:
			for cam in get_tree().get_nodes_in_group("camera"):
				cam.shake(1.0)
		
		if knockback_timer > 0.0 and !collider.is_in_group("enemies"):
			knockback_velocity = knockback_velocity.bounce(normal)
			direction = knockback_velocity.normalized()
		else:
			direction = direction.bounce(normal)

		if collider.is_in_group("enemies") and knockback_timer > 0.0:
			explode(collider)
			var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
			var ft = floating_text_scene.instantiate()
			ft.text = "Execute!"
			ft.modulate = Color.RED
			ft.global_position = collider.global_position
			get_tree().current_scene.add_child(ft)  # Or a dedicated UI node
		
		if collider.is_in_group("player") and knockback_timer > 0.0:
			collider.take_damage(1, global_position, knockback_strength_player)
	
	sprite_2d.flip_h = direction[0] < 0
	if direction[0] < 0:
		sprite_2d.rotation_degrees -= 10
	else:
		sprite_2d.rotation_degrees += 10

func take_damage(damage):
	health -= damage
	if health <= 0:
		explode(self)  

func apply_knockback(from_position: Vector2):
	var knockback_direction = (global_position - from_position).normalized()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	direction = knockback_velocity.normalized()
	sprite_2d.modulate = Color(1, 0, 0)

func explode(enemy):
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	emit_signal("enemy_died")
	enemy.queue_free()

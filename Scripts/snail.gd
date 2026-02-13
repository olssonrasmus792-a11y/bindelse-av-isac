extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/MuddyExplosion.tscn")
@export var trail_scene = preload("res://Scenes/snail_trail.tscn")

@export var speed := 150
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var direction := Vector2(1, 1).normalized()
var health = 2

@export var knockback_strength = 2000
@export var knockback_duration = 0.7

@export var drop_distance = 20.0
var last_drop_pos: Vector2

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

signal enemy_died

func _ready() -> void:
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	last_drop_pos = global_position

func _physics_process(delta):
	if knockback_timer > 0.0:
		# Smoothly interpolate knockback velocity to zero
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta
		
		if knockback_timer <= 0:
			var tween := create_tween()
			tween.tween_property(animated_sprite_2d, "modulate", Color(1, 1, 1), 0.5)
	else:
		velocity = direction * speed
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		var collider = collision.get_collider()
		
		if knockback_timer > 0.0 and !collider.is_in_group("enemies"):
			knockback_velocity = knockback_velocity.bounce(normal)
			direction = knockback_velocity.normalized()
		else:
			direction = direction.bounce(normal)
	
	if global_position.distance_to(last_drop_pos) >= drop_distance:
		spawn_trail()
		last_drop_pos = global_position
	
	
	animated_sprite_2d.flip_h = direction[0] > 0

func take_damage(damage):
	health -= damage
	flash_red()
	if health <= 0:
		emit_signal("enemy_died")  
		explode(self)  
		queue_free()

func apply_knockback(from_position: Vector2):
	var knockback_direction = (global_position - from_position).normalized()
	current_knockback = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	direction = knockback_direction

func spawn_trail():
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	get_parent().add_child(trail)

func flash_red():
	animated_sprite_2d.modulate = Color(1, 0, 0)  # red
	var tween := create_tween()
	tween.tween_property(
		animated_sprite_2d,
		"modulate",
		Color(1, 1, 1),
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func explode(enemy):
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	emit_signal("enemy_died")
	enemy.queue_free()

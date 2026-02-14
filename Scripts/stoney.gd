extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/MuddyExplosion.tscn")

@export var speed := 150
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var color_rect: ColorRect = $ColorRect
@onready var color_rect_2: ColorRect = $ColorRect2

@onready var player := get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var direction := Vector2(1, 1).normalized()
var health = 20

@export var knockback_strength_player = 200
@export var knockback_strength = 2000
@export var knockback_duration = 0.7

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

signal enemy_died

func _ready() -> void:
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _physics_process(delta):
	if knockback_timer > 0.0:
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta

	elif animated_sprite_2d.frame >= 5 and animated_sprite_2d.frame <= 12 and health > 0:
		if player:
			nav_agent.target_position = player.global_position
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				direction = (next_pos - global_position).normalized()
				velocity = direction * speed
		animated_sprite_2d.flip_h = direction.x > 0
		color_rect.visible = direction.x < 0
		color_rect_2.visible = direction.x > 0

	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			collider.take_damage(1, global_position, knockback_strength_player)
		
		if knockback_timer > 0.0 and !collider.is_in_group("enemies"):
			knockback_velocity = knockback_velocity.bounce(normal)
			current_knockback = current_knockback.bounce(normal)
			direction = current_knockback.normalized()
		else:
			direction = direction.bounce(normal)

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

func flash_red():
	animated_sprite_2d.modulate = Color.WHITE
	animated_sprite_2d.modulate = Color(1, 0, 0)
	var tween := create_tween()
	tween.tween_property(
		animated_sprite_2d,
		"modulate",
		Color(1, 1, 1),
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func explode(enemy):
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	emit_signal("enemy_died")
	enemy.queue_free()

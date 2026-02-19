extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/MuddyExplosion.tscn")
@export var trail_scene = preload("res://Scenes/snail_trail.tscn")

@export var speed := 300
@export var chase_speed_mult := 1.5
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var direction_timer: Timer = $DirectionTimer

@onready var player := get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var direction := Vector2(1, 1).normalized()
var health = 16

@export var knockback_strength_player = 200
@export var knockback_strength = 1500
@export var knockback_duration = 0.6

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
	direction = direction.normalized()
	if knockback_timer > 0.0:
		# Smoothly interpolate knockback velocity to zero
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta
	elif player and player.slow_timer > 0:
			nav_agent.target_position = player.global_position
			if not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				direction = (next_pos - global_position).normalized()
				velocity = direction * speed * chase_speed_mult
				animated_sprite_2d.speed_scale = 2.0
	else:
		velocity = direction * speed
		animated_sprite_2d.speed_scale = 1.0
	
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
	
	if global_position.distance_to(last_drop_pos) >= drop_distance:
		spawn_trail()
		last_drop_pos = global_position
	
	visuals.scale.x = -1 if direction.x > 0 else 1

func take_damage(damage):
	health -= damage
	flash_red()
	if health <= 0:
		explode(self)  

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


func _on_direction_timer_timeout() -> void:
	var new_timer = randf_range(2, 5)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	direction_timer.wait_time = new_timer

extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")
@export var trail_scene = preload("res://Scenes/Enemies/snail_trail.tscn")
@export var projectile_scene = preload("res://Scenes/Enemies/water_projectile.tscn")

@export var speed := 150
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_particles: GPUParticles2D = $HitParticles

@onready var player := get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var direction := Vector2(1, 1).normalized()
var health = 8
var projectile_speed = 400

@export var knockback_strength_player = 200
@export var knockback_strength_mult = 1
@export var knockback_duration = 0.6

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

signal enemy_died

func _ready() -> void:
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	hit_particles.emitting = false

func _physics_process(delta):
	direction = direction.normalized()
	if knockback_timer > 0.0:
		# Smoothly interpolate knockback velocity to zero
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta
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
	
	visuals.scale.x = -1 if direction.x > 0 else 1

func take_damage(damage):
	health -= damage
	flash_red()
	animation_player.play("hit")
	if health <= 0:
		explode(self)  

func apply_knockback(aim_direction: Vector2, knockback_strength: int):
	var knockback_direction = aim_direction.normalized()
	hit_particles.rotation = knockback_direction.angle()
	current_knockback = knockback_direction * knockback_strength * knockback_strength_mult
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

func _on_shoot_timer_timeout() -> void:
	var new_timer = randf_range(2, 4)
	spawn_projectile(projectile_speed)
	shoot_timer.wait_time = new_timer

func spawn_projectile(p_speed: int) -> void:
	animated_sprite_2d.play("Attack")
	
	await animated_sprite_2d.animation_finished
	
	animated_sprite_2d.play("Idle")
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = Vector2(global_position.x, global_position.y - 5)
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = p_speed
	get_tree().current_scene.add_child(projectile)

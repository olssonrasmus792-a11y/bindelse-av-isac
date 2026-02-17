extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/MuddyExplosion.tscn")
@export var jump_effect_scene = preload("res://Scenes/jump_effects.tscn")

@export var speed := 250
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var color_rect: ColorRect = $Visuals/ColorRect
@onready var direction_timer: Timer = $DirectionTimer
@onready var visuals: Node2D = $Visuals

@onready var player := get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export var aggro_range: float = 800.0
@export var lose_range: float = 1000.0
var chasing := false

var emitting_particles = false

var direction := Vector2(1, 1).normalized()
var health = 20

@export var knockback_strength_player = 200
@export var knockback_strength = 1250
@export var knockback_duration = 0.5

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

	elif animated_sprite_2d.frame >= 5 and animated_sprite_2d.frame <= 10 and health > 0:
		if player:
			var distance = global_position.distance_to(player.global_position)

			# Start chasing
			if not chasing and distance <= aggro_range:
				chasing = true

			# Stop chasing
			elif chasing and distance >= lose_range:
				chasing = false

			if chasing:
				nav_agent.target_position = player.global_position

				if not nav_agent.is_navigation_finished():
					var next_pos = nav_agent.get_next_path_position()
					direction = (next_pos - global_position).normalized()
					velocity = direction * speed
			else:
				velocity = direction * speed

		visuals.scale.x = -1 if direction.x > 0 else 1

	else:
		velocity = Vector2.ZERO
	
	if animated_sprite_2d.frame == 10 and chasing:
		play_jump_effects()
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(0.25)
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		var collider = collision.get_collider()
		
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
		explode(self)  

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
	
	health = 0
	emit_signal("enemy_died")
	enemy.queue_free()

func play_jump_effects():
	if emitting_particles:
		return
	
	var effects = jump_effect_scene.instantiate()
	get_tree().current_scene.add_child(effects)
	effects.global_position = global_position

	emitting_particles = true

	var frames = [
		effects.get_node("JumpEffect"),
		effects.get_node("JumpEffect2"),
		effects.get_node("JumpEffect3")
	]

	for i in range(frames.size()):
		if health <= 0:  # stop if enemy is dead
			break
		frames[i].restart()
		await get_tree().create_timer(0.2).timeout
		if i > 0:
			frames[i-1].visible = false

	if is_instance_valid(effects):
		effects.queue_free()

	emitting_particles = false


func _on_direction_timer_timeout() -> void:
	var new_timer = randf_range(2, 5)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	direction_timer.wait_time = new_timer

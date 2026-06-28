extends CharacterBody2D

@export var boom_scene = preload("res://Scenes/barrel_explosion.tscn")
@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")
@export var trail_scene = preload("res://Scenes/Enemies/snail_trail.tscn")
@export var xp_orb_scene = preload("res://Scenes/xp_orb.tscn")

@export var xp_orbs: int = 5
@export var xp_reward: float = 4.0
var xp_reward_range = 2 # xp rewards +- range

@export var speed := 300
@export var chase_speed_mult := 1.5
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var direction_timer: Timer = $DirectionTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var hp_bar: TextureProgressBar = $HpBar

@onready var player := get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var direction := Vector2(1, 1).normalized()
var max_health = 60.0
var health = max_health

@export var knockback_strength_player = 200
@export var knockback_strength_mult = 1.0
@export var knockback_duration = 0.6

@export var drop_distance = 20.0
var last_drop_pos: Vector2

var stun_timer := 0.0

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

var wall_hit_cooldown := 0.0
const WALL_HIT_INTERVAL := 0.15

var is_dead
signal enemy_died

func _ready() -> void:
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	last_drop_pos = global_position
	hit_particles.emitting = false

func _physics_process(delta):
	hp_bar.visible = health < max_health
	hp_bar.value = lerp(hp_bar.value, float(health), 0.25)
	direction = direction.normalized()
	
	if wall_hit_cooldown > 0.0:
		wall_hit_cooldown -= delta
	
	if stun_timer > 0.0:
		stun_timer -= delta
		animated_sprite_2d.speed_scale = 0.0
		visuals.modulate = Color.YELLOW
	
	if knockback_timer > 0.0:
		# Knockback always works
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta
	
	elif stun_timer > 0.0:
		velocity = Vector2.ZERO
	
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
		visuals.modulate = Color.WHITE
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			collider.take_damage(1, global_position, knockback_strength_player, self)
		
		if knockback_timer > 0.0 and !collider.is_in_group("enemies"):
			current_knockback = current_knockback.bounce(normal)
			direction = current_knockback.normalized()

			if GameState.get_upgrade_count("Squashed!") > 0 and wall_hit_cooldown <= 0.0:
				var impact_speed = current_knockback.length()
				var damage = remap(impact_speed, 0.0, 5000.0, 1.0, max_health * 3.0)
				damage = clampf(damage, 1.0, max_health * 3.0)
				take_damage(damage)
				spawn_floating_text("-" + str(damage), Color.WHITE, global_position)
				wall_hit_cooldown = WALL_HIT_INTERVAL
		else:
			direction = direction.bounce(normal)
	
	if global_position.distance_to(last_drop_pos) >= drop_distance:
		spawn_trail()
		last_drop_pos = global_position
	
	visuals.scale.x = -1 if direction.x > 0 else 1

func take_damage(damage):
	health -= damage
	flash_red()
	animation_player.stop()
	animation_player.play("hit")
	if health <= 0:
		explode(self)

func apply_knockback(aim_direction: Vector2, knockback_strength: int):
	var knockback_direction = aim_direction.normalized()
	hit_particles.rotation = knockback_direction.angle()
	current_knockback = knockback_direction * knockback_strength * knockback_strength_mult
	knockback_timer = knockback_duration
	direction = knockback_direction

func stun(duration: float):
	stun_timer = maxf(stun_timer, duration)

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
	if is_dead:
		return
	
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	for x in range(xp_orbs):
		var orb = xp_orb_scene.instantiate()
		orb.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		orb.xp_value = xp_reward + randi_range(-xp_reward_range, xp_reward_range)
		
		get_tree().current_scene.call_deferred("add_child", orb)
	
	if GameState.get_upgrade_count("Death Boom") > 0:
		var boom = boom_scene.instantiate()
		boom.scale = Vector2(player.explosion_size, player.explosion_size)
		boom.global_position = position
		boom.explosion_damage = player.explosion_damage
		boom.explosion_particles = player.explosion_particles
		get_tree().current_scene.call_deferred("add_child", boom)  # defer adding
		boom.emitting = true
	
	emit_signal("enemy_died")
	enemy.queue_free()

func spawn_floating_text(text: String, color: Color, pos: Vector2):
	var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
	var ft = floating_text_scene.instantiate()
	
	ft.text = text
	ft.modulate = color
	ft.global_position = pos
	
	get_tree().current_scene.call_deferred("add_child", ft)

func _on_direction_timer_timeout() -> void:
	var new_timer = randf_range(2, 5)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	direction_timer.wait_time = new_timer

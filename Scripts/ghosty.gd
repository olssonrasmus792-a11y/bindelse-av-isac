extends CharacterBody2D

@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")
@export var xp_orb_scene = preload("res://Scenes/xp_orb.tscn")

@export var xp_orbs: int = 3
@export var xp_reward: int = 2
var xp_reward_range = 1 # xp rewards +- range

@export var speed := 350
@export var chase_speed_mult := 1.5
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var hp_bar: TextureProgressBar = $HpBar

@onready var player := get_tree().get_first_node_in_group("player")

var direction := Vector2(1, 1).normalized()
@export var max_health = 60.0
var health = max_health

var base_y
var time := 0.0
@export var float_speed := 4.0
@export var float_amount := 8.0

@export var knockback_strength_player = 200
@export var knockback_strength_mult = 1.0
@export var knockback_duration = 0.6

var current_knockback := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

signal enemy_died

func _ready() -> void:
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	hit_particles.emitting = false
	base_y = animated_sprite_2d.position.y

func _physics_process(delta):
	hp_bar.value = lerp(hp_bar.value, float(health), 0.25)
	if knockback_timer > 0.0:
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta
	else:
		direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		animated_sprite_2d.speed_scale = 1.0
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			collider.take_damage(1, global_position, knockback_strength_player)
			apply_knockback(direction * -1, knockback_strength_player)
	
	visuals.scale.x = 1 if direction.x > 0 else -1
	
	time += delta
	animated_sprite_2d.position.y = base_y + sin(time * float_speed) * float_amount

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
	
	for x in range(xp_orbs):
		var orb = xp_orb_scene.instantiate()
		orb.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		orb.xp_value = xp_reward + randi_range(-xp_reward_range, xp_reward_range)
		
		get_tree().current_scene.call_deferred("add_child", orb)
	
	emit_signal("enemy_died")
	enemy.queue_free()

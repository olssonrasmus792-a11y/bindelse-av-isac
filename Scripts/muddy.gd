extends CharacterBody2D

@onready var player := get_tree().get_first_node_in_group("player")

@export var boom_scene = preload("res://Scenes/barrel_explosion.tscn")
@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")
@export var xp_orb_scene = preload("res://Scenes/xp_orb.tscn")

@export var xp_orbs: int = 5
@export var xp_reward: float = 4.0
var xp_reward_range = 2 # xp rewards +- range

var spawned_by_player = false
var queue_death = false

@export var speed := 275
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var hp_bar: TextureProgressBar = $HpBar

@onready var bounce_1: AudioStreamPlayer = $Bounce1
@onready var bounce_2: AudioStreamPlayer = $Bounce2
@onready var splat: AudioStreamPlayer = $Splat
var splat_pitch = 1.0

var direction = null
var max_health = 60.0
var health = max_health

@export var scale_factor = 1.0

@export var knockback_strength_player = 325
@export var knockback_fly_speed = 2000
@export var knockback_duration = 1.0

var stun_timer := 0.0
var stunned := false

var knockback_velocity := Vector2.ZERO
var knockback_timer := 0.0

var is_dead
signal enemy_died

func _ready() -> void:
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	if direction == null:
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	point_light_2d.visible = false
	hit_particles.emitting = false

func _physics_process(delta):
	hp_bar.visible = health < max_health
	hp_bar.value = lerp(hp_bar.value, float(health), 0.25)
	scale = Vector2(scale_factor, scale_factor)
	
	if knockback_timer > 0.0:
		velocity = knockback_velocity
		knockback_timer -= delta
		point_light_2d.visible = true
		if knockback_timer <= 0:
			splat_pitch = 1.0
			var tween := create_tween()
			tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1), 0.5)
			if spawned_by_player or queue_death:
				explode(self)
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
		
		if collider.is_in_group("barrel") and knockback_timer > 0.0:
			collider.health = 0
			collider.hit()
		
		if knockback_timer > 0.0 and !collider.is_in_group("enemies"):
			play_bounce_sound()
			knockback_velocity = knockback_velocity.bounce(normal)
			direction = knockback_velocity.normalized()
		else:
			direction = direction.bounce(normal)

		if collider.is_in_group("enemies") and knockback_timer > 0.0:
			var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
			var ft = floating_text_scene.instantiate()
			ft.text = "Execute!"
			ft.modulate = Color.RED
			ft.global_position = collider.global_position
			
			if collider.is_in_group("boss"):
				play_bounce_sound()
				knockback_velocity = knockback_velocity.bounce(normal)
				direction = knockback_velocity.normalized()
				collider.take_damage(player.damage)
				if collider.health <= player.damage:
					GameState.muddy_kills += 1
				ft.text = "-" + str(int(player.damage))
				ft.modulate = Color.WHITE
			else:
				splat_pitch += 0.5
				splat.pitch_scale = splat_pitch
				splat.play()
				collider.explode(collider)
				GameState.muddy_kills += 1
			
			get_tree().current_scene.add_child(ft)  # Or a dedicated UI node
		
		if collider.is_in_group("player") and knockback_timer > 0.0:
			if GameState.get_upgrade_count("Friend") > 0 or knockback_timer > 2.5:
				play_bounce_sound()
				knockback_velocity = knockback_velocity.bounce(normal)
				direction = knockback_velocity.normalized()
			else:
				collider.take_damage(1, global_position, knockback_strength_player, self)
	
	sprite_2d.flip_h = direction[0] < 0
	if direction[0] < 0:
		sprite_2d.rotation_degrees -= 10
	else:
		sprite_2d.rotation_degrees += 10

func take_damage(damage):
	health -= damage
	await get_tree().process_frame
	if health <= 0:
		if knockback_timer <= 0.0:
			explode(self)
		else:
			queue_death = true

func apply_knockback(aim_direction: Vector2, knockback_strength: int):
	if knockback_strength == 0:
		return
	var knockback_direction = aim_direction.normalized()
	hit_particles.rotation = knockback_direction.angle()
	knockback_velocity = knockback_direction * knockback_fly_speed
	knockback_timer = knockback_duration
	direction = knockback_direction
	sprite_2d.modulate = Color(1, 0, 0)

func stun(duration: float):
	if duration <= 0.0:
		return
	
	stun_timer = maxf(stun_timer, duration)
	stunned = true

func explode(enemy):
	if is_dead:
		return
	
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	if !spawned_by_player:
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

func play_bounce_sound():
	var roll = randf()
	
	if roll < 0.5:
		bounce_1.pitch_scale = randf_range(1.0, 1.4)
		bounce_1.play(0.2)
	else:
		bounce_2.pitch_scale = randf_range(1.0, 1.4)
		bounce_2.play(0.12)

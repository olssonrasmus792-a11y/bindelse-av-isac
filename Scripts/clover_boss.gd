extends CharacterBody2D

@onready var player := get_tree().get_first_node_in_group("player")
@onready var boss_hp_bar := get_tree().get_first_node_in_group("boss_hp_bar")

@export var xp_orbs: int = 25
@export var xp_reward: float = 15.0
var xp_reward_range = 5 # xp rewards +- range

@export var boom_scene = preload("res://Scenes/barrel_explosion.tscn")
@onready var projectile_scene = preload("res://Scenes/clover_projectile.tscn")
@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")
@export var jump_effect_scene = preload("res://Scenes/Enemies/jump_effects.tscn")
@export var xp_orb_scene = preload("res://Scenes/xp_orb.tscn")

@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var hp_bar: TextureProgressBar = $HpBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var pop_up: Control = $PopUp

@onready var splat: AudioStreamPlayer = $Splat

var base_y = 0

var jump_direction
var jump_length = 500
var move_towards_player

var player_in_spawn_range = false
var spawned = false
var spawning = false
var evolved = false

var player_is_close = false

var bullet_hell_active = false
var burst_hell_active = false
var jump_ability_active = false

var emitting_particles

var base_ability_chance = 0.00
var ability_chance = base_ability_chance
var ability_chance_increase = 0.02

var normal_speed = 450
var bullet_hell_speed = 400
var burst_hell_speed = 150

var max_health = 2500.0
var health = max_health
var evolve_health_trigger = 500
var evolve_heal_amount := 750
var evolve_heal_duration := 4.0

@export var knockback_strength_player = 200
@export var knockback_strength_mult = 0.75
@export var knockback_duration = 0.5

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
	hp_bar.value = health
	boss_hp_bar.max_value = max_health
	boss_hp_bar.value = health
	hp_bar.visible = false
	pop_up.visible = false
	shoot_timer.wait_time = 1.5
	shoot_timer.paused = true
	animated_sprite_2d.play("Sleep")
	hit_particles.emitting = false

func _process(delta: float) -> void:
	hp_bar.value = lerp(hp_bar.value, health, 0.25)
	
	boss_hp_bar.value = lerp(hp_bar.value, health, 0.25)
	boss_hp_bar.get_child(0).text = "BOSS HP: " + str(int(health)) + "/" + str(int(max_health))
	
	if wall_hit_cooldown > 0.0:
		wall_hit_cooldown -= delta
	
	if stun_timer > 0.0:
		stun_timer -= delta
		animated_sprite_2d.speed_scale = 0.0
		visuals.modulate = Color.YELLOW
	
	if knockback_timer > 0.0:
		current_knockback = current_knockback.lerp(Vector2.ZERO, 5 * delta)
		velocity = current_knockback
		knockback_timer -= delta
		move_and_slide()
	elif stun_timer > 0.0:
		velocity = Vector2.ZERO
	elif move_towards_player:
		jump_direction = (player.global_position - global_position).normalized()
		velocity = jump_direction * jump_length
		move_and_slide()
	else:
		animated_sprite_2d.speed_scale = 1.0
		visuals.modulate = Color.WHITE
	
	if bullet_hell_active or burst_hell_active or spawning:
		shoot_timer.paused = true
	elif spawned:
		shoot_timer.paused = false
	
	if animated_sprite_2d.animation == "Spin":
		animated_sprite_2d.position.y = base_y - 15
	else:
		animated_sprite_2d.position.y = base_y
	
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			collider.take_damage(1, global_position, knockback_strength_player, self)
		
		if knockback_timer > 0.0 and !collider.is_in_group("enemies"):
			if GameState.get_upgrade_count("Squashed!") > 0 and wall_hit_cooldown <= 0.0:
				var impact_speed = current_knockback.length()
				var damage = remap(impact_speed, 0.0, 5000.0, 1.0, max_health * 3.0)
				damage = clampf(damage, 1.0, max_health * 3.0)
				take_damage(damage)
				spawn_floating_text("-" + str(damage), Color.WHITE, global_position)
				wall_hit_cooldown = WALL_HIT_INTERVAL
	
	if Input.is_action_just_pressed("interact") and player_in_spawn_range and pop_up.visible and !spawned:
		get_parent().check_doors()
		get_parent().close_room()
		MusicManager.reset_music_groups()
		MusicManager.play_music(MusicManager.SONGS["BOSS_MUSIC"], MusicManager.MusicGroup.BOSS)
		var active_ghosts = get_tree().get_nodes_in_group("ghosty")
		for ghost in active_ghosts:
			ghost.queue_free()
		GameState.time_left = 0
		pop_up.visible = false
		spawning = true
		var cutscene = get_tree().get_first_node_in_group("cutscene")
		cutscene.play("cutscene")
		await cutscene.animation_finished
		spawned = true
		spawning = false
		GameState.boss_spawned = true
		hp_bar.visible = true
		shoot_timer.paused = false
		animated_sprite_2d.play("Spawn")
	
	if animated_sprite_2d.animation == "Spawn":
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(0.25)
	
	if evolved:
		scale = Vector2(3.5, 3.5)
	else:
		scale = Vector2(1.0, 1.0)

func spawn_projectile(direction: Vector2, speed: int) -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = Vector2(global_position.x, global_position.y - 30)
	projectile.direction = direction
	projectile.speed = speed
	get_tree().current_scene.add_child(projectile)

func bullet_hell():
	bullet_hell_active = true
	animated_sprite_2d.play("Spin")
	
	var shots = 30
	
	if evolved:
		shots = 4
	
	for i in range(shots):
		if spawning:
			break
		
		var angle = i * 0.65
		var direction = Vector2.RIGHT.rotated(angle)

		for j in range(4):
			var dir = direction.rotated(j * PI/2)
			spawn_projectile(dir, bullet_hell_speed)

		await get_tree().create_timer(0.1).timeout
	
	animated_sprite_2d.play("Idle")
	bullet_hell_active = false

func burst_hell():
	burst_hell_active = true
	animated_sprite_2d.play("Spin")
	
	var total_bursts = 5
	
	for x in range(total_bursts):
		if spawning:
			break
		
		shoot_burst()
		fade_red()
		await get_tree().create_timer(0.45).timeout
		jump_ability(1)
		await get_tree().create_timer(1.8 - 0.45).timeout
		if x != total_bursts - 1:
			fade_red()
		await get_tree().create_timer(0.45).timeout
	
	animated_sprite_2d.play("Idle")
	burst_hell_active = false

func shoot_burst():
	var bullets := 80
	var gap_width := 0.4
	
	if evolved:
		bullets = 40
		gap_width = 2.4
	
	var player_angle = (player.global_position - global_position).angle()
	
	# pick a random gap direction that is NOT close to the player
	var gap_angle: float
	var min_player_distance := 0.6 # radians (~35° safety zone)

	while true:
		gap_angle = randf_range(0.0, TAU)
		if abs(angle_difference(gap_angle, player_angle)) > min_player_distance:
			break

	for i in range(bullets):
		var angle = i * TAU / bullets
		
		# skip bullets inside the gap
		if abs(angle_difference(angle, gap_angle)) < gap_width:
			continue
		
		var direction = Vector2.RIGHT.rotated(angle)
		spawn_projectile(direction, burst_hell_speed)

func jump_ability(size: float):
	jump_ability_active = true
	
	var base_scale = 0.2
	var jump_height = 150
	
	var air_time = 0.25
	var land_time = 0.1
	var reset_time = 0.1

	if evolved:
		air_time /= 1.4
		land_time /= 1.4
		reset_time /= 1.4

	# --- Phase 1: Jump up immediately (thinner horizontally while moving up) ---
	var jump_tween = create_tween()
	jump_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale * 0.5, base_scale * 1.4),
		air_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	jump_tween.tween_property(
		animated_sprite_2d,
		"position:y",
		animated_sprite_2d.position.y - jump_height,
		air_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if evolved:
		move_towards_player = true
	await jump_tween.finished

	# --- Phase 2: Land (squish on impact) ---
	var land_tween = create_tween()
	land_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale * 1.5, base_scale * 0.5),
		land_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	land_tween.tween_property(
		animated_sprite_2d,
		"position:y",
		0, # back to original local position
		land_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await land_tween.finished

	# --- Phase 3: Return to normal ---
	play_jump_effects(size)
	splat.play(0.04)
	if evolved:
		move_towards_player = false
		shoot_burst()
	for cam in get_tree().get_nodes_in_group("camera"):
		if evolved:
			cam.shake(2.0)
		else:
			cam.shake(1.0)

	var reset_tween = create_tween()
	reset_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale, base_scale),
		reset_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await reset_tween.finished

	jump_ability_active = false

func play_jump_effects(size: float):
	if emitting_particles:
		return
	
	var effects = jump_effect_scene.instantiate()
	get_tree().current_scene.add_child(effects)
	effects.global_position = global_position
	effects.scale = Vector2(size, size)

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
		await get_tree().create_timer(0.15).timeout
		if i > 0:
			frames[i-1].visible = false

	if is_instance_valid(effects):
		effects.queue_free()

	emitting_particles = false

func _on_shoot_timer_timeout() -> void:
	if bullet_hell_active or burst_hell_active or jump_ability_active:
		if evolved:
			shoot_timer.wait_time = 0.5
		else:
			shoot_timer.wait_time = 2
		return
	
	animated_sprite_2d.play("Shoot")
	fade_red()
	
	await get_tree().create_timer(0.45).timeout
	
	var base_direction = (player.global_position - global_position).normalized()
	var spread := 0.5
	var bullets := 5
	
	var roll = randf()
	
	if evolved:
		jump_ability(1.7)
		shoot_timer.wait_time = 0.5
		ability_chance += ability_chance_increase
		return
	
	if roll < ability_chance:
		burst_hell()
		shoot_timer.wait_time = 1.5
		ability_chance /= 2
		return
	
	if roll < ability_chance * 2:
		bullet_hell()
		shoot_timer.wait_time = 1.5
		ability_chance = base_ability_chance
		return
	
	if roll < (ability_chance * 4 + ability_chance_increase) and player_is_close:
		jump_ability(1.75)
		shoot_timer.wait_time = 1.5
		ability_chance /= 2
		return
	
	ability_chance += ability_chance_increase
	
	for i in range(bullets):
		var offset = lerp(-spread, spread, float(i) / (bullets - 1))
		var dir = base_direction.rotated(offset)
		spawn_projectile(dir, normal_speed)
	
	await animated_sprite_2d.animation_finished
	
	animated_sprite_2d.play("Idle")
	
	shoot_timer.wait_time = 1.5

func evolve():
	spawning = true
	
	animation_player.stop()
	animation_player.play("evolve")
	
	var heal_per_tick = evolve_heal_amount / 40.0
	
	for i in range(40):
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(1.0)
		health += heal_per_tick
		health = clamp(health, 0, max_health)
		await get_tree().create_timer(evolve_heal_duration / 40.0).timeout
	
	await animation_player.animation_finished
	
	spawning = false
	evolved = true

func take_damage(damage):
	if !spawned or spawning:
		return
	
	health -= damage
	flash_red()
	animation_player.stop()
	animation_player.play("hit")
	
	if health <= evolve_health_trigger and !evolved and !spawning:
		evolve()
		MusicManager.set_music_pitch(1.2, 6.5)
	
	if health <= 0:
		explode(self)

func fade_red():
	var base_scale = 0.2
	animated_sprite_2d.modulate = Color(1, 1, 1, 1)
	animated_sprite_2d.scale = Vector2(base_scale, base_scale)

	# --- Phase 1: Charge ---
	# Tween for color
	var color_tween := create_tween()
	color_tween.tween_property(
		animated_sprite_2d,
		"modulate",
		Color(1, 0, 0, 1),
		0.40
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Tween for scale crouch
	var scale_tween := create_tween()
	scale_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale, base_scale * 0.7),
		0.40
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Wait until BOTH tweens are finished
	await color_tween.finished
	await scale_tween.finished

	# --- Phase 2: Pop/firing ---
	var pop_tween := create_tween()

	# Squish X and bounce up
	pop_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale * 1.2, base_scale * 0.9),
		0.1
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Return to normal scale
	pop_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale, base_scale),
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Reset color to white
	pop_tween.tween_property(
		animated_sprite_2d,
		"modulate",
		Color(1, 1, 1, 1),
		0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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

func apply_knockback(aim_direction: Vector2, knockback_strength: int):
	if GameState.get_upgrade_count("I'm the boss") > 0:
		var knockback_direction = aim_direction.normalized()
		hit_particles.rotation = knockback_direction.angle()
		current_knockback = knockback_direction * knockback_strength * knockback_strength_mult
		knockback_timer = knockback_duration

func stun(duration: float):
	stun_timer = maxf(stun_timer, duration)

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
	MusicManager.play_music(MusicManager.GHOST_SONGS.values().pick_random(), MusicManager.MusicGroup.GHOST, 6.0)
	GameState.boss_killed = true
	enemy.queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and !spawned and !spawning:
		player_in_spawn_range = true
		pop_up.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_spawn_range = false
		pop_up.visible = false

func spawn_floating_text(text: String, color: Color, pos: Vector2):
	var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
	var ft = floating_text_scene.instantiate()
	
	ft.text = text
	ft.modulate = color
	ft.global_position = pos
	
	get_tree().current_scene.call_deferred("add_child", ft)

extends CharacterBody2D

@onready var player := get_tree().get_first_node_in_group("player")

@onready var projectile_scene = preload("res://Scenes/clover_projectile.tscn")
@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")
@export var jump_effect_scene = preload("res://Scenes/Enemies/jump_effects.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var hp_bar: TextureProgressBar = $TextureProgressBar

var base_y = 0

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

var max_health = 200.0
var health = max_health
signal enemy_died


func _ready() -> void:
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	shoot_timer.wait_time = 1.5
	animated_sprite_2d.play("Spawn")
	await animated_sprite_2d.animation_finished
	await get_tree().create_timer(1).timeout

func _process(_delta: float) -> void:
	hp_bar.value = lerp(hp_bar.value, health, 0.25)
	
	if bullet_hell_active or burst_hell_active:
		shoot_timer.paused = true
	else:
		shoot_timer.paused = false
	
	if animated_sprite_2d.animation == "Spin":
		animated_sprite_2d.position.y = base_y - 15
	else:
		animated_sprite_2d.position.y = base_y

func spawn_projectile(direction: Vector2, speed: int) -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = Vector2(global_position.x, global_position.y - 30)
	projectile.direction = direction
	projectile.speed = speed
	get_tree().current_scene.add_child(projectile)

func bullet_hell():
	bullet_hell_active = true
	animated_sprite_2d.play("Spin")
	
	for i in range(30):
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
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await land_tween.finished

	# --- Phase 3: Return to normal ---
	play_jump_effects(size)
	for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(1.0)

	var reset_tween = create_tween()
	reset_tween.tween_property(
		animated_sprite_2d,
		"scale",
		Vector2(base_scale, base_scale),
		0.1
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
		shoot_timer.wait_time = 2
		return
	
	animated_sprite_2d.play("Shoot")
	fade_red()
	
	await get_tree().create_timer(0.45).timeout
	
	var roll = randf()
	
	if roll < ability_chance:
		bullet_hell()
		shoot_timer.wait_time = 1.5
		ability_chance = base_ability_chance
		return
	
	if roll < ability_chance * 2:
		burst_hell()
		shoot_timer.wait_time = 1.5
		ability_chance = base_ability_chance
		return
	
	if roll < (ability_chance * 4 + ability_chance_increase) and player_is_close:
		jump_ability(1.75)
		shoot_timer.wait_time = 1.5
		ability_chance /= 2
		return
	
	ability_chance += ability_chance_increase
	
	var base_direction = (player.global_position - global_position).normalized()
	var spread := 0.5
	var bullets := 5
	
	for i in range(bullets):
		var offset = lerp(-spread, spread, float(i) / (bullets - 1))
		var dir = base_direction.rotated(offset)
		spawn_projectile(dir, normal_speed)
	
	await animated_sprite_2d.animation_finished
	
	animated_sprite_2d.play("Idle")
	
	shoot_timer.wait_time = 1.5

func take_damage(damage):
	health -= damage
	flash_red()
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

func apply_knockback(_aim_direction: Vector2, _knockback_strength: int):
	pass

func explode(enemy):
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	emit_signal("enemy_died")
	GameState.boss_killed = true
	enemy.queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

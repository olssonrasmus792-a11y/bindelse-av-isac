extends CharacterBody2D

@onready var visuals: Node2D = $Visuals
@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var point_light_2d: PointLight2D = $Node2D/PointLight2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var roll_collision: CollisionShape2D = $RollCollision
@onready var roll_light: PointLight2D = $Node2D/RollLight
@onready var attack_timer: Timer = $AttackTimer
@onready var roll_timer: Timer = $RollTimer
@onready var stamina_recharge: Timer = $StaminaRecharge
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var health_bar: HBoxContainer = $"../UI/health_panel/health_bar"
@onready var stamina_bar: HBoxContainer = $"../UI/stamina_panel/stamina_bar"
@onready var health_panel: PanelContainer = $"../UI/health_panel"
@onready var stamina_panel: PanelContainer = $"../UI/stamina_panel"
@onready var attack_area: Area2D = $AttackArea
@onready var sword_sprite: AnimatedSprite2D = $AttackArea/SwordSprite
@onready var color_timer: Timer = $ColorTimer
@onready var ambient_light: CanvasModulate = $"../Ambient Light"
@onready var death_particles: GPUParticles2D = $Visuals/DeathParticles
@onready var damage_vignette: TextureRect = $"../UI/DamageVignette"

enum ColorState { YELLOW, RED, GREEN }

@onready var sword_base_position = sword_sprite.position
@onready var sword_base_rotation = sword_sprite.rotation
@onready var sword_base_scale = sword_sprite.scale

var spawn_pos
var damage = 4

@export var max_speed = 400
@export var speed = max_speed

@export var max_health = 6
@export var health = max_health

@export var max_stamina = 5
@export var stamina = max_stamina
@export var stamina_regen = 1.25 # Sekunder per stamina

@export var color_state: ColorState

@export var invulnerability_duration = 0.4
var invulnerability_timer = 0.0

var slow_timer = 0.0
var slow_duration = 0.75
var slow_amount = 0.2

@export var knockback_decay := 100.0
var knockback_velocity := Vector2.ZERO

@export var acceleration := 50.0
@export var friction := 60.0

@export var health_icon_scene = preload("res://Scenes/heart.tscn")
@export var stamina_icon_scene = preload("res://Scenes/stamina.tscn")
var health_icon_size = 50
var stamina_icon_size = 20

# Death light effect settings
var death_light_amplitude = 0.6  # max energy swing
var death_light_base = 0.4      # min energy
var death_light_time = 0.0       # internal timer
@export var death_duration = 4.25  # seconds before full death

var rolling = false
var roll_speed_mult = 1.5
var roll_direction : Vector2
var attacking = false
var recharging = false
var input_direction
var target_energy: float
var lerp_speed = 0.3
var switching_color = false

var is_dead = false


func _ready() -> void:
	point_light_2d.color = Color.LIGHT_YELLOW
	roll_light.color = Color.LIGHT_YELLOW
	death_particles.emitting = false
	sword_sprite.visible = true
	update_health()
	update_stamina_ui()


func _physics_process(delta):
	if !is_dead:
		get_input()
		move_and_slide()
	handle_attacking()
	handle_animations(delta)
	handle_movement(delta)
	handle_color()
	handle_slows(delta)
	
	if stamina < max_stamina and stamina_recharge.is_stopped():
		stamina_recharge.start(stamina_regen)
	
	if invulnerability_timer > 0:
		var alpha = remap(invulnerability_timer, 0, invulnerability_duration, 1, 0.5)
		invulnerability_timer -= delta
		modulate.a = alpha


func get_input():
	input_direction = Input.get_vector("left", "right", "up", "down")


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("attack") or event.is_action_pressed("roll")) and stamina <= 0:
		no_stamina()
	
	if event.is_action_pressed("roll") and input_direction and !rolling and stamina > 0:
		roll_direction = Input.get_vector("left", "right", "up", "down")
		roll_timer.start(0.3)
		rolling = true
		stamina -= 1
		update_stamina_ui()
	
	if event.is_action_pressed("attack") and !attacking and !recharging and stamina > 0 and !rolling:
		attacking = true
		attack_timer.start(0.2)
		play_sword_swing()
		stamina -= 1
		update_stamina_ui()
		await get_tree().create_timer(0.1).timeout
		attack_area.monitoring = true
	
	if event.is_action_pressed("swap_color") and !attacking and !switching_color:
		next_color()
		apply_color()
		switching_color = true
		color_timer.start(0.2)
	
	if event.is_action_pressed("level_up"):
		var upgrade_scene = get_tree().get_first_node_in_group("upgrade_screen")
		get_tree().paused = true
		upgrade_scene.spawn_random_cards(3)

func handle_movement(delta):
	var target_velocity: Vector2

	if rolling:
		velocity = roll_direction * (speed * roll_speed_mult) + (velocity / 5)
	else:
		target_velocity = input_direction * speed

	if input_direction != Vector2.ZERO or rolling:
		velocity = velocity.move_toward(target_velocity, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
	
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)


func _on_roll_timer_timeout() -> void:
	rolling = false


func handle_attacking():
	if attacking and !is_dead:
		pass
	else:
		attack_area.monitoring = false

func play_sword_swing():
	var t = create_tween()
	t.set_parallel(false)

	# Anticipation
	t.tween_property(sword_sprite, "rotation", sword_base_rotation + deg_to_rad(-20), 0.15)

	# Snap
	var tw = t.tween_property(sword_sprite, "rotation", sword_base_rotation + deg_to_rad(90), 0.1)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.set_ease(Tween.EASE_OUT)

	# Overshoot
	tw = t.tween_property(sword_sprite, "rotation", sword_base_rotation + deg_to_rad(80), 0.08)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)

	
	# Return rotation
	t.tween_property(sword_sprite, "rotation", sword_base_rotation, 0.12)


func sword_smear():
	var t = create_tween()
	await get_tree().create_timer(0.1).timeout
	t.tween_property(sword_sprite, "scale", sword_base_scale * Vector2(1.6, 0.7), 0.03)
	t.tween_property(sword_sprite, "scale", sword_base_scale, 0.03).set_delay(0.03)


func spawn_afterimages():
	for i in 10:
		var ghost = sword_sprite.duplicate()
		add_child(ghost)
		ghost.global_position = sword_sprite.global_position
		ghost.rotation = sword_sprite.rotation
		ghost.scale = sword_sprite.scale
		ghost.modulate = Color(1, 1, 1, 0.8)
		ghost.z_index -= 1

		var t = create_tween()
		t.tween_property(ghost, "modulate:a", 0.0, 0.15)
		t.tween_callback(ghost.queue_free)

		await get_tree().create_timer(0.02).timeout

func handle_color():
	if switching_color:
		target_energy = 1.5 + health * 0.15
		lerp_speed = 0.5
	else:
		target_energy = 0.4 + health * 0.15
		lerp_speed = 0.2


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		body.apply_knockback(global_position)
		
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(0.75)
		hit_stop(0.05, 0.25)
	
	if body.is_in_group("barrel"):
		body.hit()

func _on_attack_timer_timeout() -> void:
	attack_cooldown.start(0.5)
	recharging = true
	attacking = false

func _on_attack_cooldown_timeout() -> void:
	recharging = false

func _on_stamina_recharge_timeout() -> void:
	stamina += 1
	update_stamina_ui()

func _on_color_timer_timeout() -> void:
	switching_color = false

func next_color():
	color_state = ((color_state + 1) % ColorState.size()) as ColorState

func apply_color():
	match color_state:
		ColorState.RED:
			point_light_2d.color = Color.LIGHT_CORAL
			roll_light.color = Color.LIGHT_CORAL
		ColorState.GREEN:
			point_light_2d.color = Color.LIME_GREEN
			roll_light.color = Color.LIME_GREEN
		ColorState.YELLOW:
			point_light_2d.color = Color.LIGHT_YELLOW
			roll_light.color = Color.LIGHT_YELLOW

func update_health():
	if health < 1:
		die()
	
	for child in health_bar.get_children():
		child.queue_free()
	
	for i in range(max_health):
		var icon = health_icon_scene.instantiate()
		health_bar.add_child(icon)
		icon.modulate.a = 1.0 if i < health else 0.1
	
	health_bar.queue_sort()
	health_panel.queue_sort()

func update_stamina_ui():
	# Clear old icons
	for child in stamina_bar.get_children():
		child.queue_free()

	# Add current health icons
	for i in range(max_stamina):
		var icon = stamina_icon_scene.instantiate()
		stamina_bar.add_child(icon)
		icon.modulate.a = 1.0 if i < stamina else 0.1
	
	stamina_bar.queue_sort()
	stamina_panel.queue_sort()

func no_stamina():
	var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
	var ft = floating_text_scene.instantiate()
	ft.text = "No Stamina!"
	ft.add_theme_color_override("font_color", Color.RED)
	ft.global_position = global_position
	get_tree().current_scene.add_child(ft)  # Or a dedicated UI node

func handle_animations(delta):
	var health_state : int = round(remap(health, 1, max_health, 1, 3))
	collision_shape_2d.disabled = false
	roll_collision.disabled = true
	roll_light.visible = false
	point_light_2d.visible = true
	sword_sprite.visible = true
	
	point_light_2d.energy = lerp(point_light_2d.energy, target_energy, lerp_speed)
	roll_light.energy = lerp(roll_light.energy, target_energy, lerp_speed)
	
	if is_dead:
		death_light_time += delta * 4  # speed of pulsing
		point_light_2d.energy = death_light_base + sin(death_light_time) * death_light_amplitude
		animated_sprite_2d.play("Idle" + str(health_state))
		sword_sprite.visible = false
	
	if rolling:
		visuals.scale.x = -1 if input_direction.x > 0 else 1
		animated_sprite_2d.animation = "Roll"
		
		collision_shape_2d.disabled = true
		roll_collision.disabled = false
		
		roll_light.visible = true
		point_light_2d.visible = false
		
		sword_sprite.visible = false
	elif input_direction:
		animated_sprite_2d.play("Run" + str(health_state))
	else:
		animated_sprite_2d.play("Idle" + str(health_state))
	
	
	if input_direction.x:
		visuals.scale.x = -1 if input_direction.x < 0 else 1

func die():
	is_dead = true
	death_particles.emitting = true
	health = 0
	death_light_time = 0
	print("you are dying...")
	
	for cam in get_tree().get_nodes_in_group("camera"):
		cam.shake(1.5)
	
	# Start a one-shot timer to finish death
	var death_timer = Timer.new()
	death_timer.wait_time = death_duration
	death_particles.amount = 30
	damage_vignette.modulate.a = 1
	var tween = create_tween()
	tween.tween_property(ambient_light, "color", Color(0, 0, 0, 1), death_duration)
	tween.tween_property(damage_vignette, "modulate:a", 0, death_duration)
	death_particles.restart()
	death_timer.one_shot = true
	add_child(death_timer)
	death_timer.start()
	death_timer.timeout.connect(_on_death_timer_timeout)

func _on_death_timer_timeout():
	# Player fully dead: turn light off
	point_light_2d.energy = 0
	ambient_light.color = Color.BLACK
	
	for cam in get_tree().get_nodes_in_group("camera"):
		cam.shake(2.5)
	
	Engine.time_scale = 0.1
	await(get_tree().create_timer(0.2).timeout)
	Engine.time_scale = 1.0
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	GameState.reset_game()

func respawn_player():
	is_dead = false
	health = max_health
	point_light_2d.energy = 0.4 + health * 0.15
	position = spawn_pos

func take_damage(dmg, from_position: Vector2, knockback_strength):
	if invulnerability_timer > 0 or is_dead or (rolling and GameState.taken_upgrades.has("Rollin'")):
		return
	
	apply_knockback(from_position, knockback_strength)
	
	for cam in get_tree().get_nodes_in_group("camera"):
		cam.shake(0.5)
	
	hit_stop(0.05, 0.5)
	
	health -= dmg
	invulnerability_timer = invulnerability_duration
	
	for effect_node in get_tree().get_nodes_in_group("damageEffect"):
		effect_node.flash_vignette()
	
	flash_red()
	update_health()

func apply_knockback(from_position: Vector2, strength):
	var direction = (global_position - from_position).normalized()
	knockback_velocity = direction * strength

func hit_stop(time_scale, duration: float):
	Engine.time_scale = time_scale
	await(get_tree().create_timer(duration * time_scale).timeout)
	Engine.time_scale = 1.0

func slow_down():
	slow_timer = slow_duration

func handle_slows(delta):
	if slow_timer > 0:
		if rolling:
			speed = max_speed * slow_amount + 250
		else:
			speed = max_speed * slow_amount
		slow_timer -= delta
		animated_sprite_2d.modulate = Color.LIGHT_GREEN
		
		if slow_timer <= 0:
			speed = max_speed
			var tween := create_tween()
			tween.tween_property(animated_sprite_2d, "modulate", Color(1, 1, 1), 0.5)

func flash_red():
	animated_sprite_2d.modulate = Color(1, 0, 0)  # red
	var tween := create_tween()
	tween.tween_property(
		animated_sprite_2d,
		"modulate",
		Color(1, 1, 1),
		invulnerability_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

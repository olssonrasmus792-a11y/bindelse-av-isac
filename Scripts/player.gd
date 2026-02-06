extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
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
@onready var bat_sprite: AnimatedSprite2D = $AttackArea/BatSprite
@onready var color_timer: Timer = $ColorTimer

enum ColorState { YELLOW, RED, GREEN }

@export var damage = 1
@export var max_speed = 500
@export var speed = max_speed
@export var max_health = 6
@export var health = max_health
@export var max_stamina = 5
@export var stamina = max_stamina
@export var stamina_regen = 1
@export var color_state: ColorState
@export var invulnerability_duration = 0.4
var invulnerability_timer = 0.0
var slow_timer = 0.0
var slow_duration = 0.5
var slow_amount = 0.2

@export var acceleration := 50.0
@export var friction := 60.0

@export var health_icon_scene = preload("res://Scenes/heart.tscn")
@export var stamina_icon_scene = preload("res://Scenes/stamina.tscn")
var health_icon_size = 50
var stamina_icon_size = 20

var rolling = false
var roll_speed_mult = 1.5
var roll_direction : Vector2
var attacking = false
var recharging = false
var input_direction
var target_energy: float
var lerp_speed = 0.3
var switching_color = false


func _ready() -> void:
	point_light_2d.color = Color.LIGHT_YELLOW
	roll_light.color = Color.LIGHT_YELLOW
	update_health()
	update_stamina_ui()


func _physics_process(delta):
	get_input()
	move_and_slide()
	handle_animations()
	handle_movement()
	handle_attacking()
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
	if event.is_action_pressed("roll") and input_direction and !rolling and stamina > 0:
		roll_direction = Input.get_vector("left", "right", "up", "down")
		roll_timer.start(0.3)
		rolling = true
		stamina -= 1
		update_stamina_ui()
	
	if event.is_action_pressed("attack") and !attacking and !recharging and stamina > 0 and !rolling:
		attacking = true
		attack_timer.start(0.2)
		stamina -= 1
		update_stamina_ui()
	
	if event.is_action_pressed("swap_color") and !attacking and !switching_color:
		next_color()
		apply_color()
		switching_color = true
		color_timer.start(0.2)


func handle_movement():
	var target_velocity: Vector2

	if rolling:
		#velocity = roll_direction * speed * roll_speed_mult
		velocity = roll_direction * speed * roll_speed_mult + (velocity / 5)
	else:
		target_velocity = input_direction * speed

	if input_direction != Vector2.ZERO or rolling:
		velocity = velocity.move_toward(target_velocity, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)


func _on_roll_timer_timeout() -> void:
	rolling = false


func handle_attacking():
	if attacking:
		attack_area.monitoring = true
	else:
		attack_area.monitoring = false


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
		health = max_health
		point_light_2d.energy = 0.4 + health * 0.15
		print("you died")
	
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


func handle_animations():
	var health_state : int = round(remap(health, 1, max_health, 1, 3))
	collision_shape_2d.disabled = false
	roll_collision.disabled = true
	roll_light.visible = false
	point_light_2d.visible = true
	bat_sprite.visible = true
	
	point_light_2d.energy = lerp(point_light_2d.energy, target_energy, lerp_speed)
	roll_light.energy = lerp(roll_light.energy, target_energy, lerp_speed)
	
	if rolling:
		$AnimatedSprite2D.flip_h = input_direction[0] > 0
		$AnimatedSprite2D.animation = "Roll"
		
		collision_shape_2d.disabled = true
		roll_collision.disabled = false
		
		roll_light.visible = true
		point_light_2d.visible = false
		
		bat_sprite.visible = false
	elif input_direction:
		animated_sprite_2d.play("Run" + str(health_state))
	else:
		animated_sprite_2d.play("Idle" + str(health_state))
	
	
	if input_direction.x:
		$AnimatedSprite2D.flip_h = input_direction[0] < 0
		if  input_direction[0] < 0:
			attack_area.scale.x = 1
		else:
			attack_area.scale.x = -1
	
	if attacking:
		bat_sprite.play("Attack")

func take_damage(damage):
	if invulnerability_timer <= 0:
		health -= damage
		invulnerability_timer = invulnerability_duration
		flash_red()
		update_health()

func slow_down():
	slow_timer = slow_duration

func handle_slows(delta):
	if slow_timer > 0:
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

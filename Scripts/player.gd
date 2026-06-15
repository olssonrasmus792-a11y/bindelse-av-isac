extends CharacterBody2D

@export var CHEATS = false

@onready var visuals: Node2D = $Visuals
@onready var sword: Node2D = $Sword
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
@onready var stamina_bar: Control = $"../UI/stamina_panel/stamina_bar"
@onready var cooldown_bar: ProgressBar = $CooldownBar
@onready var health_panel: PanelContainer = $"../UI/health_panel"
@onready var stamina_panel: PanelContainer = $"../UI/stamina_panel"
@onready var attack_area: Area2D = $Sword/SwordPivot/SwordSprite/AttackArea
@onready var sword_sprite: AnimatedSprite2D = $Sword/SwordPivot/SwordSprite
@onready var color_timer: Timer = $ColorTimer
@onready var ambient_light: CanvasModulate = $"../Ambient Light"
@onready var death_particles: GPUParticles2D = $Visuals/DeathParticles
@onready var damage_vignette: TextureRect = $"../UI/DamageVignette"
@onready var low_battery: Panel = $LowBattery
@onready var glass_break: AudioStreamPlayer = $GlassBreak
@onready var pop_3: AudioStreamPlayer = $Pop3
@onready var punch_1: AudioStreamPlayer = $Punch1
@onready var punch_2: AudioStreamPlayer = $Punch2
@onready var punch_3: AudioStreamPlayer = $Punch3
@onready var pop_4: AudioStreamPlayer = $Pop4
@onready var bonk: AudioStreamPlayer = $Bonk
@onready var sparks: AudioStreamPlayer = $Sparks
@onready var deny: AudioStreamPlayer = $Deny
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var end_stats: Control = $"../UI/AnimationPlayer/EndStats"

enum ColorState { YELLOW, RED, GREEN }

@onready var sword_base_position = sword_sprite.position
@onready var sword_base_rotation = sword_sprite.rotation
@onready var sword_base_scale = sword_sprite.scale

var spawn_pos

@export var level: int = 1
@export var xp: float = 0.0
@export var xp_to_next_level: int = 80
@export var xp_gain: float = 1.00
var xp_combo := 0
var combo_timer := 0.0

const COMBO_RESET_TIME := 1.0

@export var damage = 20
@export var crit_chance = 0.05
@export var crit_damage = 1.5
@export var attack_speed = 0.3
@export var knockback = 650
@export var total_crit_hits = 0
@export var crit_damage_dealt = 0
@export var chest_bonus_damage = 0.0

@export var ability_name = ""
@export var ability_cooldown = 5.0
@export var ability_timer = 0.0
@export var ability_damage_mult = 1.0

@export var explosion_size = 1.0
@export var explosion_damage = 20
@export var explosion_particles = 20

var enemies_hit := {}
var enemies_hit_roll := {}

var chain_count := 5          # how many extra enemies it can hit
var chain_range := 450.0     # how far it can jump
var chain_falloff := 0.75    # damage multiplier per jump

@export var max_speed = 500
@export var speed = max_speed

@export var max_health = 6
@export var health = max_health

const STAMINA_BAR_WIDTH := 220.0
@export var max_stamina = 6
@export var stamina = max_stamina
@export var stamina_regen = 1.0 # Sekunder per stamina

@export var color_state: ColorState

@export var invulnerability_duration = 0.8
var invulnerability_timer = 0.0

var slow_timer = 0.0
var slow_duration = 0.75
var slow_amount = 0.2

@export var knockback_decay := 100.0
var knockback_velocity := Vector2.ZERO

@export var acceleration := 50.0
@export var friction := 70.0

@export var health_icon_scene = preload("res://Scenes/heart.tscn")
@export var stamina_icon_scene = preload("res://Scenes/stamina.tscn")
var health_icon_size = 50
var stamina_icon_size = 20

# Death light effect settings
var death_light_amplitude = 0.6  # max energy swing
var death_light_base = 0.4      # min energy
var death_light_time = 0.0       # internal timer
@export var death_duration = 4.25  # seconds before full death

var hitstop_used := false
var bonking = false
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
	low_battery.visible = false
	attack_area.monitoring = false
	stamina_bar.custom_minimum_size = Vector2(STAMINA_BAR_WIDTH, 32)
	stamina_bar.size = Vector2(STAMINA_BAR_WIDTH, 32)
	update_health()
	update_stamina_ui()
	
	
	if GameState.weapon == "Lightning Sword":
		sword_sprite.animation = "Idle_Sword"
		ability_name = "Boomerang"
		ability_cooldown = 10.0
		ability_damage_mult = 1.0
		damage = GameState.lightning_sword_damage
		knockback = GameState.lightning_sword_knockback
		crit_chance = GameState.lightning_sword_crit_chance
		crit_damage = GameState.lightning_sword_crit_damage
		if GameState.lightning_sword_level >= 50:
			xp_gain *= 1.5
	
	if GameState.weapon == "Baseball Bat":
		sword_sprite.animation = "Idle_Bat"
		ability_name = "Bonk"
		ability_cooldown = 5.0
		ability_damage_mult = 1.0
		damage = GameState.baseball_bat_damage
		knockback = GameState.baseball_bat_knockback
		crit_chance = GameState.baseball_bat_crit_chance
		crit_damage = GameState.baseball_bat_crit_damage
	
	CardRegistry.new()
	
	damage *= 1.00 + GameState.meta_bonus_damage

func _physics_process(delta):
	if !is_dead:
		get_input()
		move_and_slide()
	handle_attacking(delta)
	handle_abilities(delta)
	handle_animations(delta)
	handle_movement(delta)
	handle_color()
	handle_slows(delta)
	
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			xp_combo = 0
	
	if stamina < max_stamina and stamina_recharge.is_stopped():
		if GameState.is_fighting or GameState.boss_spawned or GameState.boss_killed:
			stamina_recharge.start(stamina_regen)
		else:
			stamina_recharge.start(stamina_regen / 4)
	
	if invulnerability_timer > 0:
		var alpha = remap(invulnerability_timer, 0, invulnerability_duration, 0.75, 0.5)
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
		invulnerability_timer = 0.45
		stamina -= 1
		enemies_hit_roll.clear()
		update_stamina_ui()
	
	if event.is_action_pressed("Ability") and ability_name != "":
		use_ability()
	
	if event.is_action_pressed("level_up") and CHEATS:
		pop_3.play()
		get_tree().paused = true
		var ui = get_tree().get_first_node_in_group("level_up_ui")
		ui.show_level_up()
	
	if event.is_action_pressed("c") and CHEATS:
		GameState.coins += 10
		max_stamina += 1
		max_health += 1
		update_stamina_ui()
		update_health()

func handle_movement(delta):
	if is_dead:
		return
	
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
	
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if rolling and GameState.get_item_count("Rollin'") > 0:
			if collider.is_in_group("enemies"):
				if enemies_hit_roll.has(collider):
					return  # already hit this attack
				
				play_hit_sound()
				enemies_hit_roll[collider] = true
				
				GameState.total_damage_dealt += (GameState.get_item_count("Rollin'") * 10)
				collider.take_damage(GameState.get_item_count("Rollin'") * 10)
				collider.apply_knockback(collider.global_position - global_position, knockback * 2)
				for item in GameState.taken_items:
					if item.name == "Rollin'":
						item.tracked_stat_values[0] += 10
				
				spawn_floating_text("-" + str(int(GameState.get_item_count("Rollin'") * 10)), Color.WHITE, collider.global_position)

func _on_roll_timer_timeout() -> void:
	rolling = false

func handle_attacking(_delta):
	if Input.is_action_pressed("attack") and !attacking and !recharging and stamina > 0 and !rolling and !is_dead:
		if sword.thrown:
			return
		attacking = true
		cooldown_bar.value = 0.0
		cooldown_bar.visible = true
		attack_timer.start(attack_speed)
		play_sword_swing()
		stamina -= 1
		update_stamina_ui()
		enemies_hit.clear()
		hitstop_used = false

	# Detect attacking from animation
	attacking = animation_player.is_playing()

	var attack_running := !attack_timer.is_stopped()
	var cooldown_running := !attack_cooldown.is_stopped()

	# Show bar while attack OR cooldown active
	cooldown_bar.visible = attack_running or cooldown_running

	# Ready again
	if not attack_running and not cooldown_running:
		cooldown_bar.value = 1.0
		return

	# --- TOTAL TIME ---
	var attack_time := attack_timer.wait_time
	var cooldown_time := attack_cooldown.wait_time
	var total_time := attack_time + cooldown_time

	var progress := 0.0

	# --- DURING ATTACK ---
	if attack_running:
		var elapsed_attack := (
			attack_time - attack_timer.time_left
		)

		progress = elapsed_attack / total_time

	# --- DURING COOLDOWN ---
	elif cooldown_running:
		var elapsed_cooldown := (
			cooldown_time - attack_cooldown.time_left
		)

		progress = (
			attack_time + elapsed_cooldown
		) / total_time

	cooldown_bar.value = progress

func _on_attack_timer_timeout() -> void:
	attack_cooldown.start(attack_speed)
	recharging = true

func _on_attack_cooldown_timeout() -> void:
	recharging = false

func play_sword_swing():
	var speed_mult = 1 / (attack_speed * 2.5)

	animation_player.speed_scale = speed_mult
	animation_player.play("sword_swing")

func handle_color():
	if switching_color:
		target_energy = 1.5 + health * 0.15
		lerp_speed = 0.5
	else:
		target_energy = 1.0 + health * 0.05
		lerp_speed = 0.2

func _on_attack_area_body_entered(body: Node2D) -> void:
	var aim_direction = (get_global_mouse_position() - global_position).normalized()
	
	if sword.thrown:
		if sword.returning:
			aim_direction = (global_position - sword.sword_sprite.global_position).normalized()
		else:
			aim_direction = sword.throw_direction
	
	if body.is_in_group("enemies"):
		if enemies_hit.has(body):
			return  # already hit this attack
		
		play_hit_sound()
		enemies_hit[body] = true
		
		var total_damage = calculate_base_damage()
		var text_color = Color.WHITE
		
		if body.is_in_group("boss"):
			if !body.spawned:
				return
			
			for item in GameState.taken_items:
				if item.name == "Boss Killer" and body.is_in_group("boss"):
					item.tracked_stat_values[0] += int((total_damage * (1 + (GameState.get_item_count("Boss Killer") * 0.15))) - total_damage)
					break
			
			total_damage *= (1 + (GameState.get_item_count("Boss Killer") * 0.15))
		
		var ft_text = "-" + str(int(total_damage))
		
		if randf() < crit_chance:
			total_crit_hits += 1
			crit_damage_dealt += int((total_damage * crit_damage) - total_damage)
			total_damage *= crit_damage
			text_color = Color.YELLOW
			ft_text = "-" + str(int(total_damage))
		
		for item in GameState.taken_items:
			if item.name == "Big Crit":
				item.tracked_stat_values[1] = crit_damage_dealt
			if item.name == "Critter":
				item.tracked_stat_values[1] = total_crit_hits
		
		GameState.total_damage_dealt += total_damage
		body.take_damage(total_damage)
		body.apply_knockback(aim_direction, knockback)
		
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(0.5)
		
		if !hitstop_used:
			hit_stop(0.05, 0.25)
			hitstop_used = true
		
		spawn_floating_text(ft_text, text_color, body.global_position)
		
		if GameState.get_item_count("Chainy") > 0:
			chain_hit(body, total_damage, chain_count)

	if body.is_in_group("barrel"):
		if enemies_hit.has(body):
			return  # already hit this attack
		play_hit_sound()
		enemies_hit[body] = true
		body.hit()
		body.apply_knockback(aim_direction)

func chain_hit(from_enemy: CharacterBody2D, dmg: float, remaining_chains: int) -> void:
	if remaining_chains <= 0:
		return

	if not is_instance_valid(from_enemy):
		return

	var from_pos: Vector2 = from_enemy.global_position

	var enemies = get_tree().get_nodes_in_group("enemies")

	var closest_enemy: CharacterBody2D = null
	var closest_dist := chain_range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		if enemy == from_enemy:
			continue

		var id = enemy.get_instance_id()

		if enemies_hit.has(id):
			continue

		var dist = from_pos.distance_to(enemy.global_position)

		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy

	if closest_enemy == null:
		return

	# Cache BEFORE awaits
	var target_pos: Vector2 = closest_enemy.global_position
	var target_enemy: CharacterBody2D = closest_enemy
	var target_id = target_enemy.get_instance_id()

	await get_tree().create_timer(0.06).timeout

	# Always spawn lightning (visual even if dead)
	spawn_lightning(from_pos, target_pos)
	hit_stop(0.5, 0.02)

	await get_tree().create_timer(0.06).timeout

	# DAMAGE only if still alive
	if is_instance_valid(target_enemy):

		enemies_hit[target_id] = true

		var new_damage = dmg * chain_falloff

		GameState.total_damage_dealt += int(new_damage)
		target_enemy.take_damage(new_damage)

		# Track item stats
		for item in GameState.taken_items:
			if item.name == "Chainy":
				item.tracked_stat_values[1] += 1
				item.tracked_stat_values[0] += int(new_damage)
				break

		spawn_floating_text("-" + str(int(new_damage)), Color.WHITE, target_pos)

		# Knockback
		var dir = (target_pos - from_pos).normalized()
		target_enemy.apply_knockback(dir, 0)

		# Safe recursive call
		if is_instance_valid(target_enemy):
			await chain_hit(target_enemy, new_damage, remaining_chains - 1)

	else:
		# Continue chain ONLY if original still exists
		if is_instance_valid(from_enemy):
			await chain_hit(from_enemy, dmg, remaining_chains - 1)

func spawn_lightning(start: Vector2, end: Vector2):
	var lightning_scene = preload("res://Scenes/chain_lightning.tscn")
	var lightning = lightning_scene.instantiate()

	get_tree().current_scene.add_child(lightning)

	lightning.setup(start, end)

func play_hit_sound():
	var roll = randf()
	
	if bonking:
		bonk.play(0.27)
	
	if roll < 0.33:
		punch_1.pitch_scale = randf_range(1.2, 1.6)
		punch_1.play(0.1)
	elif roll < 0.66:
		punch_2.pitch_scale = randf_range(0.9, 1.3)
		punch_2.play()
	else:
		punch_3.pitch_scale = randf_range(0.9, 1.3)
		punch_3.play()

func calculate_base_damage():
	var total_damage
	@warning_ignore("integer_division")
	var coin_groups = floor(GameState.coins / 5)
	
	total_damage = damage
	
	for item in GameState.taken_items:
		if item.name == "Sword":
			item.tracked_stat_values[0] += 5
	total_damage += GameState.get_item_count("Sword") * 5
	
	total_damage *= 1 + chest_bonus_damage
	
	for item in GameState.taken_items:
		if item.name == "Greedy ahh":
			item.tracked_stat_values[1] += int((total_damage * (1 + 0.05 * GameState.get_item_count("Greedy ahh") * coin_groups)) - total_damage)
			break
	total_damage *= 1 + 0.05 * GameState.get_item_count("Greedy ahh") * coin_groups
	
	if bonking:
		total_damage *= ability_damage_mult
	
	return total_damage

func handle_abilities(delta):
	if ability_timer > 0:
		ability_timer -= delta
		if ability_timer <= 0:
			ability_timer = 0
			spawn_floating_text("Ability Ready!", Color(0.288, 0.93, 0.299, 1.0), global_position)

func use_ability():
	if is_dead:
		return
	
	if ability_timer > 0:
		deny.play()
		spawn_floating_text("%.1f" % ability_timer + " Sec", Color(2.184, 0.0, 0.168, 1.0), global_position)
		return
	
	ability_timer = ability_cooldown
	
	animation_player.stop()
	
	if ability_name == "Boomerang":
		boomerang_ability()
	
	if ability_name == "Bonk":
		bonk_ability()

func boomerang_ability():
	enemies_hit.clear()
	hitstop_used = false
	sword.throw_sword()

func bonk_ability():
	var base_knockback = knockback
	knockback = base_knockback * 2
	
	bonking = true
	attacking = true
	cooldown_bar.value = 0.0
	cooldown_bar.visible = true
	attack_timer.start(attack_speed)
	play_sword_swing()
	enemies_hit.clear()
	hitstop_used = false
	
	# Tween: normal -> big -> small
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_sprite, "scale", Vector2(0.5, 0.5), 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(sword_sprite, "scale", Vector2(0.25, 0.25), 0.25)
	
	await attack_timer.timeout
	
	sword_sprite.scale = Vector2(0.25, 0.25)
	knockback = base_knockback
	bonking = false

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
	
	if health > max_health:
		health = max_health
	
	for child in health_bar.get_children():
		child.queue_free()
	
	# Read the available width BEFORE adding any icons
	var available_width = health_bar.size.x
	
	for i in range(max_health):
		var icon = health_icon_scene.instantiate()
		health_bar.add_child(icon)
		icon.modulate.a = 1.0 if i < health else 0.1
	
	await get_tree().process_frame
	
	if max_health > 1:
		var icon_width = health_bar.get_child(0).size.x
		var total_icon_width = icon_width * max_health
		var separation = int((available_width - total_icon_width) / (max_health - 1))
		health_bar.add_theme_constant_override("separation", separation)
	else:
		health_bar.add_theme_constant_override("separation", 0)
	
	health_bar.queue_sort()
	health_panel.queue_sort()

func update_stamina_ui():
	# Clear old icons
	for child in stamina_bar.get_children():
		child.queue_free()

	var count = max_stamina
	if count <= 0:
		return

	var spacing := (STAMINA_BAR_WIDTH - 10) / float(count)

	for i in range(count):
		var icon = stamina_icon_scene.instantiate()
		stamina_bar.add_child(icon)

		# position each icon inside fixed width
		icon.position = Vector2(i * spacing + 10, 0)

		# center inside slot
		icon.position.x += spacing * 0.5 - icon.size.x * 0.5

		# visual state
		icon.modulate.a = 1.0 if i < stamina else 0.1

	low_battery.visible = stamina < 2 or (stamina == 1 and stamina_recharge.time_left > stamina_regen / 2)

func no_stamina():
	spawn_floating_text("No Stamina!", Color.RED, global_position)
	deny.play()

func add_xp(amount: int):
	if is_dead:
		return
	
	xp_gain = 1.00 + GameState.meta_bonus_xp_gain
	
	amount = int(amount * xp_gain)
	
	GameState.total_xp_gained += amount
	xp += amount
	spawn_floating_text("+" + str(amount) + "xp", Color.DEEP_SKY_BLUE, global_position)
	
	xp_combo += 1
	combo_timer = COMBO_RESET_TIME
	
	var pitch = lerp(0.8, 1.6, clamp(xp_combo / 100.0, 0.0, 1.0))
	pop_4.pitch_scale += randf_range(-0.1, 0.2)
	pop_4.pitch_scale = pitch
	pop_4.play()
	
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level_up()

func level_up():
	level += 1
	
	# Scale XP requirement (important!)
	xp_to_next_level = int(xp_to_next_level * 1.24)
	
	# Trigger upgrade selection here
	upgrade_cards()

func upgrade_cards(): #Använd för xp system sen
	pop_3.play()
	get_tree().paused = true
	var ui = get_tree().get_first_node_in_group("level_up_ui")
	ui.show_level_up()

func handle_animations(delta):
	@warning_ignore("narrowing_conversion")
	var health_state : int = remap(health, 0, max_health, 1, 3)
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
		
		roll_collision.disabled = false
		await get_tree().physics_frame
		collision_shape_2d.disabled = true
		
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
	sparks.play()
	health = 0
	death_light_time = 0
	
	MusicManager.set_music_muffle(0.5, 2.5)
	MusicManager.set_music_pitch(0.5, 2.5)
	
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
	
	Engine.time_scale = 1.0
	
	await get_tree().create_timer(0.1).timeout
	
	end_stats.update_values()
	end_stats.visible = true
	
	var cutscene = get_tree().get_first_node_in_group("cutscene")
	cutscene.play("stats")
	
	var active_ghosts = get_tree().get_nodes_in_group("ghosty")
	for ghost in active_ghosts:
		ghost.queue_free()

func respawn_player():
	is_dead = false
	health = max_health
	point_light_2d.energy = 0.4 + health * 0.15
	position = spawn_pos

func take_damage(dmg, from_position: Vector2, knockback_strength):
	if rolling:
		if invulnerability_timer > 0.1:
			invulnerability_timer -= 0.01
		spawn_floating_text("Dodge!", Color.HOT_PINK, global_position)
		return
	
	if invulnerability_timer > 0 or is_dead:
		if invulnerability_timer > 0.1:
			invulnerability_timer -= 0.01
		return
	
	glass_break.pitch_scale = randf_range(1.0, 1.75)
	glass_break.play()
	
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

func spawn_floating_text(text: String, color: Color, pos: Vector2):
	var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
	var ft = floating_text_scene.instantiate()
	
	ft.text = text
	ft.modulate = color
	ft.global_position = pos
	
	get_tree().current_scene.call_deferred("add_child", ft)

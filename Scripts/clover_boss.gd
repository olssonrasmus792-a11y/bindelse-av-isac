extends CharacterBody2D

@onready var player := get_tree().get_first_node_in_group("player")

@onready var projectile_scene = preload("res://Scenes/clover_projectile.tscn")
@export var explosion_scene = preload("res://Scenes/Enemies/MuddyExplosion.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var hp_bar: TextureProgressBar = $TextureProgressBar

var player_is_close = false
var bullet_hell_active = false
var burst_hell_active = false

var normal_speed = 450
var bullet_hell_speed = 400
var burst_hell_speed = 350

var max_health = 40.0
var health = max_health
signal enemy_died


func _ready() -> void:
	hp_bar.max_value = max_health
	hp_bar.value = max_health

func _process(_delta: float) -> void:
	hp_bar.value = lerp(hp_bar.value, health, 0.25)

func spawn_projectile(direction: Vector2, speed: int) -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = Vector2(global_position.x, global_position.y - 30)
	projectile.direction = direction
	projectile.speed = speed
	get_tree().current_scene.add_child(projectile)

func bullet_hell():
	bullet_hell_active = true
	animated_sprite_2d.play("Spin")
	
	for i in range(50):
		var angle = i * 0.4
		var direction = Vector2.RIGHT.rotated(angle)
		spawn_projectile(-direction, bullet_hell_speed)
		spawn_projectile(direction,  bullet_hell_speed)
		await get_tree().create_timer(0.1).timeout
	
	animated_sprite_2d.play("Idle")
	bullet_hell_active = false

func burst_hell():
	burst_hell_active = true
	animated_sprite_2d.play("Spin")

	for x in range(5):
		shoot_burst()
		await get_tree().create_timer(1).timeout

	animated_sprite_2d.play("Idle")
	burst_hell_active = false

func shoot_burst():
	var bullets := 36
	var gap_width := 0.3  # radians (~17°)
	
	# angle pointing roughly toward the player
	var player_angle = (player.global_position - global_position).angle()
	# add a random offset so the gap is near but not exactly at the player
	var max_offset := 0.4  # radians (~45°)
	var gap_angle = player_angle + randf_range(-max_offset, max_offset)

	for i in range(bullets):
		var angle = i * TAU / bullets
		
		# skip bullets inside the gap
		if abs(angle_difference(angle, gap_angle)) < gap_width:
			continue
		
		var direction = Vector2.RIGHT.rotated(angle)
		spawn_projectile(direction, burst_hell_speed)

func _on_shoot_timer_timeout() -> void:
	if bullet_hell_active or burst_hell_active:
		shoot_timer.wait_time = randf_range(4, 5)
		return
	
	animated_sprite_2d.play("Shoot")
	
	await get_tree().create_timer(0.9).timeout
	
	if randf() < 0.25:
		bullet_hell()
		return
	
	if randf() < 0.25:
		burst_hell()
		return
	
	if player_is_close:
		var direction = (player.global_position - global_position).normalized()
		spawn_projectile(direction, normal_speed)
	
	await animated_sprite_2d.animation_finished
	
	animated_sprite_2d.play("Idle")
	
	shoot_timer.wait_time = randf_range(4, 5)

func take_damage(damage):
	health -= damage
	flash_red()
	if health <= 0:
		explode(self)  

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

func apply_knockback(_from_position: Vector2):
	pass

func explode(enemy):
	var explosion = explosion_scene.instantiate()
	
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	explosion.emitting = true
	
	emit_signal("enemy_died")
	enemy.queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

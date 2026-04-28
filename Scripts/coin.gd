extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var coin: AudioStreamPlayer = $Coin
@onready var shadow: ColorRect = $Shadow
@onready var area_2d: Area2D = $PickUpArea

var base_y
var time := 0.0
@export var float_speed := 2.0
@export var float_amount := 5.0

var velocity := Vector2.ZERO
var gravity := 900.0
var bounce := 0.4
var floor_y := 0.0
var flying := false
var has_bounced := false

var pickup_delay_timer = 0.0
var pickup_delay_duration = 0.5

var can_pick_up = false
var player_is_close = false

func _ready() -> void:
	pickup_delay_timer = pickup_delay_duration
	base_y = sprite_2d.position.y

func _process(delta: float) -> void:
	if pickup_delay_timer > 0:
		pickup_delay_timer -= delta
		if pickup_delay_timer <= 0:
			can_pick_up = true
	
	if player_is_close and can_pick_up:
		play_pickup_sound()
		GameState.coins += 1
		GameState.calculate_stats()
		var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
		var ft = floating_text_scene.instantiate()
		ft.text = "+1 Coin"
		ft.modulate = Color.GOLD
		ft.global_position = global_position
		get_tree().current_scene.add_child(ft)  # Or a dedicated UI node
		queue_free()
	
	time += delta
	sprite_2d.position.y = base_y + sin(time * float_speed) * float_amount

func _physics_process(delta):
	if flying:
		if !has_bounced:
			shadow.visible = false
			area_2d.monitoring = false

		velocity.y += gravity * delta
		position += velocity * delta

		# Hit ground
		if global_position.y >= floor_y:
			global_position.y = floor_y
			has_bounced = true

			# Bounce
			if abs(velocity.y) > 50:
				velocity.y *= -bounce
				velocity.x *= 0.6 # lose some sideways speed
				area_2d.monitoring = true
				shadow.visible = true
			else:
				velocity = Vector2.ZERO
				flying = false
				area_2d.monitoring = true
				shadow.visible = true

func _on_pick_up_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and can_pick_up:
		player_is_close = true

func _on_pick_up_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

func play_pickup_sound():
	var sound = coin
	coin.pitch_scale = randf_range(1.1, 1.4)
	
	sound.get_parent().remove_child(sound)
	get_tree().current_scene.add_child(sound)
	sound.play()

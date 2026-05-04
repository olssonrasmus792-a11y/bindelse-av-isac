extends Node2D

var player: Node2D = null

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var pop_4: AudioStreamPlayer = $Pop4

var base_y
var time := 0.0
@export var float_speed := 2.0
@export var float_amount := 5.0

var pickup_delay_timer = 0.0
var pickup_delay_duration = 0.1

@export var speed: float = 0
@export var magnet_range: float = 200
var magnet_enabled := false

var can_pick_up = false
var player_is_close = false

func _ready() -> void:
	pickup_delay_timer = pickup_delay_duration
	base_y = sprite_2d.position.y
	
	await get_tree().create_timer(randf_range(0.35, 0.6)).timeout
	magnet_enabled = true

func _process(delta: float) -> void:
	if pickup_delay_timer > 0:
		pickup_delay_timer -= delta
		if pickup_delay_timer <= 0:
			can_pick_up = true
	
	if player_is_close and can_pick_up:
		player = get_tree().get_first_node_in_group("player")
		if player.health < player.max_health:
			player.health += 1  # or however much you want
			player.update_health()
		
		play_pickup_sound()
		var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
		var ft = floating_text_scene.instantiate()
		ft.text = "+1 Hp"
		ft.modulate = Color.DEEP_PINK
		ft.global_position = global_position
		get_tree().current_scene.add_child(ft)  # Or a dedicated UI node
		queue_free()
	
	time += delta
	sprite_2d.position.y = base_y + sin(time * float_speed) * float_amount
	
	player = get_tree().get_first_node_in_group("player")
	
	var distance = global_position.distance_to(player.global_position)
	if magnet_enabled and distance < magnet_range:
		var direction = (player.global_position - global_position).normalized()
		speed = lerp(speed, 500.0, 0.1)
		global_position += direction * speed * delta

func _on_pick_up_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true

func _on_pick_up_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

func play_pickup_sound():
	var sound = pop_4
	pop_4.pitch_scale = randf_range(0.9, 1.2)
	
	sound.get_parent().remove_child(sound)
	get_tree().current_scene.add_child(sound)
	sound.play()

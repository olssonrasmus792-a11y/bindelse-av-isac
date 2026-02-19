extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D

var base_y
var time := 0.0
@export var float_speed := 2.0
@export var float_amount := 5.0

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
		var player = get_tree().get_nodes_in_group("player")
		
		for p in player:
			if p.health < p.max_health:
				p.health += 1  # or however much you want
				p.update_health()
		
		var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
		var ft = floating_text_scene.instantiate()
		ft.text = "+1 Hp"
		ft.modulate = Color.DEEP_PINK
		ft.global_position = global_position
		get_tree().current_scene.add_child(ft)  # Or a dedicated UI node
		queue_free()
	
	time += delta
	sprite_2d.position.y = base_y + sin(time * float_speed) * float_amount

func _on_pick_up_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and can_pick_up:
		player_is_close = true

func _on_pick_up_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

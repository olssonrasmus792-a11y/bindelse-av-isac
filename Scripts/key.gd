extends Node2D

var pickup_delay_timer = 0.0
var pickup_delay_duration = 0.5

var can_pick_up = false
var player_is_close = false

func _ready() -> void:
	pickup_delay_timer = pickup_delay_duration

func _process(delta: float) -> void:
	if pickup_delay_timer > 0:
		pickup_delay_timer -= delta
		if pickup_delay_timer <= 0:
			can_pick_up = true
	
	if player_is_close and can_pick_up:
		GameState.keys += 1
		queue_free()

func _on_pick_up_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and can_pick_up:
		player_is_close = true

func _on_pick_up_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false

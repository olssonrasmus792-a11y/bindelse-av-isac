extends GPUParticles2D

@onready var player := get_tree().get_first_node_in_group("player")

var explosion_damage
var explosion_particles

func _ready() -> void:
	amount = explosion_particles

func _on_area_2d_body_entered(body: Node2D) -> void:
	var aim_direction = (body.global_position - global_position).normalized()
	
	if body.is_in_group("enemies"):
		var total_damage = calculate_base_damage()
		var text_color = Color.WHITE
		var ft_text = "-" + str(int(total_damage))
		
		if randf() < player.crit_chance:
			total_damage *= 1.5
			text_color = Color.YELLOW
			ft_text = "-" + str(int(total_damage))
		
		body.take_damage(total_damage)
		body.apply_knockback(aim_direction)
		
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(0.75)
		
		player.hit_stop(0.05, 0.25)
		
		var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
		var ft = floating_text_scene.instantiate()
		ft.text = ft_text
		ft.modulate = text_color
		ft.global_position = body.global_position
		get_tree().current_scene.add_child(ft)
	
	if body.is_in_group("barrel"):
		body.hit()
		body.apply_knockback(aim_direction)

func calculate_base_damage():
	var total_damage
	
	total_damage = explosion_damage
	
	total_damage *= 1 + (GameState.get_item_count("Barrel") * 0.5)
	for item in GameState.taken_items:
		if item.name == "Barrel":
			item.damage_dealt += total_damage - explosion_damage
			break
	
	return int(total_damage)

func _on_finished() -> void:
	queue_free()

extends GPUParticles2D

@onready var player := get_tree().get_first_node_in_group("player")

var explosion_damage

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var total_damage = explosion_damage
		var text_color = Color.WHITE
		var ft_text = "-" + str(int(total_damage))
		
		if randf() < player.crit_chance:
			total_damage *= 1.5
			text_color = Color.YELLOW
			ft_text = "-" + str(int(total_damage))
		
		body.take_damage(total_damage)
		body.apply_knockback(global_position)
		
		for cam in get_tree().get_nodes_in_group("camera"):
			cam.shake(0.75)
		
		player.hit_stop(0.05, 0.25)
		
		var floating_text_scene = preload("res://Scenes/FloatingText.tscn")
		var ft = floating_text_scene.instantiate()
		ft.text = ft_text
		ft.modulate = text_color
		ft.global_position = body.global_position
		get_tree().current_scene.add_child(ft)

func _on_finished() -> void:
	queue_free()

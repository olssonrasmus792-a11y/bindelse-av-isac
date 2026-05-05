extends GPUParticles2D

@onready var player := get_tree().get_first_node_in_group("player")

var explosion_damage
var explosion_particles
var monitoring_time = 0.1
var time_left
@onready var area_2d: Area2D = $Area2D
@onready var explosion: AudioStreamPlayer = $Explosion
@export var knockback = 450

func _ready() -> void:
	amount = explosion_particles
	time_left = monitoring_time
	explosion.pitch_scale = randf_range(0.5, 0.75)
	explosion.play()

func _process(delta: float) -> void:
	time_left -= delta
	
	if time_left <= 0:
		area_2d.monitoring = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	var aim_direction = (body.global_position - global_position).normalized()
	
	if body.is_in_group("enemies"):
		var total_damage = calculate_base_damage()
		var text_color = Color.WHITE
		
		if body.is_in_group("boss"):
			if !body.spawned:
				return
			total_damage *= (1 + (GameState.get_item_count("Boss Killer") * 0.15))
		
		var ft_text = "-" + str(int(total_damage))
		
		if randf() < player.crit_chance:
			total_damage *= 1.5
			text_color = Color.YELLOW
			ft_text = "-" + str(int(total_damage))
		
		GameState.total_damage_dealt += total_damage
		body.take_damage(total_damage)
		body.apply_knockback(aim_direction, knockback)
		
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
	@warning_ignore("integer_division")
	var coin_groups = floor(GameState.coins / 5)
	
	total_damage = explosion_damage
	
	total_damage *= 1 + (GameState.get_item_count("Barrel") * 0.5)
	
	for item in GameState.taken_items:
		if item.name == "Barrel":
			item.tracked_stat_values[0] += int(total_damage - explosion_damage)
			break
	
	for item in GameState.taken_items:
		if item.name == "Greedy ahh":
			item.tracked_stat_values[1] += int((total_damage * (1 + 0.05 * GameState.get_item_count("Greedy ahh") * coin_groups)) - total_damage)
	total_damage *= 1 + 0.05 * GameState.get_item_count("Greedy ahh") * coin_groups
	
	return int(total_damage)

func _on_finished() -> void:
	queue_free()

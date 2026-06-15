extends Node2D

@onready var player := get_tree().get_first_node_in_group("player")

@export var enemy_scene := preload("res://Scenes/Enemies/Muddy.tscn")
@export var snail_scene := preload("res://Scenes/Enemies/Snail.tscn")
@export var stoney_scene := preload("res://Scenes/Enemies/stoney.tscn")
@export var ghosty_scene := preload("res://Scenes/Enemies/ghosty.tscn")
@export var clover_boss_scene := preload("res://Scenes/clover_boss.tscn")
@onready var ui: CanvasLayer = $"../UI"
@onready var stronger_ghosts: Label = $"../UI/StrongerGhosts"

var label_start_pos: Vector2
var stronger_label_t := 0.0
var stronger_label_active := false
var stronger_label_duration := 1.4

var spawn_muddy = false
var spawn_snail = false
var spawn_stoney = false
var spawn_clover_boss = false
var spawn_ghosty = true

var ghost_phase := 1
var next_phase_trigger := 0.1 # seconds
var phase_timer := 0.0
var next_phase_timer_trigger := 2.5

var ghosty_timer = 0.0
var ghosty_spawn_interval = 5.0
var ghost_increase_timer = 0.0
var ghost_increase_interval = 5.0
var ghosty_bonus_speed = 0
var ghosty_bonus_health = 0
var ghosty_modulate = 1.0
var ghosty_limit = 250

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label_start_pos = stronger_ghosts.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GameState.boss_spawned and !GameState.boss_killed:
		ghosty_spawn_interval = 2.0
		ghosty_bonus_speed = 60
	
	if GameState.time_left <= 0:
		ghosty_timer += delta * ghost_phase
		ghost_increase_timer += delta
	
	if ghost_increase_timer >= ghost_increase_interval:
		ghost_increase_timer = 0.0
		ghosty_spawn_interval -= 0.2
		ghosty_bonus_speed += 15
		ghosty_spawn_interval = clampf(ghosty_spawn_interval, 0.05, 5.0)
	
	if ghosty_spawn_interval <= next_phase_trigger:
		phase_timer += delta
	
	if phase_timer >= next_phase_timer_trigger:
		phase_timer = 0.0
		enter_next_phase()
	
	if ghosty_timer >= ghosty_spawn_interval:
		ghosty_timer = 0.0
		var roll = randf()
		var dir
		if roll < 0.5:
			dir = -1
		else:
			dir = 1
		spawn_enemy(Vector2(player.global_position.x + (randi_range(1200, 2000) * dir), player.global_position.y + (randi_range(800, 1600) * dir)))
	
	if stronger_label_active:
		stronger_label_t += delta

		var t := stronger_label_t / stronger_label_duration

		# pop back down in scale
		stronger_ghosts.scale = lerp(Vector2(1.8, 1.8), Vector2(0.8, 0.8), t)
		stronger_ghosts.position.x += randf_range(-0.1, 0.1)
		stronger_ghosts.position.y += randf_range(-0.1, 0.1)

		# fade out
		var alpha := 1.0 - t
		stronger_ghosts.modulate.a = alpha

		# optional: little float upward
		stronger_ghosts.position.y -= delta * 20.0

		if stronger_label_t >= stronger_label_duration:
			stronger_label_active = false
			stronger_ghosts.visible = false

func enter_next_phase() -> void:
	ghosty_bonus_speed += 25 * ghost_phase
	ghosty_bonus_health += 20 * ghost_phase
	
	ghosty_modulate -= 0.25
	ghosty_modulate = clamp(ghosty_modulate, 0.0, 1.0)
	
	ghosty_spawn_interval = 2.0
	ghost_increase_interval = 2.5
	
	ghost_phase += 1
	show_stronger_ghosts_label()
	
	print("Ghost Phase:", ghost_phase)

func spawn_enemy(pos: Vector2):
	if player.is_dead:
		return
	
	var active_ghosts = get_tree().get_nodes_in_group("ghosty").size()
	
	if active_ghosts > ghosty_limit:
		print("maximum ghost limit reached")
		return
	
	if spawn_muddy:
		var muddy = enemy_scene.instantiate()
		muddy.global_position = pos
		get_parent().add_child(muddy)
	
	if spawn_snail:
		var snail = snail_scene.instantiate()
		snail.global_position = pos
		get_parent().add_child(snail)
	
	if spawn_stoney:
		var stoney = stoney_scene.instantiate()
		stoney.global_position = pos
		get_parent().add_child(stoney)
	
	if spawn_clover_boss:
		var clover_boss = clover_boss_scene.instantiate()
		clover_boss.global_position = pos
		get_parent().add_child(clover_boss)
	
	if spawn_ghosty:
		var arrow_manager = get_tree().get_first_node_in_group("arrow_manager")
		var ghosty = ghosty_scene.instantiate()
		
		get_parent().add_child(ghosty)
		
		ghosty.global_position = pos
		ghosty.speed = ghosty.base_speed + ghosty_bonus_speed
		ghosty.xp_orbs += ghost_phase
		
		ghosty.max_health += ghosty_bonus_health
		ghosty.health += ghosty_bonus_health
		ghosty.hp_bar.max_value = ghosty.max_health
		ghosty.hp_bar.value = ghosty.max_health
		
		ghosty.animated_sprite_2d.self_modulate = Color(1.0, ghosty_modulate, ghosty_modulate)
		
		await get_tree().create_timer(0.1).timeout
		
		if GameState.boss_spawned and !GameState.boss_killed:
			ghosty.max_health = 1
			ghosty.health = 1
		
		if arrow_manager and !GameSettings.dark_mode:
			arrow_manager.create_arrow(ghosty)

func show_stronger_ghosts_label():
	stronger_label_active = true
	stronger_ghosts.position = label_start_pos
	stronger_label_t = 0.0

	stronger_ghosts.visible = true
	stronger_ghosts.modulate = Color(1, 1, 1, 1)
	stronger_ghosts.scale = Vector2(1.8, 1.8)

func _on_spawn_enemy_pressed() -> void:
	for x in range(10):
		spawn_enemy(Vector2(randf_range(400, 1600), randf_range(400, 1600)))

func _on_spawn_enemies_signal(pos) -> void:
	spawn_enemy(pos)

func _on_remove_enemies_pressed() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_in_group("boss"):
			continue
		if "health" in enemy:
			enemy.health = 0.0
			if enemy.has_method("take_damage"):
				enemy.take_damage(0)
			elif enemy.has_method("explode"):
				enemy.explode(enemy) 
			else:
				enemy.queue_free()

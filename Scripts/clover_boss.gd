extends CharacterBody2D

@onready var player := get_tree().get_first_node_in_group("player")

@onready var projectile_scene = preload("res://Scenes/clover_projectile.tscn")
@onready var shoot_timer: Timer = $ShootTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func spawn_projectile(direction):
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = direction
	add_child(projectile)

func _on_shoot_timer_timeout() -> void:
	var new_timer = randf_range(2, 5)
	shoot_timer.wait_time = new_timer
	
	var direction = (player.global_position - global_position).normalized()
	spawn_projectile(direction)

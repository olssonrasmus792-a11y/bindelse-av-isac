extends Node2D

@export var enemy_scene := preload("res://Scenes/Muddy.tscn")
@onready var ui: CanvasLayer = $"../UI"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func spawn_enemy(pos: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	get_parent().add_child(enemy)
	enemy.connect("enemy_died", Callable(ui, "_on_enemy_died"))

func _on_spawn_enemy_pressed() -> void:
	for x in range(10):
		spawn_enemy(Vector2(400, 600))

func _on_spawn_enemies_signal(pos) -> void:
	spawn_enemy(pos)
	print("Spawning enemies")

func _on_remove_enemies_pressed() -> void:
	get_tree().call_group("enemies", "queue_free")

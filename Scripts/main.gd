extends Node2D

@onready var end_stats: Control = $UI/AnimationPlayer/EndStats

func _ready():
	# Absolute must-haves
	get_tree().paused = false
	Engine.time_scale = 1.0

	# Timers safety
	for timer in get_tree().get_nodes_in_group("timers"):
		timer.stop()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	GameState.reset_game()
	end_stats.visible = false

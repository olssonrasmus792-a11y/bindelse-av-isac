extends Node2D

@onready var end_stats: Control = $UI/AnimationPlayer/EndStats
@onready var animation_player: AnimationPlayer = $UI/AnimationPlayer
@onready var button: Button = $UI/AnimationPlayer/EndStats/Button

func _ready():
	# Absolute must-haves
	get_tree().paused = false
	Engine.time_scale = 1.0

	# Timers safety
	for timer in get_tree().get_nodes_in_group("timers"):
		timer.stop()

func _on_button_pressed() -> void:
	if animation_player.is_playing():
		var anim = animation_player.current_animation
		var length = animation_player.get_animation(anim).length
		animation_player.seek(length, true)
	else:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		GameState.add_meta_stats()
		end_stats.visible = false

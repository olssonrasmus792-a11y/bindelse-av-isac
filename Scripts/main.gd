extends Node2D
@onready var end_stats: Control = $UI/AnimationPlayer/EndStats
@onready var animation_player: AnimationPlayer = $UI/AnimationPlayer
@onready var button: Button = $UI/AnimationPlayer/EndStats/Button

func _ready():
	get_tree().paused = false
	Engine.time_scale = 1.0
	for timer in get_tree().get_nodes_in_group("timers"):
		timer.stop()

func _on_button_pressed() -> void:
	if animation_player.is_playing():
		var anim = animation_player.current_animation
		var length = animation_player.get_animation(anim).length
		animation_player.seek(length, true)
		# Skipped before transfer started
		if not end_stats.coins_transferred:
			end_stats.transfer_coins()
			end_stats.finish_coins_instantly()
		# Skipped mid-tween
		elif not end_stats.coins_done:
			end_stats.finish_coins_instantly()
	else:
		GameState.add_meta_stats()
		end_stats.visible = false
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_play_again_pressed() -> void:
	if not end_stats.coins_transferred:
		end_stats.transfer_coins()
		end_stats.finish_coins_instantly()
	elif not end_stats.coins_done:
		end_stats.finish_coins_instantly()
	
	GameState.add_meta_stats()
	end_stats.visible = false
	
	MusicManager.fade_out_music()
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen.tscn")

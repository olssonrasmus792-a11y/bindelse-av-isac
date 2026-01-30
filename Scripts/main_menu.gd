extends Control




func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

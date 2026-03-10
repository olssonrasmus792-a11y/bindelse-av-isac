extends Control

@onready var camera_2d: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	camera_2d.make_current()
	if GameSettings.dark_mode:
		color_rect.color = Color.BLACK
	else:
		color_rect.color = Color(0.376, 0.306, 0.459)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen.tscn")


func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

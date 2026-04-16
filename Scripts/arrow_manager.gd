extends Control

var arrow_scene = preload("res://Scenes/off_screen_arrow.tscn")

func create_arrow(target):
	var arrow = arrow_scene.instantiate()
	arrow.target = target
	add_child(arrow)

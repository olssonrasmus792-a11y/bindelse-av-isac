extends Control
@onready var check_button: CheckButton = $CheckButton
@onready var color_rect: ColorRect = $ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		color_rect.color = Color.WHITE
	else:
		color_rect.color = Color.BLACK

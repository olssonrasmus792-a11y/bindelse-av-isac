extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var screen_shake_label: Label = $VBoxContainer/ScreenShakeStength/ScreenShakeLabel
@onready var menu_button: MenuButton = $ScreenSize/MenuButton
@onready var screen_shake_slider: HSlider = $VBoxContainer/ScreenShakeStength/ScreenShakeSlider
@onready var check_box: CheckBox = $VBoxContainer/DarkMode/CheckBox

func _ready() -> void:
	var popup = menu_button.get_popup()
	popup.id_pressed.connect(_on_resolution_selected)
	screen_shake_slider.value = GameSettings.screen_shake_strength * 100
	check_box.button_pressed = GameSettings.dark_mode

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_screen_shake_slider_value_changed(value: int) -> void:
	screen_shake_label.text = "Screen shake strength: " + str(value) + "%"
	GameSettings.screen_shake_strength = value / 100.0

func _on_check_box_toggled(toggled_on: bool) -> void:
	GameSettings.dark_mode = toggled_on
	if toggled_on:
		color_rect.color = Color.BLACK
	else:
		color_rect.color = Color(0.247, 0.247, 0.247)

func _on_resolution_selected(id: int) -> void:
	match id:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

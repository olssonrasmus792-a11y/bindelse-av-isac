extends Control

@onready var menu_button: MenuButton = $ScreenSize/MenuButton
@onready var color_rect: ColorRect = $ColorRect

@onready var screen_shake_label: Label = $VBoxContainer/ScreenShakeStength/ScreenShakeLabel
@onready var screen_shake_slider: HSlider = $VBoxContainer/ScreenShakeStength/ScreenShakeSlider

@onready var master_label: Label = $VBoxContainer/MasterVolume/MasterLabel
@onready var master_slider: HSlider = $VBoxContainer/MasterVolume/MasterSlider

@onready var music_label: Label = $VBoxContainer/MusicVolume/MusicLabel
@onready var music_slider: HSlider = $VBoxContainer/MusicVolume/MusicSlider

@onready var sfx_label: Label = $VBoxContainer/SFXVolume/SFXLabel
@onready var sfx_slider: HSlider = $VBoxContainer/SFXVolume/SFXSlider
@onready var sfx_test: Button = $SFXTest

@onready var check_box: CheckBox = $VBoxContainer/DarkMode/CheckBox

func _ready() -> void:
	var popup = menu_button.get_popup()
	popup.id_pressed.connect(_on_resolution_selected)
	
	screen_shake_slider.value = GameSettings.screen_shake_strength * 100
	master_slider.value = GameSettings.master_volume
	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume
	
	check_box.button_pressed = GameSettings.dark_mode

func _on_back_button_pressed() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_screen_shake_slider_value_changed(value: int) -> void:
	screen_shake_label.text = "Screen shake strength: " + str(value) + "%"
	GameSettings.screen_shake_strength = value / 100.0

func _on_master_slider_value_changed(value: float) -> void:
	master_label.text = "Master Volume: " + str(int(value)) + "%"
	
	GameSettings.master_volume = value
	
	var bus_index = AudioServer.get_bus_index("Master")
	var linear := value / 100.0
	var db := linear_to_db(linear)
	
	AudioServer.set_bus_volume_db(bus_index, db)

func _on_music_slider_value_changed(value: float) -> void:
	music_label.text = "Music Volume: " + str(int(value)) + "%"
	
	GameSettings.music_volume = value
	
	var bus_index = AudioServer.get_bus_index("Music")
	var linear := value / 100.0
	var db := linear_to_db(linear)
	
	AudioServer.set_bus_volume_db(bus_index, db)

func _on_sfx_slider_value_changed(value: float) -> void:
	sfx_label.text = "Sound Effect Volume: " + str(int(value)) + "%"
	
	GameSettings.sfx_volume = value
	
	var bus_index = AudioServer.get_bus_index("Sfx")
	var linear := value / 100.0
	var db := linear_to_db(linear)
	
	AudioServer.set_bus_volume_db(bus_index, db)

func _on_sfx_test_pressed() -> void:
	play_random_sfx(sfx_test)

func play_random_sfx(parent: Node):
	var audio_nodes = []

	for child in parent.get_children():
		if child is AudioStreamPlayer:
			audio_nodes.append(child)

	if audio_nodes.is_empty():
		return

	var random_audio = audio_nodes[randi() % audio_nodes.size()]
	random_audio.play()

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

func _on_reset_button_pressed() -> void:
	GameState.reset_progress()

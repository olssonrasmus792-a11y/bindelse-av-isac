extends Control

@onready var camera_2d: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect
@onready var kills: Label = $StatsPanel/Kills
@onready var coins: Label = $StatsPanel/Coins
@onready var wins: Label = $StatsPanel/Wins
@export var muddy_scene := preload("res://Scenes/Enemies/Muddy.tscn")

var can_quit := false


func _ready() -> void:
	camera_2d.make_current()
	
	if GameSettings.dark_mode:
		color_rect.color = Color.BLACK
	else:
		color_rect.color = Color(0.376, 0.306, 0.459)
	
	@warning_ignore("integer_division")
	var winrate = (GameState.meta_runs_completed * 100) / GameState.meta_runs_played
	
	wins.tooltip_text = "Winrate: " + str(int(winrate)) + "%"
	kills.tooltip_text = "Total kills: " + str(GameState.meta_kills) + "\n" + "Barrel kills: " + str(GameState.meta_barrel_kills) + "\n" + "Muddy kills: " + str(GameState.meta_muddy_kills) + "\n" + "Roll kills: " + str(GameState.meta_roll_kills) + "\n"
	coins.tooltip_text = "Total Coins Earned: " + str(GameState.calculate_total_coins_earned())
	
	MusicManager.set_music_muffle(0.0)
	MusicManager.set_music_pitch(1.0)
	MusicManager.play_music(MusicManager.SONGS["MENU_MUSIC"], MusicManager.MusicGroup.MENU)
	
	await get_tree().create_timer(0.5).timeout
	can_quit = true

func _on_start_button_pressed() -> void:
	clear_all_muddies()
	get_tree().change_scene_to_file("res://Scenes/weapon_select.tscn")

func _on_shop_button_pressed() -> void:
	clear_all_muddies()
	get_tree().change_scene_to_file("res://Scenes/meta_shop.tscn")

func _on_options_button_pressed() -> void:
	clear_all_muddies()
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

func _on_quit_button_pressed() -> void:
	if not can_quit:
		return

	clear_all_muddies()
	GameState.save_game()

	await get_tree().process_frame
	get_tree().quit()

func _on_muddy_button_pressed() -> void:
	var muddy = muddy_scene.instantiate()
	var screen_size = get_viewport_rect().size
	muddy.global_position = Vector2(
		randf_range(0, screen_size.x),
		randf_range(0, screen_size.y)
	)

	get_parent().add_child(muddy)
	muddy.add_to_group("main_menu_muddy")

func clear_all_muddies():
	for muddy in get_tree().get_nodes_in_group("main_menu_muddy"):
		muddy.queue_free()

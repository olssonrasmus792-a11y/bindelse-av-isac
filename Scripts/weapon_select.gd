extends Control
@onready var player := get_tree().get_first_node_in_group("player")
@onready var camera_2d: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect

@onready var lightning_sword: Panel = $LightningSword
@onready var lightning_sword_level: Panel = $LightningSwordLevel
@onready var sword_progress: ProgressBar = $SwordProgress
@onready var sword_level: Button = $SwordLevel
@onready var lightning_sword_lock: Panel = $LightningSwordLock

@onready var baseball_bat: Panel = $BaseballBat
@onready var baseball_bat_level: Panel = $BaseballBatLevel
@onready var bat_progress: ProgressBar = $BatProgress
@onready var bat_level: Button = $BatLevel

var rarity_color: Color = Color.WHITE
var shimmer_time := 0.0
var rarity_intensity := 0.5

func _ready() -> void:
	camera_2d.make_current()
	
	if GameSettings.dark_mode:
		color_rect.color = Color.BLACK
	else:
		color_rect.color = Color(0.376, 0.306, 0.459)
	
	if lightning_sword.material:
		lightning_sword.material = lightning_sword.material.duplicate()
	if baseball_bat.material:
		baseball_bat.material = baseball_bat.material.duplicate()
	
	if GameState.baseball_bat_level >= 5:
		lightning_sword_lock.visible = false
	
	bat_progress.max_value = GameState.baseball_bat_xp_needed
	bat_progress.value = GameState.baseball_bat_xp
	
	sword_progress.max_value = GameState.lightning_sword_xp_needed
	sword_progress.value = GameState.lightning_sword_xp
	
	sword_level.text = "Level " + str(GameState.lightning_sword_level) + "  :  " + str(GameState.lightning_sword_xp) + "/" + str(GameState.lightning_sword_xp_needed) + "xp"
	bat_level.text = "Level " + str(GameState.baseball_bat_level) + "  :  " + str(GameState.baseball_bat_xp) + "/" + str(GameState.baseball_bat_xp_needed) + "xp"

func _process(delta):
	shimmer_time += delta * 1.4
	
	update_shine()

func update_shine():
	var sword_mat := lightning_sword.material as ShaderMaterial
	if sword_mat:
		sword_mat.set_shader_parameter("shine_color", Color.WHITE)
		sword_mat.set_shader_parameter("intensity", rarity_intensity)
		sword_mat.set_shader_parameter("sweep_pos", fmod(shimmer_time, 3.0) - 0.5)

	var bat_mat := baseball_bat.material as ShaderMaterial
	if bat_mat:
		bat_mat.set_shader_parameter("shine_color", Color.WHITE)
		bat_mat.set_shader_parameter("intensity", rarity_intensity)
		bat_mat.set_shader_parameter("sweep_pos", fmod(shimmer_time, 3.0) - 0.5)

func _on_bat_level_pressed() -> void:
	baseball_bat.visible = !baseball_bat.visible
	baseball_bat_level.visible = !baseball_bat_level.visible
	
	if baseball_bat.visible:
		bat_level.text = "Weapon level " + str(GameState.baseball_bat_level) + "  :  " + str(GameState.baseball_bat_xp) + "/" + str(GameState.baseball_bat_xp_needed) + "xp"
	else:
		bat_level.text = "return"

func _on_sword_level_pressed() -> void:
	lightning_sword.visible = !lightning_sword.visible
	lightning_sword_level.visible = !lightning_sword_level.visible
	
	if lightning_sword.visible:
		sword_level.text = "Weapon level " + str(GameState.lightning_sword_level) + "  :  " + str(GameState.lightning_sword_xp) + "/" + str(GameState.lightning_sword_xp_needed) + "xp"
	else:
		sword_level.text = "return"

func _on_sword_button_pressed() -> void:
	GameState.weapon = "Lightning Sword"
	start_game()

func _on_bat_button_pressed() -> void:
	GameState.weapon = "Baseball Bat"
	start_game()

func start_game():
	MusicManager.fade_out_music(4.0)
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

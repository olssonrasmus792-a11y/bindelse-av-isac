extends Control

@export var data: WeaponData

@onready var front: Panel = $Front
@onready var back: Panel = $Back
@onready var weapon_name: Label = $Front/Name
@onready var back_name: Label = $Back/Name
@onready var v_box_container: VBoxContainer = $Front/VBoxContainer
@onready var damage: Label = $Front/VBoxContainer/Damage
@onready var knockback: Label = $Front/VBoxContainer/Knockback
@onready var crit_chance: Label = $Front/VBoxContainer/CritChance
@onready var crit_damage: Label = $Front/VBoxContainer/CritDamage
@onready var attack_speed: Label = $Front/VBoxContainer/AttackSpeed
@onready var range_type: Label = $Front/Range
@onready var ability: Label = $Front/Ability
@onready var take_button: Button = $Front/TakeButton
@onready var panel: Panel = $Front/Panel
@onready var texture_rect: TextureRect = $Front/Panel/TextureRect
@onready var back_texture_rect: TextureRect = $Back/Panel/TextureRect
@onready var progress: ProgressBar = $Progress
@onready var progress_button: Button = $ProgressButton
@onready var lock: Panel = $Lock
@onready var requirement: Label = $Lock/Requirement
@onready var runs: Label = $Back/VBoxContainer/Runs
@onready var wins: Label = $Back/VBoxContainer/Wins
@onready var kills: Label = $Back/VBoxContainer/Kills
@onready var damage_dealt: Label = $Back/VBoxContainer/DamageDealt
@onready var notif: Panel = $Notification

var rarity_color: Color = Color.WHITE
var shimmer_time := 0.0
var rarity_intensity := 0.5

func _ready():
	update_card()

func update_card():
	if data == null:
		return
	
	weapon_name.text = data.name
	damage.text = "Damage : " + str(data.damage)
	knockback.text = "Knockback : " + str(data.knockback)
	crit_chance.text = "Crit Chance : " + str(int(data.crit_chance * 100)) + "%"
	crit_damage.text = "Crit Damage : " + str(int(data.crit_damage * 100)) + "%"
	if data.attack_speed == 0.0:
		attack_speed.text = "Attack Speed : - / sec"
	else:
		attack_speed.text = "Attack Speed : " + str(snappedf(1 / data.attack_speed, 0.1)) + " / sec"
	range_type.text = data.range_type
	ability.text = "Ability : " + data.ability
	ability.tooltip_text = data.ability_tooltip
	texture_rect.texture = data.icon
	texture_rect.tooltip_text = data.weapon_description
	progress.value = GameState.weapon_progress[data.id]["xp"]
	progress.max_value = GameState.weapon_progress[data.id]["xp_needed"]
	progress_button.text = "Level " + str(int(GameState.weapon_progress[data.id]["level"])) + "  :  " + str(int(GameState.weapon_progress[data.id]["xp"])) + "/" + str(int(GameState.weapon_progress[data.id]["xp_needed"])) + "xp"
	
	back.self_modulate = data.card_color
	front.self_modulate = data.card_color
	weapon_name.self_modulate = data.card_color
	ability.self_modulate = data.card_color
	range_type.self_modulate = data.card_color
	
	back_name.text = data.name
	back_texture_rect.texture = data.icon
	runs.text = "Runs played: " + str(int(GameState.weapon_progress[data.id]["runs_played"]))
	wins.text = "Runs completed: " + str(int(GameState.weapon_progress[data.id]["runs_completed"]))
	kills.text = "Kills: " + str(int(GameState.weapon_progress[data.id]["kills"]))
	damage_dealt.text = "Damage dealt: " + str(int(GameState.weapon_progress[data.id]["damage"]))
	
	GameState.check_weapon_unlock(data)
	
	requirement.text = "Weapon Requirement:\n" + str(data.unlock_amount) + "/" + str(data.unlock_amount_needed) + " " + data.unlock_condition
	
	if GameState.unlocked_weapons[data.id]:
		if GameState.weapon_progress[data.id]["runs_played"] <= 0:
			notif.visible = true
		lock.hide()
	else:
		lock.show()

func _process(delta):
	shimmer_time += delta * 1.4
	
	update_shine()

func update_shine():
	var mat := front.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("shine_color", Color.WHITE)
		mat.set_shader_parameter("intensity", rarity_intensity)
		mat.set_shader_parameter("sweep_pos", fmod(shimmer_time, 3.0) - 0.5)

func _on_progress_button_pressed() -> void:
	front.visible = !front.visible
	back.visible = !back.visible

func _on_take_button_pressed() -> void:
	GameState.weapon = data.id
	GameState.start_damage = data.damage
	GameState.start_knockback = data.knockback
	GameState.start_crit_chance = data.crit_chance
	GameState.start_crit_damage = data.crit_damage
	GameState.start_attack_speed = data.attack_speed
	start_game()

func start_game():
	MusicManager.fade_out_music(4.0)
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen.tscn")

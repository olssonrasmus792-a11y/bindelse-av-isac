extends CanvasLayer

@onready var label: Label = $Label
@onready var keys: Label = $KeyPanel/HBoxContainer/Keys
@onready var coins: Label = $CoinPanel/HBoxContainer/Coins
@onready var timer: Label = $Timer
@onready var xp_bar: TextureProgressBar = $XpBar
@onready var player: CharacterBody2D = $"../Player"
@onready var level: Label = $XpBar/Level
@onready var boss_hp_bar_outline: ColorRect = $BossHpBarOutline
@onready var boss_hp_bar: TextureProgressBar = $BossHpBarOutline/BossHpBar

@onready var ability_panel: Panel = $AbilityPanel
@onready var ability_sprite: TextureRect = $AbilityPanel/TextureRect
@onready var ability_name: Label = $AbilityPanel/Ability
@onready var ability_cooldown: Label = $AbilityPanel/Cooldown

@onready var vignette: TextureRect = $DamageVignette
@export var flash_duration: float = 0.35

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.time_left = GameState.start_time + GameState.meta_bonus_time
	vignette.modulate.a = 0
	
	if GameState.weapon == "baseball_bat":
		ability_sprite.texture = preload("res://Textures/Bat_icon.png")
		ability_name.text = "Bonk (Q)"
	
	if GameState.weapon == "lightning_sword":
		ability_sprite.texture = preload("res://Textures/Sword_icon.tres")
		ability_name.text = "Throw (Q)"
	
	if GameState.weapon == "clover":
		ability_sprite.texture = preload("res://Textures/Enemies/clove throw.png")
		ability_name.text = "Nothin (Q)"
	
	if GameState.weapon == "knife":
		ability_sprite.texture = preload("res://Textures/knife_icon.png")
		ability_name.text = "Nothin (Q)"
	
	if GameState.weapon == "nothing":
		ability_sprite.texture = preload("res://Textures/heart.png")
		ability_name.text = "Nothin (Q)"
	
	if GameState.weapon == "muddy":
		ability_sprite.texture = preload("res://Textures/muddy_icon.png")
		ability_name.text = "Nothin (Q)"
	
	if GameState.weapon == "barrel":
		ability_sprite.texture = preload("res://Textures/Barrel.png")
		ability_name.text = "Nothin (Q)"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	keys.text = "Keys: " + str(GameState.keys)
	coins.text = "Coins: " + str(GameState.coins)
	label.text = "Kills: " + str(GameState.kills)
	
	handle_boss_timer(delta)
	
	xp_bar.value = player.xp
	xp_bar.max_value = player.xp_to_next_level
	level.text = "LVL " + str(player.level)
	
	if player.ability_name == "":
		ability_cooldown.text = "No ability!"
	elif player.ability_timer > 0:
		ability_cooldown.text = "%.1f" % player.ability_timer + " Seconds"
		ability_panel.modulate = Color.from_hsv(0.0, remap(player.ability_timer, player.ability_cooldown, 0.0, 1.0, 0.3), 1.0, 1.0)
	else:
		ability_panel.modulate = Color.from_hsv(0.0, 0.0, 1.0, 1.0)
		ability_cooldown.text = "Ready!"

func handle_boss_timer(delta: float):
	if GameState.time_left <= 0:
		if GameState.boss_killed:
			timer.modulate = Color.GREEN
			timer.text = "yippie!"
			timer.visible = true
			boss_hp_bar_outline.visible = false
		elif GameState.boss_spawned:
			timer.modulate = Color.RED
			timer.text = "Kill the boss!"
			timer.visible = false
			boss_hp_bar_outline.visible = true
		else:
			timer.modulate = Color.RED
			timer.text = "Find the Boss!"
			timer.visible = true
			boss_hp_bar_outline.visible = false
		return
	
	if GameState.pause_timer or !GameState.timer_started:
		timer.modulate = Color.YELLOW
		timer.text = format_time(GameState.time_left)
		return
	
	timer.modulate = Color.WHITE
	GameState.time_left -= delta
	timer.text = format_time(GameState.time_left)

func format_time(seconds: float) -> String:
	var total := int(seconds)
	var m := int(floor(total / 60.0))
	var s := total % 60
	return "%02d:%02d" % [m, s]

func flash_vignette():
	# Immediately show vignette
	vignette.visible = true
	vignette.modulate.a = 1
	
	# Tween alpha back to 0
	var tween = create_tween()
	tween.tween_property(vignette, "modulate:a", 0.0, flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	vignette.visible = false

extends Control
@onready var player := get_tree().get_first_node_in_group("player")
@onready var animation_player: AnimationPlayer = $".."
@onready var rooms: Label = $Rooms
@onready var kills: Label = $Kills
@onready var damage: Label = $Damage
@onready var level: Label = $Level
@onready var xp: Label = $Xp
@onready var boss: Label = $Bulby/Boss
@onready var button: Button = $Button
@onready var coins: Label = $Coins
@onready var coin_sfx: AudioStreamPlayer = $Coin

var coins_transferred = false
var coins_done = false
var active_coin_tween: Tween = null

func _process(_delta: float) -> void:
	if animation_player.is_playing():
		button.text = "Skip"
		var anim_time = animation_player.current_animation_position
		if anim_time >= 4.75 and not coins_transferred and animation_player.current_animation == "stats":
			transfer_coins()
	else:
		button.text = "Main Menu"

func transfer_coins():
	coins_transferred = true
	var total = GameState.total_coins_gained
	var start = GameState.meta_coins
	
	active_coin_tween = create_tween()
	for i in range(total):
		var target_value = start + i + 1
		active_coin_tween.tween_callback(func():
			coins.text = "Coins: " + str(target_value)
			play_pickup_sound()
		).set_delay(0.5 / total)
	
	active_coin_tween.tween_callback(func():
		GameState.meta_coins += total
		coins_done = true
	)

func finish_coins_instantly():
	if active_coin_tween:
		active_coin_tween.kill()
	GameState.meta_coins += GameState.total_coins_gained
	coins.text = "Coins: " + str(GameState.meta_coins)
	coins_done = true

func update_values():
	coins_transferred = false
	coins_done = false
	rooms.text = "Rooms Cleared: " + str(GameState.rooms_cleared)
	GameState.leaderboard_kills = GameState.kills
	kills.text = "Kills: " + str(GameState.kills)
	damage.text = "Damage Dealt: " + str(GameState.total_damage_dealt)
	level.text = "Level Reached: " + str(player.level)
	xp.text = "Xp Gained: " + str(GameState.total_xp_gained)
	coins.text = "Coins: " + str(GameState.meta_coins)
	if GameState.boss_killed:
		boss.add_theme_color_override("font_shadow_color", Color.LIME_GREEN)
		boss.text = "The boss is finally dead!"
	else:
		boss.add_theme_color_override("font_shadow_color", Color.RED)
		boss.text = "The boss is still alive..."

func play_pickup_sound():
	var sound = coin_sfx
	coin_sfx.pitch_scale = randf_range(1.1, 1.4)
	sound.get_parent().remove_child(sound)
	get_tree().current_scene.add_child(sound)
	sound.play(0.04)

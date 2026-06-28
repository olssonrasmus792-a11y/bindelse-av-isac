extends Node

@export var room_tiles_x = 17
@export var room_tiles_y = 11

var player_name

var meta_runs_played := 0
var meta_runs_completed := 0
var meta_rooms_cleared := 0

var meta_kills := 0
var meta_roll_kills := 0
var meta_muddy_kills := 0
var meta_barrel_kills := 0

var meta_damage := 0
var meta_coins := 0
var meta_xp := 0
var meta_xp_needed := 100
var meta_level := 1

var meta_bonus_xp_gain := 0.00
var meta_bonus_damage := 0.00
var meta_bonus_time := 0

var unlocked_weapons = {
	"baseball_bat": true,
	"lightning_sword": false,
	"clover": false,
	"knife": false,
	"nothing": false,
	"muddy": false,
	"barrel": false
}

var start_damage = 0
var start_knockback = 0
var start_crit_chance = 0.0
var start_crit_damage = 0.0
var start_attack_speed = 0.0

var weapon_progress = {
	"lightning_sword": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
	"baseball_bat": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
	"clover": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
	"knife": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
	"nothing": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
	"muddy": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
	"barrel": {
		"level": 1,
		"xp": 0,
		"xp_needed": 200,
		"runs_played": 0,
		"runs_completed": 0,
		"kills": 0,
		"damage": 0
	},
}

var leaderboard_kills := 0

var weapon = ""
var current_weapon_sort := 0

var keys := 0
var coins := 0

var kills := 0
var roll_kills := 0
var muddy_kills := 0
var barrel_kills := 0

var combo := 0

var rooms_cleared := 0
var rooms_explored := 0
var total_rooms := 0

var total_coins_gained := 0
var total_damage_dealt := 0
var total_xp_gained := 0

var enemy_start_count = 4
var muddy_base_spawn_rate = 8
var muddy_spawn_rate = muddy_base_spawn_rate
var snail_spawn_rate = 24
var stoney_spawn_rate = 16
var waterguy_spawn_rate = 18

var coin_drop_chance = 0.1

var luck = 0.0

var start_time = 360.0
var time_left = start_time
var timer_started = false
var pause_timer = false

var current_room
var is_fighting = false
var boss_spawned = false
var boss_killed = false

var taken_upgrades: Array[CardData] = []
var taken_items: Array[ItemData] = []

var dungeon_map = {}
var explored_rooms = []
var treasure_room_pos = Vector2.ZERO
var start_room_pos = Vector2.ZERO
var shop_positions = []
var workshop_positions = []
signal room_explored(pos)

func _ready() -> void:
	load_game()
	
	SilentWolf.configure({
	"api_key": "77szUE1zCV9jk7ZDlzKyV51lEkDVEVTP2Wo7o2gI",
	"game_id": "thelastlight1",
	"log_level": 1
	})
	
	SilentWolf.configure_scores({
	"open_scene_on_close": "res://scenes/MainPage.tscn"
	})

func reset_game():
	keys = 0
	coins = 0
	
	kills = 0
	roll_kills = 0
	muddy_kills = 0
	barrel_kills = 0
	
	total_damage_dealt = 0
	total_xp_gained = 0
	total_coins_gained = 0
	rooms_cleared = 0
	rooms_explored = 0
	total_rooms = 0
	coin_drop_chance = 0.1
	luck = 0.0
	muddy_spawn_rate = muddy_base_spawn_rate
	
	timer_started = false
	boss_killed = false
	boss_spawned = false
	
	for item in taken_items:
		item.reset_stats()
	
	taken_upgrades.clear()
	taken_items.clear()
	
	combo = 0

func get_item_count(item_name: String) -> int:
	var count = 0
	for item in taken_items:
		if item.name == item_name:
			count += 1
	return count

func get_upgrade_count(upgrade_name: String) -> int:
	var count = 0
	for upgrade in taken_upgrades:
		if upgrade.card_name == upgrade_name:
			count += 1
	return count

func get_enemy_amount():
	var amount = enemy_start_count
	
	amount += rooms_cleared * 2
	
	for item in GameState.taken_items:
		if item.name == "Sword":
			item.tracked_stat_values[1] += (roundi(amount * 0.2 * get_item_count("Sword")))
			break
	
	amount += amount * 0.2 * get_item_count("Sword")
	amount = roundi(amount)
	
	return amount

func explore_room(pos):
	if not explored_rooms.has(pos):
		explored_rooms.append(pos)
		room_explored.emit(pos)

func calculate_stats():
	coin_drop_chance = 0.1 * (1 + luck)
	
	for item in taken_items:
		if item.name == "Greedy ahh":
			@warning_ignore("integer_division")
			var coin_groups = floor(GameState.coins / 5)
			var value : int = 0.05 * GameState.get_item_count("Greedy ahh") * coin_groups * 100
			item.tracked_stat_values[0] = value
			break

func calculate_total_coins_earned() -> int:
	var total := 0

	# XP upgrades
	var xp_upgrades = int(meta_bonus_xp_gain * 100)
	for i in range(xp_upgrades):
		total += (i * 1) + 5


	# Damage upgrades
	var damage_upgrades = int(meta_bonus_damage * 100)
	for i in range(damage_upgrades):
		total += (i * 1) + 5


	# Time upgrades
	var time_upgrades = int(meta_bonus_time)
	for i in range(time_upgrades):
		total += i + 5


	return total + meta_coins

func add_meta_stats():
	meta_runs_played += 1
	weapon_progress[weapon]["runs_played"] += 1
	
	if boss_killed:
		meta_runs_completed += 1
		weapon_progress[weapon]["runs_completed"] += 1
	
	meta_rooms_cleared += rooms_cleared
	
	meta_kills += kills
	meta_roll_kills += roll_kills
	meta_muddy_kills += muddy_kills
	meta_barrel_kills += barrel_kills
	
	meta_damage += total_damage_dealt
	meta_xp += total_xp_gained
	
	weapon_progress[weapon]["xp"] += total_xp_gained
	weapon_progress[weapon]["kills"] += kills
	weapon_progress[weapon]["damage"] += total_damage_dealt
	
	while meta_xp >= meta_xp_needed:
		meta_xp -= meta_xp_needed
		meta_xp_needed = int(meta_xp_needed * 1.25)
		meta_level += 1
	
	while weapon_progress[weapon]["xp"] >= weapon_progress[weapon]["xp_needed"]:
		weapon_progress[weapon]["xp"] -= weapon_progress[weapon]["xp_needed"]
		weapon_progress[weapon]["xp_needed"] = int(weapon_progress[weapon]["xp_needed"] * 1.2)
		weapon_progress[weapon]["level"] += 1
	
	if player_name != "":
		var result = await SilentWolf.Scores.get_scores().sw_get_scores_complete
		
		if result.success:
			var best_score := 0
			
			for entry in result.scores:
				if entry.player_name == player_name:
					best_score = max(best_score, int(entry.score))
			
			if leaderboard_kills > best_score:
				await SilentWolf.Scores.save_score(player_name, leaderboard_kills).sw_save_score_complete
	
	save_game()

@warning_ignore("shadowed_variable")
func check_weapon_unlock(weapon: WeaponData):
	match weapon.unlock_condition:
		"kills":
			if meta_kills >= weapon.unlock_amount_needed:
				unlocked_weapons[weapon.id] = true
			else:
				weapon.unlock_amount = meta_kills
		
		"roll kills":
			if meta_roll_kills >= weapon.unlock_amount_needed:
				unlocked_weapons[weapon.id] = true
			else:
				weapon.unlock_amount = meta_roll_kills
		
		"barrel kills":
			if meta_barrel_kills >= weapon.unlock_amount_needed:
				unlocked_weapons[weapon.id] = true
			else:
				weapon.unlock_amount = meta_barrel_kills
		
		"muddy executes":
			if meta_muddy_kills >= weapon.unlock_amount_needed:
				unlocked_weapons[weapon.id] = true
			else:
				weapon.unlock_amount = meta_muddy_kills
		
		"runs completed":
			if meta_runs_completed >= weapon.unlock_amount_needed:
				unlocked_weapons[weapon.id] = true
			else:
				weapon.unlock_amount = meta_runs_completed
		
		"coins":
			if meta_coins >= weapon.unlock_amount_needed:
				unlocked_weapons[weapon.id] = true
			else:
				weapon.unlock_amount = meta_coins

func set_master_volume():
	var bus_index = AudioServer.get_bus_index("Master")
	
	var linear = GameSettings.master_volume / 100.0
	var db = linear_to_db(linear)
	
	AudioServer.set_bus_volume_db(bus_index, db)

func set_music_volume():
	var bus_index = AudioServer.get_bus_index("Music")
	
	var linear = GameSettings.music_volume / 100.0
	var db = linear_to_db(linear)
	
	AudioServer.set_bus_volume_db(bus_index, db)

func set_sfx_volume():
	var bus_index = AudioServer.get_bus_index("Sfx")
	
	var linear = GameSettings.sfx_volume / 100.0
	var db = linear_to_db(linear)
	
	AudioServer.set_bus_volume_db(bus_index, db)

func set_default_meta():
	player_name = ""
	
	GameSettings.master_volume = 25
	GameSettings.music_volume = 25
	GameSettings.sfx_volume = 25
	set_music_volume()
	GameSettings.screen_shake_strength = 1.0
	GameSettings.dark_mode = false
	
	meta_runs_played = 0
	meta_runs_completed = 0
	meta_rooms_cleared = 0
	
	meta_kills = 0
	meta_roll_kills = 0
	meta_muddy_kills = 0
	meta_barrel_kills = 0
	
	meta_damage = 0
	
	meta_coins = 0
	meta_xp = 0
	meta_xp_needed = 100
	meta_level = 1
	
	meta_bonus_xp_gain = 0.00
	meta_bonus_damage = 0.00
	meta_bonus_time = 0
	
	unlocked_weapons = {
		"baseball_bat": true,
		"lightning_sword": false,
		"clover": false,
		"knife": false,
		"nothing": false,
		"muddy": false,
		"barrel": false,
	}
	
	weapon_progress = {
		"lightning_sword": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"baseball_bat": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"clover": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"knife": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"nothing": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"muddy": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"barrel": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
	}
	current_weapon_sort = 0

func setup_weapon_progress():
	var default_weapons = {
		"lightning_sword": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"baseball_bat": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"clover": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"knife": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"nothing": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"muddy": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
		"barrel": {
			"level": 1,
			"xp": 0,
			"xp_needed": 200,
			"runs_played": 0,
			"runs_completed": 0,
			"kills": 0,
			"damage": 0
		},
	}
	
	@warning_ignore("shadowed_variable")
	for weapon in default_weapons:
		if not weapon_progress.has(weapon):
			weapon_progress[weapon] = default_weapons[weapon]

func save_game():
	var save_data = {
		"player_name": player_name,
		
		"master_volume": GameSettings.master_volume,
		"music_volume": GameSettings.music_volume,
		"sfx_volume": GameSettings.sfx_volume,
		"screen_shake": GameSettings.screen_shake_strength,
		"dark_mode": GameSettings.dark_mode,
		
		"meta_runs_played": meta_runs_played,
		"meta_runs_completed": meta_runs_completed,
		"meta_rooms_cleared": meta_rooms_cleared,
		"meta_kills": meta_kills,
		"meta_roll_kills": meta_roll_kills,
		"meta_muddy_kills": meta_muddy_kills,
		"meta_barrel_kills": meta_barrel_kills,
		"meta_damage": meta_damage,
		
		"meta_coins": meta_coins,
		"meta_xp": meta_xp,
		"meta_xp_needed": meta_xp_needed,
		"meta_level": meta_level,
		
		"meta_bonus_xp_gain": meta_bonus_xp_gain,
		"meta_bonus_damage": meta_bonus_damage,
		"meta_bonus_time": meta_bonus_time,
		
		"weapon_progress": weapon_progress,
		"current_weapon_sort": current_weapon_sort
	}
	
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))

func load_game():
	if not FileAccess.file_exists("user://save.json"):
		set_default_meta()
		return
	
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	if data == null:
		set_default_meta()
		return
	
	player_name = data.get("player_name", "")
	
	GameSettings.master_volume = data.get("master_volume", 25)
	GameSettings.music_volume = data.get("music_volume", 25)
	GameSettings.sfx_volume = data.get("sfx_volume", 25)
	GameSettings.screen_shake_strength = data.get("screen_shake", 1.0)
	GameSettings.dark_mode = data.get("dark_mode", false)
	
	set_master_volume()
	set_music_volume()
	set_sfx_volume()
	
	meta_runs_played = data.get("meta_runs_played", 0)
	meta_runs_completed = data.get("meta_runs_completed", 0)
	meta_rooms_cleared = data.get("meta_rooms_cleared", 0)
	meta_kills = data.get("meta_kills", 0)
	meta_roll_kills = data.get("meta_roll_kills", 0)
	meta_muddy_kills = data.get("meta_muddy_kills", 0)
	meta_barrel_kills = data.get("meta_barrel_kills", 0)
	meta_damage = data.get("meta_damage", 0)
	
	meta_coins = data.get("meta_coins", 0)
	meta_xp = data.get("meta_xp", 0)
	meta_xp_needed = data.get("meta_xp_needed", 100)
	meta_level = data.get("meta_level", 1)
	
	meta_bonus_xp_gain = data.get("meta_bonus_xp_gain", 0.00)
	meta_bonus_damage = data.get("meta_bonus_damage", 0.00)
	meta_bonus_time = data.get("meta_bonus_time", 0)
	
	weapon_progress = data.get("weapon_progress", {})
	current_weapon_sort = data.get("current_weapon_sort", 0)
	setup_weapon_progress()

func reset_progress():
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	
	set_default_meta()
	save_game()

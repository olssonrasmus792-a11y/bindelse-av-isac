extends Node

@export var room_tiles_x = 17
@export var room_tiles_y = 11

var meta_runs_played := 0
var meta_runs_completed := 0
var meta_rooms_cleared := 0
var meta_kills := 0
var meta_damage := 0
var meta_coins := 0
var meta_xp := 0
var meta_xp_needed := 100
var meta_level := 1

var keys := 0
var coins := 0
var kills := 0
var combo := 0
var rooms_cleared := 0

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
var pause_timer = false

var current_room
var is_fighting = false
var boss_spawned = false
var boss_killed = false

var taken_upgrades := {}
var taken_items: Array[ItemData] = []

func _ready() -> void:
	load_game()

func reset_game():
	keys = 0
	coins = 0
	kills = 0
	total_damage_dealt = 0
	total_xp_gained = 0
	total_coins_gained = 0
	rooms_cleared = 0
	combo = 0
	coin_drop_chance = 0.1
	luck = 0.0
	muddy_spawn_rate = muddy_base_spawn_rate
	boss_killed = false
	boss_spawned = false
	taken_upgrades.clear()
	taken_items.clear()

func get_item_count(item_name: String) -> int:
	var count = 0
	for item in taken_items:
		if item.name == item_name:
			count += 1
	return count

func get_enemy_amount():
	var amount = enemy_start_count
	
	amount += rooms_cleared * 2
	
	for item in GameState.taken_items:
		if item.name == "Sword":
			item.tracked_stat_values[1] += (roundi(amount * 0.2 * get_item_count("Sword")))
	
	amount += amount * 0.2 * get_item_count("Sword")
	amount = roundi(amount)
	
	return amount

func calculate_stats():
	coin_drop_chance = 0.1 * (1 + luck)
	
	for item in taken_items:
		if item.name == "Greedy ahh":
			@warning_ignore("integer_division")
			var coin_groups = floor(GameState.coins / 5)
			var value : int = 0.05 * GameState.get_item_count("Greedy ahh") * coin_groups * 100
			item.tracked_stat_values[0] = value
			break

func add_meta_stats():
	meta_runs_played += 1
	if boss_killed:
		meta_runs_completed += 1
	meta_rooms_cleared += rooms_cleared
	meta_kills += kills
	meta_damage += total_damage_dealt
	meta_coins += total_coins_gained
	meta_xp += total_xp_gained
	
	while meta_xp >= meta_xp_needed:
		meta_xp -= meta_xp_needed
		meta_xp_needed = int(meta_xp_needed * 1.25)
		meta_level += 1
	
	save_game()

func set_default_meta():
	meta_runs_played = 0
	meta_runs_completed = 0
	meta_rooms_cleared = 0
	meta_kills = 0
	meta_damage = 0
	
	meta_coins = 0
	meta_xp = 0
	meta_xp_needed = 100
	meta_level = 1

func save_game():
	var save_data = {
		"meta_runs_played": meta_runs_played,
		"meta_runs_completed": meta_runs_completed,
		"meta_rooms_cleared": meta_rooms_cleared,
		"meta_kills": meta_kills,
		"meta_damage": meta_damage,
		
		"meta_coins": meta_coins,
		"meta_xp": meta_xp,
		"meta_xp_needed": meta_xp_needed,
		"meta_level": meta_level
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
	
	meta_runs_played = data.get("meta_runs_played", 0)
	meta_runs_completed = data.get("meta_runs_completed", 0)
	meta_rooms_cleared = data.get("meta_rooms_cleared", 0)
	meta_kills = data.get("meta_kills", 0)
	meta_damage = data.get("meta_damage", 0)
	
	meta_coins = data.get("meta_coins", 0)
	meta_xp = data.get("meta_xp", 0)
	meta_xp_needed = data.get("meta_xp_needed", 100)
	meta_level = data.get("meta_level", 1)

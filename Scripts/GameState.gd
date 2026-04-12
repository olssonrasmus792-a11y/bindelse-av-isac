extends Node

@export var room_tiles_x = 17
@export var room_tiles_y = 11

var keys := 0
var coins := 0
var kills := 0
var combo := 0
var rooms_cleared := 0

var enemy_start_count = 3
var muddy_base_spawn_rate = 10
var muddy_spawn_rate = muddy_base_spawn_rate
var snail_spawn_rate = 20
var stoney_spawn_rate = 20

var coin_drop_chance = 0.1

var start_time = 300.0
var time_left = start_time
var pause_timer = false

var boss_spawned = false
var boss_killed = false

var taken_upgrades := {}
var taken_items: Array[ItemData] = []

func reset_game():
	keys = 0
	coins = 0
	kills = 0
	rooms_cleared = 0
	enemy_start_count = 3
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
			item.tracked_stat_values[1] += (roundi(amount * 0.25 * get_item_count("Sword")))
	
	amount += amount * 0.25 * get_item_count("Sword")
	amount = roundi(amount)
	
	return amount

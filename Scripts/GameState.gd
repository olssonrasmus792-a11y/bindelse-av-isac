extends Node

@export var room_tiles_x = 17
@export var room_tiles_y = 11

var keys := 0
var coins := 0
var kills := 0
var rooms_cleared := 0
var enemies_per_room = 10

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
	enemies_per_room = 10
	boss_killed = false
	boss_spawned = false
	taken_upgrades.clear()
	taken_items.clear()

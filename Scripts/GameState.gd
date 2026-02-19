extends Node

@export var room_tiles_x = 17
@export var room_tiles_y = 11

var keys := 0
var coins := 0
var kills := 0
var rooms_cleared := 0
var enemies_per_room = 10

var taken_upgrades := {}

func reset_game():
	keys = 0
	coins = 0
	kills = 0
	rooms_cleared = 0
	enemies_per_room = 10

extends Control

@onready var player := get_tree().get_first_node_in_group("player")

@onready var rooms: Label = $Rooms
@onready var kills: Label = $Kills
@onready var damage: Label = $Damage
@onready var level: Label = $Level
@onready var xp: Label = $Xp

func update_values():
	rooms.text = "Rooms Cleared: " + str(GameState.rooms_cleared)
	kills.text = "Kills: " + str(GameState.kills)
	damage.text = "Damage Dealt: " + str(GameState.total_damage_dealt)
	level.text = "Level Reached: " + str(player.level)
	xp.text = "Xp Gained: " + str(GameState.total_xp_gained)

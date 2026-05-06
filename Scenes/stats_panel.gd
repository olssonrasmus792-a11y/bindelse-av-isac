extends Panel

@onready var runs: Label = $Runs
@onready var wins: Label = $Wins
@onready var rooms: Label = $Rooms
@onready var kills: Label = $Kills
@onready var damage: Label = $Damage
@onready var coins: Label = $Coins

func _process(_delta: float) -> void:
	runs.text = "Runs Played: " + str(GameState.meta_runs_played)
	wins.text = "Runs Completed: " + str(GameState.meta_runs_completed)
	rooms.text = "Rooms Cleared: " + str(GameState.meta_rooms_cleared)
	kills.text = "Kills: " + str(GameState.meta_kills)
	damage.text = "Damage Dealt: " + str(GameState.meta_damage)
	coins.text = "Coins Collected: " + str(GameState.meta_coins)

extends Panel

@onready var level: Label = $Level
@onready var xp: Label = $Xp

@onready var reward_5: Label = $VBoxContainer/Reward5
@onready var reward_4: Label = $VBoxContainer/Reward4
@onready var reward_3: Label = $VBoxContainer/Reward3
@onready var reward_2: Label = $VBoxContainer/Reward2
@onready var reward_1: Label = $VBoxContainer/Reward1

func _ready() -> void:
	level.text = "Level " + str(GameState.baseball_bat_level)
	xp.text = str(GameState.baseball_bat_xp) + "/" + str(GameState.baseball_bat_xp_needed) + " xp"

func _process(_delta: float) -> void:
	reward_1.modulate = Color(0.4, 0.4, 0.4, 1.0)
	reward_2.modulate = Color(0.0, 0.0, 0.0, 1.0)
	reward_3.modulate = Color(0.0, 0.0, 0.0, 1.0)
	reward_4.modulate = Color(0.0, 0.0, 0.0, 1.0)
	reward_5.modulate = Color(0.0, 0.0, 0.0, 1.0)
	
	if GameState.baseball_bat_level >= 5:
		reward_1.modulate = Color(0.0, 1.0, 0.217, 1.0)
		reward_2.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if GameState.baseball_bat_level >= 10:
		reward_2.modulate = Color(0.0, 1.0, 0.217, 1.0)
		reward_3.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if GameState.baseball_bat_level >= 15:
		reward_3.modulate = Color(0.0, 1.0, 0.217, 1.0)
		reward_4.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if GameState.baseball_bat_level >= 25:
		reward_4.modulate = Color(0.0, 1.0, 0.217, 1.0)
		reward_5.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if GameState.baseball_bat_level >= 50:
		reward_5.modulate = Color(0.0, 1.0, 0.217, 1.0)

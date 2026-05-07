extends Control

@onready var coins: Label = $StatsPanel/Coins
@onready var bonus_xp: Label = $StatsPanel/BonusXp
@onready var bonus_damage: Label = $StatsPanel/BonusDamage
@onready var bonus_time: Label = $StatsPanel/BonusTime

@onready var xp_gain: Button = $XpGain
@onready var damage: Button = $Damage
@onready var time: Button = $Time

@onready var xp_cost: Label = $XpGain/XpCost
@onready var damage_cost: Label = $Damage/DamageCost
@onready var time_cost: Label = $Time/TimeCost

var xp_price := 5
var damage_price := 5
var time_price := 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameState.meta_coins < xp_price:
		xp_gain.modulate = Color(0.5, 0.5, 0.5)
	else:
		xp_gain.modulate = Color(1, 1, 1)
	
	if GameState.meta_coins < damage_price:
		damage.modulate = Color(0.5, 0.5, 0.5)
	else:
		damage.modulate = Color(1, 1, 1)
	
	if GameState.meta_coins < time_price:
		time.modulate = Color(0.5, 0.5, 0.5)
	else:
		time.modulate = Color(1, 1, 1)
	
	coins.text = "Coins: " + str(GameState.meta_coins)
	bonus_xp.text = "Xp Gain: " + str(int(GameState.meta_bonus_xp_gain * 100)) + "%"
	bonus_damage.text = "Bonus Damage: " + str(int(GameState.meta_bonus_damage * 100)) + "%"
	bonus_time.text = "Extra Time: " + str(GameState.meta_bonus_time)
	
	xp_cost.text = "Cost: " + str(xp_price) + " Coins"
	damage_cost.text = "Cost: " + str(damage_price) + " Coins"
	time_cost.text = "Cost: " + str(time_price) + " Coins"

func _on_xp_gain_pressed() -> void:
	if GameState.meta_coins >= xp_price:
		GameState.meta_coins -= xp_price
		GameState.meta_bonus_xp_gain += 0.01
		xp_price += 1
		GameState.save_game()

func _on_damage_pressed() -> void:
	if GameState.meta_coins >= damage_price:
		GameState.meta_coins -= damage_price
		GameState.meta_bonus_damage += 0.01
		damage_price += 1
		GameState.save_game()

func _on_time_pressed() -> void:
	if GameState.meta_coins >= time_price:
		GameState.meta_coins -= time_price
		GameState.meta_bonus_time += 1
		time_price += 1
		GameState.save_game()

extends Panel

var xp_price := 5
var damage_price := 5
var time_price := 5

func _ready() -> void:
	self.visible = false

func _process(_delta: float) -> void:
	xp_price = int((GameState.meta_bonus_xp_gain * 100) * 1 + 5)
	damage_price = int((GameState.meta_bonus_damage * 100) * 1 + 5)
	time_price = int(GameState.meta_bonus_time * 1 + 5)
	
	if GameState.meta_coins >= min(xp_price, damage_price, time_price):
		self.visible = true
	else:
		self.visible = false

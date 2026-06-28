extends Panel

@export var all_weapons: Array[WeaponData]

func _ready():
	self.visible = false
	check_new_weapons()


func check_new_weapons():
	for weapon in all_weapons:
		# Try unlocking it
		GameState.check_weapon_unlock(weapon)
		
		# Check if unlocked and never used
		if GameState.unlocked_weapons[weapon.id]:
			if GameState.weapon_progress[weapon.id]["runs_played"] <= 0:
				self.visible = true
				return

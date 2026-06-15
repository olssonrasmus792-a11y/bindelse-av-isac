extends Panel

@onready var damage: Label = $VBoxContainer/Damage
@onready var knockback: Label = $VBoxContainer/Knockback
@onready var crit_chance: Label = $VBoxContainer/CritChance
@onready var crit_damage: Label = $VBoxContainer/CritDamage

func _ready() -> void:
	damage.text = "Damage : " + str(int(GameState.lightning_sword_damage))
	knockback.text = "Knockback : " + str(int(GameState.lightning_sword_knockback))
	crit_chance.text = "Crit chance : " + str(int(GameState.lightning_sword_crit_chance * 100)) + "%"
	crit_damage.text = "Crit damage : " + str(int(GameState.lightning_sword_crit_damage * 100)) + "%"

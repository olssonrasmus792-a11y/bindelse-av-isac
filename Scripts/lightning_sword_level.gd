extends Panel

@onready var weapon_name: Label = $Name
@onready var level: Label = $Level
@onready var xp: Label = $Xp

func _ready() -> void:
	level.text = "Level " + str(int(GameState.weapon_progress[get_parent().data.id]["level"]))
	xp.text = str(int(GameState.weapon_progress[get_parent().data.id]["xp"])) + "/" + str(int(GameState.weapon_progress[get_parent().data.id]["xp_needed"])) + " xp"
	weapon_name.self_modulate = get_parent().data.card_color
	level.self_modulate = get_parent().data.card_color
	xp.self_modulate = get_parent().data.card_color

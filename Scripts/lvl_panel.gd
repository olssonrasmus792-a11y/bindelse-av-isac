extends Panel

@onready var xp_bar: TextureProgressBar = $XpBar
@onready var lvl: Label = $XpBar/Lvl
@onready var xp: Label = $XpBar/Xp

func _process(_delta: float) -> void:
	xp_bar.max_value = GameState.meta_xp_needed
	xp_bar.value = GameState.meta_xp
	lvl.text = "Lvl " + str(GameState.meta_level)
	xp.text = "Xp: " + str(GameState.meta_xp) + "/" + str(GameState.meta_xp_needed)

extends CanvasLayer
@onready var label: Label = $Label
@onready var keys: Label = $KeyPanel/HBoxContainer/Keys
@onready var gold: Label = $GoldPanel/HBoxContainer/Gold
var kills = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	keys.text = "Keys: " + str(GameState.keys)
	gold.text = "Gold: " + str(GameState.gold)
	label.text = "Kills: " + str(GameState.kills)

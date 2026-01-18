extends CanvasLayer
@onready var label: Label = $Label
var kills = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_enemy_died():
	kills += 1
	label.text = "Kills: " + str(kills)

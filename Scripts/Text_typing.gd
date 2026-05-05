extends Label

var characters
@onready var type_sfx: AudioStreamPlayer = $"../TypeSfx"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	characters = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if visible_characters > characters:
		characters = visible_characters
		type_sfx.play()

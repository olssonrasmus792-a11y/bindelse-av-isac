extends Control

@onready var line_edit: LineEdit = $LineEdit

func _ready() -> void:
	if GameState.player_name != "":
		line_edit.text = GameState.player_name

func _process(_delta: float) -> void:
	GameState.player_name = line_edit.text

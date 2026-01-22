extends Node2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var player_is_close = false
var chest_opened = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play("Closed")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_is_close and !chest_opened:
		open_chest()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false


func open_chest():
	animated_sprite_2d.play("Open")
	chest_opened = true

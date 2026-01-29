extends Node2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var label: Label = $NoKeys

var player_is_close = false
var chest_opened = false
var gold_amount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gold_amount = randi_range(1, 5)
	label.modulate.a = 0
	animated_sprite_2d.play("Closed")

func _process(delta: float) -> void:
	if label.modulate.a > 0:
		label.modulate.a -= delta
		label.position.y -= delta * 20

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_is_close and !chest_opened:
		label.modulate.a = 1
		
		if GameState.keys > 0:
			label.position.y = -88
			label.text = "+" + str(gold_amount) + " Gold"
			label.modulate = Color.YELLOW
			open_chest()
		else:
			label.position.y = -64
			label.text = "No Keys!"
			label.modulate = Color.RED


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = true
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_is_close = false


func open_chest():
	animated_sprite_2d.play("Open")
	chest_opened = true
	gpu_particles_2d.emitting = true
	GameState.keys -= 1
	GameState.gold += gold_amount

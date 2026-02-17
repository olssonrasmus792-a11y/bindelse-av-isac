extends Node2D

@onready var jump_effect: GPUParticles2D = $JumpEffect
@onready var jump_effect_2: GPUParticles2D = $JumpEffect2
@onready var jump_effect_3: GPUParticles2D = $JumpEffect3

@onready var collision: Area2D = $Collision
@onready var collision_2: Area2D = $Collision2
@onready var collision_3: Area2D = $Collision3

@export var knockback_strength_player = -300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision.monitoring = false
	collision_2.monitoring = false
	collision_3.monitoring = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if jump_effect.emitting:
		collision.monitoring = true
		
	if jump_effect_2.emitting:
		collision_2.monitoring = true
		
	if jump_effect_3.emitting:
		collision_3.monitoring = true


func _on_collision_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position, knockback_strength_player)

func _on_collision_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position, knockback_strength_player)

func _on_collision_3_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1, global_position, knockback_strength_player)

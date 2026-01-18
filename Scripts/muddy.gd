extends CharacterBody2D

@export var speed := 400
@onready var sprite_2d: Sprite2D = $Sprite2D

var direction := Vector2(1, 1).normalized()
var health = 2

signal enemy_died

func _ready() -> void:
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))

func _physics_process(_delta):
	velocity = direction * speed
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		direction = direction.bounce(collision.get_normal())
	
	sprite_2d.flip_h = direction[0] < 0
	if direction[0] < 0:
		sprite_2d.rotation_degrees -= 10
	else:
		sprite_2d.rotation_degrees += 10
		

func take_damage(damage):
	health -= damage
	sprite_2d.modulate = Color.RED
	if health <= 0:
		emit_signal("enemy_died")  
		print("signal emitted")
		queue_free()

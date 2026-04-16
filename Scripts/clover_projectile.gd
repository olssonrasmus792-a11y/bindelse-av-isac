extends Node2D

var knockback_strength_player = 350
var rotation_speed = -60
var speed = 450
var direction
var total_lifetime = 10.0
var lifetime = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation += rotation_speed * delta
	position += speed * direction * delta
	
	lifetime += delta
	modulate.a = remap(lifetime, 0.0, 10.0, 1.5, 0.25)
	if lifetime >= total_lifetime:
		queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(1, global_position, -knockback_strength_player)
		queue_free()

extends Node2D

var knockback_strength_player = 350
var rotation_speed = -180
var speed = 450
var direction

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation += rotation_speed * delta
	position += speed * direction * delta

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(1, global_position, -knockback_strength_player)
		queue_free()

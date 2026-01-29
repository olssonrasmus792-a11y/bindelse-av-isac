extends Node2D

@export var lifetime := 1.5  # seconds

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(1)
